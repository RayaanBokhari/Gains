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
    
    // Define colors for each macro
    private let proteinColor = Color(hex: "FF6B6B")
    private let carbsColor = Color(hex: "0A84FF")
    private let fatsColor = Color(hex: "FFD93D")
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Macros")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                
                Spacer()
                
                // Legend
                HStack(spacing: 12) {
                    LegendItem(color: proteinColor, label: "P")
                    LegendItem(color: carbsColor, label: "C")
                    LegendItem(color: fatsColor, label: "F")
                }
            }
            
            if dailyLogs.isEmpty {
                emptyState
            } else {
                Chart {
                    ForEach(dailyLogs, id: \.id) { log in
                        LineMark(
                            x: .value("Date", log.date, unit: .day),
                            y: .value("Protein", log.protein)
                        )
                        .foregroundStyle(proteinColor)
                        .interpolationMethod(.catmullRom)
                        .lineStyle(StrokeStyle(lineWidth: 2.5))
                        
                        PointMark(
                            x: .value("Date", log.date, unit: .day),
                            y: .value("Protein", log.protein)
                        )
                        .foregroundStyle(proteinColor)
                        .symbolSize(30)
                        
                        LineMark(
                            x: .value("Date", log.date, unit: .day),
                            y: .value("Carbs", log.carbs)
                        )
                        .foregroundStyle(carbsColor)
                        .interpolationMethod(.catmullRom)
                        .lineStyle(StrokeStyle(lineWidth: 2.5))
                        
                        PointMark(
                            x: .value("Date", log.date, unit: .day),
                            y: .value("Carbs", log.carbs)
                        )
                        .foregroundStyle(carbsColor)
                        .symbolSize(30)
                        
                        LineMark(
                            x: .value("Date", log.date, unit: .day),
                            y: .value("Fats", log.fats)
                        )
                        .foregroundStyle(fatsColor)
                        .interpolationMethod(.catmullRom)
                        .lineStyle(StrokeStyle(lineWidth: 2.5))
                        
                        PointMark(
                            x: .value("Date", log.date, unit: .day),
                            y: .value("Fats", log.fats)
                        )
                        .foregroundStyle(fatsColor)
                        .symbolSize(30)
                    }
                }
                .frame(height: 180)
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day, count: max(1, dailyLogs.count / 5))) { _ in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                            .foregroundStyle(Color.gainsBgTertiary)
                        AxisValueLabel(format: .dateTime.month().day())
                            .foregroundStyle(Color.gainsTextMuted)
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
                .chartLegend(.hidden)
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
            Image(systemName: "chart.line.uptrend.xyaxis")
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

struct LegendItem: View {
    let color: Color
    let label: String
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.gainsTextSecondary)
        }
    }
}

