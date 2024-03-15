//
//  DateFormatUtility.swift
//  MyCoreDataTest
//
//  Created by t&a on 2024/03/15.
//

import UIKit

class DateFormatUtility {

    private let df = DateFormatter()

    init(format: String = "yyyy年MM月dd日 HH時mm分ss秒") {
        df.dateFormat = format
        df.locale = Locale(identifier: "ja_JP")
        df.calendar = Calendar(identifier: .gregorian)
    }
    
    public func getString(date: Date) -> String {
        return df.string(from: date)
    }
    
    public func getDate(str: String) -> Date {
        return df.date(from: str) ?? Date()
    }
}

