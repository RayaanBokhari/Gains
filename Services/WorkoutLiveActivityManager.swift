//
//  WorkoutLiveActivityManager.swift
//  Gains
//
//  Manages Live Activity for lock screen workout controls
//  Enables logging sets without unlocking phone
//

import Foundation
import ActivityKit
import SwiftUI
import Combine

// MARK: - Workout Activity Attributes (Shared with Widget)
// This MUST match the definition in GainsWidgets/WorkoutActivityAttributes.swift
struct WorkoutActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var exerciseName: String
        var currentSet: Int
        var totalSets: Int
        var lastWeight: Double?
        var lastReps: Int?
        var isResting: Bool
        var restTimeRemaining: Int
        var elapsedTime: TimeInterval
        var totalSetsCompleted: Int
    }
    
    var workoutName: String
    var startTime: Date
}

// MARK: - Live Activity Manager
@MainActor
class WorkoutLiveActivityManager: ObservableObject {
    static let shared = WorkoutLiveActivityManager()
    
    @Published var currentActivity: Activity<WorkoutActivityAttributes>?
    @Published var isActivityActive: Bool = false
    
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        setupWidgetIntentListeners()
    }
    
    // MARK: - Widget Intent Listeners
    private func setupWidgetIntentListeners() {
        // Listen for "Complete Set" from widget
        NotificationCenter.default.publisher(for: NSNotification.Name("CompleteSetFromWidget"))
            .sink { [weak self] _ in
                Task { @MainActor in
                    ActiveWorkoutManager.shared.quickCompleteSet()
                    self?.syncWithWorkoutManager(ActiveWorkoutManager.shared)
                }
            }
            .store(in: &cancellables)
        
        // Listen for "Skip Rest" from widget
        NotificationCenter.default.publisher(for: NSNotification.Name("SkipRestFromWidget"))
            .sink { [weak self] _ in
                Task { @MainActor in
                    ActiveWorkoutManager.shared.skipRestTimer()
                    self?.syncWithWorkoutManager(ActiveWorkoutManager.shared)
                }
            }
            .store(in: &cancellables)
        
        // Listen for "Next Exercise" from widget
        NotificationCenter.default.publisher(for: NSNotification.Name("NextExerciseFromWidget"))
            .sink { [weak self] _ in
                Task { @MainActor in
                    ActiveWorkoutManager.shared.nextExercise()
                    self?.syncWithWorkoutManager(ActiveWorkoutManager.shared)
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Start Live Activity
    func startActivity(workoutName: String, exerciseName: String, totalSets: Int) {
        print("🏋️ WorkoutLiveActivityManager: Attempting to start Live Activity...")
        print("🏋️ WorkoutLiveActivityManager: Workout='\(workoutName)', Exercise='\(exerciseName)', Sets=\(totalSets)")
        
        // Check if Live Activities are supported
        let authInfo = ActivityAuthorizationInfo()
        print("🏋️ WorkoutLiveActivityManager: areActivitiesEnabled = \(authInfo.areActivitiesEnabled)")
        print("🏋️ WorkoutLiveActivityManager: frequentPushesEnabled = \(authInfo.frequentPushesEnabled)")
        
        guard authInfo.areActivitiesEnabled else {
            print("❌ WorkoutLiveActivityManager: Live Activities are NOT enabled on this device!")
            print("❌ WorkoutLiveActivityManager: User needs to enable Live Activities in Settings > Gains")
            return
        }
        
        // End any existing activity first
        if currentActivity != nil {
            print("🏋️ WorkoutLiveActivityManager: Ending existing activity first...")
            endActivity()
        }
        
        let attributes = WorkoutActivityAttributes(
            workoutName: workoutName,
            startTime: Date()
        )
        
        let initialState = WorkoutActivityAttributes.ContentState(
            exerciseName: exerciseName,
            currentSet: 1,
            totalSets: totalSets,
            lastWeight: nil,
            lastReps: nil,
            isResting: false,
            restTimeRemaining: 0,
            elapsedTime: 0,
            totalSetsCompleted: 0
        )
        
        do {
            print("🏋️ WorkoutLiveActivityManager: Requesting Live Activity...")
            let activity = try Activity.request(
                attributes: attributes,
                content: .init(state: initialState, staleDate: nil),
                pushType: nil
            )
            currentActivity = activity
            isActivityActive = true
            print("✅ WorkoutLiveActivityManager: Successfully started Live Activity!")
            print("✅ WorkoutLiveActivityManager: Activity ID = \(activity.id)")
            print("✅ WorkoutLiveActivityManager: Activity State = \(activity.activityState)")
        } catch {
            print("❌ WorkoutLiveActivityManager: Failed to start Live Activity!")
            print("❌ WorkoutLiveActivityManager: Error = \(error)")
            print("❌ WorkoutLiveActivityManager: Error Description = \(error.localizedDescription)")
        }
    }
    
    // MARK: - Update Activity State
    func updateActivity(
        exerciseName: String,
        currentSet: Int,
        totalSets: Int,
        lastWeight: Double?,
        lastReps: Int?,
        isResting: Bool,
        restTimeRemaining: Int,
        elapsedTime: TimeInterval,
        totalSetsCompleted: Int
    ) {
        guard let activity = currentActivity else { return }
        
        let updatedState = WorkoutActivityAttributes.ContentState(
            exerciseName: exerciseName,
            currentSet: currentSet,
            totalSets: totalSets,
            lastWeight: lastWeight,
            lastReps: lastReps,
            isResting: isResting,
            restTimeRemaining: restTimeRemaining,
            elapsedTime: elapsedTime,
            totalSetsCompleted: totalSetsCompleted
        )
        
        Task {
            await activity.update(
                ActivityContent(state: updatedState, staleDate: nil)
            )
        }
    }
    
    // MARK: - Update Rest Timer
    func updateRestTimer(timeRemaining: Int) {
        guard let activity = currentActivity else { return }
        
        Task {
            let currentState = activity.content.state
            let updatedState = WorkoutActivityAttributes.ContentState(
                exerciseName: currentState.exerciseName,
                currentSet: currentState.currentSet,
                totalSets: currentState.totalSets,
                lastWeight: currentState.lastWeight,
                lastReps: currentState.lastReps,
                isResting: timeRemaining > 0,
                restTimeRemaining: timeRemaining,
                elapsedTime: currentState.elapsedTime,
                totalSetsCompleted: currentState.totalSetsCompleted
            )
            
            await activity.update(
                ActivityContent(state: updatedState, staleDate: nil)
            )
        }
    }
    
    // MARK: - End Activity
    func endActivity() {
        guard let activity = currentActivity else { return }
        
        Task {
            await activity.end(
                ActivityContent(
                    state: activity.content.state,
                    staleDate: nil
                ),
                dismissalPolicy: .immediate
            )
            print("WorkoutLiveActivityManager: Ended Live Activity")
        }
        
        currentActivity = nil
        isActivityActive = false
    }
    
    // MARK: - Sync with Workout Manager
    func syncWithWorkoutManager(_ manager: ActiveWorkoutManager) {
        print("🏋️ WorkoutLiveActivityManager: syncWithWorkoutManager called")
        print("🏋️ WorkoutLiveActivityManager: isWorkoutActive = \(manager.isWorkoutActive)")
        
        guard manager.isWorkoutActive else {
            print("🏋️ WorkoutLiveActivityManager: Workout not active, ending activity")
            endActivity()
            return
        }
        
        guard let exercise = manager.currentExercise else {
            print("⚠️ WorkoutLiveActivityManager: No current exercise found!")
            return
        }
        
        print("🏋️ WorkoutLiveActivityManager: Current exercise = '\(exercise.name)'")
        print("🏋️ WorkoutLiveActivityManager: isActivityActive = \(isActivityActive)")
        
        // Start activity if not already running
        if !isActivityActive {
            print("🏋️ WorkoutLiveActivityManager: Activity not running, starting new one...")
            startActivity(
                workoutName: manager.workoutName,
                exerciseName: exercise.name,
                totalSets: exercise.sets.count
            )
        } else {
            // Update state
            let currentSetIndex = exercise.currentSetIndex + 1
            
            print("🏋️ WorkoutLiveActivityManager: Updating activity state...")
            updateActivity(
                exerciseName: exercise.name,
                currentSet: currentSetIndex,
                totalSets: exercise.sets.count,
                lastWeight: exercise.lastCompletedWeight,
                lastReps: exercise.lastCompletedReps,
                isResting: manager.isRestTimerActive,
                restTimeRemaining: Int(manager.restTimeRemaining),
                elapsedTime: manager.elapsedTime,
                totalSetsCompleted: manager.totalSetsCompleted
            )
        }
    }
}

// MARK: - Notification-Based Alternative
// For devices without Dynamic Island or as a fallback

class WorkoutNotificationManager {
    static let shared = WorkoutNotificationManager()
    
    private init() {}
    
    func requestAuthorization() async -> Bool {
        do {
            let center = UNUserNotificationCenter.current()
            return try await center.requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            print("Notification authorization failed: \(error)")
            return false
        }
    }
    
    func showSetReminderNotification(exerciseName: String, setNumber: Int, totalSets: Int) {
        let content = UNMutableNotificationContent()
        content.title = "Ready for Set \(setNumber)?"
        content.body = "\(exerciseName) • Set \(setNumber) of \(totalSets)"
        content.sound = .default
        content.categoryIdentifier = "WORKOUT_SET"
        
        // Add actions
        let completeAction = UNNotificationAction(
            identifier: "COMPLETE_SET",
            title: "✓ Complete",
            options: [.foreground]
        )
        
        let skipAction = UNNotificationAction(
            identifier: "SKIP_REST",
            title: "Skip Rest",
            options: []
        )
        
        let category = UNNotificationCategory(
            identifier: "WORKOUT_SET",
            actions: [completeAction, skipAction],
            intentIdentifiers: [],
            options: []
        )
        
        UNUserNotificationCenter.current().setNotificationCategories([category])
        
        let request = UNNotificationRequest(
            identifier: "workout_set_\(setNumber)",
            content: content,
            trigger: nil
        )
        
        UNUserNotificationCenter.current().add(request)
    }
    
    func cancelAllWorkoutNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
    }
}
