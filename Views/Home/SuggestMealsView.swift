//
//  SuggestMealsView.swift
//  Gains
//
//  Created by Rayaan Bokhari on 12/10/25.
//

import SwiftUI

struct SuggestMealsView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var profileViewModel = ProfileViewModel()

    // Current day status (passed in from HomeView)
    let remainingCalories: Int
    let remainingProtein: Double
    let remainingCarbs: Double
    let remainingFats: Double
    
    // Callback to save suggestions
    var onSave: (([PlannedMeal]) -> Void)?

    // Form inputs
    @State private var mealsRemaining: Int = 2
    @State private var additionalNotes = ""

    // State
    @State private var isGenerating = false
    @State private var suggestedMeals: [PlannedMeal] = []
    @State private var errorMessage: String?

    var body: some View {
        NavigationView {
            ZStack {
                Color.gainsBackground.ignoresSafeArea()

                if isGenerating {
                    loadingState
                } else if !suggestedMeals.isEmpty {
                    suggestionsView
                } else {
                    inputForm
                }
            }
            .navigationTitle("Suggest Meals")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                if suggestedMeals.isEmpty && !isGenerating {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            generateSuggestions()
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "sparkles")
                                Text("Suggest")
                            }
                        }
                        .disabled(isGenerating || remainingCalories <= 0)
                    }
                }
            }
            .onAppear {
                Task {
                    await profileViewModel.loadProfile()
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

            Text("Finding the perfect meals for you...")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.gainsText)
                .multilineTextAlignment(.center)
        }
        .padding()
    }

    // MARK: - Input Form
    private var inputForm: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Remaining Macros Card
                VStack(alignment: .leading, spacing: 12) {
                    Text("Remaining Today")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.gainsText)

                    HStack(spacing: 16) {
                        macroItem("Cal", value: "\(remainingCalories)", color: .gainsPrimary)
                        macroItem("P", value: "\(Int(remainingProtein))g", color: Color(hex: "FF6B6B"))
                        macroItem("C", value: "\(Int(remainingCarbs))g", color: .gainsPrimary)
                        macroItem("F", value: "\(Int(remainingFats))g", color: Color(hex: "FFD93D"))
                    }
                }
                .padding()
                .background(Color.gainsCardBackground)
                .cornerRadius(12)

                // Meals Count
                VStack(alignment: .leading, spacing: 8) {
                    Text("How many meals?")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.gainsText)

                    HStack(spacing: 12) {
                        ForEach(1...4, id: \.self) { count in
                            Button {
                                mealsRemaining = count
                            } label: {
                                Text("\(count)")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(mealsRemaining == count ? .white : .gainsText)
                                    .frame(width: 50, height: 50)
                                    .background(mealsRemaining == count ? Color.gainsSuccess : Color.gainsCardBackground)
                                    .cornerRadius(12)
                            }
                        }
                    }
                }

                // Additional Notes
                VStack(alignment: .leading, spacing: 8) {
                    Text("Any preferences?")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.gainsText)

                    TextField("e.g., quick to make, high protein, vegetarian...", text: $additionalNotes, axis: .vertical)
                        .lineLimit(2...4)
                        .padding()
                        .background(Color.gainsCardBackground)
                        .cornerRadius(12)
                }

                if let error = errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.system(size: 14))
                        .padding()
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(8)
                }

                Spacer(minLength: 100)
            }
            .padding()
        }
    }

    // MARK: - Suggestions View
    private var suggestionsView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Success Header
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.gainsSuccess)
                    Text("Here's what you could eat!")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.gainsText)
                }
                .padding(.bottom, 8)

                // Meal Cards
                ForEach(suggestedMeals) { meal in
                    MealSuggestionCard(meal: meal)
                }

                // Action Buttons
                VStack(spacing: 12) {
                    Button {
                        suggestedMeals = []
                        errorMessage = nil
                    } label: {
                        Text("Generate Different Suggestions")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.gainsSuccess)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.gainsCardBackground)
                            .cornerRadius(12)
                    }

                    Button {
                        onSave?(suggestedMeals)
                        dismiss()
                    } label: {
                        Text("Save & Done")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.gainsSuccess)
                            .cornerRadius(12)
                    }
                }
                .padding(.top, 16)
            }
            .padding()
        }
    }

    private func macroItem(_ label: String, value: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.system(size: 12))
                .foregroundColor(.gainsSecondaryText)
            Text(value)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Actions
    private func generateSuggestions() {
        isGenerating = true
        errorMessage = nil

        Task {
            do {
                let chatGPTService = ChatGPTService()
                let meals = try await chatGPTService.generateTodaysMeals(
                    remainingCalories: remainingCalories,
                    remainingProtein: remainingProtein,
                    remainingCarbs: remainingCarbs,
                    remainingFats: remainingFats,
                    mealsRemaining: mealsRemaining,
                    dietType: profileViewModel.profile.dietType,
                    restrictions: profileViewModel.profile.allergies,
                    additionalNotes: additionalNotes.isEmpty ? nil : additionalNotes
                )

                await MainActor.run {
                    suggestedMeals = meals
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
}

// MARK: - Meal Suggestion Card
struct MealSuggestionCard: View {
    let meal: PlannedMeal

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Text(meal.name)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.gainsText)

                Spacer()

                Text("\(meal.calories) cal")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.gainsSecondaryText)
            }

            // Macros
            HStack(spacing: 16) {
                Text("P: \(Int(meal.protein))g")
                    .font(.system(size: 13))
                    .foregroundColor(Color(hex: "FF6B6B"))
                Text("C: \(Int(meal.carbs))g")
                    .font(.system(size: 13))
                    .foregroundColor(.gainsPrimary)
                Text("F: \(Int(meal.fats))g")
                    .font(.system(size: 13))
                    .foregroundColor(Color(hex: "FFD93D"))

                if let prepTime = meal.prepTime {
                    Spacer()
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.system(size: 11))
                        Text("\(prepTime) min")
                            .font(.system(size: 12))
                    }
                    .foregroundColor(.gainsSecondaryText)
                }
            }

            // Foods
            VStack(alignment: .leading, spacing: 6) {
                ForEach(meal.foods) { food in
                    HStack {
                        Text("• \(food.name)")
                            .font(.system(size: 14))
                            .foregroundColor(.gainsText)
                        Spacer()
                        Text(food.quantity)
                            .font(.system(size: 13))
                            .foregroundColor(.gainsSecondaryText)
                    }
                }
            }

            // Notes
            if let notes = meal.notes, !notes.isEmpty {
                Text(notes)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(.gainsSecondaryText)
                    .italic()
            }
        }
        .padding()
        .background(Color.gainsCardBackground)
        .cornerRadius(12)
    }
}

#Preview {
    SuggestMealsView(
        remainingCalories: 1200,
        remainingProtein: 80,
        remainingCarbs: 120,
        remainingFats: 40
    )
}

