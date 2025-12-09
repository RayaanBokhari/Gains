//
//  DietaryPlanDetailView.swift
//  Gains
//
//  Created by Rayaan Bokhari on 12/20/25.
//

import SwiftUI

struct DietaryPlanDetailView: View {
    let plan: DietaryPlan
    @ObservedObject var planService: DietaryPlanService
    @Environment(\.dismiss) var dismiss
    @State private var selectedDay: Int = 1
    @State private var showDeleteAlert = false
    
    var body: some View {
        ZStack {
            Color.gainsBackground.ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header Info
                    headerSection
                    
                    // Macro Targets
                    macroTargetsSection
                    
                    // Day Selector
                    daySelector
                    
                    // Selected Day's Meals
                    if let dayPlan = plan.meals.first(where: { $0.dayNumber == selectedDay }) {
                        dayMealsSection(for: dayPlan)
                    } else {
                        emptyDayState
                    }
                }
                .padding()
            }
        }
        .navigationTitle(plan.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    if !plan.isActive {
                        Button {
                            Task {
                                try? await planService.setActivePlan(plan)
                            }
                        } label: {
                            Label("Set as Active", systemImage: "checkmark.circle")
                        }
                    } else {
                        Button {
                            Task {
                                try? await planService.deactivatePlan(plan)
                            }
                        } label: {
                            Label("Deactivate", systemImage: "stop.circle")
                        }
                    }
                    
                    if !plan.isRetired {
                        Button {
                            Task {
                                try? await planService.retirePlan(plan)
                                dismiss()
                            }
                        } label: {
                            Label("Retire Plan", systemImage: "archivebox")
                        }
                    }
                    
                    Divider()
                    
                    Button(role: .destructive) {
                        showDeleteAlert = true
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundColor(.gainsPrimary)
                }
            }
        }
        .alert("Delete Plan", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                Task {
                    try? await planService.deletePlan(plan)
                    dismiss()
                }
            }
        } message: {
            Text("Are you sure you want to permanently delete this meal plan?")
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            if plan.isActive {
                Label("Active Plan", systemImage: "checkmark.circle.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.gainsSuccess)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.gainsSuccess.opacity(0.2))
                    .cornerRadius(8)
            }
            
            if let description = plan.description {
                Text(description)
                    .font(.system(size: 15))
                    .foregroundColor(.gainsSecondaryText)
            }
            
            HStack(spacing: 16) {
                if let goal = plan.goal {
                    Label(goal.rawValue, systemImage: "target")
                }
                if let dietType = plan.dietType {
                    Label(dietType.rawValue, systemImage: "leaf")
                }
                Label("\(plan.mealCount) meals/day", systemImage: "fork.knife")
            }
            .font(.system(size: 13))
            .foregroundColor(.gainsSecondaryText)
            
            if let restrictions = plan.restrictions, !restrictions.isEmpty {
                HStack {
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundColor(.gainsWarning)
                    Text("Restrictions: \(restrictions.joined(separator: ", "))")
                        .font(.system(size: 12))
                        .foregroundColor(.gainsSecondaryText)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.gainsCardBackground)
        .cornerRadius(16)
    }
    
    // MARK: - Macro Targets Section
    private var macroTargetsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Daily Targets")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.gainsText)
            
            HStack(spacing: 0) {
                macroTargetItem(
                    label: "Calories",
                    value: "\(plan.dailyCalories)",
                    unit: "kcal",
                    color: .gainsText
                )
                
                Divider()
                    .frame(height: 40)
                    .background(Color.gainsSecondaryText.opacity(0.3))
                
                macroTargetItem(
                    label: "Protein",
                    value: "\(Int(plan.macros.protein))",
                    unit: "g",
                    color: .gainsPrimary
                )
                
                Divider()
                    .frame(height: 40)
                    .background(Color.gainsSecondaryText.opacity(0.3))
                
                macroTargetItem(
                    label: "Carbs",
                    value: "\(Int(plan.macros.carbs))",
                    unit: "g",
                    color: .gainsSecondary
                )
                
                Divider()
                    .frame(height: 40)
                    .background(Color.gainsSecondaryText.opacity(0.3))
                
                macroTargetItem(
                    label: "Fats",
                    value: "\(Int(plan.macros.fats))",
                    unit: "g",
                    color: .gainsWarning
                )
            }
            .padding()
            .background(Color.gainsCardBackground)
            .cornerRadius(12)
        }
    }
    
    private func macroTargetItem(label: String, value: String, unit: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(.gainsSecondaryText)
            
            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(value)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(color)
                Text(unit)
                    .font(.system(size: 11))
                    .foregroundColor(.gainsSecondaryText)
            }
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Day Selector
    private var daySelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(plan.meals.sorted(by: { $0.dayNumber < $1.dayNumber })) { day in
                    Button {
                        selectedDay = day.dayNumber
                    } label: {
                        VStack(spacing: 4) {
                            Text(String(day.dayName.prefix(3)))
                                .font(.system(size: 12, weight: .medium))
                            Text("\(day.dayNumber)")
                                .font(.system(size: 16, weight: .bold))
                        }
                        .foregroundColor(selectedDay == day.dayNumber ? .white : .gainsSecondaryText)
                        .frame(width: 50, height: 60)
                        .background(
                            selectedDay == day.dayNumber
                                ? Color.gainsSuccess
                                : Color.gainsCardBackground
                        )
                        .cornerRadius(12)
                    }
                }
            }
            .padding(.horizontal, 4)
        }
    }
    
    // MARK: - Day Meals Section
    private func dayMealsSection(for day: MealPlanDay) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text(day.dayName)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.gainsText)
                
                Spacer()
                
                Text("\(day.totalCalories) kcal")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.gainsSecondaryText)
            }
            
            if let notes = day.notes {
                Text(notes)
                    .font(.system(size: 13))
                    .foregroundColor(.gainsSecondaryText)
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.gainsCardBackground.opacity(0.5))
                    .cornerRadius(8)
            }
            
            ForEach(day.meals) { meal in
                MealPlanMealCard(meal: meal)
            }
        }
    }
    
    // MARK: - Empty Day State
    private var emptyDayState: some View {
        VStack(spacing: 12) {
            Image(systemName: "fork.knife")
                .font(.system(size: 36))
                .foregroundColor(.gainsSecondaryText)
            
            Text("No meals planned for this day")
                .font(.system(size: 15))
                .foregroundColor(.gainsSecondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }
}

// MARK: - Meal Plan Meal Card
struct MealPlanMealCard: View {
    let meal: PlannedMeal
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(meal.mealType.rawValue)
                            .font(.system(size: 12))
                            .foregroundColor(.gainsSecondaryText)
                        
                        Text(meal.name)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.gainsText)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("\(meal.calories) kcal")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.gainsText)
                        
                        if let prepTime = meal.prepTime {
                            HStack(spacing: 4) {
                                Image(systemName: "clock")
                                Text("\(prepTime) min")
                            }
                            .font(.system(size: 11))
                            .foregroundColor(.gainsSecondaryText)
                        }
                    }
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12))
                        .foregroundColor(.gainsSecondaryText)
                        .padding(.leading, 8)
                }
                .padding()
            }
            
            if isExpanded {
                Divider()
                    .background(Color.gainsSecondaryText.opacity(0.2))
                
                VStack(alignment: .leading, spacing: 12) {
                    // Macros
                    HStack(spacing: 16) {
                        macroLabel("P", value: Int(meal.protein), color: .gainsPrimary)
                        macroLabel("C", value: Int(meal.carbs), color: .gainsSecondary)
                        macroLabel("F", value: Int(meal.fats), color: .gainsWarning)
                    }
                    
                    // Foods
                    if !meal.foods.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Ingredients")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.gainsText)
                            
                            ForEach(meal.foods) { food in
                                HStack {
                                    Text("• \(food.name)")
                                        .font(.system(size: 13))
                                        .foregroundColor(.gainsText)
                                    
                                    Spacer()
                                    
                                    Text(food.quantity)
                                        .font(.system(size: 12))
                                        .foregroundColor(.gainsSecondaryText)
                                }
                            }
                        }
                    }
                    
                    // Notes
                    if let notes = meal.notes {
                        Text(notes)
                            .font(.system(size: 12))
                            .foregroundColor(.gainsSecondaryText)
                            .padding(10)
                            .background(Color.gainsCardBackground.opacity(0.5))
                            .cornerRadius(8)
                    }
                }
                .padding()
            }
        }
        .background(Color.gainsCardBackground)
        .cornerRadius(12)
    }
    
    private func macroLabel(_ label: String, value: Int, color: Color) -> some View {
        HStack(spacing: 4) {
            Text(label)
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(color)
            Text("\(value)g")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.gainsText)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(color.opacity(0.15))
        .cornerRadius(6)
    }
}

#Preview {
    NavigationView {
        DietaryPlanDetailView(
            plan: DietaryPlan(
                name: "High Protein Plan",
                description: "A plan focused on lean muscle building",
                dailyCalories: 2500,
                mealCount: 4,
                meals: [
                    MealPlanDay(
                        dayName: "Monday",
                        dayNumber: 1,
                        meals: [
                            PlannedMeal(
                                name: "Scrambled Eggs with Toast",
                                mealType: .breakfast,
                                foods: [
                                    PlannedFood(name: "Eggs", quantity: "3 large", calories: 210, protein: 18, carbs: 1, fats: 15),
                                    PlannedFood(name: "Whole Wheat Toast", quantity: "2 slices", calories: 140, protein: 6, carbs: 24, fats: 2)
                                ],
                                calories: 350,
                                protein: 24,
                                carbs: 25,
                                fats: 17,
                                prepTime: 10,
                                notes: "Use olive oil for cooking"
                            )
                        ],
                        notes: "Start the week strong!"
                    )
                ]
            ),
            planService: DietaryPlanService()
        )
    }
}

