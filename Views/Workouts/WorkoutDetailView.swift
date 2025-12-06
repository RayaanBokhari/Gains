//
//  WorkoutDetailView.swift
//  Gains
//
//  Created by Rayaan Bokhari on 11/20/25.
//

import SwiftUI

struct WorkoutDetailView: View {
    @StateObject private var viewModel = WorkoutViewModel()
    @Environment(\.dismiss) var dismiss
    
    let workout: Workout
    
    @State private var showEditSheet = false
    @State private var showDeleteConfirmation = false
    @State private var isDeleting = false
    
    var body: some View {
        ZStack {
            Color.gainsBackground.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 20) {
                    // Workout Info Card
                    workoutInfoCard
                    
                    // Exercises Section
                    exercisesSection
                    
                    // Notes Section
                    if let notes = workout.notes, !notes.isEmpty {
                        notesSection(notes: notes)
                    }
                    
                    // Delete Button
                    deleteButton
                }
                .padding()
            }
        }
        .navigationTitle(workout.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showEditSheet = true
                } label: {
                    Text("Edit")
                        .foregroundColor(.gainsPrimary)
                }
            }
        }
        .sheet(isPresented: $showEditSheet) {
            EditWorkoutView(workout: workout, viewModel: viewModel) {
                // On save, dismiss back to list
                dismiss()
            }
        }
        .confirmationDialog(
            "Delete Workout",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                deleteWorkout()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure you want to delete this workout? This action cannot be undone.")
        }
    }
    
    // MARK: - Workout Info Card
    private var workoutInfoCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Date")
                        .font(.system(size: 13))
                        .foregroundColor(.gainsSecondaryText)
                    
                    Text(workout.date, style: .date)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.gainsText)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Exercises")
                        .font(.system(size: 13))
                        .foregroundColor(.gainsSecondaryText)
                    
                    Text("\(workout.exercises.count)")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.gainsText)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Total Sets")
                        .font(.system(size: 13))
                        .foregroundColor(.gainsSecondaryText)
                    
                    Text("\(totalSets)")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.gainsText)
                }
            }
        }
        .padding()
        .background(Color.gainsCardBackground)
        .cornerRadius(16)
    }
    
    private var totalSets: Int {
        workout.exercises.reduce(0) { $0 + $1.sets.count }
    }
    
    // MARK: - Exercises Section
    private var exercisesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Exercises")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.gainsText)
            
            if workout.exercises.isEmpty {
                Text("No exercises recorded")
                    .font(.system(size: 14))
                    .foregroundColor(.gainsSecondaryText)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.gainsCardBackground)
                    .cornerRadius(12)
            } else {
                ForEach(workout.exercises) { exercise in
                    ExerciseDetailCard(exercise: exercise)
                }
            }
        }
    }
    
    // MARK: - Notes Section
    private func notesSection(notes: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Notes")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.gainsText)
            
            Text(notes)
                .font(.system(size: 15))
                .foregroundColor(.gainsText)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.gainsCardBackground)
                .cornerRadius(12)
        }
    }
    
    // MARK: - Delete Button
    private var deleteButton: some View {
        Button {
            showDeleteConfirmation = true
        } label: {
            HStack {
                if isDeleting {
                    ProgressView()
                        .tint(.white)
                } else {
                    Image(systemName: "trash")
                    Text("Delete Workout")
                }
            }
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.gainsAccentRed)
            .cornerRadius(12)
        }
        .disabled(isDeleting)
        .padding(.top, 20)
    }
    
    private func deleteWorkout() {
        isDeleting = true
        Task {
            await viewModel.deleteWorkout(workout)
            isDeleting = false
            dismiss()
        }
    }
}

// MARK: - Exercise Detail Card
struct ExerciseDetailCard: View {
    let exercise: Exercise
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Exercise name
            Text(exercise.name)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.gainsText)
            
            if exercise.sets.isEmpty {
                Text("No sets recorded")
                    .font(.system(size: 13))
                    .foregroundColor(.gainsSecondaryText)
            } else {
                // Sets header
                HStack {
                    Text("Set")
                        .frame(width: 40, alignment: .leading)
                    Text("Weight")
                        .frame(maxWidth: .infinity)
                    Text("Reps")
                        .frame(width: 50)
                }
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.gainsSecondaryText)
                
                // Sets
                ForEach(Array(exercise.sets.enumerated()), id: \.offset) { index, set in
                    HStack {
                        Text("\(index + 1)")
                            .frame(width: 40, alignment: .leading)
                            .foregroundColor(.gainsSecondaryText)
                        
                        if let weight = set.weight {
                            Text("\(Int(weight)) lbs")
                                .frame(maxWidth: .infinity)
                        } else {
                            Text("-")
                                .frame(maxWidth: .infinity)
                                .foregroundColor(.gainsSecondaryText)
                        }
                        
                        if let reps = set.reps {
                            Text("\(reps)")
                                .frame(width: 50)
                        } else {
                            Text("-")
                                .frame(width: 50)
                                .foregroundColor(.gainsSecondaryText)
                        }
                    }
                    .font(.system(size: 14))
                    .foregroundColor(.gainsText)
                    .padding(.vertical, 4)
                    
                    if index < exercise.sets.count - 1 {
                        Divider()
                    }
                }
            }
        }
        .padding()
        .background(Color.gainsCardBackground)
        .cornerRadius(12)
    }
}

// MARK: - Edit Workout View
struct EditWorkoutView: View {
    @Environment(\.dismiss) var dismiss
    
    let workout: Workout
    @ObservedObject var viewModel: WorkoutViewModel
    let onSave: () -> Void
    
    @State private var editedName: String
    @State private var editedDate: Date
    @State private var editedNotes: String
    @State private var editedExercises: [Exercise]
    @State private var isSaving = false
    @State private var showAddExercise = false
    
    init(workout: Workout, viewModel: WorkoutViewModel, onSave: @escaping () -> Void) {
        self.workout = workout
        self.viewModel = viewModel
        self.onSave = onSave
        _editedName = State(initialValue: workout.name)
        _editedDate = State(initialValue: workout.date)
        _editedNotes = State(initialValue: workout.notes ?? "")
        _editedExercises = State(initialValue: workout.exercises)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.gainsBackground.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Workout Name
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Workout Name")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.gainsSecondaryText)
                            
                            TextField("e.g., Push Day", text: $editedName)
                                .textFieldStyle(.plain)
                                .font(.system(size: 16))
                                .padding()
                                .background(Color.gainsCardBackground)
                                .cornerRadius(12)
                                .foregroundColor(.gainsText)
                        }
                        
                        // Date
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Date")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.gainsSecondaryText)
                            
                            DatePicker("", selection: $editedDate, displayedComponents: .date)
                                .datePickerStyle(.compact)
                                .labelsHidden()
                                .padding()
                                .background(Color.gainsCardBackground)
                                .cornerRadius(12)
                        }
                        
                        // Exercises
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Exercises")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.gainsSecondaryText)
                                
                                Spacer()
                                
                                Button {
                                    showAddExercise = true
                                } label: {
                                    HStack(spacing: 4) {
                                        Image(systemName: "plus")
                                        Text("Add")
                                    }
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.gainsPrimary)
                                }
                            }
                            
                            if editedExercises.isEmpty {
                                Text("No exercises")
                                    .font(.system(size: 14))
                                    .foregroundColor(.gainsSecondaryText)
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(Color.gainsCardBackground)
                                    .cornerRadius(12)
                            } else {
                                ForEach(Array(editedExercises.enumerated()), id: \.element.id) { index, exercise in
                                    EditableExerciseCard(
                                        exercise: $editedExercises[index],
                                        onDelete: {
                                            editedExercises.remove(at: index)
                                        }
                                    )
                                }
                            }
                        }
                        
                        // Notes
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Notes")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.gainsSecondaryText)
                            
                            TextField("Add notes about your workout...", text: $editedNotes, axis: .vertical)
                                .textFieldStyle(.plain)
                                .font(.system(size: 16))
                                .lineLimit(3...6)
                                .padding()
                                .background(Color.gainsCardBackground)
                                .cornerRadius(12)
                                .foregroundColor(.gainsText)
                        }
                        
                        // Save Button
                        Button {
                            saveWorkout()
                        } label: {
                            if isSaving {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Text("Save Changes")
                            }
                        }
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(editedName.isEmpty ? Color.gray : Color.gainsPrimary)
                        .cornerRadius(12)
                        .disabled(editedName.isEmpty || isSaving)
                    }
                    .padding()
                }
            }
            .navigationTitle("Edit Workout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.gainsPrimary)
                }
            }
            .sheet(isPresented: $showAddExercise) {
                AddExerciseView { exercise in
                    editedExercises.append(exercise)
                }
            }
        }
    }
    
    private func saveWorkout() {
        isSaving = true
        
        var updatedWorkout = workout
        updatedWorkout.name = editedName
        updatedWorkout.date = editedDate
        updatedWorkout.notes = editedNotes.isEmpty ? nil : editedNotes
        updatedWorkout.exercises = editedExercises
        
        Task {
            await viewModel.updateWorkout(updatedWorkout)
            isSaving = false
            dismiss()
            onSave()
        }
    }
}

// MARK: - Editable Exercise Card
struct EditableExerciseCard: View {
    @Binding var exercise: Exercise
    let onDelete: () -> Void
    
    @State private var showDeleteConfirmation = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with delete button
            HStack {
                Text(exercise.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.gainsText)
                
                Spacer()
                
                Button {
                    showDeleteConfirmation = true
                } label: {
                    Image(systemName: "trash")
                        .font(.system(size: 14))
                        .foregroundColor(.gainsAccentRed)
                }
            }
            
            // Sets
            if exercise.sets.isEmpty {
                Text("No sets")
                    .font(.system(size: 13))
                    .foregroundColor(.gainsSecondaryText)
            } else {
                ForEach(Array(exercise.sets.enumerated()), id: \.offset) { setIndex, set in
                    HStack(spacing: 12) {
                        Text("Set \(setIndex + 1)")
                            .font(.system(size: 13))
                            .foregroundColor(.gainsSecondaryText)
                            .frame(width: 50, alignment: .leading)
                        
                        // Weight
                        HStack(spacing: 4) {
                            TextField("0", value: Binding(
                                get: { set.weight ?? 0 },
                                set: { exercise.sets[setIndex].weight = $0 }
                            ), format: .number)
                            .keyboardType(.decimalPad)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 60)
                            
                            Text("lbs")
                                .font(.system(size: 12))
                                .foregroundColor(.gainsSecondaryText)
                        }
                        
                        // Reps
                        HStack(spacing: 4) {
                            TextField("0", value: Binding(
                                get: { set.reps ?? 0 },
                                set: { exercise.sets[setIndex].reps = $0 }
                            ), format: .number)
                            .keyboardType(.numberPad)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 50)
                            
                            Text("reps")
                                .font(.system(size: 12))
                                .foregroundColor(.gainsSecondaryText)
                        }
                        
                        // Delete set
                        Button {
                            exercise.sets.remove(at: setIndex)
                        } label: {
                            Image(systemName: "minus.circle.fill")
                                .font(.system(size: 18))
                                .foregroundColor(.gainsAccentRed.opacity(0.7))
                        }
                    }
                }
            }
            
            // Add set button
            Button {
                let newSet = ExerciseSet(
                    reps: exercise.sets.last?.reps,
                    weight: exercise.sets.last?.weight
                )
                exercise.sets.append(newSet)
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "plus.circle.fill")
                    Text("Add Set")
                }
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.gainsPrimary)
            }
            .padding(.top, 4)
        }
        .padding()
        .background(Color.gainsCardBackground)
        .cornerRadius(12)
        .confirmationDialog(
            "Delete Exercise",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                onDelete()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure you want to remove this exercise?")
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
                    ExerciseSet(reps: 8, weight: 155, completed: true),
                    ExerciseSet(reps: 6, weight: 175, completed: true)
                ]),
                Exercise(name: "Overhead Press", sets: [
                    ExerciseSet(reps: 10, weight: 95, completed: true),
                    ExerciseSet(reps: 8, weight: 105, completed: true)
                ])
            ],
            notes: "Great workout today! Felt strong on bench."
        ))
    }
}
