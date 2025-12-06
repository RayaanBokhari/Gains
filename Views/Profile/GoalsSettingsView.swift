//
//  GoalsSettingsView.swift
//  Gains
//
//  Created by Rayaan Bokhari on 12/20/25.
//

import SwiftUI

struct GoalsSettingsView: View {
    @ObservedObject var profileViewModel: ProfileViewModel
    @Environment(\.dismiss) var dismiss
    @State private var isSaving = false
    @State private var showMacroInfo = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.gainsBackground.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Primary Goal
                        SectionView(title: "Primary Goal") {
                            Picker("Goal", selection: Binding(
                                get: { profileViewModel.profile.primaryGoal ?? .maintenance },
                                set: { newGoal in
                                    profileViewModel.profile.primaryGoal = newGoal
                                    // Auto-update macros when goal changes
                                    updateMacrosForGoal(newGoal)
                                }
                            )) {
                                ForEach(FitnessGoal.allCases, id: \.self) { goal in
                                    Text(goal.rawValue).tag(goal as FitnessGoal?)
                                }
                            }
                            .pickerStyle(.menu)
                        }
                        
                        // Daily Calories
                        SectionView(title: "Daily Calories") {
                            HStack {
                                Text("Calorie Goal")
                                Spacer()
                                TextField("Calories", value: Binding(
                                    get: { profileViewModel.profile.dailyCaloriesGoal },
                                    set: { newValue in
                                        profileViewModel.profile.dailyCaloriesGoal = newValue
                                        // Recalculate macros when calories change
                                        if let goal = profileViewModel.profile.primaryGoal {
                                            updateMacrosForGoal(goal)
                                        }
                                    }
                                ), format: .number)
                                .keyboardType(.numberPad)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 100)
                                Text("kcal")
                                    .foregroundColor(.gainsSecondaryText)
                            }
                        }
                        
                        // Macro Goals
                        SectionView(title: "Macro Goals") {
                            VStack(spacing: 16) {
                                // Info button
                                HStack {
                                    Text("Customize your daily macro targets")
                                        .font(.system(size: 13))
                                        .foregroundColor(.gainsSecondaryText)
                                    Spacer()
                                    Button {
                                        showMacroInfo = true
                                    } label: {
                                        Image(systemName: "info.circle")
                                            .foregroundColor(.gainsPrimary)
                                    }
                                }
                                
                                // Protein
                                MacroInputRow(
                                    label: "Protein",
                                    value: Binding(
                                        get: { profileViewModel.profile.macros.protein },
                                        set: { profileViewModel.profile.macros.protein = $0 }
                                    ),
                                    color: Color(hex: "FF6B6B"),
                                    caloriesPerGram: 4,
                                    totalCalories: profileViewModel.profile.dailyCaloriesGoal
                                )
                                
                                // Carbs
                                MacroInputRow(
                                    label: "Carbs",
                                    value: Binding(
                                        get: { profileViewModel.profile.macros.carbs },
                                        set: { profileViewModel.profile.macros.carbs = $0 }
                                    ),
                                    color: .gainsPrimary,
                                    caloriesPerGram: 4,
                                    totalCalories: profileViewModel.profile.dailyCaloriesGoal
                                )
                                
                                // Fats
                                MacroInputRow(
                                    label: "Fats",
                                    value: Binding(
                                        get: { profileViewModel.profile.macros.fats },
                                        set: { profileViewModel.profile.macros.fats = $0 }
                                    ),
                                    color: Color(hex: "FFD93D"),
                                    caloriesPerGram: 9,
                                    totalCalories: profileViewModel.profile.dailyCaloriesGoal
                                )
                                
                                // Total calories from macros
                                Divider()
                                
                                HStack {
                                    Text("Total from Macros")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.gainsText)
                                    Spacer()
                                    let totalMacroCals = Int(profileViewModel.profile.macros.protein * 4 +
                                                            profileViewModel.profile.macros.carbs * 4 +
                                                            profileViewModel.profile.macros.fats * 9)
                                    Text("\(totalMacroCals) kcal")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(abs(totalMacroCals - profileViewModel.profile.dailyCaloriesGoal) <= 50 ? .gainsAccentGreen : .gainsAccentOrange)
                                }
                                
                                // Reset to defaults button
                                Button {
                                    if let goal = profileViewModel.profile.primaryGoal {
                                        updateMacrosForGoal(goal)
                                    } else {
                                        updateMacrosForGoal(.maintenance)
                                    }
                                } label: {
                                    HStack {
                                        Image(systemName: "arrow.counterclockwise")
                                        Text("Reset to Recommended")
                                    }
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.gainsPrimary)
                                }
                                .padding(.top, 8)
                            }
                        }
                        
                        // Target Weight & Date
                        SectionView(title: "Target Weight") {
                            VStack(spacing: 16) {
                                HStack {
                                    Text("Target Weight")
                                    Spacer()
                                    TextField("Weight", value: Binding(
                                        get: { profileViewModel.profile.targetWeight ?? profileViewModel.profile.weight },
                                        set: { profileViewModel.profile.targetWeight = $0 }
                                    ), format: .number)
                                    .keyboardType(.decimalPad)
                                    .textFieldStyle(.roundedBorder)
                                    .frame(width: 100)
                                    Text(profileViewModel.profile.useMetricUnits ? "kg" : "lbs")
                                }
                                
                                DatePicker("Target Date", selection: Binding(
                                    get: { profileViewModel.profile.targetDate ?? Calendar.current.date(byAdding: .month, value: 3, to: Date())! },
                                    set: { profileViewModel.profile.targetDate = $0 }
                                ), displayedComponents: .date)
                            }
                        }
                        
                        // Training Experience
                        SectionView(title: "Training Experience") {
                            Picker("Experience", selection: Binding(
                                get: { profileViewModel.profile.trainingExperience ?? .beginner },
                                set: { profileViewModel.profile.trainingExperience = $0 }
                            )) {
                                ForEach(TrainingExperience.allCases, id: \.self) { exp in
                                    Text(exp.rawValue).tag(exp as TrainingExperience?)
                                }
                            }
                            .pickerStyle(.menu)
                        }
                        
                        // Training Split
                        SectionView(title: "Training Split") {
                            Picker("Split", selection: Binding(
                                get: { profileViewModel.profile.trainingSplit ?? .fullBody },
                                set: { profileViewModel.profile.trainingSplit = $0 }
                            )) {
                                ForEach(TrainingSplit.allCases, id: \.self) { split in
                                    Text(split.rawValue).tag(split as TrainingSplit?)
                                }
                            }
                            .pickerStyle(.menu)
                        }
                        
                        // Activity Level
                        SectionView(title: "Activity Level") {
                            Picker("Activity", selection: Binding(
                                get: { profileViewModel.profile.activityLevel ?? .moderatelyActive },
                                set: { profileViewModel.profile.activityLevel = $0 }
                            )) {
                                ForEach(ActivityLevel.allCases, id: \.self) { level in
                                    Text(level.rawValue).tag(level as ActivityLevel?)
                                }
                            }
                            .pickerStyle(.menu)
                        }
                        
                        // Diet Type
                        SectionView(title: "Diet Type") {
                            Picker("Diet", selection: Binding(
                                get: { profileViewModel.profile.dietType ?? .omnivore },
                                set: { profileViewModel.profile.dietType = $0 }
                            )) {
                                ForEach(DietType.allCases, id: \.self) { diet in
                                    Text(diet.rawValue).tag(diet as DietType?)
                                }
                            }
                            .pickerStyle(.menu)
                        }
                        
                        // Meal Pattern
                        SectionView(title: "Meal Pattern") {
                            Picker("Pattern", selection: Binding(
                                get: { profileViewModel.profile.mealPattern ?? .threeMeals },
                                set: { profileViewModel.profile.mealPattern = $0 }
                            )) {
                                ForEach(MealPattern.allCases, id: \.self) { pattern in
                                    Text(pattern.rawValue).tag(pattern as MealPattern?)
                                }
                            }
                            .pickerStyle(.menu)
                        }
                        
                        // Coaching Style
                        SectionView(title: "Coaching Style") {
                            Picker("Style", selection: Binding(
                                get: { profileViewModel.profile.coachingStyle ?? .balanced },
                                set: { profileViewModel.profile.coachingStyle = $0 }
                            )) {
                                ForEach(CoachingStyle.allCases, id: \.self) { style in
                                    Text(style.rawValue).tag(style as CoachingStyle?)
                                }
                            }
                            .pickerStyle(.menu)
                        }
                        
                        // Detail Preference
                        SectionView(title: "Detail Preference") {
                            Picker("Detail", selection: Binding(
                                get: { profileViewModel.profile.detailPreference ?? .moderate },
                                set: { profileViewModel.profile.detailPreference = $0 }
                            )) {
                                ForEach(DetailPreference.allCases, id: \.self) { pref in
                                    Text(pref.rawValue).tag(pref as DetailPreference?)
                                }
                            }
                            .pickerStyle(.menu)
                        }
                        
                        // Preferred Training Days
                        SectionView(title: "Preferred Training Days") {
                            VStack(alignment: .leading, spacing: 8) {
                                ForEach(Weekday.allCases, id: \.self) { day in
                                    Toggle(day.rawValue.capitalized, isOn: Binding(
                                        get: {
                                            profileViewModel.profile.preferredTrainingDays?.contains(day) ?? false
                                        },
                                        set: { isSelected in
                                            var days = profileViewModel.profile.preferredTrainingDays ?? []
                                            if isSelected {
                                                if !days.contains(day) {
                                                    days.append(day)
                                                }
                                            } else {
                                                days.removeAll { $0 == day }
                                            }
                                            profileViewModel.profile.preferredTrainingDays = days.isEmpty ? nil : days
                                        }
                                    ))
                                    .toggleStyle(SwitchToggleStyle(tint: .gainsPrimary))
                                }
                            }
                        }
                        
                        // Allergies & Dislikes
                        SectionView(title: "Dietary Restrictions") {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Allergies (comma-separated)")
                                    .font(.system(size: 14))
                                    .foregroundColor(.gainsSecondaryText)
                                TextField("e.g., peanuts, shellfish", text: Binding(
                                    get: { (profileViewModel.profile.allergies ?? []).joined(separator: ", ") },
                                    set: { profileViewModel.profile.allergies = $0.isEmpty ? nil : $0.split(separator: ",").map { String($0).trimmingCharacters(in: .whitespaces) } }
                                ))
                                .textFieldStyle(.roundedBorder)
                                
                                Text("Disliked Foods (comma-separated)")
                                    .font(.system(size: 14))
                                    .foregroundColor(.gainsSecondaryText)
                                TextField("e.g., broccoli, mushrooms", text: Binding(
                                    get: { (profileViewModel.profile.dislikedFoods ?? []).joined(separator: ", ") },
                                    set: { profileViewModel.profile.dislikedFoods = $0.isEmpty ? nil : $0.split(separator: ",").map { String($0).trimmingCharacters(in: .whitespaces) } }
                                ))
                                .textFieldStyle(.roundedBorder)
                            }
                        }
                        
                        // Save Button
                        Button {
                            Task {
                                isSaving = true
                                await profileViewModel.saveProfile()
                                isSaving = false
                                dismiss()
                            }
                        } label: {
                            Text("Save Goals")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.gainsPrimary)
                                .cornerRadius(12)
                        }
                        .disabled(isSaving)
                        .padding(.horizontal)
                        .padding(.bottom)
                    }
                    .padding()
                }
            }
            .navigationTitle("Goals & Preferences")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.gainsPrimary)
                }
            }
            .alert("Macro Information", isPresented: $showMacroInfo) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Protein & Carbs = 4 calories per gram\nFats = 9 calories per gram\n\nRecommended macros are calculated based on your goal:\n\n• Bulk: Higher carbs for energy\n• Cut: Higher protein to preserve muscle\n• Maintenance: Balanced approach\n• Strength: Higher protein & carbs")
            }
        }
    }
    
    // MARK: - Calculate Default Macros Based on Goal
    private func updateMacrosForGoal(_ goal: FitnessGoal) {
        let calories = Double(profileViewModel.profile.dailyCaloriesGoal)
        
        // Macro percentages based on goal
        let (proteinPct, carbsPct, fatsPct): (Double, Double, Double) = {
            switch goal {
            case .bulk:
                return (0.25, 0.50, 0.25) // 25% protein, 50% carbs, 25% fats
            case .cut:
                return (0.40, 0.35, 0.25) // 40% protein, 35% carbs, 25% fats
            case .recomp:
                return (0.35, 0.40, 0.25) // 35% protein, 40% carbs, 25% fats
            case .maintenance:
                return (0.30, 0.40, 0.30) // 30% protein, 40% carbs, 30% fats
            case .strength:
                return (0.30, 0.45, 0.25) // 30% protein, 45% carbs, 25% fats
            case .endurance:
                return (0.20, 0.55, 0.25) // 20% protein, 55% carbs, 25% fats
            }
        }()
        
        // Calculate grams (protein/carbs = 4 cal/g, fats = 9 cal/g)
        let proteinGrams = (calories * proteinPct) / 4
        let carbsGrams = (calories * carbsPct) / 4
        let fatsGrams = (calories * fatsPct) / 9
        
        // Update profile macros
        profileViewModel.profile.macros.protein = round(proteinGrams)
        profileViewModel.profile.macros.carbs = round(carbsGrams)
        profileViewModel.profile.macros.fats = round(fatsGrams)
    }
}

// MARK: - Macro Input Row
struct MacroInputRow: View {
    let label: String
    @Binding var value: Double
    let color: Color
    let caloriesPerGram: Int
    let totalCalories: Int
    
    private var percentage: Int {
        guard totalCalories > 0 else { return 0 }
        let calories = value * Double(caloriesPerGram)
        return Int((calories / Double(totalCalories)) * 100)
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Color indicator
            Circle()
                .fill(color)
                .frame(width: 12, height: 12)
            
            Text(label)
                .font(.system(size: 15))
                .foregroundColor(.gainsText)
                .frame(width: 60, alignment: .leading)
            
            Spacer()
            
            // Percentage badge
            Text("\(percentage)%")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.gainsSecondaryText)
                .frame(width: 40)
            
            // Input field
            TextField("0", value: $value, format: .number)
                .keyboardType(.numberPad)
                .textFieldStyle(.roundedBorder)
                .frame(width: 70)
            
            Text("g")
                .font(.system(size: 14))
                .foregroundColor(.gainsSecondaryText)
        }
    }
}

struct SectionView<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.gainsText)
            
            content
                .padding()
                .background(Color.gainsCardBackground)
                .cornerRadius(12)
        }
    }
}

#Preview {
    GoalsSettingsView(profileViewModel: ProfileViewModel())
}
