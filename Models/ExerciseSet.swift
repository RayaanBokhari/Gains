//
//  ExerciseSet.swift
//  Gains
//
//  Created by Rayaan Bokhari on 11/20/25.
//

import Foundation

struct ExerciseSet: Identifiable, Codable, Equatable {
    let id: UUID
    var reps: Int?
    var weight: Double?
    var duration: TimeInterval?
    var distance: Double?
    var completed: Bool
    
    init(id: UUID = UUID(), reps: Int? = nil, weight: Double? = nil, duration: TimeInterval? = nil, distance: Double? = nil, completed: Bool = false) {
        self.id = id
        self.reps = reps
        self.weight = weight
        self.duration = duration
        self.distance = distance
        self.completed = completed
    }
}

