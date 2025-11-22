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
        
        let snapshot = try await db
            .collection("users")
            .document(userId)
            .collection("meals")
            .whereField("date", isEqualTo: dateId)
            .order(by: "loggedAt", descending: true)
            .getDocuments()
        
        return snapshot.documents.compactMap { doc in
            let data = doc.data()
            guard let name = data["name"] as? String,
                  let calories = data["calories"] as? Int,
                  let protein = data["protein"] as? Double,
                  let carbs = data["carbs"] as? Double,
                  let fats = data["fats"] as? Double,
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
                photoUrl: photoUrl
            )
        }
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
