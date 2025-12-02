//
//  MealTemplatesView.swift
//  Gains
//
//  Created by Rayaan Bokhari on 11/21/25.
//

import SwiftUI
import Combine
import FirebaseAuth

struct MealTemplatesView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel = MealTemplatesViewModel()
    @State private var showCreateTemplate = false
    @State private var templateToEdit: MealTemplate?
    var onTemplateSelected: ((MealTemplate) -> Void)?
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.gainsBackground.ignoresSafeArea()
                
                if viewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .gainsPrimary))
                } else if viewModel.templates.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "bookmark.fill")
                            .font(.system(size: 48))
                            .foregroundColor(.gainsSecondaryText)
                        
                        Text("No Templates Yet")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.gainsText)
                        
                        Text("Save frequently eaten meals as templates for quick logging")
                            .font(.system(size: 14))
                            .foregroundColor(.gainsSecondaryText)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(viewModel.templates) { template in
                                MealTemplateCard(
                                    template: template,
                                    onSelect: {
                                        if let onSelect = onTemplateSelected {
                                            onSelect(template)
                                        }
                                        dismiss()
                                    },
                                    onEdit: {
                                        templateToEdit = template
                                    },
                                    onDelete: {
                                        Task {
                                            await viewModel.deleteTemplate(template)
                                        }
                                    }
                                )
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Meal Templates")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundColor(.gainsPrimary)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showCreateTemplate = true
                    } label: {
                        Image(systemName: "plus")
                            .foregroundColor(.gainsPrimary)
                    }
                }
            }
            .sheet(isPresented: $showCreateTemplate) {
                CreateMealTemplateView(
                    isPresented: $showCreateTemplate,
                    template: nil,
                    onSave: { template in
                        Task {
                            await viewModel.saveTemplate(template)
                        }
                    }
                )
            }
            .sheet(item: $templateToEdit) { template in
                CreateMealTemplateView(
                    isPresented: Binding(
                        get: { templateToEdit != nil },
                        set: { if !$0 { templateToEdit = nil } }
                    ),
                    template: template,
                    onSave: { updatedTemplate in
                        Task {
                            await viewModel.saveTemplate(updatedTemplate)
                            templateToEdit = nil
                        }
                    }
                )
            }
            .task {
                await viewModel.loadTemplates()
            }
        }
    }
}

struct MealTemplateCard: View {
    let template: MealTemplate
    let onSelect: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 16) {
                // Photo or placeholder
                if let photoUrl = template.photoUrl {
                    AsyncImage(url: URL(string: photoUrl)) { image in
                        image
                            .resizable()
                            .scaledToFill()
                    } placeholder: {
                        Color.gainsCardBackground
                    }
                    .frame(width: 60, height: 60)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                } else {
                    Image(systemName: "fork.knife")
                        .font(.system(size: 24))
                        .foregroundColor(.gainsSecondaryText)
                        .frame(width: 60, height: 60)
                        .background(Color.gainsCardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                
                // Template info
                VStack(alignment: .leading, spacing: 4) {
                    Text(template.name)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.gainsText)
                    
                    HStack(spacing: 12) {
                        Label("\(template.calories)", systemImage: "flame.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.gainsSecondaryText)
                        
                        Label("\(Int(template.protein))g", systemImage: "p.circle.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.gainsSecondaryText)
                    }
                }
                
                Spacer()
                
                // Actions
                Menu {
                    Button(action: onEdit) {
                        Label("Edit", systemImage: "pencil")
                    }
                    
                    Button(role: .destructive, action: onDelete) {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .foregroundColor(.gainsSecondaryText)
                        .padding(8)
                }
            }
            .padding()
            .background(Color.gainsCardBackground)
            .cornerRadius(16)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

@MainActor
class MealTemplatesViewModel: ObservableObject {
    @Published var templates: [MealTemplate] = []
    @Published var isLoading = false
    
    private let firestore = FirestoreService.shared
    private let auth = AuthService.shared
    
    func loadTemplates() async {
        guard let user = auth.user else { return }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            templates = try await firestore.fetchMealTemplates(userId: user.uid)
        } catch {
            print("Error loading templates: \(error)")
        }
    }
    
    func saveTemplate(_ template: MealTemplate) async {
        guard let user = auth.user else { return }
        
        do {
            try await firestore.saveMealTemplate(userId: user.uid, template: template)
            await loadTemplates()
        } catch {
            print("Error saving template: \(error)")
        }
    }
    
    func deleteTemplate(_ template: MealTemplate) async {
        guard let user = auth.user,
              let templateId = template.mealTemplateId else { return }
        
        do {
            try await firestore.deleteMealTemplate(userId: user.uid, templateId: templateId)
            await loadTemplates()
        } catch {
            print("Error deleting template: \(error)")
        }
    }
}

struct CreateMealTemplateView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var isPresented: Bool
    let template: MealTemplate?
    let onSave: (MealTemplate) -> Void
    
    @State private var name: String = ""
    @State private var calories: String = ""
    @State private var protein: String = ""
    @State private var carbs: String = ""
    @State private var fats: String = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.gainsBackground.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Template Name")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.gainsSecondaryText)
                            
                            TextField("e.g., Chicken Burrito", text: $name)
                                .textFieldStyle(.plain)
                                .padding()
                                .background(Color.gainsCardBackground)
                                .cornerRadius(12)
                                .foregroundColor(.gainsText)
                        }
                        .padding(.horizontal)
                        
                        VStack(spacing: 12) {
                            TemplateNutritionInputRow(label: "Calories", value: $calories, unit: "kcal")
                            TemplateNutritionInputRow(label: "Protein", value: $protein, unit: "g")
                            TemplateNutritionInputRow(label: "Carbs", value: $carbs, unit: "g")
                            TemplateNutritionInputRow(label: "Fats", value: $fats, unit: "g")
                        }
                        .padding(.horizontal)
                    }
                    .padding(.top)
                }
            }
            .navigationTitle(template == nil ? "New Template" : "Edit Template")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                    .foregroundColor(.gainsPrimary)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveTemplate()
                    }
                    .foregroundColor(.gainsPrimary)
                    .disabled(!isValid)
                }
            }
        }
        .onAppear {
            if let template = template {
                name = template.name
                calories = String(template.calories)
                protein = String(format: "%.1f", template.protein)
                carbs = String(format: "%.1f", template.carbs)
                fats = String(format: "%.1f", template.fats)
            }
        }
    }
    
    private var isValid: Bool {
        !name.isEmpty &&
        Int(calories) != nil &&
        Double(protein) != nil &&
        Double(carbs) != nil &&
        Double(fats) != nil
    }
    
    private func saveTemplate() {
        guard let cal = Int(calories),
              let pro = Double(protein),
              let car = Double(carbs),
              let fat = Double(fats) else { return }
        
        let newTemplate = MealTemplate(
            id: template?.id ?? UUID(),
            name: name,
            calories: cal,
            protein: pro,
            carbs: car,
            fats: fat,
            photoUrl: template?.photoUrl,
            mealTemplateId: template?.mealTemplateId,
            createdAt: template?.createdAt ?? Date()
        )
        
        onSave(newTemplate)
        isPresented = false
    }
}

// File-private helper struct for nutrition input
private struct TemplateNutritionInputRow: View {
    let label: String
    @Binding var value: String
    let unit: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.gainsText)
                .frame(width: 80, alignment: .leading)
            
            TextField("0", text: $value)
                .textFieldStyle(.plain)
                .keyboardType(.decimalPad)
                .padding(8)
                .background(Color.gainsBackground)
                .cornerRadius(8)
                .foregroundColor(.gainsText)
                .multilineTextAlignment(.trailing)
            
            Text(unit)
                .font(.system(size: 12))
                .foregroundColor(.gainsSecondaryText)
                .frame(width: 40, alignment: .leading)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.gainsCardBackground)
        .cornerRadius(8)
    }
}

