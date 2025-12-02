//
//  ExerciseTemplateService.swift
//  Gains
//
//  Created by Rayaan Bokhari on 11/20/25.
//

import Foundation
import Combine
import FirebaseAuth

@MainActor
class ExerciseTemplateService: ObservableObject {
    @Published var templates: [ExerciseTemplate] = []
    
    private let firestore = FirestoreService.shared
    private let auth = AuthService.shared
    
    init() {
        Task {
            await loadTemplates()
        }
    }
    
    func loadTemplates() async {
        // Load default templates
        let defaultTemplates = getDefaultTemplates()
        
        // Load user templates from Firestore
        guard let user = auth.user else {
            templates = defaultTemplates
            return
        }
        
        do {
            let userTemplates = try await firestore.fetchExerciseTemplates(userId: user.uid)
            // Merge defaults with user templates (user templates take precedence if same name)
            var mergedTemplates = defaultTemplates
            for userTemplate in userTemplates {
                if let index = mergedTemplates.firstIndex(where: { $0.name == userTemplate.name && $0.isDefault }) {
                    mergedTemplates[index] = userTemplate
                } else {
                    mergedTemplates.append(userTemplate)
                }
            }
            templates = mergedTemplates
        } catch {
            print("Error loading templates: \(error)")
            templates = defaultTemplates
        }
    }
    
    func addTemplate(_ template: ExerciseTemplate) async throws {
        guard let user = auth.user else { return }
        
        var newTemplate = template
        newTemplate.isDefault = false
        
        try await firestore.saveExerciseTemplate(userId: user.uid, template: newTemplate)
        await loadTemplates()
    }
    
    func deleteTemplate(_ template: ExerciseTemplate) async throws {
        // Can't delete default templates
        guard !template.isDefault,
              let user = auth.user,
              let templateId = template.templateId else { return }
        
        try await firestore.deleteExerciseTemplate(userId: user.uid, templateId: templateId)
        await loadTemplates()
    }
    
    private func getDefaultTemplates() -> [ExerciseTemplate] {
        return [
            // Strength Exercises
            ExerciseTemplate(
                name: "Bench Press",
                category: .strength,
                muscleGroups: [.chest, .triceps, .shoulders],
                equipment: "Barbell, Bench",
                instructions: "Lie on bench, lower bar to chest, press up",
                isDefault: true
            ),
            ExerciseTemplate(
                name: "Squat",
                category: .strength,
                muscleGroups: [.legs, .core],
                equipment: "Barbell",
                instructions: "Stand with bar on shoulders, lower until thighs parallel, stand up",
                isDefault: true
            ),
            ExerciseTemplate(
                name: "Deadlift",
                category: .strength,
                muscleGroups: [.back, .legs, .core],
                equipment: "Barbell",
                instructions: "Lift bar from floor to standing position, keep back straight",
                isDefault: true
            ),
            ExerciseTemplate(
                name: "Overhead Press",
                category: .strength,
                muscleGroups: [.shoulders, .triceps],
                equipment: "Barbell",
                instructions: "Press bar from shoulders to overhead",
                isDefault: true
            ),
            ExerciseTemplate(
                name: "Barbell Rows",
                category: .strength,
                muscleGroups: [.back, .biceps],
                equipment: "Barbell",
                instructions: "Bend over, pull bar to lower chest/upper abdomen",
                isDefault: true
            ),
            ExerciseTemplate(
                name: "Pull-ups",
                category: .strength,
                muscleGroups: [.back, .biceps],
                equipment: "Pull-up Bar",
                instructions: "Hang from bar, pull body up until chin over bar",
                isDefault: true
            ),
            ExerciseTemplate(
                name: "Bicep Curls",
                category: .strength,
                muscleGroups: [.biceps],
                equipment: "Dumbbells or Barbell",
                instructions: "Curl weight from arms extended to full contraction",
                isDefault: true
            ),
            ExerciseTemplate(
                name: "Tricep Extensions",
                category: .strength,
                muscleGroups: [.triceps],
                equipment: "Dumbbells or Cable",
                instructions: "Extend arms from bent to straight position",
                isDefault: true
            ),
            ExerciseTemplate(
                name: "Leg Press",
                category: .strength,
                muscleGroups: [.legs],
                equipment: "Leg Press Machine",
                instructions: "Press weight with legs from bent to extended position",
                isDefault: true
            ),
            ExerciseTemplate(
                name: "Calf Raises",
                category: .strength,
                muscleGroups: [.legs],
                equipment: "Machine or Bodyweight",
                instructions: "Raise up on toes, lower back down",
                isDefault: true
            ),
            ExerciseTemplate(
                name: "Lunges",
                category: .strength,
                muscleGroups: [.legs, .core],
                equipment: "Bodyweight or Dumbbells",
                instructions: "Step forward, lower back knee toward ground, push back up",
                isDefault: true
            ),
            
            // Cardio Exercises
            ExerciseTemplate(
                name: "Running",
                category: .cardio,
                muscleGroups: [.legs, .core],
                equipment: "None",
                instructions: "Run at steady pace or intervals",
                isDefault: true
            ),
            ExerciseTemplate(
                name: "Cycling",
                category: .cardio,
                muscleGroups: [.legs],
                equipment: "Bicycle or Stationary Bike",
                instructions: "Pedal at steady pace or intervals",
                isDefault: true
            ),
            ExerciseTemplate(
                name: "Rowing",
                category: .cardio,
                muscleGroups: [.fullBody],
                equipment: "Rowing Machine",
                instructions: "Pull handle toward chest, extend back out",
                isDefault: true
            ),
            ExerciseTemplate(
                name: "Elliptical",
                category: .cardio,
                muscleGroups: [.legs],
                equipment: "Elliptical Machine",
                instructions: "Move pedals in elliptical motion",
                isDefault: true
            ),
            ExerciseTemplate(
                name: "Stair Climber",
                category: .cardio,
                muscleGroups: [.legs],
                equipment: "Stair Climber Machine",
                instructions: "Step up continuously on rotating stairs",
                isDefault: true
            ),
            
            // Flexibility Exercises
            ExerciseTemplate(
                name: "Stretching",
                category: .flexibility,
                muscleGroups: [.fullBody],
                equipment: "None",
                instructions: "Hold stretches for 30-60 seconds",
                isDefault: true
            ),
            ExerciseTemplate(
                name: "Yoga",
                category: .flexibility,
                muscleGroups: [.fullBody],
                equipment: "Yoga Mat",
                instructions: "Perform yoga poses and sequences",
                isDefault: true
            ),
            ExerciseTemplate(
                name: "Pilates",
                category: .flexibility,
                muscleGroups: [.core, .fullBody],
                equipment: "Mat or Reformer",
                instructions: "Perform controlled movements focusing on core strength",
                isDefault: true
            )
        ]
    }
}
