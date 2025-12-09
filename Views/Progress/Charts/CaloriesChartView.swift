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
    
    // Only show logs that have actual calorie data, limited to last 10 entries
    private var logsWithData: [DailyLog] {
        let filtered = dailyLogs.filter { $0.calories > 0 }
        // Take the most recent 10 entries (logs are sorted descending, so take first 10 then reverse for chart)
        return Array(filtered.prefix(10).reversed())
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Calories")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                
                Spacer()
                
                Image(systemName: "flame.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.gainsAccentOrange)
            }
            
            if logsWithData.isEmpty {
                emptyState
            } else {
                Chart {
                    ForEach(logsWithData, id: \.id) { log in
                        BarMark(
                            x: .value("Date", log.date, unit: .day),
                            y: .value("Calories", log.calories)
                        )
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.gainsPrimary, Color.gainsAccentTeal],
                                startPoint: .bottom,
                                endPoint: .top
                            )
                        )
                        .cornerRadius(4)
                    }
                }
                .frame(height: 180)
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day, count: max(1, logsWithData.count / 5))) { value in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                            .foregroundStyle(Color.gainsBgTertiary)
                        AxisValueLabel(format: .dateTime.month().day())
                            .foregroundStyle(Color.gainsTextMuted)
                            .font(.system(size: 10))
                    }
                }
                .chartYAxis {
                    AxisMarks { _ in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                            .foregroundStyle(Color.gainsBgTertiary)
                        AxisValueLabel()
                            .foregroundStyle(Color.gainsTextMuted)
                    }
                }
                .chartPlotStyle { plotArea in
                    plotArea
                        .background(Color.gainsBgTertiary.opacity(0.3))
                        .cornerRadius(8)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: GainsDesign.cornerRadiusMedium)
                .fill(Color.gainsCardSurface)
        )
    }
    
    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "flame.fill")
                .font(.system(size: 32))
                .foregroundColor(.gainsAccentOrange.opacity(0.5))
            
            Text("No entries yet")
                .font(.system(size: 15))
                .foregroundColor(.gainsTextSecondary)
            
            Text("Start logging meals to see your calorie progress")
                .font(.system(size: 13))
                .foregroundColor(.gainsTextMuted)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
        }
        .frame(height: 180)
        .frame(maxWidth: .infinity)
    }
}
