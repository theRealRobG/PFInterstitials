//
//  MockPlayerObserver.swift
//  
//
//  Created by Robert Galluccio on 16/09/2021.
//

import Foundation
@testable import PFInterstitials

class MockPlayerObserver: PlayerObserver {
    var observeValueListener: ((String?, Any?, [NSKeyValueChangeKey: Any]?, UnsafeMutableRawPointer?) -> Void)?

    init() {
        super.init(player: MockAVQueuePlayer())
    }

    override func observeValue(
        forKeyPath keyPath: String?,
        of object: Any?,
        change: [NSKeyValueChangeKey : Any]?,
        context: UnsafeMutableRawPointer?
    ) {
        observeValueListener?(keyPath, object, change, context)
    }
}
