import Foundation
import Postbox
import TelegramApi
import SwiftSignalKit

public enum SavedStickerResult {
    case generic
    case limitExceeded(Int32, Int32)
}

func _internal_toggleStickerSaved(postbox: Postbox, network: Network, accountPeerId: PeerId, file: TelegramMediaFile, saved: Bool) -> Signal<SavedStickerResult, AddSavedStickerError> {
    if saved {
        return postbox.transaction { _ -> Signal<SavedStickerResult, AddSavedStickerError> in
            return addSavedSticker(postbox: postbox, network: network, file: file, limit: Int.max)
            |> map { _ -> SavedStickerResult in
                return .generic
            }
            |> filter { _ in
                return false
            }
            |> then(
                .single(.generic)
            )
        }
        |> castError(AddSavedStickerError.self)
        |> switchToLatest
    } else {
        return removeSavedSticker(postbox: postbox, mediaId: file.fileId)
        |> map { _ -> SavedStickerResult in
            return .generic
        }
        |> castError(AddSavedStickerError.self)
    }
}
