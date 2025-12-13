//
//  ActiveWorkoutManager.swift
//  Gains
//
//  Global workout session manager - persists across app lifecycle
//  Enables lock screen control, background updates, and session recovery
//

import Foundation
import SwiftUI
import Combine

// MARK: - Workout Event Log (Append-First Architecture)
enum WorkoutEvent: Codable {
    case sessionStarted(workoutName: String, planTemplateId: UUID?)
    case exerciseStarted(exerciseId: UUID, exerciseName: String)
    case setLogged(exerciseId: UUID, setId: UUID, weight: Double?, reps: Int?)
    case setEdited(exerciseId: UUID, setId: UUID, weight: Double?, reps: Int?)
    case setUndone(exerciseId: UUID, setId: UUID)
    case restTimerStarted(duration: TimeInterval)
    case restTimerSkipped
    case exerciseCompleted(exerciseId: UUID)
    case sessionEnded
    case sessionCancelled
    
    var timestamp: Date { Date() }
}

// MARK: - Active Set State
struct ActiveSetState: Identifiable, Equatable {
    let id: UUID
    var weight: Double?
    var reps: Int?
    var isCompleted: Bool
    var completedAt: Date?
    
    init(id: UUID = UUID(), weight: Double? = nil, reps: Int? = nil, isCompleted: Bool = false) {
        self.id = id
        self.weight = weight
        self.reps = reps
        self.isCompleted = isCompleted
    }
}

// MARK: - Active Exercise State
struct ActiveExerciseState: Identifiable, Equatable {
    let id: UUID
    var name: String
    var targetSets: Int
    var targetReps: String
    var sets: [ActiveSetState]
    var isCompleted: Bool
    var restDuration: TimeInterval
    
    init(id: UUID = UUID(), name: String, targetSets: Int = 3, targetReps: String = "8-12", restDuration: TimeInterval = 90) {
        self.id = id
        self.name = name
        self.targetSets = targetSets
        self.targetReps = targetReps
        self.sets = (0..<targetSets).map { _ in ActiveSetState() }
        self.isCompleted = false
        self.restDuration = restDuration
    }
    
    var completedSetsCount: Int {
        sets.filter { $0.isCompleted }.count
    }
    
    var currentSetIndex: Int {
        sets.firstIndex { !$0.isCompleted } ?? sets.count - 1
    }
    
    // Get last completed set's values for pre-filling
    var lastCompletedWeight: Double? {
        sets.last { $0.isCompleted }?.weight
    }
    
    var lastCompletedReps: Int? {
        sets.last { $0.isCompleted }?.reps
    }
}

// MARK: - Undo Action
struct UndoableAction {
    let exerciseId: UUID
    let setId: UUID
    let previousWeight: Double?
    let previousReps: Int?
    let wasCompleted: Bool
    let timestamp: Date
    
    var isExpired: Bool {
        Date().timeIntervalSince(timestamp) > 5.0 // 5 second window
    }
}

// MARK: - Active Workout Manager (Singleton)
@MainActor
class ActiveWorkoutManager: ObservableObject {
    static let shared = ActiveWorkoutManager()
    
    // MARK: - Published State
    @Published var isWorkoutActive: Bool = false
    @Published var workoutName: String = ""
    @Published var startTime: Date?
    @Published var exercises: [ActiveExerciseState] = []
    @Published var currentExerciseIndex: Int = 0
    @Published var planTemplateId: UUID?
    
    // Rest Timer
    @Published var isRestTimerActive: Bool = false
    @Published var restTimeRemaining: TimeInterval = 0
    @Published var totalRestTime: TimeInterval = 90
    
    // Undo Support
    @Published var lastAction: UndoableAction?
    @Published var showUndoToast: Bool = false
    
    // Event Log (for persistence & sync)
    @Published private(set) var eventLog: [WorkoutEvent] = []
    
    // Timer Publishers
    private var restTimerCancellable: AnyCancellable?
    private var elapsedTimerCancellable: AnyCancellable?
    private var undoTimerCancellable: AnyCancellable?
    
    @Published var elapsedTime: TimeInterval = 0
    
    // MARK: - Computed Properties
    var currentExercise: ActiveExerciseState? {
        guard currentExerciseIndex < exercises.count else { return nil }
        return exercises[currentExerciseIndex]
    }
    
    var currentSet: ActiveSetState? {
        guard let exercise = currentExercise else { return nil }
        return exercise.sets.first { !$0.isCompleted } ?? exercise.sets.last
    }
    
    var currentSetNumber: Int {
        guard let exercise = currentExercise else { return 1 }
        return (exercise.sets.firstIndex { !$0.isCompleted } ?? exercise.sets.count - 1) + 1
    }
    
    var totalSetsCompleted: Int {
        exercises.reduce(0) { $0 + $1.completedSetsCount }
    }
    
    var totalVolume: Double {
        exercises.reduce(0) { total, exercise in
            total + exercise.sets.reduce(0) { setTotal, set in
                setTotal + (set.weight ?? 0) * Double(set.reps ?? 0)
            }
        }
    }
    
    var completionPercentage: Double {
        let totalSets = exercises.reduce(0) { $0 + $1.sets.count }
        guard totalSets > 0 else { return 0 }
        return Double(totalSetsCompleted) / Double(totalSets)
    }
    
    var restProgress: Double {
        guard totalRestTime > 0 else { return 0 }
        return 1 - (restTimeRemaining / totalRestTime)
    }
    
    // MARK: - Init
    private init() {
        loadPersistedSession()
    }
    
    // MARK: - Session Management
    func startWorkout(name: String, fromPlanId: UUID? = nil) {
        print("🏋️ ActiveWorkoutManager: Starting workout '\(name)'")
        
        isWorkoutActive = true
        workoutName = name
        startTime = Date()
        planTemplateId = fromPlanId
        exercises = []
        currentExerciseIndex = 0
        eventLog = []
        
        logEvent(.sessionStarted(workoutName: name, planTemplateId: fromPlanId))
        startElapsedTimer()
        persistSession()
        
        print("🏋️ ActiveWorkoutManager: Workout started, now syncing Live Activity...")
        
        // Start Live Activity
        syncLiveActivity()
        
        // Haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }
    
    func startWorkoutFromTemplate(_ template: WorkoutTemplate) {
        print("🏋️ ActiveWorkoutManager: Starting workout from template '\(template.name)'")
        
        startWorkout(name: template.name, fromPlanId: template.id)
        
        for plannedExercise in template.exercises {
            let exercise = ActiveExerciseState(
                name: plannedExercise.name,
                targetSets: plannedExercise.targetSets,
                targetReps: plannedExercise.targetReps,
                restDuration: TimeInterval(plannedExercise.restSeconds ?? 90)
            )
            exercises.append(exercise)
            logEvent(.exerciseStarted(exerciseId: exercise.id, exerciseName: exercise.name))
        }
        
        print("🏋️ ActiveWorkoutManager: Template loaded with \(exercises.count) exercises")
        
        persistSession()
        
        // Sync Live Activity now that we have exercises
        print("🏋️ ActiveWorkoutManager: Syncing Live Activity with template exercises...")
        syncLiveActivity()
    }
    
    func addExercise(name: String, targetSets: Int = 3, targetReps: String = "8-12", restDuration: TimeInterval = 90) {
        print("🏋️ ActiveWorkoutManager: Adding exercise '\(name)' (\(targetSets) sets)")
        
        let exercise = ActiveExerciseState(
            name: name,
            targetSets: targetSets,
            targetReps: targetReps,
            restDuration: restDuration
        )
        exercises.append(exercise)
        logEvent(.exerciseStarted(exerciseId: exercise.id, exerciseName: name))
        persistSession()
        
        print("🏋️ ActiveWorkoutManager: Exercise added, total exercises = \(exercises.count)")
        print("🏋️ ActiveWorkoutManager: Syncing Live Activity after adding exercise...")
        syncLiveActivity()
    }
    
    func cancelWorkout() {
        logEvent(.sessionCancelled)
        resetSession()
    }
    
    func endWorkout() -> Workout? {
        guard isWorkoutActive else { return nil }
        
        logEvent(.sessionEnded)
        
        let endTime = Date()
        let workoutStartTime = startTime ?? Date()
        let workoutDuration = endTime.timeIntervalSince(workoutStartTime)
        
        // Convert to Workout model for saving
        let workout = Workout(
            name: workoutName,
            date: workoutStartTime,
            exercises: exercises.map { activeExercise in
                Exercise(
                    name: activeExercise.name,
                    sets: activeExercise.sets.map { activeSet in
                        ExerciseSet(
                            reps: activeSet.reps,
                            weight: activeSet.weight,
                            completed: activeSet.isCompleted
                        )
                    },
                    restTime: activeExercise.restDuration
                )
            },
            duration: workoutDuration,
            startTime: workoutStartTime,
            endTime: endTime
        )
        
        resetSession()
        return workout
    }
    
    private func resetSession() {
        isWorkoutActive = false
        workoutName = ""
        startTime = nil
        exercises = []
        currentExerciseIndex = 0
        eventLog = []
        elapsedTime = 0
        stopRestTimer()
        stopElapsedTimer()
        clearPersistedSession()
        
        // End Live Activity
        WorkoutLiveActivityManager.shared.endActivity()
    }
    
    // MARK: - Live Activity Sync
    private func syncLiveActivity() {
        print("🏋️ ActiveWorkoutManager: Syncing Live Activity...")
        print("🏋️ ActiveWorkoutManager: isWorkoutActive=\(isWorkoutActive), exerciseCount=\(exercises.count)")
        WorkoutLiveActivityManager.shared.syncWithWorkoutManager(self)
    }
    
    // MARK: - Set Logging (One-Tap Flow)
    
    /// Complete current set with the given weight and reps
    func completeCurrentSet(weight: Double, reps: Int) {
        guard currentExerciseIndex < exercises.count else { return }
        
        let exercise = exercises[currentExerciseIndex]
        guard let setIndex = exercise.sets.firstIndex(where: { !$0.isCompleted }) else { return }
        
        // Store for undo
        let setId = exercises[currentExerciseIndex].sets[setIndex].id
        lastAction = UndoableAction(
            exerciseId: exercise.id,
            setId: setId,
            previousWeight: exercises[currentExerciseIndex].sets[setIndex].weight,
            previousReps: exercises[currentExerciseIndex].sets[setIndex].reps,
            wasCompleted: false,
            timestamp: Date()
        )
        
        // Update set
        exercises[currentExerciseIndex].sets[setIndex].weight = weight
        exercises[currentExerciseIndex].sets[setIndex].reps = reps
        exercises[currentExerciseIndex].sets[setIndex].isCompleted = true
        exercises[currentExerciseIndex].sets[setIndex].completedAt = Date()
        
        logEvent(.setLogged(exerciseId: exercise.id, setId: setId, weight: weight, reps: reps))
        
        // Haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
        // Show undo toast
        showUndoToast = true
        startUndoTimer()
        
        // Start rest timer
        startRestTimer(duration: exercise.restDuration)
        
        // Check if exercise is complete
        if exercises[currentExerciseIndex].completedSetsCount == exercises[currentExerciseIndex].sets.count {
            exercises[currentExerciseIndex].isCompleted = true
            logEvent(.exerciseCompleted(exerciseId: exercise.id))
        }
        
        persistSession()
        syncLiveActivity()
    }
    
    /// Quick complete with last values or defaults
    func quickCompleteSet() {
        let weight = currentExercise?.lastCompletedWeight ?? 0
        let reps = currentExercise?.lastCompletedReps ?? 0
        
        if weight > 0 || reps > 0 {
            completeCurrentSet(weight: weight, reps: reps)
        }
    }
    
    /// Undo last set completion
    func undoLastAction() {
        guard let action = lastAction, !action.isExpired else { return }
        
        // Find the exercise and set
        if let exerciseIndex = exercises.firstIndex(where: { $0.id == action.exerciseId }),
           let setIndex = exercises[exerciseIndex].sets.firstIndex(where: { $0.id == action.setId }) {
            
            exercises[exerciseIndex].sets[setIndex].weight = action.previousWeight
            exercises[exerciseIndex].sets[setIndex].reps = action.previousReps
            exercises[exerciseIndex].sets[setIndex].isCompleted = action.wasCompleted
            exercises[exerciseIndex].sets[setIndex].completedAt = nil
            exercises[exerciseIndex].isCompleted = false
            
            logEvent(.setUndone(exerciseId: action.exerciseId, setId: action.setId))
            
            // Stop rest timer
            stopRestTimer()
            
            // Haptic feedback
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
        }
        
        lastAction = nil
        showUndoToast = false
        persistSession()
    }
    
    // MARK: - Exercise Navigation
    func nextExercise() {
        if currentExerciseIndex < exercises.count - 1 {
            currentExerciseIndex += 1
            stopRestTimer()
            persistSession()
            syncLiveActivity()
        }
    }
    
    func previousExercise() {
        if currentExerciseIndex > 0 {
            currentExerciseIndex -= 1
            stopRestTimer()
            persistSession()
            syncLiveActivity()
        }
    }
    
    func goToExercise(at index: Int) {
        guard index >= 0 && index < exercises.count else { return }
        currentExerciseIndex = index
        stopRestTimer()
        persistSession()
        syncLiveActivity()
    }
    
    // MARK: - Weight/Rep Adjustments (Stepper Controls)
    func incrementWeight(by amount: Double = 5) {
        guard currentExerciseIndex < exercises.count else { return }
        let exercise = exercises[currentExerciseIndex]
        guard let setIndex = exercise.sets.firstIndex(where: { !$0.isCompleted }) else { return }
        
        let currentWeight = exercises[currentExerciseIndex].sets[setIndex].weight ?? 0
        exercises[currentExerciseIndex].sets[setIndex].weight = currentWeight + amount
        
        // Light haptic
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
    
    func decrementWeight(by amount: Double = 5) {
        guard currentExerciseIndex < exercises.count else { return }
        let exercise = exercises[currentExerciseIndex]
        guard let setIndex = exercise.sets.firstIndex(where: { !$0.isCompleted }) else { return }
        
        let currentWeight = exercises[currentExerciseIndex].sets[setIndex].weight ?? 0
        exercises[currentExerciseIndex].sets[setIndex].weight = max(0, currentWeight - amount)
        
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
    
    func incrementReps(by amount: Int = 1) {
        guard currentExerciseIndex < exercises.count else { return }
        let exercise = exercises[currentExerciseIndex]
        guard let setIndex = exercise.sets.firstIndex(where: { !$0.isCompleted }) else { return }
        
        let currentReps = exercises[currentExerciseIndex].sets[setIndex].reps ?? 0
        exercises[currentExerciseIndex].sets[setIndex].reps = currentReps + amount
        
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
    
    func decrementReps(by amount: Int = 1) {
        guard currentExerciseIndex < exercises.count else { return }
        let exercise = exercises[currentExerciseIndex]
        guard let setIndex = exercise.sets.firstIndex(where: { !$0.isCompleted }) else { return }
        
        let currentReps = exercises[currentExerciseIndex].sets[setIndex].reps ?? 0
        exercises[currentExerciseIndex].sets[setIndex].reps = max(0, currentReps - amount)
        
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
    
    // MARK: - Rest Timer
    func startRestTimer(duration: TimeInterval) {
        totalRestTime = duration
        restTimeRemaining = duration
        isRestTimerActive = true
        
        restTimerCancellable?.cancel()
        restTimerCancellable = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self else { return }
                if self.restTimeRemaining > 0 {
                    self.restTimeRemaining -= 1
                    
                    // Update Live Activity rest timer
                    WorkoutLiveActivityManager.shared.updateRestTimer(timeRemaining: Int(self.restTimeRemaining))
                    
                    // Gentle pulse at 10 seconds
                    if self.restTimeRemaining == 10 {
                        let generator = UIImpactFeedbackGenerator(style: .medium)
                        generator.impactOccurred()
                    }
                } else {
                    self.stopRestTimer()
                    // Completion haptic
                    let generator = UINotificationFeedbackGenerator()
                    generator.notificationOccurred(.success)
                }
            }
    }
    
    func stopRestTimer() {
        isRestTimerActive = false
        restTimeRemaining = 0
        restTimerCancellable?.cancel()
        logEvent(.restTimerSkipped)
    }
    
    func skipRestTimer() {
        stopRestTimer()
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
    
    // MARK: - Elapsed Timer
    private func startElapsedTimer() {
        elapsedTimerCancellable?.cancel()
        elapsedTimerCancellable = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self, let start = self.startTime else { return }
                self.elapsedTime = Date().timeIntervalSince(start)
            }
    }
    
    private func stopElapsedTimer() {
        elapsedTimerCancellable?.cancel()
    }
    
    // MARK: - Undo Timer
    private func startUndoTimer() {
        undoTimerCancellable?.cancel()
        undoTimerCancellable = Timer.publish(every: 5, on: .main, in: .common)
            .autoconnect()
            .first()
            .sink { [weak self] _ in
                self?.showUndoToast = false
                self?.lastAction = nil
            }
    }
    
    // MARK: - Event Logging
    private func logEvent(_ event: WorkoutEvent) {
        eventLog.append(event)
    }
    
    // MARK: - Persistence
    private let sessionKey = "active_workout_session"
    
    private func persistSession() {
        // Persist to UserDefaults for session recovery
        let sessionData: [String: Any] = [
            "isActive": isWorkoutActive,
            "workoutName": workoutName,
            "startTime": startTime?.timeIntervalSince1970 ?? 0,
            "currentExerciseIndex": currentExerciseIndex
        ]
        UserDefaults.standard.set(sessionData, forKey: sessionKey)
    }
    
    private func loadPersistedSession() {
        // Load persisted session on app launch
        guard let sessionData = UserDefaults.standard.dictionary(forKey: sessionKey),
              let isActive = sessionData["isActive"] as? Bool,
              isActive else { return }
        
        // Session recovery would go here
        // For now, we just clear stale sessions
        clearPersistedSession()
    }
    
    private func clearPersistedSession() {
        UserDefaults.standard.removeObject(forKey: sessionKey)
    }
}

// MARK: - Formatted Time Helpers
extension ActiveWorkoutManager {
    var formattedElapsedTime: String {
        let minutes = Int(elapsedTime) / 60
        let seconds = Int(elapsedTime) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    var formattedRestTime: String {
        let minutes = Int(restTimeRemaining) / 60
        let seconds = Int(restTimeRemaining) % 60
        if minutes > 0 {
            return String(format: "%d:%02d", minutes, seconds)
        }
        return "\(seconds)s"
    }
}

