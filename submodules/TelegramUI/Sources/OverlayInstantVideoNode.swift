import Foundation
import UIKit
import AsyncDisplayKit
import SwiftSignalKit
import Display
import TelegramCore
import TelegramPresentationData
import UniversalMediaPlayer
import TelegramUIPreferences
import TelegramAudio
import AccountContext
import AVKit
import CoreMedia

final class OverlayInstantVideoNode: OverlayMediaItemNode, AVPictureInPictureSampleBufferPlaybackDelegate, AVPictureInPictureControllerDelegate {
    private let content: UniversalVideoContent
    private let videoNode: UniversalVideoNode
    private let decoration: OverlayInstantVideoDecoration
    
    private let close: () -> Void
    
    private var validLayoutSize: CGSize?
    private var pipController: AVPictureInPictureController?
    
    override var group: OverlayMediaItemNodeGroup? {
        return OverlayMediaItemNodeGroup(rawValue: 1)
    }
    
    override var isMinimizeable: Bool {
        return true
    }
    
    var canAttachContent: Bool = true {
        didSet {
            self.videoNode.canAttachContent = self.canAttachContent
        }
    }
    
    var status: Signal<MediaPlayerStatus?, NoError> {
        return self.videoNode.status
    }
    
    var playbackEnded: (() -> Void)?
    
    init(context: AccountContext, audioSession: ManagedAudioSession, manager: UniversalVideoManager, content: UniversalVideoContent, close: @escaping () -> Void) {
        self.close = close
        self.content = content
        var togglePlayPauseImpl: (() -> Void)?
        let decoration = OverlayInstantVideoDecoration(tapped: {
            togglePlayPauseImpl?()
        })
        self.videoNode = UniversalVideoNode(context: context, postbox: context.account.postbox, audioSession: audioSession, manager: manager, decoration: decoration, content: content, priority: .secondaryOverlay, snapshotContentWhenGone: true)
        self.decoration = decoration
        
        super.init()
        
        togglePlayPauseImpl = { [weak self] in
            self?.videoNode.togglePlayPause()
        }
        
        self.addSubnode(self.videoNode)
        self.videoNode.ownsContentNodeUpdated = { [weak self] value in
            if let strongSelf = self {
                let previous = strongSelf.hasAttachedContext
                strongSelf.hasAttachedContext = value
                if previous != value {
                    strongSelf.hasAttachedContextUpdated?(value)
                }
                if value && strongSelf.pipController == nil {
                    strongSelf.setupPictureInPicture()
                }
            }
        }
        
        self.videoNode.playbackCompleted = { [weak self] in
            self?.playbackEnded?()
        }
        
        self.videoNode.canAttachContent = true
    }
    
    override func didLoad() {
        super.didLoad()
    }
    
    override func layout() {
        self.updateLayout(self.bounds.size)
    }
    
    override func preferredSizeForOverlayDisplay(boundingSize: CGSize) -> CGSize {
        if min(boundingSize.width, boundingSize.height) > 320.0 {
            return CGSize(width: 150.0, height: 150.0)
        } else {
            return CGSize(width: 120.0, height: 120.0)
        }
    }
    
    override func dismiss() {
        self.close()
    }
    
    override func updateLayout(_ size: CGSize) {
        if size != self.validLayoutSize {
            self.updateLayoutImpl(size)
        }
    }
    
    private func updateLayoutImpl(_ size: CGSize) {
        self.validLayoutSize = size
        
        self.videoNode.frame = CGRect(origin: CGPoint(), size: size)
        self.videoNode.updateLayout(size: size, transition: .immediate)
    }
    
    func play() {
        self.videoNode.play()
    }
    
    func playOnceWithSound(playAndRecord: Bool) {
        self.videoNode.playOnceWithSound(playAndRecord: playAndRecord)
    }
    
    func setSoundMuted(soundMuted: Bool) {
    }
    
    func continueWithOverridingAmbientMode(isAmbient: Bool) {
    }
    
    func pause() {
        self.videoNode.pause()
    }
    
    func togglePlayPause() {
        self.videoNode.togglePlayPause()
    }
    
    func seek(_ timestamp: Double) {
        self.videoNode.seek(timestamp)
    }
    
    func setSoundEnabled(_ soundEnabled: Bool) {
        if soundEnabled {
            self.videoNode.playOnceWithSound(playAndRecord: true)
        } else {
            self.videoNode.continuePlayingWithoutSound()
            self.videoNode.setBaseRate(1.0)
        }
    }
    
    func setBaseRate(_ baseRate: Double) {
        self.videoNode.setBaseRate(baseRate)
    }
    
    func setForceAudioToSpeaker(_ forceAudioToSpeaker: Bool) {
        self.videoNode.setForceAudioToSpeaker(forceAudioToSpeaker)
    }

    override func updateMinimizedEdge(_ edge: OverlayMediaItemMinimizationEdge?, adjusting: Bool) {
    }

    @available(iOSApplicationExtension 15.0, iOS 15.0, *)
    override public func makeNativeContentSource() -> AVPictureInPictureController.ContentSource? {
        guard let videoLayer = self.videoNode.getVideoLayer() else {
            return nil
        }
        return AVPictureInPictureController.ContentSource(sampleBufferDisplayLayer: videoLayer, playbackDelegate: self)
    }

    public func pictureInPictureController(_ pictureInPictureController: AVPictureInPictureController, setPlaying playing: Bool) {
        if playing {
            self.play()
        } else {
            self.pause()
        }
    }

    public func pictureInPictureControllerTimeRangeForPlayback(_ pictureInPictureController: AVPictureInPictureController) -> CMTimeRange {
        return CMTimeRange(start: CMTime(seconds: 0.0, preferredTimescale: CMTimeScale(30.0)), duration: CMTime(seconds: 60.0, preferredTimescale: CMTimeScale(30.0)))
    }

    public func pictureInPictureControllerIsPlaybackPaused(_ pictureInPictureController: AVPictureInPictureController) -> Bool {
        return false
    }

    public func pictureInPictureController(_ pictureInPictureController: AVPictureInPictureController, didTransitionToRenderSize newRenderSize: CMVideoDimensions) {
    }

    public func pictureInPictureController(_ pictureInPictureController: AVPictureInPictureController, skipByInterval skipInterval: CMTime, completion completionHandler: @escaping () -> Void) {
        completionHandler()
    }

    public func pictureInPictureControllerShouldProhibitBackgroundAudioPlayback(_ pictureInPictureController: AVPictureInPictureController) -> Bool {
        return false
    }

    private func setupPictureInPicture() {
        if #available(iOSApplicationExtension 15.0, iOS 15.0, *) {
            guard AVPictureInPictureController.isPictureInPictureSupported(), let source = self.makeNativeContentSource() else {
                return
            }
            let pipController = AVPictureInPictureController(contentSource: source)
            pipController.delegate = self
            pipController.canStartPictureInPictureAutomaticallyFromInline = true
            self.pipController = pipController
        }
    }

    public func startPictureInPicture() {
        if #available(iOSApplicationExtension 15.0, iOS 15.0, *) {
            if let pipController = self.pipController, pipController.isPictureInPicturePossible {
                pipController.startPictureInPicture()
            }
        }
    }

    public func pictureInPictureControllerWillStartPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
    }

    public func pictureInPictureControllerDidStartPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
    }

    public func pictureInPictureControllerWillStopPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
    }

    public func pictureInPictureControllerDidStopPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
    }

    public func pictureInPictureController(_ pictureInPictureController: AVPictureInPictureController, restoreUserInterfaceForPictureInPictureStopWithCompletionHandler completionHandler: @escaping (Bool) -> Void) {
        completionHandler(true)
    }
}
