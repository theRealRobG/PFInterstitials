//
//  PFInterstitialEvent.swift
//  
//
//  Created by Robert Galluccio on 15/09/2021.
//

import Foundation
import AVFoundation

public struct PFInterstitialEvent {
    public private(set) weak var primaryItem: AVPlayerItem?
    public let identifier: String
    public let time: CMTime
    public let date: Date?
    public let templateItems: [AVPlayerItem]
    public let restrictions: Restrictions
    public let resumptionOffset: CMTime
    public let playoutLimit: CMTime
    public let userDefinedAttributes: [String: Any]

    public init(
        primaryItem: AVPlayerItem?,
        identifier: String?,
        time: CMTime,
        templateItems: [AVPlayerItem],
        restrictions: Restrictions = [],
        resumptionOffset: CMTime = .zero,
        playoutLimit: CMTime = .invalid,
        userDefinedAttributes: [String: Any] = [:]
    ) {
        self.init(
            primaryItem: primaryItem,
            identifier: identifier,
            time: time,
            date: nil,
            templateItems: templateItems,
            restrictions: restrictions,
            resumptionOffset: resumptionOffset,
            playoutLimit: playoutLimit,
            userDefinedAttributes: userDefinedAttributes
        )
    }

    public init(
        primaryItem: AVPlayerItem?,
        identifier: String?,
        date: Date,
        templateItems: [AVPlayerItem],
        restrictions: Restrictions = [],
        resumptionOffset: CMTime = .zero,
        playoutLimit: CMTime = .invalid,
        userDefinedAttributes: [String: Any] = [:]
    ) {
        self.init(
            primaryItem: primaryItem,
            identifier: identifier,
            time: .invalid,
            date: date,
            templateItems: templateItems,
            restrictions: restrictions,
            resumptionOffset: resumptionOffset,
            playoutLimit: playoutLimit,
            userDefinedAttributes: userDefinedAttributes
        )
    }

    private init(
        primaryItem: AVPlayerItem?,
        identifier: String?,
        time: CMTime,
        date: Date?,
        templateItems: [AVPlayerItem],
        restrictions: Restrictions,
        resumptionOffset: CMTime,
        playoutLimit: CMTime,
        userDefinedAttributes: [String: Any]
    ) {
        self.primaryItem = primaryItem
        let eventIdentifier = identifier ?? UUID().uuidString
        self.identifier = eventIdentifier
        self.time = time
        self.date = date
        self.templateItems = templateItems.reduce(into: []) { items, item in
            item.interstitialEventIdentifier = eventIdentifier
            items.append(item)
        }
        self.restrictions = restrictions
        self.resumptionOffset = resumptionOffset
        self.playoutLimit = playoutLimit
        self.userDefinedAttributes = userDefinedAttributes
    }
}

public extension PFInterstitialEvent {
    /// These constants can be specified when creating PFInterstitialEvents in order to configure their behavior.
    struct Restrictions: OptionSet {
        /// Indicates that seeking within the primary content from a date prior to the date of the event to
        /// a date subsequent to the date of the event is not permitted.
        public static let constrainsSeekingForwardInPrimaryContent = Restrictions(rawValue: 1 << 0)
        /// Indicates that advancing the currentTime within an interstitial item, either by seeking ahead or
        /// by setting the playback rate to a value greater than the item's asset's preferredRate, is not
        /// permitted.
        public static let requiresPlaybackAtPreferredRateForAdvancement = Restrictions(rawValue: 1 << 1)

        public let rawValue: UInt

        public init(rawValue: UInt) {
            self.rawValue = rawValue
        }
    }
}

