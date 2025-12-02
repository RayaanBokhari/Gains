//
//  FirestoreService.swift
//  Gains
//
//  Created by Rayaan Bokhari on 11/20/25.
//
import Foundation
import FirebaseFirestore

final class FirestoreService {
    static let shared = FirestoreService()
    private init() {}
    
    private let db = Firestore.firestore()
    
    // MARK: - Daily Logs
    
    func saveDailyLog(userId: String, log: DailyLog) async throws {
        let logId = log.id ?? Self.todayId()
        
        let docRef = db
            .collection("users")
            .document(userId)
            .collection("dailyLogs")
            .document(logId)
        
        var data = try Firestore.Encoder().encode(log)
        // Ensure ID is consistent
        data["id"] = logId
        
        try await docRef.setData(data, merge: true)
    }
    
    func fetchDailyLog(userId: String, for date: Date) async throws -> DailyLog? {
        let logId = Self.id(for: date)
        
        let docRef = db
            .collection("users")
            .document(userId)
            .collection("dailyLogs")
            .document(logId)
        
        let snapshot = try await docRef.getDocument()
        guard snapshot.exists else { return nil }
        
        var log = try snapshot.data(as: DailyLog.self)
        log.id = logId
        return log
    }
    
    // MARK: - Meals
    
    func saveMeal(userId: String, food: Food, toDate date: Date) async throws {
        let logId = Self.id(for: date)
        
        let mealRef = db
            .collection("users")
            .document(userId)
            .collection("meals")
            .document()
        
        var mealData: [String: Any] = [
            "id": mealRef.documentID,
            "name": food.name,
            "calories": food.calories,
            "protein": food.protein,
            "carbs": food.carbs,
            "fats": food.fats,
            "loggedAt": Timestamp(date: food.loggedAt),
            "date": Self.id(for: date)
        ]
        
        // Add photo URL if present
        if let photoUrl = food.photoUrl {
            mealData["photoUrl"] = photoUrl
        }
        
        try await mealRef.setData(mealData)
        
        // Update the daily log to include this meal and update totals
        let logRef = db
            .collection("users")
            .document(userId)
            .collection("dailyLogs")
            .document(logId)
        
        try await logRef.setData([
            "id": logId,
            "date": Timestamp(date: date),
            "calories": FieldValue.increment(Int64(food.calories)),
            "protein": FieldValue.increment(Int64(food.protein)),
            "carbs": FieldValue.increment(Int64(food.carbs)),
            "fats": FieldValue.increment(Int64(food.fats)),
            "mealIds": FieldValue.arrayUnion([mealRef.documentID])
        ], merge: true)
    }
    
    func fetchMeals(userId: String, for date: Date) async throws -> [Food] {
        let dateId = Self.id(for: date)
        
        // Query by date only (no orderBy to avoid index requirement)
        // We'll sort in memory instead
        let snapshot = try await db
            .collection("users")
            .document(userId)
            .collection("meals")
            .whereField("date", isEqualTo: dateId)
            .getDocuments()
        
        let meals = snapshot.documents.compactMap { doc -> Food? in
            let data = doc.data()
            
            // Handle calories - could be Int or Double
            var calories: Int = 0
            if let calInt = data["calories"] as? Int {
                calories = calInt
            } else if let calDouble = data["calories"] as? Double {
                calories = Int(calDouble)
            } else {
                return nil
            }
            
            // Handle macros - could be Double or Int
            var protein: Double = 0
            var carbs: Double = 0
            var fats: Double = 0
            
            if let p = data["protein"] as? Double {
                protein = p
            } else if let p = data["protein"] as? Int {
                protein = Double(p)
            } else {
                return nil
            }
            
            if let c = data["carbs"] as? Double {
                carbs = c
            } else if let c = data["carbs"] as? Int {
                carbs = Double(c)
            } else {
                return nil
            }
            
            if let f = data["fats"] as? Double {
                fats = f
            } else if let f = data["fats"] as? Int {
                fats = Double(f)
            } else {
                return nil
            }
            
            guard let name = data["name"] as? String,
                  let timestamp = data["loggedAt"] as? Timestamp else {
                return nil
            }
            
            let photoUrl = data["photoUrl"] as? String
            
            return Food(
                id: UUID(),
                name: name,
                calories: calories,
                protein: protein,
                carbs: carbs,
                fats: fats,
                loggedAt: timestamp.dateValue(),
                photoUrl: photoUrl,
                mealId: doc.documentID
            )
        }
        
        // Sort by loggedAt descending in memory
        return meals.sorted { $0.loggedAt > $1.loggedAt }
    }
    
    func updateMeal(userId: String, mealId: String, food: Food, oldFood: Food, toDate date: Date) async throws {
        let dateId = Self.id(for: date)
        
        let mealRef = db
            .collection("users")
            .document(userId)
            .collection("meals")
            .document(mealId)
        
        var mealData: [String: Any] = [
            "id": mealId,
            "name": food.name,
            "calories": food.calories,
            "protein": food.protein,
            "carbs": food.carbs,
            "fats": food.fats,
            "loggedAt": Timestamp(date: food.loggedAt),
            "date": dateId
        ]
        
        // Add photo URL if present
        if let photoUrl = food.photoUrl {
            mealData["photoUrl"] = photoUrl
        } else {
            // Remove photoUrl field if it was removed
            mealData["photoUrl"] = FieldValue.delete()
        }
        
        try await mealRef.setData(mealData, merge: true)
        
        // Update the daily log totals
        // Subtract old values, add new values
        let logRef = db
            .collection("users")
            .document(userId)
            .collection("dailyLogs")
            .document(dateId)
        
        let caloriesDiff = food.calories - oldFood.calories
        let proteinDiff = food.protein - oldFood.protein
        let carbsDiff = food.carbs - oldFood.carbs
        let fatsDiff = food.fats - oldFood.fats
        
        try await logRef.setData([
            "id": dateId,
            "date": Timestamp(date: date),
            "calories": FieldValue.increment(Int64(caloriesDiff)),
            "protein": FieldValue.increment(proteinDiff),
            "carbs": FieldValue.increment(carbsDiff),
            "fats": FieldValue.increment(fatsDiff)
        ], merge: true)
    }
    
    func deleteMeal(userId: String, mealId: String, food: Food, fromDate date: Date) async throws {
        let dateId = Self.id(for: date)
        
        // Delete the meal document
        let mealRef = db
            .collection("users")
            .document(userId)
            .collection("meals")
            .document(mealId)
        
        try await mealRef.delete()
        
        // Update the daily log totals (subtract the meal's values)
        let logRef = db
            .collection("users")
            .document(userId)
            .collection("dailyLogs")
            .document(dateId)
        
        try await logRef.setData([
            "id": dateId,
            "date": Timestamp(date: date),
            "calories": FieldValue.increment(Int64(-food.calories)),
            "protein": FieldValue.increment(-food.protein),
            "carbs": FieldValue.increment(-food.carbs),
            "fats": FieldValue.increment(-food.fats),
            "mealIds": FieldValue.arrayRemove([mealId])
        ], merge: true)
    }
    
    // MARK: - User Profile
    
    func saveUserProfile(userId: String, profile: UserProfile) async throws {
        let profileRef = db
            .collection("users")
            .document(userId)
            .collection("profile")
            .document("data")
        
        var data = try Firestore.Encoder().encode(profile)
        // Ensure dateJoined is stored as Timestamp
        data["dateJoined"] = Timestamp(date: profile.dateJoined)
        
        try await profileRef.setData(data, merge: true)
    }
    
    func fetchUserProfile(userId: String) async throws -> UserProfile? {
        let profileRef = db
            .collection("users")
            .document(userId)
            .collection("profile")
            .document("data")
        
        let snapshot = try await profileRef.getDocument()
        guard snapshot.exists else { return nil }
        
        return try snapshot.data(as: UserProfile.self)
    }
    
    // MARK: - Helpers
    
    static func todayId() -> String {
        id(for: Date())
    }
    
    static func id(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter.string(from: date)
    }
}
