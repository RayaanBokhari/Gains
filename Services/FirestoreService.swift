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
