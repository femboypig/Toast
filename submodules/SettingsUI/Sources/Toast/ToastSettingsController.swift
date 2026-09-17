import Foundation
import UIKit
import Display
import SwiftSignalKit
import TelegramCore
import TelegramPresentationData
import ItemListUI
import PresentationDataUtils
import AccountContext
import AlertUI

private final class ToastSettingsControllerArguments {
    let context: AccountContext
    let toggleSaveDisappearingMedia: (Bool) -> Void
    let toggleAllowScreenshots: (Bool) -> Void
    let toggleAllowSavingProtectedContent: (Bool) -> Void
    let toggleShowAvatarsInDirect: (Bool) -> Void
    let toggleBlockChannelAds: (Bool) -> Void
    let toggleSendOriginalMedia: (Bool) -> Void
    let toggleVoiceChangerEnabled: (Bool) -> Void
    let updateVoiceChangerPitch: (Float) -> Void
    let updateVoiceChangerEcho: (Float) -> Void
    let updateVoiceChangerReverb: (Float) -> Void
    let updateVoiceChangerRobot: (Float) -> Void
    let updateVoiceChangerBass: (Float) -> Void
    let updateVoiceChangerDistortion: (Float) -> Void
    let resetVoiceEffects: () -> Void
    let openBypassLevelPicker: () -> Void
    let toggleBackgroundKeepAlive: (Bool) -> Void
    let toggleLocalNotifications: (Bool) -> Void
    let openAppearance: () -> Void
    let resetDefaults: () -> Void

    init(
        context: AccountContext,
        toggleSaveDisappearingMedia: @escaping (Bool) -> Void,
        toggleAllowScreenshots: @escaping (Bool) -> Void,
        toggleAllowSavingProtectedContent: @escaping (Bool) -> Void,
        toggleShowAvatarsInDirect: @escaping (Bool) -> Void,
        toggleBlockChannelAds: @escaping (Bool) -> Void,
        toggleSendOriginalMedia: @escaping (Bool) -> Void,
        toggleVoiceChangerEnabled: @escaping (Bool) -> Void,
        updateVoiceChangerPitch: @escaping (Float) -> Void,
        updateVoiceChangerEcho: @escaping (Float) -> Void,
        updateVoiceChangerReverb: @escaping (Float) -> Void,
        updateVoiceChangerRobot: @escaping (Float) -> Void,
        updateVoiceChangerBass: @escaping (Float) -> Void,
        updateVoiceChangerDistortion: @escaping (Float) -> Void,
        resetVoiceEffects: @escaping () -> Void,
        openBypassLevelPicker: @escaping () -> Void,
        toggleBackgroundKeepAlive: @escaping (Bool) -> Void,
        toggleLocalNotifications: @escaping (Bool) -> Void,
        openAppearance: @escaping () -> Void,
        resetDefaults: @escaping () -> Void
    ) {
        self.context = context
        self.toggleSaveDisappearingMedia = toggleSaveDisappearingMedia
        self.toggleAllowScreenshots = toggleAllowScreenshots
        self.toggleAllowSavingProtectedContent = toggleAllowSavingProtectedContent
        self.toggleShowAvatarsInDirect = toggleShowAvatarsInDirect
        self.toggleBlockChannelAds = toggleBlockChannelAds
        self.toggleSendOriginalMedia = toggleSendOriginalMedia
        self.toggleVoiceChangerEnabled = toggleVoiceChangerEnabled
        self.updateVoiceChangerPitch = updateVoiceChangerPitch
        self.updateVoiceChangerEcho = updateVoiceChangerEcho
        self.updateVoiceChangerReverb = updateVoiceChangerReverb
        self.updateVoiceChangerRobot = updateVoiceChangerRobot
        self.updateVoiceChangerBass = updateVoiceChangerBass
        self.updateVoiceChangerDistortion = updateVoiceChangerDistortion
        self.resetVoiceEffects = resetVoiceEffects
        self.openBypassLevelPicker = openBypassLevelPicker
        self.toggleBackgroundKeepAlive = toggleBackgroundKeepAlive
        self.toggleLocalNotifications = toggleLocalNotifications
        self.openAppearance = openAppearance
        self.resetDefaults = resetDefaults
    }
}

private enum ToastSettingsSection: ItemListSectionId {
    case mediaPrivacy
    case voiceChanger
    case censorship
    case background
    case icons
    case reset
}

private enum ToastSettingsEntry: ItemListNodeEntry {
    case mediaPrivacyHeader(String)
    case saveDisappearingMedia(String, Bool)
    case saveDisappearingMediaInfo(String)
    case allowScreenshots(String, Bool)
    case allowScreenshotsInfo(String)
    case allowSavingProtectedContent(String, Bool)
    case allowSavingProtectedContentInfo(String)
    case showAvatarsInDirect(String, Bool)
    case showAvatarsInDirectInfo(String)
    case blockChannelAds(String, Bool)
    case blockChannelAdsInfo(String)
    case sendOriginalMedia(String, Bool)
    case sendOriginalMediaInfo(String)

    case voiceChangerHeader(String)
    case voiceChangerEnabled(String, Bool)
    case voiceChangerPitch(String, String, Float)
    case voiceChangerEcho(String, String, Float)
    case voiceChangerReverb(String, String, Float)
    case voiceChangerRobot(String, String, Float)
    case voiceChangerBass(String, String, Float)
    case voiceChangerDistortion(String, String, Float)
    case voiceChangerReset(String)
    case voiceChangerInfo(String)

    case censorshipHeader(String)
    case censorshipLevel(String, String)
    case censorshipInfo(String)

    case backgroundHeader(String)
    case backgroundKeepAlive(String, Bool)
    case backgroundKeepAliveInfo(String)
    case localNotifications(String, Bool)
    case localNotificationsInfo(String)

    case iconsHeader(String)
    case iconsDisclosure(String, String)
    case iconsInfo(String)

    case reset(String)

    var section: ItemListSectionId {
        switch self {
        case .mediaPrivacyHeader, .saveDisappearingMedia, .saveDisappearingMediaInfo, .allowScreenshots, .allowScreenshotsInfo, .allowSavingProtectedContent, .allowSavingProtectedContentInfo, .showAvatarsInDirect, .showAvatarsInDirectInfo, .blockChannelAds, .blockChannelAdsInfo, .sendOriginalMedia, .sendOriginalMediaInfo:
            return ToastSettingsSection.mediaPrivacy.rawValue
        case .voiceChangerHeader, .voiceChangerEnabled, .voiceChangerPitch, .voiceChangerEcho, .voiceChangerReverb, .voiceChangerRobot, .voiceChangerBass, .voiceChangerDistortion, .voiceChangerReset, .voiceChangerInfo:
            return ToastSettingsSection.voiceChanger.rawValue
        case .censorshipHeader, .censorshipLevel, .censorshipInfo:
            return ToastSettingsSection.censorship.rawValue
        case .backgroundHeader, .backgroundKeepAlive, .backgroundKeepAliveInfo, .localNotifications, .localNotificationsInfo:
            return ToastSettingsSection.background.rawValue
        case .iconsHeader, .iconsDisclosure, .iconsInfo:
            return ToastSettingsSection.icons.rawValue
        case .reset:
            return ToastSettingsSection.reset.rawValue
        }
    }

    var stableId: Int32 {
        switch self {
        case .mediaPrivacyHeader:
            return 0
        case .saveDisappearingMedia:
            return 1
        case .saveDisappearingMediaInfo:
            return 2
        case .allowScreenshots:
            return 3
        case .allowScreenshotsInfo:
            return 4
        case .allowSavingProtectedContent:
            return 5
        case .allowSavingProtectedContentInfo:
            return 6
        case .showAvatarsInDirect:
            return 7
        case .showAvatarsInDirectInfo:
            return 8
        case .blockChannelAds:
            return 9
        case .blockChannelAdsInfo:
            return 10
        case .sendOriginalMedia:
            return 11
        case .sendOriginalMediaInfo:
            return 12
        case .voiceChangerHeader:
            return 20
        case .voiceChangerEnabled:
            return 21
        case .voiceChangerPitch:
            return 22
        case .voiceChangerEcho:
            return 23
        case .voiceChangerReverb:
            return 24
        case .voiceChangerRobot:
            return 25
        case .voiceChangerBass:
            return 26
        case .voiceChangerDistortion:
            return 27
        case .voiceChangerReset:
            return 28
        case .voiceChangerInfo:
            return 29
        case .censorshipHeader:
            return 30
        case .censorshipLevel:
            return 31
        case .censorshipInfo:
            return 32
        case .backgroundHeader:
            return 40
        case .backgroundKeepAlive:
            return 41
        case .backgroundKeepAliveInfo:
            return 42
        case .localNotifications:
            return 43
        case .localNotificationsInfo:
            return 44
        case .iconsHeader:
            return 50
        case .iconsDisclosure:
            return 51
        case .iconsInfo:
            return 52
        case .reset:
            return 60
        }
    }

    static func <(lhs: ToastSettingsEntry, rhs: ToastSettingsEntry) -> Bool {
        return lhs.stableId < rhs.stableId
    }

    func item(presentationData: ItemListPresentationData, arguments: Any) -> ListViewItem {
        let args = arguments as! ToastSettingsControllerArguments
        switch self {
        case let .mediaPrivacyHeader(text):
            return ItemListSectionHeaderItem(presentationData: presentationData, text: text, sectionId: self.section)
        case let .saveDisappearingMedia(title, value):
            return ItemListSwitchItem(presentationData: presentationData, title: title, value: value, sectionId: self.section, style: .blocks, updated: { value in
                args.toggleSaveDisappearingMedia(value)
            })
        case let .saveDisappearingMediaInfo(text):
            return ItemListTextItem(presentationData: presentationData, text: .plain(text), sectionId: self.section)
        case let .allowScreenshots(title, value):
            return ItemListSwitchItem(presentationData: presentationData, title: title, value: value, sectionId: self.section, style: .blocks, updated: { value in
                args.toggleAllowScreenshots(value)
            })
        case let .allowScreenshotsInfo(text):
            return ItemListTextItem(presentationData: presentationData, text: .plain(text), sectionId: self.section)
        case let .allowSavingProtectedContent(title, value):
            return ItemListSwitchItem(presentationData: presentationData, title: title, value: value, sectionId: self.section, style: .blocks, updated: { value in
                args.toggleAllowSavingProtectedContent(value)
            })
        case let .allowSavingProtectedContentInfo(text):
            return ItemListTextItem(presentationData: presentationData, text: .plain(text), sectionId: self.section)
        case let .showAvatarsInDirect(title, value):
            return ItemListSwitchItem(presentationData: presentationData, title: title, value: value, sectionId: self.section, style: .blocks, updated: { value in
                args.toggleShowAvatarsInDirect(value)
            })
        case let .showAvatarsInDirectInfo(text):
            return ItemListTextItem(presentationData: presentationData, text: .plain(text), sectionId: self.section)
        case let .blockChannelAds(title, value):
            return ItemListSwitchItem(presentationData: presentationData, title: title, value: value, sectionId: self.section, style: .blocks, updated: { value in
                args.toggleBlockChannelAds(value)
            })
        case let .blockChannelAdsInfo(text):
            return ItemListTextItem(presentationData: presentationData, text: .plain(text), sectionId: self.section)
        case let .sendOriginalMedia(title, value):
            return ItemListSwitchItem(presentationData: presentationData, title: title, value: value, sectionId: self.section, style: .blocks, updated: { value in
                args.toggleSendOriginalMedia(value)
            })
        case let .sendOriginalMediaInfo(text):
            return ItemListTextItem(presentationData: presentationData, text: .plain(text), sectionId: self.section)

        case let .voiceChangerHeader(text):
            return ItemListSectionHeaderItem(presentationData: presentationData, text: text, sectionId: self.section)
        case let .voiceChangerEnabled(title, value):
            return ItemListSwitchItem(presentationData: presentationData, title: title, value: value, sectionId: self.section, style: .blocks, updated: { value in
                args.toggleVoiceChangerEnabled(value)
            })
        case let .voiceChangerPitch(title, valueText, value):
            return ToastSliderItem(
                presentationData: presentationData,
                title: title,
                valueText: valueText,
                minValue: -12.0,
                maxValue: 12.0,
                value: value,
                sectionId: self.section,
                updated: { value in
                    args.updateVoiceChangerPitch(round(value))
                }
            )
        case let .voiceChangerEcho(title, valueText, value):
            return ToastSliderItem(
                presentationData: presentationData,
                title: title,
                valueText: valueText,
                minValue: 0.0,
                maxValue: 1.0,
                value: value,
                sectionId: self.section,
                updated: { value in
                    args.updateVoiceChangerEcho(round(value * 20.0) / 20.0)
                }
            )
        case let .voiceChangerReverb(title, valueText, value):
            return ToastSliderItem(
                presentationData: presentationData,
                title: title,
                valueText: valueText,
                minValue: 0.0,
                maxValue: 1.0,
                value: value,
                sectionId: self.section,
                updated: { value in
                    args.updateVoiceChangerReverb(round(value * 20.0) / 20.0)
                }
            )
        case let .voiceChangerRobot(title, valueText, value):
            return ToastSliderItem(
                presentationData: presentationData,
                title: title,
                valueText: valueText,
                minValue: 0.0,
                maxValue: 1.0,
                value: value,
                sectionId: self.section,
                updated: { value in
                    args.updateVoiceChangerRobot(round(value * 20.0) / 20.0)
                }
            )
        case let .voiceChangerBass(title, valueText, value):
            return ToastSliderItem(
                presentationData: presentationData,
                title: title,
                valueText: valueText,
                minValue: -12.0,
                maxValue: 12.0,
                value: value,
                sectionId: self.section,
                updated: { value in
                    args.updateVoiceChangerBass(round(value))
                }
            )
        case let .voiceChangerDistortion(title, valueText, value):
            return ToastSliderItem(
                presentationData: presentationData,
                title: title,
                valueText: valueText,
                minValue: 0.0,
                maxValue: 1.0,
                value: value,
                sectionId: self.section,
                updated: { value in
                    args.updateVoiceChangerDistortion(round(value * 20.0) / 20.0)
                }
            )
        case let .voiceChangerReset(title):
            return ItemListActionItem(presentationData: presentationData, title: title, kind: .generic, alignment: .center, sectionId: self.section, style: .blocks, action: {
                args.resetVoiceEffects()
            })
        case let .voiceChangerInfo(text):
            return ItemListTextItem(presentationData: presentationData, text: .plain(text), sectionId: self.section)

        case let .censorshipHeader(text):
            return ItemListSectionHeaderItem(presentationData: presentationData, text: text, sectionId: self.section)
        case let .censorshipLevel(title, value):
            return ItemListDisclosureItem(presentationData: presentationData, title: title, label: value, sectionId: self.section, style: .blocks, action: {
                args.openBypassLevelPicker()
            })
        case let .censorshipInfo(text):
            return ItemListTextItem(presentationData: presentationData, text: .plain(text), sectionId: self.section)

        case let .backgroundHeader(text):
            return ItemListSectionHeaderItem(presentationData: presentationData, text: text, sectionId: self.section)
        case let .backgroundKeepAlive(title, value):
            return ItemListSwitchItem(presentationData: presentationData, title: title, value: value, sectionId: self.section, style: .blocks, updated: { value in
                args.toggleBackgroundKeepAlive(value)
            })
        case let .backgroundKeepAliveInfo(text):
            return ItemListTextItem(presentationData: presentationData, text: .plain(text), sectionId: self.section)
        case let .localNotifications(title, value):
            return ItemListSwitchItem(presentationData: presentationData, title: title, value: value, sectionId: self.section, style: .blocks, updated: { value in
                args.toggleLocalNotifications(value)
            })
        case let .localNotificationsInfo(text):
            return ItemListTextItem(presentationData: presentationData, text: .plain(text), sectionId: self.section)

        case let .iconsHeader(text):
            return ItemListSectionHeaderItem(presentationData: presentationData, text: text, sectionId: self.section)
        case let .iconsDisclosure(title, value):
            return ItemListDisclosureItem(presentationData: presentationData, title: title, label: value, sectionId: self.section, style: .blocks, action: {
                args.openAppearance()
            })
        case let .iconsInfo(text):
            return ItemListTextItem(presentationData: presentationData, text: .plain(text), sectionId: self.section)

        case let .reset(title):
            return ItemListActionItem(presentationData: presentationData, title: title, kind: .destructive, alignment: .center, sectionId: self.section, style: .blocks, action: {
                args.resetDefaults()
            })
        }
    }
}

private func toastSettingsEntries(settings: ToastSettings) -> [ToastSettingsEntry] {
    var entries: [ToastSettingsEntry] = []

    entries.append(.mediaPrivacyHeader("MEDIA & PRIVACY"))
    entries.append(.saveDisappearingMedia("Save Disappearing Media", settings.saveDisappearingMedia))
    entries.append(.saveDisappearingMediaInfo("Prevents disappearing and self-destructing media from deleting automatically and allows saving them directly from the viewer."))
    entries.append(.allowScreenshots("Allow Screenshots & Recording", settings.allowScreenshots))
    entries.append(.allowScreenshotsInfo("Bypasses screenshot and screen recording blocking across secret chats and protected content without blacking out."))
    entries.append(.allowSavingProtectedContent("Bypass Copy Protection", settings.allowSavingProtectedContent))
    entries.append(.allowSavingProtectedContentInfo("Enables saving media, copying text, and forwarding messages from channels and chats with content protection enabled."))
    entries.append(.showAvatarsInDirect("Avatars in Direct Chats", settings.showAvatarsInDirectChats))
    entries.append(.showAvatarsInDirectInfo("Displays user avatars next to incoming messages in 1-on-1 private conversations."))
    entries.append(.blockChannelAds("Block Sponsored Posts", settings.blockChannelAds))
    entries.append(.blockChannelAdsInfo("Completely removes sponsored advertisements and promotional posts from channels."))
    entries.append(.sendOriginalMedia("Send Original Quality Media", settings.sendOriginalMedia))
    entries.append(.sendOriginalMediaInfo("Automatically sends photos and videos in original uncompressed resolution by default."))

    entries.append(.voiceChangerHeader("VOICE CHANGER"))
    entries.append(.voiceChangerEnabled("Enable Voice Changer", settings.voiceChangerEnabled))
    if settings.voiceChangerEnabled {
        let pitch = settings.voiceChangerPitch
        let pitchText: String
        if Int(pitch) == 0 {
            pitchText = "0 (Normal)"
        } else if pitch > 0 {
            pitchText = "+\(Int(pitch)) st"
        } else {
            pitchText = "\(Int(pitch)) st"
        }
        entries.append(.voiceChangerPitch("Pitch Shift", pitchText, pitch))

        let echo = settings.voiceChangerEcho
        let echoText = "\(Int(echo * 100.0))%"
        entries.append(.voiceChangerEcho("Echo / Delay", echoText, echo))

        let reverb = settings.voiceChangerReverb
        let reverbText = "\(Int(reverb * 100.0))%"
        entries.append(.voiceChangerReverb("Reverb / Space", reverbText, reverb))

        let robot = settings.voiceChangerRobot
        let robotText = "\(Int(robot * 100.0))%"
        entries.append(.voiceChangerRobot("Robot / Cyber Mod", robotText, robot))

        let bass = settings.voiceChangerBass
        let bassText: String
        if Int(bass) == 0 {
            bassText = "0 dB"
        } else if bass > 0 {
            bassText = "+\(Int(bass)) dB"
        } else {
            bassText = "\(Int(bass)) dB"
        }
        entries.append(.voiceChangerBass("Bass Boost", bassText, bass))

        let distortion = settings.voiceChangerDistortion
        let distText = "\(Int(distortion * 100.0))%"
        entries.append(.voiceChangerDistortion("Warm Overdrive", distText, distortion))

        entries.append(.voiceChangerReset("Reset Voice Effects to Zero"))
    }
    entries.append(.voiceChangerInfo("Transforms your voice in real time with continuous pitch shift, echo delay, multi-tap reverb, cyber modulation, bass boost, and overdrive saturation."))

    entries.append(.censorshipHeader("CENSORSHIP BYPASS / ОБХОД БЛОКИРОВОК"))
    entries.append(.censorshipLevel("Bypass Level", settings.bypassLevel.title))
    entries.append(.censorshipInfo("Anti-censorship intensity modes:\n• Disabled: Standard connection without routing\n• Low: Encrypted DNS-over-HTTPS (Cloudflare 1.1.1.1 & Google 8.8.8.8 direct-IP)\n• Medium: DoH + Initial TCP handshake packet splitting (DPI/TSPU evasion)\n• Max: Full bypass — DoH + TCP splitting + Auto-rotating built-in Fake-TLS MTProxy pool with latency health checks"))

    entries.append(.backgroundHeader("NOTIFICATIONS & BACKGROUND"))
    entries.append(.backgroundKeepAlive("Keep Connection in Background", settings.backgroundKeepAlive))
    entries.append(.backgroundKeepAliveInfo("Maintains the MTProto connection in the background so updates arrive continuously without APNs certificates."))
    entries.append(.localNotifications("Local Notifications", settings.localNotificationsEnabled))
    entries.append(.localNotificationsInfo("Delivers rich native local notification banners with sender and media preview when Telegram is in the background."))

    entries.append(.iconsHeader("APP ICONS"))
    entries.append(.iconsDisclosure("Appearance & Icons", "Toast"))
    entries.append(.iconsInfo("Switch between Toast, Toast Slice, Femboy Toast, or classic Telegram icons in Appearance settings."))

    entries.append(.reset("Reset Toast Settings"))

    return entries
}

public func toastSettingsController(context: AccountContext) -> ViewController {
    var pushControllerImpl: ((ViewController) -> Void)?
    var presentControllerImpl: ((ViewController, Any?) -> Void)?

    let arguments = ToastSettingsControllerArguments(
        context: context,
        toggleSaveDisappearingMedia: { value in
            ToastSettings.shared.saveDisappearingMedia = value
        },
        toggleAllowScreenshots: { value in
            ToastSettings.shared.allowScreenshots = value
        },
        toggleAllowSavingProtectedContent: { value in
            ToastSettings.shared.allowSavingProtectedContent = value
        },
        toggleShowAvatarsInDirect: { value in
            ToastSettings.shared.showAvatarsInDirectChats = value
        },
        toggleBlockChannelAds: { value in
            ToastSettings.shared.blockChannelAds = value
        },
        toggleSendOriginalMedia: { value in
            ToastSettings.shared.sendOriginalMedia = value
        },
        toggleVoiceChangerEnabled: { value in
            ToastSettings.shared.voiceChangerEnabled = value
        },
        updateVoiceChangerPitch: { value in
            ToastSettings.shared.voiceChangerPitch = value
        },
        updateVoiceChangerEcho: { value in
            ToastSettings.shared.voiceChangerEcho = value
        },
        updateVoiceChangerReverb: { value in
            ToastSettings.shared.voiceChangerReverb = value
        },
        updateVoiceChangerRobot: { value in
            ToastSettings.shared.voiceChangerRobot = value
        },
        updateVoiceChangerBass: { value in
            ToastSettings.shared.voiceChangerBass = value
        },
        updateVoiceChangerDistortion: { value in
            ToastSettings.shared.voiceChangerDistortion = value
        },
        resetVoiceEffects: {
            ToastSettings.shared.voiceChangerPitch = 0.0
            ToastSettings.shared.voiceChangerEcho = 0.0
            ToastSettings.shared.voiceChangerReverb = 0.0
            ToastSettings.shared.voiceChangerRobot = 0.0
            ToastSettings.shared.voiceChangerBass = 0.0
            ToastSettings.shared.voiceChangerDistortion = 0.0
        },
        openBypassLevelPicker: {
            let presentationData = context.sharedContext.currentPresentationData.with { $0 }
            let actionSheet = ActionSheetController(presentationData: presentationData)
            var items: [ActionSheetItem] = [
                ActionSheetTextItem(title: "Select Anti-Censorship Level")
            ]
            for level in ToastBypassLevel.allCases {
                let isSelected = (level == ToastSettings.shared.bypassLevel)
                let title = (isSelected ? "✓  " : "") + level.title
                items.append(ActionSheetButtonItem(title: title, color: .accent, action: { [weak actionSheet] in
                    actionSheet?.dismissAnimated()
                    ToastSettings.shared.bypassLevel = level
                }))
            }
            actionSheet.setItemGroups([
                ActionSheetItemGroup(items: items),
                ActionSheetItemGroup(items: [
                    ActionSheetButtonItem(title: presentationData.strings.Common_Cancel, color: .accent, font: .bold, action: { [weak actionSheet] in
                        actionSheet?.dismissAnimated()
                    })
                ])
            ])
            presentControllerImpl?(actionSheet, nil)
        },
        toggleBackgroundKeepAlive: { value in
            ToastSettings.shared.backgroundKeepAlive = value
            ToastBackgroundKeepAlive.shared.updateState()
        },
        toggleLocalNotifications: { value in
            ToastSettings.shared.localNotificationsEnabled = value
        },
        openAppearance: {
            pushControllerImpl?(themeSettingsController(context: context))
        },
        resetDefaults: {
            let presentationData = context.sharedContext.currentPresentationData.with { $0 }
            let alert = textAlertController(
                context: context,
                title: "Reset Toast Settings",
                text: "Are you sure you want to reset all Toast modifications to default values?",
                actions: [
                    TextAlertAction(type: .defaultAction, title: presentationData.strings.Common_Cancel, action: {}),
                    TextAlertAction(type: .destructiveAction, title: "Reset", action: {
                        ToastSettings.shared.resetToDefaults()
                        ToastBackgroundKeepAlive.shared.updateState()
                    })
                ]
            )
            presentControllerImpl?(alert, nil)
        }
    )

    let signal = combineLatest(
        context.sharedContext.presentationData,
        ToastSettings.shared.updated
    )
    |> map { presentationData, _ -> (ItemListControllerState, (ItemListNodeState, Any)) in
        let entries = toastSettingsEntries(settings: ToastSettings.shared)
        let controllerState = ItemListControllerState(
            presentationData: ItemListPresentationData(presentationData),
            title: .text("Toast"),
            leftNavigationButton: nil,
            rightNavigationButton: nil,
            backNavigationButton: ItemListBackButton(title: presentationData.strings.Common_Back)
        )
        let listState = ItemListNodeState(
            presentationData: ItemListPresentationData(presentationData),
            entries: entries,
            style: .blocks,
            animateChanges: true
        )
        return (controllerState, (listState, arguments))
    }

    let controller = ItemListController(context: context, state: signal)
    pushControllerImpl = { [weak controller] c in
        controller?.push(c)
    }
    presentControllerImpl = { [weak controller] c, a in
        controller?.present(c, in: .window(.root), with: a)
    }
    return controller
}
