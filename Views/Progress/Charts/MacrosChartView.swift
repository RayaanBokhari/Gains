//
//  MacrosChartView.swift
//  Gains
//
//  Created by Rayaan Bokhari on 11/21/25.
//

import SwiftUI
import Charts

struct MacrosChartView: View {
    let dailyLogs: [DailyLog]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Macros")
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
                        LineMark(
                            x: .value("Date", log.date, unit: .day),
                            y: .value("Protein", log.protein)
                        )
                        .foregroundStyle(Color.blue)
                        .interpolationMethod(.catmullRom)
                        
                        LineMark(
                            x: .value("Date", log.date, unit: .day),
                            y: .value("Carbs", log.carbs)
                        )
                        .foregroundStyle(Color.green)
                        .interpolationMethod(.catmullRom)
                        
                        LineMark(
                            x: .value("Date", log.date, unit: .day),
                            y: .value("Fats", log.fats)
                        )
                        .foregroundStyle(Color.orange)
                        .interpolationMethod(.catmullRom)
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
                .chartLegend {
                    HStack(spacing: 16) {
                        LegendItem(color: .blue, label: "Protein")
                        LegendItem(color: .green, label: "Carbs")
                        LegendItem(color: .orange, label: "Fats")
                    }
                    .font(.system(size: 12))
                }
            }
        }
        .padding()
        .background(Color.gainsCardBackground)
        .cornerRadius(16)
    }
}

struct LegendItem: View {
    let color: Color
    let label: String
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(label)
                .foregroundColor(.gainsSecondaryText)
        }
    }
}

