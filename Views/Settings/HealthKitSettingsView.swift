//
//  HealthKitSettingsView.swift
//  Gains
//
//  Created by Rayaan Bokhari on 12/20/25.
//

import SwiftUI
import HealthKit

struct HealthKitSettingsView: View {
    @StateObject private var healthKit = HealthKitService.shared
    @State private var showingAuthAlert = false
    @State private var authError: String?
    @State private var todaySteps: Int?
    @State private var todayActiveEnergy: Double?
    @State private var isLoadingHealthData = false
    
    // Sync toggles
    @State private var syncWeight = true
    @State private var syncWorkouts = true
    @State private var syncNutrition = true
    @State private var syncWater = true
    
    var body: some View {
        ZStack {
            Color(hex: "0A0B0E").ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Connection Status Card
                    connectionStatusCard
                    
                    if healthKit.isAuthorized {
                        // Sync Options
                        syncOptionsCard
                        
                        // Health Data Preview
                        healthDataPreviewCard
                    }
                }
                .padding()
            }
        }
        .navigationTitle("Apple Health")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Authorization Error", isPresented: $showingAuthAlert) {
            Button("Open Settings", action: openHealthSettings)
            Button("Cancel", role: .cancel) { }
        } message: {
            Text(authError ?? "Unable to access HealthKit")
        }
        .task {
            if healthKit.isAuthorized {
                await loadHealthData()
            }
        }
    }
    
    private var connectionStatusCard: some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                // Health App Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(LinearGradient(
                            colors: [Color(hex: "FF6B6B"), Color(hex: "FF8E53")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 56, height: 56)
                    
                    Image(systemName: "heart.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Apple Health")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                    
                    HStack(spacing: 6) {
                        Circle()
                            .fill(healthKit.isAuthorized ? Color.gainsSuccess : Color.gainsTextMuted)
                            .frame(width: 8, height: 8)
                        
                        Text(healthKit.isAuthorized ? "Connected" : "Not Connected")
                            .font(.system(size: 14))
                            .foregroundColor(healthKit.isAuthorized ? .gainsSuccess : .gainsTextSecondary)
                    }
                }
                
                Spacer()
            }
            
            if !healthKit.isAuthorized {
                Button {
                    Task {
                        do {
                            try await healthKit.requestAuthorization()
                            
                            // Start observing weight changes after authorization
                            if healthKit.isAuthorized {
                                healthKit.startObservingWeightChanges()
                            }
                            
                            await loadHealthData()
                        } catch {
                            authError = error.localizedDescription
                            showingAuthAlert = true
                        }
                    }
                } label: {
                    Text("Connect to Apple Health")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.gainsPrimary)
                        .cornerRadius(12)
                }
            }
        }
        .padding(16)
        .background(Color.gainsCardSurface)
        .cornerRadius(16)
    }
    
    private var syncOptionsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Sync Options")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
            
            SyncToggleRow(
                icon: "scalemass.fill",
                iconColor: .gainsAccentPurple,
                title: "Weight",
                subtitle: "Sync weight entries both ways",
                isOn: $syncWeight
            )
            
            Divider().background(Color.gainsBgTertiary)
            
            SyncToggleRow(
                icon: "dumbbell.fill",
                iconColor: .gainsPrimary,
                title: "Workouts",
                subtitle: "Export completed workouts",
                isOn: $syncWorkouts
            )
            
            Divider().background(Color.gainsBgTertiary)
            
            SyncToggleRow(
                icon: "flame.fill",
                iconColor: .gainsAccentOrange,
                title: "Nutrition",
                subtitle: "Export calories consumed",
                isOn: $syncNutrition
            )
            
            Divider().background(Color.gainsBgTertiary)
            
            SyncToggleRow(
                icon: "drop.fill",
                iconColor: .gainsPrimary,
                title: "Water",
                subtitle: "Sync water intake both ways",
                isOn: $syncWater
            )
        }
        .padding(16)
        .background(Color.gainsCardSurface)
        .cornerRadius(16)
    }
    
    private var healthDataPreviewCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Today's Data from Health")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                
                Spacer()
                
                if isLoadingHealthData {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .gainsPrimary))
                        .scaleEffect(0.8)
                }
            }
            
            HealthDataRow(
                icon: "figure.walk",
                title: "Steps",
                value: todaySteps != nil ? "\(todaySteps!)" : "—",
                iconColor: .gainsAccentGreen
            )
            
            HealthDataRow(
                icon: "flame.fill",
                title: "Active Energy",
                value: todayActiveEnergy != nil ? "\(Int(todayActiveEnergy!)) kcal" : "—",
                iconColor: .gainsAccentOrange
            )
        }
        .padding(16)
        .background(Color.gainsCardSurface)
        .cornerRadius(16)
    }
    
    private func loadHealthData() async {
        isLoadingHealthData = true
        defer { isLoadingHealthData = false }
        
        do {
            async let steps = healthKit.readTodaySteps()
            async let energy = healthKit.readTodayActiveEnergy()
            
            todaySteps = try await steps
            todayActiveEnergy = try await energy
        } catch {
            print("Error loading health data: \(error)")
        }
    }
    
    private func openHealthSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
}

struct SyncToggleRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    @Binding var isOn: Bool
    
    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(iconColor)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 15))
                    .foregroundColor(.white)
                
                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundColor(.gainsTextSecondary)
            }
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .tint(.gainsPrimary)
        }
    }
}

struct HealthDataRow: View {
    let icon: String
    let title: String
    let value: String
    let iconColor: Color
    
    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(iconColor)
                .frame(width: 24)
            
            Text(title)
                .font(.system(size: 15))
                .foregroundColor(.gainsTextSecondary)
            
            Spacer()
            
            Text(value)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.white)
        }
    }
}

#Preview {
    NavigationView {
        HealthKitSettingsView()
    }
}

