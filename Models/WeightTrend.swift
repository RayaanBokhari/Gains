//
//  WeightTrend.swift
//  Gains
//
//  Created by Rayaan Bokhari on 12/20/25.
//

import Foundation

struct WeightEntry: Identifiable, Codable, Equatable {
    let id: UUID
    var weight: Double
    var date: Date
    var notes: String?
    var entryId: String? // Firestore document ID
    
    init(id: UUID = UUID(), weight: Double, date: Date = Date(), notes: String? = nil, entryId: String? = nil) {
        self.id = id
        self.weight = weight
        self.date = date
        self.notes = notes
        self.entryId = entryId
    }
    
    static func == (lhs: WeightEntry, rhs: WeightEntry) -> Bool {
        return lhs.id == rhs.id
    }
}

struct WeightTrend {
    let entries: [WeightEntry]
    
    var currentWeight: Double? { entries.first?.weight }
    var weekAgoWeight: Double? {
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
        return entries.first { $0.date <= weekAgo }?.weight
    }
    var monthAgoWeight: Double? {
        let monthAgo = Calendar.current.date(byAdding: .month, value: -1, to: Date())!
        return entries.first { $0.date <= monthAgo }?.weight
    }
    
    var weeklyChange: Double? {
        guard let current = currentWeight, let weekAgo = weekAgoWeight else { return nil }
        return current - weekAgo
    }
    
    var monthlyChange: Double? {
        guard let current = currentWeight, let monthAgo = monthAgoWeight else { return nil }
        return current - monthAgo
    }
    
    var trendDescription: String {
        guard let weekly = weeklyChange else { return "Not enough data" }
        if abs(weekly) < 0.2 { return "Stable" }
        return weekly > 0 ? "Gaining \(String(format: "%.1f", weekly)) kg/week" : "Losing \(String(format: "%.1f", abs(weekly))) kg/week"
    }
}

