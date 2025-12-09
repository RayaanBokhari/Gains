//
//  WeightChartView.swift
//  Gains
//
//  Created by Rayaan Bokhari on 11/21/25.
//

import SwiftUI
import Charts

struct WeightChartView: View {
    let weightEntries: [WeightEntry]
    let useMetricUnits: Bool
    var onLogWeight: ((Double, String?) -> Void)?
    var onDeleteWeight: ((WeightEntry) -> Void)?
    
    @State private var showLogWeight = false
    @State private var showDeleteConfirmation = false
    @State private var entryToDelete: WeightEntry?
    @State private var selectedEntry: WeightEntry?
    @State private var showTooltip = false
    @State private var tooltipPosition: CGPoint = .zero
    
    var displayEntries: [WeightEntry] {
        // Show last 10 entries, sorted by date ascending for chart
        Array(weightEntries.prefix(10).reversed())
    }
    
    // Convert kg to user's preferred unit for display
    private func convertWeight(_ weightKg: Double) -> Double {
        return useMetricUnits ? weightKg : weightKg * 2.20462
    }
    
    // Convert user's preferred unit to kg for storage
    private func convertToKg(_ weight: Double) -> Double {
        return useMetricUnits ? weight : weight * 0.453592
    }
    
    var weeklyAverage: Double? {
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        let recentEntries = weightEntries.filter { $0.date >= weekAgo }
        guard !recentEntries.isEmpty else { return nil }
        let sum = recentEntries.reduce(0.0) { $0 + $1.weight }
        let avgKg = sum / Double(recentEntries.count)
        return convertWeight(avgKg)
    }
    
    var weeklyChange: Double? {
        guard let currentKg = weightEntries.first?.weight else { return nil }
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        // Find weight entry closest to 7 days ago (entries are sorted descending by date)
        let weekAgoEntry = weightEntries.first { $0.date <= weekAgo }
        guard let weekAgoKg = weekAgoEntry?.weight else { return nil }
        // Calculate change in kg, then convert to display unit
        let changeKg = currentKg - weekAgoKg
        // Convert the change amount to user's preferred unit
        return useMetricUnits ? changeKg : changeKg * 2.20462
    }
    
    var changeColor: Color {
        guard let change = weeklyChange else { return .gainsTextSecondary }
        if abs(change) < 0.1 { return .gainsTextSecondary }
        return change > 0 ? .gainsAccentRed : .gainsSuccess
    }
    
    var yAxisDomain: ClosedRange<Double> {
        guard !weightEntries.isEmpty else {
            return 0...100
        }
        let weights = weightEntries.map { convertWeight($0.weight) }
        let minWeight = (weights.min() ?? 0) - 2
        let maxWeight = (weights.max() ?? 100) + 2
        return minWeight...maxWeight
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Weight")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                
                Spacer()
                
                Button {
                    showLogWeight = true
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "plus.circle.fill")
                        Text("Log")
                    }
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.gainsAccentPurple)
                }
            }
            
            if weightEntries.isEmpty {
                emptyState
            } else {
                // Weight Stats Row
                weightStatsRow
                
                // Chart with tap detection
                GeometryReader { geometry in
                    ZStack {
                        Chart(displayEntries) { entry in
                            LineMark(
                                x: .value("Date", entry.date, unit: .day),
                                y: .value("Weight", convertWeight(entry.weight))
                            )
                            .foregroundStyle(Color.gainsAccentPurple)
                            .interpolationMethod(.catmullRom)
                            
                            AreaMark(
                                x: .value("Date", entry.date, unit: .day),
                                y: .value("Weight", convertWeight(entry.weight))
                            )
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color.gainsAccentPurple.opacity(0.3), .clear],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .interpolationMethod(.catmullRom)
                            
                            PointMark(
                                x: .value("Date", entry.date, unit: .day),
                                y: .value("Weight", convertWeight(entry.weight))
                            )
                            .foregroundStyle(selectedEntry?.id == entry.id ? Color.gainsAccentRed : Color.gainsAccentPurple)
                            .symbolSize(selectedEntry?.id == entry.id ? 40 : 30)
                            .opacity(selectedEntry?.id == entry.id ? 1.0 : 0.8)
                        }
                        .chartYScale(domain: yAxisDomain)
                        .chartXAxis {
                            AxisMarks(values: .stride(by: .day, count: max(1, displayEntries.count / 5))) { value in
                                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                                    .foregroundStyle(Color.gainsBgTertiary)
                                AxisValueLabel(format: .dateTime.month().day())
                                    .foregroundStyle(Color.gainsTextMuted)
                                    .font(.system(size: 10))
                            }
                        }
                        .chartYAxis {
                            AxisMarks(position: .leading) { value in
                                AxisValueLabel {
                                    if let weight = value.as(Double.self) {
                                        Text("\(Int(weight))")
                                            .font(.system(size: 10))
                                            .foregroundColor(.gainsTextMuted)
                                    }
                                }
                            }
                        }
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onEnded { value in
                                    handleChartTap(at: value.location, in: geometry.size)
                                }
                        )
                        
                        // Tooltip overlay
                        if showTooltip, let entry = selectedEntry {
                            VStack(spacing: 4) {
                                Text("Tap again to delete")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.white)
                                Text(formatDate(entry.date))
                                    .font(.system(size: 10))
                                    .foregroundColor(.gainsTextSecondary)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.gainsCardSurface)
                                    .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
                            )
                            .position(
                                x: max(60, min(geometry.size.width - 60, tooltipPosition.x)),
                                y: max(40, min(geometry.size.height - 40, tooltipPosition.y - 30))
                            )
                            .transition(.scale.combined(with: .opacity))
                            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: showTooltip)
                        }
                    }
                }
                .frame(height: 160)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: GainsDesign.cornerRadiusMedium)
                .fill(Color.gainsCardSurface)
        )
        .sheet(isPresented: $showLogWeight) {
            LogWeightSheet(
                useMetricUnits: useMetricUnits,
                onSave: { weight, notes in
                    onLogWeight?(weight, notes)
                }
            )
        }
        .alert("Delete Weight Entry", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) {
                entryToDelete = nil
                showTooltip = false
                selectedEntry = nil
            }
            Button("Delete", role: .destructive) {
                if let entry = entryToDelete {
                    onDeleteWeight?(entry)
                }
                entryToDelete = nil
                showTooltip = false
                selectedEntry = nil
            }
        } message: {
            if let entry = entryToDelete {
                let weightDisplay = useMetricUnits ? String(format: "%.1f kg", entry.weight) : String(format: "%.1f lbs", entry.weight * 2.20462)
                Text("Are you sure you want to delete the weight entry from \(formatDate(entry.date)) (\(weightDisplay))?")
            }
        }
        .onChange(of: selectedEntry) { oldValue, newValue in
            if newValue == nil {
                showTooltip = false
            }
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "scalemass")
                .font(.system(size: 32))
                .foregroundColor(.gainsAccentPurple.opacity(0.5))
            
            Text("No weight entries yet")
                .font(.system(size: 15))
                .foregroundColor(.gainsTextSecondary)
            
            Button {
                showLogWeight = true
            } label: {
                Text("Log Your Weight")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.gainsAccentPurple)
                    .cornerRadius(8)
            }
        }
        .frame(height: 160)
        .frame(maxWidth: .infinity)
    }
    
    private var weightStatsRow: some View {
        HStack(spacing: 12) {
            WeightStatBox(
                label: "Current",
                value: formatWeight(weightEntries.first.map { convertWeight($0.weight) }),
                unit: useMetricUnits ? "kg" : "lbs"
            )
            
            WeightStatBox(
                label: "7-Day Avg",
                value: formatWeight(weeklyAverage),
                unit: useMetricUnits ? "kg" : "lbs"
            )
            
            WeightStatBox(
                label: "Change",
                value: formatWeightChange(weeklyChange),
                unit: useMetricUnits ? "kg" : "lbs",
                changeColor: changeColor
            )
        }
    }
    
    private func formatWeight(_ weight: Double?) -> String {
        guard let weight = weight else { return "—" }
        return String(format: "%.1f", weight)
    }
    
    private func formatWeightChange(_ change: Double?) -> String {
        guard let change = change else { return "—" }
        let sign = change > 0 ? "+" : ""
        return "\(sign)\(String(format: "%.1f", change))"
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        if Calendar.current.isDateInToday(date) {
            return "Today"
        } else if Calendar.current.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            formatter.dateStyle = .medium
            return formatter.string(from: date)
        }
    }
    
    private func handleChartTap(at location: CGPoint, in size: CGSize) {
        guard !displayEntries.isEmpty else { return }
        
        // Calculate which entry is closest to the tap location
        let chartWidth = size.width
        let chartHeight = size.height
        
        // Normalize tap location (0-1 range)
        let normalizedX = location.x / chartWidth
        let normalizedY = location.y / chartHeight
        
        // Find the entry closest to the tap
        let entryCount = displayEntries.count
        let entryIndex = Int(normalizedX * Double(entryCount - 1))
        let clampedIndex = max(0, min(entryCount - 1, entryIndex))
        
        if clampedIndex < displayEntries.count {
            let tappedEntry = displayEntries[clampedIndex]
            
            // Check if tap is close enough to the point (within reasonable distance)
            let entryY = convertWeight(tappedEntry.weight)
            let minY = yAxisDomain.lowerBound
            let maxY = yAxisDomain.upperBound
            let normalizedEntryY = 1.0 - ((entryY - minY) / (maxY - minY))
            
            // If tap is within reasonable distance of the point
            if abs(normalizedY - normalizedEntryY) < 0.2 {
                // If same entry is tapped again, show delete confirmation
                if selectedEntry?.id == tappedEntry.id && showTooltip {
                    entryToDelete = tappedEntry
                    showDeleteConfirmation = true
                    showTooltip = false
                    selectedEntry = nil
                } else {
                    // First tap - show tooltip
                    selectedEntry = tappedEntry
                    tooltipPosition = location
                    showTooltip = true
                    
                    // Hide tooltip after 3 seconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        if selectedEntry?.id == tappedEntry.id {
                            showTooltip = false
                            selectedEntry = nil
                        }
                    }
                }
            } else {
                // Tap was not close to any point, hide tooltip
                showTooltip = false
                selectedEntry = nil
            }
        }
    }
}

struct WeightStatBox: View {
    let label: String
    let value: String
    let unit: String
    var changeColor: Color = .gainsTextSecondary
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(.gainsTextSecondary)
            
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                
                Text(unit)
                    .font(.system(size: 11))
                    .foregroundColor(.gainsTextMuted)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(Color.gainsBgTertiary.opacity(0.5))
        .cornerRadius(8)
    }
}
