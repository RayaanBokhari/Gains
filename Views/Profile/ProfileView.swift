//
//  ProfileView.swift
//  Gains
//
//  Created by Rayaan Bokhari on 11/20/25.
//

import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authService: AuthService
    @StateObject private var viewModel = ProfileViewModel()
    @State private var showEditProfile = false
    @State private var showSettings = false
    @State private var showUpgradeAccount = false
    @State private var showGoalsSettings = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Gradient background
                LinearGradient(
                    colors: [Color(hex: "0D0E14"), Color(hex: "0A0A0B")],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: GainsDesign.sectionSpacing) {
                        // Profile Header
                        profileHeader
                        
                        // Anonymous Account Upgrade Banner
                        if authService.isAnonymous {
                            upgradeBanner
                        }
                        
                        // Basic Information
                        infoSection
                        
                        // Goals & Targets
                        goalsSection
                        
                        // Quick Actions
                        quickActionsSection
                        
                        // Connected Apps
                        connectedAppsSection
                    }
                    .padding(.bottom, 100)
                }
            }
            .navigationBarHidden(true)
            .task {
                await viewModel.loadProfile()
                healthKitConnected = HealthKitService.shared.checkAuthorizationStatus()
            }
            .sheet(isPresented: $showEditProfile) {
                EditProfileView(viewModel: viewModel)
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
                    .environmentObject(authService)
            }
            .sheet(isPresented: $showUpgradeAccount) {
                SignUpView()
                    .environmentObject(authService)
            }
            .sheet(isPresented: $showGoalsSettings) {
                GoalsSettingsView(profileViewModel: viewModel)
            }
        }
    }
    
    // MARK: - Profile Header
    private var profileHeader: some View {
        VStack(spacing: 16) {
            // Avatar with gradient ring
            ZStack {
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [Color.gainsPrimary, Color.gainsAccentPurple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 3
                    )
                    .frame(width: 110, height: 110)
                
                Circle()
                    .fill(Color.gainsCardSurface)
                    .frame(width: 100, height: 100)
                    .overlay(
                        Text(String(viewModel.profile.name.prefix(1)))
                            .font(.system(size: 40, weight: .bold))
                            .foregroundColor(.white)
                    )
            }
            
            VStack(spacing: 6) {
                Text(viewModel.profile.name)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                
                if let email = authService.userEmail {
                    Text(email)
                        .font(.system(size: 14))
                        .foregroundColor(.gainsTextSecondary)
                }
            }
            
            Button {
                showEditProfile = true
            } label: {
                Text("Edit Profile")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.gainsPrimary)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 10)
                    .background(
                        Capsule()
                            .fill(Color.gainsPrimary.opacity(0.15))
                    )
            }
        }
        .padding(.top, GainsDesign.titlePaddingTop)
    }
    
    // MARK: - Upgrade Banner
    private var upgradeBanner: some View {
        Button {
            showUpgradeAccount = true
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(Color.gainsAccentOrange.opacity(0.2))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.gainsAccentOrange)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Create an Account")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Text("Sign up to sync your data across devices")
                        .font(.system(size: 13))
                        .foregroundColor(.gainsTextSecondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.gainsTextMuted)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: GainsDesign.cornerRadiusMedium)
                    .fill(
                        LinearGradient(
                            colors: [Color.gainsAccentOrange.opacity(0.12), Color.gainsAccentOrange.opacity(0.05)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: GainsDesign.cornerRadiusMedium)
                            .stroke(Color.gainsAccentOrange.opacity(0.25), lineWidth: 1)
                    )
            )
        }
        .padding(.horizontal, GainsDesign.paddingHorizontal)
    }
    
    // MARK: - Info Section
    private var infoSection: some View {
        VStack(spacing: 0) {
            InfoRow(label: "Date Joined", value: formatDate(viewModel.profile.dateJoined))
            Divider().background(Color.gainsBgTertiary)
            InfoRow(label: "Weight", value: "\(Int(viewModel.profile.weight)) \(viewModel.profile.useMetricUnits ? "kg" : "lbs")")
            Divider().background(Color.gainsBgTertiary)
            InfoRow(label: "Height", value: viewModel.profile.height)
            Divider().background(Color.gainsBgTertiary)
            InfoRow(label: "Gender", value: viewModel.profile.gender)
            Divider().background(Color.gainsBgTertiary)
            InfoRow(label: "Units", value: viewModel.profile.useMetricUnits ? "Metric" : "Imperial")
        }
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: GainsDesign.cornerRadiusMedium)
                .fill(Color.gainsCardSurface)
        )
        .padding(.horizontal, GainsDesign.paddingHorizontal)
    }
    
    // MARK: - Goals Section
    private var goalsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Goals & Targets")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                
                Spacer()
                
                Button {
                    showGoalsSettings = true
                } label: {
                    Text("Edit")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.gainsPrimary)
                }
            }
            
            // Daily Calories
            HStack {
                Text("Daily Calories")
                    .font(.system(size: 15))
                    .foregroundColor(.white)
                Spacer()
                Text("\(viewModel.profile.dailyCaloriesGoal)")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.gainsTextSecondary)
                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundColor(.gainsTextMuted)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(Color.gainsBgTertiary)
            .cornerRadius(12)
            
            // Macros Progress
            VStack(alignment: .leading, spacing: 14) {
                Text("Macros")
                    .font(.system(size: 14))
                    .foregroundColor(.gainsTextSecondary)
                
                ProfileMacroProgressBar(label: "Protein", progress: viewModel.macroProgress.protein, color: Color(hex: "FF6B6B"))
                ProfileMacroProgressBar(label: "Carbs", progress: viewModel.macroProgress.carbs, color: .gainsPrimary)
                ProfileMacroProgressBar(label: "Fats", progress: viewModel.macroProgress.fats, color: Color(hex: "FFD93D"))
            }
            
            // Water Goal
            HStack {
                Text("Water")
                    .font(.system(size: 15))
                    .foregroundColor(.white)
                Spacer()
                Text("\(Int(viewModel.profile.waterGoal)) oz")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.gainsTextSecondary)
            }
            .padding(.top, 8)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: GainsDesign.cornerRadiusMedium)
                .fill(Color.gainsCardSurface)
        )
        .padding(.horizontal, GainsDesign.paddingHorizontal)
    }
    
    // MARK: - Quick Actions
    private var quickActionsSection: some View {
        VStack(spacing: 12) {
            // Meal Plans
            NavigationLink(destination: DietaryPlansContentView()) {
                QuickActionRow(
                    icon: "fork.knife.circle.fill",
                    iconColor: Color.gainsSuccess,
                    title: "Meal Plans"
                )
            }
            
            // Achievements
            NavigationLink(destination: AchievementsView()) {
                QuickActionRow(
                    icon: "trophy.fill",
                    iconColor: Color(hex: "FFD700"),
                    title: "Achievements"
                )
            }
            
            // Settings
            Button {
                showSettings = true
            } label: {
                QuickActionRow(
                    icon: "gearshape.fill",
                    iconColor: .gainsTextSecondary,
                    title: "Settings"
                )
            }
        }
        .padding(.horizontal, GainsDesign.paddingHorizontal)
    }
    
    // MARK: - Connected Apps
    private var connectedAppsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Connected Apps")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
            
            NavigationLink(destination: HealthKitSettingsView()) {
            HStack(spacing: 16) {
                    // Apple Health Icon
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(LinearGradient(
                                colors: [Color(hex: "FF6B6B"), Color(hex: "FF8E53")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                            .frame(width: 52, height: 52)
                        
                        Image(systemName: "heart.fill")
                            .font(.system(size: 22))
                            .foregroundColor(.white)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Apple Health")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white)
                        
                        Text(healthKitConnected ? "Connected" : "Tap to connect")
                            .font(.system(size: 13))
                            .foregroundColor(healthKitConnected ? .gainsSuccess : .gainsTextSecondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.gainsTextMuted)
                }
                .padding(14)
                .background(Color.gainsBgTertiary)
                .cornerRadius(12)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: GainsDesign.cornerRadiusMedium)
                .fill(Color.gainsCardSurface)
        )
        .padding(.horizontal, GainsDesign.paddingHorizontal)
    }
    
    @State private var healthKitConnected = false
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d"
        return formatter.string(from: date)
    }
}

// MARK: - Supporting Views
struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 14))
                .foregroundColor(.gainsTextSecondary)
            Spacer()
            Text(value)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
}

struct ProfileMacroProgressBar: View {
    let label: String
    let progress: Double
    var color: Color = .gainsPrimary
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(label)
                    .font(.system(size: 14))
                    .foregroundColor(.gainsTextSecondary)
                Spacer()
                Text("\(Int(progress * 100))%")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gainsBgTertiary)
                        .frame(height: 6)
                    
                    RoundedRectangle(cornerRadius: 4)
                        .fill(color)
                        .frame(width: geometry.size.width * min(1.0, progress), height: 6)
                        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: progress)
                }
            }
            .frame(height: 6)
        }
    }
}

struct QuickActionRow: View {
    let icon: String
    var iconColor: Color = .gainsPrimary
    let title: String
    
    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 40, height: 40)
                
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(iconColor)
            }
            
            Text(title)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.gainsTextMuted)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: GainsDesign.cornerRadiusMedium)
                .fill(Color.gainsCardSurface)
        )
    }
}

struct ConnectedAppIcon: View {
    let icon: String
    var color: Color = .gainsPrimary
    
    var body: some View {
        Button(action: {}) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gainsBgTertiary)
                    .frame(width: 52, height: 52)
                
                Image(systemName: icon)
                    .font(.system(size: 22))
                    .foregroundColor(color)
            }
        }
    }
}

#Preview {
    ProfileView()
        .environmentObject(AuthService.shared)
}
