//
//  Workout.swift
//  Gains
//
//  Created by Rayaan Bokhari on 11/20/25.
//

import Foundation

struct Workout: Identifiable, Codable {
    let id: UUID
    var name: String
    var date: Date
    var exercises: [Exercise]
    var notes: String?
    var workoutId: String? // Firestore document ID
    
    init(id: UUID = UUID(), name: String, date: Date = Date(), exercises: [Exercise] = [], notes: String? = nil, workoutId: String? = nil) {
        self.id = id
        self.name = name
        self.date = date
        self.exercises = exercises
        self.notes = notes
        self.workoutId = workoutId
    }
}

