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
    
    // Example: save a daily log
    func saveDailyLog(userId: String, log: DailyLog) async throws {
        let docRef = db
            .collection("users")
            .document(userId)
            .collection("dailyLogs")
            .document(log.id) // e.g. yyyy-MM-dd
        
        try await docRef.setData(log.asDict, merge: true)
    }
    
    // Example: fetch today’s log
    func fetchDailyLog(userId: String, id: String) async throws -> DailyLog? {
        let docRef = db
            .collection("users")
            .document(userId)
            .collection("dailyLogs")
            .document(id)
        
        let snapshot = try await docRef.getDocument()
        if let data = snapshot.data(), let log = DailyLog(id: snapshot.documentID, data: data) {
            return log
        }
        return nil
    }
}
