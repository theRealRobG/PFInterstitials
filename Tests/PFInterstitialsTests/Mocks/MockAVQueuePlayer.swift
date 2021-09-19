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
    var insertListener: ((AVPlayerItem, AVPlayerItem?) -> Void)?
    var itemsListener: (() -> Void)?
    var removeAllItemsListener: (() -> Void)?

    // MARK: - Mock return values

    var addBoundaryTimeObserverReturnValue: Any = NSObject()
    var itemsReturnValue = [MockAVPlayerItem]()

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
        return addBoundaryTimeObserverReturnValue
    }

    override func removeTimeObserver(_ observer: Any) {
        removeTimeObserverListener?(observer)
    }

    override func insert(_ item: AVPlayerItem, after afterItem: AVPlayerItem?) {
        insertListener?(item, afterItem)
    }

    override func items() -> [AVPlayerItem] {
        itemsListener?()
        return itemsReturnValue
    }

    override func removeAllItems() {
        removeAllItemsListener?()
    }
}
