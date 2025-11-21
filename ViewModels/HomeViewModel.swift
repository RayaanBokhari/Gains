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
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    // Computed properties to bridge DailyLog to DailyNutrition format for UI
    var dailyNutrition: DailyNutrition {
        var nutrition = DailyNutrition()
        nutrition.caloriesConsumed = dailyLog.calories
        nutrition.proteinConsumed = Double(dailyLog.protein)
        nutrition.carbsConsumed = Double(dailyLog.carbs)
        nutrition.fatsConsumed = Double(dailyLog.fats)
        nutrition.waterConsumed = Double(dailyLog.waterOunces)
        return nutrition
    }
    
    private let firestore = FirestoreService.shared
    private let auth = AuthService.shared
    
    func loadTodayIfPossible() async {
        guard let user = auth.user else {
            print("No user signed in yet")
            return
        }
        
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        do {
            if let existing = try await firestore.fetchDailyLog(userId: user.uid, for: Date()) {
                dailyLog = existing
            } else {
                // No log yet, start with a fresh one
                var newLog = DailyLog()
                newLog.id = FirestoreService.todayId()
                dailyLog = newLog
                try await firestore.saveDailyLog(userId: user.uid, log: newLog)
            }
        } catch {
            errorMessage = "Failed to load today's log: \(error.localizedDescription)"
            print("Error loading today's log: \(error)")
        }
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
}

