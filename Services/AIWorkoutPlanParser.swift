//
//  AIWorkoutPlanParser.swift
//  Gains
//
//  Parses AI-generated workout plans into executable WorkoutPlan objects
//  Enables AI coach output to become actionable workout sessions
//

import Foundation

// MARK: - AI Generated Plan Structure
struct AIGeneratedPlan: Codable {
    let name: String
    let description: String?
    let goal: String?
    let difficulty: String?
    let durationWeeks: Int?
    let daysPerWeek: Int?
    let workouts: [AIGeneratedWorkout]
    
    enum CodingKeys: String, CodingKey {
        case name, description, goal, difficulty
        case durationWeeks = "duration_weeks"
        case daysPerWeek = "days_per_week"
        case workouts
    }
}

struct AIGeneratedWorkout: Codable {
    let name: String
    let dayNumber: Int?
    let exercises: [AIGeneratedExercise]
    let notes: String?
    
    enum CodingKeys: String, CodingKey {
        case name
        case dayNumber = "day_number"
        case exercises, notes
    }
}

struct AIGeneratedExercise: Codable {
    let name: String
    let sets: Int
    let reps: String // Can be "8-12" or "5" etc
    let restSeconds: Int?
    let rpe: Int?
    let notes: String?
    let alternatives: [String]?
    
    enum CodingKeys: String, CodingKey {
        case name, sets, reps
        case restSeconds = "rest_seconds"
        case rpe, notes, alternatives
    }
}

// MARK: - AI Workout Plan Parser
class AIWorkoutPlanParser {
    static let shared = AIWorkoutPlanParser()
    
    private init() {}
    
    // MARK: - Parse JSON to WorkoutPlan
    func parseJSONToPlan(_ jsonString: String) -> WorkoutPlan? {
        // Try to extract JSON from the response
        guard let jsonData = extractJSON(from: jsonString) else {
            print("AIWorkoutPlanParser: Could not extract JSON from response")
            return nil
        }
        
        do {
            let decoder = JSONDecoder()
            let aiPlan = try decoder.decode(AIGeneratedPlan.self, from: jsonData)
            return convertToWorkoutPlan(aiPlan)
        } catch {
            print("AIWorkoutPlanParser: Failed to decode plan: \(error)")
            return nil
        }
    }
    
    // MARK: - Extract JSON from AI Response
    private func extractJSON(from text: String) -> Data? {
        // Look for JSON block in markdown code fence
        let codeBlockPattern = "```(?:json)?\\s*([\\s\\S]*?)```"
        if let regex = try? NSRegularExpression(pattern: codeBlockPattern, options: []),
           let match = regex.firstMatch(in: text, options: [], range: NSRange(text.startIndex..., in: text)),
           let range = Range(match.range(at: 1), in: text) {
            let jsonString = String(text[range]).trimmingCharacters(in: .whitespacesAndNewlines)
            return jsonString.data(using: .utf8)
        }
        
        // Try finding JSON object directly
        if let startIndex = text.firstIndex(of: "{"),
           let endIndex = text.lastIndex(of: "}") {
            let jsonString = String(text[startIndex...endIndex])
            return jsonString.data(using: .utf8)
        }
        
        // If text looks like JSON, try it directly
        return text.trimmingCharacters(in: .whitespacesAndNewlines).data(using: .utf8)
    }
    
    // MARK: - Convert to WorkoutPlan
    private func convertToWorkoutPlan(_ aiPlan: AIGeneratedPlan) -> WorkoutPlan {
        // Map difficulty
        let difficulty: PlanDifficulty
        switch aiPlan.difficulty?.lowercased() {
        case "beginner": difficulty = .beginner
        case "advanced": difficulty = .advanced
        default: difficulty = .intermediate
        }
        
        // Map goal
        let goal: FitnessGoal?
        switch aiPlan.goal?.lowercased() {
        case let g where g?.contains("bulk") == true || g?.contains("muscle") == true:
            goal = .bulk
        case let g where g?.contains("cut") == true || g?.contains("fat") == true || g?.contains("lose") == true:
            goal = .cut
        case let g where g?.contains("strength") == true:
            goal = .strength
        case let g where g?.contains("endurance") == true:
            goal = .endurance
        case let g where g?.contains("recomp") == true:
            goal = .recomp
        default:
            goal = nil
        }
        
        // Convert workouts to templates
        var templates: [WorkoutTemplate] = []
        for (index, aiWorkout) in aiPlan.workouts.enumerated() {
            let exercises = aiWorkout.exercises.map { aiExercise in
                PlannedExercise(
                    name: aiExercise.name,
                    targetSets: aiExercise.sets,
                    targetReps: aiExercise.reps,
                    targetRPE: aiExercise.rpe,
                    restSeconds: aiExercise.restSeconds ?? 90,
                    notes: aiExercise.notes,
                    alternatives: aiExercise.alternatives
                )
            }
            
            let template = WorkoutTemplate(
                name: aiWorkout.name,
                dayNumber: aiWorkout.dayNumber ?? (index + 1),
                exercises: exercises,
                notes: aiWorkout.notes
            )
            templates.append(template)
        }
        
        return WorkoutPlan(
            name: aiPlan.name,
            description: aiPlan.description,
            goal: goal,
            difficulty: difficulty,
            durationWeeks: aiPlan.durationWeeks ?? 4,
            daysPerWeek: aiPlan.daysPerWeek ?? templates.count,
            workoutTemplates: templates,
            createdBy: .ai
        )
    }
    
    // MARK: - Generate Quick Workout from Text
    func parseQuickWorkout(_ text: String) -> WorkoutTemplate? {
        // Parse a simple workout description into a template
        // Example: "Push Day: Bench Press 4x8, Overhead Press 3x10, Tricep Dips 3x12"
        
        var exercises: [PlannedExercise] = []
        var workoutName = "Quick Workout"
        
        // Check for workout name (before colon)
        if let colonIndex = text.firstIndex(of: ":") {
            workoutName = String(text[..<colonIndex]).trimmingCharacters(in: .whitespaces)
        }
        
        // Extract exercises with sets x reps pattern
        let pattern = "([A-Za-z\\s]+)\\s*(\\d+)\\s*[xX×]\\s*(\\d+(?:-\\d+)?)"
        if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
            let matches = regex.matches(in: text, options: [], range: NSRange(text.startIndex..., in: text))
            
            for match in matches {
                if let nameRange = Range(match.range(at: 1), in: text),
                   let setsRange = Range(match.range(at: 2), in: text),
                   let repsRange = Range(match.range(at: 3), in: text) {
                    
                    let name = String(text[nameRange]).trimmingCharacters(in: .whitespaces)
                    let sets = Int(text[setsRange]) ?? 3
                    let reps = String(text[repsRange])
                    
                    let exercise = PlannedExercise(
                        name: name,
                        targetSets: sets,
                        targetReps: reps
                    )
                    exercises.append(exercise)
                }
            }
        }
        
        guard !exercises.isEmpty else { return nil }
        
        return WorkoutTemplate(
            name: workoutName,
            dayNumber: 1,
            exercises: exercises
        )
    }
    
    // MARK: - Detect Plan in AI Response
    func containsWorkoutPlan(_ text: String) -> Bool {
        // Check if the text contains structured plan indicators
        let indicators = [
            "\"exercises\"",
            "\"workouts\"",
            "\"sets\"",
            "\"reps\"",
            "day_number",
            "dayNumber"
        ]
        
        return indicators.contains { text.contains($0) }
    }
    
    // MARK: - Generate Prompt for AI
    static func generateWorkoutPlanPrompt(
        goal: FitnessGoal,
        experience: TrainingExperience,
        daysPerWeek: Int,
        split: TrainingSplit
    ) -> String {
        """
        Generate a structured workout plan in JSON format. Use this exact structure:
        
        ```json
        {
          "name": "Plan Name",
          "description": "Brief description",
          "goal": "\(goal.rawValue)",
          "difficulty": "\(experience == .beginner ? "beginner" : experience == .advanced ? "advanced" : "intermediate")",
          "duration_weeks": 4,
          "days_per_week": \(daysPerWeek),
          "workouts": [
            {
              "name": "Day 1: Push",
              "day_number": 1,
              "exercises": [
                {
                  "name": "Bench Press",
                  "sets": 4,
                  "reps": "6-8",
                  "rest_seconds": 120,
                  "notes": "Focus on form"
                }
              ],
              "notes": "Start with compound movements"
            }
          ]
        }
        ```
        
        Create a complete \(split.rawValue) split optimized for \(goal.rawValue).
        Include \(daysPerWeek) workout days with appropriate exercises for each.
        """
    }
}

// MARK: - AI Coach Integration Extension
extension AICoachViewModel {
    /// Check if the AI response contains a workout plan and offer to save it
    func checkForWorkoutPlan(in response: String) -> WorkoutPlan? {
        let parser = AIWorkoutPlanParser.shared
        
        if parser.containsWorkoutPlan(response) {
            return parser.parseJSONToPlan(response)
        }
        
        return nil
    }
}

