//
//  WorkoutDetailView.swift
//  Gains
//
//  Created by Rayaan Bokhari on 11/20/25.
//

import SwiftUI

struct WorkoutDetailView: View {
    let workout: Workout
    
    var body: some View {
        List {
            Section("Exercises") {
                ForEach(workout.exercises) { exercise in
                    ExerciseRowView(exercise: exercise)
                }
            }
            
            if let notes = workout.notes {
                Section("Notes") {
                    Text(notes)
                }
            }
        }
        .navigationTitle(workout.name)
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct ExerciseRowView: View {
    let exercise: Exercise
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(exercise.name)
                .font(.headline)
            
            if !exercise.sets.isEmpty {
                Text("\(exercise.sets.count) sets")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

#Preview {
    NavigationView {
        WorkoutDetailView(workout: Workout(
            name: "Push Day",
            exercises: [
                Exercise(name: "Bench Press", sets: [
                    ExerciseSet(reps: 10, weight: 135, completed: true),
                    ExerciseSet(reps: 8, weight: 155, completed: true)
                ])
            ]
        ))
    }
}

