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
    @State private var isReorderingDays = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.gainsBackground.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Plan Details Card
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Plan Details")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.gainsText)

                            VStack(spacing: 16) {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Plan Name")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.gainsText)

                                    TextField("Enter plan name", text: $planName)
                                        .textFieldStyle(.plain)
                                        .padding()
                                        .background(Color.gainsCardBackground)
                                        .cornerRadius(12)
                                        .foregroundColor(.gainsText)
                                }

                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Description (Optional)")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.gainsText)

                                    TextField("Describe your workout plan", text: $description, axis: .vertical)
                                        .textFieldStyle(.plain)
                                        .padding()
                                        .background(Color.gainsCardBackground)
                                        .cornerRadius(12)
                                        .foregroundColor(.gainsText)
                                        .lineLimit(3...6)
                                }

                                HStack(spacing: 16) {
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("Goal")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(.gainsText)

                                        Menu {
                                            Button {
                                                selectedGoal = nil
                                            } label: {
                                                Text("None")
                                            }
                                            ForEach(FitnessGoal.allCases, id: \.self) { goal in
                                                Button {
                                                    selectedGoal = goal
                                                } label: {
                                                    Text(goal.rawValue)
                                                }
                                            }
                                        } label: {
                                            HStack {
                                                Text(selectedGoal?.rawValue ?? "None")
                                                    .foregroundColor(.gainsText)
                                                Spacer()
                                                Image(systemName: "chevron.down")
                                                    .foregroundColor(.gainsSecondaryText)
                                            }
                                            .padding()
                                            .background(Color.gainsCardBackground)
                                            .cornerRadius(12)
                                        }
                                    }

                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("Difficulty")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(.gainsText)

                                        Menu {
                                            ForEach(PlanDifficulty.allCases, id: \.self) { diff in
                                                Button {
                                                    selectedDifficulty = diff
                                                } label: {
                                                    Text(diff.rawValue)
                                                }
                                            }
                                        } label: {
                                            HStack {
                                                Text(selectedDifficulty.rawValue)
                                                    .foregroundColor(.gainsText)
                                                Spacer()
                                                Image(systemName: "chevron.down")
                                                    .foregroundColor(.gainsSecondaryText)
                                            }
                                            .padding()
                                            .background(Color.gainsCardBackground)
                                            .cornerRadius(12)
                                        }
                                    }
                                }

                                HStack(spacing: 16) {
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("Duration")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(.gainsText)

                                        HStack {
                                            Button {
                                                if durationWeeks > 1 { durationWeeks -= 1 }
                                            } label: {
                                                Image(systemName: "minus")
                                                    .foregroundColor(.gainsSecondaryText)
                                                    .padding(8)
                                                    .background(Color.gainsCardBackground)
                                                    .cornerRadius(8)
                                            }

                                            Text("\(durationWeeks) weeks")
                                                .font(.system(size: 16, weight: .medium))
                                                .foregroundColor(.gainsText)
                                                .frame(maxWidth: .infinity)

                                            Button {
                                                if durationWeeks < 12 { durationWeeks += 1 }
                                            } label: {
                                                Image(systemName: "plus")
                                                    .foregroundColor(.gainsSecondaryText)
                                                    .padding(8)
                                                    .background(Color.gainsCardBackground)
                                                    .cornerRadius(8)
                                            }
                                        }
                                        .background(Color.gainsCardBackground)
                                        .cornerRadius(12)
                                    }

                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("Days per Week")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(.gainsText)

                                        HStack {
                                            Button {
                                                if daysPerWeek > 3 { daysPerWeek -= 1 }
                                            } label: {
                                                Image(systemName: "minus")
                                                    .foregroundColor(.gainsSecondaryText)
                                                    .padding(8)
                                                    .background(Color.gainsCardBackground)
                                                    .cornerRadius(8)
                                            }

                                            Text("\(daysPerWeek) days")
                                                .font(.system(size: 16, weight: .medium))
                                                .foregroundColor(.gainsText)
                                                .frame(maxWidth: .infinity)

                                            Button {
                                                if daysPerWeek < 7 { daysPerWeek += 1 }
                                            } label: {
                                                Image(systemName: "plus")
                                                    .foregroundColor(.gainsSecondaryText)
                                                    .padding(8)
                                                    .background(Color.gainsCardBackground)
                                                    .cornerRadius(8)
                                            }
                                        }
                                        .background(Color.gainsCardBackground)
                                        .cornerRadius(12)
                                    }
                                }
                            }
                        }
                        .padding()
                        .background(Color.gainsCardBackground)
                        .cornerRadius(16)

                        // Workout Days Section
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Text("Workout Days")
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundColor(.gainsText)

                                Spacer()

                                Text("\(workoutTemplates.count) days")
                                    .font(.system(size: 14))
                                    .foregroundColor(.gainsSecondaryText)
                            }

                            if workoutTemplates.isEmpty {
                                VStack(spacing: 16) {
                                    Image(systemName: "calendar.badge.plus")
                                        .font(.system(size: 48))
                                        .foregroundColor(.gainsSecondaryText.opacity(0.5))

                                    Text("No workout days yet")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.gainsSecondaryText)

                                    Button {
                                        let newTemplate = WorkoutTemplate(
                                            name: "Day \(workoutTemplates.count + 1)",
                                            dayNumber: workoutTemplates.count + 1,
                                            exercises: []
                                        )
                                        workoutTemplates.append(newTemplate)
                                    } label: {
                                        HStack {
                                            Image(systemName: "plus.circle.fill")
                                            Text("Add First Workout Day")
                                        }
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 24)
                                        .padding(.vertical, 14)
                                        .background(Color.gainsPrimary)
                                        .cornerRadius(12)
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 40)
                            } else {
                                ForEach(workoutTemplates.indices, id: \.self) { index in
                                    NavigationLink(destination: EditWorkoutTemplateView(
                                        template: Binding(
                                            get: { workoutTemplates[index] },
                                            set: { workoutTemplates[index] = $0 }
                                        )
                                    )) {
                                        HStack {
                                            if isReorderingDays {
                                                Image(systemName: "line.horizontal.3")
                                                    .foregroundColor(.gainsSecondaryText.opacity(0.5))
                                                    .font(.system(size: 16))
                                                    .padding(.leading, 8)
                                            }

                                            WorkoutDayPreviewCard(template: workoutTemplates[index])
                                                .padding(.leading, isReorderingDays ? -8 : 0)

                                            if isReorderingDays {
                                                Spacer()
                                            }
                                        }
                                    }
                                    .buttonStyle(.plain)
                                }
                                .onDelete(perform: isReorderingDays ? nil : { indices in
                                    workoutTemplates.remove(atOffsets: indices)
                                })
                                .onMove(perform: isReorderingDays ? { indices, newOffset in
                                    workoutTemplates.move(fromOffsets: indices, toOffset: newOffset)
                                    // Update day numbers after reordering
                                    for (index, _) in workoutTemplates.enumerated() {
                                        workoutTemplates[index].dayNumber = index + 1
                                    }
                                } : nil)

                                Button {
                                    let newTemplate = WorkoutTemplate(
                                        name: "Day \(workoutTemplates.count + 1)",
                                        dayNumber: workoutTemplates.count + 1,
                                        exercises: []
                                    )
                                    workoutTemplates.append(newTemplate)
                                } label: {
                                    HStack {
                                        Image(systemName: "plus.circle.fill")
                                            .font(.system(size: 20))
                                        Text("Add Workout Day")
                                            .font(.system(size: 16, weight: .semibold))
                                    }
                                    .foregroundColor(.gainsPrimary)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.gainsCardBackground)
                                    .cornerRadius(12)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.gainsPrimary.opacity(0.3), lineWidth: 1)
                                    )
                                }
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Create Plan")
            .navigationBarTitleDisplayMode(.inline)
            .environment(\.editMode, .constant(isReorderingDays ? EditMode.active : EditMode.inactive))
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack {
                        if workoutTemplates.count > 1 {
                            Button(isReorderingDays ? "Done" : "Reorder Days") {
                                withAnimation {
                                    isReorderingDays.toggle()
                                }
                            }
                            .font(.system(size: 14))
                        }

                        Button("Save") {
                            savePlan()
                        }
                        .disabled(planName.isEmpty || workoutTemplates.isEmpty || isSaving)
                    }
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
    @State private var isEditing = false

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
                        HStack {
                            if isEditing {
                                Image(systemName: "line.horizontal.3")
                                    .foregroundColor(.gainsSecondaryText.opacity(0.5))
                                    .font(.system(size: 14))
                            }
                            Text(template.exercises[index].name)
                            Spacer()
                            Text("\(template.exercises[index].targetSets) sets")
                                .font(.system(size: 14))
                                .foregroundColor(.gainsSecondaryText)
                        }
                    }
                }
                .onDelete(perform: isEditing ? { indices in
                    template.exercises.remove(atOffsets: indices)
                } : nil)
                .onMove(perform: isEditing ? { indices, newOffset in
                    template.exercises.move(fromOffsets: indices, toOffset: newOffset)
                } : nil)

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
        .environment(\.editMode, .constant(isEditing ? EditMode.active : EditMode.inactive))
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(isEditing ? "Done" : "Reorder") {
                    withAnimation {
                        isEditing.toggle()
                    }
                }
            }
        }
    }
}

struct WorkoutDayPreviewCard: View {
    let template: WorkoutTemplate

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(template.name)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.gainsText)

                    Text("\(template.exercises.count) exercise\(template.exercises.count == 1 ? "" : "s")")
                        .font(.system(size: 14))
                        .foregroundColor(.gainsSecondaryText)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(.gainsSecondaryText)
            }

            if !template.exercises.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(template.exercises.prefix(2)) { exercise in
                        HStack {
                            Text(exercise.name)
                                .font(.system(size: 14))
                                .foregroundColor(.gainsText)
                            Spacer()
                            Text("\(exercise.targetSets) × \(exercise.targetReps)")
                                .font(.system(size: 12))
                                .foregroundColor(.gainsSecondaryText)
                        }
                    }

                    if template.exercises.count > 2 {
                        Text("+\(template.exercises.count - 2) more exercise\(template.exercises.count - 2 == 1 ? "" : "s")")
                            .font(.system(size: 12))
                            .foregroundColor(.gainsSecondaryText)
                    }
                }
            } else {
                Text("No exercises added yet")
                    .font(.system(size: 14))
                    .foregroundColor(.gainsSecondaryText.opacity(0.7))
                    .italic()
            }

            if let notes = template.notes {
                Text(notes)
                    .font(.system(size: 12))
                    .foregroundColor(.gainsSecondaryText)
                    .italic()
                    .lineLimit(2)
            }
        }
        .padding()
        .background(Color.gainsCardBackground)
        .cornerRadius(12)
    }
}

struct EditPlannedExerciseView: View {
    @Binding var exercise: PlannedExercise
    @State private var isEditing = false

    var body: some View {
        Form {
            Section("Exercise Details") {
                TextField("Exercise Name", text: $exercise.name)
                TextField("Reps (e.g., 8-12)", text: $exercise.targetReps)
                Stepper("Rest: \(exercise.restSeconds ?? 90)s", value: Binding(
                    get: { exercise.restSeconds ?? 90 },
                    set: { exercise.restSeconds = $0 }
                ), in: 0...300, step: 15)
                TextField("Notes (Optional)", text: Binding(
                    get: { exercise.notes ?? "" },
                    set: { exercise.notes = $0.isEmpty ? nil : $0 }
                ), axis: .vertical)
                .lineLimit(3...6)
            }

            Section("Sets (\(exercise.targetSets))") {
                if exercise.targetSets > 0 {
                    ForEach(0..<exercise.targetSets, id: \.self) { setIndex in
                        HStack {
                            Text("Set \(setIndex + 1)")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.gainsText)
                            Spacer()
                            if isEditing && exercise.targetSets > 1 {
                                Button {
                                    removeSet(at: setIndex)
                                } label: {
                                    Image(systemName: "minus.circle.fill")
                                        .foregroundColor(.red)
                                        .font(.system(size: 20))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }

                if !isEditing {
                    Button {
                        withAnimation {
                            isEditing = true
                        }
                    } label: {
                        Label("Manage Sets", systemImage: "pencil")
                            .foregroundColor(.gainsPrimary)
                    }
                } else {
                    HStack {
                        Button {
                            addSet()
                        } label: {
                            Label("Add Set", systemImage: "plus.circle.fill")
                                .foregroundColor(.green)
                        }

                        Spacer()

                        Button {
                            withAnimation {
                                isEditing = false
                            }
                        } label: {
                            Text("Done")
                                .foregroundColor(.gainsPrimary)
                        }
                    }
                }
            }
        }
        .navigationTitle("Edit Exercise")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func addSet() {
        exercise.targetSets += 1
    }

    private func removeSet(at index: Int) {
        if exercise.targetSets > 1 {
            exercise.targetSets -= 1
            // Note: In a real implementation, you might want to track which set was removed
            // and reorder the remaining sets appropriately
        }
    }
}

#Preview {
    CreateWorkoutPlanView(planService: WorkoutPlanService())
}

