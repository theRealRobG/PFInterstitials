//
//  MockRenderingTarget.swift
//  
//
//  Created by Robert Galluccio on 15/09/2021.
//

import AVFoundation
import PFInterstitials

class MockRenderingTarget: RenderingTarget {
    var updatePlayerReferenceListener: ((AVPlayer) -> Void)?

    func updatePlayerReference(player: AVPlayer) {
        updatePlayerReferenceListener?(player)
    }
}
