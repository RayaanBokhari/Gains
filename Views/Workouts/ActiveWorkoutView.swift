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
    @State private var expandedExerciseId: UUID? = nil
    
    var body: some View {
        NavigationView {
            mainContent
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        cancelButton
                    }
                    
                    ToolbarItem(placement: .navigationBarTrailing) {
                        reorderButton
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
    
    // MARK: - Main Content
    private var mainContent: some View {
        ZStack {
            // Deep black background
            Color.gainsBgPrimary.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Custom Header
                workoutHeader
                
                // Content based on workout state
                workoutContent
                
                Spacer(minLength: 0)
                
                // Sticky Finish Button
                finishButton
            }
        }
    }
    
    // MARK: - Workout Content
    @ViewBuilder
    private var workoutContent: some View {
        if let workout = viewModel.currentWorkout, !workout.exercises.isEmpty {
            exerciseListView(workout: workout)
        } else {
            emptyState
        }
    }
    
    // MARK: - Exercise List View
    private func exerciseListView(workout: Workout) -> some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: GainsDesign.spacingL) {
                ForEach(Array(workout.exercises.enumerated()), id: \.element.id) { index, exercise in
                    exerciseCard(for: exercise, at: index)
                }
                
                // Add Exercise Button
                addExerciseButton
                
                // Notes Section
                notesSection
            }
            .padding(.horizontal, GainsDesign.paddingHorizontal)
            .padding(.top, GainsDesign.spacingL)
            .padding(.bottom, 120)
        }
    }
    
    // MARK: - Exercise Card Helper
    private func exerciseCard(for exercise: Exercise, at index: Int) -> some View {
        ExerciseCard(
            exercise: exercise,
            exerciseIndex: index,
            viewModel: viewModel,
            isReordering: isReorderingExercises,
            isExpanded: expandedBinding(for: exercise.id)
        )
    }
    
    // MARK: - Expanded Binding Helper
    private func expandedBinding(for exerciseId: UUID) -> Binding<Bool> {
        Binding(
            get: { expandedExerciseId == exerciseId },
            set: { newValue in
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    expandedExerciseId = newValue ? exerciseId : nil
                }
            }
        )
    }
    
    // MARK: - Cancel Button
    private var cancelButton: some View {
        Button {
            showDiscardAlert = true
        } label: {
            Text("Cancel")
                .font(.system(size: GainsDesign.body))
                .foregroundColor(.gainsError)
        }
    }
    
    // MARK: - Reorder Button
    @ViewBuilder
    private var reorderButton: some View {
        if let workout = viewModel.currentWorkout, workout.exercises.count > 1 {
            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    isReorderingExercises.toggle()
                }
            } label: {
                Text(isReorderingExercises ? "Done" : "Reorder")
                    .font(.system(size: GainsDesign.body))
                    .foregroundColor(.gainsPrimary)
            }
        }
    }
    
    // MARK: - Workout Header
    private var workoutHeader: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: GainsDesign.spacingXS) {
                Text(viewModel.currentWorkout?.name ?? "Workout")
                    .font(.system(size: GainsDesign.titleMedium, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                if let workout = viewModel.currentWorkout {
                    Text("\(workout.exercises.count) exercise\(workout.exercises.count == 1 ? "" : "s")")
                        .font(.system(size: GainsDesign.subheadline))
                        .foregroundColor(.gainsTextSecondary)
                }
            }
            
            Spacer()
            
            // Exercise count badge
            if let workout = viewModel.currentWorkout {
                ZStack {
                    Circle()
                        .fill(Color.gainsPrimary.opacity(0.15))
                        .frame(width: 56, height: 56)
                    
                    VStack(spacing: 0) {
                        Text("\(workout.exercises.count)")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.gainsPrimary)
                        Text("total")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.gainsTextSecondary)
                    }
                }
            }
        }
        .padding(.horizontal, GainsDesign.paddingHorizontal)
        .padding(.top, GainsDesign.spacingL)
        .padding(.bottom, GainsDesign.spacingM)
        .background(Color.gainsBgPrimary)
    }
    
    // MARK: - Empty State
    private var emptyState: some View {
        VStack(spacing: GainsDesign.spacingXXL) {
            Spacer()
            
            ZStack {
                Circle()
                    .fill(Color.gainsBgTertiary)
                    .frame(width: 96, height: 96)
                
                Image(systemName: "figure.strengthtraining.traditional")
                    .font(.system(size: 44, weight: .light))
                    .foregroundColor(.gainsTextTertiary)
            }
            
            VStack(spacing: GainsDesign.spacingS) {
                Text("No Exercises Yet")
                    .font(.system(size: GainsDesign.titleSmall, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                
                Text("Add exercises to start tracking\nyour workout")
                    .font(.system(size: GainsDesign.callout))
                    .foregroundColor(.gainsTextSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            
            Button {
                showAddExercise = true
            } label: {
                HStack(spacing: GainsDesign.spacingS) {
                    Image(systemName: "plus")
                        .font(.system(size: 14, weight: .semibold))
                    Text("Add First Exercise")
                        .font(.system(size: GainsDesign.body, weight: .semibold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 28)
                .frame(height: GainsDesign.buttonHeightLarge)
                .background(
                    RoundedRectangle(cornerRadius: GainsDesign.cornerRadiusMedium)
                        .fill(Color.gainsPrimary)
                )
                .shadow(color: Color.gainsPrimary.opacity(0.35), radius: 16, x: 0, y: 8)
            }
            
            Spacer()
            Spacer()
        }
        .padding(.horizontal, GainsDesign.paddingHorizontal)
    }
    
    // MARK: - Add Exercise Button
    private var addExerciseButton: some View {
        Button {
            showAddExercise = true
        } label: {
            HStack(spacing: GainsDesign.spacingS) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 20, weight: .medium))
                Text("Add Exercise")
                    .font(.system(size: GainsDesign.body, weight: .semibold))
            }
            .foregroundColor(.gainsPrimary)
            .frame(maxWidth: .infinity)
            .frame(height: GainsDesign.buttonHeightLarge)
            .background(
                RoundedRectangle(cornerRadius: GainsDesign.cornerRadiusLarge)
                    .fill(Color.gainsCardSurface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: GainsDesign.cornerRadiusLarge)
                    .stroke(Color.gainsPrimary.opacity(0.25), style: StrokeStyle(lineWidth: 1.5, dash: [8, 4]))
            )
        }
    }
    
    // MARK: - Notes Section
    private var notesSection: some View {
        VStack(alignment: .leading, spacing: GainsDesign.spacingM) {
            Text("Workout Notes")
                .font(.system(size: GainsDesign.subheadline, weight: .medium))
                .foregroundColor(.gainsTextSecondary)
            
            TextField("How did this workout feel?", text: $workoutNotes, axis: .vertical)
                .textFieldStyle(.plain)
                .font(.system(size: GainsDesign.body))
                .foregroundColor(.white)
                .lineLimit(2...4)
                .padding(GainsDesign.spacingL)
                .background(
                    RoundedRectangle(cornerRadius: GainsDesign.cornerRadiusMedium)
                        .fill(Color.gainsCardSurface)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: GainsDesign.cornerRadiusMedium)
                        .stroke(Color.white.opacity(0.04), lineWidth: 0.5)
                )
        }
    }
    
    // MARK: - Finish Button
    private var finishButton: some View {
        VStack(spacing: 0) {
            // Subtle gradient fade
            LinearGradient(
                colors: [Color.gainsBgPrimary.opacity(0), Color.gainsBgPrimary],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 20)
            
            Button {
                viewModel.currentWorkout?.notes = workoutNotes.isEmpty ? nil : workoutNotes
                Task {
                    await viewModel.endWorkout()
                    dismiss()
                }
            } label: {
                Text("Finish Workout")
                    .font(.system(size: GainsDesign.body, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: GainsDesign.buttonHeightLarge)
                    .background(
                        RoundedRectangle(cornerRadius: GainsDesign.cornerRadiusMedium)
                            .fill(
                                (viewModel.currentWorkout?.exercises.isEmpty ?? true)
                                ? Color.gainsTextMuted
                                : Color.gainsAccentGreenSoft
                            )
                    )
                    .shadow(
                        color: (viewModel.currentWorkout?.exercises.isEmpty ?? true) ? .clear : Color.gainsAccentGreen.opacity(0.35),
                        radius: 16,
                        x: 0,
                        y: 8
                    )
            }
            .disabled(viewModel.currentWorkout?.exercises.isEmpty ?? true)
            .padding(.horizontal, GainsDesign.paddingHorizontal)
            .padding(.bottom, GainsDesign.spacingXL)
            .background(Color.gainsBgPrimary)
        }
    }
}

// MARK: - Exercise Card (Collapsible Design)
struct ExerciseCard: View {
    let exercise: Exercise
    let exerciseIndex: Int
    @ObservedObject var viewModel: WorkoutViewModel
    let isReordering: Bool
    @Binding var isExpanded: Bool
    @State private var showDeleteAlert = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Exercise Header - Always Visible
            Button {
                if !isReordering {
                    isExpanded.toggle()
                }
            } label: {
                HStack(spacing: GainsDesign.spacingM) {
                    if isReordering {
                        Image(systemName: "line.horizontal.3")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.gainsTextMuted)
                    }
                    
                    VStack(alignment: .leading, spacing: GainsDesign.spacingXXS) {
                        Text(exercise.name)
                            .font(.system(size: GainsDesign.headline, weight: .semibold))
                            .foregroundColor(.white)
                        
                        Text("\(exercise.sets.count) set\(exercise.sets.count == 1 ? "" : "s")")
                            .font(.system(size: GainsDesign.footnote))
                            .foregroundColor(.gainsTextSecondary)
                    }
                    
                    Spacer()
                    
                    if !isReordering {
                        // Expand/Collapse indicator
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.gainsTextTertiary)
                        
                        // Menu
                        Menu {
                            Button(role: .destructive) {
                                showDeleteAlert = true
                            } label: {
                                Label("Remove Exercise", systemImage: "trash")
                            }
                        } label: {
                            Image(systemName: "ellipsis")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.gainsTextSecondary)
                                .frame(width: 32, height: 32)
                                .contentShape(Rectangle())
                        }
                    }
                }
                .padding(GainsDesign.spacingL)
            }
            .buttonStyle(.plain)
            
            // Collapsed View - Set Summary
            if !isExpanded && !exercise.sets.isEmpty {
                VStack(spacing: 0) {
                    Rectangle()
                        .fill(Color.gainsSeparator)
                        .frame(height: 0.5)
                    
                    VStack(spacing: GainsDesign.spacingXS) {
                        ForEach(Array(exercise.sets.enumerated()), id: \.element.id) { setIndex, set in
                            CollapsedSetRow(
                                setNumber: setIndex + 1,
                                weight: set.weight,
                                reps: set.reps,
                                isCompleted: (set.weight ?? 0) > 0 && (set.reps ?? 0) > 0
                            )
                        }
                    }
                    .padding(.horizontal, GainsDesign.spacingL)
                    .padding(.vertical, GainsDesign.spacingM)
                }
            }
            
            // Expanded View - Editable Sets
            if isExpanded {
                VStack(spacing: 0) {
                    Rectangle()
                        .fill(Color.gainsSeparator)
                        .frame(height: 0.5)
                    
                    // Sets Table Header
                    HStack(spacing: GainsDesign.spacingS) {
                        Text("SET")
                            .frame(width: 40, alignment: .leading)
                        Text("WEIGHT")
                            .frame(maxWidth: .infinity)
                        Text("REPS")
                            .frame(maxWidth: .infinity)
                        Text("✓")
                            .frame(width: 36)
                        Color.clear
                            .frame(width: 36)
                    }
                    .font(.system(size: GainsDesign.captionSmall, weight: .semibold))
                    .foregroundColor(.gainsTextTertiary)
                    .padding(.horizontal, GainsDesign.spacingL)
                    .padding(.vertical, GainsDesign.spacingM)
                    .background(Color.gainsBgTertiary.opacity(0.5))
                    
                    // Editable Sets
                    ForEach(Array(exercise.sets.enumerated()), id: \.element.id) { setIndex, set in
                        ExpandedSetRow(
                            set: set,
                            setNumber: setIndex + 1,
                            exerciseIndex: exerciseIndex,
                            setIndex: setIndex,
                            viewModel: viewModel,
                            canDelete: exercise.sets.count > 1
                        )
                        
                        if setIndex < exercise.sets.count - 1 {
                            Rectangle()
                                .fill(Color.gainsSeparator.opacity(0.5))
                                .frame(height: 0.5)
                                .padding(.leading, GainsDesign.spacingL)
                        }
                    }
                    
                    // Add Set Button
                    Button {
                        viewModel.addSet(to: exerciseIndex)
                    } label: {
                        HStack(spacing: GainsDesign.spacingS) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 16))
                            Text("Add Set")
                                .font(.system(size: GainsDesign.subheadline, weight: .semibold))
                        }
                        .foregroundColor(.gainsPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, GainsDesign.spacingM)
                    }
                    .background(Color.gainsBgTertiary.opacity(0.3))
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: GainsDesign.cornerRadiusLarge)
                .fill(Color.gainsCardSurface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: GainsDesign.cornerRadiusLarge)
                .stroke(Color.white.opacity(0.04), lineWidth: 0.5)
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

// MARK: - Collapsed Set Row
struct CollapsedSetRow: View {
    let setNumber: Int
    let weight: Double?
    let reps: Int?
    let isCompleted: Bool
    
    private var weightDisplay: String {
        guard let weight = weight, weight > 0 else { return "—" }
        return weight.truncatingRemainder(dividingBy: 1) == 0 
            ? String(format: "%.0f", weight) 
            : String(format: "%.1f", weight)
    }
    
    private var repsDisplay: String {
        guard let reps = reps, reps > 0 else { return "—" }
        return "\(reps)"
    }
    
    var body: some View {
        HStack(spacing: GainsDesign.spacingM) {
            Text("Set \(setNumber)")
                .font(.system(size: GainsDesign.footnote, weight: .medium))
                .foregroundColor(.gainsTextSecondary)
                .frame(width: 50, alignment: .leading)
            
            Text("—")
                .font(.system(size: GainsDesign.caption))
                .foregroundColor(.gainsTextMuted)
            
            HStack(spacing: GainsDesign.spacingXS) {
                Text(weightDisplay)
                    .font(.system(size: GainsDesign.footnote, weight: .medium))
                    .foregroundColor(isCompleted ? .white : .gainsTextTertiary)
                
                if weight != nil && weight! > 0 {
                    Text("lbs")
                        .font(.system(size: GainsDesign.captionSmall))
                        .foregroundColor(.gainsTextMuted)
                }
                
                Text("×")
                    .font(.system(size: GainsDesign.caption))
                    .foregroundColor(.gainsTextMuted)
                    .padding(.horizontal, 2)
                
                Text(repsDisplay)
                    .font(.system(size: GainsDesign.footnote, weight: .medium))
                    .foregroundColor(isCompleted ? .white : .gainsTextTertiary)
                
                if reps != nil && reps! > 0 {
                    Text("reps")
                        .font(.system(size: GainsDesign.captionSmall))
                        .foregroundColor(.gainsTextMuted)
                }
            }
            
            Spacer()
            
            // Completion indicator
            if isCompleted {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.gainsSuccess)
            } else {
                Circle()
                    .stroke(Color.gainsTextMuted, lineWidth: 1.5)
                    .frame(width: 16, height: 16)
            }
        }
        .padding(.vertical, GainsDesign.spacingXS)
    }
}

// MARK: - Expanded Set Row (Editable)
struct ExpandedSetRow: View {
    let set: ExerciseSet
    let setNumber: Int
    let exerciseIndex: Int
    let setIndex: Int
    @ObservedObject var viewModel: WorkoutViewModel
    let canDelete: Bool
    
    @State private var weightText: String = ""
    @State private var repsText: String = ""
    @State private var isCompleted: Bool = false
    
    var body: some View {
        HStack(spacing: GainsDesign.spacingS) {
            // Set Number
            Text("\(setNumber)")
                .font(.system(size: GainsDesign.subheadline, weight: .semibold))
                .foregroundColor(.gainsTextSecondary)
                .frame(width: 40, alignment: .leading)
            
            // Weight Input (Pill Style)
            TextField("0", text: $weightText)
                .keyboardType(.decimalPad)
                .font(.system(size: GainsDesign.body, weight: .medium))
                .multilineTextAlignment(.center)
                .foregroundColor(.white)
                .padding(.vertical, GainsDesign.spacingM)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: GainsDesign.cornerRadiusSmall)
                        .fill(Color.gainsBgTertiary)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: GainsDesign.cornerRadiusSmall)
                        .stroke(Color.gainsSeparator, lineWidth: 0.5)
                )
                .onChange(of: weightText) { _, newValue in
                    if let weight = Double(newValue) {
                        viewModel.updateSet(exerciseIndex: exerciseIndex, setIndex: setIndex, weight: weight, reps: nil)
                        updateCompletionState()
                    }
                }
            
            // Reps Input (Pill Style)
            TextField("0", text: $repsText)
                .keyboardType(.numberPad)
                .font(.system(size: GainsDesign.body, weight: .medium))
                .multilineTextAlignment(.center)
                .foregroundColor(.white)
                .padding(.vertical, GainsDesign.spacingM)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: GainsDesign.cornerRadiusSmall)
                        .fill(Color.gainsBgTertiary)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: GainsDesign.cornerRadiusSmall)
                        .stroke(Color.gainsSeparator, lineWidth: 0.5)
                )
                .onChange(of: repsText) { _, newValue in
                    if let reps = Int(newValue) {
                        viewModel.updateSet(exerciseIndex: exerciseIndex, setIndex: setIndex, weight: nil, reps: reps)
                        updateCompletionState()
                    }
                }
            
            // Completion Toggle
            Button {
                withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                    isCompleted.toggle()
                }
            } label: {
                ZStack {
                    if isCompleted {
                        Circle()
                            .fill(Color.gainsSuccess)
                            .frame(width: 28, height: 28)
                        
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                    } else {
                        Circle()
                            .stroke(Color.gainsTextMuted, lineWidth: 2)
                            .frame(width: 28, height: 28)
                    }
                }
            }
            .frame(width: 36)
            
            // Delete Button
            if canDelete {
                Button {
                    withAnimation(.easeOut(duration: 0.2)) {
                        viewModel.removeSet(exerciseIndex: exerciseIndex, setIndex: setIndex)
                    }
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(.gainsError.opacity(0.8))
                }
                .frame(width: 36)
            } else {
                Color.clear.frame(width: 36)
            }
        }
        .padding(.horizontal, GainsDesign.spacingL)
        .padding(.vertical, GainsDesign.spacingM)
        .onAppear {
            loadSetData()
        }
    }
    
    private func loadSetData() {
        if let weight = set.weight {
            weightText = weight.truncatingRemainder(dividingBy: 1) == 0 
                ? String(format: "%.0f", weight) 
                : String(format: "%.1f", weight)
        }
        if let reps = set.reps {
            repsText = String(reps)
        }
        updateCompletionState()
    }
    
    private func updateCompletionState() {
        let hasWeight = (Double(weightText) ?? 0) > 0
        let hasReps = (Int(repsText) ?? 0) > 0
        isCompleted = hasWeight && hasReps
    }
}

#Preview {
    ActiveWorkoutView(viewModel: WorkoutViewModel())
}

