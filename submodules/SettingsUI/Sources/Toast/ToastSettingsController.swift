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

private final class ToastSettingsControllerArguments {
    let context: AccountContext
    let openPrivacy: () -> Void
    let openMedia: () -> Void
    let openAds: () -> Void
    let openAppearance: () -> Void
    let openAdvanced: () -> Void

    init(
        context: AccountContext,
        openPrivacy: @escaping () -> Void,
        openMedia: @escaping () -> Void,
        openAds: @escaping () -> Void,
        openAppearance: @escaping () -> Void,
        openAdvanced: @escaping () -> Void
    ) {
        self.context = context
        self.openPrivacy = openPrivacy
        self.openMedia = openMedia
        self.openAds = openAds
        self.openAppearance = openAppearance
        self.openAdvanced = openAdvanced
    }
}

private enum ToastSettingsSection: Int32 {
    case categories
    case about
}

private enum ToastSettingsEntryStableId: Hashable {
    case privacy
    case media
    case ads
    case appearance
    case advanced
    case about
}

private enum ToastSettingsEntry: ItemListNodeEntry {
    case privacy(String, String, UIImage?)
    case media(String, String, UIImage?)
    case ads(String, String, UIImage?)
    case appearance(String, String, UIImage?)
    case advanced(String, String, UIImage?)
    case about(String)

    var section: ItemListSectionId {
        switch self {
        case .privacy, .media, .ads, .appearance, .advanced:
            return ToastSettingsSection.categories.rawValue
        case .about:
            return ToastSettingsSection.about.rawValue
        }
    }

    var stableId: ToastSettingsEntryStableId {
        switch self {
        case .privacy:
            return .privacy
        case .media:
            return .media
        case .ads:
            return .ads
        case .appearance:
            return .appearance
        case .advanced:
            return .advanced
        case .about:
            return .about
        }
    }

    static func ==(lhs: ToastSettingsEntry, rhs: ToastSettingsEntry) -> Bool {
        switch (lhs, rhs) {
        case let (.privacy(lhsTitle, lhsLabel, _), .privacy(rhsTitle, rhsLabel, _)):
            return lhsTitle == rhsTitle && lhsLabel == rhsLabel
        case let (.media(lhsTitle, lhsLabel, _), .media(rhsTitle, rhsLabel, _)):
            return lhsTitle == rhsTitle && lhsLabel == rhsLabel
        case let (.ads(lhsTitle, lhsLabel, _), .ads(rhsTitle, rhsLabel, _)):
            return lhsTitle == rhsTitle && lhsLabel == rhsLabel
        case let (.appearance(lhsTitle, lhsLabel, _), .appearance(rhsTitle, rhsLabel, _)):
            return lhsTitle == rhsTitle && lhsLabel == rhsLabel
        case let (.advanced(lhsTitle, lhsLabel, _), .advanced(rhsTitle, rhsLabel, _)):
            return lhsTitle == rhsTitle && lhsLabel == rhsLabel
        case let (.about(lhsText), .about(rhsText)):
            return lhsText == rhsText
        default:
            return false
        }
    }

    static func <(lhs: ToastSettingsEntry, rhs: ToastSettingsEntry) -> Bool {
        return lhs.stableId.hashValue < rhs.stableId.hashValue
    }

    func item(presentationData: ItemListPresentationData, arguments: Any) -> ListViewItem {
        let args = arguments as! ToastSettingsControllerArguments
        switch self {
        case let .privacy(title, label, icon):
            return ItemListDisclosureItem(presentationData: presentationData, systemStyle: .glass, icon: icon, title: title, label: label, sectionId: self.section, style: .blocks, action: {
                args.openPrivacy()
            })
        case let .media(title, label, icon):
            return ItemListDisclosureItem(presentationData: presentationData, systemStyle: .glass, icon: icon, title: title, label: label, sectionId: self.section, style: .blocks, action: {
                args.openMedia()
            })
        case let .ads(title, label, icon):
            return ItemListDisclosureItem(presentationData: presentationData, systemStyle: .glass, icon: icon, title: title, label: label, sectionId: self.section, style: .blocks, action: {
                args.openAds()
            })
        case let .appearance(title, label, icon):
            return ItemListDisclosureItem(presentationData: presentationData, systemStyle: .glass, icon: icon, title: title, label: label, sectionId: self.section, style: .blocks, action: {
                args.openAppearance()
            })
        case let .advanced(title, label, icon):
            return ItemListDisclosureItem(presentationData: presentationData, systemStyle: .glass, icon: icon, title: title, label: label, sectionId: self.section, style: .blocks, action: {
                args.openAdvanced()
            })
        case let .about(text):
            return ItemListTextItem(presentationData: presentationData, text: .plain(text), sectionId: self.section)
        }
    }
}

private func toastSettingsEntries(settings: ToastSettings) -> [ToastSettingsEntry] {
    var entries: [ToastSettingsEntry] = []

    let privacyLabel = settings.fakePasscodeEnabled ? "Decoy Active" : ""
    entries.append(.privacy("Privacy & Security", privacyLabel, PresentationResourcesSettings.security))

    let mediaLabel = settings.sendOriginalMedia ? "Original Quality" : ""
    entries.append(.media("Chats & Media", mediaLabel, PresentationResourcesSettings.dataAndStorage))

    let adsLabel = (settings.blockChannelAds || settings.blockProxySponsor) ? "Blocked" : ""
    entries.append(.ads("Ads & Promotion", adsLabel, PresentationResourcesSettings.proxy))

    entries.append(.appearance("Appearance", "", PresentationResourcesSettings.appearance))
    entries.append(.advanced("Advanced", "", PresentationResourcesSettings.powerSaving))

    entries.append(.about("Toast for iOS — enhanced Telegram client with decoy passcode protection, uncompressed original media, complete ad blocking, and advanced media playback."))

    return entries
}

public func toastSettingsController(context: AccountContext) -> ViewController {
    var pushControllerImpl: ((ViewController) -> Void)?

    let arguments = ToastSettingsControllerArguments(
        context: context,
        openPrivacy: {
            pushControllerImpl?(toastPrivacySettingsController(context: context))
        },
        openMedia: {
            pushControllerImpl?(toastMediaSettingsController(context: context))
        },
        openAds: {
            pushControllerImpl?(toastAdsSettingsController(context: context))
        },
        openAppearance: {
            pushControllerImpl?(themeSettingsController(context: context))
        },
        openAdvanced: {
            pushControllerImpl?(toastAdvancedSettingsController(context: context))
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
    return controller
}
