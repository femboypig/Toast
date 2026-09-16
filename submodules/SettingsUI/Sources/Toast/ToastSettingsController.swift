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
    let selectVoiceChangerMode: () -> Void
    let toggleBackgroundKeepAlive: (Bool) -> Void
    let toggleLocalNotifications: (Bool) -> Void
    let openAppearance: () -> Void
    let resetDefaults: () -> Void

    init(
        context: AccountContext,
        toggleSaveDisappearingMedia: @escaping (Bool) -> Void,
        toggleAllowScreenshots: @escaping (Bool) -> Void,
        toggleAllowSavingProtectedContent: @escaping (Bool) -> Void,
        selectVoiceChangerMode: @escaping () -> Void,
        toggleBackgroundKeepAlive: @escaping (Bool) -> Void,
        toggleLocalNotifications: @escaping (Bool) -> Void,
        openAppearance: @escaping () -> Void,
        resetDefaults: @escaping () -> Void
    ) {
        self.context = context
        self.toggleSaveDisappearingMedia = toggleSaveDisappearingMedia
        self.toggleAllowScreenshots = toggleAllowScreenshots
        self.toggleAllowSavingProtectedContent = toggleAllowSavingProtectedContent
        self.selectVoiceChangerMode = selectVoiceChangerMode
        self.toggleBackgroundKeepAlive = toggleBackgroundKeepAlive
        self.toggleLocalNotifications = toggleLocalNotifications
        self.openAppearance = openAppearance
        self.resetDefaults = resetDefaults
    }
}

private enum ToastSettingsSection: ItemListSectionId {
    case mediaPrivacy
    case voiceChanger
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

    case voiceChangerHeader(String)
    case voiceChangerMode(String, String)
    case voiceChangerInfo(String)

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
        case .mediaPrivacyHeader, .saveDisappearingMedia, .saveDisappearingMediaInfo, .allowScreenshots, .allowScreenshotsInfo, .allowSavingProtectedContent, .allowSavingProtectedContentInfo:
            return ToastSettingsSection.mediaPrivacy.rawValue
        case .voiceChangerHeader, .voiceChangerMode, .voiceChangerInfo:
            return ToastSettingsSection.voiceChanger.rawValue
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
        case .voiceChangerHeader:
            return 10
        case .voiceChangerMode:
            return 11
        case .voiceChangerInfo:
            return 12
        case .backgroundHeader:
            return 20
        case .backgroundKeepAlive:
            return 21
        case .backgroundKeepAliveInfo:
            return 22
        case .localNotifications:
            return 23
        case .localNotificationsInfo:
            return 24
        case .iconsHeader:
            return 30
        case .iconsDisclosure:
            return 31
        case .iconsInfo:
            return 32
        case .reset:
            return 40
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

        case let .voiceChangerHeader(text):
            return ItemListSectionHeaderItem(presentationData: presentationData, text: text, sectionId: self.section)
        case let .voiceChangerMode(title, value):
            return ItemListDisclosureItem(presentationData: presentationData, title: title, label: value, sectionId: self.section, style: .blocks, action: {
                args.selectVoiceChangerMode()
            })
        case let .voiceChangerInfo(text):
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

    entries.append(.voiceChangerHeader("VOICE CHANGER"))
    entries.append(.voiceChangerMode("Voice Effect", settings.voiceChangerMode.title))
    entries.append(.voiceChangerInfo("Transforms your voice in real time for recorded voice messages before sending."))

    entries.append(.backgroundHeader("NOTIFICATIONS & BACKGROUND"))
    entries.append(.backgroundKeepAlive("Keep Connection in Background", settings.backgroundKeepAlive))
    entries.append(.backgroundKeepAliveInfo("Maintains the MTProto connection in the background so updates arrive even when running without Apple Developer Account / APNs."))
    entries.append(.localNotifications("Local Notifications", settings.localNotificationsEnabled))
    entries.append(.localNotificationsInfo("Delivers local system notification banners for incoming messages when Telegram is backgrounded without APNs push certificates."))

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
        selectVoiceChangerMode: {
            let presentationData = context.sharedContext.currentPresentationData.with { $0 }
            let actionSheet = ActionSheetController(presentationData: presentationData)
            var items: [ActionSheetItem] = []

            for mode in ToastVoiceChangerMode.allCases {
                items.append(ActionSheetButtonItem(title: mode.title, color: .accent, action: { [weak actionSheet] in
                    actionSheet?.dismissAnimated()
                    ToastSettings.shared.voiceChangerMode = mode
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
