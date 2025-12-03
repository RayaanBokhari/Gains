//
//  NutritionSummary.swift
//  Gains
//
//  Created by Rayaan Bokhari on 12/20/25.
//

import Foundation

struct WeeklyNutritionSummary {
    let avgCalories: Double
    let avgProtein: Double
    let avgCarbs: Double
    let avgFats: Double
    let calorieGoal: Double
    let proteinGoal: Double
    let daysLogged: Int
    let daysOnCalorieTarget: Int // within ±10%
    let daysOnProteinTarget: Int
    let loggingStreak: Int
    
    var notablePatternDescription: String {
        var patterns: [String] = []
        
        let calorieAccuracy = avgCalories / calorieGoal
        if calorieAccuracy < 0.85 {
            patterns.append("Often under-eating calories")
        } else if calorieAccuracy > 1.15 {
            patterns.append("Often over-eating calories")
        }
        
        let proteinAccuracy = avgProtein / proteinGoal
        if proteinAccuracy < 0.85 {
            patterns.append("Struggling to hit protein goal")
        }
        
        if patterns.isEmpty {
            return "Consistent with targets"
        }
        return patterns.joined(separator: "; ")
    }
}

