//
//  Food.swift
//  Gains
//
//  Created by Rayaan Bokhari on 11/20/25.
//

import Foundation

struct Food: Identifiable, Codable {
    let id: UUID
    var name: String
    var calories: Int
    var protein: Double // in grams
    var carbs: Double // in grams
    var fats: Double // in grams
    var loggedAt: Date
    
    init(id: UUID = UUID(), name: String, calories: Int, protein: Double, carbs: Double, fats: Double, loggedAt: Date = Date()) {
        self.id = id
        self.name = name
        self.calories = calories
        self.protein = protein
        self.carbs = carbs
        self.fats = fats
        self.loggedAt = loggedAt
    }
}

struct DailyNutrition: Codable {
    var caloriesConsumed: Int
    var caloriesGoal: Int
    var proteinConsumed: Double
    var proteinGoal: Double
    var carbsConsumed: Double
    var carbsGoal: Double
    var fatsConsumed: Double
    var fatsGoal: Double
    var waterConsumed: Double // in oz
    var waterGoal: Double // in oz
    var foods: [Food]
    
    init(caloriesGoal: Int = 2460, proteinGoal: Double = 450, carbsGoal: Double = 202, fatsGoal: Double = 33, waterGoal: Double = 96) {
        self.caloriesConsumed = 0
        self.caloriesGoal = caloriesGoal
        self.proteinConsumed = 0
        self.proteinGoal = proteinGoal
        self.carbsConsumed = 0
        self.carbsGoal = carbsGoal
        self.fatsConsumed = 0
        self.fatsGoal = fatsGoal
        self.waterConsumed = 0
        self.waterGoal = waterGoal
        self.foods = []
    }
    
    var caloriesRemaining: Int {
        max(0, caloriesGoal - caloriesConsumed)
    }
    
    var proteinProgress: Double {
        min(1.0, proteinConsumed / proteinGoal)
    }
    
    var carbsProgress: Double {
        min(1.0, carbsConsumed / carbsGoal)
    }
    
    var fatsProgress: Double {
        min(1.0, fatsConsumed / fatsGoal)
    }
}

struct UserProfile: Codable {
    var name: String
    var dateJoined: Date
    var weight: Double // in kg or lbs
    var height: String // e.g., "5 ft 10 in"
    var gender: String
    var dailyCaloriesGoal: Int
    var macros: MacroGoals
    var waterGoal: Double // in oz
    
    struct MacroGoals: Codable {
        var protein: Double
        var carbs: Double
        var fats: Double
    }
    
    init(name: String = "Alex", dateJoined: Date = Date(), weight: Double = 116, height: String = "5 ft 10 in", gender: String = "Male", dailyCaloriesGoal: Int = 2460, macros: MacroGoals = MacroGoals(protein: 450, carbs: 202, fats: 33), waterGoal: Double = 96) {
        self.name = name
        self.dateJoined = dateJoined
        self.weight = weight
        self.height = height
        self.gender = gender
        self.dailyCaloriesGoal = dailyCaloriesGoal
        self.macros = macros
        self.waterGoal = waterGoal
    }
}

struct CommunityPost: Identifiable, Codable {
    let id: UUID
    var userName: String
    var userAvatar: String? // URL or system image name
    var timeAgo: String
    var text: String
    var imageUrl: String?
    var calories: Int?
    var protein: Double?
    var carbs: Double?
    var fats: Double?
    
    init(id: UUID = UUID(), userName: String, userAvatar: String? = nil, timeAgo: String, text: String, imageUrl: String? = nil, calories: Int? = nil, protein: Double? = nil, carbs: Double? = nil, fats: Double? = nil) {
        self.id = id
        self.userName = userName
        self.userAvatar = userAvatar
        self.timeAgo = timeAgo
        self.text = text
        self.imageUrl = imageUrl
        self.calories = calories
        self.protein = protein
        self.carbs = carbs
        self.fats = fats
    }
}

struct ChatMessage: Identifiable, Codable {
    let id: UUID
    var content: String
    var isUser: Bool
    var timestamp: Date
    
    init(id: UUID = UUID(), content: String, isUser: Bool, timestamp: Date = Date()) {
        self.id = id
        self.content = content
        self.isUser = isUser
        self.timestamp = timestamp
    }
}

