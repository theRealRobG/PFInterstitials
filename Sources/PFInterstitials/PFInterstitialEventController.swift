//
//  PFInterstitialEventController.swift
//  
//
//  Created by Robert Galluccio on 15/09/2021.
//

import Foundation
import AVFoundation

/**
 TODO
 - [x] Event notification
 - [ ] Scheduling events by `Date`
 - [ ] Resumption offset (currently always `.zero`)
 - [ ] Playout limit (currently always `.indefinite`)
 - [ ] Automatic handling of `EXT-X-DATERANGE` in manifest
 - [ ] Seek rules _(stretch goal given `AVPlayerInterstitialEventController` doesn’t handle this)_
 - [ ] Block access to queue modification (with class extension on `AVQueuePlayer`)
 */

public class PFInterstitialEventController {
    public static let eventsDidChangeNotification = Notification.Name(rawValue: "PFInterstitialEventMonitorEventsDidChangeNotification")
    public static let currentEventDidChangeNotification = Notification.Name(rawValue: "PFInterstitialEventMonitorCurrentEventDidChangeNotification")

    public let primaryPlayer: AVPlayer
    public let interstitialPlayer: AVQueuePlayer
    public var events: [PFInterstitialEvent] {
        get {
            scheduledInterstitialEvents.keys
                .sorted()
                .compactMap { scheduledInterstitialEvents[$0] }
                .flatMap { $0 }
        }
        set {
            let dedupedEvents = newValue.reduce(into: [PFInterstitialEvent]()) { events, event in
                events.removeAll(where: { $0.identifier == event.identifier })
                events.append(event)
            }
            scheduledInterstitialEvents = dedupedEvents.reduce(into: [:]) { scheduledEvents, event in
                if scheduledEvents[event.time] != nil {
                    scheduledEvents[event.time]?.append(event)
                } else {
                    scheduledEvents[event.time] = [event]
                }
            }
            NotificationCenter.default.post(name: Self.eventsDidChangeNotification, object: self)
        }
    }
    public private(set) var currentEvent: PFInterstitialEvent? {
        didSet {
            if oldValue?.identifier != currentEvent?.identifier {
                NotificationCenter.default.post(name: Self.currentEventDidChangeNotification, object: self)
            }
        }
    }

    private let renderingTarget: RenderingTarget
    private var currentPlayer: AVPlayer
    private let primaryPlayerObserver: PlayerObserver
    private let primaryPlayerItemObserver: PlayerItemObserver
    private let interstitialPlayerObserver: PlayerObserver
    private let dateTimeService: DateTimeService
    private var interstitialTransitionObserver: Any?
    private var scheduledInterstitialEvents = [CMTime: [PFInterstitialEvent]]() {
        didSet { updateInterstitialTransitionTimes() }
    }
    private var interstitialTransitionTimes: [CMTime] { scheduledInterstitialEvents.keys.sorted().map { $0 } }

    public convenience init(
        primaryPlayer: AVPlayer,
        renderingTarget: RenderingTarget
    ) {
        let interstitialPlayer = AVQueuePlayer()
        let primaryPlayerObserver = PlayerObserver(player: primaryPlayer)
        let primaryPlayerItemObserver = PlayerItemObserver()
        let interstitialPlayerObserver = PlayerObserver(player: interstitialPlayer)
        let dateTimeService = DateTimeService(primaryPlayer: primaryPlayer)
        self.init(
            primaryPlayer: primaryPlayer,
            renderingTarget: renderingTarget,
            interstitialPlayer: interstitialPlayer,
            primaryPlayerObserver: primaryPlayerObserver,
            primaryPlayerItemObserver: primaryPlayerItemObserver,
            interstitialPlayerObserver: interstitialPlayerObserver,
            dateTimeService: dateTimeService
        )
    }

    init(
        primaryPlayer: AVPlayer,
        renderingTarget: RenderingTarget,
        interstitialPlayer: AVQueuePlayer,
        primaryPlayerObserver: PlayerObserver,
        primaryPlayerItemObserver: PlayerItemObserver,
        interstitialPlayerObserver: PlayerObserver,
        dateTimeService: DateTimeService
    ) {
        self.primaryPlayer = primaryPlayer
        self.renderingTarget = renderingTarget
        self.interstitialPlayer = interstitialPlayer
        self.currentPlayer = primaryPlayer
        self.primaryPlayerObserver = primaryPlayerObserver
        self.primaryPlayerItemObserver = primaryPlayerItemObserver
        self.interstitialPlayerObserver = interstitialPlayerObserver
        self.dateTimeService = dateTimeService
        primaryPlayerObserver.delegate = self
        primaryPlayerItemObserver.delegate = self
        interstitialPlayerObserver.delegate = self
        handlePrimaryPlayerCurrentItemChange(currentItem: primaryPlayer.currentItem)
        ensureMainThreadSync { renderingTarget.updatePlayerReference(player: primaryPlayer) }
    }
}

// MARK: - PlayerObserverDelegate

extension PFInterstitialEventController: PlayerObserverDelegate {
    func player(_ player: AVPlayer, didChangeCurrentItem currentItem: AVPlayerItem?) {
        if player === interstitialPlayer {
            handleInterstitialPlayerCurrentItemChange(currentItem: currentItem)
        } else if player === primaryPlayer {
            handlePrimaryPlayerCurrentItemChange(currentItem: currentItem)
        }
    }

    private func handleInterstitialPlayerCurrentItemChange(currentItem: AVPlayerItem?) {
        guard currentPlayer === interstitialPlayer else { return }
        if let item = currentItem {
            guard
                let id = item.interstitialEventIdentifier,
                let event = scheduledInterstitialEvents.values.flatMap({ $0 }).first(where: { $0.identifier == id })
            else {
                switchToPlayerType(.primary) {
                    interstitialPlayer.removeAllItems()
                    currentEvent = nil
                    primaryPlayer.play()
                }
                return
            }
            currentEvent = event
        } else {
            switchToPlayerType(.primary) {
                currentEvent = nil
                primaryPlayer.play()
            }
        }
    }

    private func handlePrimaryPlayerCurrentItemChange(currentItem: AVPlayerItem?) {
        if let playerItem = currentItem {
            primaryPlayerItemObserver.startObserving(playerItem: playerItem)
        } else {
            primaryPlayerItemObserver.stopObserving()
        }
    }
}

// MARK: - PlayerItemObserverDelegate

extension PFInterstitialEventController: PlayerItemObserverDelegate {
    func playerItem(_ playerItem: AVPlayerItem, didUpdateLoadedTimeRanges loadedTimeRanges: [NSValue]) {
        guard currentPlayer === primaryPlayer, primaryPlayer.currentItem === playerItem else { return }
        let ranges = loadedTimeRanges.map { $0.timeRangeValue }
        let currentTime = playerItem.currentTime()
        let scheduledTimeInRanges = interstitialTransitionTimes.first { time in
            time > currentTime && ranges.contains(where: { $0.containsTime(time) })
        }
        let scheduledBreaks = scheduledTimeInRanges.map { scheduledInterstitialEvents[$0] ?? [] } ?? []
        let playerItems = scheduledBreaks
            .flatMap { $0.templateItems }
            .compactMap { $0.copyPreservingEventIdentifier() as? AVPlayerItem }
        let queuedItems = interstitialPlayer.items()
        let isQueueSetUpCorrectly = playerItems.count == queuedItems.count && queuedItems.enumerated().allSatisfy { index, item in
            guard playerItems.indices.contains(index) else { return false }
            let sameURL = item.url?.absoluteURL == playerItems[index].url?.absoluteURL
            let sameID = item.interstitialEventIdentifier == playerItems[index].interstitialEventIdentifier
            return sameURL && sameID
        }
        guard isQueueSetUpCorrectly else {
            interstitialPlayer.removeAllItems()
            playerItems.forEach { interstitialPlayer.insert($0, after: nil) }
            return
        }
    }

    func playerItem(_ playerItem: AVPlayerItem, didUpdateEffectiveRate effectiveRate: Double) {}
}

// MARK: - Scheduling Interstitials

private extension PFInterstitialEventController {
    func updateInterstitialTransitionTimes() {
        if let previousObserver = interstitialTransitionObserver {
            primaryPlayer.removeTimeObserver(previousObserver)
        }
        interstitialTransitionObserver = primaryPlayer.addBoundaryTimeObserver(
            forTimes: interstitialTransitionTimes.map { NSValue(time: $0) },
            queue: .main
        ) { [weak self] in
            guard
                let self = self,
                self.currentPlayer === self.primaryPlayer,
                self.interstitialPlayer.currentItem != nil
            else {
                return
            }
            self.switchToPlayerType(.interstitial) {
                self.player(self.interstitialPlayer, didChangeCurrentItem: self.interstitialPlayer.currentItem)
                self.interstitialPlayer.play()
            }
        }
        // Here we make sure that whenever interstitial events are updated we guarantee the ad queue
        // player is up to date.
        if let primaryPlayerItem = primaryPlayer.currentItem {
            playerItem(primaryPlayerItem, didUpdateLoadedTimeRanges: primaryPlayerItem.loadedTimeRanges)
        }
    }
}

// MARK: - Switching Player

private extension PFInterstitialEventController {
    enum PlayerType {
        case primary
        case interstitial

        var opposite: PlayerType {
            switch self {
            case .primary: return .interstitial
            case .interstitial: return .primary
            }
        }
    }

    func switchToPlayerType(_ playerType: PlayerType, completion: () -> Void) {
        let toPlayer = player(forType: playerType)
        let fromPlayer = player(forType: playerType.opposite)
        guard currentPlayer !== toPlayer else { return }
        ensureMainThreadSync {
            fromPlayer.pause()
            renderingTarget.updatePlayerReference(player: toPlayer)
            currentPlayer = toPlayer
            completion()
        }
    }

    func player(forType type: PlayerType) -> AVPlayer {
        switch type {
        case .primary: return primaryPlayer
        case .interstitial: return interstitialPlayer
        }
    }
}

