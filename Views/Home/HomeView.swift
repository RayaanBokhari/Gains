//
//  HomeView.swift
//  Gains
//
//  Created by Rayaan Bokhari on 11/20/25.
//

import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel = NutritionViewModel()
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.gainsBackground.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        HStack {
                            Text("Home")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.gainsText)
                            Spacer()
                        }
                        .padding(.horizontal)
                        .padding(.top)
                        
                        // Calories Remaining Card
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Calories remaining to day")
                                .font(.system(size: 14))
                                .foregroundColor(.gainsSecondaryText)
                            
                            Text("\(viewModel.dailyNutrition.caloriesRemaining)")
                                .font(.system(size: 48, weight: .bold))
                                .foregroundColor(.gainsText)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(Color.gainsCardBackground)
                        .cornerRadius(16)
                        .padding(.horizontal)
                        
                        // Macro Circle Progress
                        HStack(spacing: 20) {
                            // Circular Progress for Fats (matching mockup: 102g/202g)
                            ZStack {
                                Circle()
                                    .stroke(Color.gainsCardBackground, lineWidth: 12)
                                    .frame(width: 120, height: 120)
                                
                                Circle()
                                    .trim(from: 0, to: min(1.0, viewModel.dailyNutrition.fatsConsumed / 202.0))
                                    .stroke(Color.gainsPrimary, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                                    .frame(width: 120, height: 120)
                                    .rotationEffect(.degrees(-90))
                                
                                VStack {
                                    Text("\(Int(viewModel.dailyNutrition.fatsConsumed))g")
                                        .font(.system(size: 18, weight: .bold))
                                        .foregroundColor(.gainsText)
                                    Text("202g")
                                        .font(.system(size: 14))
                                        .foregroundColor(.gainsSecondaryText)
                                }
                            }
                            
                            VStack(alignment: .leading, spacing: 12) {
                                MacroRow(label: "Protein", consumed: Int(viewModel.dailyNutrition.proteinConsumed), goal: Int(viewModel.dailyNutrition.proteinGoal))
                                MacroRow(label: "Carbs", consumed: Int(viewModel.dailyNutrition.carbsConsumed), goal: Int(viewModel.dailyNutrition.carbsGoal))
                                MacroRow(label: "Fats", consumed: Int(viewModel.dailyNutrition.fatsConsumed), goal: Int(viewModel.dailyNutrition.fatsGoal))
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding()
                        .background(Color.gainsCardBackground)
                        .cornerRadius(16)
                        .padding(.horizontal)
                        
                        // Action Buttons
                        HStack(spacing: 16) {
                            ActionButton(title: "Log Food", icon: "fork.knife") {
                                // TODO: Show food logging sheet
                            }
                            
                            ActionButton(title: "Log Water", icon: "drop.fill") {
                                viewModel.addWater(8)
                            }
                        }
                        .padding(.horizontal)
                        
                        // Recent Activity
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Recent Activity")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.gainsText)
                                .padding(.horizontal)
                            
                            ForEach(viewModel.recentFoods.prefix(3)) { food in
                                RecentFoodCard(food: food)
                            }
                        }
                        .padding(.top)
                    }
                }
            }
            .navigationBarHidden(true)
        }
    }
}

struct MacroRow: View {
    let label: String
    let consumed: Int
    let goal: Int
    
    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 14))
                .foregroundColor(.gainsSecondaryText)
            Spacer()
            Text("\(consumed)g / \(goal)g")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.gainsText)
        }
    }
}

struct ActionButton: View {
    let title: String
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 16))
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.gainsPrimary)
            .cornerRadius(12)
        }
    }
}

struct RecentFoodCard: View {
    let food: Food
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(food.name)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.gainsText)
                
                Text(food.loggedAt, style: .time)
                    .font(.system(size: 14))
                    .foregroundColor(.gainsSecondaryText)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14))
                .foregroundColor(.gainsSecondaryText)
        }
        .padding()
        .background(Color.gainsCardBackground)
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

#Preview {
    HomeView()
}

