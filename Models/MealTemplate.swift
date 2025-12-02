//
//  MealTemplate.swift
//  Gains
//
//  Created by Rayaan Bokhari on 11/21/25.
//

import Foundation

struct MealTemplate: Identifiable, Codable {
    let id: UUID
    var name: String
    var calories: Int
    var protein: Double
    var carbs: Double
    var fats: Double
    var photoUrl: String?
    var mealTemplateId: String? // Firestore document ID
    var createdAt: Date
    
    init(
        id: UUID = UUID(),
        name: String,
        calories: Int,
        protein: Double,
        carbs: Double,
        fats: Double,
        photoUrl: String? = nil,
        mealTemplateId: String? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.calories = calories
        self.protein = protein
        self.carbs = carbs
        self.fats = fats
        self.photoUrl = photoUrl
        self.mealTemplateId = mealTemplateId
        self.createdAt = createdAt
    }
    
    // Convert to Food for logging
    func toFood(loggedAt: Date = Date()) -> Food {
        Food(
            name: name,
            calories: calories,
            protein: protein,
            carbs: carbs,
            fats: fats,
            loggedAt: loggedAt,
            photoUrl: photoUrl
        )
    }
}

