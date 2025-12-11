//
//  ProfileViewModel.swift
//  Gains
//
//  Created by Rayaan Bokhari on 11/20/25.
//

import Foundation
import SwiftUI
import Combine
import FirebaseAuth

@MainActor
class ProfileViewModel: ObservableObject {
    @Published var profile: UserProfile
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var todayLog: DailyLog?
    
    private let firestore = FirestoreService.shared
    private let auth = AuthService.shared
    
    init() {
        // Default profile - will be replaced when loaded
        self.profile = UserProfile()
    }
    
    /// Calculate macro progress based on today's logged data vs goals
    var macroProgress: (protein: Double, carbs: Double, fats: Double) {
        guard let log = todayLog else {
            return (0.0, 0.0, 0.0)
        }
        
        let proteinProgress = profile.macros.protein > 0 
            ? min(1.0, Double(log.protein) / profile.macros.protein) 
            : 0.0
        let carbsProgress = profile.macros.carbs > 0 
            ? min(1.0, Double(log.carbs) / profile.macros.carbs) 
            : 0.0
        let fatsProgress = profile.macros.fats > 0 
            ? min(1.0, Double(log.fats) / profile.macros.fats) 
            : 0.0
        
        return (proteinProgress, carbsProgress, fatsProgress)
    }
    
    func loadProfile() async {
        guard let user = auth.user else {
            print("⚠️ ProfileViewModel: No user signed in")
            return
        }
        
        print("📱 ProfileViewModel: Loading profile for user: \(user.uid)")
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        do {
            if var fetchedProfile = try await firestore.fetchUserProfile(userId: user.uid) {
                print("✅ ProfileViewModel: Successfully loaded profile")
                
                // Handle existing users who had profiles before onboarding was added
                // If they have meaningful data (not default values), mark them as onboarded
                if !fetchedProfile.hasCompletedOnboarding {
                    let hasCustomData = fetchedProfile.name != "Alex" ||
                                       fetchedProfile.weight != 150 ||
                                       fetchedProfile.height != "5 ft 10 in" ||
                                       fetchedProfile.dailyCaloriesGoal != 2000
                    
                    if hasCustomData {
                        print("📝 ProfileViewModel: Existing user with custom data, marking as onboarded")
                        fetchedProfile.hasCompletedOnboarding = true
                        try await firestore.saveUserProfile(userId: user.uid, profile: fetchedProfile)
                        
                        // Update AuthService state
                        await MainActor.run {
                            auth.hasCompletedOnboarding = true
                        }
                    }
                }
                
                profile = fetchedProfile
            } else {
                print("📝 ProfileViewModel: No profile found, creating default")
                // No profile exists, create default one (but don't mark as onboarded)
                profile = UserProfile(dateJoined: Date())
                // Save default profile
                try await firestore.saveUserProfile(userId: user.uid, profile: profile)
                print("✅ ProfileViewModel: Default profile created and saved")
            }
            
            // Load today's nutrition data for macro progress
            await loadTodayLog(userId: user.uid)
            
            // Set up HealthKit weight update callback
            setupHealthKitWeightObserver()
        } catch {
            errorMessage = "Failed to load profile: \(error.localizedDescription)"
            print("❌ ProfileViewModel: Error loading profile: \(error)")
            print("❌ Error details: \(error.localizedDescription)")
        }
    }
    
    /// Load today's daily log for macro progress calculation
    private func loadTodayLog(userId: String) async {
        do {
            todayLog = try await firestore.fetchDailyLog(userId: userId, for: Date())
            print("✅ ProfileViewModel: Loaded today's log - Protein: \(todayLog?.protein ?? 0)g, Carbs: \(todayLog?.carbs ?? 0)g, Fats: \(todayLog?.fats ?? 0)g")
        } catch {
            print("⚠️ ProfileViewModel: Error loading today's log: \(error)")
            todayLog = nil
        }
    }
    
    /// Refresh today's log (can be called from other views when meals are logged)
    func refreshTodayLog() async {
        guard let user = auth.user else { return }
        await loadTodayLog(userId: user.uid)
    }
    
    private func setupHealthKitWeightObserver() {
        let healthKit = HealthKitService.shared
        
        // Set callback for weight updates from HealthKit
        healthKit.onWeightUpdate = { [weak self] weightInKg in
            Task { @MainActor in
                await self?.handleHealthKitWeightUpdate(weightInKg: weightInKg)
            }
        }
        
        // Start observing if authorized
        if healthKit.isAuthorized {
            healthKit.startObservingWeightChanges()
        }
    }
    
    private func handleHealthKitWeightUpdate(weightInKg: Double) async {
        guard let user = auth.user else { return }
        
        // Convert kg to user's preferred unit
        let weightInUserUnit = profile.useMetricUnits ? weightInKg : weightInKg * 2.20462
        
        // Only update if significantly different (avoid infinite loops)
        if abs(profile.weight - weightInUserUnit) > 0.1 {
            print("📱 ProfileViewModel: HealthKit weight update detected: \(weightInKg) kg (\(weightInUserUnit) \(profile.useMetricUnits ? "kg" : "lbs"))")
            
            // Update profile weight
            profile.weight = weightInUserUnit
            
            do {
                try await firestore.saveUserProfile(userId: user.uid, profile: profile)
                print("✅ ProfileViewModel: Profile weight updated from HealthKit")
                
                let today = Date()
                
                // Check if there's already an entry for today
                if let existingEntry = try await firestore.findWeightEntryForDate(userId: user.uid, date: today) {
                    // Update existing entry
                    var updatedEntry = existingEntry
                    updatedEntry.weight = weightInKg
                    updatedEntry.notes = "Synced from Apple Health"
                    updatedEntry.date = today
                    
                    try await firestore.saveWeightEntry(userId: user.uid, entry: updatedEntry)
                    print("✅ ProfileViewModel: Updated existing weight entry from HealthKit")
                } else {
                    // Create new entry
                    let entry = WeightEntry(weight: weightInKg, date: today, notes: "Synced from Apple Health")
                    try await firestore.saveWeightEntry(userId: user.uid, entry: entry)
                    print("✅ ProfileViewModel: Weight entry created from HealthKit sync")
                }
            } catch {
                print("⚠️ ProfileViewModel: Error syncing HealthKit weight: \(error)")
            }
        }
    }
    
    func saveProfile() async {
        guard let user = auth.user else {
            errorMessage = "You must be signed in"
            print("❌ ProfileViewModel: Cannot save - no user signed in")
            return
        }
        
        print("💾 ProfileViewModel: Saving profile for user: \(user.uid)")
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        do {
            // Get the old weight to check if it changed
            let oldProfile = try? await firestore.fetchUserProfile(userId: user.uid)
            let oldWeight = oldProfile?.weight ?? profile.weight
            let weightChanged = abs(oldWeight - profile.weight) > 0.01
            
            try await firestore.saveUserProfile(userId: user.uid, profile: profile)
            print("✅ ProfileViewModel: Profile successfully saved to Firestore")
            print("📊 ProfileViewModel: Saved data - Name: \(profile.name), Weight: \(profile.weight), Units: \(profile.useMetricUnits ? "Metric" : "Imperial")")
            
            // If weight changed, create a weight entry and sync to HealthKit
            if weightChanged {
                await syncWeightToEntriesAndHealthKit()
            }
        } catch {
            errorMessage = "Failed to save profile: \(error.localizedDescription)"
            print("❌ ProfileViewModel: Error saving profile: \(error)")
            print("❌ ProfileViewModel: Error details: \(error.localizedDescription)")
        }
    }
    
    private func syncWeightToEntriesAndHealthKit() async {
        guard let user = auth.user else { return }
        
        // Convert weight to kg for weight entries (stored in kg)
        let weightInKg = profile.useMetricUnits ? profile.weight : profile.weight * 0.453592
        let today = Date()
        
        do {
            // Check if there's already an entry for today
            if let existingEntry = try await firestore.findWeightEntryForDate(userId: user.uid, date: today) {
                // Update existing entry
                var updatedEntry = existingEntry
                updatedEntry.weight = weightInKg
                updatedEntry.notes = "Updated from profile"
                updatedEntry.date = today
                
                try await firestore.saveWeightEntry(userId: user.uid, entry: updatedEntry)
                print("✅ ProfileViewModel: Updated existing weight entry from profile")
            } else {
                // Create new entry
                let entry = WeightEntry(weight: weightInKg, date: today, notes: "Updated from profile")
                try await firestore.saveWeightEntry(userId: user.uid, entry: entry)
                print("✅ ProfileViewModel: Weight entry created from profile update")
            }
            
            // Sync to HealthKit if enabled
            if HealthKitService.shared.syncEnabled {
                try? await HealthKitService.shared.saveWeight(weightInKg)
                print("✅ ProfileViewModel: Weight synced to HealthKit")
            }
        } catch {
            print("⚠️ ProfileViewModel: Error syncing weight to entries: \(error)")
        }
    }
}

