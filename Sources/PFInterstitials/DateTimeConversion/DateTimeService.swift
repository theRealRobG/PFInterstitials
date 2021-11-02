//
//  DateTimeService.swift
//  
//
//  Created by Robert Galluccio on 01/11/2021.
//

import Foundation
import AVFoundation

class DateTimeService: PlayerObserverDelegate, PlayerItemObserverDelegate {
    private let playerObserver: PlayerObserver
    private let playerItemObserver: PlayerItemObserver
    private let dateTimeConverter: DateTimeConverter
    private weak var currentPrimaryPlayerItem: AVPlayerItem?

    /// Wait for first play event to record date/time mapping (as date is unreliable during playback load).
    private var didStartPlaying = false

    convenience init(primaryPlayer: AVPlayer) {
        let playerObserver = PlayerObserver(player: primaryPlayer)
        let playerItemObserver = PlayerItemObserver()
        primaryPlayer.currentItem.map { playerItemObserver.startObserving(playerItem: $0) }
        self.init(
            currentPrimaryPlayerItem: primaryPlayer.currentItem,
            playerObserver: playerObserver,
            playerItemObserver: playerItemObserver
        )
    }

    init(
        currentPrimaryPlayerItem: AVPlayerItem?,
        playerObserver: PlayerObserver,
        playerItemObserver: PlayerItemObserver,
        dateTimeConverter: DateTimeConverter = DateTimeConverter()
    ) {
        self.currentPrimaryPlayerItem = currentPrimaryPlayerItem
        self.playerObserver = playerObserver
        self.playerItemObserver = playerItemObserver
        self.dateTimeConverter = dateTimeConverter
        playerObserver.delegate = self
        playerItemObserver.delegate = self
    }

    func date(forTime time: CMTime) -> Date? {
        dateTimeConverter.date(forTime: time)
    }

    func time(forDate date: Date) -> CMTime? {
        dateTimeConverter.time(forDate: date)
    }

    // MARK: - PlayerObserverDelegate

    func player(_ player: AVPlayer, didChangeCurrentItem currentItem: AVPlayerItem?) {
        currentPrimaryPlayerItem = currentItem
        if let item = currentItem {
            playerItemObserver.startObserving(playerItem: item)
        } else {
            playerItemObserver.stopObserving()
        }
    }

    // MARK: - PlayerItemObserverDelegate

    func playerItem(_ playerItem: AVPlayerItem, didUpdateLoadedTimeRanges loadedTimeRanges: [NSValue]) {
        let newRange = loadedTimeRanges.map { $0.timeRangeValue }.last ?? .zero
        dateTimeConverter.update(playbackTimeRange: newRange)
    }

    func playerItem(_ playerItem: AVPlayerItem, didUpdateEffectiveRate effectiveRate: Double) {
        guard didStartPlaying else {
            guard effectiveRate > 0 else { return }
            didStartPlaying = true
            addDateTimeMappingIfPossible()
            return
        }
        guard effectiveRate == 0 else { return }
        addDateTimeMappingIfPossible()
    }

    // MARK: - Private helpers

    private func addDateTimeMappingIfPossible() {
        guard let playerItem = currentPrimaryPlayerItem, let currentDate = playerItem.currentDate() else { return }
        dateTimeConverter.add(mapping: DateTimeMapping(date: currentDate, time: playerItem.currentTime()))
    }
}
