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
    @State private var isReorderingExercises = false
    
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
                                        viewModel: viewModel,
                                        isReordering: isReorderingExercises
                                    )
                                }
                                .onMove(perform: isReorderingExercises ? { indices, newOffset in
                                    viewModel.moveExercise(from: indices, to: newOffset)
                                } : nil)
                                
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
            .environment(\.editMode, .constant(isReorderingExercises ? EditMode.active : EditMode.inactive))
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        showDiscardAlert = true
                    } label: {
                        Text("Cancel")
                            .foregroundColor(.red)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    if let workout = viewModel.currentWorkout, workout.exercises.count > 1 {
                        Button(isReorderingExercises ? "Done" : "Reorder") {
                            withAnimation {
                                isReorderingExercises.toggle()
                            }
                        }
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
    let isReordering: Bool
    @State private var showDeleteAlert = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Exercise Header
            HStack {
                if isReordering {
                    Image(systemName: "line.horizontal.3")
                        .foregroundColor(.gainsSecondaryText.opacity(0.5))
                        .font(.system(size: 16))
                        .padding(.trailing, 8)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(exercise.name)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.gainsText)
                    
                    Text("\(exercise.sets.count) set\(exercise.sets.count == 1 ? "" : "s")")
                        .font(.system(size: 12))
                        .foregroundColor(.gainsSecondaryText)
                }
                
                Spacer()
                
                if !isReordering {
                    Menu {
                        Button(role: .destructive) {
                            showDeleteAlert = true
                        } label: {
                            Label("Remove Exercise", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 16))
                            .foregroundColor(.gainsSecondaryText)
                            .frame(width: 32, height: 32)
                    }
                }
            }
            .padding()
            .background(Color.gainsCardBackground)
            
            // Sets Table Header
            if !exercise.sets.isEmpty {
                HStack(spacing: 8) {
                    Text("SET")
                        .frame(width: 35, alignment: .leading)
                    Text("WEIGHT")
                        .frame(maxWidth: .infinity)
                    Text("REPS")
                        .frame(maxWidth: .infinity)
                    if exercise.sets.count > 1 {
                        Text("−")
                            .frame(width: 35)
                    } else {
                        Color.clear
                            .frame(width: 35)
                    }
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
                    viewModel: viewModel,
                    canDelete: exercise.sets.count > 1
                )
            }
            
            // Separator before Add Set
            Divider()
                .background(Color.gainsSecondaryText.opacity(0.2))
                .padding(.horizontal)
            
            // Add Set Button
            Button {
                viewModel.addSet(to: exerciseIndex)
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 16))
                    Text("Add Set")
                        .font(.system(size: 15, weight: .semibold))
                }
                .foregroundColor(.gainsPrimary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
            }
            .background(Color.gainsCardBackground)
            .padding(.horizontal, 4)
            .padding(.bottom, 4)
        }
        .background(Color.gainsCardBackground)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gainsSecondaryText.opacity(0.1), lineWidth: 1)
        )
        .alert("Remove \(exercise.name)?", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Remove", role: .destructive) {
                viewModel.removeExercise(at: exerciseIndex)
            }
        } message: {
            Text("This will delete all \(exercise.sets.count) set\(exercise.sets.count == 1 ? "" : "s") and cannot be undone.")
        }
    }
}

struct SetRow: View {
    let set: ExerciseSet
    let setNumber: Int
    let exerciseIndex: Int
    let setIndex: Int
    @ObservedObject var viewModel: WorkoutViewModel
    let canDelete: Bool
    
    @State private var weightText: String = ""
    @State private var repsText: String = ""
    
    var body: some View {
        HStack(spacing: 8) {
            Text("\(setNumber)")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.gainsSecondaryText)
                .frame(width: 35, alignment: .leading)
            
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
            
            // Delete Set Button
            if canDelete {
                Button {
                    viewModel.removeSet(exerciseIndex: exerciseIndex, setIndex: setIndex)
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.red.opacity(0.7))
                }
                .frame(width: 35)
            } else {
                // Spacer to maintain alignment when delete button is hidden
                Color.clear
                    .frame(width: 35)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
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

