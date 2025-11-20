//
//  NutritionViewModel.swift
//  Gains
//
//  Created by Rayaan Bokhari on 11/20/25.
//

import Foundation
import SwiftUI
import Combine

class NutritionViewModel: ObservableObject {
    @Published var dailyNutrition: DailyNutrition
    @Published var recentFoods: [Food] = []
    
    init() {
        self.dailyNutrition = DailyNutrition()
        // Sample data for mockup - matching the displayed values
        let sampleFood = Food(name: "Avocado Sandwich", calories: 350, protein: 12, carbs: 45, fats: 15, loggedAt: Date())
        self.dailyNutrition.foods = [sampleFood]
        self.dailyNutrition.caloriesConsumed = 898 // 2460 - 1562
        self.dailyNutrition.proteinConsumed = 112.5 // Some protein consumed
        self.dailyNutrition.carbsConsumed = 102 // Matching mockup
        self.dailyNutrition.fatsConsumed = 102 // Matching mockup circle (102g shown)
        self.recentFoods = [sampleFood]
    }
    
    func addFood(_ food: Food) {
        dailyNutrition.foods.append(food)
        dailyNutrition.caloriesConsumed += food.calories
        dailyNutrition.proteinConsumed += food.protein
        dailyNutrition.carbsConsumed += food.carbs
        dailyNutrition.fatsConsumed += food.fats
        recentFoods.insert(food, at: 0)
    }
    
    func addWater(_ ounces: Double) {
        dailyNutrition.waterConsumed += ounces
    }
}

