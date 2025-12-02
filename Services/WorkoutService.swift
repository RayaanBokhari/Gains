//
//  WorkoutService.swift
//  Gains
//
//  Created by Rayaan Bokhari on 11/20/25.
//

import Foundation
import Combine
import FirebaseAuth
import FirebaseFirestore

@MainActor
class WorkoutService: ObservableObject {
    @Published var workouts: [Workout] = []
    @Published var isListening = false
    
    private let firestore = FirestoreService.shared
    private let auth = AuthService.shared
    private nonisolated(unsafe) var listenerRegistration: ListenerRegistration?
    
    deinit {
        listenerRegistration?.remove()
    }
    
    /// Start listening to workouts with real-time updates
    /// This works offline and syncs automatically when back online
    func startListening() {
        guard let user = auth.user else {
            print("WorkoutService: No user available, cannot start listening")
            return
        }
        guard !isListening else {
            print("WorkoutService: Already listening")
            return
        }
        
        print("WorkoutService: Starting listener for user \(user.uid)")
        isListening = true
        
        let db = Firestore.firestore()
        listenerRegistration = db
            .collection("users")
            .document(user.uid)
            .collection("workouts")
            .order(by: "date", descending: true)
            .addSnapshotListener(includeMetadataChanges: true) { [weak self] snapshot, error in
                // Dispatch to main actor for UI updates
                Task { @MainActor in
                    guard let self = self else { return }
                    
                    if let error = error {
                        print("WorkoutService: Error listening to workouts: \(error)")
                        return
                    }
                    
                    guard let documents = snapshot?.documents else {
                        print("WorkoutService: No documents in snapshot")
                        return
                    }
                    
                    // Check if data is from cache or server
                    let source = snapshot?.metadata.isFromCache == true ? "cache" : "server"
                    print("WorkoutService: Loaded \(documents.count) workouts from \(source)")
                    
                    let loadedWorkouts = documents.compactMap { doc -> Workout? in
                        do {
                            var workout = try doc.data(as: Workout.self)
                            workout.workoutId = doc.documentID
                            return workout
                        } catch {
                            print("WorkoutService: Failed to decode workout \(doc.documentID): \(error)")
                            return nil
                        }
                    }
                    
                    self.workouts = loadedWorkouts
                    print("WorkoutService: Updated workouts array with \(loadedWorkouts.count) items")
                }
            }
    }
    
    /// Stop listening to real-time updates
    func stopListening() {
        listenerRegistration?.remove()
        listenerRegistration = nil
        isListening = false
    }
    
    /// One-time fetch of workouts (for initial load or manual refresh)
    func loadWorkouts() async {
        guard let user = auth.user else { return }
        
        do {
            workouts = try await firestore.fetchWorkouts(userId: user.uid)
        } catch {
            print("Error loading workouts: \(error)")
        }
    }
    
    func addWorkout(_ workout: Workout) async throws {
        guard let user = auth.user else {
            print("WorkoutService: No user available, cannot save workout")
            return
        }
        
        print("WorkoutService: Saving workout to Firestore for user \(user.uid)")
        try await firestore.saveWorkout(userId: user.uid, workout: workout)
        print("WorkoutService: Workout saved to Firestore")
        // No need to manually reload - the listener will pick up the change
    }
    
    func updateWorkout(_ workout: Workout) async throws {
        guard let user = auth.user,
              let workoutId = workout.workoutId else { return }
        
        try await firestore.updateWorkout(userId: user.uid, workoutId: workoutId, workout: workout)
        // No need to manually reload - the listener will pick up the change
    }
    
    func deleteWorkout(_ workout: Workout) async throws {
        guard let user = auth.user,
              let workoutId = workout.workoutId else { return }
        
        try await firestore.deleteWorkout(userId: user.uid, workoutId: workoutId)
        // No need to manually reload - the listener will pick up the change
    }
}

