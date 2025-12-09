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
        Generate a 7-day dietary plan:
        Goal: \(goal.rawValue)
        Daily Calories: \(dailyCalories)
        Macros: \(Int(proteinGrams))g protein, \(Int(carbGrams))g carbs, \(Int(fatGrams))g fat
        Meals per day: \(mealsPerDay)
        Diet type: \(dietTypeStr)
        Restrictions/Allergies: \(restrictionsStr)
        \(additionalNotes != nil ? "Notes: \(additionalNotes!)" : "")
        
        Return ONLY valid JSON (no markdown, no extra text):
        {"name":"Plan name","description":"Brief desc","meals":[{"dayName":"Monday","dayNumber":1,"meals":[{"name":"Breakfast","mealType":"breakfast","foods":[{"name":"Food name","quantity":"1 cup","calories":200,"protein":15,"carbs":20,"fats":5}],"calories":400,"protein":30,"carbs":40,"fats":15,"prepTime":10,"notes":"Tip"}],"notes":"Day note"}]}
        
        Include realistic foods with accurate macros. Total daily macros should approximately match targets. Keep prep times realistic (5-30 min). Vary meals across the week.
        """
        
        let systemMessage = ChatGPTRequest.Message(
            role: "system",
            content: "You are a certified nutritionist. Return ONLY compact valid JSON for dietary plans. No markdown. Be specific with food quantities and accurate with nutritional values. Create practical, easy-to-follow meal plans."
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
                userInfo: [NSLocalizedDescriptionKey: "Failed to parse dietary plan response"]
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
        } catch {
            print("Failed to decode dietary plan JSON. Raw response: \(reply)")
            print("Cleaned JSON string: \(jsonString)")
            throw NSError(
                domain: "ChatGPTService",
                code: -4,
                userInfo: [NSLocalizedDescriptionKey: "Failed to decode dietary plan. Please try again."]
            )
        }
    }
}

