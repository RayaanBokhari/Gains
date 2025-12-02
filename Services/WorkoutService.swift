//
//  WorkoutService.swift
//  Gains
//
//  Created by Rayaan Bokhari on 11/20/25.
//

import Foundation
import Combine
import FirebaseAuth

@MainActor
class WorkoutService: ObservableObject {
    @Published var workouts: [Workout] = []
    
    private let firestore = FirestoreService.shared
    private let auth = AuthService.shared
    
    func loadWorkouts() async {
        guard let user = auth.user else { return }
        
        do {
            workouts = try await firestore.fetchWorkouts(userId: user.uid)
        } catch {
            print("Error loading workouts: \(error)")
        }
    }
    
    func addWorkout(_ workout: Workout) async throws {
        guard let user = auth.user else { return }
        
        try await firestore.saveWorkout(userId: user.uid, workout: workout)
        await loadWorkouts()
    }
    
    func updateWorkout(_ workout: Workout) async throws {
        guard let user = auth.user,
              let workoutId = workout.workoutId else { return }
        
        try await firestore.updateWorkout(userId: user.uid, workoutId: workoutId, workout: workout)
        await loadWorkouts()
    }
    
    func deleteWorkout(_ workout: Workout) async throws {
        guard let user = auth.user,
              let workoutId = workout.workoutId else { return }
        
        try await firestore.deleteWorkout(userId: user.uid, workoutId: workoutId)
        await loadWorkouts()
    }
}

