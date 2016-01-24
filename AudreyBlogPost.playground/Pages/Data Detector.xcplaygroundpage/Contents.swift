//: [Previous](@previous)

import Foundation
import UIKit


enum DetectedData {
    case TransitInformation(airline: String?, flight: String)
    case PhoneNumber(phoneNumber: String)
    case Event(date: NSDate, duration: NSTimeInterval?, timeZone: NSTimeZone?)
    
    init?(result: NSTextCheckingResult) {
        if let components = result.components, flight = components[NSTextCheckingFlightKey] {
            let airline = components[NSTextCheckingFlightKey]
            self = .TransitInformation(airline: airline, flight: flight)
        } else if let date = result.date {
            self = .Event(date: date, duration: result.duration == 0 ? nil : result.duration, timeZone: result.timeZone)
        } else if let phoneNumber = result.phoneNumber {
            self = .PhoneNumber(phoneNumber: phoneNumber)
        } else {
            return nil
        }
    }
}

extension NSDataDetector {
    func enumerateMatchesInString(string: String, range: NSRange, block: ((DetectedData, NSRange) -> Void)) {
        enumerateMatchesInString(string, options: [], range: range) { result, _, _ in
            guard let result = result, data = DetectedData(result: result) else {
                return
            }
            block(data, result.range)
        }
    }
}


let string = "You are picking up John Smith tomorrow at 12:40pm, at San Francisco International Airport. The contact phone number is 4167188193. Flight UA460."
let attributedString = NSMutableAttributedString(string: string, attributes: [NSFontAttributeName: UIFont.systemFontOfSize(14)])

let types: NSTextCheckingType = [.TransitInformation, .PhoneNumber, .Date, .Address]
let detector = try! NSDataDetector(types: types.rawValue)
detector.enumerateMatchesInString(string, range: string.entireStringRange) { data, range in
    switch data {
    case let .TransitInformation(airline, flight):
        attributedString.setAttributes([
            NSLinkAttributeName: NSURL(string: "auber://flight?number=\(flight)")!,
            NSForegroundColorAttributeName: UIColor(red:0, green:0.498, blue:1, alpha:1),
            NSUnderlineStyleAttributeName: NSUnderlineStyle.StyleSingle.rawValue
        ], range: range)
    case let .Event(date, duration, timeZone):
        attributedString.setAttributes([
            NSLinkAttributeName: NSURL(string: "auber://event?date=\(date.timeIntervalSince1970)")!,
            NSForegroundColorAttributeName: UIColor(red:0.392, green:0.662, blue:0.125, alpha:1),
            NSUnderlineStyleAttributeName: NSUnderlineStyle.StyleSingle.rawValue
        ], range: range)
    case let .PhoneNumber(phoneNumber):
        attributedString.setAttributes([
            NSLinkAttributeName: NSURL(string: "auber://event?date=\(phoneNumber)")!,
            NSForegroundColorAttributeName: UIColor(red:0.749, green:0.098, blue:0.023, alpha:1),
            NSUnderlineStyleAttributeName: NSUnderlineStyle.StyleSingle.rawValue
        ], range: range)

    }
    
}

attributedString
