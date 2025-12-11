//
//  CaloriesChartView.swift
//  Gains
//
//  Created by Rayaan Bokhari on 11/21/25.
//

import SwiftUI
import Charts

struct CaloriesPoint: Identifiable {
    let id = UUID()
    let date: Date
    let calories: Double
}

struct CaloriesSlot: Identifiable {
    let id = UUID()
    let position: Int          // 0...6 fixed slots
    let label: String          // formatted date or ""
    let point: CaloriesPoint?  // nil means empty slot
}

struct CaloriesChartView: View {
    let dailyLogs: [DailyLog]
    private let maxSlots = 7
    
    // Aggregate per-day calories, keep last 10 days, sorted ascending
    private var logsForChart: [CaloriesPoint] {
        let calendar = Calendar.current
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "M/d/yy"
        
        // Log raw input
        print("📊 [CaloriesChart] Raw dailyLogs count: \(dailyLogs.count)")
        for log in dailyLogs.filter({ $0.calories > 0 }) {
            print("   - \(dateFormatter.string(from: log.date)): \(log.calories) cal")
        }
        
        // Filter days with any calories
        let grouped = Dictionary(
            grouping: dailyLogs.filter { $0.calories > 0 }
        ) { log in
            calendar.startOfDay(for: log.date)
        }
        
        let points = grouped.map { (day, logs) in
            let total = logs.reduce(0) { $0 + Double($1.calories) }
            print("📊 [CaloriesChart] Aggregated \(dateFormatter.string(from: day)): \(Int(total)) cal from \(logs.count) entries")
            return CaloriesPoint(
                date: day,
                calories: total
            )
        }
        .sorted { $0.date < $1.date }       // ascending
        
        // Last 10 days only
        let result = Array(points.suffix(10))
        print("📊 [CaloriesChart] Final chart points: \(result.count)")
        for point in result {
            print("   → \(dateFormatter.string(from: point.date)): \(Int(point.calories)) cal")
        }
        return result
    }
    
    // Build 7 fixed slots, right-aligned with the latest entries
    private var slots: [CaloriesSlot] {
        let points = logsForChart
        let useCount = min(points.count, maxSlots)
        let df = DateFormatter()
        df.dateFormat = "M/d"
        
        return (0..<maxSlots).map { position in
            let globalIndex = position - (maxSlots - useCount)
            if globalIndex >= 0 && globalIndex < useCount {
                let entryIndex = points.count - useCount + globalIndex
                let point = points[entryIndex]
                return CaloriesSlot(
                    position: position,
                    label: df.string(from: point.date),
                    point: point
                )
            } else {
                return CaloriesSlot(position: position, label: "", point: nil)
            }
        }
    }
    
    private func formatAxisDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M/d"
        return formatter.string(from: date)
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
            
            if logsForChart.isEmpty {
                emptyState
            } else {
                Chart {
                    ForEach(slots) { slot in
                        if let point = slot.point {
                            BarMark(
                                x: .value("Slot", slot.position),
                                y: .value("Calories", point.calories)
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
                }
                .chartXScale(domain: 0...(maxSlots - 1))
                .frame(height: 180)
                .chartXAxis {
                    AxisMarks(values: Array(0..<maxSlots)) { value in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                            .foregroundStyle(Color.gainsBgTertiary)
                        AxisTick()
                        if let idx = value.as(Int.self), idx < slots.count {
                            let label = slots[idx].label
                            if !label.isEmpty {
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
