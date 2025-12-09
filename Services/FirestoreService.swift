//
//  FirestoreService.swift
//  Gains
//
//  Created by Rayaan Bokhari on 11/20/25.
//
import Foundation
import FirebaseFirestore

final class FirestoreService {
    static let shared = FirestoreService()
    private init() {}
    
    private let db = Firestore.firestore()
    
    // MARK: - Daily Logs
    
    func saveDailyLog(userId: String, log: DailyLog) async throws {
        let logId = log.id ?? Self.todayId()
        
        let docRef = db
            .collection("users")
            .document(userId)
            .collection("dailyLogs")
            .document(logId)
        
        var data = try Firestore.Encoder().encode(log)
        // Ensure ID is consistent
        data["id"] = logId
        
        try await docRef.setData(data, merge: true)
    }
    
    func fetchDailyLog(userId: String, for date: Date) async throws -> DailyLog? {
        let logId = Self.id(for: date)
        
        let docRef = db
            .collection("users")
            .document(userId)
            .collection("dailyLogs")
            .document(logId)
        
        let snapshot = try await docRef.getDocument()
        guard snapshot.exists else { return nil }
        
        var log = try snapshot.data(as: DailyLog.self)
        log.id = logId
        return log
    }
    
    func fetchDailyLogsRange(userId: String, from startDate: Date, to endDate: Date) async throws -> [DailyLog] {
        let startId = Self.id(for: startDate)
        let endId = Self.id(for: endDate)
        
        let snapshot = try await db
            .collection("users")
            .document(userId)
            .collection("dailyLogs")
            .whereField("id", isGreaterThanOrEqualTo: startId)
            .whereField("id", isLessThanOrEqualTo: endId)
            .getDocuments()
        
        return snapshot.documents.compactMap { doc -> DailyLog? in
            guard var log = try? doc.data(as: DailyLog.self) else {
                return nil
            }
            log.id = doc.documentID
            return log
        }.sorted { log1, log2 in
            (log1.date) < (log2.date)
        }
    }
    
    // MARK: - Meals
    
    func saveMeal(userId: String, food: Food, toDate date: Date) async throws {
        let logId = Self.id(for: date)
        
        let mealRef = db
            .collection("users")
            .document(userId)
            .collection("meals")
            .document()
        
        var mealData: [String: Any] = [
            "id": mealRef.documentID,
            "name": food.name,
            "calories": food.calories,
            "protein": food.protein,
            "carbs": food.carbs,
            "fats": food.fats,
            "loggedAt": Timestamp(date: food.loggedAt),
            "date": Self.id(for: date)
        ]
        
        // Add photo URL if present
        if let photoUrl = food.photoUrl {
            mealData["photoUrl"] = photoUrl
        }
        
        try await mealRef.setData(mealData)
        
        // Update the daily log to include this meal and update totals
        let logRef = db
            .collection("users")
            .document(userId)
            .collection("dailyLogs")
            .document(logId)
        
        try await logRef.setData([
            "id": logId,
            "date": Timestamp(date: date),
            "calories": FieldValue.increment(Int64(food.calories)),
            "protein": FieldValue.increment(Int64(food.protein)),
            "carbs": FieldValue.increment(Int64(food.carbs)),
            "fats": FieldValue.increment(Int64(food.fats)),
            "mealIds": FieldValue.arrayUnion([mealRef.documentID])
        ], merge: true)
    }
    
    func fetchMeals(userId: String, for date: Date) async throws -> [Food] {
        let dateId = Self.id(for: date)
        
        // Query by date only (no orderBy to avoid index requirement)
        // We'll sort in memory instead
        let snapshot = try await db
            .collection("users")
            .document(userId)
            .collection("meals")
            .whereField("date", isEqualTo: dateId)
            .getDocuments()
        
        let meals = snapshot.documents.compactMap { doc -> Food? in
            let data = doc.data()
            
            // Handle calories - could be Int or Double
            var calories: Int = 0
            if let calInt = data["calories"] as? Int {
                calories = calInt
            } else if let calDouble = data["calories"] as? Double {
                calories = Int(calDouble)
            } else {
                return nil
            }
            
            // Handle macros - could be Double or Int
            var protein: Double = 0
            var carbs: Double = 0
            var fats: Double = 0
            
            if let p = data["protein"] as? Double {
                protein = p
            } else if let p = data["protein"] as? Int {
                protein = Double(p)
            } else {
                return nil
            }
            
            if let c = data["carbs"] as? Double {
                carbs = c
            } else if let c = data["carbs"] as? Int {
                carbs = Double(c)
            } else {
                return nil
            }
            
            if let f = data["fats"] as? Double {
                fats = f
            } else if let f = data["fats"] as? Int {
                fats = Double(f)
            } else {
                return nil
            }
            
            guard let name = data["name"] as? String,
                  let timestamp = data["loggedAt"] as? Timestamp else {
                return nil
            }
            
            let photoUrl = data["photoUrl"] as? String
            
            return Food(
                id: UUID(),
                name: name,
                calories: calories,
                protein: protein,
                carbs: carbs,
                fats: fats,
                loggedAt: timestamp.dateValue(),
                photoUrl: photoUrl,
                mealId: doc.documentID
            )
        }
        
        // Sort by loggedAt descending in memory
        return meals.sorted { $0.loggedAt > $1.loggedAt }
    }
    
    func updateMeal(userId: String, mealId: String, food: Food, oldFood: Food, toDate date: Date) async throws {
        let dateId = Self.id(for: date)
        
        let mealRef = db
            .collection("users")
            .document(userId)
            .collection("meals")
            .document(mealId)
        
        var mealData: [String: Any] = [
            "id": mealId,
            "name": food.name,
            "calories": food.calories,
            "protein": food.protein,
            "carbs": food.carbs,
            "fats": food.fats,
            "loggedAt": Timestamp(date: food.loggedAt),
            "date": dateId
        ]
        
        // Add photo URL if present
        if let photoUrl = food.photoUrl {
            mealData["photoUrl"] = photoUrl
        } else {
            // Remove photoUrl field if it was removed
            mealData["photoUrl"] = FieldValue.delete()
        }
        
        try await mealRef.setData(mealData, merge: true)
        
        // Update the daily log totals
        // Subtract old values, add new values
        let logRef = db
            .collection("users")
            .document(userId)
            .collection("dailyLogs")
            .document(dateId)
        
        let caloriesDiff = food.calories - oldFood.calories
        let proteinDiff = food.protein - oldFood.protein
        let carbsDiff = food.carbs - oldFood.carbs
        let fatsDiff = food.fats - oldFood.fats
        
        try await logRef.setData([
            "id": dateId,
            "date": Timestamp(date: date),
            "calories": FieldValue.increment(Int64(caloriesDiff)),
            "protein": FieldValue.increment(proteinDiff),
            "carbs": FieldValue.increment(carbsDiff),
            "fats": FieldValue.increment(fatsDiff)
        ], merge: true)
    }
    
    func deleteMeal(userId: String, mealId: String, food: Food, fromDate date: Date) async throws {
        let dateId = Self.id(for: date)
        
        // Delete the meal document
        let mealRef = db
            .collection("users")
            .document(userId)
            .collection("meals")
            .document(mealId)
        
        try await mealRef.delete()
        
        // Update the daily log totals (subtract the meal's values)
        let logRef = db
            .collection("users")
            .document(userId)
            .collection("dailyLogs")
            .document(dateId)
        
        try await logRef.setData([
            "id": dateId,
            "date": Timestamp(date: date),
            "calories": FieldValue.increment(Int64(-food.calories)),
            "protein": FieldValue.increment(-food.protein),
            "carbs": FieldValue.increment(-food.carbs),
            "fats": FieldValue.increment(-food.fats),
            "mealIds": FieldValue.arrayRemove([mealId])
        ], merge: true)
    }
    
    // MARK: - User Profile
    
    func saveUserProfile(userId: String, profile: UserProfile) async throws {
        let profileRef = db
            .collection("users")
            .document(userId)
            .collection("profile")
            .document("data")
        
        var data = try Firestore.Encoder().encode(profile)
        // Ensure dateJoined is stored as Timestamp
        data["dateJoined"] = Timestamp(date: profile.dateJoined)
        
        print("🔥 FirestoreService: Saving profile to users/\(userId)/profile/data")
        print("🔥 FirestoreService: Profile data keys: \(data.keys.sorted())")
        
        try await profileRef.setData(data, merge: true)
        
        print("✅ FirestoreService: Profile successfully saved to Firestore")
    }
    
    func fetchUserProfile(userId: String) async throws -> UserProfile? {
        let profileRef = db
            .collection("users")
            .document(userId)
            .collection("profile")
            .document("data")
        
        let snapshot = try await profileRef.getDocument()
        guard snapshot.exists else { return nil }
        
        return try snapshot.data(as: UserProfile.self)
    }
    
    // MARK: - Meal Templates
    
    func saveMealTemplate(userId: String, template: MealTemplate) async throws {
        let templateRef: DocumentReference
        if let templateId = template.mealTemplateId {
            templateRef = db
                .collection("users")
                .document(userId)
                .collection("mealTemplates")
                .document(templateId)
        } else {
            templateRef = db
                .collection("users")
                .document(userId)
                .collection("mealTemplates")
                .document()
        }
        
        var data = try Firestore.Encoder().encode(template)
        data["id"] = templateRef.documentID
        data["mealTemplateId"] = templateRef.documentID
        data["createdAt"] = Timestamp(date: template.createdAt)
        
        try await templateRef.setData(data)
    }
    
    func fetchMealTemplates(userId: String) async throws -> [MealTemplate] {
        let snapshot = try await db
            .collection("users")
            .document(userId)
            .collection("mealTemplates")
            .order(by: "createdAt", descending: true)
            .getDocuments()
        
        return snapshot.documents.compactMap { doc -> MealTemplate? in
            guard var template = try? doc.data(as: MealTemplate.self) else {
                return nil
            }
            template.mealTemplateId = doc.documentID
            return template
        }
    }
    
    func deleteMealTemplate(userId: String, templateId: String) async throws {
        let templateRef = db
            .collection("users")
            .document(userId)
            .collection("mealTemplates")
            .document(templateId)
        
        try await templateRef.delete()
    }
    
    // MARK: - Workouts
    
    func saveWorkout(userId: String, workout: Workout) async throws {
        let workoutRef: DocumentReference
        if let workoutId = workout.workoutId {
            workoutRef = db
                .collection("users")
                .document(userId)
                .collection("workouts")
                .document(workoutId)
        } else {
            workoutRef = db
                .collection("users")
                .document(userId)
                .collection("workouts")
                .document()
        }
        
        print("FirestoreService: Saving workout to users/\(userId)/workouts/\(workoutRef.documentID)")
        
        var data = try Firestore.Encoder().encode(workout)
        // Don't overwrite 'id' - keep the UUID string from encoding
        // Only set workoutId to the Firestore document ID
        data["workoutId"] = workoutRef.documentID
        data["date"] = Timestamp(date: workout.date)
        
        try await workoutRef.setData(data)
        print("FirestoreService: Workout document saved successfully")
    }
    
    func fetchWorkouts(userId: String) async throws -> [Workout] {
        let snapshot = try await db
            .collection("users")
            .document(userId)
            .collection("workouts")
            .order(by: "date", descending: true)
            .getDocuments()
        
        return snapshot.documents.compactMap { doc -> Workout? in
            guard var workout = try? doc.data(as: Workout.self) else {
                return nil
            }
            workout.workoutId = doc.documentID
            return workout
        }
    }
    
    func updateWorkout(userId: String, workoutId: String, workout: Workout) async throws {
        let workoutRef = db
            .collection("users")
            .document(userId)
            .collection("workouts")
            .document(workoutId)
        
        var data = try Firestore.Encoder().encode(workout)
        data["id"] = workoutId
        data["workoutId"] = workoutId
        data["date"] = Timestamp(date: workout.date)
        
        try await workoutRef.setData(data, merge: true)
    }
    
    func deleteWorkout(userId: String, workoutId: String) async throws {
        let workoutRef = db
            .collection("users")
            .document(userId)
            .collection("workouts")
            .document(workoutId)
        
        try await workoutRef.delete()
    }
    
    // MARK: - Exercise Templates
    
    func saveExerciseTemplate(userId: String, template: ExerciseTemplate) async throws {
        let templateRef: DocumentReference
        if let templateId = template.templateId {
            templateRef = db
                .collection("users")
                .document(userId)
                .collection("exerciseTemplates")
                .document(templateId)
        } else {
            templateRef = db
                .collection("users")
                .document(userId)
                .collection("exerciseTemplates")
                .document()
        }
        
        var data = try Firestore.Encoder().encode(template)
        data["id"] = templateRef.documentID
        data["templateId"] = templateRef.documentID
        
        try await templateRef.setData(data)
    }
    
    func fetchExerciseTemplates(userId: String) async throws -> [ExerciseTemplate] {
        let snapshot = try await db
            .collection("users")
            .document(userId)
            .collection("exerciseTemplates")
            .getDocuments()
        
        return snapshot.documents.compactMap { doc -> ExerciseTemplate? in
            guard var template = try? doc.data(as: ExerciseTemplate.self) else {
                return nil
            }
            template.templateId = doc.documentID
            return template
        }
    }
    
    func deleteExerciseTemplate(userId: String, templateId: String) async throws {
        let templateRef = db
            .collection("users")
            .document(userId)
            .collection("exerciseTemplates")
            .document(templateId)
        
        try await templateRef.delete()
    }
    
    // MARK: - Streaks
    
    func updateStreak(userId: String, streak: Streak) async throws {
        let streakRef = db
            .collection("users")
            .document(userId)
            .collection("streaks")
            .document("current")
        
        var data = try Firestore.Encoder().encode(streak)
        if let lastLogged = streak.lastLoggedDate {
            data["lastLoggedDate"] = Timestamp(date: lastLogged)
        }
        
        try await streakRef.setData(data, merge: true)
    }
    
    func fetchStreak(userId: String) async throws -> Streak? {
        let streakRef = db
            .collection("users")
            .document(userId)
            .collection("streaks")
            .document("current")
        
        let snapshot = try await streakRef.getDocument()
        guard snapshot.exists else { return nil }
        
        return try snapshot.data(as: Streak.self)
    }
    
    // MARK: - Achievements
    
    func updateAchievement(userId: String, achievement: Achievement) async throws {
        let achievementRef = db
            .collection("users")
            .document(userId)
            .collection("achievements")
            .document(achievement.id)
        
        var data = try Firestore.Encoder().encode(achievement)
        if let unlockedAt = achievement.unlockedAt {
            data["unlockedAt"] = Timestamp(date: unlockedAt)
        }
        
        try await achievementRef.setData(data, merge: true)
    }
    
    func fetchAchievements(userId: String) async throws -> [Achievement] {
        let snapshot = try await db
            .collection("users")
            .document(userId)
            .collection("achievements")
            .getDocuments()
        
        return snapshot.documents.compactMap { doc -> Achievement? in
            try? doc.data(as: Achievement.self)
        }
    }
    
    // MARK: - Community Posts
    
    func createPost(userId: String, post: CommunityPost) async throws {
        let postRef = db
            .collection("posts")
            .document()
        
        var data = try Firestore.Encoder().encode(post)
        data["id"] = postRef.documentID
        data["postId"] = postRef.documentID
        data["userId"] = userId
        data["timestamp"] = Timestamp(date: post.timestamp)
        data["likeCount"] = post.likes.count
        
        try await postRef.setData(data)
    }
    
    func fetchPosts(limit: Int = 50) async throws -> [CommunityPost] {
        let snapshot = try await db
            .collection("posts")
            .order(by: "timestamp", descending: true)
            .limit(to: limit)
            .getDocuments()
        
        return snapshot.documents.compactMap { doc -> CommunityPost? in
            guard var post = try? doc.data(as: CommunityPost.self) else {
                return nil
            }
            post.postId = doc.documentID
            return post
        }
    }
    
    func likePost(postId: String, userId: String) async throws {
        let postRef = db
            .collection("posts")
            .document(postId)
        
        let postDoc = try await postRef.getDocument()
        guard var post = try? postDoc.data(as: CommunityPost.self) else {
            throw NSError(domain: "FirestoreService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Post not found"])
        }
        
        var likes = post.likes
        if likes.contains(userId) {
            // Unlike
            likes.removeAll { $0 == userId }
        } else {
            // Like
            likes.append(userId)
        }
        
        try await postRef.updateData([
            "likes": likes,
            "likeCount": likes.count
        ])
    }
    
    func deletePost(postId: String, userId: String) async throws {
        let postRef = db
            .collection("posts")
            .document(postId)
        
        // Verify ownership
        let postDoc = try await postRef.getDocument()
        guard let post = try? postDoc.data(as: CommunityPost.self),
              post.userId == userId else {
            throw NSError(domain: "FirestoreService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Unauthorized"])
        }
        
        try await postRef.delete()
    }
    
    // MARK: - Workout Plans
    
    func saveWorkoutPlan(userId: String, plan: WorkoutPlan) async throws {
        let planRef: DocumentReference
        if let planId = plan.planId {
            planRef = db.collection("users").document(userId)
                .collection("workoutPlans").document(planId)
        } else {
            planRef = db.collection("users").document(userId)
                .collection("workoutPlans").document()
        }
        
        var data = try Firestore.Encoder().encode(plan)
        data["planId"] = planRef.documentID
        data["createdAt"] = Timestamp(date: plan.createdAt)
        
        try await planRef.setData(data)
    }
    
    func fetchWorkoutPlans(userId: String) async throws -> [WorkoutPlan] {
        let snapshot = try await db.collection("users").document(userId)
            .collection("workoutPlans")
            .order(by: "createdAt", descending: true)
            .getDocuments()
        
        return snapshot.documents.compactMap { doc -> WorkoutPlan? in
            var plan = try? doc.data(as: WorkoutPlan.self)
            plan?.planId = doc.documentID
            return plan
        }
    }
    
    func updateWorkoutPlan(userId: String, plan: WorkoutPlan) async throws {
        guard let planId = plan.planId else { return }
        let planRef = db.collection("users").document(userId)
            .collection("workoutPlans").document(planId)
        
        var data = try Firestore.Encoder().encode(plan)
        data["planId"] = planId
        data["createdAt"] = Timestamp(date: plan.createdAt)
        
        try await planRef.setData(data, merge: true)
    }
    
    func deleteWorkoutPlan(userId: String, planId: String) async throws {
        try await db.collection("users").document(userId)
            .collection("workoutPlans").document(planId)
            .delete()
    }
    
    // MARK: - Dietary Plans
    
    func fetchDietaryPlans(userId: String) async throws -> [DietaryPlan] {
        let snapshot = try await db.collection("users").document(userId)
            .collection("dietaryPlans")
            .order(by: "createdAt", descending: true)
            .getDocuments()
        
        return snapshot.documents.compactMap { doc -> DietaryPlan? in
            var plan = try? doc.data(as: DietaryPlan.self)
            plan?.planId = doc.documentID
            return plan
        }
    }
    
    func saveDietaryPlan(userId: String, plan: DietaryPlan) async throws {
        let planRef = db.collection("users").document(userId)
            .collection("dietaryPlans").document(plan.id.uuidString)
        
        var data = try Firestore.Encoder().encode(plan)
        data["planId"] = plan.id.uuidString
        data["createdAt"] = Timestamp(date: plan.createdAt)
        
        try await planRef.setData(data)
    }
    
    func updateDietaryPlan(userId: String, plan: DietaryPlan) async throws {
        guard let planId = plan.planId else { return }
        let planRef = db.collection("users").document(userId)
            .collection("dietaryPlans").document(planId)
        
        var data = try Firestore.Encoder().encode(plan)
        data["planId"] = planId
        data["createdAt"] = Timestamp(date: plan.createdAt)
        
        try await planRef.setData(data, merge: true)
    }
    
    func deleteDietaryPlan(userId: String, planId: String) async throws {
        try await db.collection("users").document(userId)
            .collection("dietaryPlans").document(planId)
            .delete()
    }
    
    // MARK: - Weight Entries
    
    func saveWeightEntry(userId: String, entry: WeightEntry) async throws {
        let entryRef: DocumentReference
        if let entryId = entry.entryId {
            entryRef = db.collection("users").document(userId)
                .collection("weightEntries").document(entryId)
        } else {
            entryRef = db.collection("users").document(userId)
                .collection("weightEntries").document()
        }
        
        var data = try Firestore.Encoder().encode(entry)
        data["entryId"] = entryRef.documentID
        data["date"] = Timestamp(date: entry.date)
        
        try await entryRef.setData(data)
    }
    
    func fetchWeightEntries(userId: String, limit: Int = 90) async throws -> [WeightEntry] {
        let snapshot = try await db.collection("users").document(userId)
            .collection("weightEntries")
            .order(by: "date", descending: true)
            .limit(to: limit)
            .getDocuments()
        
        return snapshot.documents.compactMap { doc -> WeightEntry? in
            var entry = try? doc.data(as: WeightEntry.self)
            entry?.entryId = doc.documentID
            return entry
        }
    }
    
    func findWeightEntryForDate(userId: String, date: Date) async throws -> WeightEntry? {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? date
        
        let snapshot = try await db.collection("users").document(userId)
            .collection("weightEntries")
            .whereField("date", isGreaterThanOrEqualTo: Timestamp(date: startOfDay))
            .whereField("date", isLessThan: Timestamp(date: endOfDay))
            .limit(to: 1)
            .getDocuments()
        
        return snapshot.documents.first.flatMap { doc -> WeightEntry? in
            var entry = try? doc.data(as: WeightEntry.self)
            entry?.entryId = doc.documentID
            return entry
        }
    }
    
    func deleteWeightEntry(userId: String, entryId: String) async throws {
        try await db.collection("users").document(userId)
            .collection("weightEntries").document(entryId)
            .delete()
    }
    
    // MARK: - Helpers
    
    static func todayId() -> String {
        id(for: Date())
    }
    
    static func id(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter.string(from: date)
    }
}
