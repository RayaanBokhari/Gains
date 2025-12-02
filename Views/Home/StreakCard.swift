//
//  StreakCard.swift
//  Gains
//
//  Created by Rayaan Bokhari on 11/21/25.
//

import SwiftUI
import Combine
import FirebaseAuth

struct StreakCard: View {
    @StateObject private var viewModel = StreakViewModel()
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "flame.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.orange)
                
                Text("Current Streak")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.gainsText)
                
                Spacer()
            }
            
            HStack(alignment: .lastTextBaseline, spacing: 4) {
                Text("\(viewModel.streak.currentStreak)")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.orange)
                
                Text("days")
                    .font(.system(size: 16))
                    .foregroundColor(.gainsSecondaryText)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            if viewModel.streak.longestStreak > viewModel.streak.currentStreak {
                HStack {
                    Text("Best: \(viewModel.streak.longestStreak) days")
                        .font(.system(size: 12))
                        .foregroundColor(.gainsSecondaryText)
                    Spacer()
                }
            }
        }
        .padding()
        .background(Color.gainsCardBackground)
        .cornerRadius(16)
        .task {
            await viewModel.loadStreak()
        }
    }
}

@MainActor
class StreakViewModel: ObservableObject {
    @Published var streak: Streak = Streak()
    
    private let firestore = FirestoreService.shared
    private let auth = AuthService.shared
    
    func loadStreak() async {
        guard let user = auth.user else { return }
        
        do {
            if let loadedStreak = try await firestore.fetchStreak(userId: user.uid) {
                streak = loadedStreak
            }
        } catch {
            print("Error loading streak: \(error)")
        }
    }
}

