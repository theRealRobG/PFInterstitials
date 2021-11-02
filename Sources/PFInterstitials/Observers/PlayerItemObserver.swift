//
//  PlayerItemObserver.swift
//  
//
//  Created by Robert Galluccio on 15/09/2021.
//

import Foundation
import AVFoundation

protocol PlayerItemObserverDelegate: AnyObject {
    func playerItem(_ playerItem: AVPlayerItem, didUpdateLoadedTimeRanges loadedTimeRanges: [NSValue])
    func playerItem(_ playerItem: AVPlayerItem, didUpdateEffectiveRate effectiveRate: Double)
}

class PlayerItemObserver: NSObject {
    weak var delegate: PlayerItemObserverDelegate?
    private weak var playerItem: AVPlayerItem?
    private let notificationCenter: NotificationCenter

    init(notificationCenter: NotificationCenter = .default) {
        self.notificationCenter = notificationCenter
        super.init()
    }

    deinit {
        stopObserving()
    }

    func startObserving(playerItem: AVPlayerItem) {
        stopObserving()
        self.playerItem = playerItem
        playerItem.addObserver(
            self,
            forKeyPath: #keyPath(AVPlayerItem.loadedTimeRanges),
            options: [],
            context: nil
        )
        notificationCenter.addObserver(
            self,
            selector: #selector(effectiveRateDidChange),
            name: NSNotification.Name(kCMTimebaseNotification_EffectiveRateChanged as String),
            object: nil
        )
    }

    func stopObserving() {
        guard let playerItem = self.playerItem else { return }
        playerItem.removeObserver(self, forKeyPath: #keyPath(AVPlayerItem.loadedTimeRanges))
        notificationCenter.removeObserver(
            self,
            name: NSNotification.Name(kCMTimebaseNotification_EffectiveRateChanged as String),
            object: nil
        )
    }

    override func observeValue(
        forKeyPath keyPath: String?,
        of object: Any?,
        change: [NSKeyValueChangeKey: Any]?,
        context: UnsafeMutableRawPointer?
    ) {
        guard let playerItem = playerItem else { return }
        switch keyPath {
        case #keyPath(AVPlayerItem.loadedTimeRanges):
            delegate?.playerItem(playerItem, didUpdateLoadedTimeRanges: playerItem.loadedTimeRanges)
        default:
            break
        }
    }

    @objc
    private func effectiveRateDidChange() {
        guard let playerItem = playerItem, let timebase = playerItem.timebase else { return }
        delegate?.playerItem(playerItem, didUpdateEffectiveRate: CMTimebaseGetEffectiveRate(timebase))
    }
}
