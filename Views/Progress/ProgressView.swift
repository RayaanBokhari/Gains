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
                Color.gainsBackground.ignoresSafeArea()
                
                if viewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .gainsPrimary))
                } else {
                    ScrollView {
                        VStack(spacing: 24) {
                            // Time Range Picker
                            Picker("Time Range", selection: $viewModel.selectedRange) {
                                ForEach(TimeRange.allCases, id: \.self) { range in
                                    Text(range.rawValue).tag(range)
                                }
                            }
                            .pickerStyle(.segmented)
                            .padding(.horizontal)
                            .onChange(of: viewModel.selectedRange) { _ in
                                Task {
                                    await viewModel.loadProgress()
                                }
                            }
                            
                            // Statistics Cards
                            if !viewModel.dailyLogs.isEmpty {
                                VStack(spacing: 12) {
                                    HStack {
                                        StatCard(title: "Avg Calories", value: String(format: "%.0f", viewModel.averageCalories))
                                        StatCard(title: "Total Calories", value: "\(viewModel.totalCalories)")
                                    }
                                    
                                    HStack {
                                        StatCard(title: "Avg Protein", value: String(format: "%.0fg", viewModel.averageProtein))
                                        StatCard(title: "Avg Carbs", value: String(format: "%.0fg", viewModel.averageCarbs))
                                        StatCard(title: "Avg Fats", value: String(format: "%.0fg", viewModel.averageFats))
                                    }
                                }
                                .padding(.horizontal)
                            }
                            
                            // Charts
                            if viewModel.dailyLogs.isEmpty {
                                VStack(spacing: 16) {
                                    Image(systemName: "chart.bar.fill")
                                        .font(.system(size: 48))
                                        .foregroundColor(.gainsSecondaryText)
                                    
                                    Text("No Data Yet")
                                        .font(.system(size: 20, weight: .semibold))
                                        .foregroundColor(.gainsText)
                                    
                                    Text("Start logging meals to see your progress")
                                        .font(.system(size: 14))
                                        .foregroundColor(.gainsSecondaryText)
                                        .multilineTextAlignment(.center)
                                }
                                .padding()
                            } else {
                                CaloriesChartView(dailyLogs: viewModel.dailyLogs)
                                    .padding(.horizontal)
                                
                                MacrosChartView(dailyLogs: viewModel.dailyLogs)
                                    .padding(.horizontal)
                                
                                WeightChartView(dailyLogs: viewModel.dailyLogs)
                                    .padding(.horizontal)
                            }
                        }
                        .padding(.vertical)
                    }
                }
            }
            .navigationTitle("Progress")
            .task {
                await viewModel.loadProgress()
            }
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 12))
                .foregroundColor(.gainsSecondaryText)
            
            Text(value)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.gainsText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.gainsCardBackground)
        .cornerRadius(12)
    }
}

#Preview {
    ProgressTrackingView()
}

