//
//  OnboardingView.swift
//  Gains
//
//  Created by Rayaan Bokhari on 12/11/25.
//

import SwiftUI
import FirebaseAuth

struct OnboardingView: View {
    @EnvironmentObject var authService: AuthService
    @Environment(\.dismiss) var dismiss
    
    @State private var currentStep = 0
    @State private var isCompleting = false
    
    // User data collection
    @State private var useMetricUnits = false
    @State private var weight: String = ""
    @State private var heightFeet: Int = 5
    @State private var heightInches: Int = 10
    @State private var heightCm: Int = 178
    @State private var gender: String = "Male"
    @State private var fitnessGoal: OnboardingGoal = .maintain
    @State private var activityLevel: OnboardingActivityLevel = .moderate
    @State private var dailyCalories: Int = 2000
    @State private var proteinGoal: Double = 150
    @State private var carbsGoal: Double = 200
    @State private var fatsGoal: Double = 65
    
    // Focus state for keyboard dismissal
    @FocusState private var isWeightFieldFocused: Bool
    
    private let totalSteps = 5
    
    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [Color(hex: "0D0E14"), Color(hex: "0A0A0B")],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            // Decorative elements
            GeometryReader { geo in
                Circle()
                    .fill(Color.gainsPrimary.opacity(0.08))
                    .frame(width: 300, height: 300)
                    .blur(radius: 60)
                    .offset(x: -100, y: -50)
                
                Circle()
                    .fill(Color.gainsAccentPurple.opacity(0.06))
                    .frame(width: 250, height: 250)
                    .blur(radius: 50)
                    .offset(x: geo.size.width - 80, y: geo.size.height - 300)
            }
            
            VStack(spacing: 0) {
                // Progress indicator
                if currentStep > 0 && currentStep < totalSteps {
                    progressBar
                        .padding(.top, 16)
                        .padding(.horizontal, 24)
                }
                
                // Content
                TabView(selection: $currentStep) {
                    welcomeStep.tag(0)
                    unitsStep.tag(1)
                    bodyMeasurementsStep.tag(2)
                    goalsStep.tag(3)
                    completeStep.tag(4)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: currentStep)
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    isWeightFieldFocused = false
                }
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.gainsPrimary)
            }
        }
    }
    
    // MARK: - Progress Bar
    
    private var progressBar: some View {
        HStack(spacing: 8) {
            ForEach(1..<totalSteps, id: \.self) { step in
                Capsule()
                    .fill(step <= currentStep ? Color.gainsPrimary : Color.gainsBgTertiary)
                    .frame(height: 4)
                    .animation(.spring(response: 0.3), value: currentStep)
            }
        }
    }
    
    // MARK: - Step 0: Welcome
    
    private var welcomeStep: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // Icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.gainsPrimary, Color.gainsPrimary.opacity(0.6)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)
                    .shadow(color: Color.gainsPrimary.opacity(0.4), radius: 30, y: 10)
                
                Image(systemName: "figure.strengthtraining.traditional")
                    .font(.system(size: 50, weight: .semibold))
                    .foregroundColor(.white)
            }
            
            VStack(spacing: 16) {
                Text("Welcome to Gains!")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Text("Let's personalize your experience.\nThis will only take a minute.")
                    .font(.system(size: 17))
                    .foregroundColor(.gainsTextSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            
            Spacer()
            
            Button {
                withAnimation {
                    currentStep = 1
                }
            } label: {
                Text("Get Started")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(
                        LinearGradient(
                            colors: [Color.gainsPrimary, Color.gainsPrimary.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(16)
                    .shadow(color: Color.gainsPrimary.opacity(0.4), radius: 15, y: 8)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
    }
    
    // MARK: - Step 1: Units
    
    private var unitsStep: some View {
        VStack(spacing: 32) {
            Spacer()
            
            VStack(spacing: 16) {
                Image(systemName: "ruler")
                    .font(.system(size: 50))
                    .foregroundColor(.gainsPrimary)
                
                Text("Choose Your Units")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                
                Text("This affects how measurements are displayed throughout the app")
                    .font(.system(size: 15))
                    .foregroundColor(.gainsTextSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            VStack(spacing: 16) {
                UnitOptionButton(
                    title: "Imperial",
                    subtitle: "Pounds, Feet & Inches",
                    icon: "flag.fill",
                    isSelected: !useMetricUnits
                ) {
                    useMetricUnits = false
                }
                
                UnitOptionButton(
                    title: "Metric",
                    subtitle: "Kilograms, Centimeters",
                    icon: "globe",
                    isSelected: useMetricUnits
                ) {
                    useMetricUnits = true
                }
            }
            .padding(.horizontal, 24)
            
            Spacer()
            
            navigationButtons(
                backAction: { currentStep = 0 },
                nextAction: { currentStep = 2 }
            )
        }
    }
    
    // MARK: - Step 2: Body Measurements
    
    private var bodyMeasurementsStep: some View {
        ScrollView {
            VStack(spacing: 32) {
                VStack(spacing: 16) {
                    Image(systemName: "figure.stand")
                        .font(.system(size: 50))
                        .foregroundColor(.gainsPrimary)
                    
                    Text("About You")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("This helps us calculate your nutritional needs")
                        .font(.system(size: 15))
                        .foregroundColor(.gainsTextSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 40)
                
                VStack(spacing: 24) {
                    // Gender
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Gender")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.gainsTextSecondary)
                        
                        HStack(spacing: 12) {
                            GenderButton(title: "Male", icon: "figure.stand", isSelected: gender == "Male") {
                                gender = "Male"
                            }
                            GenderButton(title: "Female", icon: "figure.stand.dress", isSelected: gender == "Female") {
                                gender = "Female"
                            }
                            GenderButton(title: "Other", icon: "person.fill", isSelected: gender == "Other") {
                                gender = "Other"
                            }
                        }
                    }
                    
                    // Weight
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Current Weight")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.gainsTextSecondary)
                        
                        HStack {
                            TextField("0", text: $weight)
                                .font(.system(size: 24, weight: .semibold))
                                .foregroundColor(.white)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.center)
                                .frame(width: 100)
                                .padding()
                                .background(Color.gainsBgTertiary)
                                .cornerRadius(12)
                                .focused($isWeightFieldFocused)
                            
                            Text(useMetricUnits ? "kg" : "lbs")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.gainsTextSecondary)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    
                    // Height
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Height")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.gainsTextSecondary)
                        
                        if useMetricUnits {
                            HStack {
                                Picker("", selection: $heightCm) {
                                    ForEach(120...220, id: \.self) { cm in
                                        Text("\(cm)").tag(cm)
                                    }
                                }
                                .pickerStyle(.wheel)
                                .frame(width: 100, height: 120)
                                
                                Text("cm")
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundColor(.gainsTextSecondary)
                            }
                            .frame(maxWidth: .infinity)
                        } else {
                            HStack(spacing: 20) {
                                VStack {
                                    Picker("", selection: $heightFeet) {
                                        ForEach(4...7, id: \.self) { ft in
                                            Text("\(ft)").tag(ft)
                                        }
                                    }
                                    .pickerStyle(.wheel)
                                    .frame(width: 60, height: 120)
                                    
                                    Text("ft")
                                        .font(.system(size: 14))
                                        .foregroundColor(.gainsTextSecondary)
                                }
                                
                                VStack {
                                    Picker("", selection: $heightInches) {
                                        ForEach(0..<12, id: \.self) { inch in
                                            Text("\(inch)").tag(inch)
                                        }
                                    }
                                    .pickerStyle(.wheel)
                                    .frame(width: 60, height: 120)
                                    
                                    Text("in")
                                        .font(.system(size: 14))
                                        .foregroundColor(.gainsTextSecondary)
                                }
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }
                }
                .padding(.horizontal, 24)
                
                navigationButtons(
                    backAction: { currentStep = 1 },
                    nextAction: { currentStep = 3 },
                    nextEnabled: !weight.isEmpty
                )
            }
        }
    }
    
    // MARK: - Step 3: Goals
    
    private var goalsStep: some View {
        ScrollView {
            VStack(spacing: 32) {
                VStack(spacing: 16) {
                    Image(systemName: "target")
                        .font(.system(size: 50))
                        .foregroundColor(.gainsPrimary)
                    
                    Text("Your Goals")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("What do you want to achieve?")
                        .font(.system(size: 15))
                        .foregroundColor(.gainsTextSecondary)
                }
                .padding(.top, 40)
                
                VStack(spacing: 16) {
                    // Fitness Goal
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Fitness Goal")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.gainsTextSecondary)
                        
                        ForEach(OnboardingGoal.allCases, id: \.self) { goal in
                            GoalOptionButton(
                                goal: goal,
                                isSelected: fitnessGoal == goal
                            ) {
                                fitnessGoal = goal
                                calculateRecommendedMacros()
                            }
                        }
                    }
                    
                    // Activity Level
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Activity Level")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.gainsTextSecondary)
                        
                        ForEach(OnboardingActivityLevel.allCases, id: \.self) { level in
                            ActivityOptionButton(
                                level: level,
                                isSelected: activityLevel == level
                            ) {
                                activityLevel = level
                                calculateRecommendedMacros()
                            }
                        }
                    }
                    
                    // Calculated targets
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Your Daily Targets")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.gainsTextSecondary)
                        
                        HStack(spacing: 12) {
                            MacroTargetCard(
                                label: "Calories",
                                value: "\(dailyCalories)",
                                color: .gainsAccentOrange
                            )
                            MacroTargetCard(
                                label: "Protein",
                                value: "\(Int(proteinGoal))g",
                                color: Color(hex: "FF6B6B")
                            )
                        }
                        
                        HStack(spacing: 12) {
                            MacroTargetCard(
                                label: "Carbs",
                                value: "\(Int(carbsGoal))g",
                                color: .gainsPrimary
                            )
                            MacroTargetCard(
                                label: "Fats",
                                value: "\(Int(fatsGoal))g",
                                color: Color(hex: "FFD93D")
                            )
                        }
                        
                        Text("These are calculated based on your profile. You can adjust them later in settings.")
                            .font(.system(size: 12))
                            .foregroundColor(.gainsTextMuted)
                            .multilineTextAlignment(.center)
                            .padding(.top, 8)
                    }
                    .padding()
                    .background(Color.gainsCardSurface)
                    .cornerRadius(16)
                }
                .padding(.horizontal, 24)
                
                navigationButtons(
                    backAction: { currentStep = 2 },
                    nextAction: { currentStep = 4 },
                    nextLabel: "Complete Setup"
                )
            }
        }
        .onAppear {
            calculateRecommendedMacros()
        }
    }
    
    // MARK: - Step 4: Complete
    
    private var completeStep: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // Celebration animation
            ZStack {
                Circle()
                    .fill(Color.gainsSuccess.opacity(0.15))
                    .frame(width: 160, height: 160)
                
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.gainsSuccess, Color.gainsSuccess.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)
                    .shadow(color: Color.gainsSuccess.opacity(0.4), radius: 30, y: 10)
                
                Image(systemName: "checkmark")
                    .font(.system(size: 50, weight: .bold))
                    .foregroundColor(.white)
            }
            
            VStack(spacing: 16) {
                Text("You're All Set!")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Text("Your personalized profile is ready.\nLet's start tracking your gains!")
                    .font(.system(size: 17))
                    .foregroundColor(.gainsTextSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            
            Spacer()
            
            Button {
                completeOnboarding()
            } label: {
                HStack(spacing: 8) {
                    if isCompleting {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text("Start Your Journey")
                            .font(.system(size: 18, weight: .semibold))
                        Image(systemName: "arrow.right")
                            .font(.system(size: 16, weight: .semibold))
                    }
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(
                    LinearGradient(
                        colors: [Color.gainsPrimary, Color.gainsAccentPurple],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(16)
                .shadow(color: Color.gainsPrimary.opacity(0.4), radius: 15, y: 8)
            }
            .disabled(isCompleting)
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
    }
    
    // MARK: - Navigation Buttons
    
    private func navigationButtons(
        backAction: @escaping () -> Void,
        nextAction: @escaping () -> Void,
        nextLabel: String = "Continue",
        nextEnabled: Bool = true
    ) -> some View {
        HStack(spacing: 16) {
            Button {
                withAnimation {
                    backAction()
                }
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.gainsTextSecondary)
                    .frame(width: 56, height: 56)
                    .background(Color.gainsBgTertiary)
                    .cornerRadius(16)
            }
            
            Button {
                withAnimation {
                    nextAction()
                }
            } label: {
                Text(nextLabel)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        nextEnabled ?
                        LinearGradient(
                            colors: [Color.gainsPrimary, Color.gainsPrimary.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        ) :
                        LinearGradient(
                            colors: [Color.gray.opacity(0.4), Color.gray.opacity(0.3)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(16)
            }
            .disabled(!nextEnabled)
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 40)
    }
    
    // MARK: - Helpers
    
    private func calculateRecommendedMacros() {
        guard let weightValue = Double(weight), weightValue > 0 else {
            // Use default values
            dailyCalories = 2000
            proteinGoal = 150
            carbsGoal = 200
            fatsGoal = 65
            return
        }
        
        // Convert to kg if needed
        let weightKg = useMetricUnits ? weightValue : weightValue * 0.453592
        
        // Base Metabolic Rate (Mifflin-St Jeor simplified)
        var bmr: Double
        if gender == "Male" {
            bmr = 10 * weightKg + 6.25 * Double(heightInCm) - 5 * 25 + 5 // Assuming age 25
        } else {
            bmr = 10 * weightKg + 6.25 * Double(heightInCm) - 5 * 25 - 161
        }
        
        // Activity multiplier
        let activityMultiplier: Double
        switch activityLevel {
        case .sedentary: activityMultiplier = 1.2
        case .light: activityMultiplier = 1.375
        case .moderate: activityMultiplier = 1.55
        case .active: activityMultiplier = 1.725
        case .veryActive: activityMultiplier = 1.9
        }
        
        var tdee = bmr * activityMultiplier
        
        // Goal adjustment
        switch fitnessGoal {
        case .lose:
            tdee -= 500 // 500 calorie deficit
        case .maintain:
            break
        case .gain:
            tdee += 300 // 300 calorie surplus
        }
        
        dailyCalories = Int(tdee)
        
        // Macro split based on goal
        let weightLbs = useMetricUnits ? weightValue * 2.20462 : weightValue
        
        switch fitnessGoal {
        case .lose:
            proteinGoal = weightLbs * 1.2 // Higher protein for cutting
            fatsGoal = Double(dailyCalories) * 0.25 / 9
            carbsGoal = (Double(dailyCalories) - proteinGoal * 4 - fatsGoal * 9) / 4
        case .maintain:
            proteinGoal = weightLbs * 1.0
            fatsGoal = Double(dailyCalories) * 0.30 / 9
            carbsGoal = (Double(dailyCalories) - proteinGoal * 4 - fatsGoal * 9) / 4
        case .gain:
            proteinGoal = weightLbs * 1.0
            fatsGoal = Double(dailyCalories) * 0.25 / 9
            carbsGoal = (Double(dailyCalories) - proteinGoal * 4 - fatsGoal * 9) / 4
        }
    }
    
    private var heightInCm: Int {
        if useMetricUnits {
            return heightCm
        } else {
            return Int(Double(heightFeet * 12 + heightInches) * 2.54)
        }
    }
    
    private func completeOnboarding() {
        isCompleting = true
        
        Task {
            guard let user = authService.user else {
                isCompleting = false
                return
            }
            
            // Build height string
            let heightString: String
            if useMetricUnits {
                heightString = "\(heightCm) cm"
            } else {
                heightString = "\(heightFeet) ft \(heightInches) in"
            }
            
            // Create profile with mapped goals
            let profile = UserProfile(
                name: user.displayName ?? "User",
                dateJoined: Date(),
                weight: Double(weight) ?? 150,
                height: heightString,
                gender: gender,
                dailyCaloriesGoal: dailyCalories,
                macros: UserProfile.MacroGoals(
                    protein: proteinGoal,
                    carbs: carbsGoal,
                    fats: fatsGoal
                ),
                waterGoal: 64,
                useMetricUnits: useMetricUnits,
                hasCompletedOnboarding: true,
                primaryGoal: fitnessGoal.fitnessGoal,
                activityLevel: activityLevel.activityLevel
            )
            
            do {
                try await FirestoreService.shared.saveUserProfile(userId: user.uid, profile: profile)
                print("✅ OnboardingView: Profile saved successfully")
                
                // Dismiss onboarding
                await MainActor.run {
                    authService.hasCompletedOnboarding = true
                }
            } catch {
                print("❌ OnboardingView: Error saving profile: \(error)")
            }
            
            isCompleting = false
        }
    }
}

// MARK: - Onboarding-specific goal type (simpler than the full FitnessGoal)

enum OnboardingGoal: String, CaseIterable {
    case lose = "Lose Weight"
    case maintain = "Maintain Weight"
    case gain = "Build Muscle"
    
    var icon: String {
        switch self {
        case .lose: return "arrow.down.circle.fill"
        case .maintain: return "equal.circle.fill"
        case .gain: return "arrow.up.circle.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .lose: return Color.gainsPrimary
        case .maintain: return Color.gainsSuccess
        case .gain: return Color.gainsAccentPurple
        }
    }
    
    var description: String {
        switch self {
        case .lose: return "Calorie deficit for fat loss"
        case .maintain: return "Balance intake and output"
        case .gain: return "Calorie surplus for growth"
        }
    }
    
    // Map to the full FitnessGoal for saving
    var fitnessGoal: FitnessGoal {
        switch self {
        case .lose: return .cut
        case .maintain: return .maintenance
        case .gain: return .bulk
        }
    }
}

enum OnboardingActivityLevel: String, CaseIterable {
    case sedentary = "Sedentary"
    case light = "Lightly Active"
    case moderate = "Moderately Active"
    case active = "Very Active"
    case veryActive = "Extremely Active"
    
    var description: String {
        switch self {
        case .sedentary: return "Little to no exercise"
        case .light: return "Light exercise 1-3 days/week"
        case .moderate: return "Moderate exercise 3-5 days/week"
        case .active: return "Hard exercise 6-7 days/week"
        case .veryActive: return "Very intense daily exercise"
        }
    }
    
    // Map to the full ActivityLevel for saving
    var activityLevel: ActivityLevel {
        switch self {
        case .sedentary: return .sedentary
        case .light: return .lightlyActive
        case .moderate: return .moderatelyActive
        case .active: return .veryActive
        case .veryActive: return .athlete
        }
    }
}

// MARK: - Supporting Views

struct UnitOptionButton: View {
    let title: String
    let subtitle: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(isSelected ? Color.gainsPrimary.opacity(0.2) : Color.gainsBgTertiary)
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: icon)
                        .font(.system(size: 20))
                        .foregroundColor(isSelected ? .gainsPrimary : .gainsTextSecondary)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Text(subtitle)
                        .font(.system(size: 14))
                        .foregroundColor(.gainsTextSecondary)
                }
                
                Spacer()
                
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 24))
                    .foregroundColor(isSelected ? .gainsPrimary : .gainsBgTertiary)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.gainsCardSurface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(isSelected ? Color.gainsPrimary : Color.clear, lineWidth: 2)
                    )
            )
        }
    }
}

struct GenderButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(isSelected ? .gainsPrimary : .gainsTextSecondary)
                
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(isSelected ? .white : .gainsTextSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.gainsPrimary.opacity(0.15) : Color.gainsBgTertiary)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? Color.gainsPrimary : Color.clear, lineWidth: 2)
                    )
            )
        }
    }
}

struct GoalOptionButton: View {
    let goal: OnboardingGoal
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: goal.icon)
                    .font(.system(size: 22))
                    .foregroundColor(goal.color)
                    .frame(width: 44, height: 44)
                    .background(goal.color.opacity(0.15))
                    .cornerRadius(12)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(goal.rawValue)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Text(goal.description)
                        .font(.system(size: 13))
                        .foregroundColor(.gainsTextSecondary)
                }
                
                Spacer()
                
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22))
                    .foregroundColor(isSelected ? goal.color : .gainsBgTertiary)
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.gainsCardSurface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(isSelected ? goal.color : Color.clear, lineWidth: 2)
                    )
            )
        }
    }
}

struct ActivityOptionButton: View {
    let level: OnboardingActivityLevel
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(level.rawValue)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.white)
                    
                    Text(level.description)
                        .font(.system(size: 12))
                        .foregroundColor(.gainsTextSecondary)
                }
                
                Spacer()
                
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20))
                    .foregroundColor(isSelected ? .gainsPrimary : .gainsBgTertiary)
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.gainsPrimary.opacity(0.1) : Color.gainsBgTertiary)
            )
        }
    }
}

struct MacroTargetCard: View {
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 6) {
            Text(label)
                .font(.system(size: 12))
                .foregroundColor(.gainsTextSecondary)
            
            Text(value)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}

#Preview {
    OnboardingView()
        .environmentObject(AuthService.shared)
}

