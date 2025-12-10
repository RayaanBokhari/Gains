//
//  ChatGPTService.swift
//  Gains
//
//  Created by Rayaan Bokhari on 11/20/25.
//

import Foundation
import Combine
import FirebaseFunctions
import FirebaseAuth

struct ChatGPTRequest: Codable {
    let messages: [Message]
    
    struct Message: Codable {
        let role: String
        let content: String
        let imageUrl: String? // For vision API
        
        init(role: String, content: String, imageUrl: String? = nil) {
            self.role = role
            self.content = content
            self.imageUrl = imageUrl
        }
    }
}

struct ChatGPTResponse: Codable {
    let reply: String
}

struct FoodEstimation: Codable {
    var name: String
    var calories: Int
    var protein: Double
    var carbs: Double
    var fats: Double
}

class ChatGPTService: ObservableObject {
    private let functions = Functions.functions(region: "us-east4")
    
    init() {
        // No API key needed - handled by Firebase Functions
    }
    
    func sendMessage(messages: [ChatGPTRequest.Message]) async throws -> String {
        return try await sendMessageWithVision(messages: messages)
    }
    
    /// Send messages with optional vision support
    private func sendMessageWithVision(messages: [ChatGPTRequest.Message]) async throws -> String {
        // Ensure user is authenticated
        guard Auth.auth().currentUser != nil else {
            throw NSError(
                domain: "ChatGPTService",
                code: -2,
                userInfo: [NSLocalizedDescriptionKey: "You must be signed in to use the AI coach."]
            )
        }
        
        // Build messages array with vision support
        let requestData: [String: Any] = [
            "messages": messages.map { message -> [String: Any] in
                var messageDict: [String: Any] = [
                    "role": message.role
                ]
                
                // If message has an image, use vision API format
                if let imageUrl = message.imageUrl {
                    messageDict["content"] = [
                        [
                            "type": "text",
                            "text": message.content
                        ],
                        [
                            "type": "image_url",
                            "image_url": [
                                "url": imageUrl
                            ]
                        ]
                    ]
                } else {
                    // Text-only format
                    messageDict["content"] = message.content
                }
                
                return messageDict
            }
        ]
        
        let function = functions.httpsCallable("aiChat")
        function.timeoutInterval = 60.0 // 60 second timeout
        
        do {
            let result = try await function.call(requestData)
            
            guard let data = result.data as? [String: Any],
                  let reply = data["reply"] as? String else {
                throw NSError(
                    domain: "ChatGPTService",
                    code: -1,
                    userInfo: [NSLocalizedDescriptionKey: "Invalid response format from server"]
                )
            }
            
            return reply
        } catch let error as NSError {
            // Handle Firebase Functions errors - extract detailed error info
            var errorMessage = "An unknown error occurred"
            
            // Firebase Functions errors have specific structure
            // Check for Firebase Functions error details
            if error.domain.contains("FunctionsError") || error.domain.contains("FIRFunctionsErrorDomain") {
                // Try to extract the error message from userInfo
                if let userInfo = error.userInfo as? [String: Any] {
                    // Check for message in various possible locations
                    if let message = userInfo["message"] as? String {
                        errorMessage = message
                    } else if let details = userInfo["details"] as? [String: Any],
                              let message = details["message"] as? String {
                        errorMessage = message
                    } else if let underlyingError = userInfo[NSUnderlyingErrorKey] as? NSError {
                        errorMessage = underlyingError.localizedDescription
                    } else {
                        errorMessage = error.localizedDescription
                    }
                } else {
                    errorMessage = error.localizedDescription
                }
            } else {
                // For other errors, use localized description
                errorMessage = error.localizedDescription
            }
            
            // Log the full error for debugging
            print("Firebase Functions Error:")
            print("  Domain: \(error.domain)")
            print("  Code: \(error.code)")
            print("  Description: \(error.localizedDescription)")
            print("  User Info: \(error.userInfo)")
            
            throw NSError(
                domain: "ChatGPTService",
                code: error.code,
                userInfo: [NSLocalizedDescriptionKey: errorMessage]
            )
        }
    }
    
    /// Estimates nutritional information from a food description and/or image
    func estimateFood(description: String, imageBase64: String? = nil) async throws -> FoodEstimation {
        // Ensure user is authenticated
        guard Auth.auth().currentUser != nil else {
            throw NSError(
                domain: "ChatGPTService",
                code: -2,
                userInfo: [NSLocalizedDescriptionKey: "You must be signed in to estimate food."]
            )
        }
        
        var promptText = """
        Analyze this food and provide a nutrition estimate in JSON format.
        
        """
        
        if !description.isEmpty {
            promptText += "Food description: \(description)\n\n"
        }
        
        if imageBase64 != nil {
            promptText += "Look at the image provided and estimate the nutritional content.\n\n"
        }
        
        promptText += """
        Return ONLY a JSON object with this exact structure (no additional text, no markdown):
        {
            "name": "A concise name for the food",
            "calories": estimated_calories_as_integer,
            "protein": estimated_protein_in_grams_as_decimal,
            "carbs": estimated_carbs_in_grams_as_decimal,
            "fats": estimated_fats_in_grams_as_decimal
        }
        
        Be reasonable with estimates. If the description is vague, make educated guesses based on typical portion sizes.
        """
        
        let systemMessage = ChatGPTRequest.Message(
            role: "system", 
            content: "You are a nutrition expert. Respond ONLY with valid JSON, no markdown formatting."
        )
        
        // Build user message with vision support
        let userMessage: ChatGPTRequest.Message
        
        if let imageData = imageBase64 {
            // Use vision API format with image
            userMessage = ChatGPTRequest.Message(
                role: "user",
                content: promptText,
                imageUrl: imageData
            )
        } else {
            // Text-only message
            userMessage = ChatGPTRequest.Message(
                role: "user",
                content: promptText
            )
        }
        
        let messages = [systemMessage, userMessage]
        let reply = try await sendMessageWithVision(messages: messages)
        
        // Try to extract JSON from the response
        var jsonString = reply.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Remove markdown code blocks if present
        if jsonString.hasPrefix("```json") {
            jsonString = jsonString.replacingOccurrences(of: "```json", with: "")
                .replacingOccurrences(of: "```", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
        } else if jsonString.hasPrefix("```") {
            jsonString = jsonString.replacingOccurrences(of: "```", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        // Find JSON object bounds
        if let start = jsonString.firstIndex(of: "{"),
           let end = jsonString.lastIndex(of: "}") {
            jsonString = String(jsonString[start...end])
        }
        
        guard let jsonData = jsonString.data(using: .utf8) else {
            throw NSError(
                domain: "ChatGPTService",
                code: -3,
                userInfo: [NSLocalizedDescriptionKey: "Failed to parse response data"]
            )
        }
        
        do {
            let estimation = try JSONDecoder().decode(FoodEstimation.self, from: jsonData)
            return estimation
        } catch {
            print("Failed to decode JSON. Raw response: \(reply)")
            print("Cleaned JSON string: \(jsonString)")
            throw NSError(
                domain: "ChatGPTService",
                code: -4,
                userInfo: [NSLocalizedDescriptionKey: "Failed to decode nutrition data. Please try again."]
            )
        }
    }
    
    /// Generates a personalized workout plan based on user preferences
    func generateWorkoutPlan(
        goal: FitnessGoal,
        experience: TrainingExperience,
        daysPerWeek: Int,
        split: TrainingSplit?,
        equipment: [String]?,
        constraints: String?
    ) async throws -> WorkoutPlan {
        // Ensure user is authenticated
        guard Auth.auth().currentUser != nil else {
            throw NSError(
                domain: "ChatGPTService",
                code: -2,
                userInfo: [NSLocalizedDescriptionKey: "You must be signed in to generate workout plans."]
            )
        }
        
        let prompt = """
        Generate a \(daysPerWeek)-day workout plan:
        Goal: \(goal.rawValue), Experience: \(experience.rawValue), Split: \(split?.rawValue ?? "Any")
        Equipment: \(equipment?.joined(separator: ", ") ?? "Full gym")
        \(constraints != nil ? "Constraints: \(constraints!)" : "")
        
        Return ONLY valid JSON (no markdown, no extra text):
        {"name":"Plan name","description":"Brief desc","durationWeeks":4,"workoutTemplates":[{"name":"Day 1","dayNumber":1,"exercises":[{"name":"Exercise","targetSets":3,"targetReps":"8-12","restSeconds":90,"notes":"Cue","alternatives":["Alt1"]}],"notes":"Notes"}]}
        
        Include 4-5 exercises per day with 1-2 alternatives each. Keep notes brief.
        """
        
        let systemMessage = ChatGPTRequest.Message(
            role: "system",
            content: "You are a fitness expert. Return ONLY compact valid JSON for workout plans. No markdown. Keep descriptions and notes brief to stay within token limits."
        )
        
        let userMessage = ChatGPTRequest.Message(
            role: "user",
            content: prompt
        )
        
        let messages = [systemMessage, userMessage]
        let reply = try await sendMessageWithVision(messages: messages)
        
        // Parse JSON response
        var jsonString = reply.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Remove markdown code blocks if present
        if jsonString.hasPrefix("```json") {
            jsonString = jsonString.replacingOccurrences(of: "```json", with: "")
                .replacingOccurrences(of: "```", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
        } else if jsonString.hasPrefix("```") {
            jsonString = jsonString.replacingOccurrences(of: "```", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        // Find JSON object bounds
        if let start = jsonString.firstIndex(of: "{"),
           let end = jsonString.lastIndex(of: "}") {
            jsonString = String(jsonString[start...end])
        }
        
        guard let jsonData = jsonString.data(using: .utf8) else {
            throw NSError(
                domain: "ChatGPTService",
                code: -3,
                userInfo: [NSLocalizedDescriptionKey: "Failed to parse workout plan response"]
            )
        }
        
        do {
            // Decode the plan structure
            struct PlanResponse: Codable {
                let name: String
                let description: String?
                let durationWeeks: Int
                let workoutTemplates: [WorkoutTemplateResponse]
            }
            
            struct WorkoutTemplateResponse: Codable {
                let name: String
                let dayNumber: Int
                let exercises: [PlannedExerciseResponse]
                let notes: String?
            }
            
            struct PlannedExerciseResponse: Codable {
                let name: String
                let targetSets: Int
                let targetReps: String
                let restSeconds: Int?
                let notes: String?
                let alternatives: [String]?
            }
            
            let planResponse = try JSONDecoder().decode(PlanResponse.self, from: jsonData)
            
            // Convert to WorkoutPlan model
            let workoutTemplates = planResponse.workoutTemplates.map { template in
                WorkoutTemplate(
                    name: template.name,
                    dayNumber: template.dayNumber,
                    exercises: template.exercises.map { exercise in
                        PlannedExercise(
                            name: exercise.name,
                            targetSets: exercise.targetSets,
                            targetReps: exercise.targetReps,
                            restSeconds: exercise.restSeconds,
                            notes: exercise.notes,
                            alternatives: exercise.alternatives
                        )
                    },
                    notes: template.notes
                )
            }
            
            return WorkoutPlan(
                name: planResponse.name,
                description: planResponse.description,
                goal: goal,
                difficulty: experience == .beginner ? .beginner : experience == .intermediate ? .intermediate : .advanced,
                durationWeeks: planResponse.durationWeeks,
                daysPerWeek: daysPerWeek,
                workoutTemplates: workoutTemplates,
                createdBy: .ai
            )
        } catch {
            print("Failed to decode workout plan JSON. Raw response: \(reply)")
            print("Cleaned JSON string: \(jsonString)")
            throw NSError(
                domain: "ChatGPTService",
                code: -4,
                userInfo: [NSLocalizedDescriptionKey: "Failed to decode workout plan. Please try again."]
            )
        }
    }
    /// Validates if a JSON string appears to be complete and well-formed
    private func isCompleteJSON(_ jsonString: String) -> Bool {
        var braceCount = 0
        var bracketCount = 0
        var inString = false
        var escaped = false

        for char in jsonString {
            if escaped {
                escaped = false
                continue
            }

            switch char {
            case "\\":
                escaped = true
            case "\"":
                if !escaped {
                    inString.toggle()
                }
            case "{":
                if !inString { braceCount += 1 }
            case "}":
                if !inString { braceCount -= 1 }
            case "[":
                if !inString { bracketCount += 1 }
            case "]":
                if !inString { bracketCount -= 1 }
            default:
                break
            }

            // If we ever go negative, the JSON is malformed
            if braceCount < 0 || bracketCount < 0 {
                return false
            }
        }

        // Final counts should be zero for complete JSON
        return braceCount == 0 && bracketCount == 0
    }

    /// Generates a personalized dietary plan based on user preferences
    func generateDietaryPlan(
        goal: FitnessGoal,
        dailyCalories: Int,
        proteinGrams: Double,
        carbGrams: Double,
        fatGrams: Double,
        mealsPerDay: Int,
        dietType: DietType?,
        restrictions: [String]?,
        additionalNotes: String?
    ) async throws -> DietaryPlan {
        // Ensure user is authenticated
        guard Auth.auth().currentUser != nil else {
            throw NSError(
                domain: "ChatGPTService",
                code: -2,
                userInfo: [NSLocalizedDescriptionKey: "You must be signed in to generate dietary plans."]
            )
        }
        
        let restrictionsStr = restrictions?.joined(separator: ", ") ?? "None"
        let dietTypeStr = dietType?.rawValue ?? "Balanced"
        
        let prompt = """
        Create 3-day meal plan:
        Goal: \(goal.rawValue), \(dailyCalories) cal/day, \(Int(proteinGrams))g protein, \(Int(carbGrams))g carbs, \(Int(fatGrams))g fat
        Meals/day: \(mealsPerDay), Diet: \(dietTypeStr), Restrictions: \(restrictionsStr)
        \(additionalNotes != nil ? "Notes: \(additionalNotes!)" : "")

        Return ONLY JSON:
        {"name":"Plan title","description":"Brief desc","meals":[{"dayName":"Day 1","dayNumber":1,"meals":[{"name":"Breakfast","mealType":"breakfast","foods":[{"name":"Food","quantity":"1 cup","calories":200,"protein":15.0,"carbs":20.0,"fats":5.0}],"calories":400,"protein":30.0,"carbs":40.0,"fats":15.0,"prepTime":10,"notes":"Tip"}],"notes":"Day note"}]}

        Requirements: 3 days (Day 1, Day 2, Day 3), realistic foods, accurate macros, varied meals, respect restrictions.
        """

        let systemMessage = ChatGPTRequest.Message(
            role: "system",
            content: "You are a nutritionist. Return ONLY valid JSON. No markdown. Use decimals for protein/carbs/fats, integers for calories."
        )

        let userMessage = ChatGPTRequest.Message(
            role: "user",
            content: prompt
        )

        let messages = [systemMessage, userMessage]
        let reply = try await sendMessageWithVision(messages: messages)
        
        // Parse JSON response with enhanced validation
        var jsonString = reply.trimmingCharacters(in: .whitespacesAndNewlines)

        // Remove markdown code blocks if present
        if jsonString.hasPrefix("```json") {
            jsonString = jsonString.replacingOccurrences(of: "```json", with: "")
                .replacingOccurrences(of: "```", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
        } else if jsonString.hasPrefix("```") {
            jsonString = jsonString.replacingOccurrences(of: "```", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
        }

        // Find JSON object bounds
        guard let startIndex = jsonString.firstIndex(of: "{"),
              let endIndex = jsonString.lastIndex(of: "}") else {
            print("ERROR: Could not find JSON object bounds in response")
            throw NSError(
                domain: "ChatGPTService",
                code: -3,
                userInfo: [NSLocalizedDescriptionKey: "Response does not contain valid JSON structure"]
            )
        }

        jsonString = String(jsonString[startIndex...endIndex])

        // Validate JSON structure before parsing
        guard jsonString.hasPrefix("{") && jsonString.hasSuffix("}") else {
            print("ERROR: JSON does not have proper object boundaries")
            throw NSError(
                domain: "ChatGPTService",
                code: -3,
                userInfo: [NSLocalizedDescriptionKey: "Invalid JSON object structure"]
            )
        }

        // Basic validation - check for required top-level keys
        guard jsonString.contains("\"name\"") &&
              jsonString.contains("\"meals\"") else {
            print("ERROR: JSON missing required keys 'name' or 'meals'")
            throw NSError(
                domain: "ChatGPTService",
                code: -3,
                userInfo: [NSLocalizedDescriptionKey: "JSON missing required plan structure"]
            )
        }

        // Check for JSON completeness by validating bracket matching
        guard isCompleteJSON(jsonString) else {
            print("ERROR: JSON response appears to be truncated or incomplete")
            throw NSError(
                domain: "ChatGPTService",
                code: -5,
                userInfo: [NSLocalizedDescriptionKey: "Response appears incomplete. The AI may have run out of tokens. Please try again."]
            )
        }

        guard let jsonData = jsonString.data(using: .utf8) else {
            print("ERROR: Could not convert JSON string to data")
            throw NSError(
                domain: "ChatGPTService",
                code: -3,
                userInfo: [NSLocalizedDescriptionKey: "Failed to encode JSON string"]
            )
        }
        
        do {
            // Decode the plan structure
            struct DietaryPlanResponse: Codable {
                let name: String
                let description: String?
                let meals: [MealPlanDayResponse]
            }
            
            struct MealPlanDayResponse: Codable {
                let dayName: String
                let dayNumber: Int
                let meals: [PlannedMealResponse]
                let notes: String?
            }
            
            struct PlannedMealResponse: Codable {
                let name: String
                let mealType: String
                let foods: [PlannedFoodResponse]
                let calories: Int
                let protein: Double
                let carbs: Double
                let fats: Double
                let prepTime: Int?
                let notes: String?
            }
            
            struct PlannedFoodResponse: Codable {
                let name: String
                let quantity: String
                let calories: Int
                let protein: Double
                let carbs: Double
                let fats: Double
            }
            
            let planResponse = try JSONDecoder().decode(DietaryPlanResponse.self, from: jsonData)
            
            // Convert to DietaryPlan model
            let mealPlanDays: [MealPlanDay] = planResponse.meals.map { dayResponse -> MealPlanDay in
                let plannedMeals: [PlannedMeal] = dayResponse.meals.map { mealResponse -> PlannedMeal in
                    let mealType: MealType
                    switch mealResponse.mealType.lowercased() {
                    case "breakfast": mealType = .breakfast
                    case "morning snack", "morningsnack": mealType = .morningSnack
                    case "lunch": mealType = .lunch
                    case "afternoon snack", "afternoonsnack": mealType = .afternoonSnack
                    case "dinner": mealType = .dinner
                    case "evening snack", "eveningsnack": mealType = .eveningSnack
                    default: mealType = .lunch
                    }
                    
                    let foods: [PlannedFood] = mealResponse.foods.map { food -> PlannedFood in
                        PlannedFood(
                            name: food.name,
                            quantity: food.quantity,
                            calories: food.calories,
                            protein: food.protein,
                            carbs: food.carbs,
                            fats: food.fats
                        )
                    }
                    
                    return PlannedMeal(
                        name: mealResponse.name,
                        mealType: mealType,
                        foods: foods,
                        calories: mealResponse.calories,
                        protein: mealResponse.protein,
                        carbs: mealResponse.carbs,
                        fats: mealResponse.fats,
                        prepTime: mealResponse.prepTime,
                        notes: mealResponse.notes
                    )
                }
                
                return MealPlanDay(
                    dayName: dayResponse.dayName,
                    dayNumber: dayResponse.dayNumber,
                    meals: plannedMeals,
                    notes: dayResponse.notes
                )
            }
            
            return DietaryPlan(
                name: planResponse.name,
                description: planResponse.description,
                goal: goal,
                dailyCalories: dailyCalories,
                macros: DietaryPlan.MacroTargets(
                    protein: proteinGrams,
                    carbs: carbGrams,
                    fats: fatGrams
                ),
                mealCount: mealsPerDay,
                meals: mealPlanDays,
                createdBy: .ai,
                dietType: dietType,
                restrictions: restrictions,
                durationWeeks: 1
            )
        } catch let decodingError as DecodingError {
            print("=== DIETARY PLAN JSON DECODING ERROR ===")
            print("Raw AI response: \(reply)")
            print("Cleaned JSON string: \(jsonString)")
            print("Decoding error: \(decodingError)")

            // Provide more specific error messages based on decoding error type
            let errorMessage: String
            switch decodingError {
            case .keyNotFound(let key, _):
                errorMessage = "Missing required field: \(key.stringValue)"
            case .typeMismatch(let type, _):
                errorMessage = "Type mismatch for expected type: \(type)"
            case .valueNotFound(let type, _):
                errorMessage = "Missing value for expected type: \(type)"
            case .dataCorrupted(let context):
                errorMessage = "Data corrupted: \(context.debugDescription)"
            @unknown default:
                errorMessage = "Unknown decoding error"
            }

            print("Detailed error: \(errorMessage)")
            print("=====================================")

            throw NSError(
                domain: "ChatGPTService",
                code: -4,
                userInfo: [NSLocalizedDescriptionKey: "Failed to decode dietary plan: \(errorMessage). Please try again."]
            )
        } catch {
            print("Failed to decode dietary plan JSON (non-decoding error). Raw response: \(reply)")
            print("Cleaned JSON string: \(jsonString)")
            print("Error: \(error)")
            throw NSError(
                domain: "ChatGPTService",
                code: -4,
                userInfo: [NSLocalizedDescriptionKey: "Failed to decode dietary plan. Please try again."]
            )
        }
    }

    /// Generates meal suggestions for today based on remaining macros
    func generateTodaysMeals(
        remainingCalories: Int,
        remainingProtein: Double,
        remainingCarbs: Double,
        remainingFats: Double,
        mealsRemaining: Int,
        dietType: DietType?,
        restrictions: [String]?,
        additionalNotes: String?
    ) async throws -> [PlannedMeal] {
        // Ensure user is authenticated
        guard Auth.auth().currentUser != nil else {
            throw NSError(
                domain: "ChatGPTService",
                code: -2,
                userInfo: [NSLocalizedDescriptionKey: "You must be signed in to generate meal suggestions."]
            )
        }

        let restrictionsStr = restrictions?.joined(separator: ", ") ?? "None"
        let dietTypeStr = dietType?.rawValue ?? "Balanced"

        let prompt = """
        Suggest \(mealsRemaining) meal(s) for the rest of today:
        Remaining: \(remainingCalories) cal, \(Int(remainingProtein))g protein, \(Int(remainingCarbs))g carbs, \(Int(remainingFats))g fat
        Diet: \(dietTypeStr), Restrictions: \(restrictionsStr)
        \(additionalNotes != nil ? "Notes: \(additionalNotes!)" : "")

        Return ONLY JSON array:
        [{"name":"Meal name","mealType":"lunch","foods":[{"name":"Food","quantity":"1 cup","calories":200,"protein":15.0,"carbs":20.0,"fats":5.0}],"calories":400,"protein":30.0,"carbs":40.0,"fats":15.0,"prepTime":10,"notes":"Tip"}]

        Requirements: realistic foods, accurate macros that fit remaining targets, easy to prepare.
        """

        let systemMessage = ChatGPTRequest.Message(
            role: "system",
            content: "You are a nutritionist. Return ONLY valid JSON array. No markdown. Use decimals for protein/carbs/fats, integers for calories."
        )

        let userMessage = ChatGPTRequest.Message(
            role: "user",
            content: prompt
        )

        let messages = [systemMessage, userMessage]
        let reply = try await sendMessageWithVision(messages: messages)

        // Parse JSON response
        var jsonString = reply.trimmingCharacters(in: .whitespacesAndNewlines)

        // Remove markdown code blocks if present
        if jsonString.hasPrefix("```json") {
            jsonString = jsonString.replacingOccurrences(of: "```json", with: "")
                .replacingOccurrences(of: "```", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
        } else if jsonString.hasPrefix("```") {
            jsonString = jsonString.replacingOccurrences(of: "```", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
        }

        // Find JSON array bounds
        guard let startIndex = jsonString.firstIndex(of: "["),
              let endIndex = jsonString.lastIndex(of: "]") else {
            throw NSError(
                domain: "ChatGPTService",
                code: -3,
                userInfo: [NSLocalizedDescriptionKey: "Response does not contain valid JSON array"]
            )
        }

        jsonString = String(jsonString[startIndex...endIndex])

        guard let jsonData = jsonString.data(using: .utf8) else {
            throw NSError(
                domain: "ChatGPTService",
                code: -3,
                userInfo: [NSLocalizedDescriptionKey: "Failed to encode JSON string"]
            )
        }

        do {
            struct PlannedMealResponse: Codable {
                let name: String
                let mealType: String
                let foods: [PlannedFoodResponse]
                let calories: Int
                let protein: Double
                let carbs: Double
                let fats: Double
                let prepTime: Int?
                let notes: String?
            }

            struct PlannedFoodResponse: Codable {
                let name: String
                let quantity: String
                let calories: Int
                let protein: Double
                let carbs: Double
                let fats: Double
            }

            let mealsResponse = try JSONDecoder().decode([PlannedMealResponse].self, from: jsonData)

            return mealsResponse.map { mealResponse -> PlannedMeal in
                let mealType: MealType
                switch mealResponse.mealType.lowercased() {
                case "breakfast": mealType = .breakfast
                case "morning snack", "morningsnack": mealType = .morningSnack
                case "lunch": mealType = .lunch
                case "afternoon snack", "afternoonsnack": mealType = .afternoonSnack
                case "dinner": mealType = .dinner
                case "evening snack", "eveningsnack": mealType = .eveningSnack
                default: mealType = .lunch
                }

                let foods: [PlannedFood] = mealResponse.foods.map { food -> PlannedFood in
                    PlannedFood(
                        name: food.name,
                        quantity: food.quantity,
                        calories: food.calories,
                        protein: food.protein,
                        carbs: food.carbs,
                        fats: food.fats
                    )
                }

                return PlannedMeal(
                    name: mealResponse.name,
                    mealType: mealType,
                    foods: foods,
                    calories: mealResponse.calories,
                    protein: mealResponse.protein,
                    carbs: mealResponse.carbs,
                    fats: mealResponse.fats,
                    prepTime: mealResponse.prepTime,
                    notes: mealResponse.notes
                )
            }
        } catch {
            print("Failed to decode meal suggestions: \(error)")
            throw NSError(
                domain: "ChatGPTService",
                code: -4,
                userInfo: [NSLocalizedDescriptionKey: "Failed to decode meal suggestions. Please try again."]
            )
        }
    }
}

