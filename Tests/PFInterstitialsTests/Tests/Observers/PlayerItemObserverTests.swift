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
    var mockDelegate: MockPlayerItemObserverDelegate!

    override func setUp() {
        sut = PlayerItemObserver()
        mockDelegate = MockPlayerItemObserverDelegate()
        sut.delegate = mockDelegate
    }

    func test_startObserving_shouldAddObserver() {
        let addObserverExp = expectation(description: "wait for add observer")
        let item = MockAVPlayerItem(url: URL(string: "http://test.com/master.m3u8")!)
        item.addObserverListener = { object, keyPath, options, context in
            XCTAssert(object === self.sut)
            XCTAssertEqual(keyPath, #keyPath(AVPlayerItem.loadedTimeRanges))
            XCTAssertEqual(options, [])
            XCTAssertNil(context)
            addObserverExp.fulfill()
        }
        sut.startObserving(playerItem: item)
        wait(for: [addObserverExp], timeout: 0.1)
    }

    func test_startObserving_shouldRemovePreviouslySetObserverBeforeAddingNewOne() {
        let addFirstObserverExp = expectation(description: "wait for add first observer")
        let removeFirstObserverExp = expectation(description: "wait for remove first observer")
        let addSecondObserverExp = expectation(description: "wait for add second observer")
        let item1 = MockAVPlayerItem(url: URL(string: "http://test.com/1/master.m3u8")!)
        let item2 = MockAVPlayerItem(url: URL(string: "http://test.com/2/master.m3u8")!)
        item1.addObserverListener = { _, _, _, _ in addFirstObserverExp.fulfill() }
        item1.removeObserverListener = { _, _ in removeFirstObserverExp.fulfill() }
        item2.addObserverListener = { _, _, _, _ in addSecondObserverExp.fulfill() }
        sut.startObserving(playerItem: item1)
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
        let removeObserverExp = expectation(description: "wait for remove first observer")
        let item = MockAVPlayerItem(url: URL(string: "http://test.com/master.m3u8")!)
        item.removeObserverListener = { _, _ in removeObserverExp.fulfill() }
        sut.startObserving(playerItem: item)
        sut.stopObserving()
        wait(for: [removeObserverExp], timeout: 0.1)
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

    func test_deinit_shouldRemoveObserver() {
        let removeObserverExp = expectation(description: "wait for remove first observer")
        let item = MockAVPlayerItem(url: URL(string: "http://test.com/master.m3u8")!)
        item.removeObserverListener = { _, _ in removeObserverExp.fulfill() }
        sut.startObserving(playerItem: item)
        sut = nil
        wait(for: [removeObserverExp], timeout: 0.1)
    }
}
