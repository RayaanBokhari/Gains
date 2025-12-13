//
//  ActiveWorkoutSessionView.swift
//  Gains
//
//  Premium workout logging - One-tap, no keyboard, fluid flow
//  Exercise Card Stack with depth effect
//

import SwiftUI

struct ActiveWorkoutSessionView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var workoutManager = ActiveWorkoutManager.shared
    @StateObject private var workoutViewModel = WorkoutViewModel()
    
    @State private var showAddExercise = false
    @State private var showDiscardAlert = false
    @State private var showTimelineView = false
    @State private var showFinishSheet = false
    
    var body: some View {
        ZStack {
            // Background
            Color.gainsAppBackground.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                workoutHeader
                
                // Main Content
                if workoutManager.exercises.isEmpty {
                    emptyStateView
                } else {
                    exerciseCardStack
                }
                
                Spacer(minLength: 0)
                
                // Bottom Action Bar
                bottomActionBar
            }
            
            // Undo Toast Overlay
            if workoutManager.showUndoToast {
                undoToast
            }
        }
        .alert("Discard Workout?", isPresented: $showDiscardAlert) {
            Button("Keep Working", role: .cancel) { }
            Button("Discard", role: .destructive) {
                workoutManager.cancelWorkout()
                dismiss()
            }
        } message: {
            Text("Your workout progress will be lost.")
        }
        .sheet(isPresented: $showAddExercise) {
            AddExerciseToSessionView(workoutManager: workoutManager)
        }
        .sheet(isPresented: $showTimelineView) {
            ExerciseTimelineView(workoutManager: workoutManager)
        }
        .sheet(isPresented: $showFinishSheet) {
            WorkoutFinishSheet(workoutManager: workoutManager, workoutViewModel: workoutViewModel) {
                dismiss()
            }
        }
    }
    
    // MARK: - Header
    private var workoutHeader: some View {
        VStack(spacing: 0) {
            HStack(alignment: .center) {
                // Cancel Button
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
                
                Spacer()
                
                // Workout Name & Timer
                VStack(spacing: 2) {
                    Text(workoutManager.workoutName)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    HStack(spacing: 6) {
                        Image(systemName: "clock.fill")
                            .font(.system(size: 10))
                            .foregroundColor(.gainsAccentOrange)
                        
                        Text(workoutManager.formattedElapsedTime)
                            .font(.system(size: 13, weight: .medium, design: .monospaced))
                            .foregroundColor(.gainsTextSecondary)
                    }
                }
                
                Spacer()
                
                // Timeline Button
                Button {
                    showTimelineView = true
                } label: {
                    Image(systemName: "list.bullet")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.gainsPrimary)
                        .frame(width: 36, height: 36)
                        .background(
                            Circle()
                                .fill(Color.gainsPrimary.opacity(0.12))
                        )
                }
            }
            .padding(.horizontal, GainsDesign.paddingHorizontal)
            .padding(.vertical, GainsDesign.spacingL)
            
            // Progress Bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.white.opacity(0.06))
                        .frame(height: 3)
                    
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [Color.gainsPrimary, Color.gainsAccentBlue],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * workoutManager.completionPercentage, height: 3)
                        .animation(.spring(response: 0.4), value: workoutManager.completionPercentage)
                }
            }
            .frame(height: 3)
        }
        .background(
            Rectangle()
                .fill(.ultraThinMaterial)
                .environment(\.colorScheme, .dark)
        )
    }
    
    // MARK: - Exercise Card Stack
    private var exerciseCardStack: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: GainsDesign.spacingL) {
                // Current Exercise (Expanded)
                if let exercise = workoutManager.currentExercise {
                    CurrentExerciseCard(
                        exercise: exercise,
                        exerciseIndex: workoutManager.currentExerciseIndex,
                        totalExercises: workoutManager.exercises.count,
                        workoutManager: workoutManager
                    )
                }
                
                // Rest Timer Card (when active)
                if workoutManager.isRestTimerActive {
                    RestTimerCard(workoutManager: workoutManager)
                }
                
                // Upcoming Exercises (Stacked)
                upcomingExercisesStack
                
                // Add Exercise Button
                addExerciseButton
            }
            .padding(.horizontal, GainsDesign.paddingHorizontal)
            .padding(.top, GainsDesign.spacingXL)
            .padding(.bottom, 160)
        }
    }
    
    // MARK: - Upcoming Exercises Stack
    private var upcomingExercisesStack: some View {
        VStack(spacing: GainsDesign.spacingS) {
            ForEach(Array(workoutManager.exercises.enumerated()), id: \.element.id) { index, exercise in
                if index > workoutManager.currentExerciseIndex {
                    UpcomingExerciseCard(
                        exercise: exercise,
                        index: index,
                        depth: index - workoutManager.currentExerciseIndex - 1,
                        workoutManager: workoutManager
                    )
                }
            }
        }
    }
    
    // MARK: - Empty State
    private var emptyStateView: some View {
        VStack(spacing: GainsDesign.spacingXXL) {
            Spacer()
            
            ZStack {
                Circle()
                    .fill(.ultraThinMaterial)
                    .environment(\.colorScheme, .dark)
                    .frame(width: 100, height: 100)
                
                Image(systemName: "plus.circle")
                    .font(.system(size: 44, weight: .light))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.gainsPrimary, Color.gainsAccentBlue],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            
            VStack(spacing: GainsDesign.spacingS) {
                Text("Add Your First Exercise")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Text("Build your workout by adding exercises")
                    .font(.system(size: 15))
                    .foregroundColor(.gainsTextSecondary)
            }
            
            Button {
                showAddExercise = true
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .semibold))
                    Text("Add Exercise")
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
    
    // MARK: - Bottom Action Bar
    private var bottomActionBar: some View {
        VStack(spacing: 0) {
            // Gradient fade
            LinearGradient(
                colors: [Color(hex: "0A0B0E").opacity(0), Color(hex: "0A0B0E")],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 24)
            
            // Stats Row
            HStack(spacing: GainsDesign.spacingXXL) {
                // Total Sets
                VStack(spacing: 2) {
                    Text("\(workoutManager.totalSetsCompleted)")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    Text("sets")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.gainsTextTertiary)
                }
                
                // Volume
                VStack(spacing: 2) {
                    Text(formatVolume(workoutManager.totalVolume))
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    Text("volume")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.gainsTextTertiary)
                }
                
                Spacer()
                
                // Finish Button
                Button {
                    showFinishSheet = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 16, weight: .semibold))
                        
                        Text("Finish")
                            .font(.system(size: 16, weight: .bold))
                    }
                    .foregroundColor(workoutManager.totalSetsCompleted > 0 ? .white : .gainsTextTertiary)
                    .padding(.horizontal, 24)
                    .frame(height: 48)
                    .background(
                        Capsule()
                            .fill(
                                workoutManager.totalSetsCompleted > 0
                                    ? LinearGradient(
                                        colors: [Color.gainsSuccess, Color(hex: "30D158")],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                    : LinearGradient(
                                        colors: [Color.gainsCardSurface, Color.gainsCardSurface],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                            )
                    )
                    .shadow(
                        color: workoutManager.totalSetsCompleted > 0 ? Color.gainsSuccess.opacity(0.4) : .clear,
                        radius: 12,
                        x: 0,
                        y: 6
                    )
                }
                .disabled(workoutManager.totalSetsCompleted == 0)
            }
            .padding(.horizontal, GainsDesign.paddingHorizontal)
            .padding(.top, GainsDesign.spacingL)
            .padding(.bottom, 34)
            .background(Color(hex: "0A0B0E"))
        }
    }
    
    // MARK: - Undo Toast
    private var undoToast: some View {
        VStack {
            Spacer()
            
            HStack(spacing: GainsDesign.spacingM) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 18))
                    .foregroundColor(.gainsSuccess)
                
                Text("Set logged")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.white)
                
                Spacer()
                
                Button {
                    workoutManager.undoLastAction()
                } label: {
                    Text("Undo")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.gainsPrimary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(Color.gainsPrimary.opacity(0.15))
                        )
                }
            }
            .padding(GainsDesign.spacingL)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.gainsCardSurface)
                    .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
            )
            .padding(.horizontal, GainsDesign.paddingHorizontal)
            .padding(.bottom, 120)
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
        .animation(.spring(response: 0.3), value: workoutManager.showUndoToast)
    }
    
    // MARK: - Helpers
    private func formatVolume(_ volume: Double) -> String {
        if volume >= 1000 {
            return String(format: "%.1fk", volume / 1000)
        }
        return "\(Int(volume))"
    }
}

// MARK: - Current Exercise Card
struct CurrentExerciseCard: View {
    let exercise: ActiveExerciseState
    let exerciseIndex: Int
    let totalExercises: Int
    @ObservedObject var workoutManager: ActiveWorkoutManager
    
    private var currentSetIndex: Int {
        exercise.sets.firstIndex { !$0.isCompleted } ?? exercise.sets.count - 1
    }
    
    private var currentSet: ActiveSetState {
        exercise.sets[safe: currentSetIndex] ?? exercise.sets.first ?? ActiveSetState()
    }
    
    @State private var weight: Double = 0
    @State private var reps: Int = 0
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    // Exercise counter
                    Text("Exercise \(exerciseIndex + 1) of \(totalExercises)")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.gainsTextTertiary)
                    
                    Text(exercise.name)
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    // Set progress
                    HStack(spacing: 6) {
                        Text("Set \(currentSetIndex + 1) of \(exercise.sets.count)")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.gainsTextSecondary)
                        
                        Text("•")
                            .foregroundColor(.gainsTextMuted)
                        
                        Text("Target: \(exercise.targetReps)")
                            .font(.system(size: 13))
                            .foregroundColor(.gainsTextTertiary)
                    }
                }
                
                Spacer()
                
                // Completion Ring
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.1), lineWidth: 4)
                        .frame(width: 52, height: 52)
                    
                    Circle()
                        .trim(from: 0, to: Double(exercise.completedSetsCount) / Double(exercise.sets.count))
                        .stroke(
                            LinearGradient(
                                colors: [Color.gainsPrimary, Color.gainsAccentBlue],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 4, lineCap: .round)
                        )
                        .frame(width: 52, height: 52)
                        .rotationEffect(.degrees(-90))
                    
                    Text("\(exercise.completedSetsCount)")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }
            }
            .padding(GainsDesign.spacingXL)
            
            Divider()
                .background(Color.white.opacity(0.08))
            
            // Input Section - Tappable fields with keyboard
            HStack(spacing: GainsDesign.spacingL) {
                // Weight Input
                TappableNumberInput(
                    value: $weight,
                    label: "lbs",
                    placeholder: "0",
                    keyboardType: .decimalPad,
                    accentColor: .gainsPrimary
                )
                
                Text("×")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(.gainsTextMuted)
                
                // Reps Input
                TappableNumberInput(
                    value: Binding(
                        get: { Double(reps) },
                        set: { reps = Int($0) }
                    ),
                    label: "reps",
                    placeholder: "0",
                    keyboardType: .numberPad,
                    accentColor: .gainsAccentBlue
                )
            }
            .padding(GainsDesign.spacingXL)
            
            // Complete Set Button
            Button {
                withAnimation(.spring(response: 0.3)) {
                    workoutManager.completeCurrentSet(weight: weight, reps: reps)
                    // Pre-fill next set with same values
                }
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 18, weight: .semibold))
                    
                    Text("Complete Set")
                        .font(.system(size: 17, weight: .bold))
                }
                .foregroundColor(canComplete ? .white : .gainsTextTertiary)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    Group {
                        if canComplete {
                            LinearGradient(
                                colors: [Color.gainsPrimary, Color.gainsAccentBlue],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        } else {
                            Color.gainsCardElevated
                        }
                    }
                )
            }
            .disabled(!canComplete)
        }
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(.ultraThinMaterial)
                .environment(\.colorScheme, .dark)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [Color.gainsPrimary.opacity(0.3), Color.gainsAccentBlue.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5
                )
        )
        .shadow(color: Color.gainsPrimary.opacity(0.15), radius: 30, x: 0, y: 15)
        .onAppear {
            // Pre-fill with last values
            if let lastWeight = exercise.lastCompletedWeight {
                weight = lastWeight
            }
            if let lastReps = exercise.lastCompletedReps {
                reps = lastReps
            }
        }
    }
    
    private var canComplete: Bool {
        weight > 0 || reps > 0
    }
    
    private func formatWeight(_ w: Double) -> String {
        w.truncatingRemainder(dividingBy: 1) == 0 ? "\(Int(w))" : String(format: "%.1f", w)
    }
}

// MARK: - Stepper Button
struct StepperButton: View {
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            action()
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
        }) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 56, height: 56)
                
                Circle()
                    .stroke(color.opacity(0.3), lineWidth: 1.5)
                    .frame(width: 56, height: 56)
                
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(color)
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Tappable Number Input (allows keyboard entry)
struct TappableNumberInput: View {
    @Binding var value: Double
    let label: String
    let placeholder: String
    let keyboardType: UIKeyboardType
    let accentColor: Color
    
    @State private var isEditing = false
    @State private var textValue: String = ""
    @FocusState private var isFocused: Bool
    
    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                // Background
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.gainsCardSurface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(isFocused ? accentColor : Color.white.opacity(0.1), lineWidth: isFocused ? 2 : 1)
                    )
                    .frame(height: 72)
                
                if isEditing {
                    // Text field for input
                    TextField(placeholder, text: $textValue)
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .keyboardType(keyboardType)
                        .focused($isFocused)
                        .onSubmit {
                            commitValue()
                        }
                        .toolbar {
                            ToolbarItemGroup(placement: .keyboard) {
                                Spacer()
                                Button("Done") {
                                    commitValue()
                                }
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.gainsPrimary)
                            }
                        }
                } else {
                    // Display value - tap to edit
                    Text(value > 0 ? formatDisplayValue() : placeholder)
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(value > 0 ? .white : .gainsTextMuted)
                        .contentTransition(.numericText())
                }
            }
            .onTapGesture {
                startEditing()
            }
            .animation(.easeInOut(duration: 0.2), value: isFocused)
            
            // Label
            Text(label)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.gainsTextTertiary)
        }
        .frame(maxWidth: .infinity)
        .onChange(of: isFocused) { _, focused in
            if !focused {
                commitValue()
            }
        }
    }
    
    private func startEditing() {
        textValue = value > 0 ? formatDisplayValue() : ""
        isEditing = true
        isFocused = true
    }
    
    private func commitValue() {
        if let parsed = Double(textValue.replacingOccurrences(of: ",", with: ".")) {
            value = parsed
        }
        isEditing = false
        isFocused = false
    }
    
    private func formatDisplayValue() -> String {
        if value == floor(value) {
            return String(format: "%.0f", value)
        } else {
            return String(format: "%.1f", value)
        }
    }
}

// MARK: - Rest Timer Card
struct RestTimerCard: View {
    @ObservedObject var workoutManager: ActiveWorkoutManager
    
    var body: some View {
        HStack(spacing: GainsDesign.spacingL) {
            // Timer Ring
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.1), lineWidth: 4)
                    .frame(width: 56, height: 56)
                
                Circle()
                    .trim(from: 0, to: workoutManager.restProgress)
                    .stroke(
                        LinearGradient(
                            colors: [Color.gainsAccentBlue, Color.gainsPrimary],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 4, lineCap: .round)
                    )
                    .frame(width: 56, height: 56)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 1), value: workoutManager.restProgress)
                
                Image(systemName: "clock.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.gainsAccentBlue)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Rest Timer")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.gainsTextSecondary)
                
                Text(workoutManager.formattedRestTime)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }
            
            Spacer()
            
            // Skip Button
            Button {
                workoutManager.skipRestTimer()
            } label: {
                Text("Skip")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.gainsPrimary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        Capsule()
                            .fill(Color.gainsPrimary.opacity(0.15))
                    )
            }
        }
        .padding(GainsDesign.spacingXL)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.gainsAccentBlue.opacity(0.1))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.gainsAccentBlue.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Upcoming Exercise Card
struct UpcomingExerciseCard: View {
    let exercise: ActiveExerciseState
    let index: Int
    let depth: Int
    @ObservedObject var workoutManager: ActiveWorkoutManager
    
    var body: some View {
        Button {
            workoutManager.goToExercise(at: index)
        } label: {
            HStack(spacing: GainsDesign.spacingL) {
                // Number badge
                Text("\(index + 1)")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.gainsTextTertiary)
                    .frame(width: 28, height: 28)
                    .background(
                        Circle()
                            .fill(Color.white.opacity(0.05))
                    )
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(exercise.name)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Text("\(exercise.sets.count) sets • \(exercise.targetReps) reps")
                        .font(.system(size: 12))
                        .foregroundColor(.gainsTextTertiary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.gainsTextMuted)
            }
            .padding(GainsDesign.spacingL)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.gainsCardSurface.opacity(1 - Double(min(depth, 3)) * 0.2))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.white.opacity(0.04), lineWidth: 0.5)
            )
            .scaleEffect(1 - Double(min(depth, 3)) * 0.02)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Array Safe Subscript
extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

// MARK: - Add Exercise to Session View
struct AddExerciseToSessionView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var workoutManager: ActiveWorkoutManager
    @StateObject private var templateService = ExerciseTemplateService()
    
    @State private var searchText = ""
    @State private var selectedCategory: ExerciseCategory? = nil
    @State private var customExerciseName = ""
    @State private var showCustomAlert = false
    
    var filteredTemplates: [ExerciseTemplate] {
        var templates = templateService.templates
        
        if let category = selectedCategory {
            templates = templates.filter { $0.category == category }
        }
        
        if !searchText.isEmpty {
            templates = templates.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
        
        return templates
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.gainsAppBackground.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Search
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gainsTextSecondary)
                        
                        TextField("Search exercises...", text: $searchText)
                            .textFieldStyle(.plain)
                            .foregroundColor(.white)
                    }
                    .padding()
                    .background(Color.gainsCardSurface)
                    .cornerRadius(12)
                    .padding()
                    
                    // Categories
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            CategoryPill(title: "All", isSelected: selectedCategory == nil) {
                                selectedCategory = nil
                            }
                            
                            ForEach(ExerciseCategory.allCases, id: \.self) { category in
                                CategoryPill(title: category.rawValue, isSelected: selectedCategory == category) {
                                    selectedCategory = category
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.bottom, 8)
                    
                    // Exercise List
                    ScrollView {
                        LazyVStack(spacing: 8) {
                            // Custom option
                            Button {
                                showCustomAlert = true
                            } label: {
                                HStack {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.system(size: 24))
                                        .foregroundColor(.gainsPrimary)
                                    
                                    VStack(alignment: .leading) {
                                        Text("Custom Exercise")
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundColor(.white)
                                        Text("Create your own")
                                            .font(.system(size: 12))
                                            .foregroundColor(.gainsTextSecondary)
                                    }
                                    
                                    Spacer()
                                }
                                .padding()
                                .background(Color.gainsCardSurface)
                                .cornerRadius(12)
                            }
                            
                            ForEach(filteredTemplates) { template in
                                Button {
                                    workoutManager.addExercise(
                                        name: template.name,
                                        targetSets: 3,
                                        targetReps: "8-12"
                                    )
                                    dismiss()
                                } label: {
                                    HStack {
                                        Image(systemName: "dumbbell.fill")
                                            .font(.system(size: 20))
                                            .foregroundColor(.gainsPrimary)
                                            .frame(width: 40, height: 40)
                                            .background(Color.gainsPrimary.opacity(0.15))
                                            .cornerRadius(10)
                                        
                                        VStack(alignment: .leading) {
                                            Text(template.name)
                                                .font(.system(size: 16, weight: .semibold))
                                                .foregroundColor(.white)
                                            
                                            Text(template.category.rawValue)
                                                .font(.system(size: 12))
                                                .foregroundColor(.gainsTextSecondary)
                                        }
                                        
                                        Spacer()
                                        
                                        Image(systemName: "plus.circle")
                                            .font(.system(size: 22))
                                            .foregroundColor(.gainsPrimary)
                                    }
                                    .padding()
                                    .background(Color.gainsCardSurface)
                                    .cornerRadius(12)
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Add Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.gainsPrimary)
                }
            }
            .alert("Custom Exercise", isPresented: $showCustomAlert) {
                TextField("Exercise name", text: $customExerciseName)
                Button("Cancel", role: .cancel) { customExerciseName = "" }
                Button("Add") {
                    if !customExerciseName.isEmpty {
                        workoutManager.addExercise(name: customExerciseName)
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Exercise Timeline View
struct ExerciseTimelineView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var workoutManager: ActiveWorkoutManager
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.gainsAppBackground.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: GainsDesign.spacingL) {
                        ForEach(Array(workoutManager.exercises.enumerated()), id: \.element.id) { index, exercise in
                            TimelineExerciseCard(
                                exercise: exercise,
                                index: index,
                                isCurrent: index == workoutManager.currentExerciseIndex
                            ) {
                                workoutManager.goToExercise(at: index)
                                dismiss()
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Exercise Timeline")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(.gainsPrimary)
                }
            }
        }
    }
}

// MARK: - Timeline Exercise Card
struct TimelineExerciseCard: View {
    let exercise: ActiveExerciseState
    let index: Int
    let isCurrent: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: GainsDesign.spacingM) {
                HStack {
                    Text(exercise.name)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    if isCurrent {
                        Text("Current")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.gainsPrimary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Capsule().fill(Color.gainsPrimary.opacity(0.2)))
                    } else if exercise.isCompleted {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.gainsSuccess)
                    }
                }
                
                // Sets
                HStack(spacing: 8) {
                    ForEach(Array(exercise.sets.enumerated()), id: \.element.id) { setIndex, set in
                        VStack(spacing: 2) {
                            Text("\(setIndex + 1)")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(set.isCompleted ? .white : .gainsTextTertiary)
                            
                            if set.isCompleted, let w = set.weight, let r = set.reps {
                                Text("\(Int(w))×\(r)")
                                    .font(.system(size: 9))
                                    .foregroundColor(.gainsTextSecondary)
                            }
                        }
                        .frame(width: 44, height: 36)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(set.isCompleted ? Color.gainsPrimary : Color.white.opacity(0.05))
                        )
                    }
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isCurrent ? Color.gainsPrimary.opacity(0.1) : Color.gainsCardSurface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isCurrent ? Color.gainsPrimary.opacity(0.4) : Color.clear, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Workout Finish Sheet
struct WorkoutFinishSheet: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var workoutManager: ActiveWorkoutManager
    @ObservedObject var workoutViewModel: WorkoutViewModel
    let onComplete: () -> Void
    
    @State private var isSaving = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.gainsAppBackground.ignoresSafeArea()
                
                VStack(spacing: GainsDesign.spacingXXL) {
                    Spacer()
                    
                    // Success Icon
                    ZStack {
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [Color.gainsSuccess.opacity(0.3), Color.clear],
                                    center: .center,
                                    startRadius: 20,
                                    endRadius: 60
                                )
                            )
                            .frame(width: 120, height: 120)
                        
                        Circle()
                            .fill(Color.gainsSuccess.opacity(0.15))
                            .frame(width: 80, height: 80)
                        
                        Image(systemName: "checkmark")
                            .font(.system(size: 36, weight: .bold))
                            .foregroundColor(.gainsSuccess)
                    }
                    
                    // Title
                    VStack(spacing: GainsDesign.spacingS) {
                        Text("Great Workout!")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        
                        Text(workoutManager.workoutName)
                            .font(.system(size: 17))
                            .foregroundColor(.gainsTextSecondary)
                    }
                    
                    // Stats Grid
                    HStack(spacing: GainsDesign.spacingXL) {
                        StatBox(
                            value: workoutManager.formattedElapsedTime,
                            label: "Duration",
                            icon: "clock.fill",
                            color: .gainsAccentOrange
                        )
                        
                        StatBox(
                            value: "\(workoutManager.totalSetsCompleted)",
                            label: "Sets",
                            icon: "checkmark.circle.fill",
                            color: .gainsPrimary
                        )
                        
                        StatBox(
                            value: formatVolume(workoutManager.totalVolume),
                            label: "Volume",
                            icon: "scalemass.fill",
                            color: .gainsAccentGreen
                        )
                    }
                    .padding(.horizontal)
                    
                    Spacer()
                    
                    // Save Button
                    Button {
                        saveWorkout()
                    } label: {
                        HStack(spacing: 10) {
                            if isSaving {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Image(systemName: "square.and.arrow.down.fill")
                                    .font(.system(size: 16, weight: .semibold))
                                Text("Save Workout")
                                    .font(.system(size: 17, weight: .bold))
                            }
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [Color.gainsSuccess, Color(hex: "30D158")],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                        )
                        .shadow(color: Color.gainsSuccess.opacity(0.4), radius: 16, x: 0, y: 8)
                    }
                    .disabled(isSaving)
                    .padding(.horizontal, GainsDesign.paddingHorizontal)
                    .padding(.bottom, 34)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Back") { dismiss() }
                        .foregroundColor(.gainsTextSecondary)
                }
            }
        }
    }
    
    private func saveWorkout() {
        isSaving = true
        
        Task {
            if let workout = workoutManager.endWorkout() {
                // Set up the workout in viewModel and save
                workoutViewModel.currentWorkout = workout
                await workoutViewModel.endWorkout()
            }
            
            isSaving = false
            dismiss()
            onComplete()
        }
    }
    
    private func formatVolume(_ v: Double) -> String {
        if v >= 1000 {
            return String(format: "%.1fk", v / 1000)
        }
        return "\(Int(v))"
    }
}

// MARK: - Stat Box
struct StatBox: View {
    let value: String
    let label: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: GainsDesign.spacingS) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 40, height: 40)
                
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(color)
            }
            
            Text(value)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.gainsTextTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, GainsDesign.spacingL)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.gainsCardSurface)
        )
    }
}

#Preview {
    ActiveWorkoutSessionView()
}

