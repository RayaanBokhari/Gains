//
//  ProgressView.swift
//  Gains
//
//  Created by Rayaan Bokhari on 11/20/25.
//

import SwiftUI

struct ProgressTrackingView: View {
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    Text("Progress Tracking")
                        .font(.title2)
                        .padding()
                    
                    // TODO: Add charts and progress metrics
                    Text("Charts and metrics coming soon")
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Progress")
        }
    }
}

#Preview {
    ProgressTrackingView()
}

