//
//  WorkoutService.swift
//  Gains
//
//  Created by Rayaan Bokhari on 11/20/25.
//

import Foundation
import Combine

class WorkoutService: ObservableObject {
    @Published var workouts: [Workout] = []
    
    init() {
        loadWorkouts()
    }
    
    func addWorkout(_ workout: Workout) {
        workouts.append(workout)
        saveWorkouts()
    }
    
    func updateWorkout(_ workout: Workout) {
        if let index = workouts.firstIndex(where: { $0.id == workout.id }) {
            workouts[index] = workout
            saveWorkouts()
        }
    }
    
    func deleteWorkout(_ workout: Workout) {
        workouts.removeAll { $0.id == workout.id }
        saveWorkouts()
    }
    
    private func saveWorkouts() {
        // TODO: Implement persistence (Core Data, UserDefaults, or file system)
    }
    
    private func loadWorkouts() {
        // TODO: Implement loading from persistence
    }
}

