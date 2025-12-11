//
//  WorkoutViewModel.swift
//  Gains
//
//  Created by Rayaan Bokhari on 11/20/25.
//

import Foundation
import Combine
import SwiftUI

@MainActor
class WorkoutViewModel: ObservableObject {
    @Published var currentWorkout: Workout?
    @Published var workouts: [Workout] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var calendarDays: [WorkoutDay] = []
    @Published var currentMonth: CalendarMonth = .current
    
    private let workoutService = WorkoutService()
    private var cancellables = Set<AnyCancellable>()
    private let calendar = Calendar.current
    
    init() {
        // Subscribe to workoutService's workouts updates
        workoutService.$workouts
            .receive(on: DispatchQueue.main)
            .sink { [weak self] workouts in
                self?.workouts = workouts
                print("WorkoutViewModel: Received \(workouts.count) workouts from service")
            }
            .store(in: &cancellables)
    }
    
    /// Call this when the view appears to start listening
    func startListening() {
        workoutService.startListening()
    }
    
    // MARK: - Active Workout Management
    
    func startWorkout(name: String) {
        currentWorkout = Workout(name: name, date: Date())
    }
    
    func cancelWorkout() {
        currentWorkout = nil
    }
    
    func endWorkout() async {
        guard let workout = currentWorkout else {
            print("WorkoutViewModel: No current workout to save")
            return
        }
        
        print("WorkoutViewModel: Saving workout '\(workout.name)' with \(workout.exercises.count) exercises")
        
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        do {
            try await workoutService.addWorkout(workout)
            print("WorkoutViewModel: Workout saved successfully")
            currentWorkout = nil
            // Workouts will update automatically via the listener
        } catch {
            errorMessage = "Failed to save workout: \(error.localizedDescription)"
            print("WorkoutViewModel: Error saving workout: \(error)")
        }
    }
    
    // MARK: - Exercise Management
    
    func addExercise(_ exercise: Exercise) {
        currentWorkout?.exercises.append(exercise)
    }
    
    func removeExercise(at index: Int) {
        guard var workout = currentWorkout,
              index >= 0 && index < workout.exercises.count else { return }
        workout.exercises.remove(at: index)
        currentWorkout = workout
    }
    
    func moveExercise(from source: IndexSet, to destination: Int) {
        guard var workout = currentWorkout else { return }
        workout.exercises.move(fromOffsets: source, toOffset: destination)
        currentWorkout = workout
    }
    
    // MARK: - Set Management
    
    func addSet(to exerciseIndex: Int) {
        guard var workout = currentWorkout,
              exerciseIndex >= 0 && exerciseIndex < workout.exercises.count else { return }
        
        // Copy values from the last set if available
        let newSet: ExerciseSet
        if let lastSet = workout.exercises[exerciseIndex].sets.last {
            newSet = ExerciseSet(reps: lastSet.reps, weight: lastSet.weight)
        } else {
            newSet = ExerciseSet()
        }
        
        workout.exercises[exerciseIndex].sets.append(newSet)
        currentWorkout = workout
    }
    
    func removeSet(exerciseIndex: Int, setIndex: Int) {
        guard var workout = currentWorkout,
              exerciseIndex >= 0 && exerciseIndex < workout.exercises.count,
              setIndex >= 0 && setIndex < workout.exercises[exerciseIndex].sets.count else { return }
        
        workout.exercises[exerciseIndex].sets.remove(at: setIndex)
        currentWorkout = workout
    }
    
    func updateSet(exerciseIndex: Int, setIndex: Int, weight: Double?, reps: Int?) {
        guard var workout = currentWorkout,
              exerciseIndex >= 0 && exerciseIndex < workout.exercises.count,
              setIndex >= 0 && setIndex < workout.exercises[exerciseIndex].sets.count else { return }
        
        if let weight = weight {
            workout.exercises[exerciseIndex].sets[setIndex].weight = weight
        }
        if let reps = reps {
            workout.exercises[exerciseIndex].sets[setIndex].reps = reps
        }
        currentWorkout = workout
    }
    
    func toggleSetComplete(exerciseIndex: Int, setIndex: Int) {
        guard var workout = currentWorkout,
              exerciseIndex >= 0 && exerciseIndex < workout.exercises.count,
              setIndex >= 0 && setIndex < workout.exercises[exerciseIndex].sets.count else { return }
        
        workout.exercises[exerciseIndex].sets[setIndex].completed.toggle()
        currentWorkout = workout
    }
    
    // MARK: - Data Loading
    
    func loadWorkouts() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        // If listener isn't active, do a one-time fetch
        if !workoutService.isListening {
            await workoutService.loadWorkouts()
        }
        // Otherwise the listener handles updates automatically
    }
    
    /// Force refresh from Firestore (for pull-to-refresh)
    func refreshWorkouts() async {
        await workoutService.loadWorkouts()
    }
    
    func updateWorkout(_ workout: Workout) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        do {
            try await workoutService.updateWorkout(workout)
            // Workouts will update automatically via the listener
        } catch {
            errorMessage = "Failed to update workout: \(error.localizedDescription)"
            print("Error updating workout: \(error)")
        }
    }
    
    func deleteWorkout(_ workout: Workout) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        do {
            try await workoutService.deleteWorkout(workout)
            // Workouts will update automatically via the listener
        } catch {
            errorMessage = "Failed to delete workout: \(error.localizedDescription)"
            print("Error deleting workout: \(error)")
        }
    }
    
    // MARK: - Weekly Training Summary
    
    var weeklyTrainingSummary: WeeklyTrainingSummary {
        let calendar = Calendar.current
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        
        let thisWeekWorkouts = workouts.filter { $0.date >= weekAgo }
        
        // Calculate muscle groups worked
        var muscleGroups: [String: Int] = [:]
        var totalVolume: Double = 0
        var totalExercises = 0
        var totalSets = 0
        
        for workout in thisWeekWorkouts {
            for exercise in workout.exercises {
                totalExercises += 1
                for set in exercise.sets {
                    totalSets += 1
                    if let weight = set.weight, let reps = set.reps {
                        totalVolume += weight * Double(reps)
                    }
                }
                // Map exercise to muscle group (simplified)
                // You could use ExerciseTemplate's muscleGroups for accuracy
                let exerciseName = exercise.name.lowercased()
                if exerciseName.contains("chest") || exerciseName.contains("bench") || exerciseName.contains("press") {
                    muscleGroups["Chest", default: 0] += 1
                }
                if exerciseName.contains("back") || exerciseName.contains("pull") || exerciseName.contains("row") {
                    muscleGroups["Back", default: 0] += 1
                }
                if exerciseName.contains("leg") || exerciseName.contains("squat") || exerciseName.contains("deadlift") {
                    muscleGroups["Legs", default: 0] += 1
                }
                if exerciseName.contains("shoulder") || exerciseName.contains("deltoid") {
                    muscleGroups["Shoulders", default: 0] += 1
                }
                if exerciseName.contains("arm") || exerciseName.contains("bicep") || exerciseName.contains("tricep") {
                    muscleGroups["Arms", default: 0] += 1
                }
            }
        }
        
        return WeeklyTrainingSummary(
            sessionsThisWeek: thisWeekWorkouts.count,
            totalVolume: totalVolume,
            muscleGroupsWorked: muscleGroups,
            lastWorkout: workouts.first,
            averageExercisesPerSession: thisWeekWorkouts.isEmpty ? 0 : Double(totalExercises) / Double(thisWeekWorkouts.count),
            averageSetsPerSession: thisWeekWorkouts.isEmpty ? 0 : Double(totalSets) / Double(thisWeekWorkouts.count)
        )
    }
    
    // MARK: - Calendar & Streak System
    
    /// Get unique days when workouts were logged (not count of workouts)
    private var uniqueWorkoutDays: Set<Date> {
        Set(workouts.map { calendar.startOfDay(for: $0.date) })
    }
    
    /// Current workout streak (consecutive DAYS with workouts, counting back from today/yesterday)
    var currentWorkoutStreak: Int {
        let uniqueDays = uniqueWorkoutDays
        guard !uniqueDays.isEmpty else { return 0 }
        
        let today = calendar.startOfDay(for: Date())
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
        
        // Streak only counts if we worked out today or yesterday
        // If last workout was 2+ days ago, streak is broken
        var checkDate: Date
        if uniqueDays.contains(today) {
            checkDate = today
        } else if uniqueDays.contains(yesterday) {
            checkDate = yesterday
        } else {
            // No workout today or yesterday = streak is 0
            return 0
        }
        
        // Count consecutive days going backwards
        var streak = 0
        while uniqueDays.contains(checkDate) {
            streak += 1
            checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate)!
        }
        
        return streak
    }
    
    /// Longest workout streak ever achieved
    var longestWorkoutStreak: Int {
        let uniqueDays = Array(uniqueWorkoutDays).sorted()
        guard uniqueDays.count >= 1 else { return 0 }
        guard uniqueDays.count >= 2 else { return 1 }
        
        var maxStreak = 1
        var currentStreak = 1
        
        for i in 1..<uniqueDays.count {
            let daysDiff = calendar.dateComponents([.day], from: uniqueDays[i-1], to: uniqueDays[i]).day ?? 0
            if daysDiff == 1 {
                currentStreak += 1
                maxStreak = max(maxStreak, currentStreak)
            } else {
                currentStreak = 1
            }
        }
        
        return maxStreak
    }
    
    /// Number of unique DAYS with workouts this month (not total workout count)
    var workoutDaysThisMonth: Int {
        uniqueWorkoutDays.filter { calendar.isDate($0, equalTo: Date(), toGranularity: .month) }.count
    }
    
    /// Total workouts in current month (can be multiple per day)
    var workoutsThisMonth: Int {
        workouts.filter { calendar.isDate($0.date, equalTo: Date(), toGranularity: .month) }.count
    }
    
    /// Navigate to previous month
    func previousMonth() {
        currentMonth = currentMonth.previous()
        rebuildCalendarDays()
    }
    
    /// Navigate to next month
    func nextMonth() {
        currentMonth = currentMonth.next()
        rebuildCalendarDays()
    }
    
    /// Navigate to current month
    func goToCurrentMonth() {
        currentMonth = .current
        rebuildCalendarDays()
    }
    
    /// Rebuild calendar days when workouts or month changes
    func rebuildCalendarDays() {
        calendarDays = buildWorkoutDays(for: currentMonth.date)
    }
    
    /// Build workout days for a given month
    func buildWorkoutDays(for month: Date) -> [WorkoutDay] {
        // Get start and end of month
        guard let monthInterval = calendar.dateInterval(of: .month, for: month) else {
            return []
        }
        
        // Get the first day of the week containing the month start
        let firstWeekday = calendar.component(.weekday, from: monthInterval.start)
        let daysToSubtract = firstWeekday - calendar.firstWeekday
        guard let gridStart = calendar.date(byAdding: .day, value: -daysToSubtract, to: monthInterval.start) else {
            return []
        }
        
        // Group workouts by day
        var workoutsByDay: [Date: [Workout]] = [:]
        for workout in workouts {
            let dayStart = calendar.startOfDay(for: workout.date)
            workoutsByDay[dayStart, default: []].append(workout)
        }
        
        // Calculate max volume for normalization
        let maxVolume = calculateMaxDailyVolume(workoutsByDay: workoutsByDay)
        
        // Detect streak days (2+ consecutive workout days)
        let streakDays = detectStreakDays()
        
        // Build 6 weeks (42 days) of calendar
        var days: [WorkoutDay] = []
        var currentDate = gridStart
        let today = calendar.startOfDay(for: Date())
        
        for _ in 0..<42 {
            let dayStart = calendar.startOfDay(for: currentDate)
            let dayWorkouts = workoutsByDay[dayStart] ?? []
            let volumeScore = calculateVolumeScore(for: dayWorkouts, maxVolume: maxVolume)
            let isCurrentDay = dayStart == today
            
            let state: WorkoutDayState
            if dayWorkouts.isEmpty {
                state = .empty
            } else if streakDays.contains(dayStart) {
                state = .streak(volumeScore: volumeScore, isCurrentDay: isCurrentDay)
            } else {
                state = .logged(volumeScore: volumeScore)
            }
            
            days.append(WorkoutDay(date: currentDate, state: state, workouts: dayWorkouts))
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? currentDate
        }
        
        return days
    }
    
    /// Detect days that are part of a streak (2+ consecutive workout days)
    private func detectStreakDays() -> Set<Date> {
        let workoutDates = workouts.map { calendar.startOfDay(for: $0.date) }
        let uniqueDates = Array(Set(workoutDates)).sorted()
        
        guard uniqueDates.count >= 2 else { return [] }
        
        var streakDays: Set<Date> = []
        var currentRun: [Date] = [uniqueDates[0]]
        
        for i in 1..<uniqueDates.count {
            let daysDiff = calendar.dateComponents([.day], from: uniqueDates[i-1], to: uniqueDates[i]).day ?? 0
            
            if daysDiff == 1 {
                currentRun.append(uniqueDates[i])
            } else {
                // End of run - add to streakDays if 2+ consecutive
                if currentRun.count >= 2 {
                    streakDays.formUnion(currentRun)
                }
                currentRun = [uniqueDates[i]]
            }
        }
        
        // Don't forget the last run
        if currentRun.count >= 2 {
            streakDays.formUnion(currentRun)
        }
        
        return streakDays
    }
    
    /// Calculate volume score for a day's workouts (normalized 0-1)
    private func calculateVolumeScore(for workouts: [Workout], maxVolume: Double) -> Double {
        guard maxVolume > 0 else { return 0 }
        
        var totalVolume: Double = 0
        for workout in workouts {
            for exercise in workout.exercises {
                for set in exercise.sets {
                    if let weight = set.weight, let reps = set.reps {
                        totalVolume += weight * Double(reps)
                    } else if let reps = set.reps {
                        // Bodyweight exercise - count reps as volume
                        totalVolume += Double(reps) * 10
                    }
                }
            }
        }
        
        return min(1.0, totalVolume / maxVolume)
    }
    
    /// Calculate max daily volume for normalization
    private func calculateMaxDailyVolume(workoutsByDay: [Date: [Workout]]) -> Double {
        var maxVolume: Double = 0
        
        for (_, dayWorkouts) in workoutsByDay {
            var dayVolume: Double = 0
            for workout in dayWorkouts {
                for exercise in workout.exercises {
                    for set in exercise.sets {
                        if let weight = set.weight, let reps = set.reps {
                            dayVolume += weight * Double(reps)
                        } else if let reps = set.reps {
                            dayVolume += Double(reps) * 10
                        }
                    }
                }
            }
            maxVolume = max(maxVolume, dayVolume)
        }
        
        return maxVolume > 0 ? maxVolume : 1000 // Default to prevent division by zero
    }
    
    /// Get workouts for a specific date
    func workouts(for date: Date) -> [Workout] {
        let dayStart = calendar.startOfDay(for: date)
        return workouts.filter { calendar.startOfDay(for: $0.date) == dayStart }
    }
}

