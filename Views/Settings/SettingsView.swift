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
                Color.gainsBackground.ignoresSafeArea()
                
                List {
                    // Account Section
                    Section {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(spacing: 16) {
                                // User Avatar
                                Circle()
                                    .fill(Color.gainsPrimary.opacity(0.2))
                                    .frame(width: 50, height: 50)
                                    .overlay(
                                        Text(String(authService.displayName?.prefix(1) ?? "U"))
                                            .font(.system(size: 20, weight: .bold))
                                            .foregroundColor(.gainsPrimary)
                                    )
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(authService.displayName ?? "User")
                                        .font(.system(size: 17, weight: .semibold))
                                        .foregroundColor(.gainsText)
                                    
                                    if let email = authService.userEmail {
                                        Text(email)
                                            .font(.system(size: 14))
                                            .foregroundColor(.gainsSecondaryText)
                                    }
                                }
                                
                                Spacer()
                            }
                            
                            // Account Status Badge
                            HStack(spacing: 6) {
                                Image(systemName: "checkmark.seal.fill")
                                    .font(.system(size: 12))
                                    .foregroundColor(.green)
                                Text("Verified Account")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.green)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color.green.opacity(0.1))
                            .cornerRadius(8)
                        }
                        .padding(.vertical, 8)
                    } header: {
                        Text("Account")
                    }
                    
                    // API Configuration Section
                    Section {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("OpenAI API Key")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.gainsText)
                            
                            Text("Required for AI Coach functionality. Get your API key from platform.openai.com")
                                .font(.system(size: 12))
                                .foregroundColor(.gainsSecondaryText)
                            
                            HStack {
                                if showAPIKey {
                                    TextField("sk-...", text: $apiKey)
                                        .textFieldStyle(PlainTextFieldStyle())
                                        .foregroundColor(.gainsText)
                                        .autocapitalization(.none)
                                        .autocorrectionDisabled()
                                        .onChange(of: apiKey) { newValue in
                                            // If user is typing, unmask
                                            if !newValue.isEmpty && isKeyMasked {
                                                // User started typing, load full key
                                                if let fullKey = APIConfiguration.shared.apiKey {
                                                    apiKey = fullKey
                                                    isKeyMasked = false
                                                }
                                            }
                                        }
                                } else {
                                    SecureField("sk-...", text: $apiKey)
                                        .textFieldStyle(PlainTextFieldStyle())
                                        .foregroundColor(.gainsText)
                                        .autocapitalization(.none)
                                        .autocorrectionDisabled()
                                        .onChange(of: apiKey) { newValue in
                                            // If user is typing, unmask
                                            if !newValue.isEmpty && isKeyMasked {
                                                // User started typing, load full key
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
                                        .foregroundColor(.gainsSecondaryText)
                                }
                            }
                            .padding()
                            .background(Color.gainsCardBackground)
                            .cornerRadius(8)
                            
                            Button(action: saveAPIKey) {
                                Text(isKeyMasked ? "Edit API Key" : "Save API Key")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background((isKeyMasked || apiKey.isEmpty) ? Color.gray : Color.gainsPrimary)
                                    .cornerRadius(8)
                            }
                            .disabled(isKeyMasked)
                            
                            if APIConfiguration.shared.hasAPIKey {
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                    Text("API Key configured")
                                        .font(.system(size: 14))
                                        .foregroundColor(.gainsSecondaryText)
                                }
                            }
                        }
                        .padding(.vertical, 4)
                    } header: {
                        Text("AI Coach Configuration")
                    }
                    
                    // App Info Section
                    Section {
                        HStack {
                            Text("Version")
                                .foregroundColor(.gainsText)
                            Spacer()
                            Text("1.0.0")
                                .foregroundColor(.gainsSecondaryText)
                        }
                        
                        NavigationLink(destination: PrivacyPolicyView()) {
                            HStack {
                                Text("Privacy Policy")
                                    .foregroundColor(.gainsText)
                                Spacer()
                            }
                        }
                        
                        NavigationLink(destination: TermsOfServiceView()) {
                            HStack {
                                Text("Terms of Service")
                                    .foregroundColor(.gainsText)
                                Spacer()
                            }
                        }
                    } header: {
                        Text("About")
                    }
                    
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
                            .foregroundColor(.red)
                        }
                        
                        if let error = signOutError {
                            Text(error)
                                .font(.system(size: 14))
                                .foregroundColor(.red)
                        }
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Settings")
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
    
    private func saveAPIKey() {
        // If the key is masked (contains "..."), don't save it again
        if apiKey.contains("...") {
            return
        }
        APIConfiguration.shared.apiKey = apiKey
        showAPIKey = false
        // Mask the key in the UI after saving
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
            Color.gainsBackground.ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Privacy Policy")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.gainsText)
                    
                    Text("Last updated: December 2024")
                        .font(.system(size: 14))
                        .foregroundColor(.gainsSecondaryText)
                    
                    Text("""
                    Your privacy is important to us. Gains collects and stores your fitness and nutrition data securely in Firebase to provide you with personalized tracking and insights.
                    
                    We do not sell your personal information to third parties. Your data is encrypted in transit and at rest.
                    
                    For AI Coach features, your queries are processed through OpenAI's API. Please review OpenAI's privacy policy for details on how they handle data.
                    
                    You can delete your account and all associated data at any time through the app settings.
                    """)
                    .font(.system(size: 16))
                    .foregroundColor(.gainsText)
                    .lineSpacing(6)
                    
                    Spacer()
                }
                .padding()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct TermsOfServiceView: View {
    var body: some View {
        ZStack {
            Color.gainsBackground.ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Terms of Service")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.gainsText)
                    
                    Text("Last updated: December 2024")
                        .font(.system(size: 14))
                        .foregroundColor(.gainsSecondaryText)
                    
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
                    .foregroundColor(.gainsText)
                    .lineSpacing(6)
                    
                    Spacer()
                }
                .padding()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    SettingsView()
        .environmentObject(AuthService.shared)
}
