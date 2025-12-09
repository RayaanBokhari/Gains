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
            
            if dailyLogs.isEmpty {
                emptyState
            } else {
                Chart {
                    ForEach(dailyLogs, id: \.id) { log in
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
                    AxisMarks(values: .stride(by: .day, count: max(1, dailyLogs.count / 5))) { value in
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
        VStack(spacing: 8) {
            Image(systemName: "chart.bar")
                .font(.system(size: 24))
                .foregroundColor(.gainsTextMuted)
            
            Text("No data available")
                .font(.system(size: 14))
                .foregroundColor(.gainsTextSecondary)
        }
        .frame(height: 180)
        .frame(maxWidth: .infinity)
    }
}
