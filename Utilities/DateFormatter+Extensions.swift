//
//  DateFormatter+Extensions.swift
//  Gains
//
//  Created by Rayaan Bokhari on 11/20/25.
//

import Foundation

extension DateFormatter {
    static let workoutDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()
    
    static let workoutDateOnly: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }()
}

