//
//  CaloriesChartView.swift
//  Gains
//
//  Created by Rayaan Bokhari on 11/21/25.
//

import SwiftUI
import Charts

struct CaloriesChartView: View {
    let dailyLogs: [DailyLog]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Calories")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.gainsText)
            
            if dailyLogs.isEmpty {
                Text("No data available")
                    .font(.system(size: 14))
                    .foregroundColor(.gainsSecondaryText)
                    .frame(height: 200)
            } else {
                Chart {
                    ForEach(dailyLogs, id: \.id) { log in
                        BarMark(
                            x: .value("Date", log.date, unit: .day),
                            y: .value("Calories", log.calories)
                        )
                        .foregroundStyle(Color.gainsPrimary)
                    }
                }
                .frame(height: 200)
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day, count: max(1, dailyLogs.count / 5))) { _ in
                        AxisGridLine()
                        AxisValueLabel(format: .dateTime.month().day())
                    }
                }
                .chartYAxis {
                    AxisMarks { _ in
                        AxisGridLine()
                        AxisValueLabel()
                    }
                }
            }
        }
        .padding()
        .background(Color.gainsCardBackground)
        .cornerRadius(16)
    }
}

