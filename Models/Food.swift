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
    var photoUrl: String? // Firebase Storage URL
    var mealId: String? // Firestore document ID for updates/deletes
    
    init(id: UUID = UUID(), name: String, calories: Int, protein: Double, carbs: Double, fats: Double, loggedAt: Date = Date(), photoUrl: String? = nil, mealId: String? = nil) {
        self.id = id
        self.name = name
        self.calories = calories
        self.protein = protein
        self.carbs = carbs
        self.fats = fats
        self.loggedAt = loggedAt
        self.photoUrl = photoUrl
        self.mealId = mealId
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
        guard proteinGoal > 0 else { return 0.0 }
        let progress = proteinConsumed / proteinGoal
        return min(1.0, max(0.0, progress.isFinite ? progress : 0.0))
    }
    
    var carbsProgress: Double {
        guard carbsGoal > 0 else { return 0.0 }
        let progress = carbsConsumed / carbsGoal
        return min(1.0, max(0.0, progress.isFinite ? progress : 0.0))
    }
    
    var fatsProgress: Double {
        guard fatsGoal > 0 else { return 0.0 }
        let progress = fatsConsumed / fatsGoal
        return min(1.0, max(0.0, progress.isFinite ? progress : 0.0))
    }
}

struct UserProfile: Codable {
    var name: String
    var dateJoined: Date
    var weight: Double // in kg (metric) or lbs (imperial)
    var height: String // e.g., "5 ft 10 in" (imperial) or "178 cm" (metric)
    var gender: String
    var dailyCaloriesGoal: Int
    var macros: MacroGoals
    var waterGoal: Double // in oz
    var useMetricUnits: Bool // true for metric (kg, cm), false for imperial (lbs, ft/in)
    
    struct MacroGoals: Codable {
        var protein: Double
        var carbs: Double
        var fats: Double
    }
    
    init(name: String = "Alex", dateJoined: Date = Date(), weight: Double = 116, height: String = "5 ft 10 in", gender: String = "Male", dailyCaloriesGoal: Int = 2460, macros: MacroGoals = MacroGoals(protein: 450, carbs: 202, fats: 33), waterGoal: Double = 96, useMetricUnits: Bool = false) {
        self.name = name
        self.dateJoined = dateJoined
        self.weight = weight
        self.height = height
        self.gender = gender
        self.dailyCaloriesGoal = dailyCaloriesGoal
        self.macros = macros
        self.waterGoal = waterGoal
        self.useMetricUnits = useMetricUnits
    }
}

struct CommunityPost: Identifiable, Codable {
    let id: UUID
    var userId: String
    var userName: String
    var userAvatar: String? // URL or system image name
    var timestamp: Date
    var text: String
    var imageUrl: String?
    var calories: Int?
    var protein: Double?
    var carbs: Double?
    var fats: Double?
    var likes: [String] // Array of user IDs who liked
    var likeCount: Int
    var postId: String? // Firestore document ID
    
    init(id: UUID = UUID(), userId: String, userName: String, userAvatar: String? = nil, timestamp: Date = Date(), text: String, imageUrl: String? = nil, calories: Int? = nil, protein: Double? = nil, carbs: Double? = nil, fats: Double? = nil, likes: [String] = [], likeCount: Int = 0, postId: String? = nil) {
        self.id = id
        self.userId = userId
        self.userName = userName
        self.userAvatar = userAvatar
        self.timestamp = timestamp
        self.text = text
        self.imageUrl = imageUrl
        self.calories = calories
        self.protein = protein
        self.carbs = carbs
        self.fats = fats
        self.likes = likes
        self.likeCount = likeCount
        self.postId = postId
    }
    
    // Computed property for timeAgo (for backward compatibility)
    var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: timestamp, relativeTo: Date())
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

