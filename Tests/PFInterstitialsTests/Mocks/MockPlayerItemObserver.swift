//
//  MockPlayerItemObserver.swift
//  
//
//  Created by Robert Galluccio on 16/09/2021.
//

import Foundation
import AVFoundation
@testable import PFInterstitials

class MockPlayerItemObserver: PlayerItemObserver {
    var startObservingListener: ((AVPlayerItem) -> Void)?
    var stopObservingListener: (() -> Void)?
    var observeValueListener: ((String?, Any?, [NSKeyValueChangeKey: Any]?, UnsafeMutableRawPointer?) -> Void)?

    override func startObserving(playerItem: AVPlayerItem) {
        startObservingListener?(playerItem)
    }

    override func stopObserving() {
        stopObservingListener?()
    }

    override func observeValue(
        forKeyPath keyPath: String?,
        of object: Any?,
        change: [NSKeyValueChangeKey: Any]?,
        context: UnsafeMutableRawPointer?
    ) {
        observeValueListener?(keyPath, object, change, context)
    }
}
