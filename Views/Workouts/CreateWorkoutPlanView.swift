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
                Color.gainsBgPrimary.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: GainsDesign.sectionSpacing) {
                        // Plan Details Section
                        planDetailsSection
                        
                        // Schedule Section
                        scheduleSection

                        // Workout Days Section
                        workoutDaysSection
                    }
                    .padding(.horizontal, GainsDesign.paddingHorizontal)
                    .padding(.vertical, GainsDesign.spacingXL)
                    .padding(.bottom, 40)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Create Plan")
                        .font(.system(size: GainsDesign.headline, weight: .semibold))
                        .foregroundColor(.white)
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Text("Cancel")
                            .font(.system(size: GainsDesign.body))
                            .foregroundColor(.gainsTextSecondary)
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: GainsDesign.spacingL) {
                        if workoutTemplates.count > 1 {
                            Button {
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                    isReorderingDays.toggle()
                                }
                            } label: {
                                Text(isReorderingDays ? "Done" : "Reorder")
                                    .font(.system(size: GainsDesign.subheadline))
                                    .foregroundColor(.gainsTextSecondary)
                            }
                        }

                        Button {
                            savePlan()
                        } label: {
                            Text("Save")
                                .font(.system(size: GainsDesign.body, weight: .semibold))
                                .foregroundColor(canSave ? .gainsPrimary : .gainsTextMuted)
                        }
                        .disabled(!canSave || isSaving)
                    }
                }
            }
            .environment(\.editMode, .constant(isReorderingDays ? EditMode.active : EditMode.inactive))
        }
    }
    
    private var canSave: Bool {
        !planName.isEmpty && !workoutTemplates.isEmpty
    }
    
    // MARK: - Plan Details Section
    private var planDetailsSection: some View {
        VStack(alignment: .leading, spacing: GainsDesign.spacingM) {
            Text("PLAN DETAILS")
                .font(.system(size: GainsDesign.footnote, weight: .medium))
                .foregroundColor(.gainsTextTertiary)
                .tracking(0.5)
            
            VStack(spacing: 0) {
                // Plan Name
                VStack(alignment: .leading, spacing: GainsDesign.spacingS) {
                    Text("Plan Name")
                        .font(.system(size: GainsDesign.subheadline))
                        .foregroundColor(.gainsTextSecondary)
                    
                    TextField("e.g., Push Pull Legs", text: $planName)
                        .textFieldStyle(.plain)
                        .font(.system(size: GainsDesign.body))
                        .foregroundColor(.white)
                        .padding(.horizontal, GainsDesign.spacingL)
                        .padding(.vertical, GainsDesign.spacingM)
                        .background(
                            RoundedRectangle(cornerRadius: GainsDesign.cornerRadiusSmall)
                                .fill(Color.gainsBgTertiary)
                        )
                }
                .padding(GainsDesign.spacingL)
                
                Rectangle()
                    .fill(Color.gainsSeparator)
                    .frame(height: 0.5)
                    .padding(.leading, GainsDesign.spacingL)
                
                // Description
                VStack(alignment: .leading, spacing: GainsDesign.spacingS) {
                    Text("Description (Optional)")
                        .font(.system(size: GainsDesign.subheadline))
                        .foregroundColor(.gainsTextSecondary)
                    
                    TextField("Describe your workout plan", text: $description, axis: .vertical)
                        .textFieldStyle(.plain)
                        .font(.system(size: GainsDesign.body))
                        .foregroundColor(.white)
                        .lineLimit(2...4)
                        .padding(.horizontal, GainsDesign.spacingL)
                        .padding(.vertical, GainsDesign.spacingM)
                        .background(
                            RoundedRectangle(cornerRadius: GainsDesign.cornerRadiusSmall)
                                .fill(Color.gainsBgTertiary)
                        )
                }
                .padding(GainsDesign.spacingL)
                
                Rectangle()
                    .fill(Color.gainsSeparator)
                    .frame(height: 0.5)
                    .padding(.leading, GainsDesign.spacingL)
                
                // Goal & Difficulty Row
                HStack(spacing: GainsDesign.spacingL) {
                    // Goal
                    VStack(alignment: .leading, spacing: GainsDesign.spacingS) {
                        Text("Goal")
                            .font(.system(size: GainsDesign.subheadline))
                            .foregroundColor(.gainsTextSecondary)
                        
                        Menu {
                            Button {
                                selectedGoal = nil
                            } label: {
                                HStack {
                                    Text("None")
                                    if selectedGoal == nil {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                            
                            Divider()
                            
                            ForEach(FitnessGoal.allCases, id: \.self) { goal in
                                Button {
                                    selectedGoal = goal
                                } label: {
                                    HStack {
                                        Text(goal.rawValue)
                                        if selectedGoal == goal {
                                            Image(systemName: "checkmark")
                                        }
                                    }
                                }
                            }
                        } label: {
                            HStack {
                                Text(selectedGoal?.rawValue ?? "None")
                                    .font(.system(size: GainsDesign.body))
                                    .foregroundColor(.white)
                                Spacer()
                                Image(systemName: "chevron.up.chevron.down")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.gainsTextTertiary)
                            }
                            .padding(.horizontal, GainsDesign.spacingL)
                            .padding(.vertical, GainsDesign.spacingM)
                            .background(
                                RoundedRectangle(cornerRadius: GainsDesign.cornerRadiusSmall)
                                    .fill(Color.gainsBgTertiary)
                            )
                        }
                    }
                    
                    // Difficulty
                    VStack(alignment: .leading, spacing: GainsDesign.spacingS) {
                        Text("Difficulty")
                            .font(.system(size: GainsDesign.subheadline))
                            .foregroundColor(.gainsTextSecondary)
                        
                        Menu {
                            ForEach(PlanDifficulty.allCases, id: \.self) { diff in
                                Button {
                                    selectedDifficulty = diff
                                } label: {
                                    HStack {
                                        Text(diff.rawValue)
                                        if selectedDifficulty == diff {
                                            Image(systemName: "checkmark")
                                        }
                                    }
                                }
                            }
                        } label: {
                            HStack {
                                Text(selectedDifficulty.rawValue)
                                    .font(.system(size: GainsDesign.body))
                                    .foregroundColor(.white)
                                Spacer()
                                Image(systemName: "chevron.up.chevron.down")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.gainsTextTertiary)
                            }
                            .padding(.horizontal, GainsDesign.spacingL)
                            .padding(.vertical, GainsDesign.spacingM)
                            .background(
                                RoundedRectangle(cornerRadius: GainsDesign.cornerRadiusSmall)
                                    .fill(Color.gainsBgTertiary)
                            )
                        }
                    }
                }
                .padding(GainsDesign.spacingL)
            }
            .background(
                RoundedRectangle(cornerRadius: GainsDesign.cornerRadiusMedium)
                    .fill(Color.gainsCardSurface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: GainsDesign.cornerRadiusMedium)
                    .stroke(Color.white.opacity(0.04), lineWidth: 0.5)
            )
        }
    }
    
    // MARK: - Schedule Section
    private var scheduleSection: some View {
        VStack(alignment: .leading, spacing: GainsDesign.spacingM) {
            Text("SCHEDULE")
                .font(.system(size: GainsDesign.footnote, weight: .medium))
                .foregroundColor(.gainsTextTertiary)
                .tracking(0.5)
            
            HStack(spacing: GainsDesign.spacingL) {
                // Duration
                VStack(alignment: .leading, spacing: GainsDesign.spacingS) {
                    Text("Duration")
                        .font(.system(size: GainsDesign.subheadline))
                        .foregroundColor(.gainsTextSecondary)
                    
                    HStack(spacing: 0) {
                        Button {
                            if durationWeeks > 1 { durationWeeks -= 1 }
                        } label: {
                            Image(systemName: "minus")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.gainsTextSecondary)
                                .frame(width: 40, height: 44)
                                .background(Color.gainsBgTertiary)
                        }
                        
                        Text("\(durationWeeks) weeks")
                            .font(.system(size: GainsDesign.body, weight: .medium))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .background(Color.gainsCardSurface)
                        
                        Button {
                            if durationWeeks < 12 { durationWeeks += 1 }
                        } label: {
                            Image(systemName: "plus")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.gainsTextSecondary)
                                .frame(width: 40, height: 44)
                                .background(Color.gainsBgTertiary)
                        }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: GainsDesign.cornerRadiusSmall))
                    .overlay(
                        RoundedRectangle(cornerRadius: GainsDesign.cornerRadiusSmall)
                            .stroke(Color.gainsSeparator, lineWidth: 0.5)
                    )
                }
                
                // Days per Week
                VStack(alignment: .leading, spacing: GainsDesign.spacingS) {
                    Text("Days per Week")
                        .font(.system(size: GainsDesign.subheadline))
                        .foregroundColor(.gainsTextSecondary)
                    
                    HStack(spacing: 0) {
                        Button {
                            if daysPerWeek > 3 { daysPerWeek -= 1 }
                        } label: {
                            Image(systemName: "minus")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.gainsTextSecondary)
                                .frame(width: 40, height: 44)
                                .background(Color.gainsBgTertiary)
                        }
                        
                        Text("\(daysPerWeek) days")
                            .font(.system(size: GainsDesign.body, weight: .medium))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .background(Color.gainsCardSurface)
                        
                        Button {
                            if daysPerWeek < 7 { daysPerWeek += 1 }
                        } label: {
                            Image(systemName: "plus")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.gainsTextSecondary)
                                .frame(width: 40, height: 44)
                                .background(Color.gainsBgTertiary)
                        }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: GainsDesign.cornerRadiusSmall))
                    .overlay(
                        RoundedRectangle(cornerRadius: GainsDesign.cornerRadiusSmall)
                            .stroke(Color.gainsSeparator, lineWidth: 0.5)
                    )
                }
            }
        }
    }

    // MARK: - Workout Days Section
    private var workoutDaysSection: some View {
        VStack(alignment: .leading, spacing: GainsDesign.spacingM) {
            HStack {
                Text("WORKOUT DAYS")
                    .font(.system(size: GainsDesign.footnote, weight: .medium))
                    .foregroundColor(.gainsTextTertiary)
                    .tracking(0.5)

                Spacer()

                Text("\(workoutTemplates.count) day\(workoutTemplates.count == 1 ? "" : "s")")
                    .font(.system(size: GainsDesign.footnote))
                    .foregroundColor(.gainsTextSecondary)
            }

            if workoutTemplates.isEmpty {
                // Empty State
                VStack(spacing: GainsDesign.spacingXL) {
                    ZStack {
                        Circle()
                            .fill(Color.gainsBgTertiary)
                            .frame(width: 72, height: 72)
                        
                        Image(systemName: "calendar.badge.plus")
                            .font(.system(size: 32, weight: .light))
                            .foregroundColor(.gainsTextTertiary)
                    }

                    VStack(spacing: GainsDesign.spacingS) {
                        Text("No workout days yet")
                            .font(.system(size: GainsDesign.body, weight: .medium))
                            .foregroundColor(.white)
                        
                        Text("Add days to build your weekly schedule")
                            .font(.system(size: GainsDesign.subheadline))
                            .foregroundColor(.gainsTextSecondary)
                    }

                    Button {
                        addWorkoutDay()
                    } label: {
                        HStack(spacing: GainsDesign.spacingS) {
                            Image(systemName: "plus")
                                .font(.system(size: 14, weight: .semibold))
                            Text("Add First Workout Day")
                                .font(.system(size: GainsDesign.body, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .frame(height: GainsDesign.buttonHeightMedium)
                        .background(
                            RoundedRectangle(cornerRadius: GainsDesign.cornerRadiusMedium)
                                .fill(Color.gainsPrimary)
                        )
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 48)
                .background(
                    RoundedRectangle(cornerRadius: GainsDesign.cornerRadiusMedium)
                        .fill(Color.gainsCardSurface)
                )
            } else {
                VStack(spacing: GainsDesign.spacingM) {
                    ForEach(workoutTemplates.indices, id: \.self) { index in
                        NavigationLink(destination: EditWorkoutTemplateView(
                            template: Binding(
                                get: { workoutTemplates[index] },
                                set: { workoutTemplates[index] = $0 }
                            )
                        )) {
                            WorkoutDayPreviewCard(
                                template: workoutTemplates[index],
                                isReordering: isReorderingDays,
                                onDelete: {
                                    withAnimation(.easeOut(duration: 0.2)) {
                                        workoutTemplates.remove(at: index)
                                        updateDayNumbers()
                                    }
                                }
                            )
                        }
                        .buttonStyle(.plain)
                    }
                    .onMove(perform: isReorderingDays ? { indices, newOffset in
                        workoutTemplates.move(fromOffsets: indices, toOffset: newOffset)
                        updateDayNumbers()
                    } : nil)

                    // Add Day Button
                    Button {
                        addWorkoutDay()
                    } label: {
                        HStack(spacing: GainsDesign.spacingS) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 18))
                            Text("Add Workout Day")
                                .font(.system(size: GainsDesign.body, weight: .semibold))
                        }
                        .foregroundColor(.gainsPrimary)
                        .frame(maxWidth: .infinity)
                        .frame(height: GainsDesign.buttonHeightLarge)
                        .background(
                            RoundedRectangle(cornerRadius: GainsDesign.cornerRadiusMedium)
                                .fill(Color.gainsCardSurface)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: GainsDesign.cornerRadiusMedium)
                                .stroke(Color.gainsPrimary.opacity(0.25), style: StrokeStyle(lineWidth: 1.5, dash: [8, 4]))
                        )
                    }
                }
            }
        }
    }
    
    // MARK: - Actions
    private func addWorkoutDay() {
        let newTemplate = WorkoutTemplate(
            name: "Day \(workoutTemplates.count + 1)",
            dayNumber: workoutTemplates.count + 1,
            exercises: []
        )
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            workoutTemplates.append(newTemplate)
        }
    }
    
    private func updateDayNumbers() {
        for (index, _) in workoutTemplates.enumerated() {
            workoutTemplates[index].dayNumber = index + 1
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

// MARK: - Workout Day Preview Card
struct WorkoutDayPreviewCard: View {
    let template: WorkoutTemplate
    var isReordering: Bool = false
    var onDelete: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: GainsDesign.spacingM) {
            if isReordering {
                Image(systemName: "line.horizontal.3")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.gainsTextMuted)
            }
            
            VStack(alignment: .leading, spacing: GainsDesign.spacingM) {
                HStack {
                    // Day indicator
                    ZStack {
                        Circle()
                            .fill(Color.gainsPrimary.opacity(0.15))
                            .frame(width: 36, height: 36)
                        
                        Text("\(template.dayNumber)")
                            .font(.system(size: GainsDesign.subheadline, weight: .bold))
                            .foregroundColor(.gainsPrimary)
                    }
                    
                    VStack(alignment: .leading, spacing: GainsDesign.spacingXXS) {
                        Text(template.name)
                            .font(.system(size: GainsDesign.headline, weight: .semibold))
                            .foregroundColor(.white)

                        Text("\(template.exercises.count) exercise\(template.exercises.count == 1 ? "" : "s")")
                            .font(.system(size: GainsDesign.footnote))
                            .foregroundColor(.gainsTextSecondary)
                    }

                    Spacer()

                    if !isReordering {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.gainsTextTertiary)
                    }
                }

                if !template.exercises.isEmpty && !isReordering {
                    VStack(alignment: .leading, spacing: GainsDesign.spacingXS) {
                        ForEach(template.exercises.prefix(2)) { exercise in
                            HStack {
                                Circle()
                                    .fill(Color.gainsTextMuted)
                                    .frame(width: 4, height: 4)
                                
                                Text(exercise.name)
                                    .font(.system(size: GainsDesign.footnote))
                                    .foregroundColor(.gainsTextSecondary)
                                
                                Spacer()
                                
                                Text("\(exercise.targetSets) × \(exercise.targetReps)")
                                    .font(.system(size: GainsDesign.caption))
                                    .foregroundColor(.gainsTextTertiary)
                            }
                        }

                        if template.exercises.count > 2 {
                            Text("+\(template.exercises.count - 2) more")
                                .font(.system(size: GainsDesign.caption))
                                .foregroundColor(.gainsTextTertiary)
                                .padding(.leading, GainsDesign.spacingM)
                        }
                    }
                }

                if let notes = template.notes, !isReordering {
                    Text(notes)
                        .font(.system(size: GainsDesign.caption))
                        .foregroundColor(.gainsTextTertiary)
                        .italic()
                        .lineLimit(2)
                }
            }
        }
        .padding(GainsDesign.spacingL)
        .background(
            RoundedRectangle(cornerRadius: GainsDesign.cornerRadiusMedium)
                .fill(Color.gainsCardSurface)
        )
        .overlay(
            RoundedRectangle(cornerRadius: GainsDesign.cornerRadiusMedium)
                .stroke(Color.white.opacity(0.04), lineWidth: 0.5)
        )
    }
}

// MARK: - Edit Workout Template View
struct EditWorkoutTemplateView: View {
    @Binding var template: WorkoutTemplate
    @Environment(\.dismiss) var dismiss
    @State private var isEditing = false

    var body: some View {
        ZStack {
            Color.gainsBgPrimary.ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: GainsDesign.sectionSpacing) {
                    // Day Details Section
                    VStack(alignment: .leading, spacing: GainsDesign.spacingM) {
                        Text("DAY DETAILS")
                            .font(.system(size: GainsDesign.footnote, weight: .medium))
                            .foregroundColor(.gainsTextTertiary)
                            .tracking(0.5)
                        
                        VStack(spacing: 0) {
                            // Day Name
                            VStack(alignment: .leading, spacing: GainsDesign.spacingS) {
                                Text("Day Name")
                                    .font(.system(size: GainsDesign.subheadline))
                                    .foregroundColor(.gainsTextSecondary)
                                
                                TextField("e.g., Push Day", text: $template.name)
                                    .textFieldStyle(.plain)
                                    .font(.system(size: GainsDesign.body))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, GainsDesign.spacingL)
                                    .padding(.vertical, GainsDesign.spacingM)
                                    .background(
                                        RoundedRectangle(cornerRadius: GainsDesign.cornerRadiusSmall)
                                            .fill(Color.gainsBgTertiary)
                                    )
                            }
                            .padding(GainsDesign.spacingL)
                            
                            Rectangle()
                                .fill(Color.gainsSeparator)
                                .frame(height: 0.5)
                                .padding(.leading, GainsDesign.spacingL)
                            
                            // Notes
                            VStack(alignment: .leading, spacing: GainsDesign.spacingS) {
                                Text("Notes (Optional)")
                                    .font(.system(size: GainsDesign.subheadline))
                                    .foregroundColor(.gainsTextSecondary)
                                
                                TextField("Add any notes for this day", text: Binding(
                                    get: { template.notes ?? "" },
                                    set: { template.notes = $0.isEmpty ? nil : $0 }
                                ), axis: .vertical)
                                .textFieldStyle(.plain)
                                .font(.system(size: GainsDesign.body))
                                .foregroundColor(.white)
                                .lineLimit(2...4)
                                .padding(.horizontal, GainsDesign.spacingL)
                                .padding(.vertical, GainsDesign.spacingM)
                                .background(
                                    RoundedRectangle(cornerRadius: GainsDesign.cornerRadiusSmall)
                                        .fill(Color.gainsBgTertiary)
                                )
                            }
                            .padding(GainsDesign.spacingL)
                        }
                        .background(
                            RoundedRectangle(cornerRadius: GainsDesign.cornerRadiusMedium)
                                .fill(Color.gainsCardSurface)
                        )
                    }
                    
                    // Exercises Section
                    VStack(alignment: .leading, spacing: GainsDesign.spacingM) {
                        HStack {
                            Text("EXERCISES")
                                .font(.system(size: GainsDesign.footnote, weight: .medium))
                                .foregroundColor(.gainsTextTertiary)
                                .tracking(0.5)
                            
                            Spacer()
                            
                            Text("\(template.exercises.count) exercise\(template.exercises.count == 1 ? "" : "s")")
                                .font(.system(size: GainsDesign.footnote))
                                .foregroundColor(.gainsTextSecondary)
                        }
                        
                        if template.exercises.isEmpty {
                            VStack(spacing: GainsDesign.spacingL) {
                                Image(systemName: "dumbbell")
                                    .font(.system(size: 32, weight: .light))
                                    .foregroundColor(.gainsTextTertiary)
                                
                                Text("No exercises added")
                                    .font(.system(size: GainsDesign.body))
                                    .foregroundColor(.gainsTextSecondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 40)
                            .background(
                                RoundedRectangle(cornerRadius: GainsDesign.cornerRadiusMedium)
                                    .fill(Color.gainsCardSurface)
                            )
                        } else {
                            VStack(spacing: GainsDesign.spacingS) {
                                ForEach(template.exercises.indices, id: \.self) { index in
                                    NavigationLink(destination: EditPlannedExerciseView(
                                        exercise: Binding(
                                            get: { template.exercises[index] },
                                            set: { template.exercises[index] = $0 }
                                        )
                                    )) {
                                        HStack(spacing: GainsDesign.spacingM) {
                                            if isEditing {
                                                Image(systemName: "line.horizontal.3")
                                                    .font(.system(size: 14))
                                                    .foregroundColor(.gainsTextMuted)
                                            }
                                            
                                            Text(template.exercises[index].name)
                                                .font(.system(size: GainsDesign.body))
                                                .foregroundColor(.white)
                                            
                                            Spacer()
                                            
                                            Text("\(template.exercises[index].targetSets) sets")
                                                .font(.system(size: GainsDesign.subheadline))
                                                .foregroundColor(.gainsTextSecondary)
                                            
                                            Image(systemName: "chevron.right")
                                                .font(.system(size: 13, weight: .medium))
                                                .foregroundColor(.gainsTextTertiary)
                                        }
                                        .padding(GainsDesign.spacingL)
                                        .background(
                                            RoundedRectangle(cornerRadius: GainsDesign.cornerRadiusMedium)
                                                .fill(Color.gainsCardSurface)
                                        )
                                    }
                                }
                                .onDelete(perform: isEditing ? { indices in
                                    template.exercises.remove(atOffsets: indices)
                                } : nil)
                                .onMove(perform: isEditing ? { indices, newOffset in
                                    template.exercises.move(fromOffsets: indices, toOffset: newOffset)
                                } : nil)
                            }
                        }
                        
                        // Add Exercise Button
                        Button {
                            let newExercise = PlannedExercise(name: "New Exercise")
                            template.exercises.append(newExercise)
                        } label: {
                            HStack(spacing: GainsDesign.spacingS) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 18))
                                Text("Add Exercise")
                                    .font(.system(size: GainsDesign.body, weight: .semibold))
                            }
                            .foregroundColor(.gainsPrimary)
                            .frame(maxWidth: .infinity)
                            .frame(height: GainsDesign.buttonHeightMedium)
                            .background(
                                RoundedRectangle(cornerRadius: GainsDesign.cornerRadiusMedium)
                                    .fill(Color.gainsCardSurface)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: GainsDesign.cornerRadiusMedium)
                                    .stroke(Color.gainsPrimary.opacity(0.3), lineWidth: 1)
                            )
                        }
                    }
                }
                .padding(.horizontal, GainsDesign.paddingHorizontal)
                .padding(.vertical, GainsDesign.spacingXL)
            }
        }
        .navigationTitle("Edit Day")
        .navigationBarTitleDisplayMode(.inline)
        .environment(\.editMode, .constant(isEditing ? EditMode.active : EditMode.inactive))
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if !template.exercises.isEmpty {
                    Button {
                        withAnimation {
                            isEditing.toggle()
                        }
                    } label: {
                        Text(isEditing ? "Done" : "Reorder")
                            .font(.system(size: GainsDesign.body))
                            .foregroundColor(.gainsPrimary)
                    }
                }
            }
        }
    }
}

// MARK: - Edit Planned Exercise View
struct EditPlannedExerciseView: View {
    @Binding var exercise: PlannedExercise
    @State private var isEditing = false

    var body: some View {
        ZStack {
            Color.gainsBgPrimary.ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: GainsDesign.sectionSpacing) {
                    // Exercise Details Section
                    VStack(alignment: .leading, spacing: GainsDesign.spacingM) {
                        Text("EXERCISE DETAILS")
                            .font(.system(size: GainsDesign.footnote, weight: .medium))
                            .foregroundColor(.gainsTextTertiary)
                            .tracking(0.5)
                        
                        VStack(spacing: 0) {
                            // Exercise Name
                            VStack(alignment: .leading, spacing: GainsDesign.spacingS) {
                                Text("Exercise Name")
                                    .font(.system(size: GainsDesign.subheadline))
                                    .foregroundColor(.gainsTextSecondary)
                                
                                TextField("e.g., Bench Press", text: $exercise.name)
                                    .textFieldStyle(.plain)
                                    .font(.system(size: GainsDesign.body))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, GainsDesign.spacingL)
                                    .padding(.vertical, GainsDesign.spacingM)
                                    .background(
                                        RoundedRectangle(cornerRadius: GainsDesign.cornerRadiusSmall)
                                            .fill(Color.gainsBgTertiary)
                                    )
                            }
                            .padding(GainsDesign.spacingL)
                            
                            Rectangle()
                                .fill(Color.gainsSeparator)
                                .frame(height: 0.5)
                                .padding(.leading, GainsDesign.spacingL)
                            
                            // Target Reps
                            VStack(alignment: .leading, spacing: GainsDesign.spacingS) {
                                Text("Target Reps")
                                    .font(.system(size: GainsDesign.subheadline))
                                    .foregroundColor(.gainsTextSecondary)
                                
                                TextField("e.g., 8-12", text: $exercise.targetReps)
                                    .textFieldStyle(.plain)
                                    .font(.system(size: GainsDesign.body))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, GainsDesign.spacingL)
                                    .padding(.vertical, GainsDesign.spacingM)
                                    .background(
                                        RoundedRectangle(cornerRadius: GainsDesign.cornerRadiusSmall)
                                            .fill(Color.gainsBgTertiary)
                                    )
                            }
                            .padding(GainsDesign.spacingL)
                            
                            Rectangle()
                                .fill(Color.gainsSeparator)
                                .frame(height: 0.5)
                                .padding(.leading, GainsDesign.spacingL)
                            
                            // Rest Time
                            HStack {
                                Text("Rest Time")
                                    .font(.system(size: GainsDesign.body))
                                    .foregroundColor(.white)
                                
                                Spacer()
                                
                                HStack(spacing: 0) {
                                    Button {
                                        let current = exercise.restSeconds ?? 90
                                        if current > 15 {
                                            exercise.restSeconds = current - 15
                                        }
                                    } label: {
                                        Image(systemName: "minus")
                                            .font(.system(size: 12, weight: .medium))
                                            .foregroundColor(.gainsTextSecondary)
                                            .frame(width: 32, height: 32)
                                            .background(Color.gainsBgTertiary)
                                    }
                                    
                                    Text("\(exercise.restSeconds ?? 90)s")
                                        .font(.system(size: GainsDesign.body, weight: .medium))
                                        .foregroundColor(.white)
                                        .frame(width: 56)
                                    
                                    Button {
                                        let current = exercise.restSeconds ?? 90
                                        if current < 300 {
                                            exercise.restSeconds = current + 15
                                        }
                                    } label: {
                                        Image(systemName: "plus")
                                            .font(.system(size: 12, weight: .medium))
                                            .foregroundColor(.gainsTextSecondary)
                                            .frame(width: 32, height: 32)
                                            .background(Color.gainsBgTertiary)
                                    }
                                }
                                .clipShape(RoundedRectangle(cornerRadius: GainsDesign.cornerRadiusXS))
                                .overlay(
                                    RoundedRectangle(cornerRadius: GainsDesign.cornerRadiusXS)
                                        .stroke(Color.gainsSeparator, lineWidth: 0.5)
                                )
                            }
                            .padding(GainsDesign.spacingL)
                            
                            Rectangle()
                                .fill(Color.gainsSeparator)
                                .frame(height: 0.5)
                                .padding(.leading, GainsDesign.spacingL)
                            
                            // Notes
                            VStack(alignment: .leading, spacing: GainsDesign.spacingS) {
                                Text("Notes (Optional)")
                                    .font(.system(size: GainsDesign.subheadline))
                                    .foregroundColor(.gainsTextSecondary)
                                
                                TextField("Form cues, tips, etc.", text: Binding(
                                    get: { exercise.notes ?? "" },
                                    set: { exercise.notes = $0.isEmpty ? nil : $0 }
                                ), axis: .vertical)
                                .textFieldStyle(.plain)
                                .font(.system(size: GainsDesign.body))
                                .foregroundColor(.white)
                                .lineLimit(2...4)
                                .padding(.horizontal, GainsDesign.spacingL)
                                .padding(.vertical, GainsDesign.spacingM)
                                .background(
                                    RoundedRectangle(cornerRadius: GainsDesign.cornerRadiusSmall)
                                        .fill(Color.gainsBgTertiary)
                                )
                            }
                            .padding(GainsDesign.spacingL)
                        }
                        .background(
                            RoundedRectangle(cornerRadius: GainsDesign.cornerRadiusMedium)
                                .fill(Color.gainsCardSurface)
                        )
                    }
                    
                    // Sets Section
                    VStack(alignment: .leading, spacing: GainsDesign.spacingM) {
                        HStack {
                            Text("SETS")
                                .font(.system(size: GainsDesign.footnote, weight: .medium))
                                .foregroundColor(.gainsTextTertiary)
                                .tracking(0.5)
                            
                            Spacer()
                            
                            Text("\(exercise.targetSets) set\(exercise.targetSets == 1 ? "" : "s")")
                                .font(.system(size: GainsDesign.footnote))
                                .foregroundColor(.gainsTextSecondary)
                        }
                        
                        VStack(spacing: 0) {
                            ForEach(0..<exercise.targetSets, id: \.self) { setIndex in
                                HStack {
                                    Text("Set \(setIndex + 1)")
                                        .font(.system(size: GainsDesign.body, weight: .medium))
                                        .foregroundColor(.white)
                                    
                                    Spacer()
                                    
                                    if isEditing && exercise.targetSets > 1 {
                                        Button {
                                            withAnimation {
                                                exercise.targetSets -= 1
                                            }
                                        } label: {
                                            Image(systemName: "minus.circle.fill")
                                                .font(.system(size: 22))
                                                .foregroundColor(.gainsError.opacity(0.8))
                                        }
                                    }
                                }
                                .padding(GainsDesign.spacingL)
                                
                                if setIndex < exercise.targetSets - 1 {
                                    Rectangle()
                                        .fill(Color.gainsSeparator)
                                        .frame(height: 0.5)
                                        .padding(.leading, GainsDesign.spacingL)
                                }
                            }
                        }
                        .background(
                            RoundedRectangle(cornerRadius: GainsDesign.cornerRadiusMedium)
                                .fill(Color.gainsCardSurface)
                        )
                        
                        // Add/Edit Sets Buttons
                        HStack(spacing: GainsDesign.spacingM) {
                            Button {
                                withAnimation {
                                    exercise.targetSets += 1
                                }
                            } label: {
                                HStack(spacing: GainsDesign.spacingS) {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.system(size: 16))
                                    Text("Add Set")
                                        .font(.system(size: GainsDesign.subheadline, weight: .semibold))
                                }
                                .foregroundColor(.gainsSuccess)
                                .frame(maxWidth: .infinity)
                                .frame(height: GainsDesign.buttonHeightMedium)
                                .background(
                                    RoundedRectangle(cornerRadius: GainsDesign.cornerRadiusSmall)
                                        .fill(Color.gainsCardSurface)
                                )
                            }
                            
                            Button {
                                withAnimation {
                                    isEditing.toggle()
                                }
                            } label: {
                                Text(isEditing ? "Done" : "Manage")
                                    .font(.system(size: GainsDesign.subheadline, weight: .semibold))
                                    .foregroundColor(.gainsPrimary)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: GainsDesign.buttonHeightMedium)
                                    .background(
                                        RoundedRectangle(cornerRadius: GainsDesign.cornerRadiusSmall)
                                            .fill(Color.gainsCardSurface)
                                    )
                            }
                        }
                    }
                }
                .padding(.horizontal, GainsDesign.paddingHorizontal)
                .padding(.vertical, GainsDesign.spacingXL)
            }
        }
        .navigationTitle("Edit Exercise")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    CreateWorkoutPlanView(planService: WorkoutPlanService())
}
