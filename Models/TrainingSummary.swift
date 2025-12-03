//
//  TrainingSummary.swift
//  Gains
//
//  Created by Rayaan Bokhari on 12/20/25.
//

import Foundation

struct WeeklyTrainingSummary {
    let sessionsThisWeek: Int
    let totalVolume: Double // total weight lifted
    let muscleGroupsWorked: [String: Int] // e.g. ["Chest": 2, "Back": 1]
    let lastWorkout: Workout?
    let averageExercisesPerSession: Double
    let averageSetsPerSession: Double
    
    var lastWorkoutDescription: String {
        guard let workout = lastWorkout else { return "No recent workouts" }
        let exercises = workout.exercises.map { $0.name }.prefix(3).joined(separator: ", ")
        return "\(workout.name): \(exercises)"
    }
    
    var lastWorkoutDateString: String {
        guard let workout = lastWorkout else { return "N/A" }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: workout.date, relativeTo: Date())
    }
    
    var muscleGroupsSummary: String {
        muscleGroupsWorked.map { "\($0.key): \($0.value)x" }.joined(separator: ", ")
    }
}

