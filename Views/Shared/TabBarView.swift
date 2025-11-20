//
//  TabBarView.swift
//  Gains
//
//  Created by Rayaan Bokhari on 11/20/25.
//

import SwiftUI

struct TabBarView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            WorkoutListView()
                .tabItem {
                    Label("Workouts", systemImage: "dumbbell.fill")
                }
                .tag(0)
            
            ExerciseListView()
                .tabItem {
                    Label("Exercises", systemImage: "list.bullet")
                }
                .tag(1)
            
            ProgressTrackingView()
                .tabItem {
                    Label("Progress", systemImage: "chart.line.uptrend.xyaxis")
                }
                .tag(2)
            
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
                .tag(3)
        }
    }
}

#Preview {
    TabBarView()
}

