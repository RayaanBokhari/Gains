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
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // Subscribe to workoutService's workouts updates
        workoutService.$workouts
            .receive(on: DispatchQueue.main)
            .sink { [weak self] workouts in
                self?.workouts = workouts
                print("WorkoutViewModel: Received \(workouts.count) workouts from service")
            }
            .store(in: &cancellables)
    }
    
    /// Call this when the view appears to start listening
    func startListening() {
        workoutService.startListening()
    }
    
    // MARK: - Active Workout Management
    
    func startWorkout(name: String) {
        currentWorkout = Workout(name: name, date: Date())
    }
    
    func cancelWorkout() {
        currentWorkout = nil
    }
    
    func endWorkout() async {
        guard let workout = currentWorkout else {
            print("WorkoutViewModel: No current workout to save")
            return
        }
        
        print("WorkoutViewModel: Saving workout '\(workout.name)' with \(workout.exercises.count) exercises")
        
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        do {
            try await workoutService.addWorkout(workout)
            print("WorkoutViewModel: Workout saved successfully")
            currentWorkout = nil
            // Workouts will update automatically via the listener
        } catch {
            errorMessage = "Failed to save workout: \(error.localizedDescription)"
            print("WorkoutViewModel: Error saving workout: \(error)")
        }
    }
    
    // MARK: - Exercise Management
    
    func addExercise(_ exercise: Exercise) {
        currentWorkout?.exercises.append(exercise)
    }
    
    func removeExercise(at index: Int) {
        guard var workout = currentWorkout,
              index >= 0 && index < workout.exercises.count else { return }
        workout.exercises.remove(at: index)
        currentWorkout = workout
    }
    
    // MARK: - Set Management
    
    func addSet(to exerciseIndex: Int) {
        guard var workout = currentWorkout,
              exerciseIndex >= 0 && exerciseIndex < workout.exercises.count else { return }
        
        // Copy values from the last set if available
        let newSet: ExerciseSet
        if let lastSet = workout.exercises[exerciseIndex].sets.last {
            newSet = ExerciseSet(reps: lastSet.reps, weight: lastSet.weight)
        } else {
            newSet = ExerciseSet()
        }
        
        workout.exercises[exerciseIndex].sets.append(newSet)
        currentWorkout = workout
    }
    
    func removeSet(exerciseIndex: Int, setIndex: Int) {
        guard var workout = currentWorkout,
              exerciseIndex >= 0 && exerciseIndex < workout.exercises.count,
              setIndex >= 0 && setIndex < workout.exercises[exerciseIndex].sets.count else { return }
        
        workout.exercises[exerciseIndex].sets.remove(at: setIndex)
        currentWorkout = workout
    }
    
    func updateSet(exerciseIndex: Int, setIndex: Int, weight: Double?, reps: Int?) {
        guard var workout = currentWorkout,
              exerciseIndex >= 0 && exerciseIndex < workout.exercises.count,
              setIndex >= 0 && setIndex < workout.exercises[exerciseIndex].sets.count else { return }
        
        if let weight = weight {
            workout.exercises[exerciseIndex].sets[setIndex].weight = weight
        }
        if let reps = reps {
            workout.exercises[exerciseIndex].sets[setIndex].reps = reps
        }
        currentWorkout = workout
    }
    
    func toggleSetComplete(exerciseIndex: Int, setIndex: Int) {
        guard var workout = currentWorkout,
              exerciseIndex >= 0 && exerciseIndex < workout.exercises.count,
              setIndex >= 0 && setIndex < workout.exercises[exerciseIndex].sets.count else { return }
        
        workout.exercises[exerciseIndex].sets[setIndex].completed.toggle()
        currentWorkout = workout
    }
    
    // MARK: - Data Loading
    
    func loadWorkouts() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        // If listener isn't active, do a one-time fetch
        if !workoutService.isListening {
            await workoutService.loadWorkouts()
        }
        // Otherwise the listener handles updates automatically
    }
    
    /// Force refresh from Firestore (for pull-to-refresh)
    func refreshWorkouts() async {
        await workoutService.loadWorkouts()
    }
    
    func updateWorkout(_ workout: Workout) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        do {
            try await workoutService.updateWorkout(workout)
            // Workouts will update automatically via the listener
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
            // Workouts will update automatically via the listener
        } catch {
            errorMessage = "Failed to delete workout: \(error.localizedDescription)"
            print("Error deleting workout: \(error)")
        }
    }
}

