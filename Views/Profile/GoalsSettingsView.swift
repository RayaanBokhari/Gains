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
                                set: { profileViewModel.profile.primaryGoal = $0 }
                            )) {
                                ForEach(FitnessGoal.allCases, id: \.self) { goal in
                                    Text(goal.rawValue).tag(goal as FitnessGoal?)
                                }
                            }
                            .pickerStyle(.menu)
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

