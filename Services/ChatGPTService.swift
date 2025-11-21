//
//  ChatGPTService.swift
//  Gains
//
//  Created by Rayaan Bokhari on 11/20/25.
//

import Foundation
import Combine

struct ChatGPTResponse: Codable {
    let choices: [Choice]
    
    struct Choice: Codable {
        let message: Message
    }
    
    struct Message: Codable {
        let role: String
        let content: String
    }
}

struct ChatGPTRequest: Codable {
    let model: String
    let messages: [Message]
    let temperature: Double
    
    struct Message: Codable {
        let role: String
        let content: String
    }
}

class ChatGPTService: ObservableObject {
    private let apiKey: String
    private let baseURL = "https://api.openai.com/v1/chat/completions"
    
    init(apiKey: String) {
        self.apiKey = apiKey
    }
    
    func sendMessage(messages: [ChatGPTRequest.Message]) async throws -> String {
        // Using gpt-4o-mini: Best balance of cost ($0.15/$0.60 per 1M tokens) and performance
        // Alternatives:
        // - "gpt-3.5-turbo": Cheaper ($0.50/$1.50) but less capable
        // - "gpt-4o": More capable ($2.50/$10.00) but more expensive
        let request = ChatGPTRequest(
            model: "gpt-4o-mini",
            messages: messages,
            temperature: 0.7
        )
        
        guard let url = URL(string: baseURL) else {
            throw NSError(domain: "ChatGPTService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            urlRequest.httpBody = try JSONEncoder().encode(request)
        } catch {
            throw NSError(domain: "ChatGPTService", code: -2, userInfo: [NSLocalizedDescriptionKey: "Failed to encode request: \(error.localizedDescription)"])
        }
        
        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "ChatGPTService", code: -3, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
        }
        
        guard httpResponse.statusCode == 200 else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw NSError(domain: "ChatGPTService", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "API error: \(errorMessage)"])
        }
        
        do {
            let chatResponse = try JSONDecoder().decode(ChatGPTResponse.self, from: data)
            return chatResponse.choices.first?.message.content ?? "No response"
        } catch {
            throw NSError(domain: "ChatGPTService", code: -4, userInfo: [NSLocalizedDescriptionKey: "Failed to decode response: \(error.localizedDescription)"])
        }
    }
}

