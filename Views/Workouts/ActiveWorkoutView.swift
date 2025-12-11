//
//  ActiveWorkoutView.swift
//  Gains
//
//  Created by Rayaan Bokhari on 11/20/25.
//

import SwiftUI
import Combine

struct ActiveWorkoutView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: WorkoutViewModel
    @State private var showAddExercise = false
    @State private var showDiscardAlert = false
    @State private var workoutNotes = ""
    @State private var isReorderingExercises = false
    @State private var collapsedExerciseIds: Set<UUID> = [] // Track collapsed exercises (expanded by default)
    @State private var workoutStartTime = Date()
    @State private var previousExerciseCount = 0
    
    var body: some View {
        NavigationView {
            mainContent
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        cancelButton
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
        .onAppear {
            workoutStartTime = Date()
        }
    }
    
    // MARK: - Main Content
    private var mainContent: some View {
        ZStack {
            // App background gradient
            Color.gainsAppBackground.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Workout Header Card
                workoutHeaderCard
                
                // Content based on workout state
                workoutContent
                
                Spacer(minLength: 0)
                
                // Sticky Finish Button
                finishButtonSection
            }
        }
    }
    
    // MARK: - Workout Content
    @ViewBuilder
    private var workoutContent: some View {
        if let workout = viewModel.currentWorkout, !workout.exercises.isEmpty {
            exerciseListView(workout: workout)
        } else {
            emptyStateCard
        }
    }
    
    // MARK: - Exercise List View
    private func exerciseListView(workout: Workout) -> some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: GainsDesign.spacingL) {
                ForEach(Array(workout.exercises.enumerated()), id: \.element.id) { index, exercise in
                    PremiumExerciseCard(
                        exercise: exercise,
                        exerciseIndex: index,
                        viewModel: viewModel,
                        isReordering: isReorderingExercises,
                        isExpanded: expandedBinding(for: exercise.id)
                    )
                }
                
                // Add Exercise Button
                addExerciseButtonCompact
                
                // Notes Section
                notesSection
            }
            .padding(.horizontal, GainsDesign.paddingHorizontal)
            .padding(.top, GainsDesign.spacingL)
            .padding(.bottom, 140)
        }
        .onChange(of: workout.exercises.count) { oldCount, newCount in
            // Auto-expand newly added exercise
            if newCount > oldCount, let newExercise = workout.exercises.last {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    collapsedExerciseIds.remove(newExercise.id)
                }
            }
        }
    }
    
    // MARK: - Expanded Binding Helper (Inverted logic - expanded by default)
    private func expandedBinding(for exerciseId: UUID) -> Binding<Bool> {
        Binding(
            get: { !collapsedExerciseIds.contains(exerciseId) }, // Expanded if NOT in collapsed set
            set: { isExpanded in
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    if isExpanded {
                        collapsedExerciseIds.remove(exerciseId)
                    } else {
                        collapsedExerciseIds.insert(exerciseId)
                    }
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
                .font(.system(size: GainsDesign.subheadline, weight: .medium))
                .foregroundColor(.gainsAccentRed)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(Color.gainsAccentRed.opacity(0.12))
                )
        }
    }
    
    // MARK: - Workout Header Card (Glass)
    private var workoutHeaderCard: some View {
        VStack(spacing: 0) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(viewModel.currentWorkout?.name ?? "Workout")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    HStack(spacing: 12) {
                        if let workout = viewModel.currentWorkout {
                            // Exercise count
                            HStack(spacing: 4) {
                                Image(systemName: "dumbbell.fill")
                                    .font(.system(size: 11))
                                    .foregroundColor(.gainsPrimary)
                                Text("\(workout.exercises.count) exercise\(workout.exercises.count == 1 ? "" : "s")")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(.gainsTextSecondary)
                            }
                            
                            // Duration
                            HStack(spacing: 4) {
                                Image(systemName: "clock.fill")
                                    .font(.system(size: 11))
                                    .foregroundColor(.gainsAccentOrange)
                                WorkoutTimer(startTime: workoutStartTime)
                            }
                        }
                    }
                }
                
                Spacer()
                
                // Total sets badge
                if let workout = viewModel.currentWorkout {
                    let totalSets = workout.exercises.reduce(0) { $0 + $1.sets.count }
                    
                    VStack(spacing: 2) {
                        Text("\(totalSets)")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color.gainsPrimary, Color.gainsAccentBlue],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        Text("sets")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.gainsTextTertiary)
                    }
                    .frame(width: 56, height: 56)
                    .background(
                        Circle()
                            .fill(Color.gainsPrimary.opacity(0.1))
                    )
                    .overlay(
                        Circle()
                            .stroke(Color.gainsPrimary.opacity(0.2), lineWidth: 1)
                    )
                }
            }
            .padding(.horizontal, GainsDesign.paddingHorizontal)
            .padding(.vertical, GainsDesign.spacingL)
        }
        .background(
            Rectangle()
                .fill(Color(hex: "0A0B0E").opacity(0.8))
                .background(.ultraThinMaterial)
                .environment(\.colorScheme, .dark)
        )
        .overlay(
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [Color.white.opacity(0.05), Color.clear],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
        )
    }
    
    // MARK: - Empty State Card
    private var emptyStateCard: some View {
        VStack(spacing: 0) {
            Spacer()
            
            VStack(spacing: GainsDesign.spacingXXL) {
                // Icon in glass circle
                ZStack {
                    Circle()
                        .fill(.ultraThinMaterial)
                        .environment(\.colorScheme, .dark)
                        .frame(width: 100, height: 100)
                    
                    Circle()
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        .frame(width: 100, height: 100)
                    
                    Image(systemName: "figure.strengthtraining.traditional")
                        .font(.system(size: 44, weight: .light))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.gainsTextSecondary, Color.gainsTextTertiary],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                }
                
                VStack(spacing: GainsDesign.spacingS) {
                    Text("No Exercises Yet")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text("Add exercises to start tracking\nyour workout")
                        .font(.system(size: 15))
                        .foregroundColor(.gainsTextSecondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                }
                
                // Primary add button with glow
                Button {
                    showAddExercise = true
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "plus")
                            .font(.system(size: 16, weight: .semibold))
                        Text("Add First Exercise")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 32)
                    .frame(height: 54)
                    .background(
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [Color.gainsPrimary, Color.gainsAccentBlue],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    )
                    .shadow(color: Color.gainsPrimary.opacity(0.5), radius: 20, x: 0, y: 10)
                }
            }
            .padding(GainsDesign.spacingXXL)
            .background(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .environment(\.colorScheme, .dark)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )
            .padding(.horizontal, GainsDesign.paddingHorizontal)
            
            Spacer()
            Spacer()
        }
    }
    
    // MARK: - Add Exercise Button (Compact)
    private var addExerciseButtonCompact: some View {
        Button {
            showAddExercise = true
        } label: {
            HStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(Color.gainsPrimary.opacity(0.15))
                        .frame(width: 28, height: 28)
                    
                    Image(systemName: "plus")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.gainsPrimary)
                }
                
                Text("Add Exercise")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.gainsPrimary)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.gainsCardSurface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.gainsPrimary.opacity(0.2), lineWidth: 1)
            )
        }
    }
    
    // MARK: - Notes Section
    private var notesSection: some View {
        VStack(alignment: .leading, spacing: GainsDesign.spacingM) {
            HStack(spacing: 8) {
                Image(systemName: "pencil.line")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.gainsTextTertiary)
                
                Text("Workout Notes")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.gainsTextSecondary)
            }
            
            TextField("How did this workout feel?", text: $workoutNotes, axis: .vertical)
                .textFieldStyle(.plain)
                .font(.system(size: 15))
                .foregroundColor(.white)
                .lineLimit(2...4)
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(.ultraThinMaterial)
                        .environment(\.colorScheme, .dark)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
        }
    }
    
    // MARK: - Finish Button Section
    private var finishButtonSection: some View {
        let hasExercises = !(viewModel.currentWorkout?.exercises.isEmpty ?? true)
        
        return VStack(spacing: 0) {
            // Gradient fade
            LinearGradient(
                colors: [Color(hex: "0A0B0E").opacity(0), Color(hex: "0A0B0E")],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 24)
            
            Button {
                viewModel.currentWorkout?.notes = workoutNotes.isEmpty ? nil : workoutNotes
                Task {
                    await viewModel.endWorkout()
                    dismiss()
                }
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 18, weight: .semibold))
                    
                    Text("Complete Workout")
                        .font(.system(size: 17, weight: .bold))
                }
                .foregroundColor(hasExercises ? .white : .gainsTextTertiary)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    Group {
                        if hasExercises {
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [Color(hex: "30D158"), Color(hex: "34C759")],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                        } else {
                            Capsule()
                                .fill(Color.gainsCardSurface)
                        }
                    }
                )
                .shadow(
                    color: hasExercises ? Color.gainsAccentGreen.opacity(0.4) : .clear,
                    radius: 20,
                    x: 0,
                    y: 10
                )
            }
            .disabled(!hasExercises)
            .padding(.horizontal, GainsDesign.paddingHorizontal)
            .padding(.bottom, 34)
            .background(Color(hex: "0A0B0E"))
        }
    }
}

// MARK: - Workout Timer
struct WorkoutTimer: View {
    let startTime: Date
    @State private var elapsed: TimeInterval = 0
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        Text(formatTime(elapsed))
            .font(.system(size: 13, weight: .medium, design: .monospaced))
            .foregroundColor(.gainsTextSecondary)
            .onReceive(timer) { _ in
                elapsed = Date().timeIntervalSince(startTime)
            }
    }
    
    private func formatTime(_ interval: TimeInterval) -> String {
        let minutes = Int(interval) / 60
        let seconds = Int(interval) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - Premium Exercise Card
struct PremiumExerciseCard: View {
    let exercise: Exercise
    let exerciseIndex: Int
    @ObservedObject var viewModel: WorkoutViewModel
    let isReordering: Bool
    @Binding var isExpanded: Bool
    @State private var showDeleteAlert = false
    
    private var completedSets: Int {
        exercise.sets.filter { ($0.weight ?? 0) > 0 && ($0.reps ?? 0) > 0 }.count
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Exercise Header
            cardHeader
            
            // Content based on state
            if isExpanded {
                expandedContent
            } else if !exercise.sets.isEmpty {
                collapsedSummary
            }
        }
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(cardBorder)
        .shadow(color: isExpanded ? Color.gainsPrimary.opacity(0.1) : .clear, radius: 20, x: 0, y: 8)
        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: isExpanded)
        .alert("Remove \(exercise.name)?", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Remove", role: .destructive) {
                viewModel.removeExercise(at: exerciseIndex)
            }
        } message: {
            Text("This will delete all \(exercise.sets.count) set\(exercise.sets.count == 1 ? "" : "s") and cannot be undone.")
        }
    }
    
    // MARK: - Card Header
    private var cardHeader: some View {
        HStack(spacing: 12) {
            if isReordering {
                Image(systemName: "line.horizontal.3")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.gainsTextMuted)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(exercise.name)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
                
                HStack(spacing: 6) {
                    Text("\(exercise.sets.count) set\(exercise.sets.count == 1 ? "" : "s")")
                        .font(.system(size: 13))
                        .foregroundColor(.gainsTextSecondary)
                    
                    if completedSets > 0 {
                        Text("•")
                            .font(.system(size: 8))
                            .foregroundColor(.gainsTextMuted)
                        
                        HStack(spacing: 3) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 10))
                                .foregroundColor(.gainsSuccess)
                            Text("\(completedSets) done")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.gainsSuccess)
                        }
                    }
                }
            }
            
            Spacer()
            
            if !isReordering {
                // Collapse/Expand toggle button
                Button {
                    isExpanded.toggle()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .foregroundColor(.gainsTextTertiary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(Color.white.opacity(0.05))
                    )
                }
                
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
        .padding(16)
    }
    
    // MARK: - Collapsed Summary
    private var collapsedSummary: some View {
        VStack(spacing: 0) {
            Divider()
                .background(Color.white.opacity(0.06))
            
            VStack(spacing: 6) {
                ForEach(Array(exercise.sets.enumerated()), id: \.element.id) { setIndex, set in
                    CollapsedSetPill(
                        setNumber: setIndex + 1,
                        weight: set.weight,
                        reps: set.reps
                    )
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
    }
    
    // MARK: - Expanded Content
    private var expandedContent: some View {
        VStack(spacing: 0) {
            Divider()
                .background(Color.white.opacity(0.06))
            
            // Sets
            VStack(spacing: 8) {
                ForEach(Array(exercise.sets.enumerated()), id: \.element.id) { setIndex, set in
                    PremiumSetRow(
                        set: set,
                        setNumber: setIndex + 1,
                        exerciseIndex: exerciseIndex,
                        setIndex: setIndex,
                        viewModel: viewModel,
                        canDelete: exercise.sets.count > 1
                    )
                }
            }
            .padding(16)
            
            Divider()
                .background(Color.white.opacity(0.06))
            
            // Add Set Button
            Button {
                viewModel.addSet(to: exerciseIndex)
            } label: {
                HStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(Color.gainsPrimary.opacity(0.15))
                            .frame(width: 24, height: 24)
                        
                        Image(systemName: "plus")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.gainsPrimary)
                    }
                    
                    Text("Add Set")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.gainsPrimary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
            }
        }
    }
    
    // MARK: - Card Background
    private var cardBackground: some View {
        ZStack {
            Rectangle()
                .fill(.ultraThinMaterial)
                .environment(\.colorScheme, .dark)
            
            Rectangle()
                .fill(Color.black.opacity(0.3))
            
            // Subtle gradient when expanded
            if isExpanded {
                LinearGradient(
                    colors: [Color.gainsPrimary.opacity(0.05), Color.clear],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
        }
    }
    
    private var cardBorder: some View {
        RoundedRectangle(cornerRadius: 20, style: .continuous)
            .stroke(
                isExpanded
                    ? Color.gainsPrimary.opacity(0.2)
                    : Color.white.opacity(0.08),
                lineWidth: 1
            )
    }
}

// MARK: - Collapsed Set Pill
struct CollapsedSetPill: View {
    let setNumber: Int
    let weight: Double?
    let reps: Int?
    
    private var isComplete: Bool {
        (weight ?? 0) > 0 && (reps ?? 0) > 0
    }
    
    private var weightStr: String {
        guard let w = weight, w > 0 else { return "—" }
        return w.truncatingRemainder(dividingBy: 1) == 0 ? "\(Int(w))" : String(format: "%.1f", w)
    }
    
    private var repsStr: String {
        guard let r = reps, r > 0 else { return "—" }
        return "\(r)"
    }
    
    var body: some View {
        HStack(spacing: 8) {
            // Set number pill
            Text("\(setNumber)")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(isComplete ? .white : .gainsTextSecondary)
                .frame(width: 24, height: 24)
                .background(
                    Circle()
                        .fill(isComplete ? Color.gainsPrimary : Color.gainsCardElevated)
                )
            
            // Weight × Reps
            Text("\(weightStr) lb × \(repsStr)")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(isComplete ? .white : .gainsTextTertiary)
            
            Spacer()
            
            // Completion indicator
            if isComplete {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.gainsSuccess)
            } else {
                Circle()
                    .stroke(Color.gainsTextMuted, lineWidth: 1.5)
                    .frame(width: 14, height: 14)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.white.opacity(isComplete ? 0.05 : 0.02))
        )
    }
}

// MARK: - Premium Set Row
struct PremiumSetRow: View {
    let set: ExerciseSet
    let setNumber: Int
    let exerciseIndex: Int
    let setIndex: Int
    @ObservedObject var viewModel: WorkoutViewModel
    let canDelete: Bool
    
    @State private var weightText: String = ""
    @State private var repsText: String = ""
    @State private var isCompleted: Bool = false
    @FocusState private var focusedField: Field?
    
    enum Field {
        case weight, reps
    }
    
    var body: some View {
        HStack(spacing: 10) {
            // Set number badge
            Text("\(setNumber)")
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 32, height: 32)
                .background(
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.gainsPrimary, Color.gainsAccentBlue],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
                .shadow(color: Color.gainsPrimary.opacity(0.3), radius: 4, x: 0, y: 2)
            
            // Weight input
            inputPill(
                value: $weightText,
                placeholder: "0",
                unit: "lb",
                isFocused: focusedField == .weight,
                field: .weight
            )
            
            Text("×")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.gainsTextMuted)
            
            // Reps input
            inputPill(
                value: $repsText,
                placeholder: "0",
                unit: "reps",
                isFocused: focusedField == .reps,
                field: .reps
            )
            
            // Completion toggle
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                    isCompleted.toggle()
                }
                // Haptic feedback
                let impactMed = UIImpactFeedbackGenerator(style: .medium)
                impactMed.impactOccurred()
            } label: {
                ZStack {
                    if isCompleted {
                        Circle()
                            .fill(Color.gainsSuccess)
                            .frame(width: 32, height: 32)
                        
                        Image(systemName: "checkmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                    } else {
                        Circle()
                            .stroke(Color.gainsTextMuted, lineWidth: 2)
                            .frame(width: 32, height: 32)
                    }
                }
                .scaleEffect(isCompleted ? 1.1 : 1.0)
            }
            
            // Delete button
            if canDelete {
                Button {
                    withAnimation(.easeOut(duration: 0.2)) {
                        viewModel.removeSet(exerciseIndex: exerciseIndex, setIndex: setIndex)
                    }
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(.gainsAccentRed.opacity(0.7))
                }
            }
        }
        .onAppear {
            loadSetData()
        }
    }
    
    // MARK: - Input Pill
    @ViewBuilder
    private func inputPill(value: Binding<String>, placeholder: String, unit: String, isFocused: Bool, field: Field) -> some View {
        HStack(spacing: 4) {
            TextField(placeholder, text: value)
                .keyboardType(field == .weight ? .decimalPad : .numberPad)
                .font(.system(size: 17, weight: .semibold))
                .multilineTextAlignment(.center)
                .foregroundColor(.white)
                .frame(width: 44)
                .focused($focusedField, equals: field)
                .onChange(of: value.wrappedValue) { _, newValue in
                    if field == .weight {
                        if let weight = Double(newValue) {
                            viewModel.updateSet(exerciseIndex: exerciseIndex, setIndex: setIndex, weight: weight, reps: nil)
                        }
                    } else {
                        if let reps = Int(newValue) {
                            viewModel.updateSet(exerciseIndex: exerciseIndex, setIndex: setIndex, weight: nil, reps: reps)
                        }
                    }
                    updateCompletionState()
                }
            
            Text(unit)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.gainsTextTertiary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(isFocused ? Color.gainsPrimary.opacity(0.1) : Color.white.opacity(0.05))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(
                    isFocused ? Color.gainsPrimary.opacity(0.5) : Color.white.opacity(0.1),
                    lineWidth: isFocused ? 1.5 : 1
                )
        )
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
