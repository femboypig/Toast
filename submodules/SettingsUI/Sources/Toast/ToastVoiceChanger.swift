import Foundation

public final class ToastVoiceChanger {
    public static let shared = ToastVoiceChanger()

    private let sampleRate: Double = 16000.0

    // Pitch shifting circular buffer: size 2048 (128ms at 16kHz), window size 1024 (64ms)
    private let pitchBufferSize: Int = 2048
    private let pitchWindowSize: Int = 1024
    private var pitchBuffer: [Float] = Array(repeating: 0.0, count: 2048)
    private var pitchWriteIndex: Int = 0
    private var pitchPhase: Double = 0.0

    // Echo circular buffer: size 8192 (512ms at 16kHz)
    private let echoBufferSize: Int = 8192
    private var echoBuffer: [Float] = Array(repeating: 0.0, count: 8192)
    private var echoWriteIndex: Int = 0

    // Reverb comb filters
    private var revBuffer1: [Float] = Array(repeating: 0.0, count: 563)
    private var revIndex1: Int = 0
    private var revBuffer2: [Float] = Array(repeating: 0.0, count: 719)
    private var revIndex2: Int = 0
    private var revBuffer3: [Float] = Array(repeating: 0.0, count: 887)
    private var revIndex3: Int = 0

    // Robot modulation phase
    private var robotPhase: Double = 0.0

    // Bass filter state
    private var bassState: Float = 0.0

    private init() {}

    public func reset() {
        self.pitchWriteIndex = 0
        self.pitchPhase = 0.0
        self.pitchBuffer = Array(repeating: 0.0, count: self.pitchBufferSize)
        self.echoWriteIndex = 0
        self.echoBuffer = Array(repeating: 0.0, count: self.echoBufferSize)
        self.revIndex1 = 0
        self.revBuffer1 = Array(repeating: 0.0, count: 563)
        self.revIndex2 = 0
        self.revBuffer2 = Array(repeating: 0.0, count: 719)
        self.revIndex3 = 0
        self.revBuffer3 = Array(repeating: 0.0, count: 887)
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

        let echoDelaySamples = 2560 // 160ms delay
        let echoFeedback = min(0.65, echoStrength * 0.55)
        let echoMix = min(0.8, echoStrength * 0.7)

        let robotFreqStep = (2.0 * Double.pi * 130.0) / self.sampleRate // 130Hz metallic carrier

        let bassGain = Float(pow(10.0, bassBoost / 20.0) - 1.0)
        let bassAlpha: Float = 0.08 // ~200Hz cutoff at 16kHz

        for i in 0 ..< count {
            let inputSample = Float(samples[i])
            var processedSample = inputSample

            // 1. Clean continuous pitch shifter
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
                processedSample = processedSample * (1.0 - robotMix * 0.8) + (processedSample * mod) * robotMix
                self.robotPhase = (self.robotPhase + robotFreqStep).truncatingRemainder(dividingBy: 2.0 * Double.pi)
            }

            // 3. Bass Boost / Cut filter
            if isBassActive {
                self.bassState += bassAlpha * (processedSample - self.bassState)
                processedSample += self.bassState * bassGain
            }

            // 4. Multi-tap Reverb
            if isReverbActive {
                let revMix = Float(reverbStrength * 0.45)
                let revFeed: Float = 0.55

                let out1 = self.revBuffer1[self.revIndex1]
                let out2 = self.revBuffer2[self.revIndex2]
                let out3 = self.revBuffer3[self.revIndex3]

                self.revBuffer1[self.revIndex1] = processedSample + out1 * revFeed
                self.revBuffer2[self.revIndex2] = processedSample + out2 * revFeed
                self.revBuffer3[self.revIndex3] = processedSample + out3 * revFeed

                self.revIndex1 = (self.revIndex1 + 1) % 563
                self.revIndex2 = (self.revIndex2 + 1) % 719
                self.revIndex3 = (self.revIndex3 + 1) % 887

                let revSum = (out1 + out2 + out3) * 0.33
                processedSample = processedSample * (1.0 - revMix * 0.4) + revSum * revMix
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
                let drive = Float(distortionStrength * 4.0)
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
