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
        HStack(spacing: 16) {
            // Photo thumbnail with caching
            Group {
                if let photoUrl = food.photoUrl, let url = URL(string: photoUrl) {
                    CachedAsyncImage(url: url) { image in
                        image
                            .resizable()
                            .scaledToFill()
                    } placeholder: {
                        Rectangle()
                            .fill(Color.gainsCardBackground)
                            .overlay(
                                ProgressView()
                                    .tint(.gainsPrimary)
                            )
                    }
                } else {
                    Image(systemName: "fork.knife")
                        .font(.system(size: 24))
                        .foregroundColor(.gainsSecondaryText)
                }
            }
            .frame(width: 100, height: 100)
            .background(Color.gainsCardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            
            // Content
            VStack(alignment: .leading, spacing: 8) {
                // Meal name and menu button
                HStack {
                    Text(food.name)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.gainsText)
                        .lineLimit(2)
                    
                    Spacer()
                    
                    Menu {
                        Button(role: .destructive, action: {
                            showDeleteConfirmation = true
                        }) {
                            Label("Delete", systemImage: "trash")
                        }
                        
                        Button(action: onEdit) {
                            Label("Edit", systemImage: "pencil")
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.gainsSecondaryText)
                            .padding(8)
                    }
                }
                
                // Time logged
                Text(timeAgo)
                    .font(.system(size: 14))
                    .foregroundColor(.gainsSecondaryText)
                
                // Calories
                Text("\(food.calories) kcal")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.gainsPrimary)
                
                // Macros
                HStack(spacing: 16) {
                    MacroBadge(label: "P", value: Int(food.protein), unit: "g")
                    MacroBadge(label: "C", value: Int(food.carbs), unit: "g")
                    MacroBadge(label: "F", value: Int(food.fats), unit: "g")
                }
            }
            
            Spacer()
        }
        .padding(16)
        .background(Color.gainsCardBackground)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 2)
        .padding(.horizontal)
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

struct MacroBadge: View {
    let label: String
    let value: Int
    let unit: String
    
    var body: some View {
        Text("\(label): \(value)\(unit)")
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(.gainsText)
    }
}

#Preview {
    ZStack {
        Color.gainsBackground.ignoresSafeArea()
        
        VStack {
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

