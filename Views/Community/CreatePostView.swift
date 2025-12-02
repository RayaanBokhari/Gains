//
//  CreatePostView.swift
//  Gains
//
//  Created by Rayaan Bokhari on 11/21/25.
//

import SwiftUI
import FirebaseAuth

struct CreatePostView: View {
    @Environment(\.dismiss) var dismiss
    @Binding var isPresented: Bool
    @ObservedObject var viewModel: CommunityViewModel
    
    @State private var text: String = ""
    @State private var calories: String = ""
    @State private var protein: String = ""
    @State private var carbs: String = ""
    @State private var fats: String = ""
    @State private var isPosting = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.gainsBackground.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Text Input
                        VStack(alignment: .leading, spacing: 8) {
                            Text("What's on your mind?")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.gainsText)
                            
                            TextField("Share your progress...", text: $text, axis: .vertical)
                                .textFieldStyle(.plain)
                                .padding()
                                .background(Color.gainsCardBackground)
                                .cornerRadius(12)
                                .foregroundColor(.gainsText)
                                .lineLimit(5...10)
                        }
                        .padding(.horizontal)
                        
                        // Optional Nutrition Info
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Nutrition Info (Optional)")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.gainsSecondaryText)
                            
                            VStack(spacing: 8) {
                                PostNutritionInputRow(label: "Calories", value: $calories, unit: "kcal")
                                PostNutritionInputRow(label: "Protein", value: $protein, unit: "g")
                                PostNutritionInputRow(label: "Carbs", value: $carbs, unit: "g")
                                PostNutritionInputRow(label: "Fats", value: $fats, unit: "g")
                            }
                        }
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
                        
                        // Post Button
                        Button {
                            Task {
                                await post()
                            }
                        } label: {
                            HStack {
                                if isPosting {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    Text("Posting...")
                                        .font(.system(size: 16, weight: .semibold))
                                } else {
                                    Image(systemName: "paperplane.fill")
                                        .font(.system(size: 16))
                                    Text("Post")
                                        .font(.system(size: 16, weight: .semibold))
                                }
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background((!text.isEmpty && !isPosting) ? Color.gainsPrimary : Color.gray.opacity(0.3))
                            .cornerRadius(12)
                        }
                        .disabled(text.isEmpty || isPosting)
                        .padding(.horizontal)
                    }
                    .padding(.top)
                }
            }
            .navigationTitle("Create Post")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                    .foregroundColor(.gainsPrimary)
                }
            }
        }
    }
    
    private func post() async {
        guard !text.isEmpty else { return }
        
        isPosting = true
        errorMessage = nil
        
        let cal = Int(calories)
        let pro = Double(protein)
        let car = Double(carbs)
        let fat = Double(fats)
        
        do {
            try await viewModel.createPost(
                text: text,
                imageUrl: nil,
                calories: cal,
                protein: pro,
                carbs: car,
                fats: fat
            )
            isPresented = false
        } catch {
            errorMessage = error.localizedDescription
            isPosting = false
        }
    }
}

private struct PostNutritionInputRow: View {
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

