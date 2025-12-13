//
//  StartWorkoutSheet.swift
//  Gains
//
//  Premium workout entry flow - Apple Maps style sheet
//  Allows starting from plan or new workout
//

import SwiftUI

struct StartWorkoutSheet: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var workoutManager = ActiveWorkoutManager.shared
    @StateObject private var planService = WorkoutPlanService()
    
    @State private var showNewWorkoutInput = false
    @State private var newWorkoutName = ""
    @State private var selectedTemplate: WorkoutTemplate?
    @FocusState private var isInputFocused: Bool
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                Color.gainsAppBackground.ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: GainsDesign.spacingXXL) {
                        // Header Icon
                        headerIcon
                        
                        // From Plan Section
                        if let activePlan = planService.activePlan, !activePlan.workoutTemplates.isEmpty {
                            fromPlanSection(plan: activePlan)
                        }
                        
                        // Quick Start Options
                        quickStartSection
                        
                        // New Workout Section
                        newWorkoutSection
                    }
                    .padding(.horizontal, GainsDesign.paddingHorizontal)
                    .padding(.top, GainsDesign.spacingXL)
                    .padding(.bottom, 60)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Text("Cancel")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.gainsPrimary)
                    }
                }
                
                ToolbarItem(placement: .principal) {
                    Text("Start Workout")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                }
            }
            .onAppear {
                Task {
                    await planService.loadPlans()
                }
            }
        }
    }
    
    // MARK: - Header Icon
    private var headerIcon: some View {
        ZStack {
            // Outer glow ring
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color.gainsPrimary.opacity(0.2), Color.clear],
                        center: .center,
                        startRadius: 30,
                        endRadius: 60
                    )
                )
                .frame(width: 120, height: 120)
            
            // Inner circle with icon
            ZStack {
                Circle()
                    .fill(.ultraThinMaterial)
                    .environment(\.colorScheme, .dark)
                    .frame(width: 80, height: 80)
                
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [Color.gainsPrimary.opacity(0.5), Color.gainsAccentBlue.opacity(0.3)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2
                    )
                    .frame(width: 80, height: 80)
                
                Image(systemName: "figure.strengthtraining.traditional")
                    .font(.system(size: 32, weight: .medium))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.gainsPrimary, Color.gainsAccentBlue],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
        }
        .padding(.bottom, GainsDesign.spacingS)
    }
    
    // MARK: - From Plan Section
    private func fromPlanSection(plan: WorkoutPlan) -> some View {
        VStack(alignment: .leading, spacing: GainsDesign.spacingL) {
            // Section Header
            HStack(spacing: GainsDesign.spacingS) {
                Image(systemName: "list.bullet.rectangle.portrait")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.gainsPrimary)
                
                Text("From Your Plan")
                    .font(.system(size: GainsDesign.footnote, weight: .semibold))
                    .foregroundColor(.gainsTextSecondary)
                    .textCase(.uppercase)
                    .tracking(0.5)
            }
            
            // Plan Name Badge
            HStack(spacing: GainsDesign.spacingS) {
                Text(plan.name)
                    .font(.system(size: GainsDesign.subheadline, weight: .medium))
                    .foregroundColor(.white)
                
                Text("Active")
                    .font(.system(size: GainsDesign.captionSmall, weight: .semibold))
                    .foregroundColor(.gainsSuccess)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(
                        Capsule()
                            .fill(Color.gainsSuccess.opacity(0.15))
                    )
            }
            
            // Workout Templates
            VStack(spacing: GainsDesign.spacingM) {
                ForEach(plan.workoutTemplates.sorted(by: { $0.dayNumber < $1.dayNumber })) { template in
                    WorkoutTemplateCard(
                        template: template,
                        isRecommended: isRecommendedToday(template, plan: plan)
                    ) {
                        startWorkoutFromTemplate(template)
                    }
                }
            }
        }
        .padding(GainsDesign.spacingXL)
        .background(
            RoundedRectangle(cornerRadius: GainsDesign.cornerRadiusXL)
                .fill(.ultraThinMaterial)
                .environment(\.colorScheme, .dark)
        )
        .overlay(
            RoundedRectangle(cornerRadius: GainsDesign.cornerRadiusXL)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }
    
    // MARK: - Quick Start Section
    private var quickStartSection: some View {
        VStack(alignment: .leading, spacing: GainsDesign.spacingL) {
            // Section Header
            HStack(spacing: GainsDesign.spacingS) {
                Image(systemName: "bolt.fill")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.gainsAccentOrange)
                
                Text("Quick Start")
                    .font(.system(size: GainsDesign.footnote, weight: .semibold))
                    .foregroundColor(.gainsTextSecondary)
                    .textCase(.uppercase)
                    .tracking(0.5)
            }
            
            // Quick Options Grid
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: GainsDesign.spacingM) {
                QuickStartOption(
                    title: "Push Day",
                    icon: "figure.arms.open",
                    color: .gainsPrimary
                ) {
                    quickStartWorkout(name: "Push Day")
                }
                
                QuickStartOption(
                    title: "Pull Day",
                    icon: "figure.strengthtraining.traditional",
                    color: .gainsAccentGreen
                ) {
                    quickStartWorkout(name: "Pull Day")
                }
                
                QuickStartOption(
                    title: "Leg Day",
                    icon: "figure.run",
                    color: .gainsAccentOrange
                ) {
                    quickStartWorkout(name: "Leg Day")
                }
                
                QuickStartOption(
                    title: "Custom",
                    icon: "plus",
                    color: .gainsTextSecondary
                ) {
                    showNewWorkoutInput = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        isInputFocused = true
                    }
                }
            }
        }
    }
    
    // MARK: - New Workout Section
    private var newWorkoutSection: some View {
        VStack(alignment: .leading, spacing: GainsDesign.spacingL) {
            // Section Header
            HStack(spacing: GainsDesign.spacingS) {
                Image(systemName: "square.and.pencil")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.gainsTextTertiary)
                
                Text("New Workout")
                    .font(.system(size: GainsDesign.footnote, weight: .semibold))
                    .foregroundColor(.gainsTextSecondary)
                    .textCase(.uppercase)
                    .tracking(0.5)
            }
            
            // Input Field
            VStack(spacing: GainsDesign.spacingM) {
                HStack(spacing: GainsDesign.spacingM) {
                    Image(systemName: "pencil")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(isInputFocused ? .gainsPrimary : .gainsTextTertiary)
                    
                    TextField("Name your workout...", text: $newWorkoutName)
                        .textFieldStyle(.plain)
                        .font(.system(size: 17, weight: .medium))
                        .foregroundColor(.white)
                        .focused($isInputFocused)
                        .submitLabel(.go)
                        .onSubmit {
                            if !newWorkoutName.isEmpty {
                                quickStartWorkout(name: newWorkoutName)
                            }
                        }
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(.ultraThinMaterial)
                        .environment(\.colorScheme, .dark)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(
                            isInputFocused
                                ? Color.gainsPrimary.opacity(0.5)
                                : Color.white.opacity(0.1),
                            lineWidth: isInputFocused ? 1.5 : 1
                        )
                )
                
                // Start Button
                Button {
                    let name = newWorkoutName.isEmpty ? "Workout" : newWorkoutName
                    quickStartWorkout(name: name)
                } label: {
                    HStack(spacing: 10) {
                        Text("Start Workout")
                            .font(.system(size: 17, weight: .semibold))
                        
                        Image(systemName: "arrow.right")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
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
                    .shadow(color: Color.gainsPrimary.opacity(0.4), radius: 16, x: 0, y: 8)
                }
            }
        }
    }
    
    // MARK: - Helpers
    private func isRecommendedToday(_ template: WorkoutTemplate, plan: WorkoutPlan) -> Bool {
        // Simple logic: recommend based on day number matching days since plan started
        guard let startDate = plan.startDate else { return template.dayNumber == 1 }
        let daysSinceStart = Calendar.current.dateComponents([.day], from: startDate, to: Date()).day ?? 0
        let cycleDay = (daysSinceStart % plan.daysPerWeek) + 1
        return template.dayNumber == cycleDay
    }
    
    private func startWorkoutFromTemplate(_ template: WorkoutTemplate) {
        workoutManager.startWorkoutFromTemplate(template)
        dismiss()
    }
    
    private func quickStartWorkout(name: String) {
        workoutManager.startWorkout(name: name)
        dismiss()
    }
}

// MARK: - Workout Template Card
struct WorkoutTemplateCard: View {
    let template: WorkoutTemplate
    let isRecommended: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: GainsDesign.spacingL) {
                // Day indicator
                VStack(spacing: 2) {
                    Text("Day")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.gainsTextTertiary)
                    
                    Text("\(template.dayNumber)")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: isRecommended
                                    ? [Color.gainsPrimary, Color.gainsAccentBlue]
                                    : [Color.gainsTextSecondary, Color.gainsTextTertiary],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                }
                .frame(width: 44, height: 44)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(isRecommended ? Color.gainsPrimary.opacity(0.15) : Color.white.opacity(0.05))
                )
                
                // Content
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: GainsDesign.spacingS) {
                        Text(template.name)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                        
                        if isRecommended {
                            Text("Today")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.gainsPrimary)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(
                                    Capsule()
                                        .fill(Color.gainsPrimary.opacity(0.2))
                                )
                        }
                    }
                    
                    Text("\(template.exercises.count) exercises")
                        .font(.system(size: 13))
                        .foregroundColor(.gainsTextSecondary)
                }
                
                Spacer()
                
                // Start indicator
                Image(systemName: "play.fill")
                    .font(.system(size: 14))
                    .foregroundColor(isRecommended ? .gainsPrimary : .gainsTextTertiary)
                    .frame(width: 32, height: 32)
                    .background(
                        Circle()
                            .fill(isRecommended ? Color.gainsPrimary.opacity(0.15) : Color.white.opacity(0.05))
                    )
            }
            .padding(GainsDesign.spacingL)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(isRecommended ? Color.gainsPrimary.opacity(0.08) : Color.white.opacity(0.03))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(
                        isRecommended
                            ? Color.gainsPrimary.opacity(0.3)
                            : Color.white.opacity(0.06),
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Quick Start Option
struct QuickStartOption: View {
    let title: String
    let icon: String
    let color: Color
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: GainsDesign.spacingM) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.15))
                        .frame(width: 48, height: 48)
                    
                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(color)
                }
                
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, GainsDesign.spacingXL)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.gainsCardSurface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.white.opacity(0.06), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    StartWorkoutSheet()
}

