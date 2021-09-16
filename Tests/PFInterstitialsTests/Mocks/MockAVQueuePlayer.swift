//
//  MockAVPlayer.swift
//  
//
//  Created by Robert Galluccio on 15/09/2021.
//

import Foundation
import AVFoundation

class MockAVQueuePlayer: AVQueuePlayer {
    // MARK: - Mock listeners

    var addObserverListener: ((NSObject, String, NSKeyValueObservingOptions, UnsafeMutableRawPointer?) -> Void)?
    var removeObserverListener: ((NSObject, String) -> Void)?
    var addBoundaryTimeObserverListener: (([NSValue], DispatchQueue?, () -> Void) -> Void)?
    var removeTimeObserverListener: ((Any) -> Void)?

    // MARK: - Mock return values

    var addBoundaryTimeObserverReturn: Any = NSObject()

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

    override func addBoundaryTimeObserver(
        forTimes times: [NSValue],
        queue: DispatchQueue?,
        using block: @escaping () -> Void
    ) -> Any {
        addBoundaryTimeObserverListener?(times, queue, block)
        return addBoundaryTimeObserverReturn
    }

    override func removeTimeObserver(_ observer: Any) {
        removeTimeObserverListener?(observer)
    }
}
