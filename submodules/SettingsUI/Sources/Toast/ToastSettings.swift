import Foundation
import SwiftSignalKit

public enum ToastVoiceChangerMode: String, CaseIterable {
    case off = "off"
    case femboy = "femboy"
    case deep = "deep"
    case helium = "helium"
    case robot = "robot"

    public var title: String {
        switch self {
        case .off:
            return "Original"
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
    private let voiceChangerModeKey = "Toast_voiceChangerMode"
    private let backgroundKeepAliveKey = "Toast_backgroundKeepAlive"
    private let localNotificationsEnabledKey = "Toast_localNotificationsEnabled"

    private let updatedPromise = ValuePromise<Bool>(true, ignoreRepeated: false)
    public var updated: Signal<Void, NoError> {
        return self.updatedPromise.get() |> map { _ in return () }
    }

    private init() {
        if self.defaults.object(forKey: self.backgroundKeepAliveKey) == nil {
            self.defaults.set(true, forKey: self.backgroundKeepAliveKey)
        }
        if self.defaults.object(forKey: self.localNotificationsEnabledKey) == nil {
            self.defaults.set(true, forKey: self.localNotificationsEnabledKey)
        }
    }

    public var saveDisappearingMedia: Bool {
        get {
            return self.defaults.bool(forKey: self.saveDisappearingMediaKey)
        }
        set {
            self.defaults.set(newValue, forKey: self.saveDisappearingMediaKey)
            self.updatedPromise.set(true)
        }
    }

    public var allowScreenshots: Bool {
        get {
            return self.defaults.bool(forKey: self.allowScreenshotsKey)
        }
        set {
            self.defaults.set(newValue, forKey: self.allowScreenshotsKey)
            self.updatedPromise.set(true)
        }
    }

    public var allowSavingProtectedContent: Bool {
        get {
            return self.defaults.bool(forKey: self.allowSavingProtectedContentKey)
        }
        set {
            self.defaults.set(newValue, forKey: self.allowSavingProtectedContentKey)
            self.updatedPromise.set(true)
        }
    }

    public var voiceChangerMode: ToastVoiceChangerMode {
        get {
            if let rawValue = self.defaults.string(forKey: self.voiceChangerModeKey),
               let mode = ToastVoiceChangerMode(rawValue: rawValue) {
                return mode
            }
            return .off
        }
        set {
            self.defaults.set(newValue.rawValue, forKey: self.voiceChangerModeKey)
            self.updatedPromise.set(true)
        }
    }

    public var backgroundKeepAlive: Bool {
        get {
            return self.defaults.bool(forKey: self.backgroundKeepAliveKey)
        }
        set {
            self.defaults.set(newValue, forKey: self.backgroundKeepAliveKey)
            self.updatedPromise.set(true)
        }
    }

    public var localNotificationsEnabled: Bool {
        get {
            return self.defaults.bool(forKey: self.localNotificationsEnabledKey)
        }
        set {
            self.defaults.set(newValue, forKey: self.localNotificationsEnabledKey)
            self.updatedPromise.set(true)
        }
    }

    public func resetToDefaults() {
        self.saveDisappearingMedia = false
        self.allowScreenshots = false
        self.allowSavingProtectedContent = false
        self.voiceChangerMode = .off
        self.backgroundKeepAlive = true
        self.localNotificationsEnabled = true
        self.updatedPromise.set(true)
    }
}
