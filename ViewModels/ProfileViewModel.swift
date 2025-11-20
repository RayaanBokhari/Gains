//
//  ProfileViewModel.swift
//  Gains
//
//  Created by Rayaan Bokhari on 11/20/25.
//

import Foundation
import SwiftUI
import Combine

class ProfileViewModel: ObservableObject {
    @Published var profile: UserProfile
    
    init() {
        var calendar = Calendar.current
        var components = DateComponents()
        components.year = 2025
        components.month = 4
        components.day = 23
        let dateJoined = calendar.date(from: components) ?? Date()
        self.profile = UserProfile(dateJoined: dateJoined)
    }
    
    var macroProgress: (protein: Double, carbs: Double, fats: Double) {
        // Sample progress: 25%, 90%, 25%
        return (0.25, 0.90, 0.25)
    }
}

