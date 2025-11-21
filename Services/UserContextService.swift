//
//  UserContextService.swift
//  Gains
//
//  Created by Rayaan Bokhari on 11/20/25.
//

import Foundation
import SwiftUI
import Combine

class UserContextService: ObservableObject {
    @Published var nutritionViewModel: NutritionViewModel?
    @Published var profileViewModel: ProfileViewModel?
    
    func buildSystemPrompt() -> String {
        var context = """
        You are an AI fitness and nutrition coach for the Gains app. You help users with their fitness goals, nutrition tracking, and provide personalized advice.
        
        User Context:
        """
        
        if let profile = profileViewModel?.profile {
            context += """
            
            Profile Information:
            - Name: \(profile.name)
            - Weight: \(Int(profile.weight)) kg
            - Height: \(profile.height)
            - Gender: \(profile.gender)
            - Daily Calorie Goal: \(profile.dailyCaloriesGoal) calories
            - Protein Goal: \(Int(profile.macros.protein))g
            - Carbs Goal: \(Int(profile.macros.carbs))g
            - Fats Goal: \(Int(profile.macros.fats))g
            - Water Goal: \(Int(profile.waterGoal)) oz
            """
        }
        
        if let nutrition = nutritionViewModel?.dailyNutrition {
            context += """
            
            Today's Nutrition Progress:
            - Calories Consumed: \(nutrition.caloriesConsumed) / \(nutrition.caloriesGoal) (Remaining: \(nutrition.caloriesRemaining))
            - Protein: \(Int(nutrition.proteinConsumed))g / \(Int(nutrition.proteinGoal))g (\(Int(nutrition.proteinProgress * 100))%)
            - Carbs: \(Int(nutrition.carbsConsumed))g / \(Int(nutrition.carbsGoal))g (\(Int(nutrition.carbsProgress * 100))%)
            - Fats: \(Int(nutrition.fatsConsumed))g / \(Int(nutrition.fatsGoal))g (\(Int(nutrition.fatsProgress * 100))%)
            - Water: \(Int(nutrition.waterConsumed)) oz / \(Int(nutrition.waterGoal)) oz
            """
            
            if !nutrition.foods.isEmpty {
                context += "\n\nRecent Foods Logged:\n"
                for food in nutrition.foods.prefix(5) {
                    context += "- \(food.name): \(food.calories) cal, \(Int(food.protein))g protein, \(Int(food.carbs))g carbs, \(Int(food.fats))g fats\n"
                }
            }
        }
        
        context += """
        
        Instructions:
        - Be friendly, encouraging, and supportive
        - Provide specific, actionable advice based on the user's current progress
        - Reference their goals and current progress when relevant
        - Keep responses concise but informative
        - If asked about nutrition, use their current macro and calorie data
        - If asked about fitness, consider their profile information
        """
        
        return context
    }
}

