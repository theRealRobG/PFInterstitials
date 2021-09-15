//
//  MockPlayerItemObserverDelegate.swift
//  
//
//  Created by Robert Galluccio on 15/09/2021.
//

import Foundation
import AVFoundation
@testable import PFInterstitials

class MockPlayerItemObserverDelegate: PlayerItemObserverDelegate {
    var didUpdateLoadedTimeRangesListener: ((AVPlayerItem, [NSValue]) -> Void)?

    func playerItem(
        _ playerItem: AVPlayerItem,
        didUpdateLoadedTimeRanges loadedTimeRanges: [NSValue]
    ) {
        didUpdateLoadedTimeRangesListener?(playerItem, loadedTimeRanges)
    }
}
