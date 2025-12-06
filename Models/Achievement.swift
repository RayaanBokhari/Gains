//
//  Achievement.swift
//  Gains
//
//  Created by Rayaan Bokhari on 11/21/25.
//

import Foundation

struct Achievement: Identifiable, Codable {
    let id: String
    var name: String
    var description: String
    var iconName: String
    var unlockedAt: Date?
    var progress: Double // 0.0 to 1.0
    var target: Int? // Target value for progress-based achievements
    
    init(id: String, name: String, description: String, iconName: String, unlockedAt: Date? = nil, progress: Double = 0.0, target: Int? = nil) {
        self.id = id
        self.name = name
        self.description = description
        self.iconName = iconName
        self.unlockedAt = unlockedAt
        self.progress = progress
        self.target = target
    }
    
    var isUnlocked: Bool {
        unlockedAt != nil
    }
}

// Predefined achievements
extension Achievement {
    static let firstMeal = Achievement(
        id: "first_meal",
        name: "First Meal",
        description: "Log your first meal",
        iconName: "fork.knife",
        target: 1
    )
    
    static let weekWarrior = Achievement(
        id: "week_warrior",
        name: "Week Warrior",
        description: "Maintain a 7-day streak",
        iconName: "flame.fill",
        target: 7
    )
    
    static let monthMaster = Achievement(
        id: "month_master",
        name: "Month Master",
        description: "Maintain a 30-day streak",
        iconName: "crown.fill",
        target: 30
    )
    
    static let centurion = Achievement(
        id: "centurion",
        name: "Centurion",
        description: "Log 100 meals",
        iconName: "medal.fill",
        target: 100
    )
    
    static let macroMaster = Achievement(
        id: "macro_master",
        name: "Macro Master",
        description: "Hit all macros 7 days in a row",
        iconName: "chart.bar.fill",
        target: 7
    )
    
    static func allAchievements() -> [Achievement] {
        return [
            .firstMeal,
            .weekWarrior,
            .monthMaster,
            .centurion,
            .macroMaster
        ]
    }
}

