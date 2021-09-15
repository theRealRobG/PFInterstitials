//
//  MockPlayerObserverDelegate.swift
//  
//
//  Created by Robert Galluccio on 15/09/2021.
//

import Foundation
import AVFoundation
@testable import PFInterstitials

class MockPlayerObserverDelegate: PlayerObserverDelegate {
    var didChangeCurrentItemListener: ((AVPlayer, AVPlayerItem?) -> Void)?

    func player(_ player: AVPlayer, didChangeCurrentItem currentItem: AVPlayerItem?) {
        didChangeCurrentItemListener?(player, currentItem)
    }
}
