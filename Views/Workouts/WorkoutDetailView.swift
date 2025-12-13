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
        VStack(spacing: 16) {
            // Top row - Date and Duration
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Date")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.gainsSecondaryText)
                    
                    Text(workout.date, style: .date)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.gainsText)
                }
                
                Spacer()
                
                // Duration badge (if available)
                if let formattedDuration = workout.formattedDuration {
                    HStack(spacing: 6) {
                        Image(systemName: "clock.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.gainsPrimary)
                        
                        Text(formattedDuration)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.gainsText)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.gainsPrimary.opacity(0.15))
                    .cornerRadius(8)
                }
            }
            
            Divider()
                .background(Color.white.opacity(0.1))
            
            // Stats row
            HStack(spacing: 0) {
                // Exercises
                statItem(value: "\(workout.exercises.count)", label: "Exercises", icon: "figure.strengthtraining.traditional")
                
                Divider()
                    .frame(height: 40)
                    .background(Color.white.opacity(0.1))
                
                // Total Sets
                statItem(value: "\(totalSets)", label: "Sets", icon: "number")
                
                Divider()
                    .frame(height: 40)
                    .background(Color.white.opacity(0.1))
                
                // Total Volume
                statItem(value: formatVolume(totalVolume), label: "Volume", icon: "scalemass.fill")
            }
        }
        .padding()
        .background(Color.gainsCardBackground)
        .cornerRadius(16)
    }
    
    private func statItem(value: String, label: String, icon: String) -> some View {
        VStack(spacing: 6) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 10))
                    .foregroundColor(.gainsPrimary)
                Text(value)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.gainsText)
            }
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(.gainsSecondaryText)
        }
        .frame(maxWidth: .infinity)
    }
    
    private var totalVolume: Double {
        workout.exercises.reduce(0) { total, exercise in
            total + exercise.sets.reduce(0) { setTotal, set in
                setTotal + ((set.weight ?? 0) * Double(set.reps ?? 0))
            }
        }
    }
    
    private func formatVolume(_ volume: Double) -> String {
        if volume >= 1000 {
            return String(format: "%.1fk", volume / 1000)
        }
        return "\(Int(volume))"
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

// MARK: - Edit Workout View (Modern Liquid Glass Style)
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
    @FocusState private var isNameFocused: Bool
    @FocusState private var isNotesFocused: Bool
    
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
                Color.gainsAppBackground.ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        headerCard
                        exercisesSection
                        notesSection
                        Spacer(minLength: 80)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                }
                
                floatingSaveButton
            }
            .navigationTitle("Edit Workout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Text("Cancel")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.gainsAccentRed)
                    }
                }
            }
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        isNameFocused = false
                        isNotesFocused = false
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.gainsPrimary)
                }
            }
            .sheet(isPresented: $showAddExercise) {
                AddExerciseView { exercise in
                    withAnimation(.spring(response: 0.3)) {
                        editedExercises.append(exercise)
                    }
                }
            }
        }
    }
    
    // MARK: - Header Card
    private var headerCard: some View {
        VStack(spacing: 16) {
            // Workout Name
            VStack(alignment: .leading, spacing: 6) {
                Text("WORKOUT NAME")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.gainsTextTertiary)
                    .tracking(0.5)
                
                TextField("e.g., Push Day", text: $editedName)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .focused($isNameFocused)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 14)
                    .background(Color.white.opacity(0.06))
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(isNameFocused ? Color.gainsPrimary : Color.white.opacity(0.08), lineWidth: 1)
                    )
            }
            
            // Date picker row
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("DATE")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.gainsTextTertiary)
                        .tracking(0.5)
                    
                    DatePicker("", selection: $editedDate, displayedComponents: .date)
                        .datePickerStyle(.compact)
                        .labelsHidden()
                        .tint(.gainsPrimary)
                }
                
                Spacer()
                
                // Duration display (if exists)
                if let duration = workout.formattedDuration {
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("DURATION")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.gainsTextTertiary)
                            .tracking(0.5)
                        
                        HStack(spacing: 4) {
                            Image(systemName: "clock.fill")
                                .font(.system(size: 12))
                                .foregroundColor(.gainsPrimary)
                            Text(duration)
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.white)
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(Color.gainsCardSurface)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.06), lineWidth: 1)
        )
    }
    
    // MARK: - Exercises Section
    private var exercisesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("EXERCISES")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.gainsTextTertiary)
                    .tracking(0.5)
                
                Spacer()
                
                Button {
                    showAddExercise = true
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "plus")
                            .font(.system(size: 12, weight: .bold))
                        Text("Add")
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .foregroundColor(.gainsPrimary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.gainsPrimary.opacity(0.15))
                    .cornerRadius(8)
                }
            }
            .padding(.horizontal, 4)
            
            if editedExercises.isEmpty {
                emptyExercisesView
            } else {
                exercisesList
            }
        }
    }
    
    private var emptyExercisesView: some View {
        VStack(spacing: 12) {
            Image(systemName: "dumbbell")
                .font(.system(size: 28))
                .foregroundColor(.gainsTextMuted)
            
            Text("No exercises yet")
                .font(.system(size: 14))
                .foregroundColor(.gainsTextSecondary)
            
            Button {
                showAddExercise = true
            } label: {
                Text("Add your first exercise")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.gainsPrimary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .background(Color.gainsCardSurface)
        .cornerRadius(16)
    }
    
    private var exercisesList: some View {
        VStack(spacing: 12) {
            ForEach(editedExercises.indices, id: \.self) { index in
                EditableExerciseCard(
                    exercise: $editedExercises[index],
                    onDelete: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            _ = editedExercises.remove(at: index)
                        }
                    }
                )
            }
        }
    }
    
    // MARK: - Notes Section
    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("NOTES")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.gainsTextTertiary)
                .tracking(0.5)
                .padding(.horizontal, 4)
            
            TextField("Add notes about your workout...", text: $editedNotes, axis: .vertical)
                .font(.system(size: 15))
                .foregroundColor(.white)
                .lineLimit(3...8)
                .focused($isNotesFocused)
                .padding(14)
                .background(Color.gainsCardSurface)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isNotesFocused ? Color.gainsPrimary : Color.white.opacity(0.06), lineWidth: 1)
                )
        }
    }
    
    // MARK: - Floating Save Button
    private var floatingSaveButton: some View {
        VStack {
            Spacer()
            
            ZStack(alignment: .bottom) {
                // Fade gradient background
                VStack {
                    Spacer()
                    Color.gainsAppBackground
                        .frame(height: 80)
                        .mask(
                            LinearGradient(
                                colors: [Color.black.opacity(0), Color.black],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                }
                .allowsHitTesting(false)
                
                // Save button
                Button {
                    saveWorkout()
                } label: {
                    HStack(spacing: 8) {
                        if isSaving {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 18))
                            Text("Save Changes")
                                .font(.system(size: 16, weight: .bold))
                        }
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(editedName.isEmpty ? AnyShapeStyle(Color.gray.opacity(0.5)) : AnyShapeStyle(LinearGradient(colors: [Color.gainsPrimary, Color.gainsAccentBlue], startPoint: .leading, endPoint: .trailing)))
                    )
                    .shadow(color: editedName.isEmpty ? Color.clear : Color.gainsPrimary.opacity(0.3), radius: 12, y: 4)
                }
                .disabled(editedName.isEmpty || isSaving)
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
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

// MARK: - Editable Exercise Card (Modern Style)
struct EditableExerciseCard: View {
    @Binding var exercise: Exercise
    let onDelete: () -> Void
    
    @State private var showDeleteConfirmation = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header with exercise name and delete
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(exercise.name)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.gainsText)
                    
                    Text("\(exercise.sets.count) sets")
                        .font(.system(size: 12))
                        .foregroundColor(.gainsSecondaryText)
                }
                
                Spacer()
                
                Button {
                    showDeleteConfirmation = true
                } label: {
                    Image(systemName: "trash")
                        .font(.system(size: 14))
                        .foregroundColor(.gainsAccentRed)
                        .padding(8)
                        .background(Color.gainsAccentRed.opacity(0.1))
                        .cornerRadius(8)
                }
            }
            
            // Sets
            if exercise.sets.isEmpty {
                Text("No sets recorded")
                    .font(.system(size: 13))
                    .foregroundColor(.gainsSecondaryText)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 12)
            } else {
                VStack(spacing: 8) {
                    ForEach(exercise.sets.indices, id: \.self) { setIndex in
                        EditableSetRow(
                            setNumber: setIndex + 1,
                            weight: Binding(
                                get: { exercise.sets[setIndex].weight ?? 0 },
                                set: { exercise.sets[setIndex].weight = $0 }
                            ),
                            reps: Binding(
                                get: { exercise.sets[setIndex].reps ?? 0 },
                                set: { exercise.sets[setIndex].reps = $0 }
                            ),
                            onDelete: {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    _ = exercise.sets.remove(at: setIndex)
                                }
                            }
                        )
                    }
                }
            }
            
            // Add set button
            Button {
                withAnimation(.spring(response: 0.3)) {
                    let newSet = ExerciseSet(
                        reps: exercise.sets.last?.reps,
                        weight: exercise.sets.last?.weight
                    )
                    exercise.sets.append(newSet)
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 16))
                    Text("Add Set")
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundColor(.gainsPrimary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.gainsPrimary.opacity(0.1))
                .cornerRadius(10)
            }
        }
        .padding(16)
        .background(Color.gainsCardBackground)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(white: 1, opacity: 0.06), lineWidth: 1)
        )
        .confirmationDialog(
            "Delete Exercise",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                withAnimation { onDelete() }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure you want to remove this exercise?")
        }
    }
}

// MARK: - Editable Set Row (Modern Tappable Input)
struct EditableSetRow: View {
    let setNumber: Int
    @Binding var weight: Double
    @Binding var reps: Int
    let onDelete: () -> Void
    
    @State private var weightText: String = ""
    @State private var repsText: String = ""
    @FocusState private var focusedField: Field?
    
    enum Field {
        case weight, reps
    }
    
    var body: some View {
        HStack(spacing: 10) {
            // Set number badge
            Text("\(setNumber)")
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundColor(.gainsSecondaryText)
                .frame(width: 24, height: 24)
                .background(Color.white.opacity(0.08))
                .cornerRadius(6)
            
            // Weight input
            HStack(spacing: 4) {
                TextField("0", text: $weightText)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(.gainsText)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.center)
                    .focused($focusedField, equals: .weight)
                    .frame(width: 50)
                    .onChange(of: weightText) { _, newValue in
                        if let value = Double(newValue) {
                            weight = value
                        }
                    }
                
                Text("lbs")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.gainsSecondaryText)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(Color.white.opacity(focusedField == .weight ? 0.12 : 0.06))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(focusedField == .weight ? Color.gainsPrimary : Color.clear, lineWidth: 1.5)
            )
            
            Text("×")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.gainsSecondaryText)
            
            // Reps input
            HStack(spacing: 4) {
                TextField("0", text: $repsText)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(.gainsText)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.center)
                    .focused($focusedField, equals: .reps)
                    .frame(width: 36)
                    .onChange(of: repsText) { _, newValue in
                        if let value = Int(newValue) {
                            reps = value
                        }
                    }
                
                Text("reps")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.gainsSecondaryText)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(Color.white.opacity(focusedField == .reps ? 0.12 : 0.06))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(focusedField == .reps ? Color.gainsAccentBlue : Color.clear, lineWidth: 1.5)
            )
            
            Spacer()
            
            // Delete button
            Button {
                onDelete()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.gainsSecondaryText)
                    .padding(6)
                    .background(Color.white.opacity(0.08))
                    .cornerRadius(6)
            }
        }
        .padding(.vertical, 4)
        .onAppear {
            weightText = weight > 0 ? (weight == floor(weight) ? String(format: "%.0f", weight) : String(format: "%.1f", weight)) : ""
            repsText = reps > 0 ? "\(reps)" : ""
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
