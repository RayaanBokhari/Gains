//
//  SavedMealPlanView.swift
//  Gains
//
//  Created by Rayaan Bokhari on 12/10/25.
//

import SwiftUI

struct SavedMealPlanView: View {
    @Environment(\.dismiss) var dismiss
    
    let meals: [PlannedMeal]
    var onClear: (() -> Void)?
    
    // Calculate totals
    private var totalCalories: Int {
        meals.reduce(0) { $0 + $1.calories }
    }
    
    private var totalProtein: Double {
        meals.reduce(0) { $0 + $1.protein }
    }
    
    private var totalCarbs: Double {
        meals.reduce(0) { $0 + $1.carbs }
    }
    
    private var totalFats: Double {
        meals.reduce(0) { $0 + $1.fats }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.gainsBackground.ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Summary Card
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Plan Summary")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.gainsText)
                            
                            HStack(spacing: 16) {
                                summaryItem("Calories", value: "\(totalCalories)", color: .gainsPrimary)
                                summaryItem("Protein", value: "\(Int(totalProtein))g", color: Color(hex: "FF6B6B"))
                                summaryItem("Carbs", value: "\(Int(totalCarbs))g", color: .gainsPrimary)
                                summaryItem("Fats", value: "\(Int(totalFats))g", color: Color(hex: "FFD93D"))
                            }
                        }
                        .padding()
                        .background(Color.gainsCardBackground)
                        .cornerRadius(12)
                        
                        // Meals
                        Text("Suggested Meals")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.gainsText)
                        
                        ForEach(meals) { meal in
                            MealPlanCard(meal: meal)
                        }
                        
                        // Clear Button
                        Button {
                            onClear?()
                            dismiss()
                        } label: {
                            HStack {
                                Image(systemName: "trash")
                                Text("Clear Meal Plan")
                            }
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(12)
                        }
                        .padding(.top, 8)
                    }
                    .padding()
                }
            }
            .navigationTitle("Today's Meal Plan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.gainsPrimary)
                }
            }
        }
    }
    
    private func summaryItem(_ label: String, value: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(.gainsSecondaryText)
            Text(value)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Meal Plan Card
struct MealPlanCard: View {
    let meal: PlannedMeal
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header (always visible)
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(meal.name)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.gainsText)
                        
                        HStack(spacing: 12) {
                            Text("\(meal.calories) cal")
                                .foregroundColor(.gainsSecondaryText)
                            Text("P: \(Int(meal.protein))g")
                                .foregroundColor(Color(hex: "FF6B6B"))
                            Text("C: \(Int(meal.carbs))g")
                                .foregroundColor(.gainsPrimary)
                            Text("F: \(Int(meal.fats))g")
                                .foregroundColor(Color(hex: "FFD93D"))
                        }
                        .font(.system(size: 12))
                    }
                    
                    Spacer()
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.gainsTextMuted)
                }
                .padding()
            }
            .buttonStyle(.plain)
            
            // Expanded content
            if isExpanded {
                VStack(alignment: .leading, spacing: 8) {
                    Divider()
                        .background(Color.gainsBackground)
                    
                    // Foods
                    ForEach(meal.foods) { food in
                        HStack {
                            Text("• \(food.name)")
                                .font(.system(size: 14))
                                .foregroundColor(.gainsText)
                            Spacer()
                            Text(food.quantity)
                                .font(.system(size: 13))
                                .foregroundColor(.gainsSecondaryText)
                            Text("\(food.calories) cal")
                                .font(.system(size: 12))
                                .foregroundColor(.gainsTextMuted)
                        }
                    }
                    
                    // Prep time and notes
                    if let prepTime = meal.prepTime {
                        HStack(spacing: 4) {
                            Image(systemName: "clock")
                                .font(.system(size: 11))
                            Text("\(prepTime) min prep")
                                .font(.system(size: 12))
                        }
                        .foregroundColor(.gainsSecondaryText)
                        .padding(.top, 4)
                    }
                    
                    if let notes = meal.notes, !notes.isEmpty {
                        Text(notes)
                            .font(.system(size: 13))
                            .foregroundColor(.gainsSecondaryText)
                            .italic()
                            .padding(.top, 2)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
        }
        .background(Color.gainsCardBackground)
        .cornerRadius(12)
    }
}

#Preview {
    SavedMealPlanView(
        meals: [
            PlannedMeal(
                name: "Grilled Chicken Salad",
                mealType: .lunch,
                foods: [
                    PlannedFood(name: "Grilled Chicken", quantity: "6 oz", calories: 276, protein: 52, carbs: 0, fats: 6),
                    PlannedFood(name: "Mixed Greens", quantity: "2 cups", calories: 20, protein: 2, carbs: 4, fats: 0)
                ],
                calories: 400,
                protein: 54,
                carbs: 10,
                fats: 12,
                prepTime: 15,
                notes: "Use olive oil dressing"
            ),
            PlannedMeal(
                name: "Protein Smoothie",
                mealType: .afternoonSnack,
                foods: [
                    PlannedFood(name: "Whey Protein", quantity: "1 scoop", calories: 120, protein: 25, carbs: 2, fats: 1),
                    PlannedFood(name: "Banana", quantity: "1 medium", calories: 105, protein: 1, carbs: 27, fats: 0)
                ],
                calories: 300,
                protein: 26,
                carbs: 35,
                fats: 5,
                prepTime: 5,
                notes: nil
            )
        ]
    )
}

