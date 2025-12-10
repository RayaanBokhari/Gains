//
//  MacrosChartView.swift
//  Gains
//
//  Created by Rayaan Bokhari on 11/21/25.
//

import SwiftUI
import Charts

// Each point for the chart with its macro type
struct MacroChartPoint: Identifiable {
    let id = UUID()
    let position: Int
    let value: Double
    let macro: String
}

struct MacroSlot: Identifiable {
    let id = UUID()
    let position: Int           // 0...6 fixed slots
    let label: String           // formatted date or ""
    let entry: DailyLog?        // nil means empty slot
}

struct MacrosChartView: View {
    let dailyLogs: [DailyLog]
    private let maxSlots = 7
    
    // Define colors for each macro
    private let proteinColor = Color(hex: "FF6B6B")
    private let carbsColor   = Color(hex: "0A84FF")
    private let fatsColor    = Color(hex: "FFD93D")
    
    // Only show logs that have macro data, sorted ascending
    private var logsWithData: [DailyLog] {
        let filtered = dailyLogs
            .filter { $0.protein > 0 || $0.carbs > 0 || $0.fats > 0 }
            .sorted { $0.date < $1.date }
        
        return Array(filtered.suffix(maxSlots))
    }
    
    // Build 7 fixed slots, right-aligned with the latest entries
    private var slots: [MacroSlot] {
        let useCount = min(logsWithData.count, maxSlots)
        let df = DateFormatter()
        df.dateFormat = "M/d"
        
        return (0..<maxSlots).map { position in
            let globalIndex = position - (maxSlots - useCount)
            if globalIndex >= 0 && globalIndex < useCount {
                let entryIndex = logsWithData.count - useCount + globalIndex
                let entry = logsWithData[entryIndex]
                return MacroSlot(
                    position: position,
                    label: df.string(from: entry.date),
                    entry: entry
                )
            } else {
                return MacroSlot(position: position, label: "", entry: nil)
            }
        }
    }
    
    // Flatten slots into chart points for each macro (only filled slots)
    private var proteinPoints: [MacroChartPoint] {
        slots.compactMap { slot in
            guard let entry = slot.entry else { return nil }
            return MacroChartPoint(position: slot.position, value: Double(entry.protein), macro: "Protein")
        }
    }
    
    private var carbsPoints: [MacroChartPoint] {
        slots.compactMap { slot in
            guard let entry = slot.entry else { return nil }
            return MacroChartPoint(position: slot.position, value: Double(entry.carbs), macro: "Carbs")
        }
    }
    
    private var fatsPoints: [MacroChartPoint] {
        slots.compactMap { slot in
            guard let entry = slot.entry else { return nil }
            return MacroChartPoint(position: slot.position, value: Double(entry.fats), macro: "Fats")
        }
    }
    
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
                    LegendItem(color: carbsColor,   label: "C")
                    LegendItem(color: fatsColor,    label: "F")
                }
            }
            
            if logsWithData.isEmpty {
                emptyState
            } else {
                Chart {
                    // Protein line + points
                    ForEach(proteinPoints) { point in
                        LineMark(
                            x: .value("Slot", point.position),
                            y: .value("Grams", point.value),
                            series: .value("Macro", "Protein")
                        )
                        .foregroundStyle(proteinColor)
                        .lineStyle(StrokeStyle(lineWidth: 2.5))
                        .interpolationMethod(.linear)
                        
                        PointMark(
                            x: .value("Slot", point.position),
                            y: .value("Grams", point.value)
                        )
                        .foregroundStyle(proteinColor)
                        .symbolSize(40)
                    }
                    
                    // Carbs line + points
                    ForEach(carbsPoints) { point in
                        LineMark(
                            x: .value("Slot", point.position),
                            y: .value("Grams", point.value),
                            series: .value("Macro", "Carbs")
                        )
                        .foregroundStyle(carbsColor)
                        .lineStyle(StrokeStyle(lineWidth: 2.5))
                        .interpolationMethod(.linear)
                        
                        PointMark(
                            x: .value("Slot", point.position),
                            y: .value("Grams", point.value)
                        )
                        .foregroundStyle(carbsColor)
                        .symbolSize(40)
                    }
                    
                    // Fats line + points
                    ForEach(fatsPoints) { point in
                        LineMark(
                            x: .value("Slot", point.position),
                            y: .value("Grams", point.value),
                            series: .value("Macro", "Fats")
                        )
                        .foregroundStyle(fatsColor)
                        .lineStyle(StrokeStyle(lineWidth: 2.5))
                        .interpolationMethod(.linear)
                        
                        PointMark(
                            x: .value("Slot", point.position),
                            y: .value("Grams", point.value)
                        )
                        .foregroundStyle(fatsColor)
                        .symbolSize(40)
                    }
                }
                .chartXScale(domain: 0...(maxSlots - 1))
                .frame(height: 180)
                .chartXAxis {
                    AxisMarks(values: Array(0..<maxSlots)) { value in
                        if let idx = value.as(Int.self), idx < slots.count {
                            let label = slots[idx].label
                            // Only show grid line if there's data
                            if !label.isEmpty {
                                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                                    .foregroundStyle(Color.gainsBgTertiary)
                                AxisValueLabel {
                                    Text(label)
                                        .font(.system(size: 9))
                                        .foregroundColor(.gainsTextMuted)
                                }
                            }
                        }
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .trailing, values: .automatic(desiredCount: 4)) { _ in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                            .foregroundStyle(Color.gainsBgTertiary)
                        AxisValueLabel()
                            .foregroundStyle(Color.gainsTextMuted)
                            .font(.system(size: 10))
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
        VStack(spacing: 12) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 32))
                .foregroundColor(.gainsPrimary.opacity(0.5))
            
            Text("No entries yet")
                .font(.system(size: 15))
                .foregroundColor(.gainsTextSecondary)
            
            Text("Start logging meals to see your macro breakdown")
                .font(.system(size: 13))
                .foregroundColor(.gainsTextMuted)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
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
