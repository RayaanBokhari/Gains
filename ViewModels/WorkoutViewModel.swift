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
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let workoutService = WorkoutService()
    
    init() {
        Task {
            await loadWorkouts()
        }
    }
    
    func startWorkout(name: String) {
        currentWorkout = Workout(name: name, date: Date())
    }
    
    func endWorkout() async {
        if let workout = currentWorkout {
            isLoading = true
            errorMessage = nil
            defer { isLoading = false }
            
            do {
                try await workoutService.addWorkout(workout)
                currentWorkout = nil
                await loadWorkouts()
            } catch {
                errorMessage = "Failed to save workout: \(error.localizedDescription)"
                print("Error saving workout: \(error)")
            }
        }
    }
    
    func addExercise(_ exercise: Exercise) {
        currentWorkout?.exercises.append(exercise)
    }
    
    func loadWorkouts() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        await workoutService.loadWorkouts()
        workouts = workoutService.workouts
    }
    
    func updateWorkout(_ workout: Workout) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        do {
            try await workoutService.updateWorkout(workout)
            await loadWorkouts()
        } catch {
            errorMessage = "Failed to update workout: \(error.localizedDescription)"
            print("Error updating workout: \(error)")
        }
    }
    
    func deleteWorkout(_ workout: Workout) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        do {
            try await workoutService.deleteWorkout(workout)
            await loadWorkouts()
        } catch {
            errorMessage = "Failed to delete workout: \(error.localizedDescription)"
            print("Error deleting workout: \(error)")
        }
    }
}

