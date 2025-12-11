//
//  WorkoutCalendarView.swift
//  Gains
//
//  Calendar Glow System - Full month calendar grid
//

import SwiftUI

struct WorkoutCalendarView: View {
    let days: [WorkoutDay]
    @Binding var selectedDate: Date
    let currentMonth: CalendarMonth
    let onPreviousMonth: () -> Void
    let onNextMonth: () -> Void
    
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 6), count: 7)
    private let weekdays: [(id: Int, label: String)] = [
        (0, "S"), (1, "M"), (2, "T"), (3, "W"), (4, "T"), (5, "F"), (6, "S")
    ]
    private let calendar = Calendar.current
    
    var body: some View {
        VStack(spacing: GainsDesign.spacingM) {
            // Month navigation header
            monthHeader
            
            // Weekday labels
            weekdayLabels
            
            // Calendar grid
            calendarGrid
        }
        .padding(.horizontal, GainsDesign.spacingM)
        .padding(.vertical, GainsDesign.spacingL)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.black.opacity(0.65))
                .background(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(.ultraThinMaterial.opacity(0.25))
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.white.opacity(0.06), lineWidth: 1)
        )
    }
    
    // MARK: - Month Header
    
    private var monthHeader: some View {
        HStack {
            Button(action: onPreviousMonth) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.gainsTextSecondary)
                    .frame(width: 36, height: 36)
                    .background(
                        Circle()
                            .fill(Color.white.opacity(0.05))
                    )
            }
            
            Spacer()
            
            Text(currentMonth.displayString)
                .font(.system(size: GainsDesign.headline, weight: .semibold))
                .foregroundColor(.white)
            
            Spacer()
            
            Button(action: onNextMonth) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.gainsTextSecondary)
                    .frame(width: 36, height: 36)
                    .background(
                        Circle()
                            .fill(Color.white.opacity(0.05))
                    )
            }
        }
        .padding(.horizontal, GainsDesign.spacingXS)
    }
    
    // MARK: - Weekday Labels
    
    private var weekdayLabels: some View {
        HStack(spacing: 6) {
            ForEach(weekdays, id: \.id) { weekday in
                Text(weekday.label)
                    .font(.system(size: GainsDesign.caption, weight: .medium))
                    .foregroundColor(.gainsTextTertiary)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, GainsDesign.spacingXS)
    }
    
    // MARK: - Calendar Grid
    
    private var calendarGrid: some View {
        LazyVGrid(columns: columns, spacing: 6) {
            ForEach(days) { day in
                Button {
                    withAnimation(reduceMotion ? nil : .spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedDate = day.date
                    }
                    // Haptic feedback
                    let impactLight = UIImpactFeedbackGenerator(style: .light)
                    impactLight.impactOccurred()
                } label: {
                    WorkoutDayPillView(
                        day: day,
                        isSelected: calendar.isDate(day.date, inSameDayAs: selectedDate),
                        isInDisplayedMonth: isInDisplayedMonth(day.date)
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    // MARK: - Helpers
    
    private func isInDisplayedMonth(_ date: Date) -> Bool {
        calendar.isDate(date, equalTo: currentMonth.date, toGranularity: .month)
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.gainsBgPrimary.ignoresSafeArea()
        
        WorkoutCalendarView(
            days: generatePreviewDays(),
            selectedDate: .constant(Date()),
            currentMonth: .current,
            onPreviousMonth: {},
            onNextMonth: {}
        )
        .padding(.horizontal, GainsDesign.paddingHorizontal)
    }
}

// Helper for preview
private func generatePreviewDays() -> [WorkoutDay] {
    let calendar = Calendar.current
    var days: [WorkoutDay] = []
    
    guard let monthInterval = calendar.dateInterval(of: .month, for: Date()) else { return [] }
    
    let firstWeekday = calendar.component(.weekday, from: monthInterval.start)
    let daysToSubtract = firstWeekday - calendar.firstWeekday
    guard let gridStart = calendar.date(byAdding: .day, value: -daysToSubtract, to: monthInterval.start) else { return [] }
    
    var currentDate = gridStart
    let today = calendar.startOfDay(for: Date())
    
    for i in 0..<42 {
        let state: WorkoutDayState
        let dayNumber = i % 7
        
        // Create some sample data
        if dayNumber == 1 || dayNumber == 3 || dayNumber == 5 {
            if i >= 7 && i < 21 {
                state = .streak(volumeScore: Double.random(in: 0.5...1.0), isCurrentDay: calendar.startOfDay(for: currentDate) == today)
            } else if i % 3 == 0 {
                state = .logged(volumeScore: Double.random(in: 0.3...0.8))
            } else {
                state = .empty
            }
        } else {
            state = .empty
        }
        
        days.append(WorkoutDay(date: currentDate, state: state))
        currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
    }
    
    return days
}

