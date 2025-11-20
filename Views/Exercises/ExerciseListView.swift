//
//  ExerciseListView.swift
//  Gains
//
//  Created by Rayaan Bokhari on 11/20/25.
//

import SwiftUI

struct ExerciseListView: View {
    @StateObject private var templateService = ExerciseTemplateService()
    
    var body: some View {
        NavigationView {
            List(templateService.templates) { template in
                ExerciseTemplateRowView(template: template)
            }
            .navigationTitle("Exercises")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        // TODO: Show add exercise sheet
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
        }
    }
}

struct ExerciseTemplateRowView: View {
    let template: ExerciseTemplate
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(template.name)
                .font(.headline)
            
            HStack {
                Text(template.category.rawValue)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.2))
                    .cornerRadius(4)
                
                if !template.muscleGroups.isEmpty {
                    Text(template.muscleGroups.map { $0.rawValue }.joined(separator: ", "))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}

#Preview {
    ExerciseListView()
}

