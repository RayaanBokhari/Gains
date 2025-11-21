//
//  AuthService.swift
//  Gains
//
//  Created by Rayaan Bokhari on 11/20/25.
//
import Foundation
import Combine
import FirebaseAuth

final class AuthService: ObservableObject {
    static let shared = AuthService()
    
    @Published var user: User? = nil
    
    private init() {
        Auth.auth().addStateDidChangeListener { _, user in
            self.user = user
        }
    }
    
    func signInAnonymously() async throws {
        if Auth.auth().currentUser == nil {
            _ = try await Auth.auth().signInAnonymously()
        }
    }
}

