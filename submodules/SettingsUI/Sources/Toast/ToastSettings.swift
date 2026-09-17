import Foundation
import SwiftSignalKit

public enum ToastVoiceChangerMode: String, CaseIterable {
    case off = "off"
    case custom = "custom"
    case femboy = "femboy"
    case deep = "deep"
    case helium = "helium"
    case robot = "robot"

    public var title: String {
        switch self {
        case .off:
            return "Original"
        case .custom:
            return "Custom"
        case .femboy:
            return "Femboy"
        case .deep:
            return "Deep Bass"
        case .helium:
            return "Helium"
        case .robot:
            return "Robot"
        }
    }
}

public final class ToastSettings {
    public static let shared = ToastSettings()

    private let defaults = UserDefaults.standard

    private let saveDisappearingMediaKey = "Toast_saveDisappearingMedia"
    private let allowScreenshotsKey = "Toast_allowScreenshots"
    private let allowSavingProtectedContentKey = "Toast_allowSavingProtectedContent"
    private let voiceChangerEnabledKey = "Toast_voiceChangerEnabled"
    private let voiceChangerPitchKey = "Toast_voiceChangerPitch"
    private let voiceChangerEchoKey = "Toast_voiceChangerEcho"
    private let voiceChangerModeKey = "Toast_voiceChangerMode"
    private let backgroundKeepAliveKey = "Toast_backgroundKeepAlive"
    private let localNotificationsEnabledKey = "Toast_localNotificationsEnabled"

    private let updatedPromise = ValuePromise<Bool>(true, ignoreRepeated: false)
    public var updated: Signal<Void, NoError> {
        return self.updatedPromise.get() |> map { _ in return () }
    }

    private init() {
        self.defaults.register(defaults: [
            self.saveDisappearingMediaKey: true,
            self.allowScreenshotsKey: true,
            self.allowSavingProtectedContentKey: true,
            self.voiceChangerEnabledKey: false,
            self.voiceChangerPitchKey: Float(0.0),
            self.voiceChangerEchoKey: Float(0.0),
            self.backgroundKeepAliveKey: true,
            self.localNotificationsEnabledKey: true
        ])
    }

    public var saveDisappearingMedia: Bool {
        get {
            return self.defaults.object(forKey: self.saveDisappearingMediaKey) as? Bool ?? true
        }
        set {
            self.defaults.set(newValue, forKey: self.saveDisappearingMediaKey)
            self.updatedPromise.set(true)
        }
    }

    public var allowScreenshots: Bool {
        get {
            return self.defaults.object(forKey: self.allowScreenshotsKey) as? Bool ?? true
        }
        set {
            self.defaults.set(newValue, forKey: self.allowScreenshotsKey)
            self.updatedPromise.set(true)
        }
    }

    public var allowSavingProtectedContent: Bool {
        get {
            return self.defaults.object(forKey: self.allowSavingProtectedContentKey) as? Bool ?? true
        }
        set {
            self.defaults.set(newValue, forKey: self.allowSavingProtectedContentKey)
            self.updatedPromise.set(true)
        }
    }

    public var voiceChangerEnabled: Bool {
        get {
            return self.defaults.object(forKey: self.voiceChangerEnabledKey) as? Bool ?? false
        }
        set {
            self.defaults.set(newValue, forKey: self.voiceChangerEnabledKey)
            self.updatedPromise.set(true)
        }
    }

    public var voiceChangerPitch: Float {
        get {
            return self.defaults.object(forKey: self.voiceChangerPitchKey) as? Float ?? 0.0
        }
        set {
            self.defaults.set(newValue, forKey: self.voiceChangerPitchKey)
            self.updatedPromise.set(true)
        }
    }

    public var voiceChangerEcho: Float {
        get {
            return self.defaults.object(forKey: self.voiceChangerEchoKey) as? Float ?? 0.0
        }
        set {
            self.defaults.set(newValue, forKey: self.voiceChangerEchoKey)
            self.updatedPromise.set(true)
        }
    }

    public var voiceChangerMode: ToastVoiceChangerMode {
        get {
            if !self.voiceChangerEnabled {
                return .off
            }
            if let rawValue = self.defaults.string(forKey: self.voiceChangerModeKey),
               let mode = ToastVoiceChangerMode(rawValue: rawValue) {
                return mode
            }
            return .custom
        }
        set {
            self.defaults.set(newValue.rawValue, forKey: self.voiceChangerModeKey)
            self.voiceChangerEnabled = (newValue != .off)
            self.updatedPromise.set(true)
        }
    }

    public var backgroundKeepAlive: Bool {
        get {
            return self.defaults.object(forKey: self.backgroundKeepAliveKey) as? Bool ?? true
        }
        set {
            self.defaults.set(newValue, forKey: self.backgroundKeepAliveKey)
            self.updatedPromise.set(true)
        }
    }

    public var localNotificationsEnabled: Bool {
        get {
            return self.defaults.object(forKey: self.localNotificationsEnabledKey) as? Bool ?? true
        }
        set {
            self.defaults.set(newValue, forKey: self.localNotificationsEnabledKey)
            self.updatedPromise.set(true)
        }
    }

    public func resetToDefaults() {
        self.saveDisappearingMedia = true
        self.allowScreenshots = true
        self.allowSavingProtectedContent = true
        self.voiceChangerEnabled = false
        self.voiceChangerPitch = 0.0
        self.voiceChangerEcho = 0.0
        self.voiceChangerMode = .off
        self.backgroundKeepAlive = true
        self.localNotificationsEnabled = true
        self.updatedPromise.set(true)
    }
}
