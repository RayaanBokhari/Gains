//
//  ProgressViewModel.swift
//  Gains
//
//  Created by Rayaan Bokhari on 11/21/25.
//

import Foundation
import SwiftUI
import Combine
import FirebaseAuth

enum TimeRange: String, CaseIterable {
    case week = "7 Days"
    case month = "30 Days"
    case quarter = "90 Days"
    case allTime = "All Time"
    
    var days: Int? {
        switch self {
        case .week: return 7
        case .month: return 30
        case .quarter: return 90
        case .allTime: return nil
        }
    }
}

@MainActor
class ProgressViewModel: ObservableObject {
    @Published var dailyLogs: [DailyLog] = []
    @Published var weightEntries: [WeightEntry] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var selectedRange: TimeRange = .month
    @Published var profile: UserProfile?
    
    private let firestore = FirestoreService.shared
    private let auth = AuthService.shared
    
    func loadProgress() async {
        guard let user = auth.user else { return }
        
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        let endDate = Date()
        let startDate: Date
        
        if let days = selectedRange.days {
            startDate = Calendar.current.date(byAdding: .day, value: -days, to: endDate) ?? endDate
        } else {
            // All time - go back 1 year
            startDate = Calendar.current.date(byAdding: .year, value: -1, to: endDate) ?? endDate
        }
        
        do {
            dailyLogs = try await firestore.fetchDailyLogsRange(
                userId: user.uid,
                from: startDate,
                to: endDate
            )
            
            // Load weight entries
            await loadWeightEntries()
            
            // Load profile for unit preferences
            if profile == nil {
                profile = try await firestore.fetchUserProfile(userId: user.uid)
            }
        } catch {
            errorMessage = "Failed to load progress: \(error.localizedDescription)"
            print("Error loading progress: \(error)")
        }
    }
    
    func loadWeightEntries() async {
        guard let user = auth.user else { return }
        
        do {
            weightEntries = try await firestore.fetchWeightEntries(userId: user.uid, limit: 90)
        } catch {
            print("Error loading weight entries: \(error)")
        }
    }
    
    func logWeight(_ weight: Double, notes: String? = nil) async {
        guard let user = auth.user else { return }
        
        // Convert weight to kg if needed (weight entries are stored in kg)
        let weightInKg: Double
        if let useMetric = profile?.useMetricUnits, !useMetric {
            // Convert lbs to kg
            weightInKg = weight * 0.453592
        } else {
            weightInKg = weight
        }
        
        let today = Date()
        
        do {
            // Check if there's already an entry for today
            if let existingEntry = try await firestore.findWeightEntryForDate(userId: user.uid, date: today) {
                // Update existing entry
                var updatedEntry = existingEntry
                updatedEntry.weight = weightInKg
                updatedEntry.notes = notes ?? existingEntry.notes
                updatedEntry.date = today // Update to current time
                
                try await firestore.saveWeightEntry(userId: user.uid, entry: updatedEntry)
                print("✅ Updated existing weight entry for today")
            } else {
                // Create new entry
                let entry = WeightEntry(weight: weightInKg, date: today, notes: notes)
                try await firestore.saveWeightEntry(userId: user.uid, entry: entry)
                print("✅ Created new weight entry for today")
            }
            
            // Update profile weight
            await updateProfileWeight(weight)
            
            // Sync to HealthKit if enabled
            if HealthKitService.shared.syncEnabled {
                try? await HealthKitService.shared.saveWeight(weightInKg)
            }
            
            await loadWeightEntries()
        } catch {
            errorMessage = "Failed to save weight: \(error.localizedDescription)"
            print("Error saving weight: \(error)")
        }
    }
    
    private func updateProfileWeight(_ weight: Double) async {
        guard let user = auth.user else { return }
        
        // Load profile if not already loaded
        if profile == nil {
            profile = try? await firestore.fetchUserProfile(userId: user.uid)
        }
        
        guard var currentProfile = profile else { return }
        
        // Update weight in profile
        currentProfile.weight = weight
        
        do {
            try await firestore.saveUserProfile(userId: user.uid, profile: currentProfile)
            profile = currentProfile
        } catch {
            print("Error updating profile weight: \(error)")
        }
    }
    
    func deleteWeightEntry(_ entry: WeightEntry) async {
        guard let user = auth.user,
              let entryId = entry.entryId else { return }
        
        do {
            try await firestore.deleteWeightEntry(userId: user.uid, entryId: entryId)
            await loadWeightEntries()
        } catch {
            errorMessage = "Failed to delete weight entry: \(error.localizedDescription)"
            print("Error deleting weight entry: \(error)")
        }
    }
    
    func deleteLatestWeightEntry() async {
        guard let latestEntry = weightEntries.first else { return }
        await deleteWeightEntry(latestEntry)
    }
    
    var weightTrend: WeightTrend? {
        guard !weightEntries.isEmpty else { return nil }
        return WeightTrend(entries: weightEntries)
    }
    
    // Computed properties for statistics
    var averageCalories: Double {
        guard !dailyLogs.isEmpty else { return 0 }
        let total = dailyLogs.reduce(0) { $0 + $1.calories }
        return Double(total) / Double(dailyLogs.count)
    }
    
    var averageProtein: Double {
        guard !dailyLogs.isEmpty else { return 0 }
        let total = dailyLogs.reduce(0) { $0 + $1.protein }
        return Double(total) / Double(dailyLogs.count)
    }
    
    var averageCarbs: Double {
        guard !dailyLogs.isEmpty else { return 0 }
        let total = dailyLogs.reduce(0) { $0 + $1.carbs }
        return Double(total) / Double(dailyLogs.count)
    }
    
    var averageFats: Double {
        guard !dailyLogs.isEmpty else { return 0 }
        let total = dailyLogs.reduce(0) { $0 + $1.fats }
        return Double(total) / Double(dailyLogs.count)
    }
    
    var totalCalories: Int {
        dailyLogs.reduce(0) { $0 + $1.calories }
    }
}

