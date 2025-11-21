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
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let chatGPTService: ChatGPTService
    private let userContextService: UserContextService
    
    init(userContextService: UserContextService = UserContextService()) {
        self.userContextService = userContextService
        self.chatGPTService = ChatGPTService()
        
        // Add welcome message if no messages exist
        if messages.isEmpty {
            let welcomeMessage = ChatMessage(
                content: "Hi! I'm your AI fitness coach. I can help you with nutrition tracking, meal planning, and fitness advice. What would you like to know?",
                isUser: false
            )
            messages.append(welcomeMessage)
        }
    }
    
    func setNutritionViewModel(_ viewModel: NutritionViewModel) {
        userContextService.nutritionViewModel = viewModel
    }
    
    func setProfileViewModel(_ viewModel: ProfileViewModel) {
        userContextService.profileViewModel = viewModel
    }
    
    func sendMessage(_ content: String) {
        guard !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        // Add user message
        let userMessage = ChatMessage(content: content, isUser: true)
        messages.append(userMessage)
        
        // Show loading state
        isLoading = true
        errorMessage = nil
        
        // Build messages for API
        var apiMessages: [ChatGPTRequest.Message] = []
        
        // Add system prompt with user context
        let systemPrompt = userContextService.buildSystemPrompt()
        apiMessages.append(ChatGPTRequest.Message(role: "system", content: systemPrompt))
        
        // Add conversation history (last 10 messages to keep context manageable)
        let recentMessages = messages.suffix(10)
        for message in recentMessages {
            apiMessages.append(ChatGPTRequest.Message(
                role: message.isUser ? "user" : "assistant",
                content: message.content
            ))
        }
        
        // Send to Firebase Function
        Task {
            do {
                let response = try await chatGPTService.sendMessage(messages: apiMessages)
                
                await MainActor.run {
                    let aiResponse = ChatMessage(content: response, isUser: false)
                    messages.append(aiResponse)
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = error.localizedDescription
                    let errorMsg = ChatMessage(
                        content: "Sorry, I encountered an error: \(error.localizedDescription). Please try again.",
                        isUser: false
                    )
                    messages.append(errorMsg)
                }
            }
        }
    }
    
    func retryLastMessage() {
        guard let lastUserMessage = messages.last(where: { $0.isUser }) else { return }
        // Remove the last AI response if it was an error
        if let lastMessage = messages.last, !lastMessage.isUser {
            messages.removeLast()
        }
        sendMessage(lastUserMessage.content)
    }
}

