//
//  FoodLoggingView.swift
//  Gains
//
//  Created by Rayaan Bokhari on 11/21/25.
//

import SwiftUI
import PhotosUI
import FirebaseAuth
import UIKit

struct FoodLoggingView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var chatGPTService = ChatGPTService()
    
    @FocusState private var focusedField: Field?
    
    @Binding var isPresented: Bool
    let onFoodLogged: (Food) -> Void
    let selectedDate: Date
    
    @State private var foodDescription: String = ""
    @State private var selectedImage: UIImage?
    @State private var pendingImage: UIImage? // Image awaiting confirmation
    @State private var showImageSourceSheet = false
    @State private var showCameraPicker = false
    @State private var showPhotoLibraryPicker = false
    @State private var showImageConfirmation = false
    @State private var isEstimating = false
    @State private var isSaving = false
    @State private var errorMessage: String?
    @State private var showEstimation = false
    @State private var showTemplates = false
    @State private var showSaveTemplate = false
    
    // Estimated/editable values
    @State private var foodName: String = ""
    @State private var calories: String = ""
    @State private var protein: String = ""
    @State private var carbs: String = ""
    @State private var fats: String = ""
    
    enum Field {
        case description, name, calories, protein, carbs, fats
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.gainsBackground.ignoresSafeArea(.all)
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Use Template Button
                        Button {
                            showTemplates = true
                        } label: {
                            HStack {
                                Image(systemName: "bookmark.fill")
                                    .font(.system(size: 14))
                                Text("Use Template")
                                    .font(.system(size: 14, weight: .medium))
                            }
                            .foregroundColor(.gainsPrimary)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.gainsPrimary.opacity(0.1))
                            .cornerRadius(12)
                        }
                        .padding(.horizontal)
                        
                        // Image Upload Section
                        if let image = selectedImage {
                            ZStack(alignment: .topTrailing) {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(height: 200)
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                                    .padding(.horizontal)
                                
                                Button {
                                    selectedImage = nil
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.system(size: 24))
                                        .foregroundColor(.white)
                                        .background(Circle().fill(Color.black.opacity(0.5)))
                                }
                                .padding()
                            }
                        } else {
                            Button {
                                showImageSourceSheet = true
                            } label: {
                                VStack(spacing: 12) {
                                    HStack(spacing: 20) {
                                        VStack(spacing: 8) {
                                            Image(systemName: "camera.fill")
                                                .font(.system(size: 28))
                                                .foregroundColor(.gainsPrimary)
                                            Text("Take Photo")
                                                .font(.system(size: 12))
                                                .foregroundColor(.gainsSecondaryText)
                                        }
                                        
                                        Rectangle()
                                            .fill(Color.gainsSecondaryText.opacity(0.3))
                                            .frame(width: 1, height: 50)
                                        
                                        VStack(spacing: 8) {
                                            Image(systemName: "photo.on.rectangle")
                                                .font(.system(size: 28))
                                                .foregroundColor(.gainsPrimary)
                                            Text("Choose Photo")
                                                .font(.system(size: 12))
                                                .foregroundColor(.gainsSecondaryText)
                                        }
                                    }
                                    
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
                            .padding(.horizontal)
                        }
                        
                        // Text Description Section
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Describe Your Food")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.gainsText)
                            
                            Text("e.g., \"Large chicken burrito with rice and beans\"")
                                .font(.system(size: 14))
                                .foregroundColor(.gainsSecondaryText)
                            
                            TextField("What did you eat?", text: $foodDescription, axis: .vertical)
                                .textFieldStyle(.plain)
                                .focused($focusedField, equals: .description)
                                .padding()
                                .background(Color.gainsCardBackground)
                                .cornerRadius(12)
                                .foregroundColor(.gainsText)
                                .lineLimit(3...6)
                        }
                        .padding(.horizontal)
                        
                        // Estimate Button
                        if !showEstimation {
                            Button {
                                Task {
                                    await estimateFood()
                                }
                            } label: {
                                HStack {
                                    if isEstimating {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        Text("Analyzing...")
                                            .font(.system(size: 16, weight: .semibold))
                                    } else {
                                        Image(systemName: "sparkles")
                                            .font(.system(size: 16))
                                        Text("Estimate with AI")
                                            .font(.system(size: 16, weight: .semibold))
                                    }
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(
                                    (foodDescription.isEmpty && selectedImage == nil) 
                                    ? Color.gray.opacity(0.3) 
                                    : Color.gainsPrimary
                                )
                                .cornerRadius(12)
                            }
                            .disabled(foodDescription.isEmpty && selectedImage == nil)
                            .disabled(isEstimating)
                            .padding(.horizontal)
                        }
                        
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
                        
                        // Estimation Results (Editable)
                        if showEstimation {
                            VStack(alignment: .leading, spacing: 16) {
                                HStack {
                                    Text("Review & Edit")
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundColor(.gainsText)
                                    
                                    Spacer()
                                    
                                    Button("Re-estimate") {
                                        Task {
                                            await estimateFood()
                                        }
                                    }
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.gainsPrimary)
                                }
                                
                                Text("Edit any values to correct the estimate")
                                    .font(.system(size: 14))
                                    .foregroundColor(.gainsSecondaryText)
                                
                                // Food Name
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Food Name")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.gainsSecondaryText)
                                    
                                    TextField("Name", text: $foodName)
                                        .textFieldStyle(.plain)
                                        .focused($focusedField, equals: .name)
                                        .padding()
                                        .background(Color.gainsBackground)
                                        .cornerRadius(8)
                                        .foregroundColor(.gainsText)
                                }
                                
                                // Nutrition Values in Grid
                                VStack(spacing: 12) {
                                    NutritionInputRow(label: "Calories", value: $calories, unit: "kcal", focusedField: $focusedField, fieldValue: .calories)
                                    NutritionInputRow(label: "Protein", value: $protein, unit: "g", focusedField: $focusedField, fieldValue: .protein)
                                    NutritionInputRow(label: "Carbs", value: $carbs, unit: "g", focusedField: $focusedField, fieldValue: .carbs)
                                    NutritionInputRow(label: "Fats", value: $fats, unit: "g", focusedField: $focusedField, fieldValue: .fats)
                                }
                            }
                            .padding()
                            .background(Color.gainsCardBackground)
                            .cornerRadius(16)
                            .padding(.horizontal)
                            
                            // Save Button and Save as Template
                            VStack(spacing: 12) {
                                Button {
                                    Task {
                                        await saveFood()
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
                                        Text("Log Food")
                                            .font(.system(size: 16, weight: .semibold))
                                    }
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background((isValidInput && !isSaving) ? Color.green : Color.gray.opacity(0.3))
                                .cornerRadius(12)
                            }
                            .disabled(!isValidInput || isSaving)
                            
                            Button {
                                showSaveTemplate = true
                            } label: {
                                HStack {
                                    Image(systemName: "bookmark")
                                        .font(.system(size: 14))
                                    Text("Save as Template")
                                        .font(.system(size: 14, weight: .medium))
                                }
                                .foregroundColor(.gainsPrimary)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.gainsPrimary.opacity(0.1))
                                .cornerRadius(12)
                            }
                            .disabled(!isValidInput)
                        }
                        .padding(.horizontal)
                        }
                    }
                    .padding(.top)
                }
                .contentShape(Rectangle())
            }
            .navigationTitle("Log Food")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        focusedField = nil
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
            .scrollDismissesKeyboard(.interactively)
        }
        .confirmationDialog("Add Photo", isPresented: $showImageSourceSheet, titleVisibility: .visible) {
            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                Button("Take Photo") {
                    showCameraPicker = true
                }
            }
            Button("Choose from Library") {
                showPhotoLibraryPicker = true
            }
            Button("Cancel", role: .cancel) { }
        }
        .sheet(isPresented: $showCameraPicker) {
            ImagePickerWithSource(image: $pendingImage, sourceType: .camera) {
                // Photo taken, show confirmation
                if pendingImage != nil {
                    showImageConfirmation = true
                }
            }
        }
        .sheet(isPresented: $showPhotoLibraryPicker) {
            ImagePickerWithSource(image: $pendingImage, sourceType: .photoLibrary) {
                // Photo selected, show confirmation
                if pendingImage != nil {
                    showImageConfirmation = true
                }
            }
        }
        .sheet(isPresented: $showImageConfirmation) {
            ImageConfirmationView(
                image: $pendingImage,
                onConfirm: {
                    selectedImage = pendingImage
                    pendingImage = nil
                    showImageConfirmation = false
                },
                onCancel: {
                    pendingImage = nil
                    showImageConfirmation = false
                }
            )
        }
        .sheet(isPresented: $showTemplates) {
            MealTemplatesView { template in
                // Pre-fill form with template data
                foodName = template.name
                calories = String(template.calories)
                protein = String(format: "%.1f", template.protein)
                carbs = String(format: "%.1f", template.carbs)
                fats = String(format: "%.1f", template.fats)
                showEstimation = true
                
                // Load photo if available
                if let photoUrl = template.photoUrl {
                    // Load image from URL
                    Task {
                        if let url = URL(string: photoUrl),
                           let data = try? await URLSession.shared.data(from: url).0,
                           let image = UIImage(data: data) {
                            await MainActor.run {
                                selectedImage = image
                            }
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showSaveTemplate) {
            CreateMealTemplateView(
                isPresented: $showSaveTemplate,
                template: createTemplateFromCurrentFood(),
                onSave: { template in
                    Task {
                        let firestore = FirestoreService.shared
                        guard let userId = Auth.auth().currentUser?.uid else { return }
                        do {
                            try await firestore.saveMealTemplate(userId: userId, template: template)
                        } catch {
                            print("Error saving template: \(error)")
                        }
                    }
                }
            )
        }
    }
    
    private var isValidInput: Bool {
        !foodName.isEmpty && 
        Int(calories) != nil &&
        Double(protein) != nil &&
        Double(carbs) != nil &&
        Double(fats) != nil
    }
    
    private func createTemplateFromCurrentFood() -> MealTemplate? {
        guard let cal = Int(calories),
              let pro = Double(protein),
              let car = Double(carbs),
              let fat = Double(fats),
              !foodName.isEmpty else {
            return nil
        }
        
        // Note: photoUrl would need to be uploaded first, but for simplicity
        // we'll create template without photo for now
        return MealTemplate(
            name: foodName,
            calories: cal,
            protein: pro,
            carbs: car,
            fats: fat
        )
    }
    
    private func estimateFood() async {
        errorMessage = nil
        isEstimating = true
        
        do {
            // Convert image to base64 if present
            let imageBase64 = selectedImage?.jpegDataURLBase64(compressionQuality: 0.7)
            
            let estimation = try await chatGPTService.estimateFood(
                description: foodDescription,
                imageBase64: imageBase64
            )
            
            // Populate the editable fields
            await MainActor.run {
                foodName = estimation.name
                calories = String(estimation.calories)
                protein = String(format: "%.1f", estimation.protein)
                carbs = String(format: "%.1f", estimation.carbs)
                fats = String(format: "%.1f", estimation.fats)
                showEstimation = true
                isEstimating = false
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                isEstimating = false
            }
        }
    }
    
    private func saveFood() async {
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
        
        var photoUrl: String? = nil
        
        // Upload photo if present
        if let image = selectedImage {
            do {
                photoUrl = try await StorageService.shared.uploadMealImage(
                    userId: userId,
                    image: image,
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
        
        let food = Food(
            name: foodName,
            calories: cal,
            protein: pro,
            carbs: car,
            fats: fat,
            loggedAt: selectedDate,
            photoUrl: photoUrl
        )
        
        await MainActor.run {
            onFoodLogged(food)
            isPresented = false
        }
    }
}

struct NutritionInputRow<Field: Hashable>: View {
    let label: String
    @Binding var value: String
    let unit: String
    var focusedField: FocusState<Field?>.Binding
    var fieldValue: Field?
    
    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.gainsText)
                .frame(width: 80, alignment: .leading)
            
            TextField("0", text: $value)
                .textFieldStyle(.plain)
                .keyboardType(.decimalPad)
                .focused(focusedField, equals: fieldValue)
                .padding(10)
                .background(Color.gainsBackground)
                .cornerRadius(8)
                .foregroundColor(.gainsText)
                .multilineTextAlignment(.trailing)
            
            Text(unit)
                .font(.system(size: 14))
                .foregroundColor(.gainsSecondaryText)
                .frame(width: 40, alignment: .leading)
        }
    }
}

// Simple Image Picker (for backward compatibility)
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.dismiss) var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.image = image
            }
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

// Image Picker with Source Type
struct ImagePickerWithSource: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    let sourceType: UIImagePickerController.SourceType
    let onImagePicked: () -> Void
    @Environment(\.dismiss) var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = sourceType
        if sourceType == .camera {
            picker.cameraCaptureMode = .photo
        }
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePickerWithSource
        
        init(_ parent: ImagePickerWithSource) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.image = image
            }
            parent.dismiss()
            // Delay slightly to ensure dismiss completes before showing confirmation
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self.parent.onImagePicked()
            }
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

// Image Confirmation View
struct ImageConfirmationView: View {
    @Binding var image: UIImage?
    let onConfirm: () -> Void
    let onCancel: () -> Void
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.gainsBackground.ignoresSafeArea()
                
                VStack(spacing: 24) {
                    Text("Use this photo?")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.gainsText)
                    
                    if let displayImage = image {
                        Image(uiImage: displayImage)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 400)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .padding(.horizontal)
                    } else {
                        // Placeholder if image not yet loaded
                        VStack(spacing: 12) {
                            ProgressView()
                                .scaleEffect(1.5)
                            Text("Loading photo...")
                                .font(.system(size: 14))
                                .foregroundColor(.gainsSecondaryText)
                        }
                        .frame(height: 300)
                    }
                    
                    Spacer()
                    
                    VStack(spacing: 12) {
                        Button {
                            onConfirm()
                        } label: {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 16))
                                Text("Use Photo")
                                    .font(.system(size: 16, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(image != nil ? Color.gainsAccentGreen : Color.gray.opacity(0.3))
                            .cornerRadius(12)
                        }
                        .disabled(image == nil)
                        
                        Button {
                            onCancel()
                        } label: {
                            HStack {
                                Image(systemName: "arrow.counterclockwise")
                                    .font(.system(size: 14))
                                Text("Choose Different Photo")
                                    .font(.system(size: 14, weight: .medium))
                            }
                            .foregroundColor(.gainsPrimary)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.gainsPrimary.opacity(0.1))
                            .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                }
                .padding(.top, 20)
            }
            .navigationBarHidden(true)
        }
    }
}

#Preview {
    FoodLoggingView(
        isPresented: .constant(true),
        onFoodLogged: { food in
            print("Logged: \(food.name)")
        },
        selectedDate: Date()
    )
}

