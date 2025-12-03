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
    
    var body: some View {
        ZStack {
            Color.gainsBackground.ignoresSafeArea()
            
            if planService.plans.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "list.bullet.rectangle")
                        .font(.system(size: 48))
                        .foregroundColor(.gainsSecondaryText)
                    
                    Text("No Workout Plans")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.gainsText)
                    
                    Text("Create or generate a plan to get started")
                        .font(.system(size: 14))
                        .foregroundColor(.gainsSecondaryText)
                    
                    VStack(spacing: 12) {
                        Button {
                            showGeneratePlan = true
                        } label: {
                            HStack {
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
                            HStack {
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
                    .padding(.horizontal)
                }
            } else {
                ScrollView {
                    VStack(spacing: 16) {
                        // Active Plan
                        if let activePlan = planService.activePlan {
                            ActivePlanCard(plan: activePlan, planService: planService)
                        }
                        
                        // All Plans
                        ForEach(planService.plans) { plan in
                            if plan.id != planService.activePlan?.id {
                                WorkoutPlanCard(plan: plan, planService: planService)
                            }
                        }
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
}

struct ActivePlanCard: View {
    let plan: WorkoutPlan
    @ObservedObject var planService: WorkoutPlanService
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Active Plan", systemImage: "checkmark.circle.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.gainsPrimary)
                Spacer()
            }
            
            Text(plan.name)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.gainsText)
            
            if let description = plan.description {
                Text(description)
                    .font(.system(size: 14))
                    .foregroundColor(.gainsSecondaryText)
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
    }
}

struct WorkoutPlanCard: View {
    let plan: WorkoutPlan
    @ObservedObject var planService: WorkoutPlanService
    @State private var showDeleteAlert = false
    
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
            Text("Are you sure you want to delete this workout plan?")
        }
    }
}

#Preview {
    WorkoutPlansView()
}

