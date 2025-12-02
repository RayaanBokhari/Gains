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
    
    private let firestore = FirestoreService.shared
    private let auth = AuthService.shared
    
    init() {
        // Default profile - will be replaced when loaded
        self.profile = UserProfile()
    }
    
    var macroProgress: (protein: Double, carbs: Double, fats: Double) {
        // Sample progress: 25%, 90%, 25%
        return (0.25, 0.90, 0.25)
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
            if let fetchedProfile = try await firestore.fetchUserProfile(userId: user.uid) {
                print("✅ ProfileViewModel: Successfully loaded profile")
                profile = fetchedProfile
            } else {
                print("📝 ProfileViewModel: No profile found, creating default")
                // No profile exists, create default one
                profile = UserProfile(dateJoined: Date())
                // Save default profile
                try await firestore.saveUserProfile(userId: user.uid, profile: profile)
                print("✅ ProfileViewModel: Default profile created and saved")
            }
        } catch {
            errorMessage = "Failed to load profile: \(error.localizedDescription)"
            print("❌ ProfileViewModel: Error loading profile: \(error)")
            print("❌ Error details: \(error.localizedDescription)")
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
            try await firestore.saveUserProfile(userId: user.uid, profile: profile)
            print("✅ ProfileViewModel: Profile successfully saved to Firestore")
            print("📊 ProfileViewModel: Saved data - Name: \(profile.name), Weight: \(profile.weight), Units: \(profile.useMetricUnits ? "Metric" : "Imperial")")
        } catch {
            errorMessage = "Failed to save profile: \(error.localizedDescription)"
            print("❌ ProfileViewModel: Error saving profile: \(error)")
            print("❌ ProfileViewModel: Error details: \(error.localizedDescription)")
        }
    }
}

