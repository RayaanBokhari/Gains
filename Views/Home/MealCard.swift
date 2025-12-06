//
//  MealCard.swift
//  Gains
//
//  Created by Rayaan Bokhari on 11/21/25.
//

import SwiftUI

struct MealCard: View {
    let food: Food
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    @State private var showDeleteConfirmation = false
    
    private var timeAgo: String {
        let now = Date()
        let timeInterval = now.timeIntervalSince(food.loggedAt)
        
        if timeInterval < 60 {
            return "Just now"
        } else if timeInterval < 3600 {
            let minutes = Int(timeInterval / 60)
            return "\(minutes)m ago"
        } else if timeInterval < 86400 {
            let hours = Int(timeInterval / 3600)
            return "\(hours)h ago"
        } else {
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            return formatter.string(from: food.loggedAt)
        }
    }
    
    var body: some View {
        HStack(spacing: 14) {
            // Photo thumbnail with caching
            Group {
                if let photoUrl = food.photoUrl, let url = URL(string: photoUrl) {
                    CachedAsyncImage(url: url) { image in
                        image
                            .resizable()
                            .scaledToFill()
                    } placeholder: {
                        Rectangle()
                            .fill(Color.gainsBgTertiary)
                            .overlay(
                                ProgressView()
                                    .tint(.gainsPrimary)
                            )
                    }
                } else {
                    ZStack {
                        Rectangle()
                            .fill(Color(hex: "2A2C30"))
                        Image(systemName: "fork.knife")
                            .font(.system(size: 24))
                            .foregroundColor(Color(hex: "6E6E73"))
                    }
                }
            }
            .frame(width: 80, height: 80)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            
            // Content
            VStack(alignment: .leading, spacing: 6) {
                // Meal name
                Text(food.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(2)
                
                // Time logged
                Text(timeAgo)
                    .font(.system(size: 12))
                    .foregroundColor(.gainsTextMuted)
                
                // Macros row
                HStack(spacing: 12) {
                    Text("\(food.calories) kcal")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.gainsPrimary)
                    
                    HStack(spacing: 8) {
                        MacroPill(label: "P", value: Int(food.protein))
                        MacroPill(label: "C", value: Int(food.carbs))
                        MacroPill(label: "F", value: Int(food.fats))
                    }
                }
            }
            
            Spacer()
            
            // Menu button
            Menu {
                Button(action: onEdit) {
                    Label("Edit", systemImage: "pencil")
                }
                
                Button(role: .destructive, action: {
                    showDeleteConfirmation = true
                }) {
                    Label("Delete", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.gainsTextSecondary)
                    .frame(width: 32, height: 32)
                    .background(Color.gainsBgTertiary)
                    .cornerRadius(8)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(hex: "1A1C20"))
        )
        .padding(.horizontal, 24)
        .confirmationDialog(
            "Delete this meal?",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                onDelete()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This action cannot be undone.")
        }
    }
}

struct MacroPill: View {
    let label: String
    let value: Int
    
    var body: some View {
        Text("\(label): \(value)g")
            .font(.system(size: 11, weight: .medium))
            .foregroundColor(Color(hex: "A0A0A5"))
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(Color(hex: "2A2C30"))
            .cornerRadius(4)
    }
}

#Preview {
    ZStack {
        Color.gainsBgPrimary.ignoresSafeArea()
        
        VStack(spacing: 12) {
            MealCard(
                food: Food(
                    name: "Grilled Chicken Salad",
                    calories: 350,
                    protein: 35,
                    carbs: 15,
                    fats: 12,
                    loggedAt: Date().addingTimeInterval(-3600),
                    photoUrl: nil
                ),
                onEdit: {},
                onDelete: {}
            )
            
            MealCard(
                food: Food(
                    name: "Large Chicken Burrito with Rice and Beans",
                    calories: 650,
                    protein: 45,
                    carbs: 80,
                    fats: 18,
                    loggedAt: Date().addingTimeInterval(-7200),
                    photoUrl: nil
                ),
                onEdit: {},
                onDelete: {}
            )
        }
    }
}
