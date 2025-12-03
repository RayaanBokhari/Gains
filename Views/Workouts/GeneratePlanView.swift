//
//  GeneratePlanView.swift
//  Gains
//
//  Created by Rayaan Bokhari on 12/20/25.
//

import SwiftUI

struct GeneratePlanView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var planService: WorkoutPlanService
    @StateObject private var profileViewModel = ProfileViewModel()
    
    @State private var selectedGoal: FitnessGoal = .maintenance
    @State private var selectedExperience: TrainingExperience = .beginner
    @State private var daysPerWeek = 4
    @State private var selectedSplit: TrainingSplit?
    @State private var equipment: [String] = []
    @State private var constraints = ""
    @State private var isGenerating = false
    @State private var generatedPlan: WorkoutPlan?
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.gainsBackground.ignoresSafeArea()
                
                if isGenerating {
                    // Loading state
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.5)
                            .progressViewStyle(CircularProgressViewStyle(tint: .gainsPrimary))
                        
                        Text("Generating your personalized workout plan...")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.gainsText)
                            .multilineTextAlignment(.center)
                        
                        Text("This may take up to 30 seconds")
                            .font(.system(size: 14))
                            .foregroundColor(.gainsSecondaryText)
                    }
                    .padding()
                } else if let plan = generatedPlan {
                    // Show generated plan preview
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Generated Plan")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.gainsText)
                            
                            Text(plan.name)
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.gainsText)
                            
                            if let description = plan.description {
                                Text(description)
                                    .font(.system(size: 14))
                                    .foregroundColor(.gainsSecondaryText)
                            }
                            
                            ForEach(plan.workoutTemplates.sorted(by: { $0.dayNumber < $1.dayNumber })) { template in
                                WorkoutDayCard(template: template)
                            }
                            
                            Button {
                                savePlan(plan)
                            } label: {
                                Text("Save Plan")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.gainsPrimary)
                                    .cornerRadius(12)
                            }
                            
                            Button {
                                generatedPlan = nil
                            } label: {
                                Text("Generate Another")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.gainsPrimary)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.gainsCardBackground)
                                    .cornerRadius(12)
                            }
                        }
                        .padding()
                    }
                } else {
                    // Show generation form
                    Form {
                        Section("Plan Preferences") {
                            Picker("Goal", selection: $selectedGoal) {
                                ForEach(FitnessGoal.allCases, id: \.self) { goal in
                                    Text(goal.rawValue).tag(goal)
                                }
                            }
                            
                            Picker("Experience Level", selection: $selectedExperience) {
                                ForEach(TrainingExperience.allCases, id: \.self) { exp in
                                    Text(exp.rawValue).tag(exp)
                                }
                            }
                            
                            Stepper("Days per week: \(daysPerWeek)", value: $daysPerWeek, in: 3...7)
                            
                            Picker("Training Split (Optional)", selection: $selectedSplit) {
                                Text("Let AI decide").tag(nil as TrainingSplit?)
                                ForEach(TrainingSplit.allCases, id: \.self) { split in
                                    Text(split.rawValue).tag(split as TrainingSplit?)
                                }
                            }
                        }
                        
                        Section("Equipment & Constraints") {
                            TextField("Available Equipment (comma-separated)", text: Binding(
                                get: { equipment.joined(separator: ", ") },
                                set: { equipment = $0.isEmpty ? [] : $0.split(separator: ",").map { String($0).trimmingCharacters(in: .whitespaces) } }
                            ))
                            
                            TextField("Constraints (injuries, time limits, etc.)", text: $constraints, axis: .vertical)
                                .lineLimit(3...6)
                        }
                        
                        if let error = errorMessage {
                            Section {
                                Text(error)
                                    .foregroundColor(.red)
                                    .font(.system(size: 14))
                            }
                        }
                    }
                }
            }
            .navigationTitle("Generate Plan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                if generatedPlan == nil {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            generatePlan()
                        } label: {
                            if isGenerating {
                                ProgressView()
                            } else {
                                Text("Generate")
                            }
                        }
                        .disabled(isGenerating)
                    }
                }
            }
            .onAppear {
                Task {
                    await profileViewModel.loadProfile()
                    // Pre-fill with profile data if available
                    if let goal = profileViewModel.profile.primaryGoal {
                        selectedGoal = goal
                    }
                    if let experience = profileViewModel.profile.trainingExperience {
                        selectedExperience = experience
                    }
                    if let split = profileViewModel.profile.trainingSplit {
                        selectedSplit = split
                    }
                }
            }
        }
    }
    
    private func generatePlan() {
        isGenerating = true
        errorMessage = nil
        
        Task {
            do {
                let chatGPTService = ChatGPTService()
                let plan = try await chatGPTService.generateWorkoutPlan(
                    goal: selectedGoal,
                    experience: selectedExperience,
                    daysPerWeek: daysPerWeek,
                    split: selectedSplit,
                    equipment: equipment.isEmpty ? nil : equipment,
                    constraints: constraints.isEmpty ? nil : constraints
                )
                
                await MainActor.run {
                    generatedPlan = plan
                    isGenerating = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isGenerating = false
                }
            }
        }
    }
    
    private func savePlan(_ plan: WorkoutPlan) {
        Task {
            do {
                try await planService.savePlan(plan)
                await MainActor.run {
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to save plan: \(error.localizedDescription)"
                }
            }
        }
    }
}

#Preview {
    GeneratePlanView(planService: WorkoutPlanService())
}

