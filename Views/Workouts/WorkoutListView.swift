//
//  WorkoutListView.swift
//  Gains
//
//  Created by Rayaan Bokhari on 11/20/25.
//

import SwiftUI

struct WorkoutListView: View {
    @StateObject private var viewModel = WorkoutViewModel()
    
    var body: some View {
        NavigationView {
            List(viewModel.workouts) { workout in
                NavigationLink(destination: WorkoutDetailView(workout: workout)) {
                    WorkoutRowView(workout: workout)
                }
            }
            .navigationTitle("Workouts")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        viewModel.startWorkout(name: "New Workout")
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
        }
    }
}

struct WorkoutRowView: View {
    let workout: Workout
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(workout.name)
                .font(.headline)
            Text(workout.date, style: .date)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    WorkoutListView()
}

