//
//  CommunityViewModel.swift
//  Gains
//
//  Created by Rayaan Bokhari on 11/20/25.
//

import Foundation
import SwiftUI
import Combine

class CommunityViewModel: ObservableObject {
    @Published var posts: [CommunityPost] = []
    @Published var stories: [String] = ["Stories", "Noles", "Sioma", "Han", "Utte"]
    
    init() {
        // Sample posts for mockup
        posts = [
            CommunityPost(
                userName: "Emily Moore",
                timeAgo: "#1 ago",
                text: "Lunch today!",
                calories: 948,
                protein: 72,
                carbs: 85,
                fats: 24
            ),
            CommunityPost(
                userName: "Jacob Carter",
                timeAgo: "Tue",
                text: "Hit my high carb goal"
            )
        ]
    }
}

