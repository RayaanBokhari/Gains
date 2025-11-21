//
//  SettingsView.swift
//  Gains
//
//  Created by Rayaan Bokhari on 11/20/25.
//

import SwiftUI

struct SettingsView: View {
    @State private var apiKey: String = ""
    @State private var showAPIKey = false
    @State private var isKeyMasked = true
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.gainsBackground.ignoresSafeArea()
                
                List {
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
                    
                    Section {
                        HStack {
                            Text("Version")
                                .foregroundColor(.gainsText)
                            Spacer()
                            Text("1.0.0")
                                .foregroundColor(.gainsSecondaryText)
                        }
                    } header: {
                        Text("About")
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Settings")
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
}

#Preview {
    SettingsView()
}

