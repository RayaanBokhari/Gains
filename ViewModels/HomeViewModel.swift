//
//  HomeViewModel.swift
//  Gains
//
//  Created by Rayaan Bokhari on 11/20/25.
//

import Foundation
import SwiftUI
import Combine
import FirebaseAuth

@MainActor
final class HomeViewModel: ObservableObject {
    @Published var dailyLog: DailyLog = DailyLog()
    @Published var recentFoods: [Food] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var selectedDate: Date = Date()
    
    // Computed properties to bridge DailyLog to DailyNutrition format for UI
    var dailyNutrition: DailyNutrition {
        var nutrition = DailyNutrition()
        nutrition.caloriesConsumed = dailyLog.calories
        nutrition.proteinConsumed = Double(dailyLog.protein)
        nutrition.carbsConsumed = Double(dailyLog.carbs)
        nutrition.fatsConsumed = Double(dailyLog.fats)
        nutrition.waterConsumed = Double(dailyLog.waterOunces)
        nutrition.foods = recentFoods
        return nutrition
    }
    
    private let firestore = FirestoreService.shared
    private let auth = AuthService.shared
    
    func loadTodayIfPossible() async {
        selectedDate = Date()
        await loadDate(Date())
    }
    
    func addCalories(_ amount: Int) async {
        guard let user = auth.user else { return }
        
        dailyLog.calories += amount
        
        do {
            try await firestore.saveDailyLog(userId: user.uid, log: dailyLog)
        } catch {
            errorMessage = "Failed to save: \(error.localizedDescription)"
            print("Failed to save daily log: \(error)")
        }
    }
    
    func addMacros(protein: Int, carbs: Int, fats: Int) async {
        guard let user = auth.user else { return }
        
        dailyLog.protein += protein
        dailyLog.carbs += carbs
        dailyLog.fats += fats
        
        do {
            try await firestore.saveDailyLog(userId: user.uid, log: dailyLog)
        } catch {
            errorMessage = "Failed to save: \(error.localizedDescription)"
            print("Failed to save daily log: \(error)")
        }
    }
    
    func addWater(_ ounces: Int) async {
        guard let user = auth.user else { return }
        
        dailyLog.waterOunces += ounces
        
        do {
            try await firestore.saveDailyLog(userId: user.uid, log: dailyLog)
        } catch {
            errorMessage = "Failed to save: \(error.localizedDescription)"
            print("Failed to save daily log: \(error)")
        }
    }
    
    func logFood(_ food: Food) async {
        guard let user = auth.user else { return }
        
        do {
            try await firestore.saveMeal(userId: user.uid, food: food, toDate: selectedDate)
            
            // Update streaks and achievements
            await updateStreaksAndAchievements(userId: user.uid)
            
            // Refresh to get updated values
            await loadDate(selectedDate)
        } catch {
            errorMessage = "Failed to log food: \(error.localizedDescription)"
            print("Failed to log food: \(error)")
        }
    }
    
    private func updateStreaksAndAchievements(userId: String) async {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        // Fetch current streak
        var streak = (try? await firestore.fetchStreak(userId: userId)) ?? Streak()
        
        // Check if user logged today
        if let lastLogged = streak.lastLoggedDate {
            let lastLoggedDay = calendar.startOfDay(for: lastLogged)
            let daysSince = calendar.dateComponents([.day], from: lastLoggedDay, to: today).day ?? 0
            
            if daysSince == 0 {
                // Already logged today, no change
            } else if daysSince == 1 {
                // Consecutive day
                streak.currentStreak += 1
                streak.longestStreak = max(streak.longestStreak, streak.currentStreak)
            } else {
                // Streak broken
                streak.currentStreak = 1
            }
        } else {
            // First time logging
            streak.currentStreak = 1
            streak.longestStreak = 1
        }
        
        streak.lastLoggedDate = Date()
        
        // Save streak
        do {
            try await firestore.updateStreak(userId: userId, streak: streak)
        } catch {
            print("Error updating streak: \(error)")
        }
        
        // Update achievements
        await updateAchievements(userId: userId, streak: streak)
    }
    
    private func updateAchievements(userId: String, streak: Streak) async {
        var achievements = (try? await firestore.fetchAchievements(userId: userId)) ?? []
        let allAchievements = Achievement.allAchievements()
        
        // Create a dictionary of existing achievements
        var achievementDict: [String: Achievement] = [:]
        for achievement in achievements {
            achievementDict[achievement.id] = achievement
        }
        
        // Check each achievement
        for var achievement in allAchievements {
            if let existing = achievementDict[achievement.id] {
                achievement = existing
            }
            
            var shouldUpdate = false
            
            switch achievement.id {
            case "first_meal":
                if achievement.unlockedAt == nil {
                    achievement.unlockedAt = Date()
                    achievement.progress = 1.0
                    shouldUpdate = true
                }
                
            case "week_warrior":
                if achievement.unlockedAt == nil && streak.currentStreak >= 7 {
                    achievement.unlockedAt = Date()
                    achievement.progress = 1.0
                    shouldUpdate = true
                } else if achievement.unlockedAt == nil {
                    achievement.progress = min(1.0, Double(streak.currentStreak) / 7.0)
                    shouldUpdate = true
                }
                
            case "month_master":
                if achievement.unlockedAt == nil && streak.currentStreak >= 30 {
                    achievement.unlockedAt = Date()
                    achievement.progress = 1.0
                    shouldUpdate = true
                } else if achievement.unlockedAt == nil {
                    achievement.progress = min(1.0, Double(streak.currentStreak) / 30.0)
                    shouldUpdate = true
                }
                
            case "centurion":
                // This would need meal count, simplified for now
                // Could fetch meal count from daily logs
                break
                
            case "macro_master":
                // This would need to check daily logs for macro completion
                // Simplified for now
                break
                
            default:
                break
            }
            
            if shouldUpdate {
                do {
                    try await firestore.updateAchievement(userId: userId, achievement: achievement)
                } catch {
                    print("Error updating achievement: \(error)")
                }
            }
        }
    }
    
    func loadDate(_ date: Date) async {
        selectedDate = date
        guard let user = auth.user else {
            print("No user signed in yet")
            return
        }
        
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        do {
            if let existing = try await firestore.fetchDailyLog(userId: user.uid, for: date) {
                dailyLog = existing
            } else {
                // No log yet, start with a fresh one
                var newLog = DailyLog()
                newLog.id = FirestoreService.id(for: date)
                newLog.date = date
                dailyLog = newLog
                // Only save if it's today or past (don't create future logs)
                if date <= Date() {
                    try await firestore.saveDailyLog(userId: user.uid, log: newLog)
                }
            }
            
            // Load meals for the selected date
            recentFoods = try await firestore.fetchMeals(userId: user.uid, for: date)
        } catch {
            errorMessage = "Failed to load log: \(error.localizedDescription)"
            print("Error loading log: \(error)")
        }
    }
    
    func editMeal(_ updatedFood: Food) async {
        guard let user = auth.user,
              let mealId = updatedFood.mealId else {
            errorMessage = "Cannot edit meal: missing meal ID"
            return
        }
        
        // Find the old food object to calculate differences
        guard let oldFood = recentFoods.first(where: { $0.mealId == mealId }) else {
            errorMessage = "Cannot find meal to edit"
            return
        }
        
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        do {
            try await firestore.updateMeal(
                userId: user.uid,
                mealId: mealId,
                food: updatedFood,
                oldFood: oldFood,
                toDate: selectedDate
            )
            
            // Refresh to get updated values
            await loadDate(selectedDate)
        } catch {
            errorMessage = "Failed to update meal: \(error.localizedDescription)"
            print("Failed to update meal: \(error)")
        }
    }
    
    func deleteMeal(_ food: Food) async {
        guard let user = auth.user,
              let mealId = food.mealId else {
            errorMessage = "Cannot delete meal: missing meal ID"
            return
        }
        
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        do {
            // Delete photo from Storage if it exists
            if let photoUrl = food.photoUrl {
                try? await StorageService.shared.deletePhoto(from: photoUrl)
            }
            
            try await firestore.deleteMeal(
                userId: user.uid,
                mealId: mealId,
                food: food,
                fromDate: selectedDate
            )
            
            // Refresh to get updated values
            await loadDate(selectedDate)
        } catch {
            errorMessage = "Failed to delete meal: \(error.localizedDescription)"
            print("Failed to delete meal: \(error)")
        }
    }
    
    func refreshMeals() async {
        await loadDate(selectedDate)
    }
    
    func goToPreviousDay() async {
        let calendar = Calendar.current
        if let previousDay = calendar.date(byAdding: .day, value: -1, to: selectedDate) {
            await loadDate(previousDay)
        }
    }
    
    func goToNextDay() async {
        let calendar = Calendar.current
        // Don't allow going to future dates
        guard !calendar.isDateInToday(selectedDate) else { return }
        
        if let nextDay = calendar.date(byAdding: .day, value: 1, to: selectedDate),
           nextDay <= Date() {
            await loadDate(nextDay)
        }
    }
    
    // MARK: - Weekly Nutrition Summary
    
    func calculateWeeklySummary() async -> WeeklyNutritionSummary? {
        guard let user = auth.user else { return nil }
        
        let calendar = Calendar.current
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        
        do {
            let logs = try await firestore.fetchDailyLogsRange(userId: user.uid, from: weekAgo, to: Date())
            
            guard !logs.isEmpty else { return nil }
            
            let totalCalories = logs.reduce(0) { $0 + $1.calories }
            let totalProtein = logs.reduce(0.0) { $0 + Double($1.protein) }
            let totalCarbs = logs.reduce(0.0) { $0 + Double($1.carbs) }
            let totalFats = logs.reduce(0.0) { $0 + Double($1.fats) }
            
            let avgCalories = Double(totalCalories) / Double(logs.count)
            let avgProtein = totalProtein / Double(logs.count)
            let avgCarbs = totalCarbs / Double(logs.count)
            let avgFats = totalFats / Double(logs.count)
            
            // Get goals from profile
            let profile = try? await firestore.fetchUserProfile(userId: user.uid)
            let calorieGoal = Double(profile?.dailyCaloriesGoal ?? 2460)
            let proteinGoal = profile?.macros.protein ?? 450
            
            // Calculate days on target (within ±10%)
            let daysOnCalorieTarget = logs.filter { log in
                let accuracy = Double(log.calories) / calorieGoal
                return accuracy >= 0.9 && accuracy <= 1.1
            }.count
            
            let daysOnProteinTarget = logs.filter { log in
                let accuracy = Double(log.protein) / proteinGoal
                return accuracy >= 0.9 && accuracy <= 1.1
            }.count
            
            // Get streak
            let streak = (try? await firestore.fetchStreak(userId: user.uid)) ?? Streak()
            
            return WeeklyNutritionSummary(
                avgCalories: avgCalories,
                avgProtein: avgProtein,
                avgCarbs: avgCarbs,
                avgFats: avgFats,
                calorieGoal: calorieGoal,
                proteinGoal: proteinGoal,
                daysLogged: logs.count,
                daysOnCalorieTarget: daysOnCalorieTarget,
                daysOnProteinTarget: daysOnProteinTarget,
                loggingStreak: streak.currentStreak
            )
        } catch {
            print("Error calculating weekly summary: \(error)")
            return nil
        }
    }
}

