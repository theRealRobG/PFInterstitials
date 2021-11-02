//
//  MockNotificationCenter.swift
//  
//
//  Created by Robert Galluccio on 01/11/2021.
//

import Foundation

class MockNotificationCenter: NotificationCenter {
    var addObserverListener: ((Any, Selector, NSNotification.Name?, Any?) -> Void)?
    var removeObserverListener: ((Any, NSNotification.Name?, Any?) -> Void)?

    override func addObserver(
        _ observer: Any,
        selector aSelector: Selector,
        name aName: NSNotification.Name?,
        object anObject: Any?
    ) {
        addObserverListener?(observer, aSelector, aName, anObject)
    }

    override func removeObserver(
        _ observer: Any,
        name aName: NSNotification.Name?,
        object anObject: Any?
    ) {
        removeObserverListener?(observer, aName, anObject)
    }
}
