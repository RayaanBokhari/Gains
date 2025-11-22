//
//  HomeView.swift
//  Gains
//
//  Created by Rayaan Bokhari on 11/20/25.
//

import SwiftUI
import FirebaseAuth

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    @State private var showFoodLogging = false
    
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
                            
                            if viewModel.isLoading {
                                ProgressView()
                                    .padding(.top, 4)
                            }
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
                                showFoodLogging = true
                            }
                            
                            ActionButton(title: "Log Water", icon: "drop.fill") {
                                Task {
                                    await viewModel.addWater(8)
                                }
                            }
                        }
                        .padding(.horizontal)
                        
                        // Test Button for Firebase
                        ActionButton(title: "+250 kcal", icon: "plus.circle.fill") {
                            Task {
                                await viewModel.addCalories(250)
                            }
                        }
                        .padding(.horizontal)
                        
                        // Recent Foods
                        if !viewModel.recentFoods.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Today's Meals")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.gainsText)
                                    .padding(.horizontal)
                                
                                ForEach(viewModel.recentFoods) { food in
                                    RecentFoodCard(food: food)
                                }
                            }
                            .padding(.top)
                        }
                    }
                }
            }
            .navigationBarHidden(true)
            .task {
                await viewModel.loadTodayIfPossible()
            }
            .sheet(isPresented: $showFoodLogging) {
                FoodLoggingView(
                    isPresented: $showFoodLogging,
                    onFoodLogged: { food in
                        Task {
                            await viewModel.logFood(food)
                        }
                    },
                    selectedDate: viewModel.selectedDate
                )
            }
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
        HStack(spacing: 12) {
            // Photo thumbnail if available
            if let photoUrl = food.photoUrl, let url = URL(string: photoUrl) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    Rectangle()
                        .fill(Color.gainsCardBackground)
                        .overlay(
                            ProgressView()
                        )
                }
                .frame(width: 60, height: 60)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                // Placeholder icon
                Image(systemName: "fork.knife")
                    .font(.system(size: 20))
                    .foregroundColor(.gainsSecondaryText)
                    .frame(width: 60, height: 60)
                    .background(Color.gainsCardBackground)
                    .cornerRadius(8)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(food.name)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.gainsText)
                
                HStack(spacing: 8) {
                    Text(food.loggedAt, style: .time)
                        .font(.system(size: 14))
                        .foregroundColor(.gainsSecondaryText)
                    
                    Text("•")
                        .foregroundColor(.gainsSecondaryText)
                    
                    Text("\(food.calories) kcal")
                        .font(.system(size: 14))
                        .foregroundColor(.gainsSecondaryText)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text("P: \(Int(food.protein))g")
                    .font(.system(size: 12))
                    .foregroundColor(.gainsSecondaryText)
                Text("C: \(Int(food.carbs))g")
                    .font(.system(size: 12))
                    .foregroundColor(.gainsSecondaryText)
                Text("F: \(Int(food.fats))g")
                    .font(.system(size: 12))
                    .foregroundColor(.gainsSecondaryText)
            }
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

