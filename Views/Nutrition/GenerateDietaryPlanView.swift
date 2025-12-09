//
//  GenerateDietaryPlanView.swift
//  Gains
//
//  Created by Rayaan Bokhari on 12/20/25.
//

import SwiftUI

struct GenerateDietaryPlanView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var planService: DietaryPlanService
    @StateObject private var profileViewModel = ProfileViewModel()
    
    // Form inputs
    @State private var selectedGoal: FitnessGoal = .maintenance
    @State private var dailyCalories: Int = 2000
    @State private var proteinGrams: Double = 150
    @State private var carbGrams: Double = 200
    @State private var fatGrams: Double = 65
    @State private var mealsPerDay: Int = 3
    @State private var selectedDietType: DietType?
    @State private var restrictions: [String] = []
    @State private var restrictionInput = ""
    @State private var additionalNotes = ""
    
    // State
    @State private var isGenerating = false
    @State private var generatedPlan: DietaryPlan?
    @State private var errorMessage: String?
    
    // Common restrictions
    let commonRestrictions = ["Dairy", "Gluten", "Nuts", "Soy", "Eggs", "Shellfish", "Pork", "Beef"]
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.gainsBackground.ignoresSafeArea()
                
                if isGenerating {
                    loadingState
                } else if let plan = generatedPlan {
                    generatedPlanPreview(plan)
                } else {
                    generationForm
                }
            }
            .navigationTitle("Generate Meal Plan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                if generatedPlan == nil && !isGenerating {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            generatePlan()
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "sparkles")
                                Text("Generate")
                            }
                        }
                        .disabled(isGenerating)
                    }
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
    
    // MARK: - Loading State
    private var loadingState: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
                .progressViewStyle(CircularProgressViewStyle(tint: .gainsSuccess))
            
            Text("Creating your personalized meal plan...")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.gainsText)
                .multilineTextAlignment(.center)
            
            Text("This may take up to 30 seconds")
                .font(.system(size: 14))
                .foregroundColor(.gainsSecondaryText)
        }
        .padding()
    }
    
    // MARK: - Generation Form
    private var generationForm: some View {
        Form {
            Section("Fitness Goal") {
                Picker("Goal", selection: $selectedGoal) {
                    ForEach(FitnessGoal.allCases, id: \.self) { goal in
                        Text(goal.rawValue).tag(goal)
                    }
                }
                .onChange(of: selectedGoal) { _, newGoal in
                    updateMacrosForGoal(newGoal)
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
                
                // Calculated calories indicator
                let calculatedCals = Int(proteinGrams * 4 + carbGrams * 4 + fatGrams * 9)
                if calculatedCals != dailyCalories {
                    HStack {
                        Image(systemName: "exclamationmark.triangle")
                            .foregroundColor(.gainsWarning)
                        Text("Macros = \(calculatedCals) kcal")
                            .font(.system(size: 13))
                            .foregroundColor(.gainsWarning)
                    }
                }
            }
            
            Section("Meal Structure") {
                Stepper("Meals per day: \(mealsPerDay)", value: $mealsPerDay, in: 2...6)
                
                Picker("Diet Type", selection: $selectedDietType) {
                    Text("Balanced").tag(nil as DietType?)
                    ForEach(DietType.allCases, id: \.self) { type in
                        Text(type.rawValue).tag(type as DietType?)
                    }
                }
            }
            
            Section("Dietary Restrictions") {
                // Quick add common restrictions
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(commonRestrictions, id: \.self) { restriction in
                            Button {
                                if restrictions.contains(restriction) {
                                    restrictions.removeAll { $0 == restriction }
                                } else {
                                    restrictions.append(restriction)
                                }
                            } label: {
                                Text(restriction)
                                    .font(.system(size: 13))
                                    .foregroundColor(restrictions.contains(restriction) ? .white : .gainsText)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(
                                        restrictions.contains(restriction)
                                            ? Color.gainsSuccess
                                            : Color.gainsCardBackground
                                    )
                                    .cornerRadius(16)
                            }
                        }
                    }
                }
                .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
                
                // Custom restriction input
                HStack {
                    TextField("Add custom restriction", text: $restrictionInput)
                    
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
                
                // Show selected restrictions
                if !restrictions.isEmpty {
                    FlowLayout(spacing: 8) {
                        ForEach(restrictions, id: \.self) { restriction in
                            HStack(spacing: 4) {
                                Text(restriction)
                                    .font(.system(size: 12))
                                Button {
                                    restrictions.removeAll { $0 == restriction }
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.system(size: 12))
                                }
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Color.gainsSuccess)
                            .cornerRadius(12)
                        }
                    }
                }
            }
            
            Section("Additional Notes") {
                TextField("Preferences, allergies, cooking skill...", text: $additionalNotes, axis: .vertical)
                    .lineLimit(3...6)
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
    
    // MARK: - Generated Plan Preview
    private func generatedPlanPreview(_ plan: DietaryPlan) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Success header
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.gainsSuccess)
                    Text("Plan Generated!")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.gainsText)
                }
                
                Text(plan.name)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.gainsText)
                
                if let description = plan.description {
                    Text(description)
                        .font(.system(size: 15))
                        .foregroundColor(.gainsSecondaryText)
                }
                
                // Macro overview
                VStack(alignment: .leading, spacing: 8) {
                    Text("Daily Targets")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.gainsSecondaryText)
                    
                    HStack(spacing: 16) {
                        macroPreviewItem("Cal", value: "\(plan.dailyCalories)", color: .gainsText)
                        macroPreviewItem("P", value: "\(Int(plan.macros.protein))g", color: .gainsPrimary)
                        macroPreviewItem("C", value: "\(Int(plan.macros.carbs))g", color: .gainsSecondary)
                        macroPreviewItem("F", value: "\(Int(plan.macros.fats))g", color: .gainsWarning)
                    }
                }
                .padding()
                .background(Color.gainsCardBackground)
                .cornerRadius(12)
                
                // Days preview
                Text("Weekly Overview")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.gainsText)
                
                ForEach(plan.meals.prefix(3)) { day in
                    DayPreviewCard(day: day)
                }
                
                if plan.meals.count > 3 {
                    Text("+ \(plan.meals.count - 3) more days")
                        .font(.system(size: 14))
                        .foregroundColor(.gainsSecondaryText)
                        .frame(maxWidth: .infinity)
                }
                
                // Action buttons
                VStack(spacing: 12) {
                    Button {
                        savePlan(plan)
                    } label: {
                        Text("Save Plan")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.gainsSuccess)
                            .cornerRadius(12)
                    }
                    
                    Button {
                        generatedPlan = nil
                        errorMessage = nil
                    } label: {
                        Text("Generate Another")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.gainsSuccess)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.gainsCardBackground)
                            .cornerRadius(12)
                    }
                }
            }
            .padding()
        }
    }
    
    private func macroPreviewItem(_ label: String, value: String, color: Color) -> some View {
        VStack(spacing: 2) {
            Text(label)
                .font(.system(size: 12))
                .foregroundColor(.gainsSecondaryText)
            Text(value)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Actions
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
        
        // Update macros based on goal if defaults are still in place
        if profile.macros.protein == 450 && profile.macros.carbs == 202 {
            updateMacrosForGoal(selectedGoal)
        }
    }
    
    private func updateMacrosForGoal(_ goal: FitnessGoal) {
        // Smart macro defaults based on goal
        switch goal {
        case .bulk:
            proteinGrams = Double(dailyCalories) * 0.30 / 4  // 30% protein
            carbGrams = Double(dailyCalories) * 0.45 / 4     // 45% carbs
            fatGrams = Double(dailyCalories) * 0.25 / 9       // 25% fat
        case .cut:
            proteinGrams = Double(dailyCalories) * 0.35 / 4  // 35% protein
            carbGrams = Double(dailyCalories) * 0.30 / 4     // 30% carbs
            fatGrams = Double(dailyCalories) * 0.35 / 9       // 35% fat
        case .maintenance:
            proteinGrams = Double(dailyCalories) * 0.25 / 4  // 25% protein
            carbGrams = Double(dailyCalories) * 0.45 / 4     // 45% carbs
            fatGrams = Double(dailyCalories) * 0.30 / 9       // 30% fat
        case .endurance:
            proteinGrams = Double(dailyCalories) * 0.20 / 4  // 20% protein
            carbGrams = Double(dailyCalories) * 0.55 / 4     // 55% carbs
            fatGrams = Double(dailyCalories) * 0.25 / 9       // 25% fat
        case .strength:
            proteinGrams = Double(dailyCalories) * 0.30 / 4  // 30% protein
            carbGrams = Double(dailyCalories) * 0.40 / 4     // 40% carbs
            fatGrams = Double(dailyCalories) * 0.30 / 9       // 30% fat
        case .recomp:
            proteinGrams = Double(dailyCalories) * 0.30 / 4  // 30% protein
            carbGrams = Double(dailyCalories) * 0.40 / 4     // 40% carbs
            fatGrams = Double(dailyCalories) * 0.30 / 9       // 30% fat
        }
    }
    
    private func generatePlan() {
        isGenerating = true
        errorMessage = nil
        
        Task {
            do {
                let chatGPTService = ChatGPTService()
                let plan = try await chatGPTService.generateDietaryPlan(
                    goal: selectedGoal,
                    dailyCalories: dailyCalories,
                    proteinGrams: proteinGrams,
                    carbGrams: carbGrams,
                    fatGrams: fatGrams,
                    mealsPerDay: mealsPerDay,
                    dietType: selectedDietType,
                    restrictions: restrictions.isEmpty ? nil : restrictions,
                    additionalNotes: additionalNotes.isEmpty ? nil : additionalNotes
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
    
    private func savePlan(_ plan: DietaryPlan) {
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

// MARK: - Day Preview Card
struct DayPreviewCard: View {
    let day: MealPlanDay
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(day.dayName)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.gainsText)
                
                Spacer()
                
                Text("\(day.totalCalories) kcal")
                    .font(.system(size: 13))
                    .foregroundColor(.gainsSecondaryText)
            }
            
            ForEach(day.meals.prefix(3)) { meal in
                HStack {
                    Text(meal.mealType.rawValue)
                        .font(.system(size: 12))
                        .foregroundColor(.gainsSecondaryText)
                        .frame(width: 80, alignment: .leading)
                    
                    Text(meal.name)
                        .font(.system(size: 13))
                        .foregroundColor(.gainsText)
                        .lineLimit(1)
                    
                    Spacer()
                }
            }
        }
        .padding()
        .background(Color.gainsCardBackground)
        .cornerRadius(12)
    }
}

// MARK: - Flow Layout for Tags
struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.width ?? 0, subviews: subviews, spacing: spacing)
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing)
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x,
                                      y: bounds.minY + result.positions[index].y),
                         proposal: .unspecified)
        }
    }
    
    struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []
        
        init(in width: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var rowHeight: CGFloat = 0
            
            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                
                if x + size.width > width && x > 0 {
                    x = 0
                    y += rowHeight + spacing
                    rowHeight = 0
                }
                
                positions.append(CGPoint(x: x, y: y))
                rowHeight = max(rowHeight, size.height)
                x += size.width + spacing
                
                self.size.width = max(self.size.width, x - spacing)
            }
            
            self.size.height = y + rowHeight
        }
    }
}

#Preview {
    GenerateDietaryPlanView(planService: DietaryPlanService())
}

