//
//  Workout.swift
//  Gains
//
//  Created by Rayaan Bokhari on 11/20/25.
//

import Foundation

struct Workout: Identifiable, Codable, Equatable {
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
    
    // Custom decoding to handle legacy data where 'id' might be a non-UUID string
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Try to decode id as UUID, if it fails generate a new one
        if let uuidString = try? container.decode(String.self, forKey: .id),
           let uuid = UUID(uuidString: uuidString) {
            self.id = uuid
        } else if let uuid = try? container.decode(UUID.self, forKey: .id) {
            self.id = uuid
        } else {
            // Generate a new UUID if decoding fails (legacy data)
            self.id = UUID()
        }
        
        self.name = try container.decode(String.self, forKey: .name)
        self.date = try container.decode(Date.self, forKey: .date)
        self.exercises = try container.decodeIfPresent([Exercise].self, forKey: .exercises) ?? []
        self.notes = try container.decodeIfPresent(String.self, forKey: .notes)
        self.workoutId = try container.decodeIfPresent(String.self, forKey: .workoutId)
    }
}

