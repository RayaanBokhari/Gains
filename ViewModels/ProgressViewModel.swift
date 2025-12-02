//
//  ProgressViewModel.swift
//  Gains
//
//  Created by Rayaan Bokhari on 11/21/25.
//

import Foundation
import SwiftUI
import Combine
import FirebaseAuth

enum TimeRange: String, CaseIterable {
    case week = "7 Days"
    case month = "30 Days"
    case quarter = "90 Days"
    case allTime = "All Time"
    
    var days: Int? {
        switch self {
        case .week: return 7
        case .month: return 30
        case .quarter: return 90
        case .allTime: return nil
        }
    }
}

@MainActor
class ProgressViewModel: ObservableObject {
    @Published var dailyLogs: [DailyLog] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var selectedRange: TimeRange = .month
    
    private let firestore = FirestoreService.shared
    private let auth = AuthService.shared
    
    func loadProgress() async {
        guard let user = auth.user else { return }
        
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        let endDate = Date()
        let startDate: Date
        
        if let days = selectedRange.days {
            startDate = Calendar.current.date(byAdding: .day, value: -days, to: endDate) ?? endDate
        } else {
            // All time - go back 1 year
            startDate = Calendar.current.date(byAdding: .year, value: -1, to: endDate) ?? endDate
        }
        
        do {
            dailyLogs = try await firestore.fetchDailyLogsRange(
                userId: user.uid,
                from: startDate,
                to: endDate
            )
        } catch {
            errorMessage = "Failed to load progress: \(error.localizedDescription)"
            print("Error loading progress: \(error)")
        }
    }
    
    // Computed properties for statistics
    var averageCalories: Double {
        guard !dailyLogs.isEmpty else { return 0 }
        let total = dailyLogs.reduce(0) { $0 + $1.calories }
        return Double(total) / Double(dailyLogs.count)
    }
    
    var averageProtein: Double {
        guard !dailyLogs.isEmpty else { return 0 }
        let total = dailyLogs.reduce(0) { $0 + $1.protein }
        return Double(total) / Double(dailyLogs.count)
    }
    
    var averageCarbs: Double {
        guard !dailyLogs.isEmpty else { return 0 }
        let total = dailyLogs.reduce(0) { $0 + $1.carbs }
        return Double(total) / Double(dailyLogs.count)
    }
    
    var averageFats: Double {
        guard !dailyLogs.isEmpty else { return 0 }
        let total = dailyLogs.reduce(0) { $0 + $1.fats }
        return Double(total) / Double(dailyLogs.count)
    }
    
    var totalCalories: Int {
        dailyLogs.reduce(0) { $0 + $1.calories }
    }
}

