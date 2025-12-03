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
                Color.gainsBackground.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Profile Header
                        VStack(spacing: 16) {
                            Circle()
                                .fill(Color.gainsCardBackground)
                                .frame(width: 100, height: 100)
                                .overlay(
                                    Text(String(viewModel.profile.name.prefix(1)))
                                        .font(.system(size: 40, weight: .bold))
                                        .foregroundColor(.gainsText)
                                )
                            
                            VStack(spacing: 4) {
                                Text(viewModel.profile.name)
                                    .font(.system(size: 32, weight: .bold))
                                    .foregroundColor(.gainsText)
                                
                                if let email = authService.userEmail {
                                    Text(email)
                                        .font(.system(size: 14))
                                        .foregroundColor(.gainsSecondaryText)
                                }
                            }
                            
                            Button {
                                showEditProfile = true
                            } label: {
                                Text("Edit Profile")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.gainsPrimary)
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 8)
                                    .background(Color.gainsPrimary.opacity(0.1))
                                    .cornerRadius(8)
                            }
                        }
                        .padding(.top)
                        
                        // Anonymous Account Upgrade Banner
                        if authService.isAnonymous {
                            Button {
                                showUpgradeAccount = true
                            } label: {
                                HStack(spacing: 12) {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .font(.system(size: 20))
                                        .foregroundColor(.orange)
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Create an Account")
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundColor(.gainsText)
                                        
                                        Text("Sign up to sync your data across devices")
                                            .font(.system(size: 12))
                                            .foregroundColor(.gainsSecondaryText)
                                    }
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 14))
                                        .foregroundColor(.gainsSecondaryText)
                                }
                                .padding()
                                .background(
                                    LinearGradient(
                                        colors: [Color.orange.opacity(0.15), Color.orange.opacity(0.05)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(16)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                                )
                            }
                            .padding(.horizontal)
                        }
                        
                        // Basic Information
                        VStack(alignment: .leading, spacing: 12) {
                            InfoRow(label: "Date Joined", value: formatDate(viewModel.profile.dateJoined))
                            InfoRow(label: "Weight", value: "\(Int(viewModel.profile.weight)) \(viewModel.profile.useMetricUnits ? "kg" : "lbs")")
                            InfoRow(label: "Height", value: viewModel.profile.height)
                            InfoRow(label: "Gender", value: viewModel.profile.gender)
                            InfoRow(label: "Units", value: viewModel.profile.useMetricUnits ? "Metric" : "Imperial")
                        }
                        .padding()
                        .background(Color.gainsCardBackground)
                        .cornerRadius(16)
                        .padding(.horizontal)
                        
                        // Goals & Targets
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Text("Goals & Targets")
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundColor(.gainsText)
                                
                                Spacer()
                                
                                Button {
                                    showGoalsSettings = true
                                } label: {
                                    Text("Edit")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.gainsPrimary)
                                }
                            }
                            
                            // Daily Calories
                            Button {
                                showEditProfile = true
                            } label: {
                                HStack {
                                    Text("Daily Calories")
                                        .font(.system(size: 16))
                                        .foregroundColor(.gainsText)
                                    Spacer()
                                    Text("\(viewModel.profile.dailyCaloriesGoal)")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.gainsSecondaryText)
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 14))
                                        .foregroundColor(.gainsSecondaryText)
                                }
                            }
                            
                            Divider()
                                .background(Color.gainsCardBackground)
                            
                            // Macros Progress
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Macros")
                                    .font(.system(size: 16))
                                    .foregroundColor(.gainsText)
                                
                                MacroProgressBar(label: "Protein", progress: viewModel.macroProgress.protein)
                                MacroProgressBar(label: "Carbs", progress: viewModel.macroProgress.carbs)
                                MacroProgressBar(label: "Fats", progress: viewModel.macroProgress.fats)
                            }
                            
                            Divider()
                                .background(Color.gainsCardBackground)
                            
                            // Water Goal
                            HStack {
                                Text("Water")
                                    .font(.system(size: 16))
                                    .foregroundColor(.gainsText)
                                Spacer()
                                Text("\(Int(viewModel.profile.waterGoal)) oz")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.gainsSecondaryText)
                            }
                        }
                        .padding()
                        .background(Color.gainsCardBackground)
                        .cornerRadius(16)
                        .padding(.horizontal)
                        
                        // Achievements
                        NavigationLink(destination: AchievementsView()) {
                            HStack {
                                Image(systemName: "trophy.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(.yellow)
                                
                                Text("Achievements")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.gainsText)
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14))
                                    .foregroundColor(.gainsSecondaryText)
                            }
                            .padding()
                            .background(Color.gainsCardBackground)
                            .cornerRadius(16)
                        }
                        .padding(.horizontal)
                        
                        // Settings
                        Button {
                            showSettings = true
                        } label: {
                            HStack {
                                Image(systemName: "gearshape.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(.gainsSecondaryText)
                                
                                Text("Settings")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.gainsText)
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14))
                                    .foregroundColor(.gainsSecondaryText)
                            }
                            .padding()
                            .background(Color.gainsCardBackground)
                            .cornerRadius(16)
                        }
                        .padding(.horizontal)
                        
                        // Connected Apps
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Connected Apps")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.gainsText)
                            
                            HStack(spacing: 20) {
                                ConnectedAppIcon(icon: "arrow.up")
                                ConnectedAppIcon(icon: "face.smiling")
                                ConnectedAppIcon(icon: "person.2")
                                ConnectedAppIcon(icon: "person.2")
                            }
                        }
                        .padding()
                        .background(Color.gainsCardBackground)
                        .cornerRadius(16)
                        .padding(.horizontal)
                        .padding(.bottom)
                    }
                }
            }
            .navigationBarHidden(true)
            .task {
                await viewModel.loadProfile()
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
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d"
        return formatter.string(from: date)
    }
}

struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 14))
                .foregroundColor(.gainsSecondaryText)
            Spacer()
            Text(value)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.gainsText)
        }
    }
}

struct MacroProgressBar: View {
    let label: String
    let progress: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label)
                    .font(.system(size: 14))
                    .foregroundColor(.gainsSecondaryText)
                Spacer()
                Text("\(Int(progress * 100))%")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.gainsText)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.gainsBackground)
                        .frame(height: 8)
                        .cornerRadius(4)
                    
                    Rectangle()
                        .fill(Color.gainsPrimary)
                        .frame(width: geometry.size.width * progress, height: 8)
                        .cornerRadius(4)
                }
            }
            .frame(height: 8)
        }
    }
}

struct ConnectedAppIcon: View {
    let icon: String
    
    var body: some View {
        Button(action: {}) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(.gainsPrimary)
                .frame(width: 50, height: 50)
                .background(Color.gainsBackground)
                .cornerRadius(12)
        }
    }
}

#Preview {
    ProfileView()
        .environmentObject(AuthService.shared)
}
