//
//  EditMealView.swift
//  Gains
//
//  Created by Rayaan Bokhari on 11/21/25.
//

import SwiftUI
import PhotosUI
import FirebaseAuth
import UIKit

struct EditMealView: View {
    @Environment(\.dismiss) var dismiss
    
    @FocusState private var focusedField: Field?
    
    @Binding var isPresented: Bool
    let food: Food
    let onMealUpdated: (Food) -> Void
    let selectedDate: Date
    
    @State private var foodName: String
    @State private var calories: String
    @State private var protein: String
    @State private var carbs: String
    @State private var fats: String
    @State private var selectedImage: UIImage?
    @State private var showImagePicker = false
    @State private var isSaving = false
    @State private var errorMessage: String?
    @State private var currentPhotoUrl: String?
    @State private var shouldRemovePhoto = false
    
    enum Field {
        case name, calories, protein, carbs, fats
    }
    
    init(isPresented: Binding<Bool>, food: Food, onMealUpdated: @escaping (Food) -> Void, selectedDate: Date) {
        self._isPresented = isPresented
        self.food = food
        self.onMealUpdated = onMealUpdated
        self.selectedDate = selectedDate
        
        // Initialize state with current food values
        _foodName = State(initialValue: food.name)
        _calories = State(initialValue: String(food.calories))
        _protein = State(initialValue: String(format: "%.1f", food.protein))
        _carbs = State(initialValue: String(format: "%.1f", food.carbs))
        _fats = State(initialValue: String(format: "%.1f", food.fats))
        _currentPhotoUrl = State(initialValue: food.photoUrl)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.gainsBackground.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Photo Display/Edit Section
                        VStack(spacing: 12) {
                            if let image = selectedImage {
                                ZStack(alignment: .topTrailing) {
                                    Image(uiImage: image)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(height: 200)
                                        .clipShape(RoundedRectangle(cornerRadius: 16))
                                    
                                    HStack(spacing: 12) {
                                        Button {
                                            selectedImage = nil
                                            shouldRemovePhoto = true
                                        } label: {
                                            Image(systemName: "trash.circle.fill")
                                                .font(.system(size: 28))
                                                .foregroundColor(.red)
                                                .background(Circle().fill(Color.white))
                                        }
                                        
                                        Button {
                                            showImagePicker = true
                                        } label: {
                                            Image(systemName: "pencil.circle.fill")
                                                .font(.system(size: 28))
                                                .foregroundColor(.gainsPrimary)
                                                .background(Circle().fill(Color.white))
                                        }
                                    }
                                    .padding()
                                }
                            } else if let photoUrl = currentPhotoUrl, !shouldRemovePhoto, let url = URL(string: photoUrl) {
                                ZStack(alignment: .topTrailing) {
                                    CachedAsyncImage(url: url) { image in
                                        image
                                            .resizable()
                                            .scaledToFill()
                                    } placeholder: {
                                        Rectangle()
                                            .fill(Color.gainsCardBackground)
                                            .overlay(ProgressView())
                                    }
                                    .frame(height: 200)
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                                    
                                    HStack(spacing: 12) {
                                        Button {
                                            shouldRemovePhoto = true
                                            currentPhotoUrl = nil
                                        } label: {
                                            Image(systemName: "trash.circle.fill")
                                                .font(.system(size: 28))
                                                .foregroundColor(.red)
                                                .background(Circle().fill(Color.white))
                                        }
                                        
                                        Button {
                                            showImagePicker = true
                                        } label: {
                                            Image(systemName: "pencil.circle.fill")
                                                .font(.system(size: 28))
                                                .foregroundColor(.gainsPrimary)
                                                .background(Circle().fill(Color.white))
                                        }
                                    }
                                    .padding()
                                }
                            } else {
                                Button {
                                    showImagePicker = true
                                    shouldRemovePhoto = false
                                } label: {
                                    VStack(spacing: 12) {
                                        Image(systemName: "camera.fill")
                                            .font(.system(size: 40))
                                            .foregroundColor(.gainsPrimary)
                                        
                                        Text("Add Photo (Optional)")
                                            .font(.system(size: 16, weight: .medium))
                                            .foregroundColor(.gainsText)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 150)
                                    .background(Color.gainsCardBackground)
                                    .cornerRadius(16)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(Color.gainsPrimary.opacity(0.3), style: StrokeStyle(lineWidth: 2, dash: [5]))
                                    )
                                }
                            }
                        }
                        .padding(.horizontal)
                        
                        // Food Name
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Food Name")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.gainsText)
                            
                            TextField("Name", text: $foodName)
                                .textFieldStyle(.plain)
                                .focused($focusedField, equals: .name)
                                .padding()
                                .background(Color.gainsCardBackground)
                                .cornerRadius(12)
                                .foregroundColor(.gainsText)
                        }
                        .padding(.horizontal)
                        
                        // Nutrition Values
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Nutrition Information")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.gainsText)
                            
                            VStack(spacing: 12) {
                                NutritionInputRow<Field>(label: "Calories", value: $calories, unit: "kcal", focusedField: $focusedField, fieldValue: .calories)
                                NutritionInputRow<Field>(label: "Protein", value: $protein, unit: "g", focusedField: $focusedField, fieldValue: .protein)
                                NutritionInputRow<Field>(label: "Carbs", value: $carbs, unit: "g", focusedField: $focusedField, fieldValue: .carbs)
                                NutritionInputRow<Field>(label: "Fats", value: $fats, unit: "g", focusedField: $focusedField, fieldValue: .fats)
                            }
                        }
                        .padding()
                        .background(Color.gainsCardBackground)
                        .cornerRadius(16)
                        .padding(.horizontal)
                        
                        // Error Message
                        if let error = errorMessage {
                            Text(error)
                                .font(.system(size: 14))
                                .foregroundColor(.red)
                                .padding()
                                .background(Color.red.opacity(0.1))
                                .cornerRadius(8)
                                .padding(.horizontal)
                        }
                        
                        // Save Button
                        Button {
                            Task {
                                await saveMeal()
                            }
                        } label: {
                            HStack {
                                if isSaving {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    Text("Saving...")
                                        .font(.system(size: 16, weight: .semibold))
                                } else {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 16))
                                    Text("Save Changes")
                                        .font(.system(size: 16, weight: .semibold))
                                }
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background((isValidInput && !isSaving) ? Color.gainsPrimary : Color.gray.opacity(0.3))
                            .cornerRadius(12)
                        }
                        .disabled(!isValidInput || isSaving)
                        .padding(.horizontal)
                        .padding(.bottom)
                    }
                    .padding(.top)
                }
            }
            .navigationTitle("Edit Meal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                    .foregroundColor(.gainsPrimary)
                }
            }
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        focusedField = nil
                    }
                    .foregroundColor(.gainsPrimary)
                    .fontWeight(.semibold)
                }
            }
            .simultaneousGesture(
                TapGesture()
                    .onEnded { _ in
                        focusedField = nil
                    }
            )
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(image: $selectedImage)
        }
    }
    
    private var isValidInput: Bool {
        !foodName.isEmpty &&
        Int(calories) != nil &&
        Double(protein) != nil &&
        Double(carbs) != nil &&
        Double(fats) != nil
    }
    
    private func saveMeal() async {
        guard let cal = Int(calories),
              let pro = Double(protein),
              let car = Double(carbs),
              let fat = Double(fats) else {
            await MainActor.run {
                errorMessage = "Please enter valid numbers"
            }
            return
        }
        
        guard let userId = Auth.auth().currentUser?.uid else {
            await MainActor.run {
                errorMessage = "You must be signed in"
            }
            return
        }
        
        isSaving = true
        errorMessage = nil
        
        var photoUrl: String? = currentPhotoUrl
        
        // Handle photo changes
        if shouldRemovePhoto {
            // Delete old photo if it exists
            if let oldUrl = food.photoUrl {
                do {
                    try await StorageService.shared.deletePhoto(from: oldUrl)
                } catch {
                    print("Failed to delete old photo: \(error)")
                    // Continue anyway - photo deletion is not critical
                }
            }
            photoUrl = nil
        } else if let newImage = selectedImage {
            // Upload new photo
            do {
                // Delete old photo first if it exists
                if let oldUrl = food.photoUrl {
                    try? await StorageService.shared.deletePhoto(from: oldUrl)
                }
                
                photoUrl = try await StorageService.shared.uploadMealImage(
                    userId: userId,
                    image: newImage,
                    for: selectedDate
                )
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to upload photo: \(error.localizedDescription)"
                    isSaving = false
                }
                return
            }
        }
        
        let updatedFood = Food(
            id: food.id,
            name: foodName,
            calories: cal,
            protein: pro,
            carbs: car,
            fats: fat,
            loggedAt: food.loggedAt,
            photoUrl: photoUrl,
            mealId: food.mealId
        )
        
        await MainActor.run {
            onMealUpdated(updatedFood)
            isPresented = false
        }
    }
}

#Preview {
    EditMealView(
        isPresented: .constant(true),
        food: Food(
            name: "Grilled Chicken Salad",
            calories: 350,
            protein: 35,
            carbs: 15,
            fats: 12,
            loggedAt: Date(),
            photoUrl: nil
        ),
        onMealUpdated: { _ in },
        selectedDate: Date()
    )
}

