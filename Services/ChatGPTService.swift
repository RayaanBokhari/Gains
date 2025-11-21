//
//  ChatGPTService.swift
//  Gains
//
//  Created by Rayaan Bokhari on 11/20/25.
//

import Foundation
import Combine
import FirebaseFunctions
import FirebaseAuth

struct ChatGPTRequest: Codable {
    let messages: [Message]
    
    struct Message: Codable {
        let role: String
        let content: String
    }
}

struct ChatGPTResponse: Codable {
    let reply: String
}

class ChatGPTService: ObservableObject {
    private let functions = Functions.functions(region: "us-east4")
    
    init() {
        // No API key needed - handled by Firebase Functions
    }
    
    func sendMessage(messages: [ChatGPTRequest.Message]) async throws -> String {
        // Ensure user is authenticated
        guard Auth.auth().currentUser != nil else {
            throw NSError(
                domain: "ChatGPTService",
                code: -2,
                userInfo: [NSLocalizedDescriptionKey: "You must be signed in to use the AI coach."]
            )
        }
        
        let requestData: [String: Any] = [
            "messages": messages.map { [
                "role": $0.role,
                "content": $0.content
            ]}
        ]
        
        let function = functions.httpsCallable("aiChat")
        function.timeoutInterval = 60.0 // 60 second timeout
        
        do {
            let result = try await function.call(requestData)
            
            guard let data = result.data as? [String: Any],
                  let reply = data["reply"] as? String else {
                throw NSError(
                    domain: "ChatGPTService",
                    code: -1,
                    userInfo: [NSLocalizedDescriptionKey: "Invalid response format from server"]
                )
            }
            
            return reply
        } catch let error as NSError {
            // Handle Firebase Functions errors - extract detailed error info
            var errorMessage = "An unknown error occurred"
            
            // Firebase Functions errors have specific structure
            // Check for Firebase Functions error details
            if error.domain.contains("FunctionsError") || error.domain.contains("FIRFunctionsErrorDomain") {
                // Try to extract the error message from userInfo
                if let userInfo = error.userInfo as? [String: Any] {
                    // Check for message in various possible locations
                    if let message = userInfo["message"] as? String {
                        errorMessage = message
                    } else if let details = userInfo["details"] as? [String: Any],
                              let message = details["message"] as? String {
                        errorMessage = message
                    } else if let underlyingError = userInfo[NSUnderlyingErrorKey] as? NSError {
                        errorMessage = underlyingError.localizedDescription
                    } else {
                        errorMessage = error.localizedDescription
                    }
                } else {
                    errorMessage = error.localizedDescription
                }
            } else {
                // For other errors, use localized description
                errorMessage = error.localizedDescription
            }
            
            // Log the full error for debugging
            print("Firebase Functions Error:")
            print("  Domain: \(error.domain)")
            print("  Code: \(error.code)")
            print("  Description: \(error.localizedDescription)")
            print("  User Info: \(error.userInfo)")
            
            throw NSError(
                domain: "ChatGPTService",
                code: error.code,
                userInfo: [NSLocalizedDescriptionKey: errorMessage]
            )
        }
    }
}

