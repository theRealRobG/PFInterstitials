//
//  DateTimeMapping.swift
//  
//
//  Created by Robert Galluccio on 27/09/2021.
//

import Foundation
import AVFoundation

struct DateTimeMapping: DateTimeConversion {
    let date: Date
    let time: CMTime

    init(date: Date, time: CMTime) {
        self.date = date
        self.time = time
    }

    func date(forTime: CMTime) -> Date {
        let diff = forTime - time
        return date.addingTimeInterval(diff.seconds)
    }

    func time(forDate: Date) -> CMTime {
        let diff = date.timeIntervalSince(forDate)
        return time - CMTime(seconds: diff, preferredTimescale: 1)
    }
}
