//
//  GainsApp.swift
//  Gains
//
//  Created by Rayaan Bokhari on 11/20/25.
//

import SwiftUI
import FirebaseCore
import FirebaseAuth

@main
struct GainsApp: App {
    @StateObject private var authService = AuthService.shared

    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authService)
                .task {
                    do {
                        try await authService.signInAnonymously()
                    } catch {
                        print("Failed to sign in anonymously: \(error)")
                    }
                }
                .preferredColorScheme(.dark)
        }
    }
}


