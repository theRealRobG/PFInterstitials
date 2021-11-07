//
//  DateTimeServiceTests.swift
//  
//
//  Created by Robert Galluccio on 02/11/2021.
//

@testable import PFInterstitials
import XCTest
import CoreMedia

class DateTimeServiceTests: XCTestCase {
    var sut: DateTimeService!
    var mockPrimaryPlayer: MockAVQueuePlayer!
    var mockPrimaryPlayerItem: MockAVPlayerItem!
    var mockPlayerObserver: MockPlayerObserver!
    var mockPlayerItemObserver: MockPlayerItemObserver!
    var mockDateTimeConverter: MockDateTimeConverter!

    override func setUp() {
        mockPrimaryPlayerItem = MockAVPlayerItem(url: URL(string: "http://test.com/master.m3u8")!)
        mockPrimaryPlayer = MockAVQueuePlayer(playerItem: mockPrimaryPlayerItem)
        mockPlayerObserver = MockPlayerObserver()
        mockPlayerItemObserver = MockPlayerItemObserver()
        mockDateTimeConverter = MockDateTimeConverter()
        sut = DateTimeService(
            currentPrimaryPlayerItem: mockPrimaryPlayerItem,
            playerObserver: mockPlayerObserver,
            playerItemObserver: mockPlayerItemObserver,
            dateTimeConverter: mockDateTimeConverter
        )
    }

    func test_init_shouldSetSelfAsDelegateOnObservers() {
        XCTAssert(sut === mockPlayerObserver.delegate)
        XCTAssert(sut === mockPlayerItemObserver.delegate)
    }

    func test_date_shouldUseDateTimeConverterForDate() {
        let dateForTimeExp = expectation(description: "wait for get date for time")
        let expectedTime = CMTime(value: 10, timescale: 1)
        let expectedDate = Date(timeIntervalSince1970: 100)
        mockDateTimeConverter.dateForTimeListener = { time in
            XCTAssertEqual(time, expectedTime)
            dateForTimeExp.fulfill()
        }
        mockDateTimeConverter.dateForTimeReturnValue = expectedDate
        XCTAssertEqual(sut.date(forTime: expectedTime), expectedDate)
        wait(for: [dateForTimeExp], timeout: 0.1)
    }

    func test_time_shouldUseDateTimeConverterForTime() {
        let timeForDateExp = expectation(description: "wait for get time for date")
        let expectedTime = CMTime(value: 10, timescale: 1)
        let expectedDate = Date(timeIntervalSince1970: 100)
        mockDateTimeConverter.timeForDateListener = { date in
            XCTAssertEqual(date, expectedDate)
            timeForDateExp.fulfill()
        }
        mockDateTimeConverter.timeForDateReturnValue = expectedTime
        XCTAssertEqual(sut.time(forDate: expectedDate), expectedTime)
        wait(for: [timeForDateExp], timeout: 0.1)
    }

    func test_didUpdateLoadedTimeRanges_shouldUpdateConverterWithNewRange() {
        let newRangesExp = expectation(description: "wait for new ranges")
        let expectedRange = NSValue(
            timeRange: CMTimeRange(
                start: .zero,
                end: CMTime(value: 100, timescale: 1)
            )
        )
        mockDateTimeConverter.updateListener = { range in
            XCTAssertEqual(range, expectedRange.timeRangeValue)
            newRangesExp.fulfill()
        }
        sut.playerItem(mockPrimaryPlayerItem, didUpdateLoadedTimeRanges: [expectedRange])
        wait(for: [newRangesExp], timeout: 0.1)
    }

    func test_didUpdateEffectiveRate_whenDidNotStartPlayingAndRateIsPositive_shouldAddTimeMapping() {
        let addMappingExp = expectation(description: "wait for add mapping")
        let expectedTime = CMTime(value: 100, timescale: 1)
        let expectedDate = Date(timeIntervalSince1970: 100)
        mockPrimaryPlayerItem.currentTimeReturnValue = expectedTime
        mockPrimaryPlayerItem.currentDateReturnValue = expectedDate
        mockDateTimeConverter.addListener = { conversion in
            XCTAssertEqual(conversion.time, expectedTime)
            XCTAssertEqual(conversion.date, expectedDate)
            addMappingExp.fulfill()
        }
        sut.playerItem(mockPrimaryPlayerItem, didUpdateEffectiveRate: 1)
        wait(for: [addMappingExp], timeout: 0.1)
    }

    func test_didUpdateEffectiveRate_whenDidNotStartPlayingAndRateIsZero_shouldNotAddTimeMapping() {
        let addMappingExp = expectation(description: "wait for add mapping")
        addMappingExp.isInverted = true
        mockPrimaryPlayerItem.currentTimeReturnValue = CMTime(value: 100, timescale: 1)
        mockPrimaryPlayerItem.currentDateReturnValue = Date(timeIntervalSince1970: 100)
        mockDateTimeConverter.addListener = { _ in addMappingExp.fulfill() }
        sut.playerItem(mockPrimaryPlayerItem, didUpdateEffectiveRate: 0)
        wait(for: [addMappingExp], timeout: 0.1)
    }

    func test_didUpdateEffectiveRate_whenDidStartPlaying_andRateIsZero_shouldAddTimeMapping() {
        let addMappingExp = expectation(description: "wait for add mapping")
        let expectedTime = CMTime(value: 100, timescale: 1)
        let expectedDate = Date(timeIntervalSince1970: 100)
        mockPrimaryPlayerItem.currentTimeReturnValue = expectedTime
        mockPrimaryPlayerItem.currentDateReturnValue = expectedDate
        sut.playerItem(mockPrimaryPlayerItem, didUpdateEffectiveRate: 1)
        mockDateTimeConverter.addListener = { conversion in
            XCTAssertEqual(conversion.time, expectedTime)
            XCTAssertEqual(conversion.date, expectedDate)
            addMappingExp.fulfill()
        }
        sut.playerItem(mockPrimaryPlayerItem, didUpdateEffectiveRate: 0)
        wait(for: [addMappingExp], timeout: 0.1)
    }

    func test_didUpdateEffectiveRate_whenDidStartPlaying_andRateIsNotZero_shouldNotAddTimeMapping() {
        let addMappingExp = expectation(description: "wait for add mapping")
        addMappingExp.isInverted = true
        mockPrimaryPlayerItem.currentTimeReturnValue = CMTime(value: 100, timescale: 1)
        mockPrimaryPlayerItem.currentDateReturnValue = Date(timeIntervalSince1970: 100)
        sut.playerItem(mockPrimaryPlayerItem, didUpdateEffectiveRate: 1)
        mockDateTimeConverter.addListener = { _ in addMappingExp.fulfill() }
        sut.playerItem(mockPrimaryPlayerItem, didUpdateEffectiveRate: 0.9)
        wait(for: [addMappingExp], timeout: 0.1)
    }

    func test_didUpdateEffectiveRate_whenDidStartPlaying_andRateIsZero_butPlaybacNotLikelyToKeepUp_shouldNotAddTimeMapping() {
        let addMappingExp = expectation(description: "wait for add mapping")
        addMappingExp.isInverted = true
        mockPrimaryPlayerItem.currentTimeReturnValue = CMTime(value: 100, timescale: 1)
        mockPrimaryPlayerItem.currentDateReturnValue = Date(timeIntervalSince1970: 100)
        mockPrimaryPlayerItem.fakeIsPlaybackLikelyToKeepUp = false
        sut.playerItem(mockPrimaryPlayerItem, didUpdateEffectiveRate: 1)
        mockDateTimeConverter.addListener = { _ in addMappingExp.fulfill() }
        sut.playerItem(mockPrimaryPlayerItem, didUpdateEffectiveRate: 0)
        wait(for: [addMappingExp], timeout: 0.1)
    }

    func test_didChangeCurrentItem_whenNewItem_shouldStartObserving() {
        let startObservingExp = expectation(description: "wait for start observing")
        let expectedItem = MockAVPlayerItem(url: URL(string: "http://expected.com/master.m3u8")!)
        mockPlayerItemObserver.startObservingListener = { item in
            XCTAssert(item === expectedItem)
            startObservingExp.fulfill()
        }
        sut.player(mockPrimaryPlayer, didChangeCurrentItem: expectedItem)
        wait(for: [startObservingExp], timeout: 0.1)
    }

    func test_didChangeCurrentItem_whenNoItem_shouldStopObserving() {
        let stopObservingExp = expectation(description: "wait for stop observing")
        mockPlayerItemObserver.stopObservingListener = { stopObservingExp.fulfill() }
        sut.player(mockPrimaryPlayer, didChangeCurrentItem: nil)
        wait(for: [stopObservingExp], timeout: 0.1)
    }
}
