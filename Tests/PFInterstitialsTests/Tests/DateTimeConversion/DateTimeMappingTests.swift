//
//  DateTimeMappingTests.swift
//  
//
//  Created by Robert Galluccio on 27/09/2021.
//

import Foundation
import AVFoundation
import XCTest
@testable import PFInterstitials

class DateTimeMappingTests: XCTestCase {
    func test_time_forDate_shouldCalculateBasedOfReferenceMapping() {
        let mapping = DateTimeMapping(date: Date(timeIntervalSince1970: 0), time: .zero)
        XCTAssertEqual(CMTime(value: 10, timescale: 1), mapping.time(forDate: Date(timeIntervalSince1970: 10)))
        XCTAssertEqual(CMTime(value: -10, timescale: 1), mapping.time(forDate: Date(timeIntervalSince1970: -10)))
        XCTAssertEqual(CMTime(value: 0, timescale: 1), mapping.time(forDate: Date(timeIntervalSince1970: 0)))
    }

    func test_date_forTime_shouldCalculateBasedOfReferenceMapping() {
        let mapping = DateTimeMapping(date: Date(timeIntervalSince1970: 0), time: .zero)
        XCTAssertEqual(Date(timeIntervalSince1970: 10), mapping.date(forTime: CMTime(value: 10, timescale: 1)))
        XCTAssertEqual(Date(timeIntervalSince1970: -10), mapping.date(forTime: CMTime(value: -10, timescale: 1)))
        XCTAssertEqual(Date(timeIntervalSince1970: 0), mapping.date(forTime: CMTime(value: 0, timescale: 1)))
    }
}
