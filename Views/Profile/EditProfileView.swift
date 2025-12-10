//
//  EditProfileView.swift
//  Gains
//
//  Created by Rayaan Bokhari on 11/21/25.
//

import SwiftUI

struct EditProfileView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: ProfileViewModel
    
    @FocusState private var focusedField: Field?
    
    @State private var name: String
    @State private var weight: String
    @State private var gender: String
    @State private var dailyCaloriesGoal: String
    @State private var proteinGoal: String
    @State private var carbsGoal: String
    @State private var fatsGoal: String
    @State private var waterGoal: String
    @State private var isSaving = false
    @State private var errorMessage: String?
    
    enum Field {
        case name, weight, calories, protein, carbs, fats, water
    }
    
    // Unit preference
    @State private var useMetricUnits: Bool
    
    // Height state - Imperial (feet/inches)
    @State private var heightFeet: Int
    @State private var heightInches: Int
    
    // Height state - Metric (cm)
    @State private var heightCm: Int
    
    let genders = ["Male", "Female", "Other"]
    
    init(viewModel: ProfileViewModel) {
        self.viewModel = viewModel
        _name = State(initialValue: viewModel.profile.name)
        _weight = State(initialValue: String(format: "%.1f", viewModel.profile.weight))
        _gender = State(initialValue: viewModel.profile.gender)
        _dailyCaloriesGoal = State(initialValue: String(viewModel.profile.dailyCaloriesGoal))
        _proteinGoal = State(initialValue: String(format: "%.0f", viewModel.profile.macros.protein))
        _carbsGoal = State(initialValue: String(format: "%.0f", viewModel.profile.macros.carbs))
        _fatsGoal = State(initialValue: String(format: "%.0f", viewModel.profile.macros.fats))
        _waterGoal = State(initialValue: String(format: "%.0f", viewModel.profile.waterGoal))
        _useMetricUnits = State(initialValue: viewModel.profile.useMetricUnits)
        
        // Parse height based on current unit preference
        let (feet, inches, cm) = Self.parseHeight(viewModel.profile.height, useMetric: viewModel.profile.useMetricUnits)
        _heightFeet = State(initialValue: feet)
        _heightInches = State(initialValue: inches)
        _heightCm = State(initialValue: cm)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.gainsBackground.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Unit Preference
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Units")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.gainsText)
                            
                            Picker("Unit System", selection: $useMetricUnits) {
                                Text("Imperial (lbs, ft/in)").tag(false)
                                Text("Metric (kg, cm)").tag(true)
                            }
                            .pickerStyle(.segmented)
                            .onChange(of: useMetricUnits) { oldValue, newValue in
                                // Convert height when switching units
                                if oldValue != newValue {
                                    if newValue {
                                        // Converting to metric: ft/in -> cm
                                        let totalInches = heightFeet * 12 + heightInches
                                        heightCm = Int(Double(totalInches) * 2.54)
                                    } else {
                                        // Converting to imperial: cm -> ft/in
                                        let totalInches = Int(Double(heightCm) / 2.54)
                                        heightFeet = totalInches / 12
                                        heightInches = totalInches % 12
                                    }
                                }
                            }
                        }
                        .padding()
                        .background(Color.gainsCardBackground)
                        .cornerRadius(16)
                        .padding(.horizontal)
                        
                        // Basic Information
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Basic Information")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.gainsText)
                            
                            ProfileTextField(label: "Name", text: $name, focusField: $focusedField, fieldValue: .name)
                            
                            // Weight Input with Unit
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Weight")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.gainsSecondaryText)
                                
                                HStack {
                                    TextField("0", text: $weight)
                                        .textFieldStyle(.plain)
                                        .keyboardType(.decimalPad)
                                        .focused($focusedField, equals: .weight)
                                        .padding()
                                        .background(Color.gainsBackground)
                                        .cornerRadius(8)
                                        .foregroundColor(.gainsText)
                                        .onChange(of: weight) { oldValue, newValue in
                                            // Filter out non-numeric characters except decimal point
                                            let filtered = newValue.filter { "0123456789.".contains($0) }
                                            if filtered != newValue {
                                                weight = filtered
                                            }
                                        }
                                    
                                    Text(useMetricUnits ? "kg" : "lbs")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.gainsSecondaryText)
                                        .frame(width: 40)
                                }
                            }
                            
                            // Height Picker
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Height")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.gainsSecondaryText)
                                
                                if useMetricUnits {
                                    // Metric: cm picker
                                    HStack {
                                        Picker("Centimeters", selection: $heightCm) {
                                            ForEach(100...250, id: \.self) { cm in
                                                Text("\(cm) cm").tag(cm)
                                            }
                                        }
                                        .pickerStyle(.wheel)
                                        .frame(maxWidth: .infinity)
                                    }
                                    .frame(height: 150)
                                } else {
                                    // Imperial: feet and inches pickers
                                    HStack(spacing: 20) {
                                        VStack {
                                            Text("Feet")
                                                .font(.system(size: 12))
                                                .foregroundColor(.gainsSecondaryText)
                                            Picker("Feet", selection: $heightFeet) {
                                                ForEach(3...8, id: \.self) { ft in
                                                    Text("\(ft)").tag(ft)
                                                }
                                            }
                                            .pickerStyle(.wheel)
                                        }
                                        
                                        VStack {
                                            Text("Inches")
                                                .font(.system(size: 12))
                                                .foregroundColor(.gainsSecondaryText)
                                            Picker("Inches", selection: $heightInches) {
                                                ForEach(0..<12, id: \.self) { inch in
                                                    Text("\(inch)").tag(inch)
                                                }
                                            }
                                            .pickerStyle(.wheel)
                                        }
                                    }
                                    .frame(height: 150)
                                }
                            }
                            
                            // Gender Picker
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Gender")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.gainsSecondaryText)
                                
                                Picker("Gender", selection: $gender) {
                                    ForEach(genders, id: \.self) { option in
                                        Text(option).tag(option)
                                    }
                                }
                                .pickerStyle(.segmented)
                                .background(Color.gainsCardBackground)
                                .cornerRadius(8)
                            }
                        }
                        .padding()
                        .background(Color.gainsCardBackground)
                        .cornerRadius(16)
                        .padding(.horizontal)
                        
                        // Goals & Targets
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Goals & Targets")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.gainsText)
                            
                            ProfileTextField(label: "Daily Calories", text: $dailyCaloriesGoal, keyboardType: .numberPad, focusField: $focusedField, fieldValue: .calories)
                            
                            Divider()
                                .background(Color.gainsBackground)
                            
                            Text("Macros (grams per day)")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.gainsSecondaryText)
                            
                            // Protein with suggested amount based on body weight
                            VStack(alignment: .leading, spacing: 4) {
                                ProfileTextField(label: "Protein", text: $proteinGoal, keyboardType: .decimalPad, focusField: $focusedField, fieldValue: .protein)
                                
                                // Suggested protein based on 1g per lb body weight
                                if let weightValue = Double(weight) {
                                    let suggestedProtein = useMetricUnits ? Int(weightValue * 2.2) : Int(weightValue)
                                    let currentProtein = Int(Double(proteinGoal) ?? 0)
                                    
                                    if abs(currentProtein - suggestedProtein) > 10 {
                                        Button {
                                            proteinGoal = String(suggestedProtein)
                                        } label: {
                                            HStack(spacing: 4) {
                                                Image(systemName: "lightbulb.fill")
                                                    .font(.system(size: 11))
                                                Text("Recommended: \(suggestedProtein)g (1g per lb)")
                                                    .font(.system(size: 12))
                                            }
                                            .foregroundColor(.gainsPrimary)
                                        }
                                        .padding(.leading, 4)
                                    }
                                }
                            }
                            ProfileTextField(label: "Carbs", text: $carbsGoal, keyboardType: .decimalPad, focusField: $focusedField, fieldValue: .carbs)
                            ProfileTextField(label: "Fats", text: $fatsGoal, keyboardType: .decimalPad, focusField: $focusedField, fieldValue: .fats)
                            
                            Divider()
                                .background(Color.gainsBackground)
                            
                            ProfileTextField(label: "Water Goal (oz)", text: $waterGoal, keyboardType: .decimalPad, focusField: $focusedField, fieldValue: .water)
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
                                await saveProfile()
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
                            .background(isValidInput && !isSaving ? Color.gainsPrimary : Color.gray.opacity(0.3))
                            .cornerRadius(12)
                        }
                        .disabled(!isValidInput || isSaving)
                        .padding(.horizontal)
                        .padding(.bottom)
                    }
                    .padding(.top)
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
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
    }
    
    private var isValidInput: Bool {
        !name.isEmpty &&
        Double(weight) != nil &&
        Int(dailyCaloriesGoal) != nil &&
        Double(proteinGoal) != nil &&
        Double(carbsGoal) != nil &&
        Double(fatsGoal) != nil &&
        Double(waterGoal) != nil
    }
    
    private func saveProfile() async {
        guard let weightValue = Double(weight),
              let calories = Int(dailyCaloriesGoal),
              let protein = Double(proteinGoal),
              let carbs = Double(carbsGoal),
              let fats = Double(fatsGoal),
              let water = Double(waterGoal) else {
            errorMessage = "Please enter valid numbers"
            return
        }
        
        // Format height string based on unit system
        let heightString: String
        if useMetricUnits {
            heightString = "\(heightCm) cm"
        } else {
            heightString = "\(heightFeet) ft \(heightInches) in"
        }
        
        // Update profile
        viewModel.profile.name = name
        viewModel.profile.weight = weightValue
        viewModel.profile.height = heightString
        viewModel.profile.gender = gender
        viewModel.profile.dailyCaloriesGoal = calories
        viewModel.profile.macros.protein = protein
        viewModel.profile.macros.carbs = carbs
        viewModel.profile.macros.fats = fats
        viewModel.profile.waterGoal = water
        viewModel.profile.useMetricUnits = useMetricUnits
        
        await viewModel.saveProfile()
        
        if viewModel.errorMessage == nil {
            dismiss()
        } else {
            errorMessage = viewModel.errorMessage
        }
    }
    
    // Helper to parse height string into components
    static func parseHeight(_ heightString: String, useMetric: Bool) -> (feet: Int, inches: Int, cm: Int) {
        if useMetric {
            // Parse "178 cm" format
            let cmValue = Int(heightString.replacingOccurrences(of: " cm", with: "").trimmingCharacters(in: .whitespaces)) ?? 175
            let totalInches = Int(Double(cmValue) / 2.54)
            return (totalInches / 12, totalInches % 12, cmValue)
        } else {
            // Parse "5 ft 10 in" format
            let components = heightString.components(separatedBy: " ")
            var feet = 5
            var inches = 10
            
            if let ftIndex = components.firstIndex(where: { $0.lowercased() == "ft" || $0 == "ft" }),
               let ftValue = Int(components[max(0, ftIndex - 1)]) {
                feet = ftValue
            }
            
            if let inIndex = components.firstIndex(where: { $0.lowercased() == "in" || $0 == "in" }),
               let inValue = Int(components[max(0, inIndex - 1)]) {
                inches = inValue
            }
            
            let totalInches = feet * 12 + inches
            let cm = Int(Double(totalInches) * 2.54)
            return (feet, inches, cm)
        }
    }
}

struct ProfileTextField: View {
    let label: String
    @Binding var text: String
    var placeholder: String = ""
    var keyboardType: UIKeyboardType = .default
    var focusField: FocusState<EditProfileView.Field?>.Binding
    var fieldValue: EditProfileView.Field?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.gainsSecondaryText)
            
            TextField(placeholder.isEmpty ? label : placeholder, text: $text)
                .textFieldStyle(.plain)
                .keyboardType(keyboardType)
                .focused(focusField, equals: fieldValue)
                .padding()
                .background(Color.gainsBackground)
                .cornerRadius(8)
                .foregroundColor(.gainsText)
        }
    }
}

#Preview {
    EditProfileView(viewModel: ProfileViewModel())
}
