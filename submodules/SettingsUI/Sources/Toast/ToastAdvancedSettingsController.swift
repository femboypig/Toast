import Foundation
import UIKit
import Display
import SwiftSignalKit
import Postbox
import TelegramCore
import TelegramPresentationData
import ItemListUI
import PresentationDataUtils
import AccountContext
import TextFormat
import AlertUI

private final class ToastAdvancedSettingsControllerArguments {
    let context: AccountContext
    let toggleBackgroundKeepAlive: (Bool) -> Void
    let toggleLocalNotifications: (Bool) -> Void
    let resetDefaults: () -> Void

    init(
        context: AccountContext,
        toggleBackgroundKeepAlive: @escaping (Bool) -> Void,
        toggleLocalNotifications: @escaping (Bool) -> Void,
        resetDefaults: @escaping () -> Void
    ) {
        self.context = context
        self.toggleBackgroundKeepAlive = toggleBackgroundKeepAlive
        self.toggleLocalNotifications = toggleLocalNotifications
        self.resetDefaults = resetDefaults
    }
}

private enum ToastAdvancedSection: Int32 {
    case background
    case reset
}

private enum ToastAdvancedEntryStableId: Hashable {
    case backgroundHeader
    case backgroundKeepAlive
    case backgroundKeepAliveInfo
    case localNotifications
    case localNotificationsInfo

    case resetHeader
    case resetAction
    case resetInfo
}

private enum ToastAdvancedEntry: ItemListNodeEntry {
    case backgroundHeader(String)
    case backgroundKeepAlive(String, Bool)
    case backgroundKeepAliveInfo(String)
    case localNotifications(String, Bool)
    case localNotificationsInfo(String)

    case resetAction(String)
    case resetInfo(String)

    var section: ItemListSectionId {
        switch self {
        case .backgroundHeader, .backgroundKeepAlive, .backgroundKeepAliveInfo, .localNotifications, .localNotificationsInfo:
            return ToastAdvancedSection.background.rawValue
        case .resetAction, .resetInfo:
            return ToastAdvancedSection.reset.rawValue
        }
    }

    var stableId: ToastAdvancedEntryStableId {
        switch self {
        case .backgroundHeader:
            return .backgroundHeader
        case .backgroundKeepAlive:
            return .backgroundKeepAlive
        case .backgroundKeepAliveInfo:
            return .backgroundKeepAliveInfo
        case .localNotifications:
            return .localNotifications
        case .localNotificationsInfo:
            return .localNotificationsInfo
        case .resetAction:
            return .resetAction
        case .resetInfo:
            return .resetInfo
        }
    }

    static func ==(lhs: ToastAdvancedEntry, rhs: ToastAdvancedEntry) -> Bool {
        switch (lhs, rhs) {
        case let (.backgroundHeader(lhsText), .backgroundHeader(rhsText)):
            return lhsText == rhsText
        case let (.backgroundKeepAlive(lhsText, lhsValue), .backgroundKeepAlive(rhsText, rhsValue)):
            return lhsText == rhsText && lhsValue == rhsValue
        case let (.backgroundKeepAliveInfo(lhsText), .backgroundKeepAliveInfo(rhsText)):
            return lhsText == rhsText
        case let (.localNotifications(lhsText, lhsValue), .localNotifications(rhsText, rhsValue)):
            return lhsText == rhsText && lhsValue == rhsValue
        case let (.localNotificationsInfo(lhsText), .localNotificationsInfo(rhsText)):
            return lhsText == rhsText
        case let (.resetAction(lhsText), .resetAction(rhsText)):
            return lhsText == rhsText
        case let (.resetInfo(lhsText), .resetInfo(rhsText)):
            return lhsText == rhsText
        default:
            return false
        }
    }

    static func <(lhs: ToastAdvancedEntry, rhs: ToastAdvancedEntry) -> Bool {
        return lhs.stableId.hashValue < rhs.stableId.hashValue
    }

    func item(presentationData: ItemListPresentationData, arguments: Any) -> ListViewItem {
        let args = arguments as! ToastAdvancedSettingsControllerArguments
        switch self {
        case let .backgroundHeader(title):
            return ItemListSectionHeaderItem(presentationData: presentationData, text: title, sectionId: self.section)
        case let .backgroundKeepAlive(title, value):
            return ItemListSwitchItem(presentationData: presentationData, title: title, value: value, sectionId: self.section, style: .blocks, updated: { updatedValue in
                args.toggleBackgroundKeepAlive(updatedValue)
            })
        case let .backgroundKeepAliveInfo(text):
            return ItemListTextItem(presentationData: presentationData, text: .plain(text), sectionId: self.section)
        case let .localNotifications(title, value):
            return ItemListSwitchItem(presentationData: presentationData, title: title, value: value, sectionId: self.section, style: .blocks, updated: { updatedValue in
                args.toggleLocalNotifications(updatedValue)
            })
        case let .localNotificationsInfo(text):
            return ItemListTextItem(presentationData: presentationData, text: .plain(text), sectionId: self.section)

        case let .resetAction(title):
            return ItemListActionItem(presentationData: presentationData, title: title, kind: .destructive, alignment: .natural, sectionId: self.section, style: .blocks, action: {
                args.resetDefaults()
            })
        case let .resetInfo(text):
            return ItemListTextItem(presentationData: presentationData, text: .plain(text), sectionId: self.section)
        }
    }
}

private func toastAdvancedEntries(presentationData: PresentationData, settings: ToastSettings) -> [ToastAdvancedEntry] {
    var entries: [ToastAdvancedEntry] = []

    // Background Keep-Alive & Local Notifications
    entries.append(.backgroundHeader("BACKGROUND ACTIVITY"))
    entries.append(.backgroundKeepAlive("Background Keep-Alive", settings.backgroundKeepAlive))
    entries.append(.backgroundKeepAliveInfo("Maintains network connectivity in background to prevent missed calls and delay in incoming notifications."))
    entries.append(.localNotifications("Local Notification Sound", settings.localNotificationsEnabled))
    entries.append(.localNotificationsInfo("Uses custom tones for incoming local notifications."))

    // Reset All Settings
    entries.append(.resetAction("Reset All Settings to Default"))
    entries.append(.resetInfo("Restores all Toast modifications and customization options to their original default values."))

    return entries
}

public func toastAdvancedSettingsController(context: AccountContext) -> ViewController {
    var presentControllerImpl: ((ViewController, Any?) -> Void)?

    let arguments = ToastAdvancedSettingsControllerArguments(
        context: context,
        toggleBackgroundKeepAlive: { value in
            ToastSettings.shared.backgroundKeepAlive = value
            ToastBackgroundKeepAlive.shared.updateState()
        },
        toggleLocalNotifications: { value in
            ToastSettings.shared.localNotificationsEnabled = value
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
        let entries = toastAdvancedEntries(presentationData: presentationData, settings: ToastSettings.shared)
        let controllerState = ItemListControllerState(
            presentationData: ItemListPresentationData(presentationData),
            title: .text("Advanced"),
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
    presentControllerImpl = { [weak controller] c, a in
        controller?.present(c, in: .window(.root), with: a)
    }
    return controller
}
