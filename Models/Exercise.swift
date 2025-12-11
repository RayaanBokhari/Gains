//
//  Exercise.swift
//  Gains
//
//  Created by Rayaan Bokhari on 11/20/25.
//

import Foundation

struct Exercise: Identifiable, Codable, Equatable {
    let id: UUID
    var name: String
    var sets: [ExerciseSet]
    var restTime: TimeInterval?
    var notes: String?
    
    init(id: UUID = UUID(), name: String, sets: [ExerciseSet] = [], restTime: TimeInterval? = nil, notes: String? = nil) {
        self.id = id
        self.name = name
        self.sets = sets
        self.restTime = restTime
        self.notes = notes
    }
}

