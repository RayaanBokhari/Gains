//
//  DietaryPlansView.swift
//  Gains
//
//  Created by Rayaan Bokhari on 12/20/25.
//

import SwiftUI

// Wrapper for standalone navigation
struct DietaryPlansView: View {
    var body: some View {
        NavigationView {
            DietaryPlansContentView()
        }
    }
}

// Content view without NavigationView - used when embedded
struct DietaryPlansContentView: View {
    @StateObject private var planService = DietaryPlanService()
    @State private var showCreatePlan = false
    @State private var showGeneratePlan = false
    @State private var showRetiredPlans = false
    
    var body: some View {
        ZStack {
            Color.gainsBackground.ignoresSafeArea()
            
            if planService.isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .gainsPrimary))
            } else if planService.plans.isEmpty && planService.retiredPlans.isEmpty {
                emptyState
            } else {
                ScrollView {
                    VStack(spacing: 20) {
                        // Active Plan
                        if let activePlan = planService.activePlan {
                            ActiveDietaryPlanCard(plan: activePlan, planService: planService)
                        }
                        
                        // Available Plans (not active, not retired)
                        let availablePlans = planService.plans.filter { $0.id != planService.activePlan?.id }
                        if !availablePlans.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Available Plans")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.gainsText)
                                
                                ForEach(availablePlans) { plan in
                                    DietaryPlanCard(plan: plan, planService: planService)
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
        .navigationTitle("Meal Plans")
        .navigationBarTitleDisplayMode(.inline)
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
            CreateDietaryPlanView(planService: planService)
        }
        .sheet(isPresented: $showGeneratePlan) {
            GenerateDietaryPlanView(planService: planService)
        }
    }
    
    // MARK: - Empty State
    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "fork.knife.circle")
                .font(.system(size: 56))
                .foregroundColor(.gainsSecondaryText)
            
            VStack(spacing: 8) {
                Text("No Meal Plans")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(.gainsText)
                
                Text("Create or generate a personalized meal plan")
                    .font(.system(size: 15))
                    .foregroundColor(.gainsSecondaryText)
                    .multilineTextAlignment(.center)
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
                    .background(Color.gainsSuccess)
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
                    .foregroundColor(.gainsSuccess)
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
                    RetiredDietaryPlanCard(plan: plan, planService: planService)
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
                    .background(Color.gainsSuccess)
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
                    .foregroundColor(.gainsSuccess)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.gainsCardBackground)
                    .cornerRadius(10)
                }
            }
        }
    }
}

// MARK: - Active Dietary Plan Card
struct ActiveDietaryPlanCard: View {
    let plan: DietaryPlan
    @ObservedObject var planService: DietaryPlanService
    @State private var showDeleteAlert = false
    @State private var showRetireAlert = false
    
    var body: some View {
        NavigationLink(destination: DietaryPlanDetailView(plan: plan, planService: planService)) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Label("Active Plan", systemImage: "checkmark.circle.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.gainsSuccess)
                    
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
                
                // Macro targets
                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Calories")
                            .font(.system(size: 11))
                            .foregroundColor(.gainsSecondaryText)
                        Text("\(plan.dailyCalories)")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.gainsText)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Protein")
                            .font(.system(size: 11))
                            .foregroundColor(.gainsSecondaryText)
                        Text("\(Int(plan.macros.protein))g")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.gainsPrimary)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Carbs")
                            .font(.system(size: 11))
                            .foregroundColor(.gainsSecondaryText)
                        Text("\(Int(plan.macros.carbs))g")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.gainsSecondary)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Fats")
                            .font(.system(size: 11))
                            .foregroundColor(.gainsSecondaryText)
                        Text("\(Int(plan.macros.fats))g")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.gainsWarning)
                    }
                }
                .padding(.top, 4)
                
                HStack {
                    Label("\(plan.mealCount) meals/day", systemImage: "fork.knife")
                    Spacer()
                    if let dietType = plan.dietType {
                        Label(dietType.rawValue, systemImage: "leaf")
                    }
                }
                .font(.system(size: 12))
                .foregroundColor(.gainsSecondaryText)
                
                Text("View Full Plan →")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.gainsSuccess)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.gainsCardBackground)
                    .cornerRadius(8)
            }
            .padding()
            .background(Color.gainsSuccess.opacity(0.1))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.gainsSuccess, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .alert("Delete Plan", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                Task {
                    try? await planService.deletePlan(plan)
                }
            }
        } message: {
            Text("Are you sure you want to permanently delete this meal plan?")
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

// MARK: - Dietary Plan Card (Available)
struct DietaryPlanCard: View {
    let plan: DietaryPlan
    @ObservedObject var planService: DietaryPlanService
    @State private var showDeleteAlert = false
    @State private var showRetireAlert = false
    
    var body: some View {
        NavigationLink(destination: DietaryPlanDetailView(plan: plan, planService: planService)) {
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
                    Label("\(plan.dailyCalories) kcal", systemImage: "flame")
                    Spacer()
                    Label("\(plan.mealCount) meals/day", systemImage: "fork.knife")
                }
                .font(.system(size: 12))
                .foregroundColor(.gainsSecondaryText)
            }
            .padding()
            .background(Color.gainsCardBackground)
            .cornerRadius(16)
        }
        .buttonStyle(PlainButtonStyle())
        .alert("Delete Plan", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                Task {
                    try? await planService.deletePlan(plan)
                }
            }
        } message: {
            Text("Are you sure you want to permanently delete this meal plan?")
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

// MARK: - Retired Dietary Plan Card
struct RetiredDietaryPlanCard: View {
    let plan: DietaryPlan
    @ObservedObject var planService: DietaryPlanService
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
                Label("\(plan.dailyCalories) kcal", systemImage: "flame")
                Spacer()
                Label("\(plan.mealCount) meals/day", systemImage: "fork.knife")
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
            Text("Are you sure you want to permanently delete this plan?")
        }
    }
}

#Preview {
    DietaryPlansView()
}

