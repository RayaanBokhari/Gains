//
//  TabBarView.swift
//  Gains
//
//  Created by Rayaan Bokhari on 11/20/25.
//

import SwiftUI

struct TabBarView: View {
    @EnvironmentObject var authService: AuthService
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Image(systemName: selectedTab == 0 ? "house.fill" : "house")
                    Text("Home")
                }
                .tag(0)
            
            WorkoutListView()
                .tabItem {
                    Image(systemName: selectedTab == 1 ? "dumbbell.fill" : "dumbbell")
                    Text("Workouts")
                }
                .tag(1)
            
            ProgressTrackingView()
                .tabItem {
                    Image(systemName: selectedTab == 2 ? "chart.line.uptrend.xyaxis" : "chart.line.uptrend.xyaxis")
                    Text("Progress")
                }
                .tag(2)
            
            CommunityView()
                .tabItem {
                    Image(systemName: selectedTab == 3 ? "person.2.fill" : "person.2")
                    Text("Community")
                }
                .tag(3)
            
            ProfileView()
                .environmentObject(authService)
                .tabItem {
                    Image(systemName: selectedTab == 4 ? "person.fill" : "person")
                    Text("Profile")
                }
                .tag(4)
        }
        .accentColor(.gainsPrimary)
        .onAppear {
            configureTabBarAppearance()
        }
    }
    
    private func configureTabBarAppearance() {
        // Create frosted glass effect
        let appearance = UITabBarAppearance()
        appearance.configureWithDefaultBackground()
        
        // Background with blur effect
        appearance.backgroundEffect = UIBlurEffect(style: .systemUltraThinMaterialDark)
        appearance.backgroundColor = UIColor(Color.gainsCardSurface.opacity(0.7))
        
        // Remove the default separator line
        appearance.shadowColor = .clear
        appearance.shadowImage = UIImage()
        
        // Normal state
        let normalAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor(Color.gainsTextMuted),
            .font: UIFont.systemFont(ofSize: 10, weight: .medium)
        ]
        appearance.stackedLayoutAppearance.normal.iconColor = UIColor(Color.gainsTextMuted)
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = normalAttributes
        
        // Selected state
        let selectedAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor(Color.gainsPrimary),
            .font: UIFont.systemFont(ofSize: 10, weight: .semibold)
        ]
        appearance.stackedLayoutAppearance.selected.iconColor = UIColor(Color.gainsPrimary)
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = selectedAttributes
        
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
}

#Preview {
    TabBarView()
        .environmentObject(AuthService.shared)
}
