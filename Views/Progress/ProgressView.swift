//
//  ProgressView.swift
//  Gains
//
//  Created by Rayaan Bokhari on 11/20/25.
//

import SwiftUI

struct ProgressTrackingView: View {
    @StateObject private var viewModel = ProgressViewModel()
    
    var body: some View {
        NavigationView {
            ZStack {
                // Gradient background
                LinearGradient(
                    colors: [Color(hex: "0D0E14"), Color(hex: "0A0A0B")],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                if viewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .gainsPrimary))
                } else {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: GainsDesign.sectionSpacing) {
                            // Header
                            headerSection
                            
                            // Time Range Picker
                            timeRangePicker
                            
                            // Statistics Cards
                            if !viewModel.dailyLogs.isEmpty {
                                statisticsSection
                            }
                            
                            // Charts
                            if viewModel.dailyLogs.isEmpty {
                                emptyState
                            } else {
                                chartsSection
                            }
                        }
                        .padding(.bottom, 100)
                    }
                }
            }
            .navigationBarHidden(true)
            .task {
                await viewModel.loadProgress()
            }
        }
    }
    
    private var headerSection: some View {
        HStack {
            Text("Progress")
                .font(.system(size: 34, weight: .bold))
                .foregroundColor(.white)
            Spacer()
        }
        .padding(.horizontal, GainsDesign.paddingHorizontal)
        .padding(.top, GainsDesign.titlePaddingTop)
    }
    
    private var timeRangePicker: some View {
        HStack(spacing: 0) {
            ForEach(TimeRange.allCases, id: \.self) { range in
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        viewModel.selectedRange = range
                    }
                    Task {
                        await viewModel.loadProgress()
                    }
                } label: {
                    Text(range.rawValue)
                        .font(.system(size: 14, weight: viewModel.selectedRange == range ? .semibold : .medium))
                        .foregroundColor(viewModel.selectedRange == range ? .white : .gainsTextSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            Group {
                                if viewModel.selectedRange == range {
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.gainsCardSurface)
                                }
                            }
                        )
                }
            }
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gainsBgTertiary.opacity(0.5))
        )
        .padding(.horizontal, GainsDesign.paddingHorizontal)
    }
    
    private var statisticsSection: some View {
        VStack(spacing: 12) {
            // Top row - Calories stats
            HStack(spacing: 12) {
                StatCard(
                    title: "Avg Calories",
                    value: String(format: "%.0f", viewModel.averageCalories),
                    icon: "flame.fill",
                    iconColor: .gainsAccentOrange
                )
                StatCard(
                    title: "Total Calories",
                    value: "\(viewModel.totalCalories)",
                    icon: "sum",
                    iconColor: .gainsPrimary
                )
            }
            
            // Bottom row - Macros
            HStack(spacing: 12) {
                StatCard(
                    title: "Avg Protein",
                    value: String(format: "%.0fg", viewModel.averageProtein),
                    icon: "p.circle.fill",
                    iconColor: Color(hex: "FF6B6B")
                )
                StatCard(
                    title: "Avg Carbs",
                    value: String(format: "%.0fg", viewModel.averageCarbs),
                    icon: "c.circle.fill",
                    iconColor: .gainsPrimary
                )
                StatCard(
                    title: "Avg Fats",
                    value: String(format: "%.0fg", viewModel.averageFats),
                    icon: "f.circle.fill",
                    iconColor: Color(hex: "FFD93D")
                )
            }
        }
        .padding(.horizontal, GainsDesign.paddingHorizontal)
    }
    
    private var emptyState: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(Color.gainsBgTertiary)
                    .frame(width: 80, height: 80)
                
                Image(systemName: "chart.bar.fill")
                    .font(.system(size: 32))
                    .foregroundColor(.gainsTextMuted)
            }
            
            VStack(spacing: 8) {
                Text("No Data Yet")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(.white)
                
                Text("Start logging meals to see your progress")
                    .font(.system(size: 15))
                    .foregroundColor(.gainsTextSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
    
    private var chartsSection: some View {
        VStack(spacing: 16) {
            CaloriesChartView(dailyLogs: viewModel.dailyLogs)
                .padding(.horizontal, GainsDesign.paddingHorizontal)
            
            MacrosChartView(dailyLogs: viewModel.dailyLogs)
                .padding(.horizontal, GainsDesign.paddingHorizontal)
            
            WeightChartView(dailyLogs: viewModel.dailyLogs)
                .padding(.horizontal, GainsDesign.paddingHorizontal)
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    var icon: String? = nil
    var iconColor: Color = .gainsPrimary
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.system(size: 12))
                    .foregroundColor(.gainsTextSecondary)
                
                Spacer()
                
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 12))
                        .foregroundColor(iconColor)
                }
            }
            
            Text(value)
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: GainsDesign.cornerRadiusMedium)
                .fill(Color.gainsCardSurface)
        )
    }
}

#Preview {
    ProgressTrackingView()
}
