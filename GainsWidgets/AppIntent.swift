//
//  AppIntent.swift
//  GainsWidgets
//
//  App Intents for workout control from Live Activity
//  Enables interactive buttons on lock screen (iOS 17+)
//

import WidgetKit
import AppIntents

// MARK: - Widget Configuration Intent
struct ConfigurationAppIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource { "Configuration" }
    static var description: IntentDescription { "Configure the Gains widget." }

    @Parameter(title: "Favorite Emoji", default: "💪")
    var favoriteEmoji: String
}

// MARK: - Workout Control Intents (iOS 17+)
// These enable interactive buttons directly on the Live Activity

/// Intent to complete the current set (quick complete with last values)
@available(iOS 17.0, *)
struct CompleteSetIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Complete Set"
    static var description = IntentDescription("Mark the current set as complete")
    
    func perform() async throws -> some IntentResult {
        // This will be handled by the main app via App Groups
        // The main app's ActiveWorkoutManager listens for this
        
        // Post notification that the main app can observe
        await MainActor.run {
            NotificationCenter.default.post(
                name: NSNotification.Name("CompleteSetFromWidget"),
                object: nil
            )
        }
        
        return .result()
    }
}

/// Intent to skip the rest timer
@available(iOS 17.0, *)
struct SkipRestIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Skip Rest"
    static var description = IntentDescription("Skip the rest timer and continue")
    
    func perform() async throws -> some IntentResult {
        await MainActor.run {
            NotificationCenter.default.post(
                name: NSNotification.Name("SkipRestFromWidget"),
                object: nil
            )
        }
        
        return .result()
    }
}

/// Intent to move to the next exercise
@available(iOS 17.0, *)
struct NextExerciseIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Next Exercise"
    static var description = IntentDescription("Move to the next exercise")
    
    func perform() async throws -> some IntentResult {
        await MainActor.run {
            NotificationCenter.default.post(
                name: NSNotification.Name("NextExerciseFromWidget"),
                object: nil
            )
        }
        
        return .result()
    }
}

/// Intent to open the app to the active workout
@available(iOS 17.0, *)
struct OpenWorkoutIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Open Workout"
    static var description = IntentDescription("Open the Gains app to your active workout")
    
    static var openAppWhenRun: Bool = true
    
    func perform() async throws -> some IntentResult {
        // The app will automatically open due to openAppWhenRun = true
        // Deep link to workout view is handled by the URL scheme
        return .result()
    }
}
