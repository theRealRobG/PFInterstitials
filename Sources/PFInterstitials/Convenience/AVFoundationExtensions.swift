//
//  AVFoundationExtensions.swift
//  
//
//  Created by Robert Galluccio on 15/09/2021.
//

import Foundation
import AVFoundation

extension CMTime: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(value)
        hasher.combine(timescale)
    }
}

// Idea for how to associate random data with an NSObject was taken from the following
// SO answer: https://stackoverflow.com/a/25428409

private var AssociatedObjectHandle = 0

extension AVPlayerItem {
    var url: URL? { (asset as? AVURLAsset)?.url }

    var interstitialEventIdentifier: String? {
        get { objc_getAssociatedObject(self, &AssociatedObjectHandle) as? String }
        set { objc_setAssociatedObject(self, &AssociatedObjectHandle, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }

    func copyPreservingEventIdentifier() -> Any {
        let id = interstitialEventIdentifier
        let newCopy = copy()
        guard let newItem = newCopy as? AVPlayerItem else { return newCopy }
        newItem.interstitialEventIdentifier = id
        return newItem
    }
}

