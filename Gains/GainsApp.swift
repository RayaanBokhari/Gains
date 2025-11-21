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
                    await authService.signInIfNeeded()
                }
                .preferredColorScheme(.dark)
        }
    }
}


