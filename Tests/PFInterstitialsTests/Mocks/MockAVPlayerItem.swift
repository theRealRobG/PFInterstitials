//
//  MockAVPlayerItem.swift
//  
//
//  Created by Robert Galluccio on 15/09/2021.
//

import Foundation
import AVFoundation

class MockAVPlayerItem: AVPlayerItem {
    // MARK: - Mock listeners

    var addObserverListener: ((NSObject, String, NSKeyValueObservingOptions, UnsafeMutableRawPointer?) -> Void)?
    var removeObserverListener: ((NSObject, String) -> Void)?
    var currentTimeListener: (() -> Void)?

    // MARK: - Mock return values

    var currentTimeReturnValue = CMTime.zero

    // MARK: - Override properties

    override var loadedTimeRanges: [NSValue] { fakeLoadedTimeRanges }
    var fakeLoadedTimeRanges = [NSValue]()

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

    override func currentTime() -> CMTime {
        currentTimeListener?()
        return currentTimeReturnValue
    }
}
