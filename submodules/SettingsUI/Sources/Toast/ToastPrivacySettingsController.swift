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
import UndoUI
import AlertUI
import ItemListPeerItem
import ItemListPeerActionItem
import PasscodeUI
import TelegramUIPreferences

private final class ToastPrivacySettingsControllerArguments {
    let context: AccountContext
    let toggleFakePasscodeEnabled: (Bool) -> Void
    let openFakePasscodeSetup: () -> Void
    let toggleDecoyHidePrivateChats: (Bool) -> Void
    let toggleDecoyHideSecretChats: (Bool) -> Void
    let toggleDecoyHideChannels: (Bool) -> Void
    let toggleDecoyHideGroups: (Bool) -> Void
    let addHiddenPeer: () -> Void
    let removeHiddenPeer: (EnginePeer.Id) -> Void
    let toggleSaveDisappearingMedia: (Bool) -> Void
    let toggleAllowScreenshots: (Bool) -> Void
    let toggleAllowSavingProtectedContent: (Bool) -> Void

    init(
        context: AccountContext,
        toggleFakePasscodeEnabled: @escaping (Bool) -> Void,
        openFakePasscodeSetup: @escaping () -> Void,
        toggleDecoyHidePrivateChats: @escaping (Bool) -> Void,
        toggleDecoyHideSecretChats: @escaping (Bool) -> Void,
        toggleDecoyHideChannels: @escaping (Bool) -> Void,
        toggleDecoyHideGroups: @escaping (Bool) -> Void,
        addHiddenPeer: @escaping () -> Void,
        removeHiddenPeer: @escaping (EnginePeer.Id) -> Void,
        toggleSaveDisappearingMedia: @escaping (Bool) -> Void,
        toggleAllowScreenshots: @escaping (Bool) -> Void,
        toggleAllowSavingProtectedContent: @escaping (Bool) -> Void
    ) {
        self.context = context
        self.toggleFakePasscodeEnabled = toggleFakePasscodeEnabled
        self.openFakePasscodeSetup = openFakePasscodeSetup
        self.toggleDecoyHidePrivateChats = toggleDecoyHidePrivateChats
        self.toggleDecoyHideSecretChats = toggleDecoyHideSecretChats
        self.toggleDecoyHideChannels = toggleDecoyHideChannels
        self.toggleDecoyHideGroups = toggleDecoyHideGroups
        self.addHiddenPeer = addHiddenPeer
        self.removeHiddenPeer = removeHiddenPeer
        self.toggleSaveDisappearingMedia = toggleSaveDisappearingMedia
        self.toggleAllowScreenshots = toggleAllowScreenshots
        self.toggleAllowSavingProtectedContent = toggleAllowSavingProtectedContent
    }
}

private enum ToastPrivacySection: Int32 {
    case fakePasscode
    case hideByType
    case specificChats
    case mediaPrivacy
}

private enum ToastPrivacyEntryStableId: Hashable {
    case fakePasscodeHeader
    case fakePasscodeEnabled
    case fakePasscodeSetup
    case fakePasscodeInfo

    case hideByTypeHeader
    case decoyHidePrivateChats
    case decoyHideSecretChats
    case decoyHideChannels
    case decoyHideGroups
    case hideByTypeInfo

    case specificChatsHeader
    case addChatAction
    case peer(EnginePeer.Id)
    case specificChatsInfo

    case mediaPrivacyHeader
    case saveDisappearingMedia
    case saveDisappearingMediaInfo
    case allowScreenshots
    case allowScreenshotsInfo
    case allowSavingProtectedContent
    case allowSavingProtectedContentInfo
}

private enum ToastPrivacyEntry: ItemListNodeEntry {
    case fakePasscodeHeader(String)
    case fakePasscodeEnabled(String, Bool)
    case fakePasscodeSetup(String, String)
    case fakePasscodeInfo(String)

    case hideByTypeHeader(String)
    case decoyHidePrivateChats(String, Bool)
    case decoyHideSecretChats(String, Bool)
    case decoyHideChannels(String, Bool)
    case decoyHideGroups(String, Bool)
    case hideByTypeInfo(String)

    case specificChatsHeader(String)
    case addChatAction(String)
    case peerItem(Int32, PresentationDateTimeFormat, PresentationPersonNameOrder, EnginePeer)
    case specificChatsInfo(String)

    case mediaPrivacyHeader(String)
    case saveDisappearingMedia(String, Bool)
    case saveDisappearingMediaInfo(String)
    case allowScreenshots(String, Bool)
    case allowScreenshotsInfo(String)
    case allowSavingProtectedContent(String, Bool)
    case allowSavingProtectedContentInfo(String)

    var section: ItemListSectionId {
        switch self {
        case .fakePasscodeHeader, .fakePasscodeEnabled, .fakePasscodeSetup, .fakePasscodeInfo:
            return ToastPrivacySection.fakePasscode.rawValue
        case .hideByTypeHeader, .decoyHidePrivateChats, .decoyHideSecretChats, .decoyHideChannels, .decoyHideGroups, .hideByTypeInfo:
            return ToastPrivacySection.hideByType.rawValue
        case .specificChatsHeader, .addChatAction, .peerItem, .specificChatsInfo:
            return ToastPrivacySection.specificChats.rawValue
        case .mediaPrivacyHeader, .saveDisappearingMedia, .saveDisappearingMediaInfo, .allowScreenshots, .allowScreenshotsInfo, .allowSavingProtectedContent, .allowSavingProtectedContentInfo:
            return ToastPrivacySection.mediaPrivacy.rawValue
        }
    }

    var stableId: ToastPrivacyEntryStableId {
        switch self {
        case .fakePasscodeHeader:
            return .fakePasscodeHeader
        case .fakePasscodeEnabled:
            return .fakePasscodeEnabled
        case .fakePasscodeSetup:
            return .fakePasscodeSetup
        case .fakePasscodeInfo:
            return .fakePasscodeInfo

        case .hideByTypeHeader:
            return .hideByTypeHeader
        case .decoyHidePrivateChats:
            return .decoyHidePrivateChats
        case .decoyHideSecretChats:
            return .decoyHideSecretChats
        case .decoyHideChannels:
            return .decoyHideChannels
        case .decoyHideGroups:
            return .decoyHideGroups
        case .hideByTypeInfo:
            return .hideByTypeInfo

        case .specificChatsHeader:
            return .specificChatsHeader
        case .addChatAction:
            return .addChatAction
        case let .peerItem(_, _, _, peer):
            return .peer(peer.id)
        case .specificChatsInfo:
            return .specificChatsInfo

        case .mediaPrivacyHeader:
            return .mediaPrivacyHeader
        case .saveDisappearingMedia:
            return .saveDisappearingMedia
        case .saveDisappearingMediaInfo:
            return .saveDisappearingMediaInfo
        case .allowScreenshots:
            return .allowScreenshots
        case .allowScreenshotsInfo:
            return .allowScreenshotsInfo
        case .allowSavingProtectedContent:
            return .allowSavingProtectedContent
        case .allowSavingProtectedContentInfo:
            return .allowSavingProtectedContentInfo
        }
    }

    static func ==(lhs: ToastPrivacyEntry, rhs: ToastPrivacyEntry) -> Bool {
        switch (lhs, rhs) {
        case let (.fakePasscodeHeader(lhsText), .fakePasscodeHeader(rhsText)):
            return lhsText == rhsText
        case let (.fakePasscodeEnabled(lhsText, lhsValue), .fakePasscodeEnabled(rhsText, rhsValue)):
            return lhsText == rhsText && lhsValue == rhsValue
        case let (.fakePasscodeSetup(lhsTitle, lhsValue), .fakePasscodeSetup(rhsTitle, rhsValue)):
            return lhsTitle == rhsTitle && lhsValue == rhsValue
        case let (.fakePasscodeInfo(lhsText), .fakePasscodeInfo(rhsText)):
            return lhsText == rhsText

        case let (.hideByTypeHeader(lhsText), .hideByTypeHeader(rhsText)):
            return lhsText == rhsText
        case let (.decoyHidePrivateChats(lhsText, lhsValue), .decoyHidePrivateChats(rhsText, rhsValue)):
            return lhsText == rhsText && lhsValue == rhsValue
        case let (.decoyHideSecretChats(lhsText, lhsValue), .decoyHideSecretChats(rhsText, rhsValue)):
            return lhsText == rhsText && lhsValue == rhsValue
        case let (.decoyHideChannels(lhsText, lhsValue), .decoyHideChannels(rhsText, rhsValue)):
            return lhsText == rhsText && lhsValue == rhsValue
        case let (.decoyHideGroups(lhsText, lhsValue), .decoyHideGroups(rhsText, rhsValue)):
            return lhsText == rhsText && lhsValue == rhsValue
        case let (.hideByTypeInfo(lhsText), .hideByTypeInfo(rhsText)):
            return lhsText == rhsText

        case let (.specificChatsHeader(lhsText), .specificChatsHeader(rhsText)):
            return lhsText == rhsText
        case let (.addChatAction(lhsText), .addChatAction(rhsText)):
            return lhsText == rhsText
        case let (.peerItem(lhsIndex, _, _, lhsPeer), .peerItem(rhsIndex, _, _, rhsPeer)):
            return lhsIndex == rhsIndex && lhsPeer == rhsPeer
        case let (.specificChatsInfo(lhsText), .specificChatsInfo(rhsText)):
            return lhsText == rhsText

        case let (.mediaPrivacyHeader(lhsText), .mediaPrivacyHeader(rhsText)):
            return lhsText == rhsText
        case let (.saveDisappearingMedia(lhsText, lhsValue), .saveDisappearingMedia(rhsText, rhsValue)):
            return lhsText == rhsText && lhsValue == rhsValue
        case let (.saveDisappearingMediaInfo(lhsText), .saveDisappearingMediaInfo(rhsText)):
            return lhsText == rhsText
        case let (.allowScreenshots(lhsText, lhsValue), .allowScreenshots(rhsText, rhsValue)):
            return lhsText == rhsText && lhsValue == rhsValue
        case let (.allowScreenshotsInfo(lhsText), .allowScreenshotsInfo(rhsText)):
            return lhsText == rhsText
        case let (.allowSavingProtectedContent(lhsText, lhsValue), .allowSavingProtectedContent(rhsText, rhsValue)):
            return lhsText == rhsText && lhsValue == rhsValue
        case let (.allowSavingProtectedContentInfo(lhsText), .allowSavingProtectedContentInfo(rhsText)):
            return lhsText == rhsText
        default:
            return false
        }
    }

    static func <(lhs: ToastPrivacyEntry, rhs: ToastPrivacyEntry) -> Bool {
        return lhs.stableId.hashValue < rhs.stableId.hashValue
    }

    func item(presentationData: ItemListPresentationData, arguments: Any) -> ListViewItem {
        let args = arguments as! ToastPrivacySettingsControllerArguments
        switch self {
        case let .fakePasscodeHeader(title):
            return ItemListSectionHeaderItem(presentationData: presentationData, text: title, sectionId: self.section)
        case let .fakePasscodeEnabled(title, value):
            return ItemListSwitchItem(presentationData: presentationData, title: title, value: value, sectionId: self.section, style: .blocks, updated: { updatedValue in
                args.toggleFakePasscodeEnabled(updatedValue)
            })
        case let .fakePasscodeSetup(title, value):
            return ItemListDisclosureItem(presentationData: presentationData, title: title, label: value, sectionId: self.section, style: .blocks, action: {
                args.openFakePasscodeSetup()
            })
        case let .fakePasscodeInfo(text):
            return ItemListTextItem(presentationData: presentationData, text: .plain(text), sectionId: self.section)

        case let .hideByTypeHeader(title):
            return ItemListSectionHeaderItem(presentationData: presentationData, text: title, sectionId: self.section)
        case let .decoyHidePrivateChats(title, value):
            return ItemListSwitchItem(presentationData: presentationData, title: title, value: value, sectionId: self.section, style: .blocks, updated: { updatedValue in
                args.toggleDecoyHidePrivateChats(updatedValue)
            })
        case let .decoyHideSecretChats(title, value):
            return ItemListSwitchItem(presentationData: presentationData, title: title, value: value, sectionId: self.section, style: .blocks, updated: { updatedValue in
                args.toggleDecoyHideSecretChats(updatedValue)
            })
        case let .decoyHideChannels(title, value):
            return ItemListSwitchItem(presentationData: presentationData, title: title, value: value, sectionId: self.section, style: .blocks, updated: { updatedValue in
                args.toggleDecoyHideChannels(updatedValue)
            })
        case let .decoyHideGroups(title, value):
            return ItemListSwitchItem(presentationData: presentationData, title: title, value: value, sectionId: self.section, style: .blocks, updated: { updatedValue in
                args.toggleDecoyHideGroups(updatedValue)
            })
        case let .hideByTypeInfo(text):
            return ItemListTextItem(presentationData: presentationData, text: .plain(text), sectionId: self.section)

        case let .specificChatsHeader(title):
            return ItemListSectionHeaderItem(presentationData: presentationData, text: title, sectionId: self.section)
        case let .addChatAction(title):
            return ItemListPeerActionItem(presentationData: presentationData, systemStyle: .glass, icon: PresentationResourcesItemList.plusIconImage(presentationData.theme), title: title, sectionId: self.section, height: .generic, editing: false, action: {
                args.addHiddenPeer()
            })
        case let .peerItem(_, dateTimeFormat, nameDisplayOrder, peer):
            let revealOptions = ItemListPeerItemRevealOptions(options: [
                ItemListPeerItemRevealOption(type: .destructive, title: presentationData.strings.Common_Delete, action: {
                    args.removeHiddenPeer(peer.id)
                })
            ])
            return ItemListPeerItem(
                presentationData: presentationData,
                systemStyle: .glass,
                dateTimeFormat: dateTimeFormat,
                nameDisplayOrder: nameDisplayOrder,
                context: args.context,
                peer: peer,
                presence: nil,
                text: .none,
                label: .none,
                editing: ItemListPeerItemEditing(editable: true, editing: false, revealed: false),
                revealOptions: revealOptions,
                switchValue: nil,
                enabled: true,
                selectable: true,
                sectionId: self.section,
                action: {},
                setPeerIdWithRevealedOptions: { _, _ in },
                removePeer: { peerId in
                    args.removeHiddenPeer(peerId)
                }
            )
        case let .specificChatsInfo(text):
            return ItemListTextItem(presentationData: presentationData, text: .plain(text), sectionId: self.section)

        case let .mediaPrivacyHeader(title):
            return ItemListSectionHeaderItem(presentationData: presentationData, text: title, sectionId: self.section)
        case let .saveDisappearingMedia(title, value):
            return ItemListSwitchItem(presentationData: presentationData, title: title, value: value, sectionId: self.section, style: .blocks, updated: { updatedValue in
                args.toggleSaveDisappearingMedia(updatedValue)
            })
        case let .saveDisappearingMediaInfo(text):
            return ItemListTextItem(presentationData: presentationData, text: .plain(text), sectionId: self.section)
        case let .allowScreenshots(title, value):
            return ItemListSwitchItem(presentationData: presentationData, title: title, value: value, sectionId: self.section, style: .blocks, updated: { updatedValue in
                args.toggleAllowScreenshots(updatedValue)
            })
        case let .allowScreenshotsInfo(text):
            return ItemListTextItem(presentationData: presentationData, text: .plain(text), sectionId: self.section)
        case let .allowSavingProtectedContent(title, value):
            return ItemListSwitchItem(presentationData: presentationData, title: title, value: value, sectionId: self.section, style: .blocks, updated: { updatedValue in
                args.toggleAllowSavingProtectedContent(updatedValue)
            })
        case let .allowSavingProtectedContentInfo(text):
            return ItemListTextItem(presentationData: presentationData, text: .plain(text), sectionId: self.section)
        }
    }
}

private func toastPrivacyEntries(presentationData: PresentationData, settings: ToastSettings, hiddenPeers: [EnginePeer]) -> [ToastPrivacyEntry] {
    var entries: [ToastPrivacyEntry] = []

    // Fake Passcode
    entries.append(.fakePasscodeHeader("DECOY PASSCODE (ДВОЙНОЕ ДНО)"))
    entries.append(.fakePasscodeEnabled("Enable Decoy Passcode", settings.fakePasscodeEnabled))
    if settings.fakePasscodeEnabled {
        let label = settings.fakePasscode.isEmpty ? "Set Passcode" : String(repeating: "•", count: max(4, settings.fakePasscode.count))
        entries.append(.fakePasscodeSetup("Decoy Passcode", label))
    }
    entries.append(.fakePasscodeInfo("When unlocked with this passcode, selected chats and chat categories will be hidden."))

    // Hide by Type
    if settings.fakePasscodeEnabled {
        entries.append(.hideByTypeHeader("HIDE BY TYPE"))
        entries.append(.decoyHidePrivateChats("Private Chats", settings.decoyHidePrivateChats))
        entries.append(.decoyHideSecretChats("Secret Chats", settings.decoyHideSecretChats))
        entries.append(.decoyHideChannels("Channels", settings.decoyHideChannels))
        entries.append(.decoyHideGroups("Groups", settings.decoyHideGroups))
        entries.append(.hideByTypeInfo("Chats matching the selected types will not appear when unlocked with the decoy passcode."))

        // Specific Hidden Chats
        entries.append(.specificChatsHeader("SPECIFIC HIDDEN CHATS"))
        entries.append(.addChatAction("Add Chat..."))
        var index: Int32 = 0
        for peer in hiddenPeers {
            entries.append(.peerItem(index, presentationData.dateTimeFormat, presentationData.nameDisplayOrder, peer))
            index += 1
        }
        entries.append(.specificChatsInfo("Specific chats listed above will be hidden under the decoy passcode."))
    }

    // Media Privacy
    entries.append(.mediaPrivacyHeader("MEDIA PRIVACY & RESTRICTIONS"))
    entries.append(.saveDisappearingMedia("Save Disappearing Media", settings.saveDisappearingMedia))
    entries.append(.saveDisappearingMediaInfo("Allows saving photos and videos sent with a timer."))
    entries.append(.allowScreenshots("Allow Screenshots", settings.allowScreenshots))
    entries.append(.allowScreenshotsInfo("Enables screenshots in secret chats and view-once media."))
    entries.append(.allowSavingProtectedContent("Save Protected Content", settings.allowSavingProtectedContent))
    entries.append(.allowSavingProtectedContentInfo("Bypasses download restrictions in channels and groups that forbid saving content."))

    return entries
}

public func toastPrivacySettingsController(context: AccountContext) -> ViewController {
    var pushControllerImpl: ((ViewController) -> Void)?
    var popControllerImpl: (() -> Void)?
    var presentControllerImpl: ((ViewController, Any?) -> Void)?

    let arguments = ToastPrivacySettingsControllerArguments(
        context: context,
        toggleFakePasscodeEnabled: { value in
            ToastSettings.shared.fakePasscodeEnabled = value
            if value && ToastSettings.shared.fakePasscode.isEmpty {
                let setupController = PasscodeSetupController(context: context, mode: .setup(change: false, .digits4))
                setupController.title = "Decoy Passcode"
                setupController.complete = { passcode, _ in
                    ToastSettings.shared.fakePasscode = passcode
                    popControllerImpl?()
                }
                pushControllerImpl?(setupController)
            }
        },
        openFakePasscodeSetup: {
            let currentPasscode = ToastSettings.shared.fakePasscode
            let fieldType: PasscodeEntryFieldType
            if currentPasscode.count == 6 && currentPasscode.allSatisfy({ $0.isNumber }) {
                fieldType = .digits6
            } else if currentPasscode.count == 4 && currentPasscode.allSatisfy({ $0.isNumber }) {
                fieldType = .digits4
            } else if !currentPasscode.isEmpty {
                fieldType = .alphanumeric
            } else {
                fieldType = .digits4
            }
            if currentPasscode.isEmpty {
                let setupController = PasscodeSetupController(context: context, mode: .setup(change: false, fieldType))
                setupController.title = "Decoy Passcode"
                setupController.complete = { passcode, _ in
                    ToastSettings.shared.fakePasscode = passcode
                    ToastSettings.shared.fakePasscodeEnabled = true
                    popControllerImpl?()
                }
                pushControllerImpl?(setupController)
            } else {
                let presentationData = context.sharedContext.currentPresentationData.with { $0 }
                let actionSheet = ActionSheetController(presentationData: presentationData)
                var items: [ActionSheetItem] = [
                    ActionSheetTextItem(title: "Decoy Passcode / Двойное дно")
                ]
                items.append(ActionSheetButtonItem(title: "Change Passcode", color: .accent, action: { [weak actionSheet] in
                    actionSheet?.dismissAnimated()
                    let setupController = PasscodeSetupController(context: context, mode: .setup(change: true, fieldType))
                    setupController.title = "Decoy Passcode"
                    setupController.complete = { passcode, _ in
                        ToastSettings.shared.fakePasscode = passcode
                        popControllerImpl?()
                    }
                    pushControllerImpl?(setupController)
                }))
                items.append(ActionSheetButtonItem(title: "Turn Off Decoy Passcode", color: .destructive, action: { [weak actionSheet] in
                    actionSheet?.dismissAnimated()
                    ToastSettings.shared.fakePasscode = ""
                    ToastSettings.shared.fakePasscodeEnabled = false
                }))
                actionSheet.setItemGroups([
                    ActionSheetItemGroup(items: items),
                    ActionSheetItemGroup(items: [
                        ActionSheetButtonItem(title: presentationData.strings.Common_Cancel, color: .accent, font: .bold, action: { [weak actionSheet] in
                            actionSheet?.dismissAnimated()
                        })
                    ])
                ])
                presentControllerImpl?(actionSheet, nil)
            }
        },
        toggleDecoyHidePrivateChats: { value in
            ToastSettings.shared.decoyHidePrivateChats = value
        },
        toggleDecoyHideSecretChats: { value in
            ToastSettings.shared.decoyHideSecretChats = value
        },
        toggleDecoyHideChannels: { value in
            ToastSettings.shared.decoyHideChannels = value
        },
        toggleDecoyHideGroups: { value in
            ToastSettings.shared.decoyHideGroups = value
        },
        addHiddenPeer: {
            let controller = context.sharedContext.makePeerSelectionController(
                PeerSelectionControllerParams(
                    context: context,
                    filter: [.excludeSavedMessages, .excludeRecent],
                    title: "Select Chat to Hide"
                )
            )
            controller.peerSelected = { [weak controller] peer, _ in
                var current = ToastSettings.shared.decoyHiddenPeerIds
                if !current.contains(peer.id.toInt64()) {
                    current.append(peer.id.toInt64())
                    ToastSettings.shared.decoyHiddenPeerIds = current
                }
                controller?.dismiss()
            }
            pushControllerImpl?(controller)
        },
        removeHiddenPeer: { peerId in
            var current = ToastSettings.shared.decoyHiddenPeerIds
            current.removeAll { $0 == peerId.toInt64() }
            ToastSettings.shared.decoyHiddenPeerIds = current
        },
        toggleSaveDisappearingMedia: { value in
            ToastSettings.shared.saveDisappearingMedia = value
        },
        toggleAllowScreenshots: { value in
            ToastSettings.shared.allowScreenshots = value
        },
        toggleAllowSavingProtectedContent: { value in
            ToastSettings.shared.allowSavingProtectedContent = value
        }
    )

    let hiddenPeersSignal: Signal<[EnginePeer], NoError> = ToastSettings.shared.updated
    |> mapToSignal { _ -> Signal<[EnginePeer], NoError> in
        let ids = ToastSettings.shared.decoyHiddenPeerIds.map { PeerId($0) }
        return context.account.postbox.transaction { transaction -> [EnginePeer] in
            return ids.compactMap { transaction.getPeer($0).flatMap { EnginePeer($0) } }
        }
    }

    let signal = combineLatest(
        context.sharedContext.presentationData,
        ToastSettings.shared.updated,
        hiddenPeersSignal
    )
    |> map { presentationData, _, hiddenPeers -> (ItemListControllerState, (ItemListNodeState, Any)) in
        let entries = toastPrivacyEntries(presentationData: presentationData, settings: ToastSettings.shared, hiddenPeers: hiddenPeers)
        let controllerState = ItemListControllerState(
            presentationData: ItemListPresentationData(presentationData),
            title: .text("Privacy & Security"),
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
    popControllerImpl = { [weak controller] in
        let _ = controller?.navigationController?.popViewController(animated: true)
    }
    presentControllerImpl = { [weak controller] c, a in
        controller?.present(c, in: .window(.root), with: a)
    }
    return controller
}
