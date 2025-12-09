//
//  LogWeightSheet.swift
//  Gains
//
//  Created by Rayaan Bokhari on 12/20/25.
//

import SwiftUI

struct LogWeightSheet: View {
    let useMetricUnits: Bool
    let onSave: (Double, String?) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var weightText = ""
    @State private var notes = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(hex: "0A0B0E").ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Weight Input
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Weight")
                                .font(.system(size: 14))
                                .foregroundColor(.gainsTextSecondary)
                            
                            HStack(alignment: .firstTextBaseline, spacing: 8) {
                                TextField("0.0", text: $weightText)
                                    .keyboardType(.decimalPad)
                                    .font(.system(size: 48, weight: .bold))
                                    .foregroundColor(.white)
                                
                                Text(useMetricUnits ? "kg" : "lbs")
                                    .font(.system(size: 20))
                                    .foregroundColor(.gainsTextSecondary)
                            }
                        }
                        .padding(20)
                        .background(Color.gainsCardSurface)
                        .cornerRadius(12)
                        
                        // Notes
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Notes (optional)")
                                .font(.system(size: 14))
                                .foregroundColor(.gainsTextSecondary)
                            
                            TextField("How are you feeling?", text: $notes, axis: .vertical)
                                .foregroundColor(.white)
                                .lineLimit(3...6)
                        }
                        .padding(20)
                        .background(Color.gainsCardSurface)
                        .cornerRadius(12)
                        
                        Spacer()
                    }
                    .padding()
                }
            }
            .navigationTitle("Log Weight")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.gainsPrimary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if let weight = Double(weightText) {
                            onSave(weight, notes.isEmpty ? nil : notes)
                            dismiss()
                        }
                    }
                    .foregroundColor(.gainsPrimary)
                    .fontWeight(.semibold)
                    .disabled(Double(weightText) == nil || weightText.isEmpty)
                }
            }
        }
    }
}

#Preview {
    LogWeightSheet(useMetricUnits: false) { weight, notes in
        print("Weight: \(weight), Notes: \(notes ?? "none")")
    }
}

