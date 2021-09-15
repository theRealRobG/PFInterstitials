//
//  AVFoundationExtensionsTests.swift
//  
//
//  Created by Robert Galluccio on 15/09/2021.
//

import Foundation
import AVFoundation
import XCTest
@testable import PFInterstitials

class AVFoundationExtensionsTests: XCTestCase {
    func test_AVPlayerItem_url_shouldGetURLFromAVURLAsset() {
        let expectedURL = URL(string: "http://test.com/master.m3u8")!
        let item = AVPlayerItem(asset: AVURLAsset(url: expectedURL))
        XCTAssertEqual(expectedURL, item.url)
    }

    func test_AVPlayerItem_interstitialEventIdentifier_shouldBeAbleToGetAndSet() {
        let expectedId = "test-id"
        let item = AVPlayerItem(url: URL(string: "http://test.com/master.m3u8")!)
        XCTAssertNil(item.interstitialEventIdentifier)
        item.interstitialEventIdentifier = expectedId
        XCTAssertEqual(expectedId, item.interstitialEventIdentifier)
    }

    func test_AVPlayerItem_copyPreservingEventIdentifier_shouldPreserveEventId() {
        let expectedId = "test-id"
        let item = AVPlayerItem(url: URL(string: "http://test.com/master.m3u8")!)
        item.interstitialEventIdentifier = expectedId
        XCTAssertEqual(expectedId, item.interstitialEventIdentifier)
        guard let copiedItem = item.copyPreservingEventIdentifier() as? AVPlayerItem else {
            return XCTFail("Copied item was not AVPlayerItem")
        }
        XCTAssertEqual(expectedId, copiedItem.interstitialEventIdentifier)
        XCTAssert(item !== copiedItem)
    }
}
