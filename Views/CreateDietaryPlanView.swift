//
//  CreateDietaryPlanView.swift
//  Gains
//
//  Created by Rayaan Bokhari on 12/20/25.
//

import SwiftUI

struct CreateDietaryPlanView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var planService: DietaryPlanService
    @StateObject private var profileViewModel = ProfileViewModel()
    
    // Basic info
    @State private var planName = ""
    @State private var planDescription = ""
    @State private var selectedGoal: FitnessGoal = .maintenance
    @State private var selectedDietType: DietType?
    
    // Targets
    @State private var dailyCalories: Int = 2000
    @State private var proteinGrams: Double = 150
    @State private var carbGrams: Double = 200
    @State private var fatGrams: Double = 65
    @State private var mealsPerDay: Int = 3
    
    // Restrictions
    @State private var restrictions: [String] = []
    @State private var restrictionInput = ""
    
    @State private var isSaving = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.gainsBackground.ignoresSafeArea()
                
                Form {
                    Section("Plan Info") {
                        TextField("Plan Name", text: $planName)
                        TextField("Description (optional)", text: $planDescription, axis: .vertical)
                            .lineLimit(2...4)
                    }
                    
                    Section("Fitness Goal") {
                        Picker("Goal", selection: $selectedGoal) {
                            ForEach(FitnessGoal.allCases, id: \.self) { goal in
                                Text(goal.rawValue).tag(goal)
                            }
                        }
                        
                        Picker("Diet Type", selection: $selectedDietType) {
                            Text("Balanced").tag(nil as DietType?)
                            ForEach(DietType.allCases, id: \.self) { type in
                                Text(type.rawValue).tag(type as DietType?)
                            }
                        }
                    }
                    
                    Section("Daily Targets") {
                        HStack {
                            Text("Calories")
                            Spacer()
                            TextField("Calories", value: $dailyCalories, format: .number)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 80)
                            Text("kcal")
                                .foregroundColor(.gainsSecondaryText)
                        }
                        
                        HStack {
                            Text("Protein")
                            Spacer()
                            TextField("Protein", value: $proteinGrams, format: .number)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 60)
                            Text("g")
                                .foregroundColor(.gainsSecondaryText)
                        }
                        
                        HStack {
                            Text("Carbs")
                            Spacer()
                            TextField("Carbs", value: $carbGrams, format: .number)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 60)
                            Text("g")
                                .foregroundColor(.gainsSecondaryText)
                        }
                        
                        HStack {
                            Text("Fats")
                            Spacer()
                            TextField("Fats", value: $fatGrams, format: .number)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 60)
                            Text("g")
                                .foregroundColor(.gainsSecondaryText)
                        }
                        
                        Stepper("Meals per day: \(mealsPerDay)", value: $mealsPerDay, in: 2...6)
                    }
                    
                    Section("Dietary Restrictions") {
                        HStack {
                            TextField("Add restriction", text: $restrictionInput)
                            
                            if !restrictionInput.isEmpty {
                                Button {
                                    restrictions.append(restrictionInput)
                                    restrictionInput = ""
                                } label: {
                                    Image(systemName: "plus.circle.fill")
                                        .foregroundColor(.gainsSuccess)
                                }
                            }
                        }
                        
                        if !restrictions.isEmpty {
                            ForEach(restrictions, id: \.self) { restriction in
                                HStack {
                                    Text(restriction)
                                    Spacer()
                                    Button {
                                        restrictions.removeAll { $0 == restriction }
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(.gainsSecondaryText)
                                    }
                                }
                            }
                        }
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
            .navigationTitle("Create Meal Plan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        savePlan()
                    } label: {
                        if isSaving {
                            ProgressView()
                        } else {
                            Text("Save")
                        }
                    }
                    .disabled(planName.isEmpty || isSaving)
                }
            }
            .onAppear {
                Task {
                    await profileViewModel.loadProfile()
                    prefillFromProfile()
                }
            }
        }
    }
    
    private func prefillFromProfile() {
        let profile = profileViewModel.profile
        
        if let goal = profile.primaryGoal {
            selectedGoal = goal
        }
        
        // Use profile calorie goal
        if profile.dailyCaloriesGoal > 0 {
            dailyCalories = profile.dailyCaloriesGoal
        }
        
        // Use profile macro goals
        if profile.macros.protein > 0 {
            proteinGrams = profile.macros.protein
        }
        
        if profile.macros.carbs > 0 {
            carbGrams = profile.macros.carbs
        }
        
        if profile.macros.fats > 0 {
            fatGrams = profile.macros.fats
        }
        
        if let dietType = profile.dietType {
            selectedDietType = dietType
        }
        
        // Load allergies as restrictions
        if let allergies = profile.allergies, !allergies.isEmpty {
            restrictions = allergies
        }
    }
    
    private func savePlan() {
        isSaving = true
        errorMessage = nil
        
        let plan = DietaryPlan(
            name: planName,
            description: planDescription.isEmpty ? nil : planDescription,
            goal: selectedGoal,
            dailyCalories: dailyCalories,
            macros: DietaryPlan.MacroTargets(
                protein: proteinGrams,
                carbs: carbGrams,
                fats: fatGrams
            ),
            mealCount: mealsPerDay,
            meals: [], // Empty for manual creation - user can add meals later
            createdBy: .user,
            dietType: selectedDietType,
            restrictions: restrictions.isEmpty ? nil : restrictions,
            durationWeeks: 1
        )
        
        Task {
            do {
                try await planService.savePlan(plan)
                await MainActor.run {
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to save plan: \(error.localizedDescription)"
                    isSaving = false
                }
            }
        }
    }
}

#Preview {
    CreateDietaryPlanView(planService: DietaryPlanService())
}

