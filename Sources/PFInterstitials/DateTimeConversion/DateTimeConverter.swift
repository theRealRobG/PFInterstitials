//
//  DateTimeConverter.swift
//  
//
//  Created by Robert Galluccio on 27/09/2021.
//

import Foundation
import AVFoundation

class DateTimeConverter {
    private var mappings = [DateTimeConversion]() {
        didSet {
            mappings.sort(by: { $0.time < $1.time })
            updateDateRanges(using: mappings)
        }
    }
    private var dateRanges = [Range<Date>]()

    func add(mapping: DateTimeConversion) {
        mappings.append(mapping)
    }

    func update(playbackTimeRange: CMTimeRange) {
        let timesToRemove = mappings.enumerated()
            .filter { mapping in
                if playbackTimeRange.containsTime(mapping.element.time) {
                    return false
                } else if mappings.indices.contains(mapping.offset + 1), playbackTimeRange.containsTime(mappings[mapping.offset + 1].time) {
                    return false
                } else if !mappings.indices.contains(mapping.offset + 1) {
                    return false
                } else {
                    return true
                }
            }
            .map { $0.element.time }
        mappings.removeAll(where: { timesToRemove.contains($0.time) })
    }

    func date(forTime time: CMTime) -> Date? {
        let mapping = mappings.last(where: { $0.time <= time }) ?? mappings.first
        return mapping?.date(forTime: time)
    }

    func time(forDate date: Date) -> CMTime? {
        guard let index = dateRanges.firstIndex(where: { $0.contains(date) }) else { return nil }
        guard mappings.indices.contains(index) else { return nil }
        return mappings[index].time(forDate: date)
    }

    private func updateDateRanges(using mappings: [DateTimeConversion]) {
        dateRanges = mappings.enumerated().reduce(into: []) { ranges, enumeratedMapping in
            let index = enumeratedMapping.offset
            let mapping = enumeratedMapping.element
            let rangeStart: Date
            let rangeEnd: Date
            if ranges.isEmpty {
                rangeStart = .distantPast
            } else {
                rangeStart = mapping.date
            }
            if mappings.indices.contains(index + 1) {
                rangeEnd = mapping.date(forTime: mappings[index + 1].time)
            } else {
                rangeEnd = .distantFuture
            }
            ranges.append(rangeStart..<rangeEnd)
        }
    }
}
