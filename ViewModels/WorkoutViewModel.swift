//
//  WorkoutViewModel.swift
//  Gains
//
//  Created by Rayaan Bokhari on 11/20/25.
//

import Foundation
import Combine
import SwiftUI

@MainActor
class WorkoutViewModel: ObservableObject {
    @Published var currentWorkout: Workout?
    @Published var workouts: [Workout] = []
    
    private let workoutService = WorkoutService()
    
    init() {
        loadWorkouts()
    }
    
    func startWorkout(name: String) {
        currentWorkout = Workout(name: name, date: Date())
    }
    
    func endWorkout() {
        if var workout = currentWorkout {
            workoutService.addWorkout(workout)
            currentWorkout = nil
            loadWorkouts()
        }
    }
    
    func addExercise(_ exercise: Exercise) {
        currentWorkout?.exercises.append(exercise)
    }
    
    private func loadWorkouts() {
        workouts = workoutService.workouts
    }
}

