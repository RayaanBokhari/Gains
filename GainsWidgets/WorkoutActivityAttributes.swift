//
//  WorkoutActivityAttributes.swift
//  GainsWidgets
//
//  Shared attributes for Workout Live Activity
//  This file must be included in BOTH the main app and widget targets
//

import Foundation
import ActivityKit

// MARK: - Workout Activity Attributes
struct WorkoutActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic state that updates during workout
        var exerciseName: String
        var currentSet: Int
        var totalSets: Int
        var lastWeight: Double?
        var lastReps: Int?
        var isResting: Bool
        var restTimeRemaining: Int // seconds
        var elapsedTime: TimeInterval
        var totalSetsCompleted: Int
        
        // Formatted helpers
        var formattedRestTime: String {
            let minutes = restTimeRemaining / 60
            let seconds = restTimeRemaining % 60
            if minutes > 0 {
                return String(format: "%d:%02d", minutes, seconds)
            }
            return "\(seconds)s"
        }
        
        var formattedElapsedTime: String {
            let minutes = Int(elapsedTime) / 60
            let seconds = Int(elapsedTime) % 60
            return String(format: "%d:%02d", minutes, seconds)
        }
        
        var lastSetSummary: String? {
            guard let weight = lastWeight, let reps = lastReps else { return nil }
            let weightStr = weight.truncatingRemainder(dividingBy: 1) == 0 
                ? "\(Int(weight))" 
                : String(format: "%.1f", weight)
            return "\(weightStr) lb × \(reps)"
        }
    }
    
    // Static data that doesn't change during the activity
    var workoutName: String
    var startTime: Date
}

