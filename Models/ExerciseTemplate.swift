//
//  ExerciseTemplate.swift
//  Gains
//
//  Created by Rayaan Bokhari on 11/20/25.
//

import Foundation

struct ExerciseTemplate: Identifiable, Codable {
    let id: UUID
    var name: String
    var category: ExerciseCategory
    var muscleGroups: [MuscleGroup]
    var equipment: String?
    var instructions: String?
    
    init(id: UUID = UUID(), name: String, category: ExerciseCategory, muscleGroups: [MuscleGroup] = [], equipment: String? = nil, instructions: String? = nil) {
        self.id = id
        self.name = name
        self.category = category
        self.muscleGroups = muscleGroups
        self.equipment = equipment
        self.instructions = instructions
    }
}

enum ExerciseCategory: String, Codable, CaseIterable {
    case strength = "Strength"
    case cardio = "Cardio"
    case flexibility = "Flexibility"
    case other = "Other"
}

enum MuscleGroup: String, Codable, CaseIterable {
    case chest = "Chest"
    case back = "Back"
    case shoulders = "Shoulders"
    case biceps = "Biceps"
    case triceps = "Triceps"
    case legs = "Legs"
    case core = "Core"
    case fullBody = "Full Body"
}

