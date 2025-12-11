//
//  WorkoutCalendarModels.swift
//  Gains
//
//  Created for Calendar Glow System
//

import Foundation

// MARK: - Workout Day State
/// Represents the visual state of a day in the workout calendar
enum WorkoutDayState: Equatable {
    case empty                                              // No workout logged
    case logged(volumeScore: Double)                        // Single workout day (not part of streak)
    case streak(volumeScore: Double, isCurrentDay: Bool)    // Part of 2+ consecutive days
    
    var volumeScore: Double {
        switch self {
        case .empty:
            return 0
        case .logged(let score), .streak(let score, _):
            return score
        }
    }
    
    var isStreakDay: Bool {
        if case .streak = self { return true }
        return false
    }
}

// MARK: - Workout Day
/// Represents a single day in the workout calendar
struct WorkoutDay: Identifiable, Equatable {
    let id: UUID
    let date: Date
    let state: WorkoutDayState
    let workouts: [Workout]
    
    init(date: Date, state: WorkoutDayState, workouts: [Workout] = []) {
        self.id = UUID()
        self.date = date
        self.state = state
        self.workouts = workouts
    }
    
    var dayNumber: Int {
        Calendar.current.component(.day, from: date)
    }
    
    var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }
    
    var isInCurrentMonth: Bool {
        Calendar.current.isDate(date, equalTo: Date(), toGranularity: .month)
    }
    
    // Equatable conformance (ignoring workouts array for performance)
    static func == (lhs: WorkoutDay, rhs: WorkoutDay) -> Bool {
        lhs.id == rhs.id &&
        lhs.date == rhs.date &&
        lhs.state == rhs.state
    }
}

// MARK: - Calendar Month
/// Helper struct for month navigation
struct CalendarMonth: Equatable {
    let date: Date
    
    var year: Int {
        Calendar.current.component(.year, from: date)
    }
    
    var month: Int {
        Calendar.current.component(.month, from: date)
    }
    
    var displayString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: date)
    }
    
    var shortDisplayString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM yyyy"
        return formatter.string(from: date)
    }
    
    func previous() -> CalendarMonth {
        let newDate = Calendar.current.date(byAdding: .month, value: -1, to: date) ?? date
        return CalendarMonth(date: newDate)
    }
    
    func next() -> CalendarMonth {
        let newDate = Calendar.current.date(byAdding: .month, value: 1, to: date) ?? date
        return CalendarMonth(date: newDate)
    }
    
    static var current: CalendarMonth {
        CalendarMonth(date: Date())
    }
}

