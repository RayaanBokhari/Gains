//
//  WorkoutPlanDetailView.swift
//  Gains
//
//  Created by Rayaan Bokhari on 12/20/25.
//

import SwiftUI

struct WorkoutPlanDetailView: View {
    let plan: WorkoutPlan
    @ObservedObject var planService: WorkoutPlanService
    @State private var showStartWorkout = false
    @State private var selectedTemplate: WorkoutTemplate?
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text(plan.name)
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.gainsText)
                    
                    if let description = plan.description {
                        Text(description)
                            .font(.system(size: 16))
                            .foregroundColor(.gainsSecondaryText)
                    }
                    
                    HStack(spacing: 16) {
                        Label("\(plan.daysPerWeek) days/week", systemImage: "calendar")
                        Label("\(plan.durationWeeks) weeks", systemImage: "clock")
                        Label(plan.difficulty.rawValue, systemImage: "chart.bar")
                    }
                    .font(.system(size: 14))
                    .foregroundColor(.gainsSecondaryText)
                    
                    if let goal = plan.goal {
                        Label(goal.rawValue, systemImage: "target")
                            .font(.system(size: 14))
                            .foregroundColor(.gainsPrimary)
                    }
                }
                .padding()
                .background(Color.gainsCardBackground)
                .cornerRadius(16)
                
                // Workout Days
                VStack(alignment: .leading, spacing: 16) {
                    Text("Workout Schedule")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.gainsText)
                    
                    ForEach(plan.workoutTemplates.sorted(by: { $0.dayNumber < $1.dayNumber })) { template in
                        Button {
                            selectedTemplate = template
                            showStartWorkout = true
                        } label: {
                            WorkoutDayCard(template: template)
                        }
                        .buttonStyle(.plain)
                    }
                }
                
                // Action Buttons
                VStack(spacing: 12) {
                    if !plan.isActive {
                        Button {
                            Task {
                                try? await planService.setActivePlan(plan)
                            }
                        } label: {
                            Text("Set as Active Plan")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.gainsPrimary)
                                .cornerRadius(12)
                        }
                    }
                    
                    Button {
                        showStartWorkout = true
                    } label: {
                        Text("Start Today's Workout")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.gainsPrimary)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.gainsCardBackground)
                            .cornerRadius(12)
                    }
                }
            }
            .padding()
        }
        .background(Color.gainsBackground.ignoresSafeArea())
        .navigationTitle("Plan Details")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showStartWorkout) {
            if let template = selectedTemplate {
                StartWorkoutFromPlanView(template: template)
            } else if let firstTemplate = plan.workoutTemplates.first {
                StartWorkoutFromPlanView(template: firstTemplate)
            }
        }
    }
}

struct StartWorkoutFromPlanView: View {
    let template: WorkoutTemplate
    @Environment(\.dismiss) var dismiss
    @StateObject private var workoutViewModel = WorkoutViewModel()
    @State private var showActiveWorkout = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.gainsBackground.ignoresSafeArea()
                
                VStack(spacing: 24) {
                    // Workout Preview
                    VStack(alignment: .leading, spacing: 12) {
                        Text(template.name)
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.gainsText)
                        
                        Text("\(template.exercises.count) exercises")
                            .font(.system(size: 14))
                            .foregroundColor(.gainsSecondaryText)
                        
                        Divider()
                        
                        ForEach(template.exercises) { exercise in
                            HStack {
                                Text(exercise.name)
                                    .font(.system(size: 16))
                                    .foregroundColor(.gainsText)
                                Spacer()
                                Text("\(exercise.targetSets) × \(exercise.targetReps)")
                                    .font(.system(size: 14))
                                    .foregroundColor(.gainsSecondaryText)
                            }
                        }
                    }
                    .padding()
                    .background(Color.gainsCardBackground)
                    .cornerRadius(16)
                    .padding(.horizontal)
                    
                    Spacer()
                    
                    // Start Button
                    Button {
                        startWorkout()
                    } label: {
                        Text("Start Workout")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.gainsPrimary)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal)
                    .padding(.bottom)
                }
                .padding(.top)
            }
            .navigationTitle("Start Workout")
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
                ActiveWorkoutView(viewModel: workoutViewModel)
            }
        }
    }
    
    private func startWorkout() {
        // Create a workout from the template
        workoutViewModel.startWorkout(name: template.name)
        
        // Add exercises from the template
        for plannedExercise in template.exercises {
            let sets = (0..<plannedExercise.targetSets).map { _ in ExerciseSet() }
            let exercise = Exercise(
                name: plannedExercise.name,
                sets: sets,
                restTime: plannedExercise.restSeconds != nil ? TimeInterval(plannedExercise.restSeconds!) : nil,
                notes: plannedExercise.notes
            )
            workoutViewModel.addExercise(exercise)
        }
        
        showActiveWorkout = true
    }
}

struct WorkoutDayCard: View {
    let template: WorkoutTemplate
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(template.name)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.gainsText)
            
            ForEach(template.exercises) { exercise in
                ExercisePlanRow(exercise: exercise)
            }
            
            if let notes = template.notes {
                Text(notes)
                    .font(.system(size: 12))
                    .foregroundColor(.gainsSecondaryText)
                    .italic()
            }
        }
        .padding()
        .background(Color.gainsCardBackground)
        .cornerRadius(12)
    }
}

struct ExercisePlanRow: View {
    let exercise: PlannedExercise
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(exercise.name)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.gainsText)
                
                HStack(spacing: 12) {
                    Text("\(exercise.targetSets) sets")
                    Text("× \(exercise.targetReps) reps")
                    if let rest = exercise.restSeconds {
                        Text("\(rest)s rest")
                    }
                }
                .font(.system(size: 12))
                .foregroundColor(.gainsSecondaryText)
                
                if let notes = exercise.notes {
                    Text(notes)
                        .font(.system(size: 11))
                        .foregroundColor(.gainsSecondaryText)
                        .italic()
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NavigationView {
        WorkoutPlanDetailView(
            plan: WorkoutPlan(
                name: "Sample Plan",
                description: "A sample workout plan",
                workoutTemplates: [
                    WorkoutTemplate(
                        name: "Day 1: Push",
                        dayNumber: 1,
                        exercises: [
                            PlannedExercise(name: "Bench Press", targetSets: 4, targetReps: "8-10")
                        ]
                    )
                ]
            ),
            planService: WorkoutPlanService()
        )
    }
}

