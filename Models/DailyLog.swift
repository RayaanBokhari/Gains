//
//  DailyLog.swift
//  Gains
//
//  Created by Rayaan Bokhari on 11/20/25.
//

import Foundation
import FirebaseFirestore

struct DailyLog: Identifiable {
    let id: String                 // Firestore doc ID (e.g. "2025-02-20")
    
    var date: Date                 // actual date for convenience
    
    var calories: Int
    var protein: Int
    var carbs: Int
    var fats: Int
    
    var waterOunces: Int
    
    // List of meal IDs if you store meals separately
    var mealIds: [String]
    
    // Default initializer for a blank day. If id is nil, derive it from the date as yyyy-MM-dd
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
        self.id = id ?? DailyLog.dateFormatter.string(from: date)
        self.date = date
        self.calories = calories
        self.protein = protein
        self.carbs = carbs
        self.fats = fats
        self.waterOunces = waterOunces
        self.mealIds = mealIds
    }
    
    private static let dateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.calendar = Calendar(identifier: .gregorian)
        df.locale = Locale(identifier: "en_US_POSIX")
        df.timeZone = TimeZone(secondsFromGMT: 0)
        df.dateFormat = "yyyy-MM-dd"
        return df
    }()
}

extension DailyLog {
    init?(id: String, data: [String: Any]) {
        guard
            let ts = data["date"] as? Timestamp,
            let calories = data["calories"] as? Int,
            let protein = data["protein"] as? Int,
            let carbs = data["carbs"] as? Int,
            let fats = data["fats"] as? Int,
            let waterOunces = data["waterOunces"] as? Int,
            let mealIds = data["mealIds"] as? [String]
        else { return nil }
        
        self.id = id
        self.date = ts.dateValue()
        self.calories = calories
        self.protein = protein
        self.carbs = carbs
        self.fats = fats
        self.waterOunces = waterOunces
        self.mealIds = mealIds
    }
    
    var asDict: [String: Any] {
        [
            "date": Timestamp(date: date),
            "calories": calories,
            "protein": protein,
            "carbs": carbs,
            "fats": fats,
            "waterOunces": waterOunces,
            "mealIds": mealIds
        ]
    }
}
