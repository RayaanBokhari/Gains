//
//  WorkoutListView.swift
//  Gains
//
//  Created by Rayaan Bokhari on 11/20/25.
//

import SwiftUI

enum WorkoutTab: String, CaseIterable {
    case history = "History"
    case plans = "Plans"
}

struct WorkoutListView: View {
    @StateObject private var viewModel = WorkoutViewModel()
    @State private var showAICoach = false
    @State private var showNewWorkout = false
    @State private var selectedTab: WorkoutTab = .history
    
    var body: some View {
        NavigationView {
            ZStack {
                // Deep black background
                Color.gainsBgPrimary
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Custom Header with generous breathing room
                    headerSection
                    
                    // Apple-style segmented control
                    tabSelector
                        .padding(.horizontal, GainsDesign.paddingHorizontal)
                        .padding(.bottom, GainsDesign.spacingXL)
                    
                    // Content
                    switch selectedTab {
                    case .history:
                        WorkoutHistoryView(viewModel: viewModel, showAICoach: $showAICoach, showNewWorkout: $showNewWorkout)
                    case .plans:
                        WorkoutPlansContentView()
                    }
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showAICoach) {
                AICoachView()
            }
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        HStack(alignment: .center) {
            Text("Workouts")
                .font(.system(size: GainsDesign.titleLarge, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            
            Spacer()
            
            if selectedTab == .history {
                Button {
                    showNewWorkout = true
                } label: {
                    ZStack {
                        Circle()
                            .fill(Color.gainsPrimary)
                            .frame(width: 32, height: 32)
                        
                        Image(systemName: "plus")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    .shadow(color: Color.gainsPrimary.opacity(0.4), radius: 8, x: 0, y: 4)
                }
            }
        }
        .padding(.horizontal, GainsDesign.paddingHorizontal)
        .padding(.top, GainsDesign.titlePaddingTop)
        .padding(.bottom, GainsDesign.spacingXL)
    }
    
    // MARK: - Tab Selector (Apple Fitness Style)
    private var tabSelector: some View {
        GeometryReader { geometry in
            let tabWidth = (geometry.size.width - 8) / 2
            
            ZStack(alignment: .leading) {
                // Background pill
                RoundedRectangle(cornerRadius: GainsDesign.cornerRadiusSmall)
                    .fill(Color.gainsBgTertiary.opacity(0.6))
                
                // Selection indicator
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.gainsCardElevated)
                    .frame(width: tabWidth)
                    .offset(x: selectedTab == .history ? 4 : tabWidth + 4)
                    .animation(.spring(response: 0.35, dampingFraction: 0.8), value: selectedTab)
                
                // Tab buttons
                HStack(spacing: 0) {
                    ForEach(WorkoutTab.allCases, id: \.self) { tab in
                        Button {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                selectedTab = tab
                            }
                        } label: {
                            Text(tab.rawValue)
                                .font(.system(size: GainsDesign.callout, weight: selectedTab == tab ? .semibold : .medium))
                                .foregroundColor(selectedTab == tab ? .white : .gainsTextSecondary)
                                .frame(maxWidth: .infinity)
                                .frame(height: 40)
                        }
                    }
                }
            }
        }
        .frame(height: 48)
    }
}

// MARK: - Workout History View
struct WorkoutHistoryView: View {
    @ObservedObject var viewModel: WorkoutViewModel
    @Binding var showAICoach: Bool
    @Binding var showNewWorkout: Bool
    
    var body: some View {
        ZStack {
            if viewModel.isLoading {
                VStack(spacing: GainsDesign.spacingL) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .gainsPrimary))
                        .scaleEffect(1.2)
                    
                    Text("Loading workouts...")
                        .font(.system(size: GainsDesign.subheadline))
                        .foregroundColor(.gainsTextSecondary)
                }
            } else if viewModel.workouts.isEmpty {
                emptyState
            } else {
                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: GainsDesign.cardSpacing) {
                        ForEach(viewModel.workouts) { workout in
                            NavigationLink(destination: WorkoutDetailView(workout: workout)) {
                                WorkoutRowView(workout: workout)
                            }
                            .buttonStyle(.plain)
                            .contextMenu {
                                Button(role: .destructive) {
                                    Task {
                                        await viewModel.deleteWorkout(workout)
                                    }
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                    .padding(.horizontal, GainsDesign.paddingHorizontal)
                    .padding(.bottom, 100)
                }
                .refreshable {
                    await viewModel.refreshWorkouts()
                }
            }
            
            // AI Coach Floating Button
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    aiCoachButton
                }
            }
        }
        .onAppear {
            viewModel.startListening()
        }
        .sheet(isPresented: $showNewWorkout) {
            NewWorkoutView(viewModel: viewModel)
        }
    }
    
    // MARK: - Empty State
    private var emptyState: some View {
        VStack(spacing: GainsDesign.spacingXXL) {
            Spacer()
            
            // Icon with soft background
            ZStack {
                Circle()
                    .fill(Color.gainsBgTertiary)
                    .frame(width: 96, height: 96)
                
                Image(systemName: "dumbbell.fill")
                    .font(.system(size: 40, weight: .medium))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.gainsTextTertiary, Color.gainsTextMuted],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            }
            
            VStack(spacing: GainsDesign.spacingS) {
                Text("No Workouts Yet")
                    .font(.system(size: GainsDesign.titleSmall, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                
                Text("Start tracking your fitness journey")
                    .font(.system(size: GainsDesign.callout))
                    .foregroundColor(.gainsTextSecondary)
            }
            
            // Primary CTA
            Button {
                showNewWorkout = true
            } label: {
                HStack(spacing: GainsDesign.spacingS) {
                    Image(systemName: "plus")
                        .font(.system(size: 14, weight: .semibold))
                    Text("Start Workout")
                        .font(.system(size: GainsDesign.body, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(width: 200)
                .frame(height: GainsDesign.buttonHeightLarge)
                .background(
                    RoundedRectangle(cornerRadius: GainsDesign.cornerRadiusMedium)
                        .fill(Color.gainsPrimary)
                )
                .shadow(color: Color.gainsPrimary.opacity(0.35), radius: 16, x: 0, y: 8)
            }
            
            Spacer()
        }
        .padding(.horizontal, GainsDesign.paddingHorizontal)
    }
    
    // MARK: - AI Coach Button
    private var aiCoachButton: some View {
        Button {
            showAICoach = true
        } label: {
            HStack(spacing: GainsDesign.spacingS) {
                Image(systemName: "sparkles")
                    .font(.system(size: 15, weight: .semibold))
                Text("AI Coach")
                    .font(.system(size: GainsDesign.subheadline, weight: .semibold))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(
                Capsule()
                    .fill(Color.gainsPrimaryGradient)
            )
            .shadow(color: Color.gainsPrimary.opacity(0.4), radius: 16, x: 0, y: 6)
        }
        .padding(.trailing, GainsDesign.paddingHorizontal)
        .padding(.bottom, GainsDesign.spacingXXL)
    }
}

// MARK: - New Workout View
struct NewWorkoutView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: WorkoutViewModel
    @State private var workoutName = ""
    @State private var showActiveWorkout = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.gainsBgPrimary.ignoresSafeArea()
                
                VStack(spacing: GainsDesign.spacingXXL) {
                    // Input Section
                    VStack(alignment: .leading, spacing: GainsDesign.spacingM) {
                        Text("Workout Name")
                            .font(.system(size: GainsDesign.subheadline, weight: .medium))
                            .foregroundColor(.gainsTextSecondary)
                        
                        TextField("e.g., Push Day, Leg Day", text: $workoutName)
                            .textFieldStyle(.plain)
                            .font(.system(size: GainsDesign.body))
                            .padding(.horizontal, GainsDesign.spacingL)
                            .padding(.vertical, GainsDesign.spacingL)
                            .background(
                                RoundedRectangle(cornerRadius: GainsDesign.cornerRadiusMedium)
                                    .fill(Color.gainsCardSurface)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: GainsDesign.cornerRadiusMedium)
                                    .stroke(Color.gainsInputBorder, lineWidth: 0.5)
                            )
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, GainsDesign.paddingHorizontal)
                    
                    // Start Button
                    Button {
                        if !workoutName.isEmpty {
                            viewModel.startWorkout(name: workoutName)
                            showActiveWorkout = true
                        }
                    } label: {
                        Text("Start Workout")
                            .font(.system(size: GainsDesign.body, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: GainsDesign.buttonHeightLarge)
                            .background(
                                RoundedRectangle(cornerRadius: GainsDesign.cornerRadiusMedium)
                                    .fill(workoutName.isEmpty ? Color.gainsTextMuted : Color.gainsPrimary)
                            )
                            .shadow(color: workoutName.isEmpty ? .clear : Color.gainsPrimary.opacity(0.3), radius: 12, x: 0, y: 6)
                    }
                    .disabled(workoutName.isEmpty)
                    .padding(.horizontal, GainsDesign.paddingHorizontal)
                    .animation(.easeInOut(duration: 0.2), value: workoutName.isEmpty)
                    
                    Spacer()
                }
                .padding(.top, GainsDesign.spacingXXL)
            }
            .navigationTitle("New Workout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.gainsPrimary)
                }
            }
            .fullScreenCover(isPresented: $showActiveWorkout, onDismiss: {
                dismiss()
            }) {
                ActiveWorkoutView(viewModel: viewModel)
            }
        }
    }
}

// MARK: - Workout Row View (Premium Card Style)
struct WorkoutRowView: View {
    let workout: Workout
    
    // Get appropriate icon for workout type
    private var workoutIcon: String {
        let name = workout.name.lowercased()
        if name.contains("push") {
            return "figure.arms.open"
        } else if name.contains("pull") {
            return "figure.strengthtraining.traditional"
        } else if name.contains("leg") {
            return "figure.run"
        } else if name.contains("chest") {
            return "figure.arms.open"
        } else if name.contains("back") {
            return "figure.strengthtraining.traditional"
        } else if name.contains("arm") || name.contains("bicep") || name.contains("tricep") {
            return "figure.boxing"
        } else if name.contains("shoulder") {
            return "figure.boxing"
        } else if name.contains("core") || name.contains("ab") {
            return "figure.core.training"
        } else if name.contains("cardio") {
            return "figure.run"
        }
        return "figure.strengthtraining.traditional"
    }
    
    var body: some View {
        HStack(spacing: GainsDesign.spacingL) {
            // Icon Container with blue gradient
            ZStack {
                RoundedRectangle(cornerRadius: GainsDesign.cornerRadiusSmall)
                    .fill(
                        LinearGradient(
                            colors: [Color.gainsPrimary.opacity(0.2), Color.gainsPrimary.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: GainsDesign.iconContainerMedium, height: GainsDesign.iconContainerMedium)
                
                Image(systemName: workoutIcon)
                    .font(.system(size: GainsDesign.iconMedium, weight: .medium))
                    .foregroundColor(.gainsPrimary)
            }
            
            // Content
            VStack(alignment: .leading, spacing: GainsDesign.spacingXS) {
                Text(workout.name)
                    .font(.system(size: GainsDesign.headline, weight: .semibold))
                    .foregroundColor(.white)
                
                HStack(spacing: GainsDesign.spacingS) {
                    Text("\(workout.exercises.count) exercise\(workout.exercises.count == 1 ? "" : "s")")
                        .font(.system(size: GainsDesign.footnote))
                        .foregroundColor(.gainsTextSecondary)
                    
                    Text("•")
                        .font(.system(size: 8))
                        .foregroundColor(.gainsTextTertiary)
                    
                    Text(workout.date, style: .date)
                        .font(.system(size: GainsDesign.footnote))
                        .foregroundColor(.gainsTextTertiary)
                }
            }
            
            Spacer()
            
            // Chevron
            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.gainsTextTertiary)
        }
        .padding(GainsDesign.cardPadding)
        .background(
            RoundedRectangle(cornerRadius: GainsDesign.cornerRadiusLarge)
                .fill(Color.gainsCardSurface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: GainsDesign.cornerRadiusLarge)
                .stroke(Color.white.opacity(0.04), lineWidth: 0.5)
        )
        .shadow(
            color: Color.black.opacity(0.15),
            radius: 12,
            x: 0,
            y: 4
        )
    }
}

#Preview {
    WorkoutListView()
}
