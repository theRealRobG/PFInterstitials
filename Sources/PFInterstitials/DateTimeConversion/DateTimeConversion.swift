//
//  DateTimeConversion.swift
//  
//
//  Created by Robert Galluccio on 27/09/2021.
//

import Foundation
import AVFoundation

protocol DateTimeConversion {
    var date: Date { get }
    var time: CMTime { get }

    func date(forTime time: CMTime) -> Date
    func time(forDate date: Date) -> CMTime
}
