//
//  SettingsView.swift
//  Gains
//
//  Created by Rayaan Bokhari on 11/20/25.
//

import SwiftUI

struct SettingsView: View {
    var body: some View {
        NavigationView {
            List {
                Section("Preferences") {
                    // TODO: Add settings options
                    Text("Settings options coming soon")
                        .foregroundColor(.secondary)
                }
                
                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }
}

#Preview {
    SettingsView()
}

