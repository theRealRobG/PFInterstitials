//
//  PlayerObserverTests.swift
//  
//
//  Created by Robert Galluccio on 15/09/2021.
//

import Foundation
import AVFoundation
import XCTest
@testable import PFInterstitials

class PlayerObserverTests: XCTestCase {
    func test_init_shouldAddObserver() {
        let addObserverExp = expectation(description: "wait for add observer")
        let player = MockAVQueuePlayer()
        player.addObserverListener = { observer, keyPath, options, context in
            XCTAssert(observer is PlayerObserver)
            XCTAssertEqual(keyPath, #keyPath(AVPlayer.currentItem))
            XCTAssertEqual(options, [])
            XCTAssertNil(context)
            addObserverExp.fulfill()
        }
        _ = PlayerObserver(player: player)
        wait(for: [addObserverExp], timeout: 0.1)
    }

    func test_deinit_shouldRemoveObserver() {
        let removeObserverExp = expectation(description: "wait for remove observer")
        let player = MockAVQueuePlayer()
        var sut: PlayerObserver? = PlayerObserver(player: player)
        player.removeObserverListener = { _, keyPath in
            XCTAssertEqual(keyPath, #keyPath(AVPlayer.currentItem))
            removeObserverExp.fulfill()
        }
        // The XCTAssertNotNil is to silence the warning above. We need to keep it referenced
        // because otherwise it is derefernced too quickly.
        XCTAssertNotNil(sut)
        sut = nil
        wait(for: [removeObserverExp], timeout: 0.1)
    }

    func test_observeValue_whenCurrentItem_shouldNotifyDelegate() {
        let delegateExp = expectation(description: "wait for delegate notification")
        let delegate = MockPlayerObserverDelegate()
        let expectedPlayer = MockAVQueuePlayer()
        let expectedItem = MockAVPlayerItem(url: URL(string: "https://test.com/master.m3u8")!)
        let sut = PlayerObserver(player: expectedPlayer)
        sut.delegate = delegate
        delegate.didChangeCurrentItemListener = { player, item in
            XCTAssert(player === expectedPlayer)
            XCTAssert(item === expectedItem)
            delegateExp.fulfill()
        }
        expectedPlayer.fakeCurrentItem = expectedItem
        sut.observeValue(
            forKeyPath: #keyPath(AVPlayer.currentItem),
            of: nil,
            change: nil,
            context: nil
        )
        wait(for: [delegateExp], timeout: 0.1)
    }
}
