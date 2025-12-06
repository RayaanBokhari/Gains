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
            Color.gainsBackground.ignoresSafeArea()
            
            if planService.plans.isEmpty && planService.retiredPlans.isEmpty {
                emptyState
            } else {
                ScrollView {
                    VStack(spacing: 20) {
                        // Active Plan
                        if let activePlan = planService.activePlan {
                            ActivePlanCard(plan: activePlan, planService: planService)
                        }
                        
                        // Available Plans (not active, not retired)
                        let availablePlans = planService.plans.filter { $0.id != planService.activePlan?.id }
                        if !availablePlans.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Available Plans")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.gainsText)
                                
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
                    .padding()
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
    
    // MARK: - Empty State
    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "list.bullet.rectangle")
                .font(.system(size: 56))
                .foregroundColor(.gainsSecondaryText)
            
            VStack(spacing: 8) {
                Text("No Workout Plans")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(.gainsText)
                
                Text("Create or generate a plan to get started")
                    .font(.system(size: 15))
                    .foregroundColor(.gainsSecondaryText)
            }
            
            VStack(spacing: 12) {
                Button {
                    showGeneratePlan = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "sparkles")
                        Text("Generate with AI")
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.gainsPrimary)
                    .cornerRadius(12)
                }
                
                Button {
                    showCreatePlan = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "plus")
                        Text("Create Manually")
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.gainsPrimary)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.gainsCardBackground)
                    .cornerRadius(12)
                }
            }
            .padding(.horizontal, 40)
        }
    }
    
    // MARK: - Retired Plans Section
    private var retiredPlansSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Button {
                withAnimation {
                    showRetiredPlans.toggle()
                }
            } label: {
                HStack {
                    Image(systemName: "archivebox")
                        .foregroundColor(.gainsSecondaryText)
                    
                    Text("Retired Plans (\(planService.retiredPlans.count))")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.gainsText)
                    
                    Spacer()
                    
                    Image(systemName: showRetiredPlans ? "chevron.up" : "chevron.down")
                        .font(.system(size: 14))
                        .foregroundColor(.gainsSecondaryText)
                }
                .padding()
                .background(Color.gainsCardBackground)
                .cornerRadius(12)
            }
            
            if showRetiredPlans {
                ForEach(planService.retiredPlans) { plan in
                    RetiredPlanCard(plan: plan, planService: planService)
                }
            }
        }
    }
    
    // MARK: - Quick Actions
    private var quickActionsSection: some View {
        VStack(spacing: 12) {
            Divider()
                .background(Color.gainsCardBackground)
                .padding(.vertical, 8)
            
            HStack(spacing: 12) {
                Button {
                    showGeneratePlan = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "sparkles")
                        Text("Generate")
                    }
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.gainsPrimary)
                    .cornerRadius(10)
                }
                
                Button {
                    showCreatePlan = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "plus")
                        Text("Create")
                    }
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.gainsPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.gainsCardBackground)
                    .cornerRadius(10)
                }
            }
        }
    }
}

// MARK: - Active Plan Card
struct ActivePlanCard: View {
    let plan: WorkoutPlan
    @ObservedObject var planService: WorkoutPlanService
    @State private var showActionSheet = false
    @State private var showDeleteAlert = false
    @State private var showRetireAlert = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Active Plan", systemImage: "checkmark.circle.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.gainsPrimary)
                
                Spacer()
                
                // More options menu
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
                        .font(.system(size: 16))
                        .foregroundColor(.gainsSecondaryText)
                        .frame(width: 32, height: 32)
                }
            }
            
            Text(plan.name)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.gainsText)
            
            if let description = plan.description {
                Text(description)
                    .font(.system(size: 14))
                    .foregroundColor(.gainsSecondaryText)
                    .lineLimit(2)
            }
            
            // Progress info
            if let startDate = plan.startDate, let endDate = plan.endDate {
                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Started")
                            .font(.system(size: 11))
                            .foregroundColor(.gainsSecondaryText)
                        Text(startDate, style: .date)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.gainsText)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Ends")
                            .font(.system(size: 11))
                            .foregroundColor(.gainsSecondaryText)
                        Text(endDate, style: .date)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.gainsText)
                    }
                }
                .padding(.top, 4)
            }
            
            HStack {
                Label("\(plan.daysPerWeek) days/week", systemImage: "calendar")
                Spacer()
                Label("\(plan.durationWeeks) weeks", systemImage: "clock")
            }
            .font(.system(size: 12))
            .foregroundColor(.gainsSecondaryText)
            
            NavigationLink(destination: WorkoutPlanDetailView(plan: plan, planService: planService)) {
                Text("View Plan")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.gainsPrimary)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.gainsCardBackground)
                    .cornerRadius(8)
            }
        }
        .padding()
        .background(Color.gainsPrimary.opacity(0.1))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.gainsPrimary, lineWidth: 2)
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
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(plan.name)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.gainsText)
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
                        .foregroundColor(.gainsSecondaryText)
                }
            }
            
            if let description = plan.description {
                Text(description)
                    .font(.system(size: 14))
                    .foregroundColor(.gainsSecondaryText)
                    .lineLimit(2)
            }
            
            HStack {
                Label("\(plan.daysPerWeek) days/week", systemImage: "calendar")
                Spacer()
                Label(plan.difficulty.rawValue, systemImage: "chart.bar")
            }
            .font(.system(size: 12))
            .foregroundColor(.gainsSecondaryText)
            
            NavigationLink(destination: WorkoutPlanDetailView(plan: plan, planService: planService)) {
                Text("View Details")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.gainsPrimary)
            }
        }
        .padding()
        .background(Color.gainsCardBackground)
        .cornerRadius(16)
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
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(plan.name)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.gainsText)
                    
                    if let retiredAt = plan.retiredAt {
                        Text("Retired \(retiredAt, style: .relative) ago")
                            .font(.system(size: 12))
                            .foregroundColor(.gainsSecondaryText)
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
                        .foregroundColor(.gainsSecondaryText)
                }
            }
            
            HStack {
                Label("\(plan.daysPerWeek) days/week", systemImage: "calendar")
                Spacer()
                Label("\(plan.durationWeeks) weeks", systemImage: "clock")
            }
            .font(.system(size: 11))
            .foregroundColor(.gainsSecondaryText)
        }
        .padding()
        .background(Color.gainsCardBackground.opacity(0.6))
        .cornerRadius(12)
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
