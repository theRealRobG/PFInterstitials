//
//  PlayerObserver.swift
//  
//
//  Created by Robert Galluccio on 15/09/2021.
//

import Foundation
import AVFoundation

protocol PlayerObserverDelegate: AnyObject {
    func player(_ player: AVPlayer, didChangeCurrentItem currentItem: AVPlayerItem?)
}

class PlayerObserver: NSObject {
    weak var delegate: PlayerObserverDelegate?
    private weak var player: AVPlayer?

    init(player: AVPlayer) {
        self.player = player
        super.init()
        startObserving()
    }

    deinit {
        stopObserving()
    }

    override func observeValue(
        forKeyPath keyPath: String?,
        of object: Any?,
        change: [NSKeyValueChangeKey: Any]?,
        context: UnsafeMutableRawPointer?
    ) {
        guard let player = self.player else { return }
        switch keyPath {
        case #keyPath(AVPlayer.currentItem):
            delegate?.player(player, didChangeCurrentItem: player.currentItem)
        default:
            break
        }
    }

    private func startObserving() {
        guard let player = self.player else { return }
        player.addObserver(
            self,
            forKeyPath: #keyPath(AVPlayer.currentItem),
            options: [],
            context: nil
        )
    }

    private func stopObserving() {
        guard let player = self.player else { return }
        player.removeObserver(self, forKeyPath: #keyPath(AVPlayer.currentItem))
    }
}
