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
    @Published var workoutViewModel: WorkoutViewModel?
    @Published var homeViewModel: HomeViewModel?
    @Published var streakData: Streak?
    @Published var achievements: [Achievement] = []
    @Published var mealTemplates: [MealTemplate] = []
    @Published var weeklyNutritionSummary: WeeklyNutritionSummary?
    @Published var weeklyTrainingSummary: WeeklyTrainingSummary?
    @Published var weightTrend: WeightTrend?
    @Published var activeDietaryPlan: DietaryPlan?
    @Published var activeWorkoutPlan: WorkoutPlan?
    
    func buildSystemPrompt() -> String {
        var context = """
        You are an AI fitness and nutrition coach for the Gains app. You help users with their fitness goals, nutrition tracking, and provide personalized advice.
        
        User Context:
        """
        
        if let profile = profileViewModel?.profile {
            context += """
            
            Profile Information:
            - Name: \(profile.name)
            - Weight: \(Int(profile.weight)) \(profile.useMetricUnits ? "kg" : "lbs")
            - Height: \(profile.height)
            - Gender: \(profile.gender)
            - Daily Calorie Goal: \(profile.dailyCaloriesGoal) calories
            - Protein Goal: \(Int(profile.macros.protein))g
            - Carbs Goal: \(Int(profile.macros.carbs))g
            - Fats Goal: \(Int(profile.macros.fats))g
            - Water Goal: \(Int(profile.waterGoal)) oz
            """
            
            // Add extended profile information
            if let goal = profile.primaryGoal {
                context += "\n- Primary Goal: \(goal.rawValue)"
            }
            if let targetWeight = profile.targetWeight {
                context += "\n- Target Weight: \(Int(targetWeight)) \(profile.useMetricUnits ? "kg" : "lbs")"
            }
            if let targetDate = profile.targetDate {
                context += "\n- Target Date: \(profile.targetDateString)"
            }
            if let experience = profile.trainingExperience {
                context += "\n- Training Experience: \(experience.rawValue)"
            }
            if let split = profile.trainingSplit {
                context += "\n- Training Split: \(split.rawValue)"
            }
            if let activity = profile.activityLevel {
                context += "\n- Activity Level: \(activity.rawValue)"
            }
            if let diet = profile.dietType {
                context += "\n- Diet Type: \(diet.rawValue)"
            }
            let restrictions = profile.restrictionsDescription
            if restrictions != "None" {
                context += "\n- Dietary Restrictions: \(restrictions)"
            }
            if let mealPattern = profile.mealPattern {
                context += "\n- Meal Pattern: \(mealPattern.rawValue)"
            }
            if let coachingStyle = profile.coachingStyle {
                context += "\n- Coaching Style Preference: \(coachingStyle.rawValue)"
            }
            if let detailPref = profile.detailPreference {
                context += "\n- Detail Preference: \(detailPref.rawValue)"
            }
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
        
        // Add weekly nutrition summary
        if let weeklyNutrition = weeklyNutritionSummary {
            context += """
            
            Weekly Nutrition Summary (Last 7 Days):
            - Average Calories: \(Int(weeklyNutrition.avgCalories)) / \(Int(weeklyNutrition.calorieGoal))
            - Average Protein: \(Int(weeklyNutrition.avgProtein))g / \(Int(weeklyNutrition.proteinGoal))g
            - Days Logged: \(weeklyNutrition.daysLogged)
            - Days on Calorie Target: \(weeklyNutrition.daysOnCalorieTarget)
            - Days on Protein Target: \(weeklyNutrition.daysOnProteinTarget)
            - Logging Streak: \(weeklyNutrition.loggingStreak) days
            - Pattern: \(weeklyNutrition.notablePatternDescription)
            """
        }
        
        // Add workout context
        if let trainingSummary = weeklyTrainingSummary {
            context += """
            
            Weekly Training Summary:
            - Sessions This Week: \(trainingSummary.sessionsThisWeek)
            - Total Volume: \(Int(trainingSummary.totalVolume)) kg lifted
            - Average Exercises per Session: \(String(format: "%.1f", trainingSummary.averageExercisesPerSession))
            - Average Sets per Session: \(String(format: "%.1f", trainingSummary.averageSetsPerSession))
            - Last Workout: \(trainingSummary.lastWorkoutDescription) (\(trainingSummary.lastWorkoutDateString))
            """
            if !trainingSummary.muscleGroupsWorked.isEmpty {
                context += "\n- Muscle Groups Worked: \(trainingSummary.muscleGroupsSummary)"
            }
        }
        
        // Add weight trend
        if let trend = weightTrend {
            context += """
            
            Weight Trend:
            - Current Weight: \(trend.currentWeight != nil ? String(format: "%.1f", trend.currentWeight!) : "N/A")
            - Weekly Change: \(trend.weeklyChange != nil ? String(format: "%.1f", trend.weeklyChange!) : "N/A")
            - Monthly Change: \(trend.monthlyChange != nil ? String(format: "%.1f", trend.monthlyChange!) : "N/A")
            - Trend: \(trend.trendDescription)
            """
        }
        
        // Add streak and achievements
        if let streak = streakData {
            context += """
            
            Streak Information:
            - Current Streak: \(streak.currentStreak) days
            - Longest Streak: \(streak.longestStreak) days
            """
        }
        
        if !achievements.isEmpty {
            let unlockedCount = achievements.filter { $0.isUnlocked }.count
            context += "\n- Achievements Unlocked: \(unlockedCount) / \(achievements.count)"
        }
        
        // Add meal templates
        if !mealTemplates.isEmpty {
            context += "\n\nSaved Meal Templates (\(mealTemplates.count)):"
            for template in mealTemplates.prefix(5) {
                context += "\n- \(template.name): \(template.calories) cal, \(Int(template.protein))g protein"
            }
        }
        
        context += """
        
        Instructions:
        - Be friendly, encouraging, and supportive
        - Provide specific, actionable advice based on the user's current progress
        - Reference their goals and current progress when relevant
        - Keep responses concise but informative
        - If asked about nutrition, use their current macro and calorie data
        - If asked about fitness, consider their profile information, training history, and goals
        - Adapt your communication style to their coaching preference
        - Provide detail level matching their preference
        """
        
        return context
    }
}

