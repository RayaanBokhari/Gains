//
//  ExerciseTemplateService.swift
//  Gains
//
//  Created by Rayaan Bokhari on 11/20/25.
//

import Foundation

class ExerciseTemplateService: ObservableObject {
    @Published var templates: [ExerciseTemplate] = []
    
    init() {
        loadDefaultTemplates()
    }
    
    func addTemplate(_ template: ExerciseTemplate) {
        templates.append(template)
        saveTemplates()
    }
    
    func deleteTemplate(_ template: ExerciseTemplate) {
        templates.removeAll { $0.id == template.id }
        saveTemplates()
    }
    
    private func loadDefaultTemplates() {
        // TODO: Load default exercise templates
    }
    
    private func saveTemplates() {
        // TODO: Implement persistence
    }
}

