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
            
            // Refresh to get updated values
            await loadDate(selectedDate)
        } catch {
            errorMessage = "Failed to log food: \(error.localizedDescription)"
            print("Failed to log food: \(error)")
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
}

