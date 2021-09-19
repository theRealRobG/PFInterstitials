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

    /// The event controller needs to be a delegate to the observers in order to receive events to act on.
    func test_init_shouldSetObserverDelegates() {
        XCTAssert(mockPrimaryPlayerObserver.delegate === sut)
        XCTAssert(mockPrimaryPlayerItemObserver.delegate === sut)
        XCTAssert(mockInterstitialPlayerObserver.delegate === sut)
    }

    /// We want to observe the primary player item immediately as it will give us information on how to construct the queue of
    /// interstitial items.
    func test_init_shouldStartObservingCurrentPlayerItem() {
        let startObservingExp = expectation(description: "wait for start observing")
        mockPrimaryPlayerItemObserver.startObservingListener = { playerItem in
            XCTAssert(playerItem === self.mockPrimaryPlayerItem)
            startObservingExp.fulfill()
        }
        initialiseSUT()
        wait(for: [startObservingExp], timeout: 0.1)
    }

    /// The assumption is that the primary player is the current player immediately.
    func test_init_shouldUpdatePlayerReferenceToPrimaryOnRenderingTarget() {
        let updatePlayerExp = expectation(description: "wait for update player reference")
        mockRenderingTarget.updatePlayerReferenceListener = { player in
            XCTAssert(player === self.mockPrimaryPlayer)
            updatePlayerExp.fulfill()
        }
        initialiseSUT()
        wait(for: [updatePlayerExp], timeout: 0.1)
    }

    /// There shouldn't exist events before the user has set any.
    func test_events_get_shouldBeInitiallyEmpty() {
        XCTAssertTrue(sut.events.isEmpty)
    }

    /// Once events are set by the user it should be reflected in the events array.
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

    /// There cannot be two events with the same identifier (assumptions are made based on this later on). The AVFoundation
    /// documentation for ``AVPlayerInterstitialEvent/identifier`` indicates: _Setting an event on the interstitial_
    /// _event controller replaces any existing event with the same identifier._
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

    /// When the `events` change the consumer needs to know about this.
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

    /// Since the array of scheduled events has changed, we need to update where the event boundaries sit on the primary player
    /// timeline, as this is what drives when the interstitial player is presented.
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
        mockPrimaryPlayer.addBoundaryTimeObserverReturnValue = expectedObserver
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

    /// If the user schedules an event within the loaded ranges then it should immediately be reflected in the interstitial player
    /// (otherwise, if there are no loaded range changes when we reach the event time, the queue will be incorrect as we move to the
    /// interstitial player).
    func test_events_set_whenEventWithinLoadedRangesAndAfterCurrentTime_shouldFillQueueWithEvent() {
        let queueInsertExp = expectation(description: "wait for insert into queue player")
        queueInsertExp.expectedFulfillmentCount = 3
        let expectedId = "test-ad-id"
        let expectedItems = [1, 2, 3].reduce(into: [MockAVPlayerItem]()) { items, count in
            items.append(MockAVPlayerItem(url: URL(string: "http://test.com/\(count).m3u8")!))
        }
        let expectedEvent = PFInterstitialEvent(
            primaryItem: mockPrimaryPlayerItem,
            identifier: expectedId,
            time: CMTime(value: 10, timescale: 1),
            templateItems: expectedItems
        )
        var count = 0
        mockInterstitialPlayer.insertListener = { item, afterItem in
            count += 1
            XCTAssertNil(afterItem)
            XCTAssertEqual(item.interstitialEventIdentifier, expectedId)
            XCTAssertEqual(item.url, URL(string: "http://test.com/\(count).m3u8")!)
            queueInsertExp.fulfill()
        }
        mockPrimaryPlayerItem.currentTimeReturnValue = .zero
        mockPrimaryPlayerItem.fakeLoadedTimeRanges = [
            NSValue(timeRange: CMTimeRange(start: .zero, end: CMTime(value: 20, timescale: 1)))
        ]

        sut.events = [expectedEvent]

        wait(for: [queueInsertExp], timeout: 0.1)
    }

    // MARK: - PlayerItemObserverDelegate

    /// If loaded ranges update to include a scheduled event then we should prepare the interstitial player with the items from this
    /// event.
    ///
    /// This is based on the following statement in the interstitials guide (1.0b3):
    /// > The player loads the resource specified by the URL after it buffers the primary asset to the scheduled interstitial playback
    /// > time.
    func test_didUpdateLoadedTimeRanges_whenLoadedTimeRangesIncludeEvent_shouldFillQueueWithItems() {
        let queueInsertExp = expectation(description: "wait for insert into queue player")
        queueInsertExp.expectedFulfillmentCount = 3
        let expectedId = "test-ad-id"
        let expectedItems = [1, 2, 3].reduce(into: [MockAVPlayerItem]()) { items, count in
            items.append(MockAVPlayerItem(url: URL(string: "http://test.com/\(count).m3u8")!))
        }
        let expectedEvent = PFInterstitialEvent(
            primaryItem: mockPrimaryPlayerItem,
            identifier: expectedId,
            time: CMTime(value: 10, timescale: 1),
            templateItems: expectedItems
        )
        var count = 0
        mockInterstitialPlayer.insertListener = { item, afterItem in
            count += 1
            XCTAssertNil(afterItem)
            XCTAssertEqual(item.interstitialEventIdentifier, expectedId)
            XCTAssertEqual(item.url, URL(string: "http://test.com/\(count).m3u8")!)
            queueInsertExp.fulfill()
        }
        mockPrimaryPlayerItem.currentTimeReturnValue = .zero

        sut.events = [expectedEvent]

        let ranges = [NSValue(timeRange: CMTimeRange(start: .zero, end: CMTime(value: 20, timescale: 1)))]
        mockPrimaryPlayerItem.fakeLoadedTimeRanges = ranges
        mockPrimaryPlayerItemObserver.delegate?.playerItem(
            mockPrimaryPlayerItem,
            didUpdateLoadedTimeRanges: ranges
        )
        wait(for: [queueInsertExp], timeout: 0.1)
    }

    /// The loaded ranges may include positions that are "in the past", and so we don't want to append items to the interstitial queue
    /// that are scheduled before our current playhead position.
    func test_didUpdateLoadedTimeRanges_whenLoadedTimeRangesIncludeEvent_butCurrentPositionIsAfterEvent_shouldNotFillQueueWithItems() {
        let queueInsertExp = expectation(description: "wait for insert into queue player")
        queueInsertExp.isInverted = true
        let expectedEvent = PFInterstitialEvent(
            primaryItem: mockPrimaryPlayerItem,
            identifier: "test-id",
            time: CMTime(value: 10, timescale: 1),
            templateItems: [MockAVPlayerItem(url: URL(string: "https://test.com/master.m3u8")!)]
        )
        mockInterstitialPlayer.insertListener = { _, _ in
            queueInsertExp.fulfill()
        }
        mockPrimaryPlayerItem.currentTimeReturnValue = CMTime(value: 15, timescale: 1)

        sut.events = [expectedEvent]

        let ranges = [NSValue(timeRange: CMTimeRange(start: .zero, end: CMTime(value: 20, timescale: 1)))]
        mockPrimaryPlayerItem.fakeLoadedTimeRanges = ranges
        mockPrimaryPlayerItemObserver.delegate?.playerItem(
            mockPrimaryPlayerItem,
            didUpdateLoadedTimeRanges: ranges
        )
        wait(for: [queueInsertExp], timeout: 0.1)
    }

    /// If we enter a range of time that does not have any interstitials expected within the buffered range, then the interstitial queue
    /// should be updated to reflect this.
    func test_didUpdateLoadedTimeRanges_whenNoEventInLoadedRanges_andQueueHasItems_shouldRemoveItemsFromQueue() {
        let queueInsertExp = expectation(description: "wait for insert into queue player")
        queueInsertExp.isInverted = true
        let expectedEvent = PFInterstitialEvent(
            primaryItem: mockPrimaryPlayerItem,
            identifier: "test-id",
            time: CMTime(value: 10, timescale: 1),
            templateItems: [MockAVPlayerItem(url: URL(string: "https://test.com/master.m3u8")!)]
        )
        mockInterstitialPlayer.insertListener = { _, _ in
            queueInsertExp.fulfill()
        }
        mockPrimaryPlayerItem.currentTimeReturnValue = .zero

        sut.events = [expectedEvent]

        let ranges = [NSValue(timeRange: CMTimeRange(start: .zero, end: CMTime(value: 5, timescale: 1)))]
        mockPrimaryPlayerItem.fakeLoadedTimeRanges = ranges
        mockPrimaryPlayerItemObserver.delegate?.playerItem(
            mockPrimaryPlayerItem,
            didUpdateLoadedTimeRanges: ranges
        )
        wait(for: [queueInsertExp], timeout: 0.1)
    }

    /// In the unexpected event that the interstitial queue is mismatching what we expect the queue to be (based on scheduled
    /// events and loaded time ranges), then we need to flush the interstitial queue before filling it with what is expected.
    func test_didUpdateLoadedTimeRanges_whenEventInLoadedRangesDoesNotMatchQueueItems_shouldRemoveItemsThenAddExpectedItems() {
        let removeItemsExp = expectation(description: "wait for remove from queue player")
        let queueInsertExp = expectation(description: "wait for insert into queue player")
        queueInsertExp.expectedFulfillmentCount = 3
        let expectedId = "test-ad-id"
        let expectedItems = [1, 2, 3].reduce(into: [MockAVPlayerItem]()) { items, count in
            items.append(MockAVPlayerItem(url: URL(string: "http://test.com/\(count).m3u8")!))
        }
        let expectedEvent = PFInterstitialEvent(
            primaryItem: mockPrimaryPlayerItem,
            identifier: expectedId,
            time: CMTime(value: 10, timescale: 1),
            templateItems: expectedItems
        )
        mockInterstitialPlayer.removeAllItemsListener = {
            removeItemsExp.fulfill()
        }
        var count = 0
        mockInterstitialPlayer.insertListener = { item, afterItem in
            count += 1
            XCTAssertNil(afterItem)
            XCTAssertEqual(item.interstitialEventIdentifier, expectedId)
            XCTAssertEqual(item.url, URL(string: "http://test.com/\(count).m3u8")!)
            queueInsertExp.fulfill()
        }
        mockPrimaryPlayerItem.currentTimeReturnValue = .zero

        sut.events = [expectedEvent]

        mockInterstitialPlayer.itemsReturnValue = [MockAVPlayerItem(url: URL(string: "http://random.com/where-did-you-come-from.m3u8?answer=unknown")!)]
        let ranges = [NSValue(timeRange: CMTimeRange(start: .zero, end: CMTime(value: 20, timescale: 1)))]
        mockPrimaryPlayerItem.fakeLoadedTimeRanges = ranges
        mockPrimaryPlayerItemObserver.delegate?.playerItem(
            mockPrimaryPlayerItem,
            didUpdateLoadedTimeRanges: ranges
        )
        wait(for: [removeItemsExp, queueInsertExp], timeout: 0.1, enforceOrder: true)
    }

    /// Similar to above, where we must maintain the queue against loaded ranges and scheduled events, if we have a range update
    /// and the queue has items despite the expectation being that there are no items, then we should remove all items and no
    /// further items should be added.
    func test_didUpdateLoadedTimeRanges_whenQueueItemsExistButNoEventExistsInLoadedRanges_shouldRemoveItems() {
        let removeItemsExp = expectation(description: "wait for remove from queue player")
        let queueInsertExp = expectation(description: "wait for insert into queue player")
        queueInsertExp.isInverted = true
        mockInterstitialPlayer.removeAllItemsListener = {
            removeItemsExp.fulfill()
        }
        mockInterstitialPlayer.insertListener = { _, _ in
            queueInsertExp.fulfill()
        }
        mockPrimaryPlayerItem.currentTimeReturnValue = .zero

        mockInterstitialPlayer.itemsReturnValue = [MockAVPlayerItem(url: URL(string: "http://random.com/where-did-you-come-from.m3u8?answer=unknown")!)]
        let ranges = [NSValue(timeRange: CMTimeRange(start: .zero, end: CMTime(value: 20, timescale: 1)))]
        mockPrimaryPlayerItem.fakeLoadedTimeRanges = ranges
        mockPrimaryPlayerItemObserver.delegate?.playerItem(
            mockPrimaryPlayerItem,
            didUpdateLoadedTimeRanges: ranges
        )
        wait(for: [removeItemsExp, queueInsertExp], timeout: 0.1)
    }

    /// If we add multiple events to the queue then we will be loading unnecessary interstitials as we finish the first event.
    func test_didUpdateLoadedTimeRanges_whenMultipleEventsInLoadedRanges_shouldOnlyAddFirstEvent() {
        let queueInsertExp = expectation(description: "wait for insert into queue player")
        queueInsertExp.expectedFulfillmentCount = 3
        let expectedId = "test-ad-id"
        let expectedItems = [1, 2, 3].reduce(into: [MockAVPlayerItem]()) { items, count in
            items.append(MockAVPlayerItem(url: URL(string: "http://test.com/\(count).m3u8")!))
        }
        let expectedEvent = PFInterstitialEvent(
            primaryItem: mockPrimaryPlayerItem,
            identifier: expectedId,
            time: CMTime(value: 10, timescale: 1),
            templateItems: expectedItems
        )
        let nextId = "next-test-ad-id"
        let nextItems = [4, 5, 6].reduce(into: [MockAVPlayerItem]()) { items, count in
            items.append(MockAVPlayerItem(url: URL(string: "http://test.com/\(count).m3u8")!))
        }
        let nextEvent = PFInterstitialEvent(
            primaryItem: mockPrimaryPlayerItem,
            identifier: nextId,
            time: CMTime(value: 20, timescale: 1),
            templateItems: nextItems
        )
        var count = 0
        mockInterstitialPlayer.insertListener = { item, afterItem in
            count += 1
            XCTAssertNil(afterItem)
            XCTAssertEqual(item.interstitialEventIdentifier, expectedId)
            XCTAssertEqual(item.url, URL(string: "http://test.com/\(count).m3u8")!)
            queueInsertExp.fulfill()
        }
        mockPrimaryPlayerItem.currentTimeReturnValue = .zero

        sut.events = [expectedEvent, nextEvent]

        let ranges = [NSValue(timeRange: CMTimeRange(start: .zero, end: CMTime(value: 30, timescale: 1)))]
        mockPrimaryPlayerItem.fakeLoadedTimeRanges = ranges
        mockPrimaryPlayerItemObserver.delegate?.playerItem(
            mockPrimaryPlayerItem,
            didUpdateLoadedTimeRanges: ranges
        )
        wait(for: [queueInsertExp], timeout: 0.1)
    }

    /// If there are multiple events scheduled for a single time then they should be concatenated on top of each other.
    ///
    /// This is based on the following statement in the interstitials guide (1.0b3):
    /// > Two or more interstitials scheduled at the same START-DATE should be played in the order that their EXT-X-DATERANGE
    /// > tags appear in the playlist.
    func test_didUpdateLoadedTimeRanges_whenMultipleEventsExistForOneTimeInLoadedRanges_shouldAddAllEvents() {
        let queueInsertExp = expectation(description: "wait for insert into queue player")
        queueInsertExp.expectedFulfillmentCount = 6
        let expectedId = "test-ad-id"
        let expectedItems = [1, 2, 3].reduce(into: [MockAVPlayerItem]()) { items, count in
            items.append(MockAVPlayerItem(url: URL(string: "http://test.com/\(count).m3u8")!))
        }
        let expectedEvent = PFInterstitialEvent(
            primaryItem: mockPrimaryPlayerItem,
            identifier: expectedId,
            time: CMTime(value: 10, timescale: 1),
            templateItems: expectedItems
        )
        let nextId = "next-test-ad-id"
        let nextItems = [4, 5, 6].reduce(into: [MockAVPlayerItem]()) { items, count in
            items.append(MockAVPlayerItem(url: URL(string: "http://test.com/\(count).m3u8")!))
        }
        let nextEvent = PFInterstitialEvent(
            primaryItem: mockPrimaryPlayerItem,
            identifier: nextId,
            time: CMTime(value: 10, timescale: 1),
            templateItems: nextItems
        )
        var count = 0
        mockInterstitialPlayer.insertListener = { item, afterItem in
            count += 1
            XCTAssertNil(afterItem)
            if [1, 2, 3].contains(count) {
                XCTAssertEqual(item.interstitialEventIdentifier, expectedId)
            } else if [4, 5, 6].contains(count) {
                XCTAssertEqual(item.interstitialEventIdentifier, nextId)
            } else {
                XCTFail("Unexpected item being added to queue")
            }
            XCTAssertEqual(item.url, URL(string: "http://test.com/\(count).m3u8")!)
            queueInsertExp.fulfill()
        }
        mockPrimaryPlayerItem.currentTimeReturnValue = .zero

        sut.events = [expectedEvent, nextEvent]

        let ranges = [NSValue(timeRange: CMTimeRange(start: .zero, end: CMTime(value: 20, timescale: 1)))]
        mockPrimaryPlayerItem.fakeLoadedTimeRanges = ranges
        mockPrimaryPlayerItemObserver.delegate?.playerItem(
            mockPrimaryPlayerItem,
            didUpdateLoadedTimeRanges: ranges
        )
        wait(for: [queueInsertExp], timeout: 0.1)
    }
}
