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
                // Gradient background
                LinearGradient(
                    colors: [Color(hex: "0D0E14"), Color(hex: "0A0A0B")],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: GainsDesign.sectionSpacing) {
                        // Header with Date Navigation
                        headerSection
                        
                        // Calories Remaining Card - Hero element
                        caloriesCard
                        
                        // Macros Overview Card
                        macrosOverviewCard
                        
                        // Quick Actions Row
                        quickActionsSection
                        
                        // Today's Meals Section
                        mealsSection
                    }
                    .padding(.bottom, 100) // Extra padding for tab bar
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
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 20) {
            // Large Title
            HStack {
                Text("Home")
                    .font(.system(size: 34, weight: .bold))
                    .foregroundColor(.white)
                Spacer()
            }
            .padding(.horizontal, GainsDesign.paddingHorizontal)
            .padding(.top, GainsDesign.titlePaddingTop)
            
            // Date Navigation Pill
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
                
                // Date Display
                Button {
                    showDatePicker = true
                } label: {
                    HStack(spacing: 8) {
                        Text(formatDate(viewModel.selectedDate))
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                        
                        if Calendar.current.isDateInToday(viewModel.selectedDate) {
                            Text("Today")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.gainsPrimary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.gainsPrimary.opacity(0.15))
                                .cornerRadius(6)
                        }
                    }
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
                        .foregroundColor(Calendar.current.isDateInToday(viewModel.selectedDate) ? .gainsTextMuted : .gainsPrimary)
                        .frame(width: 44, height: 44)
                }
                .disabled(Calendar.current.isDateInToday(viewModel.selectedDate))
            }
            .padding(.horizontal, 8)
            .background(
                RoundedRectangle(cornerRadius: GainsDesign.cornerRadiusPill)
                    .fill(.ultraThinMaterial)
                    .environment(\.colorScheme, .dark)
            )
            .padding(.horizontal, GainsDesign.paddingHorizontal)
        }
    }
    
    // MARK: - Calories Card (Hero Element)
    private var caloriesCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(Calendar.current.isDateInToday(viewModel.selectedDate) ? "calories remaining today" : "calories remaining")
                .font(.system(size: 14))
                .foregroundColor(.gainsTextSecondary)
            
            HStack(alignment: .center) {
                Text("\(viewModel.dailyNutrition.caloriesRemaining)")
                    .font(.system(size: 52, weight: .bold))
                    .foregroundColor(.white)
                    .contentTransition(.numericText())
                
                Spacer()
                
                // Flame Icon
                Image(systemName: "flame.fill")
                    .font(.system(size: 32))
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
            RoundedRectangle(cornerRadius: GainsDesign.cornerRadiusLarge)
                .fill(Color.gainsCardGradient)
                .shadow(color: .black.opacity(0.25), radius: 20, x: 0, y: 4)
        )
        .padding(.horizontal, GainsDesign.paddingHorizontal)
    }
    
    // MARK: - Macros Overview Card
    private var macrosOverviewCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Macros Overview")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
            
            VStack(spacing: 14) {
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
            RoundedRectangle(cornerRadius: GainsDesign.cornerRadiusLarge)
                .fill(Color.gainsCardSurface)
        )
        .padding(.horizontal, GainsDesign.paddingHorizontal)
    }
    
    // MARK: - Quick Actions Section
    private var quickActionsSection: some View {
        HStack(spacing: 12) {
            // Log Food Button (Green)
            Button {
                showFoodLogging = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "fork.knife")
                        .font(.system(size: 16, weight: .semibold))
                    Text("Log Food")
                        .font(.system(size: 15, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: GainsDesign.buttonHeightMedium)
                .background(Color.gainsAccentGreen)
                .cornerRadius(GainsDesign.cornerRadiusSmall)
            }
            
            // Add Water Button (Blue)
            Button {
                Task {
                    await viewModel.addWater(8)
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "drop.fill")
                        .font(.system(size: 16, weight: .semibold))
                    Text("Add Water")
                        .font(.system(size: 15, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: GainsDesign.buttonHeightMedium)
                .background(Color.gainsPrimary)
                .cornerRadius(GainsDesign.cornerRadiusSmall)
            }
        }
        .padding(.horizontal, GainsDesign.paddingHorizontal)
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
            .padding(.horizontal, GainsDesign.paddingHorizontal)
            
            if viewModel.recentFoods.isEmpty {
                // Empty State
                emptyMealsState
            } else {
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
    
    // MARK: - Empty Meals State
    private var emptyMealsState: some View {
        HStack(spacing: 20) {
            // Left side - Quick Actions Card
            VStack(alignment: .leading, spacing: 12) {
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
                    .frame(height: 40)
                    .background(Color.gainsAccentGreen)
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
                    .frame(height: 40)
                    .background(Color.gainsPrimary)
                    .cornerRadius(10)
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: GainsDesign.cornerRadiusMedium)
                    .fill(Color.gainsCardSurface)
            )
            
            // Right side - Empty State Message
            VStack(spacing: 12) {
                Image(systemName: "fork.knife")
                    .font(.system(size: 36))
                    .foregroundColor(.gainsTextMuted)
                
                Text("No meals added yet")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                
                Text("Add your first meal to start your day.")
                    .font(.system(size: 13))
                    .foregroundColor(.gainsTextSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(16)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: GainsDesign.cornerRadiusMedium)
                    .fill(Color.gainsCardSurface)
            )
        }
        .padding(.horizontal, GainsDesign.paddingHorizontal)
    }
    
    // MARK: - Helpers
    private func formatDate(_ date: Date) -> String {
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
                    .font(.system(size: 14))
                    .foregroundColor(.gainsTextSecondary)
                
                Spacer()
                
                Text("\(consumed)g")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                
                Text("\(consumed) / \(goal)g")
                    .font(.system(size: 14))
                    .foregroundColor(.gainsTextSecondary)
            }
            
            // Progress Bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gainsProgressBackground)
                        .frame(height: 6)
                    
                    // Progress
                    RoundedRectangle(cornerRadius: 4)
                        .fill(color)
                        .frame(width: geometry.size.width * progress, height: 6)
                        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: progress)
                }
            }
            .frame(height: 6)
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
                Color.gainsBgPrimary.ignoresSafeArea()
                
                VStack(spacing: 24) {
                    DatePicker(
                        "Select Date",
                        selection: $tempDate,
                        displayedComponents: .date
                    )
                    .datePickerStyle(.graphical)
                    .accentColor(.gainsPrimary)
                    .padding()
                    .background(Color.gainsCardSurface)
                    .cornerRadius(GainsDesign.cornerRadiusMedium)
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
