import Foundation
import UIKit
import UserNotifications
import AVFoundation

public final class ToastBackgroundKeepAlive {
    public static let shared = ToastBackgroundKeepAlive()

    private var backgroundTaskIdentifier: UIBackgroundTaskIdentifier = .invalid
    private var silentAudioPlayer: AVAudioPlayer?
    private var isRunning = false

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

    private func startSilentAudio() {
        guard self.silentAudioPlayer == nil else { return }

        // Generate a minimal 1-second silent WAV file in memory
        let sampleRate: Int = 8000
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
        data.append(Data(repeating: 0, count: dataSize))

        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
            let player = try AVAudioPlayer(data: data)
            player.numberOfLoops = -1
            player.volume = 0.001
            player.play()
            self.silentAudioPlayer = player
        } catch {
        }
    }

    private func stopSilentAudio() {
        self.silentAudioPlayer?.stop()
        self.silentAudioPlayer = nil
    }

    public func postLocalNotification(title: String, body: String, peerId: Int64, messageId: Int32) {
        guard ToastSettings.shared.localNotificationsEnabled else { return }

        let center = UNUserNotificationCenter.current()
        center.getNotificationSettings { settings in
            if settings.authorizationStatus == .notDetermined {
                center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
                    if granted {
                        self.enqueueNotification(title: title, body: body, peerId: peerId, messageId: messageId)
                    }
                }
            } else if settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional {
                self.enqueueNotification(title: title, body: body, peerId: peerId, messageId: messageId)
            }
        }
    }

    private func enqueueNotification(title: String, body: String, peerId: Int64, messageId: Int32) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body.isEmpty ? "New message" : body
        content.sound = .default
        content.userInfo = [
            "peerId": "\(peerId)",
            "messageId": "\(messageId)"
        ]

        let request = UNNotificationRequest(
            identifier: "toast_msg_\(peerId)_\(messageId)",
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
    }
}
