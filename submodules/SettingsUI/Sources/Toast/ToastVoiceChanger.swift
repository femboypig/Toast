import Foundation

public final class ToastVoiceChanger {
    public static let shared = ToastVoiceChanger()

    private let sampleRate: Double = 48000.0

    // Pitch shifting circular buffer: size 8192 (170ms at 48kHz), window size 4096 (85ms)
    private let pitchBufferSize: Int = 8192
    private let pitchWindowSize: Int = 4096
    private var pitchBuffer: [Float] = Array(repeating: 0.0, count: 8192)
    private var pitchWriteIndex: Int = 0
    private var pitchPhase: Double = 0.0

    // Echo circular buffer: size 32768 (682ms at 48kHz)
    private let echoBufferSize: Int = 32768
    private var echoBuffer: [Float] = Array(repeating: 0.0, count: 32768)
    private var echoWriteIndex: Int = 0

    // Reverb comb filters (primes around 32-48ms at 48kHz)
    private let revLen1: Int = 1553
    private var revBuffer1: [Float] = Array(repeating: 0.0, count: 1553)
    private var revIndex1: Int = 0

    private let revLen2: Int = 1787
    private var revBuffer2: [Float] = Array(repeating: 0.0, count: 1787)
    private var revIndex2: Int = 0

    private let revLen3: Int = 2053
    private var revBuffer3: [Float] = Array(repeating: 0.0, count: 2053)
    private var revIndex3: Int = 0

    private let revLen4: Int = 2281
    private var revBuffer4: [Float] = Array(repeating: 0.0, count: 2281)
    private var revIndex4: Int = 0

    // Schroeder all-pass diffuser (11.6ms at 48kHz) to eliminate comb flutter
    private let allpassLen: Int = 557
    private var allpassBuffer: [Float] = Array(repeating: 0.0, count: 557)
    private var allpassIndex: Int = 0

    // Robot modulation phase
    private var robotPhase: Double = 0.0

    // Bass filter state (one-pole low-pass filter)
    private var bassState: Float = 0.0

    private init() {}

    public func reset() {
        self.pitchWriteIndex = 0
        self.pitchPhase = 0.0
        self.pitchBuffer = Array(repeating: 0.0, count: self.pitchBufferSize)
        self.echoWriteIndex = 0
        self.echoBuffer = Array(repeating: 0.0, count: self.echoBufferSize)
        self.revIndex1 = 0
        self.revBuffer1 = Array(repeating: 0.0, count: self.revLen1)
        self.revIndex2 = 0
        self.revBuffer2 = Array(repeating: 0.0, count: self.revLen2)
        self.revIndex3 = 0
        self.revBuffer3 = Array(repeating: 0.0, count: self.revLen3)
        self.revIndex4 = 0
        self.revBuffer4 = Array(repeating: 0.0, count: self.revLen4)
        self.allpassIndex = 0
        self.allpassBuffer = Array(repeating: 0.0, count: self.allpassLen)
        self.robotPhase = 0.0
        self.bassState = 0.0
    }

    public func process(samples: UnsafeMutablePointer<Int16>, count: Int) {
        guard ToastSettings.shared.voiceChangerEnabled, count > 0 else {
            return
        }

        let pitchSemitones = Double(ToastSettings.shared.voiceChangerPitch)
        let echoStrength = Double(ToastSettings.shared.voiceChangerEcho)
        let reverbStrength = Double(ToastSettings.shared.voiceChangerReverb)
        let robotStrength = Double(ToastSettings.shared.voiceChangerRobot)
        let bassBoost = Double(ToastSettings.shared.voiceChangerBass)
        let distortionStrength = Double(ToastSettings.shared.voiceChangerDistortion)

        let isPitchActive = abs(pitchSemitones) > 0.05
        let isEchoActive = echoStrength > 0.02
        let isReverbActive = reverbStrength > 0.02
        let isRobotActive = robotStrength > 0.02
        let isBassActive = abs(bassBoost) > 0.1
        let isDistortionActive = distortionStrength > 0.02

        guard isPitchActive || isEchoActive || isReverbActive || isRobotActive || isBassActive || isDistortionActive else {
            return
        }

        // Pitch ratio R: 2^(semitones / 12)
        let pitchRatio = pow(2.0, pitchSemitones / 12.0)
        let rate = (1.0 - pitchRatio) / Double(self.pitchWindowSize)

        let pitchMask = self.pitchBufferSize - 1
        let echoMask = self.echoBufferSize - 1

        let echoDelaySamples = 9600 // 200ms delay at 48kHz
        let echoFeedback = min(0.60, echoStrength * 0.50)
        let echoMix = min(0.75, echoStrength * 0.65)

        let robotFreqStep = (2.0 * Double.pi * 130.0) / self.sampleRate // 130Hz metallic carrier

        let bassGain = Float(pow(10.0, bassBoost / 20.0) - 1.0)
        let bassAlpha: Float = 0.02 // ~150Hz cutoff at 48kHz

        for i in 0 ..< count {
            let inputSample = Float(samples[i])
            var processedSample = inputSample

            // 1. Clean continuous pitch shifter with Hann window crossfade
            if isPitchActive {
                self.pitchBuffer[self.pitchWriteIndex] = inputSample

                let phi0 = self.pitchPhase - floor(self.pitchPhase)
                let phi1 = (self.pitchPhase + 0.5) - floor(self.pitchPhase + 0.5)

                let d0 = phi0 * Double(self.pitchWindowSize)
                let d1 = phi1 * Double(self.pitchWindowSize)

                let readPos0 = (Double(self.pitchWriteIndex) - d0 + Double(self.pitchBufferSize)).truncatingRemainder(dividingBy: Double(self.pitchBufferSize))
                let i0 = Int(readPos0) & pitchMask
                let frac0 = Float(readPos0 - floor(readPos0))
                let s0 = self.pitchBuffer[i0] * (1.0 - frac0) + self.pitchBuffer[(i0 + 1) & pitchMask] * frac0
                let w0 = Float(0.5 * (1.0 - cos(2.0 * Double.pi * phi0)))

                let readPos1 = (Double(self.pitchWriteIndex) - d1 + Double(self.pitchBufferSize)).truncatingRemainder(dividingBy: Double(self.pitchBufferSize))
                let i1 = Int(readPos1) & pitchMask
                let frac1 = Float(readPos1 - floor(readPos1))
                let s1 = self.pitchBuffer[i1] * (1.0 - frac1) + self.pitchBuffer[(i1 + 1) & pitchMask] * frac1
                let w1 = Float(0.5 * (1.0 - cos(2.0 * Double.pi * phi1)))

                processedSample = s0 * w0 + s1 * w1

                self.pitchWriteIndex = (self.pitchWriteIndex + 1) & pitchMask
                self.pitchPhase = (self.pitchPhase + rate).truncatingRemainder(dividingBy: 1.0)
                if self.pitchPhase < 0.0 {
                    self.pitchPhase += 1.0
                }
            }

            // 2. Robot / Ring modulation
            if isRobotActive {
                let mod = Float(cos(self.robotPhase))
                let robotMix = Float(robotStrength)
                processedSample = processedSample * (1.0 - robotMix * 0.75) + (processedSample * mod) * robotMix
                self.robotPhase = (self.robotPhase + robotFreqStep).truncatingRemainder(dividingBy: 2.0 * Double.pi)
            }

            // 3. Bass Boost / Cut filter
            if isBassActive {
                self.bassState += bassAlpha * (processedSample - self.bassState)
                processedSample += self.bassState * bassGain
            }

            // 4. Multi-tap Reverb with Schroeder allpass diffusion
            if isReverbActive {
                let revMix = Float(reverbStrength * 0.40)
                let revFeed: Float = 0.50

                let out1 = self.revBuffer1[self.revIndex1]
                let out2 = self.revBuffer2[self.revIndex2]
                let out3 = self.revBuffer3[self.revIndex3]
                let out4 = self.revBuffer4[self.revIndex4]

                self.revBuffer1[self.revIndex1] = processedSample + out1 * revFeed
                self.revBuffer2[self.revIndex2] = processedSample + out2 * revFeed
                self.revBuffer3[self.revIndex3] = processedSample + out3 * revFeed
                self.revBuffer4[self.revIndex4] = processedSample + out4 * revFeed

                self.revIndex1 = (self.revIndex1 + 1) % self.revLen1
                self.revIndex2 = (self.revIndex2 + 1) % self.revLen2
                self.revIndex3 = (self.revIndex3 + 1) % self.revLen3
                self.revIndex4 = (self.revIndex4 + 1) % self.revLen4

                let combSum = (out1 + out2 + out3 + out4) * 0.25

                // Allpass diffuser: y[n] = -g*x[n] + x[n-D] + g*y[n-D]
                let apIn = combSum
                let apOutOld = self.allpassBuffer[self.allpassIndex]
                let apFeedback: Float = 0.5
                let apNew = apIn + apOutOld * apFeedback
                self.allpassBuffer[self.allpassIndex] = apNew
                self.allpassIndex = (self.allpassIndex + 1) % self.allpassLen
                let diffuseReverb = apOutOld - apIn * apFeedback

                processedSample = processedSample * (1.0 - revMix * 0.35) + diffuseReverb * revMix
            }

            // 5. Echo / Delay line
            if isEchoActive {
                let echoReadIndex = (self.echoWriteIndex - echoDelaySamples + self.echoBufferSize) & echoMask
                let delayedSample = self.echoBuffer[echoReadIndex]

                let newEchoValue = processedSample + delayedSample * Float(echoFeedback)
                self.echoBuffer[self.echoWriteIndex] = newEchoValue
                self.echoWriteIndex = (self.echoWriteIndex + 1) & echoMask

                processedSample = processedSample * Float(1.0 - echoMix * 0.35) + delayedSample * Float(echoMix)
            }

            // 6. Distortion / Soft Drive
            if isDistortionActive {
                let drive = Float(distortionStrength * 3.5)
                let norm = processedSample / 32768.0
                let driven = (1.0 + drive) * norm / (1.0 + drive * abs(norm))
                processedSample = driven * 32768.0
            }

            // 7. Soft-clipping / limiter to prevent digital overflow
            let clamped: Float
            if processedSample > 32600.0 {
                clamped = 32600.0
            } else if processedSample < -32600.0 {
                clamped = -32600.0
            } else {
                clamped = processedSample
            }

            samples[i] = Int16(clamped)
        }
    }

    public func process(samples: UnsafeMutablePointer<Int16>, count: Int, mode: ToastVoiceChangerMode) {
        self.process(samples: samples, count: count)
    }
}
