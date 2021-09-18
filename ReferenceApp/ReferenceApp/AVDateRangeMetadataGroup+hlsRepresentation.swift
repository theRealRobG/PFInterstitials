//
//  AVDateRangeMetadataGroup+hlsRepresentation.swift
//  ReferenceApp
//
//  Created by Robert Galluccio on 18/09/2021.
//

import Foundation
import AVFoundation

private extension TimeInterval {
    var pretty: String {
        if self.rounded() == self {
            return "\(Int(self))"
        } else {
            return "\(self)"
        }
    }
}

extension AVDateRangeMetadataGroup {
    private enum DateRangeAttribute: String {
        case CLASS
        case DURATION
        case PLANNED_DURATION = "PLANNED-DURATION"
        case SCTE35_CMD = "SCTE35-CMD"
        case SCTE35_OUT = "SCTE35-OUT"
        case SCTE35_IN = "SCTE35-IN"
        case END_ON_NEXT = "END-ON-NEXT"
    }

    var hlsRepresentation: String {
        let iso8601DateFormatter = ISO8601DateFormatter()
        var hlsTag = "#EXT-X-DATERANGE:START-DATE=\"\(iso8601DateFormatter.string(from: self.startDate))\""
        if let id = self.uniqueID {
            hlsTag += ",ID=\"\(id)\""
        }
        if let endDate = self.endDate {
            hlsTag += ",END-DATE=\"\(iso8601DateFormatter.string(from: endDate))\""
        }
        items.forEach { item in
            guard let key = item.key as? String, let attribute = DateRangeAttribute(rawValue: key) else {
                if let custom = customAtrribute(from: item) {
                    hlsTag += ",\(custom)"
                }
                return
            }
            switch attribute {
            case .CLASS:
                guard let value = item.stringValue else { return }
                hlsTag += ",\(attribute.rawValue)=\"\(value)\""
            case .DURATION:
                guard let value = item.numberValue?.timeValue.seconds else { return }
                hlsTag += ",\(attribute.rawValue)=\(value.pretty)"
            case .PLANNED_DURATION:
                guard let value = item.numberValue?.timeValue.seconds else { return }
                hlsTag += ",\(attribute.rawValue)=\(value.pretty)"
            case .SCTE35_CMD:
                guard let value = item.dataValue?.map({ String(format: "%02hhX", $0) }).joined() else { return }
                hlsTag += ",\(attribute.rawValue)=0x\(value)"
            case .SCTE35_OUT:
                guard let value = item.dataValue?.map({ String(format: "%02hhX", $0) }).joined() else { return }
                hlsTag += ",\(attribute.rawValue)=0x\(value)"
            case .SCTE35_IN:
                guard let value = item.dataValue?.map({ String(format: "%02hhX", $0) }).joined() else { return }
                hlsTag += ",\(attribute.rawValue)=0x\(value)"
            case .END_ON_NEXT:
                guard let value = item.stringValue else { return }
                hlsTag += ",\(attribute.rawValue)=\(value)"
            }
        }
        return hlsTag
    }

    private func customAtrribute(from item: AVMetadataItem) -> String? {
        guard let key = item.key as? String, key.starts(with: "X-") else { return nil }
        if let value = item.stringValue {
            return "\(key)=\"\(value)\""
        } else if let value = item.numberValue?.timeValue.seconds {
            return "\(key)=\(value.pretty)"
        } else if let value = item.dataValue?.map({ String(format: "%02hhX", $0) }).joined() {
            return "\(key)=\(value)"
        } else {
            return nil
        }
    }
}
