//
//  DietaryPlan.swift
//  Gains
//
//  Created by Rayaan Bokhari on 12/20/25.
//

import Foundation

struct DietaryPlan: Identifiable, Codable {
    let id: UUID
    var planId: String? // Firestore document ID
    var name: String
    var description: String?
    var goal: FitnessGoal?
    var dailyCalories: Int
    var macros: MacroTargets
    var mealCount: Int // Number of meals per day
    var meals: [MealPlanDay] // Weekly meal templates
    var createdAt: Date
    var createdBy: PlanCreator
    var isActive: Bool
    var isRetired: Bool
    var retiredAt: Date?
    var dietType: DietType?
    var restrictions: [String]? // Allergies, dislikes
    var durationWeeks: Int
    
    struct MacroTargets: Codable {
        var protein: Double // grams
        var carbs: Double // grams
        var fats: Double // grams
        
        var proteinCalories: Int { Int(protein * 4) }
        var carbsCalories: Int { Int(carbs * 4) }
        var fatsCalories: Int { Int(fats * 9) }
        var totalCalories: Int { proteinCalories + carbsCalories + fatsCalories }
    }
    
    init(
        id: UUID = UUID(),
        name: String,
        description: String? = nil,
        goal: FitnessGoal? = nil,
        dailyCalories: Int = 2000,
        macros: MacroTargets = MacroTargets(protein: 150, carbs: 200, fats: 65),
        mealCount: Int = 3,
        meals: [MealPlanDay] = [],
        createdBy: PlanCreator = .user,
        dietType: DietType? = nil,
        restrictions: [String]? = nil,
        durationWeeks: Int = 4
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.goal = goal
        self.dailyCalories = dailyCalories
        self.macros = macros
        self.mealCount = mealCount
        self.meals = meals
        self.createdAt = Date()
        self.createdBy = createdBy
        self.isActive = false
        self.isRetired = false
        self.retiredAt = nil
        self.dietType = dietType
        self.restrictions = restrictions
        self.durationWeeks = durationWeeks
    }
}

struct MealPlanDay: Identifiable, Codable {
    let id: UUID
    var dayName: String // e.g., "Monday" or "Day 1"
    var dayNumber: Int
    var meals: [PlannedMeal]
    var notes: String?
    
    init(id: UUID = UUID(), dayName: String, dayNumber: Int, meals: [PlannedMeal] = [], notes: String? = nil) {
        self.id = id
        self.dayName = dayName
        self.dayNumber = dayNumber
        self.meals = meals
        self.notes = notes
    }
    
    var totalCalories: Int {
        meals.reduce(0) { $0 + $1.calories }
    }
    
    var totalProtein: Double {
        meals.reduce(0) { $0 + $1.protein }
    }
    
    var totalCarbs: Double {
        meals.reduce(0) { $0 + $1.carbs }
    }
    
    var totalFats: Double {
        meals.reduce(0) { $0 + $1.fats }
    }
}

struct PlannedMeal: Identifiable, Codable {
    let id: UUID
    var name: String // e.g., "Breakfast", "Lunch", "Dinner", "Snack"
    var mealType: MealType
    var foods: [PlannedFood]
    var calories: Int
    var protein: Double
    var carbs: Double
    var fats: Double
    var prepTime: Int? // minutes
    var notes: String?
    var alternatives: [String]? // Alternative meal ideas
    
    init(
        id: UUID = UUID(),
        name: String,
        mealType: MealType = .lunch,
        foods: [PlannedFood] = [],
        calories: Int = 0,
        protein: Double = 0,
        carbs: Double = 0,
        fats: Double = 0,
        prepTime: Int? = nil,
        notes: String? = nil,
        alternatives: [String]? = nil
    ) {
        self.id = id
        self.name = name
        self.mealType = mealType
        self.foods = foods
        self.calories = calories
        self.protein = protein
        self.carbs = carbs
        self.fats = fats
        self.prepTime = prepTime
        self.notes = notes
        self.alternatives = alternatives
    }
}

struct PlannedFood: Identifiable, Codable {
    let id: UUID
    var name: String
    var quantity: String // e.g., "1 cup", "200g", "2 slices"
    var calories: Int
    var protein: Double
    var carbs: Double
    var fats: Double
    
    init(
        id: UUID = UUID(),
        name: String,
        quantity: String = "1 serving",
        calories: Int = 0,
        protein: Double = 0,
        carbs: Double = 0,
        fats: Double = 0
    ) {
        self.id = id
        self.name = name
        self.quantity = quantity
        self.calories = calories
        self.protein = protein
        self.carbs = carbs
        self.fats = fats
    }
}

enum MealType: String, Codable, CaseIterable {
    case breakfast = "Breakfast"
    case morningSnack = "Morning Snack"
    case lunch = "Lunch"
    case afternoonSnack = "Afternoon Snack"
    case dinner = "Dinner"
    case eveningSnack = "Evening Snack"
}

