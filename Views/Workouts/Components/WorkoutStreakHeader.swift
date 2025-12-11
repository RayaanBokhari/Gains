//
//  WorkoutStreakHeader.swift
//  Gains
//
//  Calendar Glow System - Streak summary header card
//

import SwiftUI

struct WorkoutStreakHeader: View {
    let currentStreak: Int
    let longestStreak: Int
    let workoutDaysThisMonth: Int
    
    @State private var isAnimating = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    private var hasActiveStreak: Bool {
        currentStreak > 0
    }
    
    var body: some View {
        HStack(spacing: GainsDesign.spacingL) {
            // Flame icon with glow
            flameIcon
            
            // Current streak
            VStack(alignment: .leading, spacing: 2) {
                Text("Current Streak")
                    .font(.system(size: GainsDesign.footnote))
                    .foregroundColor(.gainsTextSecondary)
                
                HStack(alignment: .lastTextBaseline, spacing: 4) {
                    Text("\(currentStreak)")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(
                            hasActiveStreak
                                ? AnyShapeStyle(Color.gainsFlameGradient)
                                : AnyShapeStyle(Color.gainsTextTertiary)
                        )
                        .contentTransition(.numericText())
                    
                    Text("days")
                        .font(.system(size: GainsDesign.subheadline, weight: .medium))
                        .foregroundColor(.gainsTextSecondary)
                }
            }
            
            Spacer()
            
            // Stats badges
            HStack(spacing: GainsDesign.spacingS) {
                // Best streak
                statBadge(title: "Best", value: "\(longestStreak)")
                
                // Unique workout days this month
                statBadge(title: "Days", value: "\(workoutDaysThisMonth)")
            }
        }
        .padding(GainsDesign.spacingL)
        .background(
            RoundedRectangle(cornerRadius: GainsDesign.cornerRadiusMedium, style: .continuous)
                .fill(Color.gainsCardSurface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: GainsDesign.cornerRadiusMedium, style: .continuous)
                .stroke(
                    hasActiveStreak
                        ? Color.gainsAccentOrange.opacity(0.2)
                        : Color.white.opacity(0.04),
                    lineWidth: 1
                )
        )
        .shadow(
            color: hasActiveStreak ? Color.gainsAccentOrange.opacity(0.15) : .clear,
            radius: 16,
            x: 0,
            y: 4
        )
        .onAppear {
            if !reduceMotion && hasActiveStreak {
                withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                    isAnimating = true
                }
            }
        }
    }
    
    // MARK: - Flame Icon
    
    private var flameIcon: some View {
        ZStack {
            // Glow circle behind flame
            if hasActiveStreak {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                Color.gainsAccentOrange.opacity(isAnimating ? 0.3 : 0.2),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 0,
                            endRadius: 30
                        )
                    )
                    .frame(width: 60, height: 60)
            }
            
            // Icon background
            Circle()
                .fill(
                    hasActiveStreak
                        ? Color.gainsAccentOrange.opacity(0.15)
                        : Color.gainsBgTertiary
                )
                .frame(width: 50, height: 50)
            
            // Flame icon
            Image(systemName: hasActiveStreak ? "flame.fill" : "flame")
                .font(.system(size: 24, weight: .medium))
                .foregroundStyle(
                    hasActiveStreak
                        ? AnyShapeStyle(Color.gainsFlameGradient)
                        : AnyShapeStyle(Color.gainsTextTertiary)
                )
                .scaleEffect(isAnimating && hasActiveStreak ? 1.1 : 1.0)
        }
    }
    
    // MARK: - Stat Badge
    
    private func statBadge(title: String, value: String) -> some View {
        VStack(alignment: .center, spacing: 2) {
            Text(title)
                .font(.system(size: GainsDesign.captionSmall))
                .foregroundColor(.gainsTextMuted)
            
            Text(value)
                .font(.system(size: GainsDesign.headline, weight: .semibold))
                .foregroundColor(.gainsTextSecondary)
        }
        .padding(.horizontal, GainsDesign.spacingM)
        .padding(.vertical, GainsDesign.spacingS)
        .background(
            RoundedRectangle(cornerRadius: GainsDesign.cornerRadiusXS)
                .fill(Color.gainsBgTertiary)
        )
    }
}

// MARK: - Compact Variant

struct WorkoutStreakHeaderCompact: View {
    let currentStreak: Int
    let longestStreak: Int
    
    private var hasActiveStreak: Bool {
        currentStreak > 0
    }
    
    var body: some View {
        HStack(spacing: GainsDesign.spacingM) {
            // Flame
            Image(systemName: hasActiveStreak ? "flame.fill" : "flame")
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(
                    hasActiveStreak
                        ? AnyShapeStyle(Color.gainsFlameGradient)
                        : AnyShapeStyle(Color.gainsTextTertiary)
                )
            
            // Streak count
            HStack(spacing: 4) {
                Text("\(currentStreak)")
                    .font(.system(size: GainsDesign.body, weight: .bold))
                    .foregroundStyle(
                        hasActiveStreak
                            ? AnyShapeStyle(Color.gainsFlameGradient)
                            : AnyShapeStyle(Color.gainsTextTertiary)
                    )
                
                Text("day streak")
                    .font(.system(size: GainsDesign.footnote))
                    .foregroundColor(.gainsTextSecondary)
            }
            
            Spacer()
            
            // Best badge
            if longestStreak > currentStreak {
                HStack(spacing: 4) {
                    Text("Best:")
                        .font(.system(size: GainsDesign.caption))
                        .foregroundColor(.gainsTextMuted)
                    
                    Text("\(longestStreak)")
                        .font(.system(size: GainsDesign.footnote, weight: .semibold))
                        .foregroundColor(.gainsTextSecondary)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(Color.gainsBgTertiary)
                )
            }
        }
        .padding(.horizontal, GainsDesign.spacingL)
        .padding(.vertical, GainsDesign.spacingM)
        .background(
            RoundedRectangle(cornerRadius: GainsDesign.cornerRadiusSmall, style: .continuous)
                .fill(Color.gainsCardSurface)
        )
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.gainsBgPrimary.ignoresSafeArea()
        
        VStack(spacing: 20) {
            Text("Streak Headers")
                .font(.headline)
                .foregroundColor(.white)
            
            // Active streak
            WorkoutStreakHeader(
                currentStreak: 5,
                longestStreak: 12,
                workoutDaysThisMonth: 8
            )
            .padding(.horizontal, GainsDesign.paddingHorizontal)
            
            // No streak
            WorkoutStreakHeader(
                currentStreak: 0,
                longestStreak: 12,
                workoutDaysThisMonth: 3
            )
            .padding(.horizontal, GainsDesign.paddingHorizontal)
            
            // Compact variant
            WorkoutStreakHeaderCompact(
                currentStreak: 4,
                longestStreak: 8
            )
            .padding(.horizontal, GainsDesign.paddingHorizontal)
        }
    }
}

