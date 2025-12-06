//
//  WorkoutPlan.swift
//  Gains
//
//  Created by Rayaan Bokhari on 12/20/25.
//

import Foundation

struct WorkoutPlan: Identifiable, Codable {
    let id: UUID
    var planId: String? // Firestore document ID
    var name: String
    var description: String?
    var goal: FitnessGoal?
    var difficulty: PlanDifficulty
    var durationWeeks: Int
    var daysPerWeek: Int
    var workoutTemplates: [WorkoutTemplate]
    var createdAt: Date
    var createdBy: PlanCreator
    var isActive: Bool
    var isRetired: Bool // For archived/completed plans
    var retiredAt: Date? // When the plan was retired
    var startDate: Date? // When the plan was started
    var endDate: Date? // Calculated end date based on duration
    
    init(
        id: UUID = UUID(),
        name: String,
        description: String? = nil,
        goal: FitnessGoal? = nil,
        difficulty: PlanDifficulty = .intermediate,
        durationWeeks: Int = 4,
        daysPerWeek: Int = 4,
        workoutTemplates: [WorkoutTemplate] = [],
        createdBy: PlanCreator = .user,
        isRetired: Bool = false
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.goal = goal
        self.difficulty = difficulty
        self.durationWeeks = durationWeeks
        self.daysPerWeek = daysPerWeek
        self.workoutTemplates = workoutTemplates
        self.createdAt = Date()
        self.createdBy = createdBy
        self.isActive = false
        self.isRetired = isRetired
        self.retiredAt = nil
        self.startDate = nil
        self.endDate = nil
    }
    
    var isExpired: Bool {
        guard let endDate = endDate else { return false }
        return Date() > endDate
    }
    
    var statusDescription: String {
        if isActive {
            return "Active"
        } else if isRetired {
            return "Retired"
        } else if isExpired {
            return "Expired"
        } else {
            return "Available"
        }
    }
}

struct WorkoutTemplate: Identifiable, Codable {
    let id: UUID
    var name: String // e.g., "Day 1: Push", "Day 2: Pull"
    var dayNumber: Int
    var exercises: [PlannedExercise]
    var notes: String?
    
    init(id: UUID = UUID(), name: String, dayNumber: Int, exercises: [PlannedExercise] = [], notes: String? = nil) {
        self.id = id
        self.name = name
        self.dayNumber = dayNumber
        self.exercises = exercises
        self.notes = notes
    }
}

struct PlannedExercise: Identifiable, Codable {
    let id: UUID
    var name: String
    var targetSets: Int
    var targetReps: String // e.g., "8-12" or "5"
    var targetRPE: Int? // Rate of Perceived Exertion 1-10
    var restSeconds: Int?
    var notes: String?
    var alternatives: [String]? // Alternative exercises
    
    init(
        id: UUID = UUID(),
        name: String,
        targetSets: Int = 3,
        targetReps: String = "8-12",
        targetRPE: Int? = nil,
        restSeconds: Int? = 90,
        notes: String? = nil,
        alternatives: [String]? = nil
    ) {
        self.id = id
        self.name = name
        self.targetSets = targetSets
        self.targetReps = targetReps
        self.targetRPE = targetRPE
        self.restSeconds = restSeconds
        self.notes = notes
        self.alternatives = alternatives
    }
}

enum PlanDifficulty: String, Codable, CaseIterable {
    case beginner = "Beginner"
    case intermediate = "Intermediate"
    case advanced = "Advanced"
}

enum PlanCreator: String, Codable {
    case user = "User Created"
    case ai = "AI Generated"
    case template = "Template"
}

// Supporting enums for UserProfile (will be moved there)
enum FitnessGoal: String, Codable, CaseIterable {
    case bulk = "Bulk (Gain Muscle)"
    case cut = "Cut (Lose Fat)"
    case recomp = "Body Recomposition"
    case maintenance = "Maintain Current"
    case strength = "Build Strength"
    case endurance = "Improve Endurance"
}

enum TrainingExperience: String, Codable, CaseIterable {
    case beginner = "Beginner (< 1 year)"
    case intermediate = "Intermediate (1-3 years)"
    case advanced = "Advanced (3+ years)"
}

enum TrainingSplit: String, Codable, CaseIterable {
    case pushPullLegs = "Push/Pull/Legs"
    case upperLower = "Upper/Lower"
    case fullBody = "Full Body"
    case bro = "Bro Split (Body Part)"
    case custom = "Custom"
}

enum ActivityLevel: String, Codable, CaseIterable {
    case sedentary = "Sedentary (Desk job)"
    case lightlyActive = "Lightly Active"
    case moderatelyActive = "Moderately Active"
    case veryActive = "Very Active"
    case athlete = "Athlete"
}

enum DietType: String, Codable, CaseIterable {
    case omnivore = "Omnivore"
    case vegetarian = "Vegetarian"
    case vegan = "Vegan"
    case pescatarian = "Pescatarian"
    case keto = "Keto"
    case halal = "Halal"
    case kosher = "Kosher"
}

enum MealPattern: String, Codable, CaseIterable {
    case threeMeals = "3 meals/day"
    case threePlusSnacks = "3 meals + snacks"
    case twoMeals = "2 large meals"
    case intermittentFasting = "Intermittent Fasting"
    case frequentSmall = "5-6 small meals"
}

enum CoachingStyle: String, Codable, CaseIterable {
    case gentle = "Gentle & Supportive"
    case balanced = "Balanced"
    case toughLove = "Direct & Challenging"
}

enum DetailPreference: String, Codable, CaseIterable {
    case simple = "Keep it Simple"
    case moderate = "Some Detail"
    case detailed = "In-Depth & Nerdy"
}

enum Weekday: String, Codable, CaseIterable {
    case monday, tuesday, wednesday, thursday, friday, saturday, sunday
}

