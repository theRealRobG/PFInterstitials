//
//  PlayerItemObserverTests.swift
//  
//
//  Created by Robert Galluccio on 15/09/2021.
//

import Foundation
import AVFoundation
import XCTest
@testable import PFInterstitials

class PlayerItemObserverTests: XCTestCase {
    var sut: PlayerItemObserver!
    var mockNotificationCenter: MockNotificationCenter!
    var mockDelegate: MockPlayerItemObserverDelegate!

    override func setUp() {
        mockNotificationCenter = MockNotificationCenter()
        sut = PlayerItemObserver(notificationCenter: mockNotificationCenter)
        mockDelegate = MockPlayerItemObserverDelegate()
        sut.delegate = mockDelegate
    }

    func test_startObserving_shouldAddObserver() {
        let addItemObserverExp = expectation(description: "wait for add item observer")
        let addNotificationCenterObserverExp = expectation(description: "wait for add notification observer")
        let item = MockAVPlayerItem(url: URL(string: "http://test.com/master.m3u8")!)
        item.addObserverListener = { object, keyPath, options, context in
            XCTAssert(object === self.sut)
            XCTAssertEqual(keyPath, #keyPath(AVPlayerItem.loadedTimeRanges))
            XCTAssertEqual(options, [])
            XCTAssertNil(context)
            addItemObserverExp.fulfill()
        }
        mockNotificationCenter.addObserverListener = { observer, _, name, object in
            XCTAssert((observer as? PlayerItemObserver) === self.sut)
            XCTAssertEqual(name, NSNotification.Name(kCMTimebaseNotification_EffectiveRateChanged as String))
            XCTAssertNil(object)
            addNotificationCenterObserverExp.fulfill()
        }
        sut.startObserving(playerItem: item)
        wait(for: [addItemObserverExp, addNotificationCenterObserverExp], timeout: 0.1)
    }

    func test_startObserving_shouldRemovePreviouslySetObserverBeforeAddingNewOne() {
        let addFirstObserverExp = expectation(description: "wait for add first observer")
        addFirstObserverExp.expectedFulfillmentCount = 2
        let removeFirstObserverExp = expectation(description: "wait for remove first observer")
        removeFirstObserverExp.expectedFulfillmentCount = 2
        let addSecondObserverExp = expectation(description: "wait for add second observer")
        addSecondObserverExp.expectedFulfillmentCount = 2
        let item1 = MockAVPlayerItem(url: URL(string: "http://test.com/1/master.m3u8")!)
        let item2 = MockAVPlayerItem(url: URL(string: "http://test.com/2/master.m3u8")!)
        item1.addObserverListener = { _, _, _, _ in addFirstObserverExp.fulfill() }
        item1.removeObserverListener = { _, _ in removeFirstObserverExp.fulfill() }
        item2.addObserverListener = { _, _, _, _ in addSecondObserverExp.fulfill() }
        mockNotificationCenter.addObserverListener = { _, _, _, _ in addFirstObserverExp.fulfill() }
        mockNotificationCenter.removeObserverListener = { _, _, _ in removeFirstObserverExp.fulfill() }
        sut.startObserving(playerItem: item1)
        mockNotificationCenter.addObserverListener = { _, _, _, _ in addSecondObserverExp.fulfill() }
        sut.startObserving(playerItem: item2)
        wait(
            for: [
                addFirstObserverExp,
                removeFirstObserverExp,
                addSecondObserverExp
            ],
            timeout: 0.1,
            enforceOrder: true
        )
    }

    func test_stopObserving_shouldRemoveObserver() {
        let removeItemObserverExp = expectation(description: "wait for remove first item observer")
        let removeNotificationObserverExp = expectation(description: "wait for remove notification observer")
        let item = MockAVPlayerItem(url: URL(string: "http://test.com/master.m3u8")!)
        item.removeObserverListener = { object, keyPath in
            XCTAssert((object as? PlayerItemObserver) === self.sut)
            XCTAssertEqual(keyPath, #keyPath(AVPlayerItem.loadedTimeRanges))
            removeItemObserverExp.fulfill()
        }
        mockNotificationCenter.removeObserverListener = { observer, name, object in
            XCTAssert((observer as? PlayerItemObserver) === self.sut)
            XCTAssertEqual(name, NSNotification.Name(kCMTimebaseNotification_EffectiveRateChanged as String))
            XCTAssertNil(object)
            removeNotificationObserverExp.fulfill()
        }
        sut.startObserving(playerItem: item)
        sut.stopObserving()
        wait(for: [removeItemObserverExp, removeNotificationObserverExp], timeout: 0.1)
    }

    func test_observeValue_shouldNotifyLoadedTimeRanges() {
        let delegateExp = expectation(description: "wait for notification of delegate")
        let expectedItem = MockAVPlayerItem(url: URL(string: "http://test.com/master.m3u8")!)
        let expectedRange = NSValue(
            timeRange: CMTimeRange(
                start: .zero,
                end: CMTime(value: 100, timescale: 1)
            )
        )
        mockDelegate.didUpdateLoadedTimeRangesListener = { item, ranges in
            XCTAssert(item === expectedItem)
            XCTAssertEqual(ranges, [expectedRange])
            delegateExp.fulfill()
        }
        sut.startObserving(playerItem: expectedItem)
        expectedItem.fakeLoadedTimeRanges = [expectedRange]
        sut.observeValue(
            forKeyPath: #keyPath(AVPlayerItem.loadedTimeRanges),
            of: nil,
            change: nil,
            context: nil
        )
        wait(for: [delegateExp], timeout: 0.1)
    }

    func test_notification_shouldNotifyEffectiveRate() {
        let delegateExp = expectation(description: "wait for notification of delegate")
        let expectedItem = MockAVPlayerItem(url: URL(string: "http://test.com/master.m3u8")!)
        var selector: Selector?
        mockNotificationCenter.addObserverListener = { _, aSelector, _, _ in
            selector = aSelector
        }
        mockDelegate.didUpdateEffectiveRateListener = { item, rate in
            XCTAssert(item === expectedItem)
            XCTAssertEqual(rate, 0)
            delegateExp.fulfill()
        }
        sut.startObserving(playerItem: expectedItem)
        guard let effectiveRateChangedSelector = selector else { return XCTFail() }
        sut.performSelector(onMainThread: effectiveRateChangedSelector, with: nil, waitUntilDone: false)
        wait(for: [delegateExp], timeout: 0.1)
    }

    func test_deinit_shouldRemoveObserver() {
        let removeItemObserverExp = expectation(description: "wait for remove first observer")
        let removeNotificationObserverExp = expectation(description: "wait for remove notification observer")
        let item = MockAVPlayerItem(url: URL(string: "http://test.com/master.m3u8")!)
        item.removeObserverListener = { _, _ in removeItemObserverExp.fulfill() }
        mockNotificationCenter.removeObserverListener = { _, _, _ in removeNotificationObserverExp.fulfill() }
        sut.startObserving(playerItem: item)
        sut = nil
        wait(for: [removeItemObserverExp, removeNotificationObserverExp], timeout: 0.1)
    }
}
