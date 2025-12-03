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
    @Published var currentConversation: ChatConversation
    @Published var conversations: [ChatConversation] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // Legacy support - computed property for messages
    var messages: [ChatMessage] {
        currentConversation.messages
    }
    
    private let chatGPTService: ChatGPTService
    let userContextService: UserContextService
    private let chatStorage = ChatStorageService.shared
    
    init(userContextService: UserContextService = UserContextService()) {
        self.userContextService = userContextService
        self.chatGPTService = ChatGPTService()
        self.currentConversation = ChatConversation()
        
        Task {
            await loadConversations()
            
            // Add welcome message if no messages exist
            await MainActor.run {
                if currentConversation.messages.isEmpty {
                    let welcomeMessage = ChatMessage(
                        content: "Hi! I'm your AI fitness coach. I can help you with nutrition tracking, meal planning, and fitness advice. What would you like to know?",
                        isUser: false
                    )
                    currentConversation.addMessage(welcomeMessage)
                    saveCurrentConversation()
                }
            }
        }
    }
    
    func setNutritionViewModel(_ viewModel: NutritionViewModel) {
        userContextService.nutritionViewModel = viewModel
    }
    
    func setProfileViewModel(_ viewModel: ProfileViewModel) {
        userContextService.profileViewModel = viewModel
    }
    
    func setWorkoutViewModel(_ viewModel: WorkoutViewModel) {
        userContextService.workoutViewModel = viewModel
    }
    
    func setHomeViewModel(_ viewModel: HomeViewModel) {
        userContextService.homeViewModel = viewModel
    }
    
    func loadConversations() async {
        do {
            let loaded = try await chatStorage.loadAllConversations()
            await MainActor.run {
                self.conversations = loaded
                // Load most recent or create new
                if let recent = loaded.first {
                    self.currentConversation = recent
                }
            }
        } catch {
            print("Failed to load conversations: \(error)")
        }
    }
    
    func saveCurrentConversation() {
        Task {
            do {
                try await chatStorage.saveConversation(currentConversation)
            } catch {
                print("Failed to save conversation: \(error)")
            }
        }
    }
    
    func startNewConversation() {
        saveCurrentConversation()
        currentConversation = ChatConversation()
        // Add welcome message
        let welcome = ChatMessage(
            content: "Hi! I'm your AI fitness coach. How can I help you today?",
            isUser: false
        )
        currentConversation.addMessage(welcome)
        saveCurrentConversation()
    }
    
    func selectConversation(_ conversation: ChatConversation) {
        saveCurrentConversation()
        currentConversation = conversation
    }
    
    func refreshConversationsList() async {
        await loadConversations()
    }
    
    func deleteConversation(_ conversation: ChatConversation) async {
        do {
            try await chatStorage.deleteConversation(id: conversation.id)
            await loadConversations()
            // If deleted conversation was current, start new one
            if currentConversation.id == conversation.id {
                startNewConversation()
            }
        } catch {
            print("Failed to delete conversation: \(error)")
        }
    }
    
    func sendMessage(_ content: String) {
        guard !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        // Add user message
        let userMessage = ChatMessage(content: content, isUser: true)
        currentConversation.addMessage(userMessage)
        saveCurrentConversation()
        
        // Show loading state
        isLoading = true
        errorMessage = nil
        
        // Build messages for API
        var apiMessages: [ChatGPTRequest.Message] = []
        
        // Add system prompt with user context
        let systemPrompt = userContextService.buildSystemPrompt()
        apiMessages.append(ChatGPTRequest.Message(role: "system", content: systemPrompt))
        
        // Add conversation history (last 10 messages to keep context manageable)
        let recentMessages = currentConversation.messages.suffix(10)
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
                    currentConversation.addMessage(aiResponse)
                    saveCurrentConversation()
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
                    currentConversation.addMessage(errorMsg)
                    saveCurrentConversation()
                }
            }
        }
    }
    
    func retryLastMessage() {
        guard let lastUserMessage = currentConversation.messages.last(where: { $0.isUser }) else { return }
        // Remove the last AI response if it was an error
        if let lastMessage = currentConversation.messages.last, !lastMessage.isUser {
            currentConversation.messages.removeLast()
        }
        sendMessage(lastUserMessage.content)
    }
}

