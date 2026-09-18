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

private final class ToastAdsSettingsControllerArguments {
    let context: AccountContext
    let toggleBlockChannelAds: (Bool) -> Void
    let toggleBlockProxySponsor: (Bool) -> Void

    init(
        context: AccountContext,
        toggleBlockChannelAds: @escaping (Bool) -> Void,
        toggleBlockProxySponsor: @escaping (Bool) -> Void
    ) {
        self.context = context
        self.toggleBlockChannelAds = toggleBlockChannelAds
        self.toggleBlockProxySponsor = toggleBlockProxySponsor
    }
}

private enum ToastAdsSection: Int32 {
    case channelAds
    case proxySponsor
}

private enum ToastAdsEntryStableId: Hashable {
    case channelAdsHeader
    case blockChannelAds
    case blockChannelAdsInfo

    case proxySponsorHeader
    case blockProxySponsor
    case blockProxySponsorInfo
}

private enum ToastAdsEntry: ItemListNodeEntry {
    case channelAdsHeader(String)
    case blockChannelAds(String, Bool)
    case blockChannelAdsInfo(String)

    case proxySponsorHeader(String)
    case blockProxySponsor(String, Bool)
    case blockProxySponsorInfo(String)

    var section: ItemListSectionId {
        switch self {
        case .channelAdsHeader, .blockChannelAds, .blockChannelAdsInfo:
            return ToastAdsSection.channelAds.rawValue
        case .proxySponsorHeader, .blockProxySponsor, .blockProxySponsorInfo:
            return ToastAdsSection.proxySponsor.rawValue
        }
    }

    var stableId: ToastAdsEntryStableId {
        switch self {
        case .channelAdsHeader:
            return .channelAdsHeader
        case .blockChannelAds:
            return .blockChannelAds
        case .blockChannelAdsInfo:
            return .blockChannelAdsInfo
        case .proxySponsorHeader:
            return .proxySponsorHeader
        case .blockProxySponsor:
            return .blockProxySponsor
        case .blockProxySponsorInfo:
            return .blockProxySponsorInfo
        }
    }

    static func ==(lhs: ToastAdsEntry, rhs: ToastAdsEntry) -> Bool {
        switch (lhs, rhs) {
        case let (.channelAdsHeader(lhsText), .channelAdsHeader(rhsText)):
            return lhsText == rhsText
        case let (.blockChannelAds(lhsText, lhsValue), .blockChannelAds(rhsText, rhsValue)):
            return lhsText == rhsText && lhsValue == rhsValue
        case let (.blockChannelAdsInfo(lhsText), .blockChannelAdsInfo(rhsText)):
            return lhsText == rhsText
        case let (.proxySponsorHeader(lhsText), .proxySponsorHeader(rhsText)):
            return lhsText == rhsText
        case let (.blockProxySponsor(lhsText, lhsValue), .blockProxySponsor(rhsText, rhsValue)):
            return lhsText == rhsText && lhsValue == rhsValue
        case let (.blockProxySponsorInfo(lhsText), .blockProxySponsorInfo(rhsText)):
            return lhsText == rhsText
        default:
            return false
        }
    }

    static func <(lhs: ToastAdsEntry, rhs: ToastAdsEntry) -> Bool {
        return lhs.stableId.hashValue < rhs.stableId.hashValue
    }

    func item(presentationData: ItemListPresentationData, arguments: Any) -> ListViewItem {
        let args = arguments as! ToastAdsSettingsControllerArguments
        switch self {
        case let .channelAdsHeader(title):
            return ItemListSectionHeaderItem(presentationData: presentationData, text: title, sectionId: self.section)
        case let .blockChannelAds(title, value):
            return ItemListSwitchItem(presentationData: presentationData, title: title, value: value, sectionId: self.section, style: .blocks, updated: { updatedValue in
                args.toggleBlockChannelAds(updatedValue)
            })
        case let .blockChannelAdsInfo(text):
            return ItemListTextItem(presentationData: presentationData, text: .plain(text), sectionId: self.section)

        case let .proxySponsorHeader(title):
            return ItemListSectionHeaderItem(presentationData: presentationData, text: title, sectionId: self.section)
        case let .blockProxySponsor(title, value):
            return ItemListSwitchItem(presentationData: presentationData, title: title, value: value, sectionId: self.section, style: .blocks, updated: { updatedValue in
                args.toggleBlockProxySponsor(updatedValue)
            })
        case let .blockProxySponsorInfo(text):
            return ItemListTextItem(presentationData: presentationData, text: .plain(text), sectionId: self.section)
        }
    }
}

private func toastAdsEntries(presentationData: PresentationData, settings: ToastSettings) -> [ToastAdsEntry] {
    var entries: [ToastAdsEntry] = []

    // Channel Ads
    entries.append(.channelAdsHeader("SPONSORED MESSAGES"))
    entries.append(.blockChannelAds("Block Sponsored Messages", settings.blockChannelAds))
    entries.append(.blockChannelAdsInfo("Hides official sponsored promotional posts shown at the bottom of public channels."))

    // Proxy Sponsor
    entries.append(.proxySponsorHeader("PROXY PROMOTION"))
    entries.append(.blockProxySponsor("Block Proxy Sponsor Channel", settings.blockProxySponsor))
    entries.append(.blockProxySponsorInfo("Hides the proxy sponsor channel pinned at the top of the chat list when connected via sponsored MTProto proxies."))

    return entries
}

public func toastAdsSettingsController(context: AccountContext) -> ViewController {
    let arguments = ToastAdsSettingsControllerArguments(
        context: context,
        toggleBlockChannelAds: { value in
            ToastSettings.shared.blockChannelAds = value
        },
        toggleBlockProxySponsor: { value in
            ToastSettings.shared.blockProxySponsor = value
        }
    )

    let signal = combineLatest(
        context.sharedContext.presentationData,
        ToastSettings.shared.updated
    )
    |> map { presentationData, _ -> (ItemListControllerState, (ItemListNodeState, Any)) in
        let entries = toastAdsEntries(presentationData: presentationData, settings: ToastSettings.shared)
        let controllerState = ItemListControllerState(
            presentationData: ItemListPresentationData(presentationData),
            title: .text("Ads & Promotion"),
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

    return ItemListController(context: context, state: signal)
}
