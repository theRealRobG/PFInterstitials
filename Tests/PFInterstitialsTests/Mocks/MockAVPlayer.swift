//
//  MockAVPlayer.swift
//  
//
//  Created by Robert Galluccio on 15/09/2021.
//

import Foundation
import AVFoundation

class MockAVPlayer: AVPlayer {
    // MARK: - Mock listeners

    var addObserverListener: ((NSObject, String, NSKeyValueObservingOptions, UnsafeMutableRawPointer?) -> Void)?
    var removeObserverListener: ((NSObject, String) -> Void)?

    // MARK: - Override properties

    override var currentItem: AVPlayerItem? { fakeCurrentItem }
    var fakeCurrentItem: MockAVPlayerItem?

    // MARK: - Override functions

    override func addObserver(
        _ observer: NSObject,
        forKeyPath keyPath: String,
        options: NSKeyValueObservingOptions = [],
        context: UnsafeMutableRawPointer?
    ) {
        addObserverListener?(observer, keyPath, options, context)
    }

    override func removeObserver(_ observer: NSObject, forKeyPath keyPath: String) {
        removeObserverListener?(observer, keyPath)
    }
}
