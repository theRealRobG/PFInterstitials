//
//  PFInterstitialEventControllerTests.swift
//  
//
//  Created by Robert Galluccio on 15/09/2021.
//

import Foundation
import AVFoundation
import XCTest
@testable import PFInterstitials

class PFInterstitialEventControllerTests: XCTestCase {
    var sut: PFInterstitialEventController!
    var mockPrimaryPlayerItem: MockAVPlayerItem!
    var mockPrimaryPlayer: MockAVQueuePlayer!
    var mockRenderingTarget: MockRenderingTarget!
    var mockInterstitialPlayer: MockAVQueuePlayer!
    var mockPrimaryPlayerObserver: MockPlayerObserver!
    var mockPrimaryPlayerItemObserver: MockPlayerItemObserver!
    var mockInterstitialPlayerObserver: MockPlayerObserver!

    override func setUp() {
        mockPrimaryPlayerItem = MockAVPlayerItem(url: URL(string: "http://test.com/master.m3u8")!)
        mockPrimaryPlayer = MockAVQueuePlayer()
        mockPrimaryPlayer.fakeCurrentItem = mockPrimaryPlayerItem
        mockRenderingTarget = MockRenderingTarget()
        mockInterstitialPlayer = MockAVQueuePlayer()
        mockPrimaryPlayerObserver = MockPlayerObserver()
        mockPrimaryPlayerItemObserver = MockPlayerItemObserver()
        mockInterstitialPlayerObserver = MockPlayerObserver()
        initialiseSUT()
    }

    func initialiseSUT() {
        sut = PFInterstitialEventController(
            primaryPlayer: mockPrimaryPlayer,
            renderingTarget: mockRenderingTarget,
            interstitialPlayer: mockInterstitialPlayer,
            primaryPlayerObserver: mockPrimaryPlayerObserver,
            primaryPlayerItemObserver: mockPrimaryPlayerItemObserver,
            interstitialPlayerObserver: mockInterstitialPlayerObserver
        )
    }

    func test_init_shouldSetObserverDelegates() {
        XCTAssert(mockPrimaryPlayerObserver.delegate === sut)
        XCTAssert(mockPrimaryPlayerItemObserver.delegate === sut)
        XCTAssert(mockInterstitialPlayerObserver.delegate === sut)
    }

    func test_init_shouldStartObservingCurrentPlayerItem() {
        let startObservingExp = expectation(description: "wait for start observing")
        mockPrimaryPlayerItemObserver.startObservingListener = { playerItem in
            XCTAssert(playerItem === self.mockPrimaryPlayerItem)
            startObservingExp.fulfill()
        }
        initialiseSUT()
        wait(for: [startObservingExp], timeout: 0.1)
    }

    func test_init_shouldUpdatePlayerReferenceToPrimaryOnRenderingTarget() {
        let updatePlayerExp = expectation(description: "wait for update player reference")
        mockRenderingTarget.updatePlayerReferenceListener = { player in
            XCTAssert(player === self.mockPrimaryPlayer)
            updatePlayerExp.fulfill()
        }
        initialiseSUT()
        wait(for: [updatePlayerExp], timeout: 0.1)
    }

    func test_events_get_shouldBeInitiallyEmpty() {
        XCTAssertTrue(sut.events.isEmpty)
    }

    func test_events_set_shouldUpdateEvents() {
        let event = PFInterstitialEvent(
            primaryItem: nil,
            identifier: nil,
            time: .zero,
            templateItems: []
        )
        sut.events.append(event)
        XCTAssertEqual(sut.events.first?.identifier, event.identifier)
        XCTAssertEqual(sut.events.first?.time, event.time)
    }

    func test_events_set_shouldOverrideSetEventsWithSameIdentifier() {
        let identifier = "test-id"
        let expectedTime = CMTime(value: 100, timescale: 1)
        let firstEvent = PFInterstitialEvent(
            primaryItem: nil,
            identifier: identifier,
            time: .zero,
            templateItems: []
        )
        let replacementEvent = PFInterstitialEvent(
            primaryItem: nil,
            identifier: identifier,
            time: expectedTime,
            templateItems: []
        )
        sut.events.append(firstEvent)
        sut.events.append(replacementEvent)
        XCTAssertEqual(sut.events.count, 1)
        XCTAssertEqual(sut.events.first?.identifier, identifier)
        XCTAssertEqual(sut.events.first?.time, expectedTime)
        sut.events.append(firstEvent)
        XCTAssertEqual(sut.events.count, 1)
        XCTAssertEqual(sut.events.first?.identifier, identifier)
        XCTAssertEqual(sut.events.first?.time, .zero)
    }

    func test_events_set_shouldNotifyNotificationCenter() {
        let eventsUpdatedExp = expectation(description: "wait for events updated")
        let expectedIdentifier = "test-event-id"
        let expectedDate = Date(timeIntervalSince1970: 100)
        let expectedEvent = PFInterstitialEvent(
            primaryItem: nil,
            identifier: expectedIdentifier,
            date: expectedDate,
            templateItems: []
        )
        let observer = NotificationCenter.default.addObserver(
            forName: PFInterstitialEventController.eventsDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let eventController = notification.object as? PFInterstitialEventController else {
                return XCTFail("Expected Notification object to be PFInterstitialEventController")
            }
            XCTAssert(eventController === self?.sut)
            XCTAssertEqual(eventController.events.count, 1)
            XCTAssertEqual(eventController.events.first?.identifier, expectedIdentifier)
            XCTAssertEqual(eventController.events.first?.date, expectedDate)
            eventsUpdatedExp.fulfill()
        }
        sut.events.append(expectedEvent)
        wait(for: [eventsUpdatedExp], timeout: 0.1)
        NotificationCenter.default.removeObserver(observer)
    }

    func test_events_set_shouldUpdateBoundaryTimeObservers() {
        let addFirstObserverExp = expectation(description: "wait for add first observer")
        let removeFirstObserverExp = expectation(description: "wait for remove first observer")
        let addNextObserverExp = expectation(description: "wait for add next observer")
        let events = [1, 2, 3].map {
            PFInterstitialEvent(
                primaryItem: mockPrimaryPlayerItem,
                identifier: "test-id-\($0)",
                time: CMTime(value: 100 * $0, timescale: 1),
                templateItems: []
            )
        }
        var addCount = 0
        mockPrimaryPlayer.addBoundaryTimeObserverListener = { times, queue, _ in
            addCount += 1
            switch addCount {
            case 1:
                guard times.count == 1 else { return XCTFail("Unexpected count: \(times.count)") }
                XCTAssertEqual(times[0].timeValue, CMTime(value: 100, timescale: 1))
                addFirstObserverExp.fulfill()
            case 2:
                guard times.count == 3 else { return XCTFail("Unexpected count: \(times.count)") }
                XCTAssertEqual(times[0].timeValue, CMTime(value: 100, timescale: 1))
                XCTAssertEqual(times[1].timeValue, CMTime(value: 200, timescale: 1))
                XCTAssertEqual(times[2].timeValue, CMTime(value: 300, timescale: 1))
                addNextObserverExp.fulfill()
            default:
                XCTFail("Unexpected add boundary time observer count: \(addCount)")
            }
        }
        let expectedObserver = NSObject()
        mockPrimaryPlayer.addBoundaryTimeObserverReturn = expectedObserver
        mockPrimaryPlayer.removeTimeObserverListener = { observer in
            XCTAssert(observer as? NSObject === expectedObserver)
            removeFirstObserverExp.fulfill()
        }
        sut.events = [events[0]]
        sut.events = events
        wait(
            for: [
                addFirstObserverExp,
                removeFirstObserverExp,
                addNextObserverExp
            ],
            timeout: 0.1,
            enforceOrder: true
        )
    }
}
