//
//  MockDateTimeConverstion.swift
//  
//
//  Created by Robert Galluccio on 27/09/2021.
//

import Foundation
import AVFoundation
@testable import PFInterstitials

class MockDateTimeConversion: DateTimeConversion {
    var dateForTimeListener: ((CMTime) -> Void)?
    var timeForDateListener: ((Date) -> Void)?

    var dateForTimeReturnValue: Date?
    var timeForDateReturnValue: CMTime?

    var fakeDate: Date?
    var fakeTime: CMTime?
    var date: Date { fakeDate ?? underlyingMap.date }
    var time: CMTime { fakeTime ?? underlyingMap.time }

    let underlyingMap: DateTimeMapping

    init(date: Date = Date(timeIntervalSince1970: 0), time: CMTime = .zero) {
        underlyingMap = DateTimeMapping(date: date, time: time)
    }

    func date(forTime time: CMTime) -> Date {
        dateForTimeListener?(time)
        return dateForTimeReturnValue ?? underlyingMap.date(forTime: time)
    }

    func time(forDate date: Date) -> CMTime {
        timeForDateListener?(date)
        return timeForDateReturnValue ?? underlyingMap.time(forDate: date)
    }
}
