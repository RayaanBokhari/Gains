//
//  WorkoutDayPillView.swift
//  Gains
//
//  Calendar Glow System - Individual day pill component
//

import SwiftUI

struct WorkoutDayPillView: View {
    let day: WorkoutDay
    let isSelected: Bool
    let isInDisplayedMonth: Bool
    
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    private var dayNumber: String {
        "\(day.dayNumber)"
    }
    
    var body: some View {
        VStack(spacing: 4) {
            Text(dayNumber)
                .font(.system(size: GainsDesign.footnote, weight: .semibold))
                .foregroundStyle(foregroundColor)
            
            volumeIndicator
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .padding(.horizontal, 4)
        .background(backgroundView)
        .overlay(innerStroke)
        .overlay(selectionRing)
        .scaleEffect(scale)
        .shadow(color: outerGlowColor, radius: outerGlowRadius, x: 0, y: 0)
        .animation(reduceMotion ? nil : .spring(response: 0.28, dampingFraction: 0.8), value: isSelected)
        .opacity(isInDisplayedMonth ? 1.0 : 0.3)
        .accessibilityLabel(accessibilityLabel)
    }
    
    // MARK: - Subviews
    
    @ViewBuilder
    private var volumeIndicator: some View {
        switch day.state {
        case .empty:
            Spacer()
                .frame(height: 3)
        case .logged(let volume), .streak(let volume, _):
            let width: CGFloat = 8 + CGFloat(volume) * 18 // 0...1 -> 8...26
            RoundedRectangle(cornerRadius: 999)
                .fill(volumeBarColor)
                .frame(width: width, height: 3)
                .shadow(color: volumeBarShadow, radius: 2, x: 0, y: 0)
        }
    }
    
    @ViewBuilder
    private var backgroundView: some View {
        ZStack {
            // Base dark layer
            RoundedRectangle(cornerRadius: GainsDesign.cornerRadiusSmall, style: .continuous)
                .fill(Color.black.opacity(0.45))
            
            // State-specific overlay
            switch day.state {
            case .empty:
                RoundedRectangle(cornerRadius: GainsDesign.cornerRadiusSmall, style: .continuous)
                    .fill(Color.white.opacity(0.03))
                
            case .logged:
                RoundedRectangle(cornerRadius: GainsDesign.cornerRadiusSmall, style: .continuous)
                    .fill(Color.gainsCardSurface)
                // Subtle inner glow
                RoundedRectangle(cornerRadius: GainsDesign.cornerRadiusSmall, style: .continuous)
                    .fill(
                        RadialGradient(
                            colors: [Color.gainsPrimary.opacity(0.15), Color.clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: 30
                        )
                    )
                
            case .streak:
                // Gradient background for streak days
                RoundedRectangle(cornerRadius: GainsDesign.cornerRadiusSmall, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color.gainsPrimary, Color.indigo],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .opacity(0.7)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: GainsDesign.cornerRadiusSmall, style: .continuous)
                .fill(.ultraThinMaterial.opacity(0.25))
        )
    }
    
    private var innerStroke: some View {
        RoundedRectangle(cornerRadius: GainsDesign.cornerRadiusSmall, style: .continuous)
            .stroke(innerStrokeColor, lineWidth: 1)
    }
    
    @ViewBuilder
    private var selectionRing: some View {
        if isSelected {
            RoundedRectangle(cornerRadius: GainsDesign.cornerRadiusSmall, style: .continuous)
                .stroke(Color.white.opacity(0.6), lineWidth: 2)
        }
    }
    
    // MARK: - Styling Properties
    
    private var foregroundColor: Color {
        switch day.state {
        case .empty:
            return Color.white.opacity(isInDisplayedMonth ? 0.35 : 0.2)
        default:
            return .white
        }
    }
    
    private var innerStrokeColor: Color {
        switch day.state {
        case .empty:
            return Color.white.opacity(0.05)
        case .logged:
            return Color.gainsPrimary.opacity(0.4)
        case .streak:
            return Color.white.opacity(0.18)
        }
    }
    
    private var outerGlowColor: Color {
        switch day.state {
        case .streak:
            return Color.gainsAccentOrange.opacity(0.55)
        default:
            return .clear
        }
    }
    
    private var outerGlowRadius: CGFloat {
        switch day.state {
        case .streak:
            return 16
        default:
            return 0
        }
    }
    
    private var volumeBarColor: Color {
        switch day.state {
        case .empty:
            return .clear
        case .logged:
            return Color.gainsAccentOrange.opacity(0.6)
        case .streak:
            return Color.gainsAccentOrange
        }
    }
    
    private var volumeBarShadow: Color {
        switch day.state {
        case .streak:
            return Color.gainsAccentOrange.opacity(0.4)
        default:
            return .clear
        }
    }
    
    private var scale: CGFloat {
        if isSelected {
            return 1.08
        }
        switch day.state {
        case .streak(_, let isCurrentDay) where isCurrentDay:
            return 1.05
        default:
            return 1.0
        }
    }
    
    private var accessibilityLabel: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        let dateString = formatter.string(from: day.date)
        
        switch day.state {
        case .empty:
            return "\(dateString), no workout"
        case .logged:
            let count = day.workouts.count
            return "\(dateString), \(count) workout\(count == 1 ? "" : "s")"
        case .streak:
            let count = day.workouts.count
            return "\(dateString), streak day, \(count) workout\(count == 1 ? "" : "s")"
        }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.gainsBgPrimary.ignoresSafeArea()
        
        VStack(spacing: 20) {
            Text("Day Pill States")
                .font(.headline)
                .foregroundColor(.white)
            
            HStack(spacing: 12) {
                // Empty state
                WorkoutDayPillView(
                    day: WorkoutDay(date: Date(), state: .empty),
                    isSelected: false,
                    isInDisplayedMonth: true
                )
                .frame(width: 44)
                
                // Logged state
                WorkoutDayPillView(
                    day: WorkoutDay(date: Date(), state: .logged(volumeScore: 0.5)),
                    isSelected: false,
                    isInDisplayedMonth: true
                )
                .frame(width: 44)
                
                // Streak state
                WorkoutDayPillView(
                    day: WorkoutDay(date: Date(), state: .streak(volumeScore: 0.8, isCurrentDay: false)),
                    isSelected: false,
                    isInDisplayedMonth: true
                )
                .frame(width: 44)
                
                // Streak + Today
                WorkoutDayPillView(
                    day: WorkoutDay(date: Date(), state: .streak(volumeScore: 1.0, isCurrentDay: true)),
                    isSelected: true,
                    isInDisplayedMonth: true
                )
                .frame(width: 44)
            }
        }
        .padding()
    }
}

