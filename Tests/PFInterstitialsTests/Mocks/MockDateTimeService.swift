//
//  MockDateTimeService.swift
//  
//
//  Created by Robert Galluccio on 01/11/2021.
//

@testable import PFInterstitials
import CoreMedia

class MockDateTimeService: DateTimeService {
    // MARK: - Mock listeners
    
    var dateForTimeListener: ((CMTime) -> Void)?
    var timeForDateListener: ((Date) -> Void)?

    // MARK: - Mock return values

    var dateForTimeReturnValue: Date?
    var timeForDateReturnValue: CMTime?

    init() {
        super.init(
            currentPrimaryPlayerItem: MockAVPlayerItem(url: URL(string: "http://fake.com/master.m3u8")!),
            playerObserver: MockPlayerObserver(),
            playerItemObserver: MockPlayerItemObserver(),
            dateTimeConverter: MockDateTimeConverter()
        )
    }

    // MARK: - Override functions

    override func date(forTime time: CMTime) -> Date? {
        dateForTimeListener?(time)
        return dateForTimeReturnValue
    }

    override func time(forDate date: Date) -> CMTime? {
        timeForDateListener?(date)
        return timeForDateReturnValue
    }
}
