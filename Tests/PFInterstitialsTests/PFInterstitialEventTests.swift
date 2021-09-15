//
//  PFInterstitialEventTests.swift
//  
//
//  Created by Robert Galluccio on 15/09/2021.
//

import AVFoundation
import XCTest
@testable import PFInterstitials

class PFInterstitialEventTests: XCTestCase {
    func test_init_whenIdentifierPassed_shouldSetIdentifierOnTemplateItems() {
        let expectedId = "event-test-id"
        let urls = [1, 2, 3].compactMap { URL(string: "http://test.com/\($0)/master.m3u8") }
        let items = urls.map { AVPlayerItem(url: $0) }
        let event = PFInterstitialEvent(
            primaryItem: nil,
            identifier: expectedId,
            time: .zero,
            templateItems: items
        )
        for item in event.templateItems {
            XCTAssertEqual(expectedId, item.interstitialEventIdentifier)
        }
    }

    func test_init_whenNoIdentifierPassed_shouldSetUUIDOnTemplateItems() {
        let urls = [1, 2, 3].compactMap { URL(string: "http://test.com/\($0)/master.m3u8") }
        let items = urls.map { AVPlayerItem(url: $0) }
        let event = PFInterstitialEvent(
            primaryItem: nil,
            identifier: nil,
            time: .zero,
            templateItems: items
        )
        for item in event.templateItems {
            XCTAssertNotNil(item.interstitialEventIdentifier)
        }
    }
}
