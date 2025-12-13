//
//  GainsWidgetsLiveActivity.swift
//  GainsWidgets
//
//  Workout Live Activity - Lock screen & Dynamic Island UI
//  Appears when workout is in progress, enables logging without unlocking
//

import ActivityKit
import WidgetKit
import SwiftUI

// MARK: - Workout Live Activity Widget
struct WorkoutLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: WorkoutActivityAttributes.self) { context in
            // Lock Screen / Banner UI - This is what shows on lock screen!
            WorkoutLockScreenView(context: context)
                .activityBackgroundTint(Color.black.opacity(0.9))
                .activitySystemActionForegroundColor(.white)
            
        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded Dynamic Island UI
                DynamicIslandExpandedRegion(.leading) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(context.state.exerciseName)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.white)
                            .lineLimit(1)
                        
                        Text("Set \(context.state.currentSet)/\(context.state.totalSets)")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                    }
                }
                
                DynamicIslandExpandedRegion(.trailing) {
                    if context.state.isResting {
                        VStack(spacing: 2) {
                            Text(formatTime(context.state.restTimeRemaining))
                                .font(.system(size: 22, weight: .bold, design: .rounded))
                                .foregroundColor(Color(hex: "64D2FF"))
                            Text("rest")
                                .font(.system(size: 10))
                                .foregroundColor(.gray)
                        }
                    } else {
                        VStack(spacing: 2) {
                            Text("\(context.state.totalSetsCompleted)")
                                .font(.system(size: 22, weight: .bold, design: .rounded))
                                .foregroundColor(Color(hex: "30D158"))
                            Text("done")
                                .font(.system(size: 10))
                                .foregroundColor(.gray)
                        }
                    }
                }
                
                DynamicIslandExpandedRegion(.bottom) {
                    HStack(spacing: 12) {
                        // Last set info
                        if let weight = context.state.lastWeight, let reps = context.state.lastReps {
                            Text("Last: \(Int(weight))lb × \(reps)")
                                .font(.system(size: 12))
                                .foregroundColor(.gray)
                        }
                        
                        Spacer()
                        
                        // Timer
                        HStack(spacing: 4) {
                            Image(systemName: "clock")
                                .font(.system(size: 10))
                            Text(formatElapsedTime(context.state.elapsedTime))
                                .font(.system(size: 12, design: .monospaced))
                        }
                        .foregroundColor(Color(hex: "FF9F0A"))
                    }
                }
                
            } compactLeading: {
                Image(systemName: "dumbbell.fill")
                    .foregroundColor(Color(hex: "0A84FF"))
                
            } compactTrailing: {
                if context.state.isResting {
                    Text(formatTime(context.state.restTimeRemaining))
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Color(hex: "64D2FF"))
                } else {
                    Text("\(context.state.currentSet)/\(context.state.totalSets)")
                        .font(.system(size: 14, weight: .semibold))
                }
                
            } minimal: {
                Image(systemName: "dumbbell.fill")
                    .foregroundColor(Color(hex: "0A84FF"))
            }
            .widgetURL(URL(string: "gains://workout"))
            .keylineTint(Color(hex: "0A84FF"))
        }
    }
    
    private func formatTime(_ seconds: Int) -> String {
        if seconds >= 60 {
            return "\(seconds / 60):\(String(format: "%02d", seconds % 60))"
        }
        return "\(seconds)s"
    }
    
    private func formatElapsedTime(_ interval: TimeInterval) -> String {
        let minutes = Int(interval) / 60
        let seconds = Int(interval) % 60
        return "\(minutes):\(String(format: "%02d", seconds))"
    }
}

// MARK: - Lock Screen View with Interactive Controls
struct WorkoutLockScreenView: View {
    let context: ActivityViewContext<WorkoutActivityAttributes>
    
    var body: some View {
        VStack(spacing: 12) {
            // Top Row - Header info in single line
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "dumbbell.fill")
                        .font(.system(size: 12))
                        .foregroundColor(Color(hex: "0A84FF"))
                    
                    Text(context.attributes.workoutName)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                // Timer badge
                HStack(spacing: 4) {
                    Image(systemName: "clock.fill")
                        .font(.system(size: 10))
                        .foregroundColor(Color(hex: "FF9F0A"))
                    
                    Text(formatElapsedTime(context.state.elapsedTime))
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                        .foregroundColor(.white)
                }
            }
            
            // Main Content Row - Exercise info + Progress
            HStack(alignment: .center, spacing: 16) {
                // Exercise Info
                VStack(alignment: .leading, spacing: 2) {
                    Text(context.state.exerciseName)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    HStack(spacing: 4) {
                        Text("Set \(context.state.currentSet)/\(context.state.totalSets)")
                            .font(.system(size: 13))
                            .foregroundColor(.gray)
                        
                        if let weight = context.state.lastWeight, let reps = context.state.lastReps {
                            Text("•")
                                .foregroundColor(Color(hex: "48484A"))
                            Text("\(Int(weight))lb × \(reps)")
                                .font(.system(size: 12))
                                .foregroundColor(Color(hex: "8E8E93"))
                        }
                    }
                }
                
                Spacer()
                
                // Compact Progress Indicator
                if context.state.isResting {
                    VStack(spacing: 2) {
                        Text(formatRestTime(context.state.restTimeRemaining))
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(Color(hex: "64D2FF"))
                        Text("REST")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(Color(hex: "64D2FF"))
                    }
                } else {
                    ZStack {
                        Circle()
                            .stroke(Color.white.opacity(0.15), lineWidth: 3)
                        
                        Circle()
                            .trim(from: 0, to: CGFloat(context.state.totalSetsCompleted) / CGFloat(max(context.state.totalSets * 3, 1)))
                            .stroke(Color(hex: "30D158"), style: StrokeStyle(lineWidth: 3, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                        
                        Text("\(context.state.totalSetsCompleted)")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                    }
                    .frame(width: 44, height: 44)
                }
            }
            
            // Action Buttons Row - Compact
            HStack(spacing: 8) {
                // Previous Exercise Button
                Link(destination: URL(string: "gains://workout/previous")!) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 44, height: 36)
                        .background(Color.white.opacity(0.12))
                        .cornerRadius(8)
                }
                
                // Main Action Button - Complete Set or Skip Rest
                if context.state.isResting {
                    Link(destination: URL(string: "gains://workout/skiprest")!) {
                        HStack(spacing: 5) {
                            Image(systemName: "forward.fill")
                                .font(.system(size: 11))
                            Text("Skip Rest")
                                .font(.system(size: 13, weight: .bold))
                        }
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .frame(height: 36)
                        .background(Color(hex: "64D2FF"))
                        .cornerRadius(8)
                    }
                } else {
                    Link(destination: URL(string: "gains://workout/complete")!) {
                        HStack(spacing: 5) {
                            Image(systemName: "checkmark")
                                .font(.system(size: 12, weight: .bold))
                            Text("Log Set")
                                .font(.system(size: 13, weight: .bold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 36)
                        .background(Color(hex: "0A84FF"))
                        .cornerRadius(8)
                    }
                }
                
                // Next Exercise Button
                Link(destination: URL(string: "gains://workout/next")!) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 44, height: 36)
                        .background(Color.white.opacity(0.12))
                        .cornerRadius(8)
                }
                
                // End Workout Button (compact)
                Link(destination: URL(string: "gains://workout/end")!) {
                    Image(systemName: "stop.fill")
                        .font(.system(size: 11))
                        .foregroundColor(Color(hex: "FF453A"))
                        .frame(width: 44, height: 36)
                        .background(Color(hex: "FF453A").opacity(0.15))
                        .cornerRadius(8)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
    
    private func formatRestTime(_ seconds: Int) -> String {
        if seconds >= 60 {
            return "\(seconds / 60):\(String(format: "%02d", seconds % 60))"
        }
        return "\(seconds)s"
    }
    
    private func formatElapsedTime(_ interval: TimeInterval) -> String {
        let minutes = Int(interval) / 60
        let seconds = Int(interval) % 60
        return "\(minutes):\(String(format: "%02d", seconds))"
    }
}

// MARK: - Color Extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Previews
extension WorkoutActivityAttributes {
    static var preview: WorkoutActivityAttributes {
        WorkoutActivityAttributes(workoutName: "Push Day", startTime: Date())
    }
}

extension WorkoutActivityAttributes.ContentState {
    static var active: WorkoutActivityAttributes.ContentState {
        WorkoutActivityAttributes.ContentState(
            exerciseName: "Bench Press",
            currentSet: 2,
            totalSets: 4,
            lastWeight: 185,
            lastReps: 8,
            isResting: false,
            restTimeRemaining: 0,
            elapsedTime: 1234,
            totalSetsCompleted: 5
        )
    }
    
    static var resting: WorkoutActivityAttributes.ContentState {
        WorkoutActivityAttributes.ContentState(
            exerciseName: "Bench Press",
            currentSet: 3,
            totalSets: 4,
            lastWeight: 185,
            lastReps: 8,
            isResting: true,
            restTimeRemaining: 67,
            elapsedTime: 1234,
            totalSetsCompleted: 6
        )
    }
}

#Preview("Lock Screen - Active", as: .content, using: WorkoutActivityAttributes.preview) {
    WorkoutLiveActivity()
} contentStates: {
    WorkoutActivityAttributes.ContentState.active
}

#Preview("Lock Screen - Resting", as: .content, using: WorkoutActivityAttributes.preview) {
    WorkoutLiveActivity()
} contentStates: {
    WorkoutActivityAttributes.ContentState.resting
}

// Keep legacy for backwards compatibility
struct GainsWidgetsAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var emoji: String
    }
    var name: String
}

struct GainsWidgetsLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: GainsWidgetsAttributes.self) { context in
            VStack { Text("Hello \(context.state.emoji)") }
                .activityBackgroundTint(Color.cyan)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) { Text("L") }
                DynamicIslandExpandedRegion(.trailing) { Text("T") }
                DynamicIslandExpandedRegion(.bottom) { Text(context.state.emoji) }
            } compactLeading: { Text("L") } compactTrailing: { Text(context.state.emoji) } minimal: { Text(context.state.emoji) }
        }
    }
}
