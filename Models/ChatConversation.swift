//
//  ChatConversation.swift
//  Gains
//
//  Created by Rayaan Bokhari on 12/20/25.
//

import Foundation

struct ChatConversation: Identifiable, Codable {
    let id: UUID
    var title: String
    var messages: [ChatMessage]
    var createdAt: Date
    var lastUpdated: Date
    
    init(id: UUID = UUID(), title: String = "New Conversation", messages: [ChatMessage] = []) {
        self.id = id
        self.title = title
        self.messages = messages
        self.createdAt = Date()
        self.lastUpdated = Date()
    }
    
    mutating func addMessage(_ message: ChatMessage) {
        messages.append(message)
        lastUpdated = Date()
        
        // Auto-generate title from first user message if still default
        if title == "New Conversation",
           let firstUserMessage = messages.first(where: { $0.isUser }) {
            title = String(firstUserMessage.content.prefix(50))
            if firstUserMessage.content.count > 50 {
                title += "..."
            }
        }
    }
}

