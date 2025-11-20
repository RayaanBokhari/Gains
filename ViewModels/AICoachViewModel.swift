//
//  AICoachViewModel.swift
//  Gains
//
//  Created by Rayaan Bokhari on 11/20/25.
//

import Foundation
import SwiftUI
import Combine

class AICoachViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    
    init() {
        // Sample messages for mockup
        messages = [
            ChatMessage(content: "How many calories did I eat today?", isUser: true),
            ChatMessage(content: "What are some high-protein snacks?", isUser: true),
            ChatMessage(content: "Here are some ideas for high-protein snacks:\n• Greek yogurt\n• Cottage cheese\n• Protein bar\n• Hard-boiled eggs", isUser: false)
        ]
    }
    
    func sendMessage(_ content: String) {
        let userMessage = ChatMessage(content: content, isUser: true)
        messages.append(userMessage)
        
        // Simulate AI response
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            let aiResponse = ChatMessage(content: "I understand you're asking about \(content). Here's some helpful information...", isUser: false)
            self.messages.append(aiResponse)
        }
    }
}

