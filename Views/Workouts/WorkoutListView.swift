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
                // Gradient background
                LinearGradient(
                    colors: [Color(hex: "0D0E14"), Color(hex: "0A0A0B")],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Custom Header
                    headerSection
                    
                    // Tab selector with frosted look
                    tabSelector
                        .padding(.horizontal, GainsDesign.paddingHorizontal)
                        .padding(.bottom, 16)
                    
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
    
    private var headerSection: some View {
        HStack {
            Text("Workouts")
                .font(.system(size: 34, weight: .bold))
                .foregroundColor(.white)
            
            Spacer()
            
            if selectedTab == .history {
                Button {
                    showNewWorkout = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.gainsPrimary, Color.gainsAccentTeal],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
            }
        }
        .padding(.horizontal, GainsDesign.paddingHorizontal)
        .padding(.top, GainsDesign.titlePaddingTop)
        .padding(.bottom, 20)
    }
    
    private var tabSelector: some View {
        HStack(spacing: 0) {
            ForEach(WorkoutTab.allCases, id: \.self) { tab in
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        selectedTab = tab
                    }
                } label: {
                    Text(tab.rawValue)
                        .font(.system(size: 15, weight: selectedTab == tab ? .semibold : .medium))
                        .foregroundColor(selectedTab == tab ? .white : .gainsTextSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            Group {
                                if selectedTab == tab {
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(Color.gainsCardSurface)
                                }
                            }
                        )
                }
            }
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.gainsBgTertiary.opacity(0.5))
        )
    }
}

struct WorkoutHistoryView: View {
    @ObservedObject var viewModel: WorkoutViewModel
    @Binding var showAICoach: Bool
    @Binding var showNewWorkout: Bool
    
    var body: some View {
        ZStack {
            if viewModel.isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .gainsPrimary))
            } else if viewModel.workouts.isEmpty {
                // Empty state
                emptyState
            } else {
                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.workouts) { workout in
                            NavigationLink(destination: WorkoutDetailView(workout: workout)) {
                                WorkoutRowView(workout: workout)
                            }
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
    
    private var emptyState: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(Color.gainsBgTertiary)
                    .frame(width: 80, height: 80)
                
                Image(systemName: "dumbbell.fill")
                    .font(.system(size: 32))
                    .foregroundColor(.gainsTextMuted)
            }
            
            VStack(spacing: 8) {
                Text("No Workouts Yet")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(.white)
                
                Text("Start tracking your fitness journey")
                    .font(.system(size: 15))
                    .foregroundColor(.gainsTextSecondary)
            }
            
            Button {
                showNewWorkout = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "plus")
                        .font(.system(size: 14, weight: .semibold))
                    Text("Start Workout")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 28)
                .padding(.vertical, 14)
                .background(
                    LinearGradient(
                        colors: [Color.gainsPrimary, Color.gainsAccentBlue],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(14)
                .shadow(color: Color.gainsPrimary.opacity(0.3), radius: 12, x: 0, y: 6)
            }
        }
        .padding()
    }
    
    private var aiCoachButton: some View {
        Button {
            showAICoach = true
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .font(.system(size: 16, weight: .semibold))
                Text("AI Coach")
                    .font(.system(size: 14, weight: .semibold))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 18)
            .padding(.vertical, 14)
            .background(
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [Color.gainsPrimary, Color.gainsAccentBlue],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            )
            .shadow(color: Color.gainsPrimary.opacity(0.4), radius: 12, x: 0, y: 6)
        }
        .padding(.trailing, GainsDesign.paddingHorizontal)
        .padding(.bottom, 24)
    }
}

struct NewWorkoutView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: WorkoutViewModel
    @State private var workoutName = ""
    @State private var showActiveWorkout = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.gainsBgPrimary.ignoresSafeArea()
                
                VStack(spacing: 24) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Workout Name")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.gainsTextSecondary)
                        
                        TextField("e.g., Push Day, Leg Day", text: $workoutName)
                            .textFieldStyle(.plain)
                            .font(.system(size: 16))
                            .padding()
                            .background(Color.gainsCardSurface)
                            .cornerRadius(GainsDesign.cornerRadiusSmall)
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, GainsDesign.paddingHorizontal)
                    
                    Button {
                        if !workoutName.isEmpty {
                            viewModel.startWorkout(name: workoutName)
                            showActiveWorkout = true
                        }
                    } label: {
                        Text("Start Workout")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: GainsDesign.buttonHeightLarge)
                            .background(
                                Group {
                                    if workoutName.isEmpty {
                                        Color.gainsTextMuted.opacity(0.3)
                                    } else {
                                        LinearGradient(
                                            colors: [Color.gainsPrimary, Color.gainsAccentBlue],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    }
                                }
                            )
                            .cornerRadius(GainsDesign.cornerRadiusSmall)
                    }
                    .disabled(workoutName.isEmpty)
                    .padding(.horizontal, GainsDesign.paddingHorizontal)
                    
                    Spacer()
                }
                .padding(.top, 24)
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

struct WorkoutRowView: View {
    let workout: Workout
    
    var body: some View {
        HStack(spacing: 14) {
            // Icon
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.gainsPrimary.opacity(0.15))
                    .frame(width: 44, height: 44)
                
                Image(systemName: "figure.strengthtraining.traditional")
                    .font(.system(size: 18))
                    .foregroundColor(.gainsPrimary)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(workout.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                
                HStack(spacing: 8) {
                    Text("\(workout.exercises.count) exercises")
                        .font(.system(size: 13))
                        .foregroundColor(.gainsTextSecondary)
                    
                    Circle()
                        .fill(Color.gainsTextMuted)
                        .frame(width: 3, height: 3)
                    
                    Text(workout.date, style: .date)
                        .font(.system(size: 13))
                        .foregroundColor(.gainsTextMuted)
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.gainsTextMuted)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: GainsDesign.cornerRadiusMedium)
                .fill(Color.gainsCardSurface)
        )
    }
}

#Preview {
    WorkoutListView()
}
