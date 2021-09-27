//
//  DateTimeConverterTests.swift
//  
//
//  Created by Robert Galluccio on 27/09/2021.
//

import Foundation
import AVFoundation
import XCTest
@testable import PFInterstitials

class DateTimeConverterTests: XCTestCase {
    var sut: DateTimeConverter!

    override func setUp() {
        sut = DateTimeConverter()
    }

    func test_time_forDate_whenNoMappingsAdded_shouldNotProvideTime() {
        XCTAssertNil(sut.time(forDate: Date(timeIntervalSince1970: 0)))
    }

    func test_date_forTime_whenNoMappingsAdded_shouldNotProvideTime() {
        XCTAssertNil(sut.date(forTime: .zero))
    }

    func test_time_forDate_whenOneMapping_shouldUseMappingToProvideTime() {
        let timeExp = expectation(description: "wait for get time")
        let expectedTime = CMTime(value: 100, timescale: 1)
        let expectedDate = Date(timeIntervalSince1970: 100)
        let mockMapping = MockDateTimeConversion()
        mockMapping.timeForDateReturnValue = expectedTime
        mockMapping.timeForDateListener = { date in
            XCTAssertEqual(expectedDate, date)
            timeExp.fulfill()
        }
        sut.add(mapping: mockMapping)
        XCTAssertEqual(expectedTime, sut.time(forDate: expectedDate))
        wait(for: [timeExp], timeout: 0.1)
    }

    func test_date_forTime_whenOneMapping_shouldUseMappingToProvideDate() {
        let dateExp = expectation(description: "wait for get date")
        let expectedTime = CMTime(value: 100, timescale: 1)
        let expectedDate = Date(timeIntervalSince1970: 100)
        let mockMapping = MockDateTimeConversion()
        mockMapping.dateForTimeReturnValue = expectedDate
        mockMapping.dateForTimeListener = { time in
            XCTAssertEqual(expectedTime, time)
            dateExp.fulfill()
        }
        sut.add(mapping: mockMapping)
        XCTAssertEqual(expectedDate, sut.date(forTime: expectedTime))
        wait(for: [dateExp], timeout: 0.1)
    }

    func test_time_forDate_whenMultipleMappings_shouldUseMappingWithDateRangeContainingDate() {
        let timeExp = expectation(description: "wait for get time")
        timeExp.expectedFulfillmentCount = 1
        let mocks = getRegularMappings(times: 0, 100, 200)
        mocks.forEach { sut.add(mapping: $0) }
        mocks.forEach { mock in
            mock.timeForDateListener = { _ in
                XCTAssert(mock === mocks[1])
                timeExp.fulfill()
                mock.timeForDateListener = nil
            }
        }
        _ = sut.time(forDate: Date(timeIntervalSince1970: 180))
        wait(for: [timeExp], timeout: 0.1)
    }

    func test_time_forDate_whenDateIsBeforeAnyMapping_shouldUseFirstMapping() {
        let timeExp = expectation(description: "wait for get time")
        timeExp.expectedFulfillmentCount = 1
        let mocks = getRegularMappings(times: 0, 100, 200)
        mocks.forEach { sut.add(mapping: $0) }
        mocks.forEach { mock in
            mock.timeForDateListener = { _ in
                XCTAssert(mock === mocks[0])
                timeExp.fulfill()
                mock.timeForDateListener = nil
            }
        }
        _ = sut.time(forDate: Date(timeIntervalSince1970: -100))
        wait(for: [timeExp], timeout: 0.1)
    }

    func test_time_forDate_whenDateIsAfterAllMappings_shouldUseLastMapping() {
        let timeExp = expectation(description: "wait for get time")
        timeExp.expectedFulfillmentCount = 1
        let mocks = getRegularMappings(times: 0, 100, 200)
        mocks.forEach { sut.add(mapping: $0) }
        mocks.forEach { mock in
            mock.timeForDateListener = { _ in
                XCTAssert(mock === mocks[2])
                timeExp.fulfill()
                mock.timeForDateListener = nil
            }
        }
        _ = sut.time(forDate: Date(timeIntervalSince1970: 500))
        wait(for: [timeExp], timeout: 0.1)
    }

    func test_time_forDate_whenDateIsInDateRangeGap_shouldNotReturnTime() {
        let timeExp = expectation(description: "wait for get time")
        timeExp.isInverted = true
        var mocks = getRegularMappings(times: 0, 100)
        mocks.append(MockDateTimeConversion(date: Date(timeIntervalSince1970: 300), time: CMTime(value: 200, timescale: 1)))
        mocks.forEach { sut.add(mapping: $0) }
        mocks.forEach { mock in
            mock.timeForDateListener = { _ in timeExp.fulfill() }
        }
        _ = sut.time(forDate: Date(timeIntervalSince1970: 250))
        wait(for: [timeExp], timeout: 0.1)
    }

    func test_date_forTime_whenMultipleMappings_shouldUseMappingWithForLastTimeLessThanDesiredTime() {
        let dateExp = expectation(description: "wait for get date")
        dateExp.expectedFulfillmentCount = 1
        let mocks = getRegularMappings(times: 0, 100, 200)
        mocks.forEach { sut.add(mapping: $0) }
        mocks.forEach { mock in
            mock.dateForTimeListener = { _ in
                XCTAssert(mock === mocks[1])
                dateExp.fulfill()
                mock.dateForTimeListener = nil
            }
        }
        _ = sut.date(forTime: CMTime(value: 180, timescale: 1))
        wait(for: [dateExp], timeout: 0.1)
    }

    func test_date_forTime_whenTimeIsBeforeAnyMapping_shouldUseFirstMapping() {
        let dateExp = expectation(description: "wait for get date")
        dateExp.expectedFulfillmentCount = 1
        let mocks = getRegularMappings(times: 0, 100, 200)
        mocks.forEach { sut.add(mapping: $0) }
        mocks.forEach { mock in
            mock.dateForTimeListener = { _ in
                XCTAssert(mock === mocks[0])
                dateExp.fulfill()
                mock.dateForTimeListener = nil
            }
        }
        _ = sut.date(forTime: CMTime(value: -100, timescale: 1))
        wait(for: [dateExp], timeout: 0.1)
    }

    func test_date_forTime_whenTimeIsAfterAllMappings_shouldUseLastMapping() {
        let dateExp = expectation(description: "wait for get date")
        dateExp.expectedFulfillmentCount = 1
        let mocks = getRegularMappings(times: 0, 100, 200)
        mocks.forEach { sut.add(mapping: $0) }
        mocks.forEach { mock in
            mock.dateForTimeListener = { _ in
                XCTAssert(mock === mocks[2])
                dateExp.fulfill()
                mock.dateForTimeListener = nil
            }
        }
        _ = sut.date(forTime: CMTime(value: 500, timescale: 1))
        wait(for: [dateExp], timeout: 0.1)
    }

    func test_update_playbackTimeRanges_whenRangeDoesNotIncludeMapping_shouldRemoveMapping() {
        let deinitExp = expectation(description: "wait for deinit")
        sut.add(mapping: DeinitConversion(onDeinit: deinitExp.fulfill()))
        sut.add(mapping: MockDateTimeConversion(date: Date(timeIntervalSince1970: 100), time: CMTime(value: 100, timescale: 1)))
        sut.update(playbackTimeRange: CMTimeRange(start: CMTime(value: 150, timescale: 1), end: CMTime(value: 250, timescale: 1)))
        wait(for: [deinitExp], timeout: 0.1)
    }

    func test_update_playbackTimeRanges_whenRangeStillIncludesMapping_shouldNotRemoveMapping() {
        let deinitExp = expectation(description: "wait for deinit")
        deinitExp.isInverted = true
        sut.add(mapping: DeinitConversion(onDeinit: deinitExp.fulfill()))
        sut.add(mapping: MockDateTimeConversion(date: Date(timeIntervalSince1970: 100), time: CMTime(value: 100, timescale: 1)))
        sut.update(playbackTimeRange: CMTimeRange(start: CMTime(value: -100, timescale: 1), end: CMTime(value: 250, timescale: 1)))
        wait(for: [deinitExp], timeout: 0.1)
    }

    func test_update_playbackTimeRanges_whenRangeStillIncludesSomeRangeBetweenMappingAndNext_shouldNotRemoveMapping() {
        let deinitExp = expectation(description: "wait for deinit")
        deinitExp.isInverted = true
        sut.add(mapping: DeinitConversion(onDeinit: deinitExp.fulfill()))
        sut.add(mapping: MockDateTimeConversion(date: Date(timeIntervalSince1970: 100), time: CMTime(value: 100, timescale: 1)))
        sut.update(playbackTimeRange: CMTimeRange(start: CMTime(value: 50, timescale: 1), end: CMTime(value: 250, timescale: 1)))
        wait(for: [deinitExp], timeout: 0.1)
    }
}

private extension DateTimeConverterTests {
    func getRegularMappings(times: Int...) -> [MockDateTimeConversion] {
        times.map {
            MockDateTimeConversion(
                date: Date(timeIntervalSince1970: TimeInterval($0)),
                time: CMTime(value: CMTimeValue($0), timescale: 1)
            )
        }
    }

    class DeinitConversion: DateTimeConversion {
        let date: Date
        let time: CMTime

        private var deinitCompletion: () -> Void

        init(
            date: Date = Date(timeIntervalSince1970: 0),
            time: CMTime = .zero,
            onDeinit deinitCompletion: @escaping @autoclosure () -> Void
        ) {
            self.date = date
            self.time = time
            self.deinitCompletion = deinitCompletion
        }

        deinit { deinitCompletion() }

        func time(forDate date: Date) -> CMTime { self.time }
        func date(forTime time: CMTime) -> Date { self.date }
    }
}
