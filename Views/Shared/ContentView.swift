//
//  ContentView.swift
//  Gains
//
//  Created by Rayaan Bokhari on 11/20/25.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authService: AuthService
    
    var body: some View {
        Group {
            if authService.isLoading || authService.isCheckingOnboarding {
                // Loading state
                LoadingView()
            } else if authService.isAuthenticated {
                // User is signed in
                if authService.hasCompletedOnboarding {
                    // User has completed onboarding, show main app
                    TabBarView()
                } else {
                    // User needs to complete onboarding
                    OnboardingView()
                }
            } else {
                // User needs to sign in
                AuthenticationView()
            }
        }
        .animation(.easeInOut(duration: 0.3), value: authService.isAuthenticated)
        .animation(.easeInOut(duration: 0.3), value: authService.isLoading)
        .animation(.easeInOut(duration: 0.3), value: authService.hasCompletedOnboarding)
    }
}

// MARK: - Loading View

struct LoadingView: View {
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            Color.gainsBackground
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                // Animated logo
                ZStack {
                    Circle()
                        .stroke(Color.gainsPrimary.opacity(0.2), lineWidth: 4)
                        .frame(width: 80, height: 80)
                    
                    Circle()
                        .trim(from: 0, to: 0.7)
                        .stroke(
                            LinearGradient(
                                colors: [Color.gainsPrimary, Color.gainsPrimary.opacity(0.5)],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            style: StrokeStyle(lineWidth: 4, lineCap: .round)
                        )
                        .frame(width: 80, height: 80)
                        .rotationEffect(.degrees(isAnimating ? 360 : 0))
                        .animation(
                            .linear(duration: 1)
                            .repeatForever(autoreverses: false),
                            value: isAnimating
                        )
                    
                    Image(systemName: "figure.strengthtraining.traditional")
                        .font(.system(size: 30, weight: .semibold))
                        .foregroundColor(.gainsPrimary)
                }
                
                Text("Gains")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.gainsText)
            }
        }
        .onAppear {
            isAnimating = true
        }
    }
}

#Preview("Content View") {
    ContentView()
        .environmentObject(AuthService.shared)
}

#Preview("Loading") {
    LoadingView()
}
