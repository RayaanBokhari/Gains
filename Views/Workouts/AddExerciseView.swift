//
//  AddExerciseView.swift
//  Gains
//
//  Created by Rayaan Bokhari on 11/20/25.
//

import SwiftUI

struct AddExerciseView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var templateService = ExerciseTemplateService()
    
    // Either viewModel or closure will be used
    private var viewModel: WorkoutViewModel?
    private var onExerciseAdded: ((Exercise) -> Void)?
    
    @State private var searchText = ""
    @State private var selectedCategory: ExerciseCategory? = nil
    @State private var showCustomExercise = false
    @State private var customExerciseName = ""
    
    // Initializer for WorkoutViewModel usage (active workout)
    init(viewModel: WorkoutViewModel) {
        self.viewModel = viewModel
        self.onExerciseAdded = nil
    }
    
    // Initializer for closure-based usage (edit mode)
    init(onExerciseAdded: @escaping (Exercise) -> Void) {
        self.viewModel = nil
        self.onExerciseAdded = onExerciseAdded
    }
    
    var filteredTemplates: [ExerciseTemplate] {
        var templates = templateService.templates
        
        if let category = selectedCategory {
            templates = templates.filter { $0.category == category }
        }
        
        if !searchText.isEmpty {
            templates = templates.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
        
        return templates
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.gainsBackground.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Search Bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gainsSecondaryText)
                        
                        TextField("Search exercises...", text: $searchText)
                            .textFieldStyle(.plain)
                            .foregroundColor(.gainsText)
                    }
                    .padding()
                    .background(Color.gainsCardBackground)
                    .cornerRadius(12)
                    .padding()
                    
                    // Category Filter
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            CategoryPill(
                                title: "All",
                                isSelected: selectedCategory == nil,
                                action: { selectedCategory = nil }
                            )
                            
                            ForEach(ExerciseCategory.allCases, id: \.self) { category in
                                CategoryPill(
                                    title: category.rawValue,
                                    isSelected: selectedCategory == category,
                                    action: { selectedCategory = category }
                                )
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.bottom, 8)
                    
                    // Exercise List
                    ScrollView {
                        LazyVStack(spacing: 8) {
                            // Custom Exercise Option
                            Button {
                                showCustomExercise = true
                            } label: {
                                HStack {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.system(size: 24))
                                        .foregroundColor(.gainsPrimary)
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Create Custom Exercise")
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundColor(.gainsText)
                                        Text("Add your own exercise")
                                            .font(.system(size: 12))
                                            .foregroundColor(.gainsSecondaryText)
                                    }
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 14))
                                        .foregroundColor(.gainsSecondaryText)
                                }
                                .padding()
                                .background(Color.gainsCardBackground)
                                .cornerRadius(12)
                            }
                            
                            if filteredTemplates.isEmpty {
                                VStack(spacing: 12) {
                                    Image(systemName: "magnifyingglass")
                                        .font(.system(size: 32))
                                        .foregroundColor(.gainsSecondaryText)
                                    Text("No exercises found")
                                        .font(.system(size: 16))
                                        .foregroundColor(.gainsSecondaryText)
                                }
                                .padding(.top, 40)
                            } else {
                                ForEach(filteredTemplates) { template in
                                    ExerciseTemplateRow(template: template) {
                                        addExercise(from: template)
                                    }
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Add Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.gainsPrimary)
                }
            }
            .alert("Custom Exercise", isPresented: $showCustomExercise) {
                TextField("Exercise name", text: $customExerciseName)
                Button("Cancel", role: .cancel) {
                    customExerciseName = ""
                }
                Button("Add") {
                    if !customExerciseName.isEmpty {
                        addCustomExercise(name: customExerciseName)
                        customExerciseName = ""
                    }
                }
            } message: {
                Text("Enter a name for your exercise")
            }
        }
    }
    
    private func addExercise(from template: ExerciseTemplate) {
        let exercise = Exercise(
            name: template.name,
            sets: [ExerciseSet()] // Start with one empty set
        )
        
        if let onExerciseAdded = onExerciseAdded {
            // Closure-based callback (edit mode)
            onExerciseAdded(exercise)
        } else {
            // ViewModel-based (active workout mode)
            viewModel?.addExercise(exercise)
        }
        dismiss()
    }
    
    private func addCustomExercise(name: String) {
        let exercise = Exercise(
            name: name,
            sets: [ExerciseSet()]
        )
        
        if let onExerciseAdded = onExerciseAdded {
            // Closure-based callback (edit mode)
            onExerciseAdded(exercise)
        } else {
            // ViewModel-based (active workout mode)
            viewModel?.addExercise(exercise)
        }
        dismiss()
    }
}

struct CategoryPill: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(isSelected ? .white : .gainsSecondaryText)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.gainsPrimary : Color.gainsCardBackground)
                .cornerRadius(20)
        }
    }
}

struct ExerciseTemplateRow: View {
    let template: ExerciseTemplate
    let onAdd: () -> Void
    
    var body: some View {
        Button(action: onAdd) {
            HStack(spacing: 12) {
                // Icon based on category
                Image(systemName: iconForCategory(template.category))
                    .font(.system(size: 20))
                    .foregroundColor(.gainsPrimary)
                    .frame(width: 40, height: 40)
                    .background(Color.gainsPrimary.opacity(0.15))
                    .cornerRadius(10)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(template.name)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.gainsText)
                    
                    HStack(spacing: 8) {
                        Text(template.category.rawValue)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.gainsPrimary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.gainsPrimary.opacity(0.15))
                            .cornerRadius(4)
                        
                        if !template.muscleGroups.isEmpty {
                            Text(template.muscleGroups.map { $0.rawValue }.joined(separator: ", "))
                                .font(.system(size: 11))
                                .foregroundColor(.gainsSecondaryText)
                                .lineLimit(1)
                        }
                    }
                }
                
                Spacer()
                
                Image(systemName: "plus.circle")
                    .font(.system(size: 22))
                    .foregroundColor(.gainsPrimary)
            }
            .padding()
            .background(Color.gainsCardBackground)
            .cornerRadius(12)
        }
    }
    
    private func iconForCategory(_ category: ExerciseCategory) -> String {
        switch category {
        case .strength:
            return "dumbbell.fill"
        case .cardio:
            return "heart.fill"
        case .flexibility:
            return "figure.flexibility"
        case .other:
            return "figure.mixed.cardio"
        }
    }
}

#Preview {
    AddExerciseView(onExerciseAdded: { exercise in
        print("Added exercise: \(exercise.name)")
    })
}
