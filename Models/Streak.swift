//
//  Streak.swift
//  Gains
//
//  Created by Rayaan Bokhari on 11/21/25.
//

import Foundation

struct Streak: Codable {
    var currentStreak: Int
    var longestStreak: Int
    var lastLoggedDate: Date?
    
    init(currentStreak: Int = 0, longestStreak: Int = 0, lastLoggedDate: Date? = nil) {
        self.currentStreak = currentStreak
        self.longestStreak = longestStreak
        self.lastLoggedDate = lastLoggedDate
    }
}

