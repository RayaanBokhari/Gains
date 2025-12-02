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
        VStack(alignment: .leading, spacing: 12) {
            Text("Weight")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.gainsText)
            
            Text("Weight tracking coming soon")
                .font(.system(size: 14))
                .foregroundColor(.gainsSecondaryText)
                .frame(height: 200)
        }
        .padding()
        .background(Color.gainsCardBackground)
        .cornerRadius(16)
    }
}

