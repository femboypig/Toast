import Foundation
import UIKit
import UserNotifications
import AVFoundation
import Intents

public final class ToastBackgroundKeepAlive {
    public static let shared = ToastBackgroundKeepAlive()

    private var backgroundTaskIdentifier: UIBackgroundTaskIdentifier = .invalid
    private var silentAudioPlayer: AVAudioPlayer?
    private var isRunning = false
    private var isObserverRegistered = false

    private init() {}

    public func updateState() {
        if UIApplication.shared.applicationState != .active && ToastSettings.shared.backgroundKeepAlive {
            self.startKeepAlive()
        } else {
            self.stopKeepAlive()
        }
    }

    public func startKeepAlive() {
        guard !self.isRunning else { return }
        self.isRunning = true

        self.backgroundTaskIdentifier = UIApplication.shared.beginBackgroundTask(withName: "ToastKeepAlive") { [weak self] in
            self?.renewBackgroundTask()
        }

        self.setupInterruptionObserver()
        self.startSilentAudio()
    }

    public func stopKeepAlive() {
        self.isRunning = false
        self.stopSilentAudio()

        if self.backgroundTaskIdentifier != .invalid {
            UIApplication.shared.endBackgroundTask(self.backgroundTaskIdentifier)
            self.backgroundTaskIdentifier = .invalid
        }
    }

    private func renewBackgroundTask() {
        if self.backgroundTaskIdentifier != .invalid {
            UIApplication.shared.endBackgroundTask(self.backgroundTaskIdentifier)
            self.backgroundTaskIdentifier = .invalid
        }

        if self.isRunning && ToastSettings.shared.backgroundKeepAlive {
            self.backgroundTaskIdentifier = UIApplication.shared.beginBackgroundTask(withName: "ToastKeepAlive") { [weak self] in
                self?.renewBackgroundTask()
            }
        }
    }

    private func setupInterruptionObserver() {
        guard !self.isObserverRegistered else { return }
        self.isObserverRegistered = true
        NotificationCenter.default.addObserver(self, selector: #selector(self.handleAudioInterruption(_:)), name: AVAudioSession.interruptionNotification, object: nil)
    }

    @objc private func handleAudioInterruption(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
            return
        }

        if type == .ended {
            let _ = try? AVAudioSession.sharedInstance().setActive(true)
            if self.isRunning && ToastSettings.shared.backgroundKeepAlive {
                self.silentAudioPlayer?.play()
            }
        }
    }

    private func startSilentAudio() {
        guard self.silentAudioPlayer == nil else {
            if self.silentAudioPlayer?.isPlaying == false {
                self.silentAudioPlayer?.play()
            }
            return
        }

        // Generate a minimal 1-second WAV file in memory with sub-audible dither
        let sampleRate: Int = 16000
        let numSamples: Int = sampleRate
        let numChannels: Int = 1
        let bitsPerSample: Int = 16
        let byteRate: Int = sampleRate * numChannels * bitsPerSample / 8
        let blockAlign: Int = numChannels * bitsPerSample / 8
        let dataSize: Int = numSamples * blockAlign
        let chunkSize: Int = 36 + dataSize

        var data = Data()
        data.append(contentsOf: [0x52, 0x49, 0x46, 0x46]) // "RIFF"
        data.append(contentsOf: withUnsafeBytes(of: UInt32(chunkSize).littleEndian, Array.init))
        data.append(contentsOf: [0x57, 0x41, 0x56, 0x45]) // "WAVE"
        data.append(contentsOf: [0x66, 0x6D, 0x74, 0x20]) // "fmt "
        data.append(contentsOf: withUnsafeBytes(of: UInt32(16).littleEndian, Array.init))
        data.append(contentsOf: withUnsafeBytes(of: UInt16(1).littleEndian, Array.init)) // PCM
        data.append(contentsOf: withUnsafeBytes(of: UInt16(numChannels).littleEndian, Array.init))
        data.append(contentsOf: withUnsafeBytes(of: UInt32(sampleRate).littleEndian, Array.init))
        data.append(contentsOf: withUnsafeBytes(of: UInt32(byteRate).littleEndian, Array.init))
        data.append(contentsOf: withUnsafeBytes(of: UInt16(blockAlign).littleEndian, Array.init))
        data.append(contentsOf: withUnsafeBytes(of: UInt16(bitsPerSample).littleEndian, Array.init))
        data.append(contentsOf: [0x64, 0x61, 0x74, 0x61]) // "data"
        data.append(contentsOf: withUnsafeBytes(of: UInt32(dataSize).littleEndian, Array.init))

        // Sub-audible dither (+1/-1, -90dB) prevents iOS power management from idling audio hardware
        var pcmSamples = [Int16](repeating: 0, count: numSamples)
        for i in 0 ..< numSamples {
            pcmSamples[i] = (i % 2 == 0) ? 1 : -1
        }
        data.append(contentsOf: pcmSamples.withUnsafeBytes { Array($0) })

        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
            let player = try AVAudioPlayer(data: data)
            player.numberOfLoops = -1
            player.volume = 0.001
            player.prepareToPlay()
            player.play()
            self.silentAudioPlayer = player
        } catch {
        }
    }

    private func stopSilentAudio() {
        self.silentAudioPlayer?.stop()
        self.silentAudioPlayer = nil
    }

    public func postLocalNotification(
        title: String,
        body: String,
        peerId: Int64,
        messageId: Int32,
        senderTitle: String? = nil,
        isGroup: Bool = false,
        avatarData: Data? = nil
    ) {
        guard ToastSettings.shared.localNotificationsEnabled else { return }

        let center = UNUserNotificationCenter.current()
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body.isEmpty ? "New message" : body
        content.sound = .default
        content.userInfo = [
            "peerId": "\(peerId)",
            "messageId": "\(messageId)"
        ]

        var resolvedAvatarData = avatarData
        if resolvedAvatarData == nil {
            let letter = String((senderTitle ?? title).prefix(1)).uppercased()
            let size = CGSize(width: 120.0, height: 120.0)
            UIGraphicsBeginImageContextWithOptions(size, false, 2.0)
            if let ctx = UIGraphicsGetCurrentContext() {
                ctx.saveGState()
                ctx.addEllipse(in: CGRect(origin: .zero, size: size))
                ctx.clip()

                let hash = abs((senderTitle ?? title).hashValue)
                let hue = CGFloat(hash % 360) / 360.0
                let startColor = UIColor(hue: hue, saturation: 0.65, brightness: 0.85, alpha: 1.0)
                let endColor = UIColor(hue: hue, saturation: 0.8, brightness: 0.65, alpha: 1.0)
                let colors = [startColor.cgColor, endColor.cgColor] as CFArray
                let colorSpace = CGColorSpaceCreateDeviceRGB()
                if let gradient = CGGradient(colorsSpace: colorSpace, colors: colors, locations: [0.0, 1.0]) {
                    ctx.drawLinearGradient(gradient, start: CGPoint(x: 0, y: 0), end: CGPoint(x: 0, y: size.height), options: [])
                }

                if !letter.isEmpty {
                    let font = UIFont.systemFont(ofSize: 52.0, weight: .semibold)
                    let attributes: [NSAttributedString.Key: Any] = [
                        .font: font,
                        .foregroundColor: UIColor.white
                    ]
                    let str = NSAttributedString(string: letter, attributes: attributes)
                    let strSize = str.size()
                    let strRect = CGRect(
                        x: (size.width - strSize.width) / 2.0,
                        y: (size.height - strSize.height) / 2.0,
                        width: strSize.width,
                        height: strSize.height
                    )
                    str.draw(in: strRect)
                }

                ctx.restoreGState()
                let img = UIGraphicsGetImageFromCurrentImageContext()
                UIGraphicsEndImageContext()
                resolvedAvatarData = img?.jpegData(compressionQuality: 0.85)
            } else {
                UIGraphicsEndImageContext()
            }
        }

        var finalContent: UNNotificationContent = content

        if #available(iOS 15.0, *) {
            let senderName = senderTitle ?? title
            var personImage: INImage?
            if let data = resolvedAvatarData {
                personImage = INImage(imageData: data)
            }

            let handle = INPersonHandle(value: "\(peerId)", type: .unknown)
            let sender = INPerson(
                personHandle: handle,
                nameComponents: nil,
                displayName: senderName,
                image: personImage,
                contactIdentifier: nil,
                customIdentifier: "\(peerId)"
            )

            let intent = INSendMessageIntent(
                recipients: isGroup ? nil : [sender],
                content: content.body,
                speakableGroupName: isGroup ? INSpeakableString(spokenPhrase: title) : nil,
                conversationIdentifier: "\(peerId)",
                serviceName: nil,
                sender: sender
            )

            let interaction = INInteraction(intent: intent, response: nil)
            interaction.direction = .incoming
            interaction.donate(completion: nil)

            if let updated = try? content.updating(from: intent) {
                finalContent = updated
            }
        }

        let request = UNNotificationRequest(
            identifier: "toast_msg_\(peerId)_\(messageId)",
            content: finalContent,
            trigger: nil
        )

        center.getNotificationSettings { settings in
            if settings.authorizationStatus == .notDetermined {
                center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
                    if granted {
                        center.add(request, withCompletionHandler: nil)
                    }
                }
            } else if settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional {
                center.add(request, withCompletionHandler: nil)
            }
        }
    }
}
