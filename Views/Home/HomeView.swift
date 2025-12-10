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
    @State private var showSuggestMeals = false
    @State private var showSavedMealPlan = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Gradient background with blue tint (matching mockup)
                LinearGradient(
                    colors: [
                        Color(hex: "0F1318"),  // Dark navy blue at top
                        Color(hex: "0D0F12"),  // Slightly lighter
                        Color(hex: "0A0B0E")   // Near black at bottom
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        // Header with Date Navigation
                        headerSection
                        
                        // Calories Remaining Card - Hero element
                        caloriesCard
                        
                        // Macros Overview Card
                        macrosOverviewCard
                        
                        // Meal Plan Card (if suggestions exist)
                        if !viewModel.savedMealSuggestions.isEmpty {
                            mealPlanCard
                        }
                        
                        // Today's Meals Section (always includes quick actions)
                        mealsSection
                    }
                    .padding(.bottom, 100) // Extra padding for tab bar
                }
            }
            .navigationBarHidden(true)
            .task {
                await viewModel.loadTodayIfPossible()
            }
            .onAppear {
                // Reload profile when view appears to sync any changes from Profile settings
                Task {
                    await viewModel.refreshProfile()
                }
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
            .sheet(isPresented: $showSuggestMeals) {
                SuggestMealsView(
                    remainingCalories: viewModel.dailyNutrition.caloriesRemaining,
                    remainingProtein: max(0, viewModel.dailyNutrition.proteinGoal - viewModel.dailyNutrition.proteinConsumed),
                    remainingCarbs: max(0, viewModel.dailyNutrition.carbsGoal - viewModel.dailyNutrition.carbsConsumed),
                    remainingFats: max(0, viewModel.dailyNutrition.fatsGoal - viewModel.dailyNutrition.fatsConsumed),
                    onSave: { meals in
                        viewModel.saveMealSuggestions(meals)
                    }
                )
            }
            .sheet(isPresented: $showSavedMealPlan) {
                SavedMealPlanView(
                    meals: viewModel.savedMealSuggestions,
                    onClear: {
                        viewModel.clearMealSuggestions()
                    }
                )
            }
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 16) {
            // Large Title
            HStack {
                Text("Home")
                    .font(.system(size: 34, weight: .bold))
                    .foregroundColor(.white)
                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)
            
            // Date Navigation Pill - Clean and sleek like mockup
            HStack(spacing: 0) {
                // Previous Day Button
                Button {
                    Task {
                        await viewModel.goToPreviousDay()
                    }
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.gainsPrimary)
                        .frame(width: 44, height: 44)
                }
                
                Spacer()
                
                // Date Display - Just the text, clean like mockup
                Button {
                    showDatePicker = true
                } label: {
                    Text(formatDateDisplay(viewModel.selectedDate))
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                // Next Day Button
                Button {
                    Task {
                        await viewModel.goToNextDay()
                    }
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Calendar.current.isDateInToday(viewModel.selectedDate) ? .gainsTextMuted.opacity(0.5) : .gainsPrimary)
                        .frame(width: 44, height: 44)
                }
                .disabled(Calendar.current.isDateInToday(viewModel.selectedDate))
            }
            .padding(.horizontal, 4)
            .frame(height: 44)
            .background(
                RoundedRectangle(cornerRadius: 22)
                    .fill(Color(hex: "1C1E22").opacity(0.9))
            )
            .padding(.horizontal, 24)
        }
    }
    
    // MARK: - Calories Card (Hero Element)
    private var caloriesCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(Calendar.current.isDateInToday(viewModel.selectedDate) ? "calories remaining today" : "calories remaining")
                .font(.system(size: 15))
                .foregroundColor(.gainsTextSecondary)
            
            HStack(alignment: .center) {
                Text("\(viewModel.dailyNutrition.caloriesRemaining)")
                    .font(.system(size: 56, weight: .bold))
                    .foregroundColor(.white)
                    .contentTransition(.numericText())
                
                Spacer()
                
                // Flame Icon with blue gradient
                Image(systemName: "flame.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color(hex: "0A84FF"), Color(hex: "5AC8FA")],
                            startPoint: .bottom,
                            endPoint: .top
                        )
                    )
            }
            
            if viewModel.isLoading {
                ProgressView()
                    .tint(.gainsPrimary)
                    .padding(.top, 4)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(hex: "1A1C20"))
        )
        .padding(.horizontal, 24)
    }
    
    // MARK: - Meal Plan Card
    private var mealPlanCard: some View {
        Button {
            showSavedMealPlan = true
        } label: {
            HStack(spacing: 12) {
                // Icon
                ZStack {
                    Circle()
                        .fill(Color.purple.opacity(0.2))
                        .frame(width: 44, height: 44)
                    Image(systemName: "sparkles")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.purple)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Today's Meal Plan")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                    Text("\(viewModel.savedMealSuggestions.count) meals suggested")
                        .font(.system(size: 13))
                        .foregroundColor(.gainsTextSecondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.gainsTextMuted)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(hex: "1A1C20"))
            )
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 24)
    }
    
    // MARK: - Macros Overview Card
    private var macrosOverviewCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Macros Overview")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.white)
            
            VStack(spacing: 16) {
                MacroProgressRow(
                    label: "Protein",
                    consumed: Int(viewModel.dailyNutrition.proteinConsumed),
                    goal: Int(viewModel.dailyNutrition.proteinGoal),
                    color: Color(hex: "FF6B6B")
                )
                
                MacroProgressRow(
                    label: "Carbs",
                    consumed: Int(viewModel.dailyNutrition.carbsConsumed),
                    goal: Int(viewModel.dailyNutrition.carbsGoal),
                    color: .gainsPrimary
                )
                
                MacroProgressRow(
                    label: "Fats",
                    consumed: Int(viewModel.dailyNutrition.fatsConsumed),
                    goal: Int(viewModel.dailyNutrition.fatsGoal),
                    color: Color(hex: "FFD93D")
                )
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(hex: "1A1C20"))
        )
        .padding(.horizontal, 24)
    }
    
    // MARK: - Meals Section
    private var mealsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section Header
            HStack {
                Text(Calendar.current.isDateInToday(viewModel.selectedDate) ? "Today's Meals" : "Meals")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)
                
                if !viewModel.recentFoods.isEmpty {
                    Text("\(viewModel.recentFoods.count)")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.gainsPrimary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.gainsPrimary.opacity(0.15))
                        .cornerRadius(10)
                }
                
                Spacer()
            }
            .padding(.horizontal, 24)
            
            if viewModel.recentFoods.isEmpty {
                // Empty State - Two cards side by side like mockup
                emptyMealsState
            } else {
                // Full-width Quick Actions Card
                quickActionsCard
                
                // Meals List
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
    }
    
    // MARK: - Quick Actions Card (full width, shown when meals exist)
    private var quickActionsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Quick Actions")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)

            HStack(spacing: 12) {
                // Log Food Button (Green)
                Button {
                    showFoodLogging = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "fork.knife")
                            .font(.system(size: 14, weight: .semibold))
                        Text("Log Food")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 42)
                    .background(Color.gainsAccentGreen)
                    .cornerRadius(10)
                }

                // AI Suggest Meals Button (Purple)
                Button {
                    showSuggestMeals = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 14, weight: .semibold))
                        Text("Suggest")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 42)
                    .background(Color.purple)
                    .cornerRadius(10)
                }

                // Add Water Button (Blue)
                Button {
                    Task {
                        await viewModel.addWater(8)
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "drop.fill")
                            .font(.system(size: 14, weight: .semibold))
                        Text("Water")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 42)
                    .background(Color.gainsPrimary)
                    .cornerRadius(10)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(hex: "1A1C20"))
        )
        .padding(.horizontal, 24)
    }
    
    // MARK: - Empty Meals State (matches mockup exactly)
    private var emptyMealsState: some View {
        HStack(alignment: .top, spacing: 12) {
            // Left side - Quick Actions Card
            VStack(alignment: .leading, spacing: 14) {
                Text("Quick Actions")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)

                Button {
                    showFoodLogging = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "fork.knife")
                            .font(.system(size: 14, weight: .semibold))
                        Text("Log Food")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 42)
                    .background(Color.gainsAccentGreen)
                    .cornerRadius(10)
                }

                Button {
                    showSuggestMeals = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 14, weight: .semibold))
                        Text("AI Suggest")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 42)
                    .background(Color.purple)
                    .cornerRadius(10)
                }

                Button {
                    Task {
                        await viewModel.addWater(8)
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "drop.fill")
                            .font(.system(size: 14, weight: .semibold))
                        Text("Add Water")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 42)
                    .background(Color.gainsPrimary)
                    .cornerRadius(10)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(hex: "1A1C20"))
            )

            // Right side - Empty State Message
            VStack(spacing: 12) {
                Spacer()

                Image(systemName: "fork.knife")
                    .font(.system(size: 32))
                    .foregroundColor(.gainsTextMuted)

                Text("No meals added yet")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)

                Text("Log food or use AI to suggest meals")
                    .font(.system(size: 13))
                    .foregroundColor(.gainsTextSecondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)

                Spacer()
            }
            .padding(16)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(hex: "1A1C20"))
            )
        }
        .fixedSize(horizontal: false, vertical: true)
        .padding(.horizontal, 24)
    }
    
    // MARK: - Helpers
    private func formatDateDisplay(_ date: Date) -> String {
        if Calendar.current.isDateInToday(date) {
            return "Today"
        } else if Calendar.current.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d, yyyy"
            return formatter.string(from: date)
        }
    }
}

// MARK: - Macro Progress Row Component
struct MacroProgressRow: View {
    let label: String
    let consumed: Int
    let goal: Int
    let color: Color
    
    private var progress: Double {
        guard goal > 0 else { return 0 }
        return min(1.0, Double(consumed) / Double(goal))
    }
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text(label)
                    .font(.system(size: 15))
                    .foregroundColor(.gainsTextSecondary)
                
                Spacer()
                
                Text("\(consumed)g")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.white)
                
                Text("\(consumed) / \(goal)g")
                    .font(.system(size: 15))
                    .foregroundColor(.gainsTextSecondary)
            }
            
            // Progress Bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color(hex: "2A2C30"))
                        .frame(height: 5)
                    
                    // Progress
                    RoundedRectangle(cornerRadius: 3)
                        .fill(color)
                        .frame(width: max(0, geometry.size.width * progress), height: 5)
                        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: progress)
                }
            }
            .frame(height: 5)
        }
    }
}

// MARK: - Date Picker Sheet
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
                Color(hex: "0A0B0E").ignoresSafeArea()
                
                VStack(spacing: 24) {
                    DatePicker(
                        "Select Date",
                        selection: $tempDate,
                        displayedComponents: .date
                    )
                    .datePickerStyle(.graphical)
                    .accentColor(.gainsPrimary)
                    .padding()
                    .background(Color(hex: "1A1C20"))
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

#Preview {
    HomeView()
}
