import Foundation
import Accelerate

public final class ToastVoiceChanger {
    public static let shared = ToastVoiceChanger()

    private var robotPhase: Double = 0.0
    private var pitchPhase: Double = 0.0
    private let sampleRate: Double = 16000.0

    private var grainBuffer: [Float] = Array(repeating: 0.0, count: 512)
    private var grainBufferPos: Int = 0

    private init() {}

    public func reset() {
        self.robotPhase = 0.0
        self.pitchPhase = 0.0
        self.grainBufferPos = 0
        self.grainBuffer = Array(repeating: 0.0, count: 512)
    }

    public func process(samples: UnsafeMutablePointer<Int16>, count: Int, mode: ToastVoiceChangerMode) {
        guard mode != .off, count > 0 else {
            return
        }

        switch mode {
        case .off:
            break
        case .robot:
            self.processRobot(samples: samples, count: count)
        case .femboy:
            self.processPitchShift(samples: samples, count: count, pitchRatio: 1.35)
        case .helium:
            self.processPitchShift(samples: samples, count: count, pitchRatio: 1.68)
        case .deep:
            self.processPitchShift(samples: samples, count: count, pitchRatio: 0.76)
        }
    }

    private func processRobot(samples: UnsafeMutablePointer<Int16>, count: Int) {
        let carrierFreq: Double = 70.0
        let twoPi = 2.0 * Double.pi
        let phaseIncrement = twoPi * carrierFreq / self.sampleRate

        for i in 0 ..< count {
            let original = Double(samples[i]) / 32768.0
            let carrier = sin(self.robotPhase)
            self.robotPhase += phaseIncrement
            if self.robotPhase > twoPi {
                self.robotPhase -= twoPi
            }

            var modulated = original * (0.65 * carrier + 0.35)
            // Soft clipping / saturation
            if modulated > 0.85 {
                modulated = 0.85 + (modulated - 0.85) * 0.2
            } else if modulated < -0.85 {
                modulated = -0.85 + (modulated + 0.85) * 0.2
            }

            let clamped = max(-1.0, min(1.0, modulated))
            samples[i] = Int16(clamped * 32767.0)
        }
    }

    private func processPitchShift(samples: UnsafeMutablePointer<Int16>, count: Int, pitchRatio: Double) {
        let grainSize = 256
        let halfGrain = grainSize / 2

        var tempFloats = [Float](repeating: 0, count: count)
        for i in 0 ..< count {
            tempFloats[i] = Float(samples[i])
        }

        var outputFloats = [Float](repeating: 0, count: count)

        var readIndex = self.pitchPhase
        for i in 0 ..< count {
            let offsetInGrain = i % halfGrain
            let crossfade = Float(offsetInGrain) / Float(halfGrain)

            let pos1 = Int(readIndex) % count
            let pos2 = (Int(readIndex) + halfGrain) % count

            let s1 = tempFloats[pos1]
            let s2 = tempFloats[pos2]

            // Overlap-add between two grains with linear cross-fade
            let blended = s1 * (1.0 - crossfade) + s2 * crossfade
            outputFloats[i] = blended

            readIndex += pitchRatio
            while readIndex >= Double(count) {
                readIndex -= Double(count)
            }
        }
        self.pitchPhase = readIndex

        for i in 0 ..< count {
            let val = max(-32768.0, min(32767.0, outputFloats[i]))
            samples[i] = Int16(val)
        }
    }
}
