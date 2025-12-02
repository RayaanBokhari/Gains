//
//  ActiveWorkoutView.swift
//  Gains
//
//  Created by Rayaan Bokhari on 11/20/25.
//

import SwiftUI

struct ActiveWorkoutView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: WorkoutViewModel
    @State private var showAddExercise = false
    @State private var showDiscardAlert = false
    @State private var workoutNotes = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.gainsBackground.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header
                    HStack {
                        Text(viewModel.currentWorkout?.name ?? "Workout")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.gainsText)
                        
                        Spacer()
                        
                        // Exercise count
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("\(viewModel.currentWorkout?.exercises.count ?? 0)")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.gainsPrimary)
                            Text("exercises")
                                .font(.system(size: 12))
                                .foregroundColor(.gainsSecondaryText)
                        }
                    }
                    .padding()
                    .background(Color.gainsCardBackground)
                    
                    if let workout = viewModel.currentWorkout, !workout.exercises.isEmpty {
                        // Exercise List
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(Array(workout.exercises.enumerated()), id: \.element.id) { index, exercise in
                                    ExerciseCard(
                                        exercise: exercise,
                                        exerciseIndex: index,
                                        viewModel: viewModel
                                    )
                                }
                                
                                // Add Exercise Button
                                Button {
                                    showAddExercise = true
                                } label: {
                                    HStack {
                                        Image(systemName: "plus.circle.fill")
                                            .font(.system(size: 20))
                                        Text("Add Exercise")
                                            .font(.system(size: 16, weight: .semibold))
                                    }
                                    .foregroundColor(.gainsPrimary)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.gainsCardBackground)
                                    .cornerRadius(12)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.gainsPrimary.opacity(0.3), lineWidth: 1)
                                    )
                                }
                                
                                // Notes Section
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Workout Notes")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.gainsSecondaryText)
                                    
                                    TextField("Add notes about your workout...", text: $workoutNotes, axis: .vertical)
                                        .textFieldStyle(.plain)
                                        .padding()
                                        .background(Color.gainsCardBackground)
                                        .cornerRadius(12)
                                        .foregroundColor(.gainsText)
                                        .lineLimit(3...6)
                                }
                            }
                            .padding()
                        }
                    } else {
                        // Empty state
                        VStack(spacing: 24) {
                            Spacer()
                            
                            Image(systemName: "figure.strengthtraining.traditional")
                                .font(.system(size: 64))
                                .foregroundColor(.gainsSecondaryText.opacity(0.5))
                            
                            VStack(spacing: 8) {
                                Text("No Exercises Yet")
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundColor(.gainsText)
                                
                                Text("Add exercises to start tracking your workout")
                                    .font(.system(size: 14))
                                    .foregroundColor(.gainsSecondaryText)
                                    .multilineTextAlignment(.center)
                            }
                            
                            Button {
                                showAddExercise = true
                            } label: {
                                HStack {
                                    Image(systemName: "plus.circle.fill")
                                    Text("Add First Exercise")
                                }
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 14)
                                .background(Color.gainsPrimary)
                                .cornerRadius(12)
                            }
                            
                            Spacer()
                        }
                        .padding()
                    }
                    
                    // Finish Workout Button
                    Button {
                        viewModel.currentWorkout?.notes = workoutNotes.isEmpty ? nil : workoutNotes
                        Task {
                            await viewModel.endWorkout()
                            dismiss()
                        }
                    } label: {
                        Text("Finish Workout")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                (viewModel.currentWorkout?.exercises.isEmpty ?? true)
                                    ? Color.gray.opacity(0.5)
                                    : Color.green
                            )
                            .cornerRadius(12)
                    }
                    .disabled(viewModel.currentWorkout?.exercises.isEmpty ?? true)
                    .padding()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        showDiscardAlert = true
                    } label: {
                        Text("Cancel")
                            .foregroundColor(.red)
                    }
                }
            }
            .alert("Discard Workout?", isPresented: $showDiscardAlert) {
                Button("Keep Working", role: .cancel) { }
                Button("Discard", role: .destructive) {
                    viewModel.cancelWorkout()
                    dismiss()
                }
            } message: {
                Text("Your workout progress will be lost.")
            }
            .sheet(isPresented: $showAddExercise) {
                AddExerciseView(viewModel: viewModel)
            }
        }
    }
}

struct ExerciseCard: View {
    let exercise: Exercise
    let exerciseIndex: Int
    @ObservedObject var viewModel: WorkoutViewModel
    @State private var showAddSet = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Exercise Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(exercise.name)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.gainsText)
                    
                    Text("\(exercise.sets.count) set\(exercise.sets.count == 1 ? "" : "s")")
                        .font(.system(size: 12))
                        .foregroundColor(.gainsSecondaryText)
                }
                
                Spacer()
                
                Button {
                    viewModel.removeExercise(at: exerciseIndex)
                } label: {
                    Image(systemName: "trash")
                        .font(.system(size: 14))
                        .foregroundColor(.red.opacity(0.7))
                }
            }
            .padding()
            .background(Color.gainsCardBackground)
            
            // Sets Table Header
            if !exercise.sets.isEmpty {
                HStack {
                    Text("SET")
                        .frame(width: 40, alignment: .leading)
                    Text("WEIGHT")
                        .frame(maxWidth: .infinity)
                    Text("REPS")
                        .frame(maxWidth: .infinity)
                    Text("✓")
                        .frame(width: 40)
                }
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(.gainsSecondaryText)
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(Color.gainsBackground)
            }
            
            // Sets
            ForEach(Array(exercise.sets.enumerated()), id: \.element.id) { setIndex, set in
                SetRow(
                    set: set,
                    setNumber: setIndex + 1,
                    exerciseIndex: exerciseIndex,
                    setIndex: setIndex,
                    viewModel: viewModel
                )
            }
            
            // Add Set Button
            Button {
                viewModel.addSet(to: exerciseIndex)
            } label: {
                HStack {
                    Image(systemName: "plus")
                        .font(.system(size: 12, weight: .semibold))
                    Text("Add Set")
                        .font(.system(size: 14, weight: .medium))
                }
                .foregroundColor(.gainsPrimary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
            }
            .background(Color.gainsCardBackground.opacity(0.5))
        }
        .background(Color.gainsCardBackground)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gainsSecondaryText.opacity(0.1), lineWidth: 1)
        )
    }
}

struct SetRow: View {
    let set: ExerciseSet
    let setNumber: Int
    let exerciseIndex: Int
    let setIndex: Int
    @ObservedObject var viewModel: WorkoutViewModel
    
    @State private var weightText: String = ""
    @State private var repsText: String = ""
    
    var body: some View {
        HStack {
            Text("\(setNumber)")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.gainsSecondaryText)
                .frame(width: 40, alignment: .leading)
            
            // Weight Input
            TextField("0", text: $weightText)
                .keyboardType(.decimalPad)
                .font(.system(size: 14))
                .multilineTextAlignment(.center)
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(Color.gainsBackground)
                .cornerRadius(8)
                .foregroundColor(.gainsText)
                .frame(maxWidth: .infinity)
                .onChange(of: weightText) { _, newValue in
                    if let weight = Double(newValue) {
                        viewModel.updateSet(exerciseIndex: exerciseIndex, setIndex: setIndex, weight: weight, reps: nil)
                    }
                }
            
            // Reps Input
            TextField("0", text: $repsText)
                .keyboardType(.numberPad)
                .font(.system(size: 14))
                .multilineTextAlignment(.center)
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(Color.gainsBackground)
                .cornerRadius(8)
                .foregroundColor(.gainsText)
                .frame(maxWidth: .infinity)
                .onChange(of: repsText) { _, newValue in
                    if let reps = Int(newValue) {
                        viewModel.updateSet(exerciseIndex: exerciseIndex, setIndex: setIndex, weight: nil, reps: reps)
                    }
                }
            
            // Complete Toggle
            Button {
                viewModel.toggleSetComplete(exerciseIndex: exerciseIndex, setIndex: setIndex)
            } label: {
                Image(systemName: set.completed ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22))
                    .foregroundColor(set.completed ? .green : .gainsSecondaryText)
            }
            .frame(width: 40)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(set.completed ? Color.green.opacity(0.1) : Color.clear)
        .onAppear {
            if let weight = set.weight {
                weightText = weight.truncatingRemainder(dividingBy: 1) == 0 ? String(format: "%.0f", weight) : String(format: "%.1f", weight)
            }
            if let reps = set.reps {
                repsText = String(reps)
            }
        }
    }
}

#Preview {
    ActiveWorkoutView(viewModel: WorkoutViewModel())
}

