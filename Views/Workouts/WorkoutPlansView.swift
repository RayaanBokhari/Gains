//
//  WorkoutPlansView.swift
//  Gains
//
//  Created by Rayaan Bokhari on 12/20/25.
//

import SwiftUI

// Wrapper for standalone navigation
struct WorkoutPlansView: View {
    var body: some View {
        NavigationView {
            WorkoutPlansContentView()
        }
    }
}

// Content view without NavigationView - used when embedded in WorkoutListView
struct WorkoutPlansContentView: View {
    @StateObject private var planService = WorkoutPlanService()
    @State private var showCreatePlan = false
    @State private var showGeneratePlan = false
    @State private var showRetiredPlans = false
    
    var body: some View {
        ZStack {
            Color.gainsBgPrimary.ignoresSafeArea()
            
            if planService.plans.isEmpty && planService.retiredPlans.isEmpty {
                emptyState
            } else {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: GainsDesign.sectionSpacing) {
                        // Active Plan
                        if let activePlan = planService.activePlan {
                            ActivePlanCard(plan: activePlan, planService: planService)
                        }
                        
                        // Available Plans (not active, not retired)
                        let availablePlans = planService.plans.filter { $0.id != planService.activePlan?.id }
                        if !availablePlans.isEmpty {
                            VStack(alignment: .leading, spacing: GainsDesign.spacingL) {
                                Text("Available Plans")
                                    .font(.system(size: GainsDesign.headline, weight: .semibold))
                                    .foregroundColor(.white)
                                
                                ForEach(availablePlans) { plan in
                                    WorkoutPlanCard(plan: plan, planService: planService)
                                }
                            }
                        }
                        
                        // Retired Plans Section
                        if !planService.retiredPlans.isEmpty {
                            retiredPlansSection
                        }
                        
                        // Quick Actions
                        quickActionsSection
                    }
                    .padding(.horizontal, GainsDesign.paddingHorizontal)
                    .padding(.vertical, GainsDesign.spacingL)
                    .padding(.bottom, 60)
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button {
                        showGeneratePlan = true
                    } label: {
                        Label("Generate with AI", systemImage: "sparkles")
                    }
                    
                    Button {
                        showCreatePlan = true
                    } label: {
                        Label("Create Manually", systemImage: "plus")
                    }
                } label: {
                    Image(systemName: "plus")
                        .foregroundColor(.gainsPrimary)
                }
            }
        }
        .onAppear {
            Task {
                await planService.loadPlans()
            }
        }
        .sheet(isPresented: $showCreatePlan) {
            CreateWorkoutPlanView(planService: planService)
        }
        .sheet(isPresented: $showGeneratePlan) {
            GeneratePlanView(planService: planService)
        }
    }
    
    // MARK: - Empty State (Apple Fitness Style)
    private var emptyState: some View {
        VStack(spacing: 0) {
            Spacer()
            
            VStack(spacing: GainsDesign.spacingXXL) {
                // Minimalist icon illustration
                ZStack {
                    // Outer ring
                    Circle()
                        .stroke(Color.gainsTextMuted.opacity(0.3), lineWidth: 2)
                        .frame(width: 100, height: 100)
                    
                    // Inner content
                    VStack(spacing: 4) {
                        Image(systemName: "list.bullet.rectangle.portrait")
                            .font(.system(size: 36, weight: .light))
                            .foregroundColor(.gainsTextTertiary)
                    }
                }
                .padding(.bottom, GainsDesign.spacingS)
                
                // Message hierarchy
                VStack(spacing: GainsDesign.spacingM) {
                    Text("No Workout Plans Yet")
                        .font(.system(size: GainsDesign.titleSmall, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text("Create a custom plan or let AI generate\none based on your goals")
                        .font(.system(size: GainsDesign.callout))
                        .foregroundColor(.gainsTextSecondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                }
                
                // Action Buttons
                VStack(spacing: GainsDesign.spacingM) {
                    // Primary Button - Generate with AI
                    Button {
                        showGeneratePlan = true
                    } label: {
                        HStack(spacing: GainsDesign.spacingS) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 16, weight: .medium))
                            Text("Generate with AI")
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
                    
                    // Secondary Button - Create Manually
                    Button {
                        showCreatePlan = true
                    } label: {
                        HStack(spacing: GainsDesign.spacingS) {
                            Image(systemName: "plus")
                                .font(.system(size: 14, weight: .medium))
                            Text("Create Manually")
                                .font(.system(size: GainsDesign.body, weight: .medium))
                        }
                        .foregroundColor(.gainsTextSecondary)
                        .frame(maxWidth: .infinity)
                        .frame(height: GainsDesign.buttonHeightLarge)
                    }
                }
                .padding(.horizontal, 32)
            }
            
            Spacer()
            Spacer()
        }
        .padding(.horizontal, GainsDesign.paddingHorizontal)
    }
    
    // MARK: - Retired Plans Section
    private var retiredPlansSection: some View {
        VStack(alignment: .leading, spacing: GainsDesign.spacingM) {
            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    showRetiredPlans.toggle()
                }
            } label: {
                HStack(spacing: GainsDesign.spacingM) {
                    ZStack {
                        RoundedRectangle(cornerRadius: GainsDesign.cornerRadiusXS)
                            .fill(Color.gainsTextMuted.opacity(0.15))
                            .frame(width: 36, height: 36)
                        
                        Image(systemName: "archivebox")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.gainsTextTertiary)
                    }
                    
                    Text("Retired Plans")
                        .font(.system(size: GainsDesign.body, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Text("(\(planService.retiredPlans.count))")
                        .font(.system(size: GainsDesign.subheadline))
                        .foregroundColor(.gainsTextSecondary)
                    
                    Spacer()
                    
                    Image(systemName: showRetiredPlans ? "chevron.up" : "chevron.down")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.gainsTextTertiary)
                }
                .padding(GainsDesign.cardPadding)
                .background(
                    RoundedRectangle(cornerRadius: GainsDesign.cornerRadiusLarge)
                        .fill(Color.gainsCardSurface)
                )
            }
            
            if showRetiredPlans {
                ForEach(planService.retiredPlans) { plan in
                    RetiredPlanCard(plan: plan, planService: planService)
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .move(edge: .top)),
                            removal: .opacity
                        ))
                }
            }
        }
    }
    
    // MARK: - Quick Actions
    private var quickActionsSection: some View {
        VStack(spacing: GainsDesign.spacingL) {
            Rectangle()
                .fill(Color.gainsSeparator)
                .frame(height: 0.5)
                .padding(.vertical, GainsDesign.spacingS)
            
            HStack(spacing: GainsDesign.spacingM) {
                // Generate Button
                Button {
                    showGeneratePlan = true
                } label: {
                    HStack(spacing: GainsDesign.spacingS) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 14, weight: .medium))
                        Text("Generate")
                            .font(.system(size: GainsDesign.subheadline, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: GainsDesign.buttonHeightMedium)
                    .background(
                        RoundedRectangle(cornerRadius: GainsDesign.cornerRadiusSmall)
                            .fill(Color.gainsPrimary)
                    )
                }
                
                // Create Button
                Button {
                    showCreatePlan = true
                } label: {
                    HStack(spacing: GainsDesign.spacingS) {
                        Image(systemName: "plus")
                            .font(.system(size: 14, weight: .medium))
                        Text("Create")
                            .font(.system(size: GainsDesign.subheadline, weight: .semibold))
                    }
                    .foregroundColor(.gainsPrimary)
                    .frame(maxWidth: .infinity)
                    .frame(height: GainsDesign.buttonHeightMedium)
                    .background(
                        RoundedRectangle(cornerRadius: GainsDesign.cornerRadiusSmall)
                            .fill(Color.gainsCardSurface)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: GainsDesign.cornerRadiusSmall)
                            .stroke(Color.gainsPrimary.opacity(0.3), lineWidth: 1)
                    )
                }
            }
        }
    }
}

// MARK: - Active Plan Card (Premium Highlight Style)
struct ActivePlanCard: View {
    let plan: WorkoutPlan
    @ObservedObject var planService: WorkoutPlanService
    @State private var showDeleteAlert = false
    @State private var showRetireAlert = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: GainsDesign.spacingL) {
            // Header
            HStack {
                HStack(spacing: GainsDesign.spacingS) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 14, weight: .medium))
                    Text("Active Plan")
                        .font(.system(size: GainsDesign.footnote, weight: .semibold))
                }
                .foregroundColor(.gainsPrimary)
                
                Spacer()
                
                Menu {
                    Button {
                        showRetireAlert = true
                    } label: {
                        Label("Retire Plan", systemImage: "archivebox")
                    }
                    
                    Button {
                        Task {
                            try? await planService.deactivatePlan(plan)
                        }
                    } label: {
                        Label("Deactivate", systemImage: "stop.circle")
                    }
                    
                    Divider()
                    
                    Button(role: .destructive) {
                        showDeleteAlert = true
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.gainsTextSecondary)
                        .frame(width: 32, height: 32)
                        .contentShape(Rectangle())
                }
            }
            
            // Plan Title
            Text(plan.name)
                .font(.system(size: GainsDesign.titleSmall, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            
            // Description
            if let description = plan.description {
                Text(description)
                    .font(.system(size: GainsDesign.subheadline))
                    .foregroundColor(.gainsTextSecondary)
                    .lineLimit(2)
            }
            
            // Progress info
            if let startDate = plan.startDate, let endDate = plan.endDate {
                HStack(spacing: GainsDesign.spacingXL) {
                    VStack(alignment: .leading, spacing: GainsDesign.spacingXXS) {
                        Text("Started")
                            .font(.system(size: GainsDesign.captionSmall))
                            .foregroundColor(.gainsTextTertiary)
                        Text(startDate, style: .date)
                            .font(.system(size: GainsDesign.footnote, weight: .medium))
                            .foregroundColor(.white)
                    }
                    
                    VStack(alignment: .leading, spacing: GainsDesign.spacingXXS) {
                        Text("Ends")
                            .font(.system(size: GainsDesign.captionSmall))
                            .foregroundColor(.gainsTextTertiary)
                        Text(endDate, style: .date)
                            .font(.system(size: GainsDesign.footnote, weight: .medium))
                            .foregroundColor(.white)
                    }
                }
            }
            
            // Meta info
            HStack(spacing: GainsDesign.spacingL) {
                Label("\(plan.daysPerWeek) days/week", systemImage: "calendar")
                Spacer()
                Label("\(plan.durationWeeks) weeks", systemImage: "clock")
            }
            .font(.system(size: GainsDesign.caption))
            .foregroundColor(.gainsTextSecondary)
            
            // View Plan Button
            NavigationLink(destination: WorkoutPlanDetailView(plan: plan, planService: planService)) {
                Text("View Plan")
                    .font(.system(size: GainsDesign.subheadline, weight: .semibold))
                    .foregroundColor(.gainsPrimary)
                    .frame(maxWidth: .infinity)
                    .frame(height: GainsDesign.buttonHeightMedium)
                    .background(
                        RoundedRectangle(cornerRadius: GainsDesign.cornerRadiusSmall)
                            .fill(Color.gainsPrimary.opacity(0.12))
                    )
            }
        }
        .padding(GainsDesign.spacingXL)
        .background(
            RoundedRectangle(cornerRadius: GainsDesign.cornerRadiusXL)
                .fill(Color.gainsPrimary.opacity(0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: GainsDesign.cornerRadiusXL)
                .stroke(Color.gainsPrimary.opacity(0.4), lineWidth: 1.5)
        )
        .alert("Delete Plan", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                Task {
                    try? await planService.deletePlan(plan)
                }
            }
        } message: {
            Text("Are you sure you want to permanently delete this workout plan? This cannot be undone.")
        }
        .alert("Retire Plan", isPresented: $showRetireAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Retire") {
                Task {
                    try? await planService.retirePlan(plan)
                }
            }
        } message: {
            Text("Retiring this plan will archive it. You can restore it later from the Retired Plans section.")
        }
    }
}

// MARK: - Workout Plan Card (Available)
struct WorkoutPlanCard: View {
    let plan: WorkoutPlan
    @ObservedObject var planService: WorkoutPlanService
    @State private var showDeleteAlert = false
    @State private var showRetireAlert = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: GainsDesign.spacingL) {
            HStack {
                Text(plan.name)
                    .font(.system(size: GainsDesign.headline, weight: .semibold))
                    .foregroundColor(.white)
                
                Spacer()
                
                Menu {
                    Button {
                        Task {
                            try? await planService.setActivePlan(plan)
                        }
                    } label: {
                        Label("Set as Active", systemImage: "checkmark.circle")
                    }
                    
                    Button {
                        showRetireAlert = true
                    } label: {
                        Label("Retire Plan", systemImage: "archivebox")
                    }
                    
                    Divider()
                    
                    Button(role: .destructive) {
                        showDeleteAlert = true
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.gainsTextSecondary)
                        .frame(width: 28, height: 28)
                        .contentShape(Rectangle())
                }
            }
            
            if let description = plan.description {
                Text(description)
                    .font(.system(size: GainsDesign.subheadline))
                    .foregroundColor(.gainsTextSecondary)
                    .lineLimit(2)
            }
            
            HStack(spacing: GainsDesign.spacingL) {
                Label("\(plan.daysPerWeek) days/week", systemImage: "calendar")
                Spacer()
                Label(plan.difficulty.rawValue, systemImage: "chart.bar")
            }
            .font(.system(size: GainsDesign.caption))
            .foregroundColor(.gainsTextSecondary)
            
            NavigationLink(destination: WorkoutPlanDetailView(plan: plan, planService: planService)) {
                HStack {
                    Text("View Details")
                        .font(.system(size: GainsDesign.subheadline, weight: .medium))
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .medium))
                }
                .foregroundColor(.gainsPrimary)
            }
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
        .alert("Delete Plan", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                Task {
                    try? await planService.deletePlan(plan)
                }
            }
        } message: {
            Text("Are you sure you want to permanently delete this workout plan?")
        }
        .alert("Retire Plan", isPresented: $showRetireAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Retire") {
                Task {
                    try? await planService.retirePlan(plan)
                }
            }
        } message: {
            Text("Retiring this plan will archive it. You can restore it later.")
        }
    }
}

// MARK: - Retired Plan Card
struct RetiredPlanCard: View {
    let plan: WorkoutPlan
    @ObservedObject var planService: WorkoutPlanService
    @State private var showDeleteAlert = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: GainsDesign.spacingM) {
            HStack {
                VStack(alignment: .leading, spacing: GainsDesign.spacingXS) {
                    Text(plan.name)
                        .font(.system(size: GainsDesign.body, weight: .semibold))
                        .foregroundColor(.white)
                    
                    if let retiredAt = plan.retiredAt {
                        Text("Retired \(retiredAt, style: .relative) ago")
                            .font(.system(size: GainsDesign.caption))
                            .foregroundColor(.gainsTextTertiary)
                    }
                }
                
                Spacer()
                
                Menu {
                    Button {
                        Task {
                            try? await planService.restorePlan(plan)
                        }
                    } label: {
                        Label("Restore Plan", systemImage: "arrow.uturn.backward")
                    }
                    
                    Button {
                        Task {
                            try? await planService.setActivePlan(plan)
                        }
                    } label: {
                        Label("Restore & Activate", systemImage: "checkmark.circle")
                    }
                    
                    Divider()
                    
                    Button(role: .destructive) {
                        showDeleteAlert = true
                    } label: {
                        Label("Delete Permanently", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.gainsTextSecondary)
                        .frame(width: 28, height: 28)
                        .contentShape(Rectangle())
                }
            }
            
            HStack(spacing: GainsDesign.spacingL) {
                Label("\(plan.daysPerWeek) days/week", systemImage: "calendar")
                Spacer()
                Label("\(plan.durationWeeks) weeks", systemImage: "clock")
            }
            .font(.system(size: GainsDesign.captionSmall))
            .foregroundColor(.gainsTextTertiary)
        }
        .padding(GainsDesign.spacingL)
        .background(
            RoundedRectangle(cornerRadius: GainsDesign.cornerRadiusMedium)
                .fill(Color.gainsCardSurface.opacity(0.6))
        )
        .alert("Delete Plan", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                Task {
                    try? await planService.deletePlan(plan)
                }
            }
        } message: {
            Text("Are you sure you want to permanently delete this plan? This cannot be undone.")
        }
    }
}

#Preview {
    WorkoutPlansView()
}
