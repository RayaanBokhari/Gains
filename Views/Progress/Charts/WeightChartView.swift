//
//  WeightChartView.swift
//  Gains
//
//  Created by Rayaan Bokhari on 11/21/25.
//

import SwiftUI
import Charts

struct WeightChartView: View {
    let dailyLogs: [DailyLog]
    // Note: Weight tracking would need to be added to DailyLog or separate collection
    // For now, this is a placeholder that can be extended
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Weight")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                
                Spacer()
                
                Image(systemName: "scalemass.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.gainsAccentPurple)
            }
            
            // Placeholder state
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color.gainsAccentPurple.opacity(0.15))
                        .frame(width: 56, height: 56)
                    
                    Image(systemName: "scalemass")
                        .font(.system(size: 24))
                        .foregroundColor(.gainsAccentPurple)
                }
                
                Text("Weight tracking coming soon")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.white)
                
                Text("Track your weight progress over time")
                    .font(.system(size: 13))
                    .foregroundColor(.gainsTextSecondary)
            }
            .frame(height: 160)
            .frame(maxWidth: .infinity)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: GainsDesign.cornerRadiusMedium)
                .fill(Color.gainsCardSurface)
        )
    }
}
