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
        HStack(spacing: 16) {
            // Flame Icon with glow effect
            ZStack {
                Circle()
                    .fill(Color.gainsAccentOrange.opacity(0.15))
                    .frame(width: 50, height: 50)
                
                Image(systemName: "flame.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(hex: "FF6B35"), Color(hex: "FF9500")],
                            startPoint: .bottom,
                            endPoint: .top
                        )
                    )
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Current Streak")
                    .font(.system(size: 14))
                    .foregroundColor(.gainsTextSecondary)
                
                HStack(alignment: .lastTextBaseline, spacing: 4) {
                    Text("\(viewModel.streak.currentStreak)")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color(hex: "FF6B35"), Color(hex: "FF9500")],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .contentTransition(.numericText())
                    
                    Text("days")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.gainsTextSecondary)
                }
            }
            
            Spacer()
            
            // Best streak badge
            if viewModel.streak.longestStreak > viewModel.streak.currentStreak {
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Best")
                        .font(.system(size: 11))
                        .foregroundColor(.gainsTextMuted)
                    
                    Text("\(viewModel.streak.longestStreak)")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.gainsTextSecondary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.gainsBgTertiary)
                .cornerRadius(10)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: GainsDesign.cornerRadiusMedium)
                .fill(Color.gainsCardSurface)
        )
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
