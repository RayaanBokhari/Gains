//
//  SettingsView.swift
//  Gains
//
//  Created by Rayaan Bokhari on 11/20/25.
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var authService: AuthService
    @Environment(\.dismiss) var dismiss
    
    @State private var apiKey: String = ""
    @State private var showAPIKey = false
    @State private var isKeyMasked = true
    @State private var showSignOutConfirmation = false
    @State private var signOutError: String?
    
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
                
                List {
                    // Account Section
                    Section {
                        accountCard
                    } header: {
                        Text("Account")
                            .foregroundColor(.gainsTextSecondary)
                    }
                    .listRowBackground(Color.gainsCardSurface)
                    
                    // API Configuration Section
                    Section {
                        apiConfigCard
                    } header: {
                        Text("AI Coach Configuration")
                            .foregroundColor(.gainsTextSecondary)
                    }
                    .listRowBackground(Color.gainsCardSurface)
                    
                    // App Info Section
                    Section {
                        HStack {
                            Text("Version")
                                .foregroundColor(.white)
                            Spacer()
                            Text("1.0.0")
                                .foregroundColor(.gainsTextSecondary)
                        }
                        
                        NavigationLink(destination: PrivacyPolicyView()) {
                            Text("Privacy Policy")
                                .foregroundColor(.white)
                        }
                        
                        NavigationLink(destination: TermsOfServiceView()) {
                            Text("Terms of Service")
                                .foregroundColor(.white)
                        }
                    } header: {
                        Text("About")
                            .foregroundColor(.gainsTextSecondary)
                    }
                    .listRowBackground(Color.gainsCardSurface)
                    
                    // Sign Out Section
                    Section {
                        Button(role: .destructive) {
                            showSignOutConfirmation = true
                        } label: {
                            HStack {
                                Spacer()
                                Image(systemName: "rectangle.portrait.and.arrow.right")
                                Text("Sign Out")
                                    .font(.system(size: 16, weight: .semibold))
                                Spacer()
                            }
                            .foregroundColor(.gainsAccentRed)
                        }
                        
                        if let error = signOutError {
                            Text(error)
                                .font(.system(size: 14))
                                .foregroundColor(.gainsAccentRed)
                        }
                    }
                    .listRowBackground(Color.gainsCardSurface)
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.gainsPrimary)
                }
            }
            .confirmationDialog(
                "Sign Out",
                isPresented: $showSignOutConfirmation,
                titleVisibility: .visible
            ) {
                Button("Sign Out", role: .destructive) {
                    signOut()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Are you sure you want to sign out? You can sign back in anytime.")
            }
            .onAppear {
                // Load existing API key (masked)
                if let existingKey = APIConfiguration.shared.apiKey, !existingKey.isEmpty {
                    // Show masked version if key exists
                    if existingKey.count > 7 {
                        apiKey = String(existingKey.prefix(7)) + "..."
                    } else {
                        apiKey = existingKey
                    }
                }
            }
        }
    }
    
    private var accountCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 14) {
                // User Avatar with gradient ring
                ZStack {
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [Color.gainsPrimary, Color.gainsAccentPurple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2
                        )
                        .frame(width: 54, height: 54)
                    
                    Circle()
                        .fill(Color.gainsBgTertiary)
                        .frame(width: 48, height: 48)
                        .overlay(
                            Text(String(authService.displayName?.prefix(1) ?? "U"))
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.white)
                        )
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(authService.displayName ?? "User")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                    
                    if let email = authService.userEmail {
                        Text(email)
                            .font(.system(size: 14))
                            .foregroundColor(.gainsTextSecondary)
                    }
                }
                
                Spacer()
            }
            
            // Account Status Badge
            HStack(spacing: 6) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 12))
                    .foregroundColor(.gainsAccentGreen)
                Text("Verified Account")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.gainsAccentGreen)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color.gainsAccentGreen.opacity(0.15))
            .cornerRadius(8)
        }
        .padding(.vertical, 8)
    }
    
    private var apiConfigCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("OpenAI API Key")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)
            
            Text("Required for AI Coach functionality. Get your API key from platform.openai.com")
                .font(.system(size: 12))
                .foregroundColor(.gainsTextSecondary)
            
            HStack {
                if showAPIKey {
                    TextField("sk-...", text: $apiKey)
                        .textFieldStyle(PlainTextFieldStyle())
                        .foregroundColor(.white)
                        .autocapitalization(.none)
                        .autocorrectionDisabled()
                        .onChange(of: apiKey) { newValue in
                            if !newValue.isEmpty && isKeyMasked {
                                if let fullKey = APIConfiguration.shared.apiKey {
                                    apiKey = fullKey
                                    isKeyMasked = false
                                }
                            }
                        }
                } else {
                    SecureField("sk-...", text: $apiKey)
                        .textFieldStyle(PlainTextFieldStyle())
                        .foregroundColor(.white)
                        .autocapitalization(.none)
                        .autocorrectionDisabled()
                        .onChange(of: apiKey) { newValue in
                            if !newValue.isEmpty && isKeyMasked {
                                if let fullKey = APIConfiguration.shared.apiKey {
                                    apiKey = fullKey
                                    isKeyMasked = false
                                }
                            }
                        }
                }
                
                Button(action: {
                    showAPIKey.toggle()
                }) {
                    Image(systemName: showAPIKey ? "eye.slash.fill" : "eye.fill")
                        .foregroundColor(.gainsTextSecondary)
                }
            }
            .padding(14)
            .background(Color.gainsBgTertiary)
            .cornerRadius(10)
            
            Button(action: saveAPIKey) {
                Text(isKeyMasked ? "Edit API Key" : "Save API Key")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(
                        Group {
                            if isKeyMasked || apiKey.isEmpty {
                                Color.gainsTextMuted.opacity(0.5)
                            } else {
                                LinearGradient(
                                    colors: [Color.gainsPrimary, Color.gainsAccentBlue],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            }
                        }
                    )
                    .cornerRadius(10)
            }
            .disabled(isKeyMasked)
            
            if APIConfiguration.shared.hasAPIKey {
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.gainsAccentGreen)
                    Text("API Key configured")
                        .font(.system(size: 14))
                        .foregroundColor(.gainsTextSecondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    private func saveAPIKey() {
        if apiKey.contains("...") {
            return
        }
        APIConfiguration.shared.apiKey = apiKey
        showAPIKey = false
        if !apiKey.isEmpty && apiKey.count > 7 {
            apiKey = String(apiKey.prefix(7)) + "..."
        }
    }
    
    private func signOut() {
        do {
            try authService.signOut()
            dismiss()
        } catch {
            signOutError = "Failed to sign out: \(error.localizedDescription)"
        }
    }
}

// MARK: - Placeholder Views

struct PrivacyPolicyView: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "0D0E14"), Color(hex: "0A0A0B")],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Privacy Policy")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("Last updated: December 2024")
                        .font(.system(size: 14))
                        .foregroundColor(.gainsTextSecondary)
                    
                    Text("""
                    Your privacy is important to us. Gains collects and stores your fitness and nutrition data securely in Firebase to provide you with personalized tracking and insights.
                    
                    We do not sell your personal information to third parties. Your data is encrypted in transit and at rest.
                    
                    For AI Coach features, your queries are processed through OpenAI's API. Please review OpenAI's privacy policy for details on how they handle data.
                    
                    You can delete your account and all associated data at any time through the app settings.
                    """)
                    .font(.system(size: 16))
                    .foregroundColor(.white)
                    .lineSpacing(6)
                    
                    Spacer()
                }
                .padding(GainsDesign.paddingHorizontal)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct TermsOfServiceView: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "0D0E14"), Color(hex: "0A0A0B")],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Terms of Service")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("Last updated: December 2024")
                        .font(.system(size: 14))
                        .foregroundColor(.gainsTextSecondary)
                    
                    Text("""
                    By using Gains, you agree to these terms:
                    
                    1. You are responsible for maintaining the confidentiality of your account.
                    
                    2. The app is provided "as is" without warranties of any kind.
                    
                    3. We are not liable for any health decisions made based on app data or AI suggestions.
                    
                    4. Always consult healthcare professionals for medical advice.
                    
                    5. We reserve the right to modify or discontinue the service at any time.
                    
                    6. Your use of the AI Coach feature is subject to OpenAI's usage policies.
                    """)
                    .font(.system(size: 16))
                    .foregroundColor(.white)
                    .lineSpacing(6)
                    
                    Spacer()
                }
                .padding(GainsDesign.paddingHorizontal)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    SettingsView()
        .environmentObject(AuthService.shared)
}
