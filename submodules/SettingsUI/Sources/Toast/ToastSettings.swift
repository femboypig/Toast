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
    private let voiceChangerReverbKey = "Toast_voiceChangerReverb"
    private let voiceChangerRobotKey = "Toast_voiceChangerRobot"
    private let voiceChangerBassKey = "Toast_voiceChangerBass"
    private let voiceChangerDistortionKey = "Toast_voiceChangerDistortion"
    private let voiceChangerModeKey = "Toast_voiceChangerMode"
    private let backgroundKeepAliveKey = "Toast_backgroundKeepAlive"
    private let localNotificationsEnabledKey = "Toast_localNotificationsEnabled"
    private let blockChannelAdsKey = "Toast_blockChannelAds"
    private let blockProxySponsorKey = "Toast_blockProxySponsor"
    private let sendOriginalMediaKey = "Toast_sendOriginalMedia"
    private let freeVoiceToTextKey = "Toast_freeVoiceToText"
    private let forwardWithoutQuoteKey = "Toast_forwardWithoutQuote"
    private let fakePasscodeEnabledKey = "Toast_fakePasscodeEnabled"
    private let fakePasscodeKey = "Toast_fakePasscode"
    private let decoyChannelsOnlyKey = "Toast_decoyChannelsOnly"
    private let decoyHidePrivateChatsKey = "Toast_decoyHidePrivateChats"
    private let decoyHideSecretChatsKey = "Toast_decoyHideSecretChats"
    private let decoyHideChannelsKey = "Toast_decoyHideChannels"
    private let decoyHideGroupsKey = "Toast_decoyHideGroups"
    private let decoyHiddenPeerIdsKey = "Toast_decoyHiddenPeerIds"
    private let isDecoyActiveKey = "Toast_isDecoyActive"

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
            self.voiceChangerReverbKey: Float(0.0),
            self.voiceChangerRobotKey: Float(0.0),
            self.voiceChangerBassKey: Float(0.0),
            self.voiceChangerDistortionKey: Float(0.0),
            self.backgroundKeepAliveKey: true,
            self.localNotificationsEnabledKey: true,
            self.blockChannelAdsKey: true,
            self.blockProxySponsorKey: true,
            self.sendOriginalMediaKey: false,
            self.freeVoiceToTextKey: true,
            self.forwardWithoutQuoteKey: false,
            self.fakePasscodeEnabledKey: false,
            self.fakePasscodeKey: "",
            self.decoyChannelsOnlyKey: false,
            self.decoyHidePrivateChatsKey: false,
            self.decoyHideSecretChatsKey: true,
            self.decoyHideChannelsKey: false,
            self.decoyHideGroupsKey: false,
            self.decoyHiddenPeerIdsKey: [],
            self.isDecoyActiveKey: false
        ])
    }

    private func notifyUpdated() {
        self.updatedPromise.set(true)
        NotificationCenter.default.post(name: NSNotification.Name("ToastSettingsUpdated"), object: nil)
    }

    public var saveDisappearingMedia: Bool {
        get {
            return self.defaults.object(forKey: self.saveDisappearingMediaKey) as? Bool ?? true
        }
        set {
            self.defaults.set(newValue, forKey: self.saveDisappearingMediaKey)
            self.notifyUpdated()
        }
    }

    public var allowScreenshots: Bool {
        get {
            return self.defaults.object(forKey: self.allowScreenshotsKey) as? Bool ?? true
        }
        set {
            self.defaults.set(newValue, forKey: self.allowScreenshotsKey)
            self.notifyUpdated()
        }
    }

    public var allowSavingProtectedContent: Bool {
        get {
            return self.defaults.object(forKey: self.allowSavingProtectedContentKey) as? Bool ?? true
        }
        set {
            self.defaults.set(newValue, forKey: self.allowSavingProtectedContentKey)
            self.notifyUpdated()
        }
    }

    public var voiceChangerEnabled: Bool {
        get {
            return self.defaults.object(forKey: self.voiceChangerEnabledKey) as? Bool ?? false
        }
        set {
            self.defaults.set(newValue, forKey: self.voiceChangerEnabledKey)
            self.notifyUpdated()
        }
    }

    public var voiceChangerPitch: Float {
        get {
            return self.defaults.object(forKey: self.voiceChangerPitchKey) as? Float ?? 0.0
        }
        set {
            self.defaults.set(newValue, forKey: self.voiceChangerPitchKey)
            self.notifyUpdated()
        }
    }

    public var voiceChangerEcho: Float {
        get {
            return self.defaults.object(forKey: self.voiceChangerEchoKey) as? Float ?? 0.0
        }
        set {
            self.defaults.set(newValue, forKey: self.voiceChangerEchoKey)
            self.notifyUpdated()
        }
    }

    public var voiceChangerReverb: Float {
        get {
            return self.defaults.object(forKey: self.voiceChangerReverbKey) as? Float ?? 0.0
        }
        set {
            self.defaults.set(newValue, forKey: self.voiceChangerReverbKey)
            self.notifyUpdated()
        }
    }

    public var voiceChangerRobot: Float {
        get {
            return self.defaults.object(forKey: self.voiceChangerRobotKey) as? Float ?? 0.0
        }
        set {
            self.defaults.set(newValue, forKey: self.voiceChangerRobotKey)
            self.notifyUpdated()
        }
    }

    public var voiceChangerBass: Float {
        get {
            return self.defaults.object(forKey: self.voiceChangerBassKey) as? Float ?? 0.0
        }
        set {
            self.defaults.set(newValue, forKey: self.voiceChangerBassKey)
            self.notifyUpdated()
        }
    }

    public var voiceChangerDistortion: Float {
        get {
            return self.defaults.object(forKey: self.voiceChangerDistortionKey) as? Float ?? 0.0
        }
        set {
            self.defaults.set(newValue, forKey: self.voiceChangerDistortionKey)
            self.notifyUpdated()
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
            self.notifyUpdated()
        }
    }

    public var backgroundKeepAlive: Bool {
        get {
            return self.defaults.object(forKey: self.backgroundKeepAliveKey) as? Bool ?? true
        }
        set {
            self.defaults.set(newValue, forKey: self.backgroundKeepAliveKey)
            self.notifyUpdated()
        }
    }

    public var localNotificationsEnabled: Bool {
        get {
            return self.defaults.object(forKey: self.localNotificationsEnabledKey) as? Bool ?? true
        }
        set {
            self.defaults.set(newValue, forKey: self.localNotificationsEnabledKey)
            self.notifyUpdated()
        }
    }

    public var blockChannelAds: Bool {
        get {
            return self.defaults.object(forKey: self.blockChannelAdsKey) as? Bool ?? true
        }
        set {
            self.defaults.set(newValue, forKey: self.blockChannelAdsKey)
            self.notifyUpdated()
        }
    }

    public var blockProxySponsor: Bool {
        get {
            return self.defaults.object(forKey: self.blockProxySponsorKey) as? Bool ?? true
        }
        set {
            self.defaults.set(newValue, forKey: self.blockProxySponsorKey)
            self.notifyUpdated()
        }
    }

    public var sendOriginalMedia: Bool {
        get {
            return self.defaults.object(forKey: self.sendOriginalMediaKey) as? Bool ?? false
        }
        set {
            self.defaults.set(newValue, forKey: self.sendOriginalMediaKey)
            self.notifyUpdated()
        }
    }

    public var freeVoiceToText: Bool {
        get {
            return self.defaults.object(forKey: self.freeVoiceToTextKey) as? Bool ?? true
        }
        set {
            self.defaults.set(newValue, forKey: self.freeVoiceToTextKey)
            self.notifyUpdated()
        }
    }

    public var forwardWithoutQuote: Bool {
        get {
            return self.defaults.object(forKey: self.forwardWithoutQuoteKey) as? Bool ?? false
        }
        set {
            self.defaults.set(newValue, forKey: self.forwardWithoutQuoteKey)
            self.notifyUpdated()
        }
    }

    public var fakePasscodeEnabled: Bool {
        get {
            return self.defaults.object(forKey: self.fakePasscodeEnabledKey) as? Bool ?? false
        }
        set {
            self.defaults.set(newValue, forKey: self.fakePasscodeEnabledKey)
            self.notifyUpdated()
        }
    }

    public var fakePasscode: String {
        get {
            return self.defaults.string(forKey: self.fakePasscodeKey) ?? ""
        }
        set {
            self.defaults.set(newValue, forKey: self.fakePasscodeKey)
            self.notifyUpdated()
        }
    }

    public var decoyChannelsOnly: Bool {
        get {
            return self.defaults.object(forKey: self.decoyChannelsOnlyKey) as? Bool ?? false
        }
        set {
            self.defaults.set(newValue, forKey: self.decoyChannelsOnlyKey)
            self.notifyUpdated()
        }
    }

    public var decoyHidePrivateChats: Bool {
        get {
            return self.defaults.object(forKey: self.decoyHidePrivateChatsKey) as? Bool ?? false
        }
        set {
            self.defaults.set(newValue, forKey: self.decoyHidePrivateChatsKey)
            self.notifyUpdated()
        }
    }

    public var decoyHideSecretChats: Bool {
        get {
            return self.defaults.object(forKey: self.decoyHideSecretChatsKey) as? Bool ?? true
        }
        set {
            self.defaults.set(newValue, forKey: self.decoyHideSecretChatsKey)
            self.notifyUpdated()
        }
    }

    public var decoyHideChannels: Bool {
        get {
            return self.defaults.object(forKey: self.decoyHideChannelsKey) as? Bool ?? false
        }
        set {
            self.defaults.set(newValue, forKey: self.decoyHideChannelsKey)
            self.notifyUpdated()
        }
    }

    public var decoyHideGroups: Bool {
        get {
            return self.defaults.object(forKey: self.decoyHideGroupsKey) as? Bool ?? false
        }
        set {
            self.defaults.set(newValue, forKey: self.decoyHideGroupsKey)
            self.notifyUpdated()
        }
    }

    public var decoyHiddenPeerIds: [Int64] {
        get {
            return self.defaults.array(forKey: self.decoyHiddenPeerIdsKey) as? [Int64] ?? []
        }
        set {
            self.defaults.set(newValue, forKey: self.decoyHiddenPeerIdsKey)
            self.notifyUpdated()
        }
    }

    public func addDecoyHiddenPeerId(_ id: Int64) {
        var current = self.decoyHiddenPeerIds
        if !current.contains(id) {
            current.append(id)
            self.decoyHiddenPeerIds = current
        }
    }

    public func removeDecoyHiddenPeerId(_ id: Int64) {
        var current = self.decoyHiddenPeerIds
        if let index = current.firstIndex(of: id) {
            current.remove(at: index)
            self.decoyHiddenPeerIds = current
        }
    }

    public var isDecoyActive: Bool {
        get {
            return self.defaults.bool(forKey: self.isDecoyActiveKey)
        }
        set {
            self.defaults.set(newValue, forKey: self.isDecoyActiveKey)
            self.notifyUpdated()
        }
    }

    public func resetToDefaults() {
        self.saveDisappearingMedia = true
        self.allowScreenshots = true
        self.allowSavingProtectedContent = true
        self.voiceChangerEnabled = false
        self.voiceChangerPitch = 0.0
        self.voiceChangerEcho = 0.0
        self.voiceChangerReverb = 0.0
        self.voiceChangerRobot = 0.0
        self.voiceChangerBass = 0.0
        self.voiceChangerDistortion = 0.0
        self.voiceChangerMode = .off
        self.backgroundKeepAlive = true
        self.localNotificationsEnabled = true
        self.blockChannelAds = true
        self.blockProxySponsor = true
        self.sendOriginalMedia = false
        self.freeVoiceToText = true
        self.forwardWithoutQuote = false
        self.fakePasscodeEnabled = false
        self.fakePasscode = ""
        self.decoyChannelsOnly = false
        self.decoyHidePrivateChats = false
        self.decoyHideSecretChats = true
        self.decoyHideChannels = false
        self.decoyHideGroups = false
        self.decoyHiddenPeerIds = []
        self.isDecoyActive = false
        self.notifyUpdated()
    }
}
