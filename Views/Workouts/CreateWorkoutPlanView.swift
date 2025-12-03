//
//  CreateWorkoutPlanView.swift
//  Gains
//
//  Created by Rayaan Bokhari on 12/20/25.
//

import SwiftUI

struct CreateWorkoutPlanView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var planService: WorkoutPlanService
    
    @State private var planName = ""
    @State private var description = ""
    @State private var selectedGoal: FitnessGoal?
    @State private var selectedDifficulty: PlanDifficulty = .intermediate
    @State private var durationWeeks = 4
    @State private var daysPerWeek = 4
    @State private var workoutTemplates: [WorkoutTemplate] = []
    @State private var isSaving = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.gainsBackground.ignoresSafeArea()
                
                Form {
                    Section("Plan Details") {
                        TextField("Plan Name", text: $planName)
                        TextField("Description (Optional)", text: $description, axis: .vertical)
                            .lineLimit(3...6)
                        
                        Picker("Goal", selection: $selectedGoal) {
                            Text("None").tag(nil as FitnessGoal?)
                            ForEach(FitnessGoal.allCases, id: \.self) { goal in
                                Text(goal.rawValue).tag(goal as FitnessGoal?)
                            }
                        }
                        
                        Picker("Difficulty", selection: $selectedDifficulty) {
                            ForEach(PlanDifficulty.allCases, id: \.self) { diff in
                                Text(diff.rawValue).tag(diff)
                            }
                        }
                        
                        Stepper("Duration: \(durationWeeks) weeks", value: $durationWeeks, in: 1...12)
                        Stepper("Days per week: \(daysPerWeek)", value: $daysPerWeek, in: 3...7)
                    }
                    
                    Section("Workout Days") {
                        ForEach(workoutTemplates.indices, id: \.self) { index in
                            NavigationLink(destination: EditWorkoutTemplateView(
                                template: Binding(
                                    get: { workoutTemplates[index] },
                                    set: { workoutTemplates[index] = $0 }
                                )
                            )) {
                                Text(workoutTemplates[index].name)
                            }
                        }
                        .onDelete { indices in
                            workoutTemplates.remove(atOffsets: indices)
                        }
                        
                        Button {
                            let newTemplate = WorkoutTemplate(
                                name: "Day \(workoutTemplates.count + 1)",
                                dayNumber: workoutTemplates.count + 1,
                                exercises: []
                            )
                            workoutTemplates.append(newTemplate)
                        } label: {
                            Label("Add Workout Day", systemImage: "plus")
                        }
                    }
                }
            }
            .navigationTitle("Create Plan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        savePlan()
                    }
                    .disabled(planName.isEmpty || workoutTemplates.isEmpty || isSaving)
                }
            }
        }
    }
    
    private func savePlan() {
        guard !planName.isEmpty, !workoutTemplates.isEmpty else { return }
        
        isSaving = true
        
        let plan = WorkoutPlan(
            name: planName,
            description: description.isEmpty ? nil : description,
            goal: selectedGoal,
            difficulty: selectedDifficulty,
            durationWeeks: durationWeeks,
            daysPerWeek: daysPerWeek,
            workoutTemplates: workoutTemplates,
            createdBy: .user
        )
        
        Task {
            do {
                try await planService.savePlan(plan)
                await MainActor.run {
                    isSaving = false
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isSaving = false
                    print("Error saving plan: \(error)")
                }
            }
        }
    }
}

struct EditWorkoutTemplateView: View {
    @Binding var template: WorkoutTemplate
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        Form {
            Section("Day Details") {
                TextField("Day Name", text: $template.name)
                Stepper("Day Number: \(template.dayNumber)", value: $template.dayNumber, in: 1...7)
                TextField("Notes (Optional)", text: Binding(
                    get: { template.notes ?? "" },
                    set: { template.notes = $0.isEmpty ? nil : $0 }
                ), axis: .vertical)
                .lineLimit(3...6)
            }
            
            Section("Exercises") {
                ForEach(template.exercises.indices, id: \.self) { index in
                    NavigationLink(destination: EditPlannedExerciseView(
                        exercise: Binding(
                            get: { template.exercises[index] },
                            set: { template.exercises[index] = $0 }
                        )
                    )) {
                        Text(template.exercises[index].name)
                    }
                }
                .onDelete { indices in
                    template.exercises.remove(atOffsets: indices)
                }
                
                Button {
                    let newExercise = PlannedExercise(name: "New Exercise")
                    template.exercises.append(newExercise)
                } label: {
                    Label("Add Exercise", systemImage: "plus")
                }
            }
        }
        .navigationTitle("Edit Day")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct EditPlannedExerciseView: View {
    @Binding var exercise: PlannedExercise
    
    var body: some View {
        Form {
            TextField("Exercise Name", text: $exercise.name)
            Stepper("Sets: \(exercise.targetSets)", value: $exercise.targetSets, in: 1...10)
            TextField("Reps (e.g., 8-12)", text: $exercise.targetReps)
            Stepper("Rest: \(exercise.restSeconds ?? 0)s", value: Binding(
                get: { exercise.restSeconds ?? 90 },
                set: { exercise.restSeconds = $0 }
            ), in: 0...300)
            TextField("Notes (Optional)", text: Binding(
                get: { exercise.notes ?? "" },
                set: { exercise.notes = $0.isEmpty ? nil : $0 }
            ), axis: .vertical)
            .lineLimit(3...6)
        }
        .navigationTitle("Edit Exercise")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    CreateWorkoutPlanView(planService: WorkoutPlanService())
}

