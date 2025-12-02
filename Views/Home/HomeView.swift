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
    @State private var showEditMeal = false
    @State private var selectedMeal: Food?
    
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
                        
                        // Today's Meals Section
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Today's Meals")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.gainsText)
                                
                                if !viewModel.recentFoods.isEmpty {
                                    Text("\(viewModel.recentFoods.count)")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.gainsPrimary)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.gainsPrimary.opacity(0.2))
                                        .cornerRadius(12)
                                }
                            }
                            .padding(.horizontal)
                            
                            if viewModel.recentFoods.isEmpty {
                                // Empty state
                                VStack(spacing: 16) {
                                    Image(systemName: "fork.knife")
                                        .font(.system(size: 48))
                                        .foregroundColor(.gainsSecondaryText)
                                    
                                    Text("No meals logged today")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.gainsText)
                                    
                                    Text("Start tracking your nutrition by logging your first meal")
                                        .font(.system(size: 14))
                                        .foregroundColor(.gainsSecondaryText)
                                        .multilineTextAlignment(.center)
                                    
                                    Button {
                                        showFoodLogging = true
                                    } label: {
                                        Text("Log Food")
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 24)
                                            .padding(.vertical, 12)
                                            .background(Color.gainsPrimary)
                                            .cornerRadius(12)
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 40)
                                .padding(.horizontal)
                            } else {
                                ForEach(viewModel.recentFoods) { food in
                                    MealCard(
                                        food: food,
                                        onEdit: {
                                            selectedMeal = food
                                            showEditMeal = true
                                        },
                                        onDelete: {
                                            Task {
                                                await viewModel.deleteMeal(food)
                                            }
                                        }
                                    )
                                }
                            }
                        }
                        .padding(.top)
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
            .sheet(isPresented: $showEditMeal) {
                if let meal = selectedMeal {
                    EditMealView(
                        isPresented: $showEditMeal,
                        food: meal,
                        onMealUpdated: { updatedFood in
                            Task {
                                await viewModel.editMeal(updatedFood)
                            }
                        },
                        selectedDate: viewModel.selectedDate
                    )
                }
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

#Preview {
    HomeView()
}

