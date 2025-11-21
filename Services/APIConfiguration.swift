//
//  APIConfiguration.swift
//  Gains
//
//  Created by Rayaan Bokhari on 11/20/25.
//

import Foundation

class APIConfiguration {
    static let shared = APIConfiguration()
    
    private let apiKeyKey = "OpenAI_API_Key"
    
    var apiKey: String? {
        get {
            // First try to get from UserDefaults
            if let key = UserDefaults.standard.string(forKey: apiKeyKey), !key.isEmpty {
                return key
            }
            // Fallback to environment variable (useful for development)
            return ProcessInfo.processInfo.environment["OPENAI_API_KEY"]
        }
        set {
            UserDefaults.standard.set(newValue, forKey: apiKeyKey)
        }
    }
    
    var hasAPIKey: Bool {
        return apiKey != nil && !apiKey!.isEmpty
    }
    
    private init() {}
}

