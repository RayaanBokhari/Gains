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
            VStack(spacing: 0) {
                // Tab selector
                Picker("", selection: $selectedTab) {
                    ForEach(WorkoutTab.allCases, id: \.self) { tab in
                        Text(tab.rawValue).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .padding()
                
                // Content
                switch selectedTab {
                case .history:
                    WorkoutHistoryView(viewModel: viewModel, showAICoach: $showAICoach, showNewWorkout: $showNewWorkout)
                case .plans:
                    WorkoutPlansContentView()
                }
            }
            .background(Color.gainsBackground)
            .navigationTitle("Workouts")
            .toolbar {
                if selectedTab == .history {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            showNewWorkout = true
                        } label: {
                            Image(systemName: "plus")
                                .foregroundColor(.gainsPrimary)
                        }
                    }
                }
            }
            .sheet(isPresented: $showAICoach) {
                AICoachView()
            }
        }
    }
}

struct WorkoutHistoryView: View {
    @ObservedObject var viewModel: WorkoutViewModel
    @Binding var showAICoach: Bool
    @Binding var showNewWorkout: Bool
    
    var body: some View {
        ZStack {
            Color.gainsBackground.ignoresSafeArea()
                
                if viewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .gainsPrimary))
                } else if viewModel.workouts.isEmpty {
                    // Empty state
                    VStack(spacing: 16) {
                        Image(systemName: "dumbbell.fill")
                            .font(.system(size: 48))
                            .foregroundColor(.gainsSecondaryText)
                        
                        Text("No Workouts Yet")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.gainsText)
                        
                        Text("Start tracking your fitness journey")
                            .font(.system(size: 14))
                            .foregroundColor(.gainsSecondaryText)
                        
                        Button {
                            showNewWorkout = true
                        } label: {
                            Text("Start Workout")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 24)
                                .padding(.vertical, 12)
                                .background(Color.gainsPrimary)
                                .cornerRadius(12)
                        }
                    }
                } else {
                    ScrollView {
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
                        .padding()
                    }
                    .refreshable {
                        // Force a fresh fetch from Firestore
                        await viewModel.refreshWorkouts()
                    }
                }
                
                // AI Coach Floating Button
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
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
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(Color.gainsPrimary)
                            .cornerRadius(24)
                            .shadow(color: Color.gainsPrimary.opacity(0.4), radius: 8, x: 0, y: 4)
                        }
                        .padding(.trailing, 20)
                        .padding(.bottom, 20)
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
}

// Extension for toolbar on WorkoutListView
extension WorkoutListView {
    @ToolbarContentBuilder
    func workoutToolbar() -> some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            Button {
                showNewWorkout = true
            } label: {
                Image(systemName: "plus")
                    .foregroundColor(.gainsPrimary)
            }
        }
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
                Color.gainsBackground.ignoresSafeArea()
                
                VStack(spacing: 24) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Workout Name")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.gainsSecondaryText)
                        
                        TextField("e.g., Push Day, Leg Day", text: $workoutName)
                            .textFieldStyle(.plain)
                            .padding()
                            .background(Color.gainsCardBackground)
                            .cornerRadius(12)
                            .foregroundColor(.gainsText)
                    }
                    .padding(.horizontal)
                    
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
                            .padding()
                            .background(workoutName.isEmpty ? Color.gray.opacity(0.3) : Color.gainsPrimary)
                            .cornerRadius(12)
                    }
                    .disabled(workoutName.isEmpty)
                    .padding(.horizontal)
                    
                    Spacer()
                }
                .padding(.top)
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
                // Dismiss this sheet too when active workout is dismissed
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
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(workout.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.gainsText)
                
                HStack(spacing: 12) {
                    Label("\(workout.exercises.count) exercises", systemImage: "figure.strengthtraining.traditional")
                        .font(.system(size: 12))
                        .foregroundColor(.gainsSecondaryText)
                    
                    Text(workout.date, style: .date)
                        .font(.system(size: 12))
                        .foregroundColor(.gainsSecondaryText)
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14))
                .foregroundColor(.gainsSecondaryText)
        }
        .padding()
        .background(Color.gainsCardBackground)
        .cornerRadius(12)
    }
}

#Preview {
    WorkoutListView()
}

