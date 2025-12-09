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
    @State private var showEquipmentSection = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Deep black background
                Color.gainsBgPrimary.ignoresSafeArea()
                
                if isGenerating {
                    loadingState
                } else if let plan = generatedPlan {
                    generatedPlanPreview(plan)
                } else {
                    generationForm
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Generate Plan")
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
                
                if generatedPlan == nil && !isGenerating {
                    ToolbarItem(placement: .navigationBarTrailing) {
                            Button {
                            generatePlan()
                            } label: {
                            Text("Generate")
                                .font(.system(size: GainsDesign.body, weight: .semibold))
                                    .foregroundColor(.gainsPrimary)
                        }
                    }
                }
            }
            .onAppear {
                loadProfileDefaults()
            }
        }
    }
    
    // MARK: - Loading State
    private var loadingState: some View {
        VStack(spacing: GainsDesign.spacingXXL) {
            // Animated loading indicator
            ZStack {
                Circle()
                    .stroke(Color.gainsTextMuted.opacity(0.2), lineWidth: 4)
                    .frame(width: 64, height: 64)
                
                Circle()
                    .trim(from: 0, to: 0.7)
                    .stroke(
                        LinearGradient(
                            colors: [Color.gainsPrimary, Color.gainsPrimaryLight],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        style: StrokeStyle(lineWidth: 4, lineCap: .round)
                    )
                    .frame(width: 64, height: 64)
                    .rotationEffect(.degrees(-90))
                    .animation(
                        Animation.linear(duration: 1).repeatForever(autoreverses: false),
                        value: isGenerating
                    )
            }
            
            VStack(spacing: GainsDesign.spacingS) {
                Text("Creating Your Plan")
                    .font(.system(size: GainsDesign.titleSmall, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                
                Text("AI is designing a personalized workout\nplan based on your preferences")
                    .font(.system(size: GainsDesign.callout))
                    .foregroundColor(.gainsTextSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            
            Text("This may take up to 30 seconds")
                .font(.system(size: GainsDesign.footnote))
                .foregroundColor(.gainsTextTertiary)
        }
        .padding(.horizontal, GainsDesign.paddingHorizontal)
    }
    
    // MARK: - Generation Form
    private var generationForm: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: GainsDesign.sectionSpacing) {
                // Plan Preferences Section
                formSection(title: "Plan Preferences") {
                    VStack(spacing: 0) {
                        // Goal
                        formRow(label: "Goal", isLast: false) {
                            Menu {
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
                                HStack(spacing: GainsDesign.spacingS) {
                                    Text(selectedGoal.rawValue)
                                        .font(.system(size: GainsDesign.body))
                                        .foregroundColor(.gainsTextSecondary)
                                    Image(systemName: "chevron.up.chevron.down")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(.gainsTextTertiary)
                                }
                            }
                        }
                        
                        // Experience Level
                        formRow(label: "Experience Level", isLast: false) {
                            Menu {
                                ForEach(TrainingExperience.allCases, id: \.self) { exp in
                                    Button {
                                        selectedExperience = exp
                                    } label: {
                                        HStack {
                                            Text(exp.rawValue)
                                            if selectedExperience == exp {
                                                Image(systemName: "checkmark")
                                            }
                                        }
                                    }
                                }
                            } label: {
                                HStack(spacing: GainsDesign.spacingS) {
                                    Text(selectedExperience.rawValue)
                                        .font(.system(size: GainsDesign.body))
                                        .foregroundColor(.gainsTextSecondary)
                                    Image(systemName: "chevron.up.chevron.down")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(.gainsTextTertiary)
                                }
                            }
                        }
                        
                        // Days per Week
                        formRow(label: "Days per week: \(daysPerWeek)", isLast: false) {
                            HStack(spacing: 0) {
                                Button {
                                    if daysPerWeek > 3 {
                                        daysPerWeek -= 1
                                    }
                                } label: {
                                    Image(systemName: "minus")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.gainsTextSecondary)
                                        .frame(width: 36, height: 32)
                                        .background(Color.gainsBgTertiary)
                                }
                                
                                Rectangle()
                                    .fill(Color.gainsSeparator)
                                    .frame(width: 0.5)
                                
                                Button {
                                    if daysPerWeek < 7 {
                                        daysPerWeek += 1
                                    }
                                } label: {
                                    Image(systemName: "plus")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.gainsTextSecondary)
                                        .frame(width: 36, height: 32)
                                        .background(Color.gainsBgTertiary)
                                }
                            }
                            .clipShape(RoundedRectangle(cornerRadius: GainsDesign.cornerRadiusXS))
                            .overlay(
                                RoundedRectangle(cornerRadius: GainsDesign.cornerRadiusXS)
                                    .stroke(Color.gainsSeparator, lineWidth: 0.5)
                            )
                        }
                        
                        // Training Split
                        formRow(label: "Training Split", isLast: true) {
                            Menu {
                                Button {
                                    selectedSplit = nil
                                } label: {
                                    HStack {
                                        Text("Let AI decide")
                                        if selectedSplit == nil {
                                            Image(systemName: "checkmark")
                                        }
                                    }
                                }
                                
                                Divider()
                                
                                ForEach(TrainingSplit.allCases, id: \.self) { split in
                                    Button {
                                        selectedSplit = split
                                    } label: {
                                        HStack {
                                            Text(split.rawValue)
                                            if selectedSplit == split {
                                                Image(systemName: "checkmark")
                                            }
                                        }
                                    }
                                }
                            } label: {
                                HStack(spacing: GainsDesign.spacingS) {
                                    Text(selectedSplit?.rawValue ?? "Let AI decide")
                                        .font(.system(size: GainsDesign.body))
                                        .foregroundColor(.gainsTextSecondary)
                                    Image(systemName: "chevron.up.chevron.down")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(.gainsTextTertiary)
                                }
                            }
                        }
                    }
                }
                
                // Equipment & Constraints Section (Collapsible)
                formSection(title: "Equipment & Constraints", isCollapsible: true, isExpanded: $showEquipmentSection) {
                    VStack(spacing: 0) {
                        // Equipment
                        VStack(alignment: .leading, spacing: GainsDesign.spacingS) {
                            Text("Available Equipment")
                                .font(.system(size: GainsDesign.subheadline))
                                .foregroundColor(.gainsTextSecondary)
                            
                            TextField("Dumbbells, barbell, cables...", text: Binding(
                                get: { equipment.joined(separator: ", ") },
                                set: { equipment = $0.isEmpty ? [] : $0.split(separator: ",").map { String($0).trimmingCharacters(in: .whitespaces) } }
                            ))
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
                        
                        // Constraints
                        VStack(alignment: .leading, spacing: GainsDesign.spacingS) {
                            Text("Constraints")
                                .font(.system(size: GainsDesign.subheadline))
                                .foregroundColor(.gainsTextSecondary)
                            
                            TextField("Injuries, time limits, etc.", text: $constraints, axis: .vertical)
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
                }
                
                // Error Message
                if let error = errorMessage {
                    HStack(spacing: GainsDesign.spacingS) {
                        Image(systemName: "exclamationmark.circle.fill")
                            .font(.system(size: 16))
                        Text(error)
                            .font(.system(size: GainsDesign.subheadline))
                    }
                    .foregroundColor(.gainsError)
                    .padding(GainsDesign.spacingL)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: GainsDesign.cornerRadiusMedium)
                            .fill(Color.gainsError.opacity(0.1))
                    )
                }
                
                // Generate Button (Bottom)
                Button {
                    generatePlan()
                } label: {
                    HStack(spacing: GainsDesign.spacingS) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 16, weight: .medium))
                        Text("Generate Workout Plan")
                            .font(.system(size: GainsDesign.body, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: GainsDesign.buttonHeightLarge)
                    .background(
                        RoundedRectangle(cornerRadius: GainsDesign.cornerRadiusMedium)
                            .fill(Color.gainsPrimary)
                    )
                    .shadow(color: Color.gainsPrimary.opacity(0.35), radius: 16, x: 0, y: 8)
                }
                .padding(.top, GainsDesign.spacingS)
            }
            .padding(.horizontal, GainsDesign.paddingHorizontal)
            .padding(.vertical, GainsDesign.spacingXL)
        }
    }
    
    // MARK: - Generated Plan Preview
    private func generatedPlanPreview(_ plan: WorkoutPlan) -> some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: GainsDesign.sectionSpacing) {
                // Success Header
                VStack(spacing: GainsDesign.spacingM) {
                    ZStack {
                        Circle()
                            .fill(Color.gainsSuccess.opacity(0.15))
                            .frame(width: 64, height: 64)
                        
                        Image(systemName: "checkmark")
                            .font(.system(size: 28, weight: .semibold))
                            .foregroundColor(.gainsSuccess)
                    }
                    
                    Text("Plan Generated!")
                        .font(.system(size: GainsDesign.titleSmall, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, GainsDesign.spacingL)
                
                // Plan Overview
                VStack(alignment: .leading, spacing: GainsDesign.spacingL) {
                    Text(plan.name)
                        .font(.system(size: GainsDesign.titleSmall, weight: .bold))
                        .foregroundColor(.white)
                    
                    if let description = plan.description {
                        Text(description)
                            .font(.system(size: GainsDesign.subheadline))
                            .foregroundColor(.gainsTextSecondary)
                            .lineSpacing(4)
                    }
                    
                    // Meta info
                    HStack(spacing: GainsDesign.spacingXL) {
                        Label("\(plan.daysPerWeek) days/week", systemImage: "calendar")
                        Label("\(plan.durationWeeks) weeks", systemImage: "clock")
                    }
                    .font(.system(size: GainsDesign.footnote))
                    .foregroundColor(.gainsTextTertiary)
                }
                .padding(GainsDesign.cardPadding)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: GainsDesign.cornerRadiusLarge)
                        .fill(Color.gainsCardSurface)
                )
                
                // Workout Days
                VStack(alignment: .leading, spacing: GainsDesign.spacingL) {
                    Text("Workout Schedule")
                        .font(.system(size: GainsDesign.headline, weight: .semibold))
                        .foregroundColor(.white)
                    
                    ForEach(plan.workoutTemplates.sorted(by: { $0.dayNumber < $1.dayNumber })) { template in
                        GeneratedPlanDayCard(template: template)
                    }
                }
                
                // Action Buttons
                VStack(spacing: GainsDesign.spacingM) {
                    Button {
                        savePlan(plan)
                    } label: {
                        Text("Save Plan")
                            .font(.system(size: GainsDesign.body, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: GainsDesign.buttonHeightLarge)
                            .background(
                                RoundedRectangle(cornerRadius: GainsDesign.cornerRadiusMedium)
                                    .fill(Color.gainsSuccess)
                            )
                            .shadow(color: Color.gainsSuccess.opacity(0.35), radius: 12, x: 0, y: 6)
                    }
                    
                        Button {
                        generatedPlan = nil
                        errorMessage = nil
                        } label: {
                        Text("Generate Another")
                            .font(.system(size: GainsDesign.body, weight: .medium))
                            .foregroundColor(.gainsTextSecondary)
                            .frame(maxWidth: .infinity)
                            .frame(height: GainsDesign.buttonHeightMedium)
                    }
                }
                .padding(.top, GainsDesign.spacingS)
            }
            .padding(.horizontal, GainsDesign.paddingHorizontal)
            .padding(.vertical, GainsDesign.spacingXL)
        }
    }
    
    // MARK: - Helper Views
    private func formSection<Content: View>(
        title: String,
        isCollapsible: Bool = false,
        isExpanded: Binding<Bool>? = nil,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: GainsDesign.spacingM) {
            if isCollapsible, let isExpanded = isExpanded {
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        isExpanded.wrappedValue.toggle()
                    }
                } label: {
                    HStack {
                        Text(title)
                            .font(.system(size: GainsDesign.footnote, weight: .medium))
                            .foregroundColor(.gainsTextTertiary)
                            .textCase(.uppercase)
                            .tracking(0.5)
                        
                        Spacer()
                        
                        Image(systemName: isExpanded.wrappedValue ? "chevron.up" : "chevron.down")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.gainsTextTertiary)
                    }
                }
            } else {
                Text(title)
                    .font(.system(size: GainsDesign.footnote, weight: .medium))
                    .foregroundColor(.gainsTextTertiary)
                    .textCase(.uppercase)
                    .tracking(0.5)
            }
            
            if !isCollapsible || (isExpanded?.wrappedValue ?? true) {
                VStack(spacing: 0) {
                    content()
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
    }
    
    private func formRow<Content: View>(
        label: String,
        isLast: Bool = false,
        @ViewBuilder trailing: () -> Content
    ) -> some View {
        VStack(spacing: 0) {
            HStack {
                Text(label)
                    .font(.system(size: GainsDesign.body))
                    .foregroundColor(.white)
                
                Spacer()
                
                trailing()
            }
            .padding(.horizontal, GainsDesign.spacingL)
            .padding(.vertical, GainsDesign.spacingM + 2)
            
            if !isLast {
                Rectangle()
                    .fill(Color.gainsSeparator)
                    .frame(height: 0.5)
                    .padding(.leading, GainsDesign.spacingL)
            }
        }
    }
    
    // MARK: - Actions
    private func loadProfileDefaults() {
                Task {
                    await profileViewModel.loadProfile()
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

// MARK: - Generated Plan Day Card (For Preview)
struct GeneratedPlanDayCard: View {
    let template: WorkoutTemplate
    
    var body: some View {
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
                        .font(.system(size: GainsDesign.body, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Text("\(template.exercises.count) exercise\(template.exercises.count == 1 ? "" : "s")")
                        .font(.system(size: GainsDesign.footnote))
                        .foregroundColor(.gainsTextSecondary)
                }
                
                Spacer()
            }
            
            // Exercise list preview
            if !template.exercises.isEmpty {
                VStack(alignment: .leading, spacing: GainsDesign.spacingS) {
                    ForEach(template.exercises.prefix(3)) { exercise in
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
                    
                    if template.exercises.count > 3 {
                        Text("+\(template.exercises.count - 3) more")
                            .font(.system(size: GainsDesign.caption))
                            .foregroundColor(.gainsTextTertiary)
                            .padding(.leading, GainsDesign.spacingM)
                    }
                }
                .padding(.leading, GainsDesign.spacingXS)
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

#Preview {
    GeneratePlanView(planService: WorkoutPlanService())
}
