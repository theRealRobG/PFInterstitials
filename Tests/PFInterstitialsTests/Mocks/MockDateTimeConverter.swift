//
//  MockDateTimeConverter.swift
//  
//
//  Created by Robert Galluccio on 01/11/2021.
//

@testable import PFInterstitials
import CoreMedia

class MockDateTimeConverter: DateTimeConverter {
    // MARK: - Mock listeners
    
    var addListener: ((DateTimeConversion) -> Void)?
    var updateListener: ((CMTimeRange) -> Void)?
    var dateForTimeListener: ((CMTime) -> Void)?
    var timeForDateListener: ((Date) -> Void)?

    // MARK: - Mock return values

    var dateForTimeReturnValue: Date?
    var timeForDateReturnValue: CMTime?

    override func add(mapping: DateTimeConversion) {
        addListener?(mapping)
    }

    override func update(playbackTimeRange: CMTimeRange) {
        updateListener?(playbackTimeRange)
    }

    override func date(forTime time: CMTime) -> Date? {
        dateForTimeListener?(time)
        return dateForTimeReturnValue
    }

    override func time(forDate date: Date) -> CMTime? {
        timeForDateListener?(date)
        return timeForDateReturnValue
    }
}
