//
//  AchievementsView.swift
//  Gains
//
//  Created by Rayaan Bokhari on 11/21/25.
//

import SwiftUI
import Combine
import FirebaseAuth

struct AchievementsView: View {
    @StateObject private var viewModel = AchievementsViewModel()
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                ForEach(viewModel.achievements) { achievement in
                    AchievementCard(achievement: achievement)
                }
            }
            .padding()
        }
        .background(Color.gainsBackground)
        .navigationTitle("Achievements")
        .task {
            await viewModel.loadAchievements()
        }
    }
}

struct AchievementCard: View {
    let achievement: Achievement
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(achievement.isUnlocked ? Color.gainsPrimary.opacity(0.2) : Color.gainsCardBackground)
                    .frame(width: 60, height: 60)
                
                Image(systemName: achievement.iconName)
                    .font(.system(size: 28))
                    .foregroundColor(achievement.isUnlocked ? .gainsPrimary : .gainsSecondaryText)
            }
            
            Text(achievement.name)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.gainsText)
                .multilineTextAlignment(.center)
                .lineLimit(2)
            
            if !achievement.isUnlocked && achievement.target != nil {
                Text("\(Int(achievement.progress * Double(achievement.target!))) / \(achievement.target!)")
                    .font(.system(size: 10))
                    .foregroundColor(.gainsSecondaryText)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.gainsCardBackground)
        .cornerRadius(12)
        .opacity(achievement.isUnlocked ? 1.0 : 0.6)
    }
}

@MainActor
class AchievementsViewModel: ObservableObject {
    @Published var achievements: [Achievement] = []
    
    private let firestore = FirestoreService.shared
    private let auth = AuthService.shared
    
    func loadAchievements() async {
        guard let user = auth.user else { return }
        
        do {
            let loadedAchievements = try await firestore.fetchAchievements(userId: user.uid)
            let allAchievements = Achievement.allAchievements()
            
            // Merge loaded with defaults
            var merged: [Achievement] = []
            for achievement in allAchievements {
                if let loaded = loadedAchievements.first(where: { $0.id == achievement.id }) {
                    merged.append(loaded)
                } else {
                    merged.append(achievement)
                }
            }
            
            achievements = merged
        } catch {
            print("Error loading achievements: \(error)")
            achievements = Achievement.allAchievements()
        }
    }
}

