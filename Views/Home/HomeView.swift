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
    @State private var showDatePicker = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.gainsBackground.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header with Date Navigation
                        VStack(spacing: 12) {
                            HStack {
                                Text("Home")
                                    .font(.system(size: 28, weight: .bold))
                                    .foregroundColor(.gainsText)
                                Spacer()
                            }
                            
                            // Date Navigation Bar
                            HStack(spacing: 16) {
                                // Previous Day Button
                                Button {
                                    Task {
                                        await viewModel.goToPreviousDay()
                                    }
                                } label: {
                                    Image(systemName: "chevron.left")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.gainsPrimary)
                                        .frame(width: 40, height: 40)
                                        .background(Color.gainsPrimary.opacity(0.1))
                                        .cornerRadius(10)
                                }
                                
                                // Date Display Button
                                Button {
                                    showDatePicker = true
                                } label: {
                                    HStack(spacing: 8) {
                                        Image(systemName: "calendar")
                                            .font(.system(size: 14))
                                        
                                        Text(formatDate(viewModel.selectedDate))
                                            .font(.system(size: 16, weight: .semibold))
                                        
                                        if Calendar.current.isDateInToday(viewModel.selectedDate) {
                                            Text("Today")
                                                .font(.system(size: 12, weight: .medium))
                                                .padding(.horizontal, 6)
                                                .padding(.vertical, 2)
                                                .background(Color.gainsPrimary.opacity(0.2))
                                                .cornerRadius(6)
                                        }
                                    }
                                    .foregroundColor(.gainsText)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 10)
                                    .background(Color.gainsCardBackground)
                                    .cornerRadius(12)
                                }
                                
                                // Next Day Button
                                Button {
                                    Task {
                                        await viewModel.goToNextDay()
                                    }
                                } label: {
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.gainsPrimary)
                                        .frame(width: 40, height: 40)
                                        .background(Color.gainsPrimary.opacity(0.1))
                                        .cornerRadius(10)
                                }
                                .disabled(Calendar.current.isDateInToday(viewModel.selectedDate))
                                .opacity(Calendar.current.isDateInToday(viewModel.selectedDate) ? 0.5 : 1.0)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top)
                        
                        // Calories Remaining Card
                        VStack(alignment: .leading, spacing: 8) {
                            Text(Calendar.current.isDateInToday(viewModel.selectedDate) ? "Calories remaining today" : "Calories remaining")
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
                            // Circular Progress for Fats
                            ZStack {
                                Circle()
                                    .stroke(Color.gainsCardBackground, lineWidth: 12)
                                    .frame(width: 120, height: 120)
                                
                                let fatsGoal = max(1.0, viewModel.dailyNutrition.fatsGoal) // Prevent division by zero
                                let fatsConsumed = max(0.0, viewModel.dailyNutrition.fatsConsumed) // Prevent negative values
                                let progress = min(1.0, max(0.0, fatsConsumed / fatsGoal)) // Clamp between 0 and 1
                                
                                Circle()
                                    .trim(from: 0, to: progress.isFinite ? progress : 0)
                                    .stroke(Color.gainsPrimary, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                                    .frame(width: 120, height: 120)
                                    .rotationEffect(.degrees(-90))
                                
                                VStack {
                                    Text("\(Int(fatsConsumed))g")
                                        .font(.system(size: 18, weight: .bold))
                                        .foregroundColor(.gainsText)
                                    Text("\(Int(fatsGoal))g")
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
                        
                        // Streak Card
                        StreakCard()
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
                        
                        // Meals Section
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text(Calendar.current.isDateInToday(viewModel.selectedDate) ? "Today's Meals" : "Meals")
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
                                    
                                    Text(Calendar.current.isDateInToday(viewModel.selectedDate) ? "No meals logged today" : "No meals logged")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.gainsText)
                                    
                                    Text(Calendar.current.isDateInToday(viewModel.selectedDate) ? "Start tracking your nutrition by logging your first meal" : "No meals were logged on this day")
                                        .font(.system(size: 14))
                                        .foregroundColor(.gainsSecondaryText)
                                        .multilineTextAlignment(.center)
                                    
                                    if Calendar.current.isDateInToday(viewModel.selectedDate) {
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
            .sheet(isPresented: $showDatePicker) {
                DatePickerSheet(
                    selectedDate: $viewModel.selectedDate,
                    isPresented: $showDatePicker,
                    onDateSelected: { date in
                        Task {
                            await viewModel.loadDate(date)
                        }
                    }
                )
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        if Calendar.current.isDateInToday(date) {
            return "Today"
        } else if Calendar.current.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            formatter.dateFormat = "MMM d, yyyy"
            return formatter.string(from: date)
        }
    }
}

struct DatePickerSheet: View {
    @Binding var selectedDate: Date
    @Binding var isPresented: Bool
    let onDateSelected: (Date) -> Void
    
    @State private var tempDate: Date
    
    init(selectedDate: Binding<Date>, isPresented: Binding<Bool>, onDateSelected: @escaping (Date) -> Void) {
        self._selectedDate = selectedDate
        self._isPresented = isPresented
        self.onDateSelected = onDateSelected
        _tempDate = State(initialValue: selectedDate.wrappedValue)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.gainsBackground.ignoresSafeArea()
                
                VStack(spacing: 24) {
                    DatePicker(
                        "Select Date",
                        selection: $tempDate,
                        displayedComponents: .date
                    )
                    .datePickerStyle(.graphical)
                    .accentColor(.gainsPrimary)
                    .padding()
                    .background(Color.gainsCardBackground)
                    .cornerRadius(16)
                    .padding()
                }
            }
            .navigationTitle("Select Date")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                    .foregroundColor(.gainsPrimary)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        selectedDate = tempDate
                        onDateSelected(tempDate)
                        isPresented = false
                    }
                    .foregroundColor(.gainsPrimary)
                    .fontWeight(.semibold)
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

