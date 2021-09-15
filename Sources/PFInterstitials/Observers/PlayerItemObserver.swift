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
}

class PlayerItemObserver: NSObject {
    weak var delegate: PlayerItemObserverDelegate?
    private weak var playerItem: AVPlayerItem?

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
    }

    func stopObserving() {
        guard let playerItem = self.playerItem else { return }
        playerItem.removeObserver(self, forKeyPath: #keyPath(AVPlayer.currentItem))
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
}
