//
//  DailyLog.swift
//  Gains
//
//  Created by Rayaan Bokhari on 11/20/25.
//

import Foundation
import FirebaseFirestore

struct DailyLog: Codable, Identifiable {
    var id: String?
    
    var date: Date
    var calories: Int
    var protein: Int
    var carbs: Int
    var fats: Int
    var waterOunces: Int
    var mealIds: [String]
    
    init(
        id: String? = nil,
        date: Date = Date(),
        calories: Int = 0,
        protein: Int = 0,
        carbs: Int = 0,
        fats: Int = 0,
        waterOunces: Int = 0,
        mealIds: [String] = []
    ) {
        self.id = id
        self.date = date
        self.calories = calories
        self.protein = protein
        self.carbs = carbs
        self.fats = fats
        self.waterOunces = waterOunces
        self.mealIds = mealIds
    }
}
