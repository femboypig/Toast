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

private final class ToastMediaSettingsControllerArguments {
    let context: AccountContext
    let toggleSendOriginalMedia: (Bool) -> Void
    let toggleForwardWithoutQuote: (Bool) -> Void
    let toggleFreeVoiceToText: (Bool) -> Void
    let toggleVoiceChangerEnabled: (Bool) -> Void
    let updateVoiceChangerPitch: (Float) -> Void
    let updateVoiceChangerEcho: (Float) -> Void
    let updateVoiceChangerReverb: (Float) -> Void
    let updateVoiceChangerRobot: (Float) -> Void
    let updateVoiceChangerBass: (Float) -> Void
    let updateVoiceChangerDistortion: (Float) -> Void
    let resetVoiceEffects: () -> Void

    init(
        context: AccountContext,
        toggleSendOriginalMedia: @escaping (Bool) -> Void,
        toggleForwardWithoutQuote: @escaping (Bool) -> Void,
        toggleFreeVoiceToText: @escaping (Bool) -> Void,
        toggleVoiceChangerEnabled: @escaping (Bool) -> Void,
        updateVoiceChangerPitch: @escaping (Float) -> Void,
        updateVoiceChangerEcho: @escaping (Float) -> Void,
        updateVoiceChangerReverb: @escaping (Float) -> Void,
        updateVoiceChangerRobot: @escaping (Float) -> Void,
        updateVoiceChangerBass: @escaping (Float) -> Void,
        updateVoiceChangerDistortion: @escaping (Float) -> Void,
        resetVoiceEffects: @escaping () -> Void
    ) {
        self.context = context
        self.toggleSendOriginalMedia = toggleSendOriginalMedia
        self.toggleForwardWithoutQuote = toggleForwardWithoutQuote
        self.toggleFreeVoiceToText = toggleFreeVoiceToText
        self.toggleVoiceChangerEnabled = toggleVoiceChangerEnabled
        self.updateVoiceChangerPitch = updateVoiceChangerPitch
        self.updateVoiceChangerEcho = updateVoiceChangerEcho
        self.updateVoiceChangerReverb = updateVoiceChangerReverb
        self.updateVoiceChangerRobot = updateVoiceChangerRobot
        self.updateVoiceChangerBass = updateVoiceChangerBass
        self.updateVoiceChangerDistortion = updateVoiceChangerDistortion
        self.resetVoiceEffects = resetVoiceEffects
    }
}

private enum ToastMediaSection: Int32 {
    case quality
    case messaging
    case videoNotes
    case voiceChanger
}

private enum ToastMediaEntryStableId: Hashable {
    case qualityHeader
    case sendOriginalMedia
    case sendOriginalMediaInfo

    case messagingHeader
    case forwardWithoutQuote
    case forwardWithoutQuoteInfo
    case freeVoiceToText
    case freeVoiceToTextInfo

    case videoNotesHeader
    case videoNotesInfo

    case voiceChangerHeader
    case voiceChangerEnabled
    case voiceChangerPitch
    case voiceChangerEcho
    case voiceChangerReverb
    case voiceChangerRobot
    case voiceChangerBass
    case voiceChangerDistortion
    case voiceChangerReset
    case voiceChangerInfo
}

private enum ToastMediaEntry: ItemListNodeEntry {
    case qualityHeader(String)
    case sendOriginalMedia(String, Bool)
    case sendOriginalMediaInfo(String)

    case messagingHeader(String)
    case forwardWithoutQuote(String, Bool)
    case forwardWithoutQuoteInfo(String)
    case freeVoiceToText(String, Bool)
    case freeVoiceToTextInfo(String)

    case videoNotesHeader(String)
    case videoNotesInfo(String)

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

    var section: ItemListSectionId {
        switch self {
        case .qualityHeader, .sendOriginalMedia, .sendOriginalMediaInfo:
            return ToastMediaSection.quality.rawValue
        case .messagingHeader, .forwardWithoutQuote, .forwardWithoutQuoteInfo, .freeVoiceToText, .freeVoiceToTextInfo:
            return ToastMediaSection.messaging.rawValue
        case .videoNotesHeader, .videoNotesInfo:
            return ToastMediaSection.videoNotes.rawValue
        case .voiceChangerHeader, .voiceChangerEnabled, .voiceChangerPitch, .voiceChangerEcho, .voiceChangerReverb, .voiceChangerRobot, .voiceChangerBass, .voiceChangerDistortion, .voiceChangerReset, .voiceChangerInfo:
            return ToastMediaSection.voiceChanger.rawValue
        }
    }

    var stableId: ToastMediaEntryStableId {
        switch self {
        case .qualityHeader:
            return .qualityHeader
        case .sendOriginalMedia:
            return .sendOriginalMedia
        case .sendOriginalMediaInfo:
            return .sendOriginalMediaInfo

        case .messagingHeader:
            return .messagingHeader
        case .forwardWithoutQuote:
            return .forwardWithoutQuote
        case .forwardWithoutQuoteInfo:
            return .forwardWithoutQuoteInfo
        case .freeVoiceToText:
            return .freeVoiceToText
        case .freeVoiceToTextInfo:
            return .freeVoiceToTextInfo

        case .videoNotesHeader:
            return .videoNotesHeader
        case .videoNotesInfo:
            return .videoNotesInfo

        case .voiceChangerHeader:
            return .voiceChangerHeader
        case .voiceChangerEnabled:
            return .voiceChangerEnabled
        case .voiceChangerPitch:
            return .voiceChangerPitch
        case .voiceChangerEcho:
            return .voiceChangerEcho
        case .voiceChangerReverb:
            return .voiceChangerReverb
        case .voiceChangerRobot:
            return .voiceChangerRobot
        case .voiceChangerBass:
            return .voiceChangerBass
        case .voiceChangerDistortion:
            return .voiceChangerDistortion
        case .voiceChangerReset:
            return .voiceChangerReset
        case .voiceChangerInfo:
            return .voiceChangerInfo
        }
    }

    static func ==(lhs: ToastMediaEntry, rhs: ToastMediaEntry) -> Bool {
        switch (lhs, rhs) {
        case let (.qualityHeader(lhsText), .qualityHeader(rhsText)):
            return lhsText == rhsText
        case let (.sendOriginalMedia(lhsText, lhsValue), .sendOriginalMedia(rhsText, rhsValue)):
            return lhsText == rhsText && lhsValue == rhsValue
        case let (.sendOriginalMediaInfo(lhsText), .sendOriginalMediaInfo(rhsText)):
            return lhsText == rhsText

        case let (.messagingHeader(lhsText), .messagingHeader(rhsText)):
            return lhsText == rhsText
        case let (.forwardWithoutQuote(lhsText, lhsValue), .forwardWithoutQuote(rhsText, rhsValue)):
            return lhsText == rhsText && lhsValue == rhsValue
        case let (.forwardWithoutQuoteInfo(lhsText), .forwardWithoutQuoteInfo(rhsText)):
            return lhsText == rhsText
        case let (.freeVoiceToText(lhsText, lhsValue), .freeVoiceToText(rhsText, rhsValue)):
            return lhsText == rhsText && lhsValue == rhsValue
        case let (.freeVoiceToTextInfo(lhsText), .freeVoiceToTextInfo(rhsText)):
            return lhsText == rhsText

        case let (.videoNotesHeader(lhsText), .videoNotesHeader(rhsText)):
            return lhsText == rhsText
        case let (.videoNotesInfo(lhsText), .videoNotesInfo(rhsText)):
            return lhsText == rhsText

        case let (.voiceChangerHeader(lhsText), .voiceChangerHeader(rhsText)):
            return lhsText == rhsText
        case let (.voiceChangerEnabled(lhsText, lhsValue), .voiceChangerEnabled(rhsText, rhsValue)):
            return lhsText == rhsText && lhsValue == rhsValue
        case let (.voiceChangerPitch(lhsTitle, lhsText, lhsValue), .voiceChangerPitch(rhsTitle, rhsText, rhsValue)):
            return lhsTitle == rhsTitle && lhsText == rhsText && lhsValue == rhsValue
        case let (.voiceChangerEcho(lhsTitle, lhsText, lhsValue), .voiceChangerEcho(rhsTitle, rhsText, rhsValue)):
            return lhsTitle == rhsTitle && lhsText == rhsText && lhsValue == rhsValue
        case let (.voiceChangerReverb(lhsTitle, lhsText, lhsValue), .voiceChangerReverb(rhsTitle, rhsText, rhsValue)):
            return lhsTitle == rhsTitle && lhsText == rhsText && lhsValue == rhsValue
        case let (.voiceChangerRobot(lhsTitle, lhsText, lhsValue), .voiceChangerRobot(rhsTitle, rhsText, rhsValue)):
            return lhsTitle == rhsTitle && lhsText == rhsText && lhsValue == rhsValue
        case let (.voiceChangerBass(lhsTitle, lhsText, lhsValue), .voiceChangerBass(rhsTitle, rhsText, rhsValue)):
            return lhsTitle == rhsTitle && lhsText == rhsText && lhsValue == rhsValue
        case let (.voiceChangerDistortion(lhsTitle, lhsText, lhsValue), .voiceChangerDistortion(rhsTitle, rhsText, rhsValue)):
            return lhsTitle == rhsTitle && lhsText == rhsText && lhsValue == rhsValue
        case let (.voiceChangerReset(lhsText), .voiceChangerReset(rhsText)):
            return lhsText == rhsText
        case let (.voiceChangerInfo(lhsText), .voiceChangerInfo(rhsText)):
            return lhsText == rhsText
        default:
            return false
        }
    }

    static func <(lhs: ToastMediaEntry, rhs: ToastMediaEntry) -> Bool {
        return lhs.stableId.hashValue < rhs.stableId.hashValue
    }

    func item(presentationData: ItemListPresentationData, arguments: Any) -> ListViewItem {
        let args = arguments as! ToastMediaSettingsControllerArguments
        switch self {
        case let .qualityHeader(title):
            return ItemListSectionHeaderItem(presentationData: presentationData, text: title, sectionId: self.section)
        case let .sendOriginalMedia(title, value):
            return ItemListSwitchItem(presentationData: presentationData, title: title, value: value, sectionId: self.section, style: .blocks, updated: { updatedValue in
                args.toggleSendOriginalMedia(updatedValue)
            })
        case let .sendOriginalMediaInfo(text):
            return ItemListTextItem(presentationData: presentationData, text: .plain(text), sectionId: self.section)

        case let .messagingHeader(title):
            return ItemListSectionHeaderItem(presentationData: presentationData, text: title, sectionId: self.section)
        case let .forwardWithoutQuote(title, value):
            return ItemListSwitchItem(presentationData: presentationData, title: title, value: value, sectionId: self.section, style: .blocks, updated: { updatedValue in
                args.toggleForwardWithoutQuote(updatedValue)
            })
        case let .forwardWithoutQuoteInfo(text):
            return ItemListTextItem(presentationData: presentationData, text: .plain(text), sectionId: self.section)
        case let .freeVoiceToText(title, value):
            return ItemListSwitchItem(presentationData: presentationData, title: title, value: value, sectionId: self.section, style: .blocks, updated: { updatedValue in
                args.toggleFreeVoiceToText(updatedValue)
            })
        case let .freeVoiceToTextInfo(text):
            return ItemListTextItem(presentationData: presentationData, text: .plain(text), sectionId: self.section)

        case let .videoNotesHeader(title):
            return ItemListSectionHeaderItem(presentationData: presentationData, text: title, sectionId: self.section)
        case let .videoNotesInfo(text):
            return ItemListTextItem(presentationData: presentationData, text: .plain(text), sectionId: self.section)

        case let .voiceChangerHeader(title):
            return ItemListSectionHeaderItem(presentationData: presentationData, text: title, sectionId: self.section)
        case let .voiceChangerEnabled(title, value):
            return ItemListSwitchItem(presentationData: presentationData, title: title, value: value, sectionId: self.section, style: .blocks, updated: { updatedValue in
                args.toggleVoiceChangerEnabled(updatedValue)
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
        }
    }
}

private func toastMediaEntries(presentationData: PresentationData, settings: ToastSettings) -> [ToastMediaEntry] {
    var entries: [ToastMediaEntry] = []

    // Media Quality
    entries.append(.qualityHeader("MEDIA QUALITY"))
    entries.append(.sendOriginalMedia("Send Original Quality Media", settings.sendOriginalMedia))
    entries.append(.sendOriginalMediaInfo("Automatically sends photos and videos in full uncompressed resolution by default."))

    // Messaging
    entries.append(.messagingHeader("MESSAGING"))
    entries.append(.forwardWithoutQuote("Forward Without Quote", settings.forwardWithoutQuote))
    entries.append(.forwardWithoutQuoteInfo("Removes author attribution when forwarding messages by default."))
    entries.append(.freeVoiceToText("Free Voice-to-Text", settings.freeVoiceToText))
    entries.append(.freeVoiceToTextInfo("Transcribes voice and video messages without Telegram Premium."))

    // Video Notes (Кружочки)
    entries.append(.videoNotesHeader("ROUND VIDEO NOTES (КРУЖОЧКИ)"))
    entries.append(.videoNotesInfo("Video messages continue playing in Picture-in-Picture mode or background when switching chats. Includes interactive scrubber, timeline seeking, and ±10 second skip controls."))

    // Voice Changer
    entries.append(.voiceChangerHeader("VOICE CHANGER"))
    entries.append(.voiceChangerEnabled("Enable Voice Changer", settings.voiceChangerEnabled))
    if settings.voiceChangerEnabled {
        let pitch = settings.voiceChangerPitch
        let pitchText = pitch > 0 ? "+\(Int(pitch)) semitones" : (pitch < 0 ? "\(Int(pitch)) semitones" : "Normal")
        entries.append(.voiceChangerPitch("Pitch Shift", pitchText, pitch))

        let echo = settings.voiceChangerEcho
        let echoText = echo > 0 ? "\(Int(echo * 100))%" : "Off"
        entries.append(.voiceChangerEcho("Echo Effect", echoText, echo))

        let reverb = settings.voiceChangerReverb
        let reverbText = reverb > 0 ? "\(Int(reverb * 100))%" : "Off"
        entries.append(.voiceChangerReverb("Reverb Effect", reverbText, reverb))

        let robot = settings.voiceChangerRobot
        let robotText = robot > 0 ? "\(Int(robot * 100))%" : "Off"
        entries.append(.voiceChangerRobot("Robot Ring Modulator", robotText, robot))

        let bass = settings.voiceChangerBass
        let bassText = bass > 0 ? "+\(Int(bass)) dB" : (bass < 0 ? "\(Int(bass)) dB" : "0 dB")
        entries.append(.voiceChangerBass("Bass Boost", bassText, bass))

        let distortion = settings.voiceChangerDistortion
        let distText = distortion > 0 ? "\(Int(distortion * 100))%" : "Off"
        entries.append(.voiceChangerDistortion("Distortion / Overdrive", distText, distortion))

        entries.append(.voiceChangerReset("Reset Voice Effects"))
    }
    entries.append(.voiceChangerInfo("Applies real-time DSP audio processing to your outgoing voice messages."))

    return entries
}

public func toastMediaSettingsController(context: AccountContext) -> ViewController {
    let arguments = ToastMediaSettingsControllerArguments(
        context: context,
        toggleSendOriginalMedia: { value in
            ToastSettings.shared.sendOriginalMedia = value
        },
        toggleForwardWithoutQuote: { value in
            ToastSettings.shared.forwardWithoutQuote = value
        },
        toggleFreeVoiceToText: { value in
            ToastSettings.shared.freeVoiceToText = value
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
        }
    )

    let signal = combineLatest(
        context.sharedContext.presentationData,
        ToastSettings.shared.updated
    )
    |> map { presentationData, _ -> (ItemListControllerState, (ItemListNodeState, Any)) in
        let entries = toastMediaEntries(presentationData: presentationData, settings: ToastSettings.shared)
        let controllerState = ItemListControllerState(
            presentationData: ItemListPresentationData(presentationData),
            title: .text("Chats & Media"),
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
