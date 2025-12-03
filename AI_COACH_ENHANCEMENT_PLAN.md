# AI Coach Enhancement Plan

This document outlines the implementation plan for enhancing the AI Coach to be a fully personalized, context-aware fitness and nutrition assistant with persistent chat history and workout plan generation capabilities.

---

## Table of Contents

1. [Overview](#overview)
2. [Phase 1: Enhanced User Context](#phase-1-enhanced-user-context)
3. [Phase 2: Extended User Profile & Goals](#phase-2-extended-user-profile--goals)
4. [Phase 3: Persistent Chat History](#phase-3-persistent-chat-history)
5. [Phase 4: Workout Plans Feature](#phase-4-workout-plans-feature)
6. [Phase 5: AI-Generated Workout Plans](#phase-5-ai-generated-workout-plans)
7. [Data Models](#data-models)
8. [File Changes Summary](#file-changes-summary)
9. [Implementation Order](#implementation-order)

---

## Overview

### Current State
- AI Coach has access to: basic profile, today's nutrition, last 5 foods
- No workout context, no historical trends, no persistent chat
- Cannot generate or save workout plans

### Target State
- Full user context: workouts, weight trends, streaks, achievements, nutrition history, meal templates
- Extended profile with detailed goals (target weight, fitness goals, training preferences)
- Persistent chat history (local cache with future Firestore sync option)
- AI can generate personalized workout plans
- New "Workout Plans" tab for saved/generated plans

---

## Phase 1: Enhanced User Context

### Goal
Give the AI Coach access to all user data for truly personalized responses.

### 1.1 Add Workout Context

**New: `WeeklyTrainingSummary` struct**

```swift
// Add to Models/Workout.swift or create Models/TrainingSummary.swift

struct WeeklyTrainingSummary {
    let sessionsThisWeek: Int
    let totalVolume: Double // total weight lifted
    let muscleGroupsWorked: [String: Int] // e.g. ["Chest": 2, "Back": 1]
    let lastWorkout: Workout?
    let averageExercisesPerSession: Double
    let averageSetsPerSession: Double
    
    var lastWorkoutDescription: String {
        guard let workout = lastWorkout else { return "No recent workouts" }
        let exercises = workout.exercises.map { $0.name }.prefix(3).joined(separator: ", ")
        return "\(workout.name): \(exercises)"
    }
    
    var lastWorkoutDateString: String {
        guard let workout = lastWorkout else { return "N/A" }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: workout.date, relativeTo: Date())
    }
    
    var muscleGroupsSummary: String {
        muscleGroupsWorked.map { "\($0.key): \($0.value)x" }.joined(separator: ", ")
    }
}
```

**Update: `WorkoutViewModel.swift`**

Add computed property:

```swift
var weeklyTrainingSummary: WeeklyTrainingSummary {
    let calendar = Calendar.current
    let weekAgo = calendar.date(byAdding: .day, value: -7, to: Date())!
    
    let thisWeekWorkouts = workouts.filter { $0.date >= weekAgo }
    
    // Calculate muscle groups worked
    var muscleGroups: [String: Int] = [:]
    var totalVolume: Double = 0
    var totalExercises = 0
    var totalSets = 0
    
    for workout in thisWeekWorkouts {
        for exercise in workout.exercises {
            totalExercises += 1
            for set in exercise.sets {
                totalSets += 1
                if let weight = set.weight, let reps = set.reps {
                    totalVolume += weight * Double(reps)
                }
            }
            // Map exercise to muscle group (simplified)
            // You could use ExerciseTemplate's muscleGroups for accuracy
        }
    }
    
    return WeeklyTrainingSummary(
        sessionsThisWeek: thisWeekWorkouts.count,
        totalVolume: totalVolume,
        muscleGroupsWorked: muscleGroups,
        lastWorkout: workouts.first,
        averageExercisesPerSession: thisWeekWorkouts.isEmpty ? 0 : Double(totalExercises) / Double(thisWeekWorkouts.count),
        averageSetsPerSession: thisWeekWorkouts.isEmpty ? 0 : Double(totalSets) / Double(thisWeekWorkouts.count)
    )
}
```

### 1.2 Add Weight History Context

**New: `WeightTrend` struct**

```swift
// Models/WeightTrend.swift

struct WeightEntry: Identifiable, Codable {
    let id: UUID
    let weight: Double
    let date: Date
    
    init(id: UUID = UUID(), weight: Double, date: Date = Date()) {
        self.id = id
        self.weight = weight
        self.date = date
    }
}

struct WeightTrend {
    let entries: [WeightEntry]
    
    var currentWeight: Double? { entries.first?.weight }
    var weekAgoWeight: Double? {
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
        return entries.first { $0.date <= weekAgo }?.weight
    }
    var monthAgoWeight: Double? {
        let monthAgo = Calendar.current.date(byAdding: .month, value: -1, to: Date())!
        return entries.first { $0.date <= monthAgo }?.weight
    }
    
    var weeklyChange: Double? {
        guard let current = currentWeight, let weekAgo = weekAgoWeight else { return nil }
        return current - weekAgo
    }
    
    var monthlyChange: Double? {
        guard let current = currentWeight, let monthAgo = monthAgoWeight else { return nil }
        return current - monthAgo
    }
    
    var trendDescription: String {
        guard let weekly = weeklyChange else { return "Not enough data" }
        if abs(weekly) < 0.2 { return "Stable" }
        return weekly > 0 ? "Gaining \(String(format: "%.1f", weekly)) kg/week" : "Losing \(String(format: "%.1f", abs(weekly))) kg/week"
    }
}
```

### 1.3 Add Weekly Nutrition Summary

**New: `WeeklyNutritionSummary` struct**

```swift
// Add to Models/DailyLog.swift or create Models/NutritionSummary.swift

struct WeeklyNutritionSummary {
    let avgCalories: Double
    let avgProtein: Double
    let avgCarbs: Double
    let avgFats: Double
    let calorieGoal: Double
    let proteinGoal: Double
    let daysLogged: Int
    let daysOnCalorieTarget: Int // within ±10%
    let daysOnProteinTarget: Int
    let loggingStreak: Int
    
    var notablePatternDescription: String {
        var patterns: [String] = []
        
        let calorieAccuracy = avgCalories / calorieGoal
        if calorieAccuracy < 0.85 {
            patterns.append("Often under-eating calories")
        } else if calorieAccuracy > 1.15 {
            patterns.append("Often over-eating calories")
        }
        
        let proteinAccuracy = avgProtein / proteinGoal
        if proteinAccuracy < 0.85 {
            patterns.append("Struggling to hit protein goal")
        }
        
        if patterns.isEmpty {
            return "Consistent with targets"
        }
        return patterns.joined(separator: "; ")
    }
}
```

**Update: `HomeViewModel.swift` or create dedicated service**

Add method to calculate weekly summary from `dailyLogs`:

```swift
func calculateWeeklySummary() async -> WeeklyNutritionSummary? {
    // Fetch last 7 days of daily logs
    // Calculate averages and patterns
    // Return summary
}
```

### 1.4 Add Streaks & Achievements Context

**Update: `UserContextService.swift`**

Add properties:

```swift
@Published var streakData: Streak?
@Published var achievements: [Achievement] = []
```

### 1.5 Add Meal Templates Context

**Update: `UserContextService.swift`**

Add property:

```swift
@Published var mealTemplates: [MealTemplate] = []
```

---

## Phase 2: Extended User Profile & Goals

### Goal
Allow users to set detailed fitness goals and preferences that the AI Coach can use.

### 2.1 Extend UserProfile Model

**Update: `Models/Food.swift` (where UserProfile is defined) or create separate file**

```swift
struct UserProfile: Codable {
    // Existing fields
    var name: String
    var dateJoined: Date
    var weight: Double
    var height: String
    var gender: String
    var dailyCaloriesGoal: Int
    var macros: MacroGoals
    var waterGoal: Double
    var useMetricUnits: Bool
    
    // NEW: Goal & Training Context
    var primaryGoal: FitnessGoal?
    var targetWeight: Double?
    var targetDate: Date?
    var trainingExperience: TrainingExperience?
    var trainingSplit: TrainingSplit?
    var activityLevel: ActivityLevel?
    var preferredTrainingDays: [Weekday]?
    
    // NEW: Diet & Lifestyle Context
    var dietType: DietType?
    var allergies: [String]?
    var dislikedFoods: [String]?
    var mealPattern: MealPattern?
    
    // NEW: Coaching Preferences
    var coachingStyle: CoachingStyle?
    var detailPreference: DetailPreference?
    
    // Computed descriptions for AI context
    var goalDescription: String {
        primaryGoal?.rawValue ?? "Not set"
    }
    
    var targetDateString: String {
        guard let date = targetDate else { return "Not set" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    
    var restrictionsDescription: String {
        let restrictions = (allergies ?? []) + (dislikedFoods?.map { "dislikes \($0)" } ?? [])
        return restrictions.isEmpty ? "None" : restrictions.joined(separator: ", ")
    }
}

// Supporting Enums
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
```

### 2.2 Create Goals Settings View

**New: `Views/Profile/GoalsSettingsView.swift`**

A dedicated view for users to set:
- Primary fitness goal
- Target weight & date
- Training experience & split
- Activity level
- Diet type & restrictions
- Coaching preferences

This should be accessible from Profile → Settings or a dedicated "Goals" section.

---

## Phase 3: Persistent Chat History

### Goal
Save chat conversations locally so users can continue conversations and reference past advice.

### 3.1 Create Chat Storage Service

**New: `Services/ChatStorageService.swift`**

```swift
import Foundation

actor ChatStorageService {
    static let shared = ChatStorageService()
    
    private let fileManager = FileManager.default
    private var cacheDirectory: URL {
        fileManager.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("ChatHistory")
    }
    
    private init() {
        // Create directory if needed
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }
    
    // MARK: - Conversation Management
    
    func saveConversation(_ conversation: ChatConversation) throws {
        let fileURL = cacheDirectory.appendingPathComponent("\(conversation.id.uuidString).json")
        let data = try JSONEncoder().encode(conversation)
        try data.write(to: fileURL)
    }
    
    func loadConversation(id: UUID) throws -> ChatConversation? {
        let fileURL = cacheDirectory.appendingPathComponent("\(id.uuidString).json")
        guard fileManager.fileExists(atPath: fileURL.path) else { return nil }
        let data = try Data(contentsOf: fileURL)
        return try JSONDecoder().decode(ChatConversation.self, from: data)
    }
    
    func loadAllConversations() throws -> [ChatConversation] {
        let files = try fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: nil)
        return files.compactMap { url -> ChatConversation? in
            guard url.pathExtension == "json" else { return nil }
            guard let data = try? Data(contentsOf: url) else { return nil }
            return try? JSONDecoder().decode(ChatConversation.self, from: data)
        }.sorted { $0.lastUpdated > $1.lastUpdated }
    }
    
    func deleteConversation(id: UUID) throws {
        let fileURL = cacheDirectory.appendingPathComponent("\(id.uuidString).json")
        try fileManager.removeItem(at: fileURL)
    }
    
    func clearAllConversations() throws {
        let files = try fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: nil)
        for file in files {
            try fileManager.removeItem(at: file)
        }
    }
}
```

### 3.2 Create Chat Models

**New: `Models/ChatConversation.swift`**

```swift
import Foundation

struct ChatConversation: Identifiable, Codable {
    let id: UUID
    var title: String
    var messages: [ChatMessage]
    var createdAt: Date
    var lastUpdated: Date
    
    init(id: UUID = UUID(), title: String = "New Conversation", messages: [ChatMessage] = []) {
        self.id = id
        self.title = title
        self.messages = messages
        self.createdAt = Date()
        self.lastUpdated = Date()
    }
    
    mutating func addMessage(_ message: ChatMessage) {
        messages.append(message)
        lastUpdated = Date()
        
        // Auto-generate title from first user message if still default
        if title == "New Conversation",
           let firstUserMessage = messages.first(where: { $0.isUser }) {
            title = String(firstUserMessage.content.prefix(50))
            if firstUserMessage.content.count > 50 {
                title += "..."
            }
        }
    }
}

struct ChatMessage: Identifiable, Codable {
    let id: UUID
    let content: String
    let isUser: Bool
    let timestamp: Date
    
    init(id: UUID = UUID(), content: String, isUser: Bool, timestamp: Date = Date()) {
        self.id = id
        self.content = content
        self.isUser = isUser
        self.timestamp = timestamp
    }
}
```

### 3.3 Update AICoachViewModel

**Update: `ViewModels/AICoachViewModel.swift`**

```swift
class AICoachViewModel: ObservableObject {
    @Published var currentConversation: ChatConversation
    @Published var conversations: [ChatConversation] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let chatGPTService: ChatGPTService
    private let userContextService: UserContextService
    private let chatStorage = ChatStorageService.shared
    
    init(...) {
        // Load or create conversation
        self.currentConversation = ChatConversation()
        
        Task {
            await loadConversations()
        }
    }
    
    func loadConversations() async {
        do {
            let loaded = try await chatStorage.loadAllConversations()
            await MainActor.run {
                self.conversations = loaded
                // Load most recent or create new
                if let recent = loaded.first {
                    self.currentConversation = recent
                }
            }
        } catch {
            print("Failed to load conversations: \(error)")
        }
    }
    
    func saveCurrentConversation() {
        Task {
            try? await chatStorage.saveConversation(currentConversation)
        }
    }
    
    func startNewConversation() {
        saveCurrentConversation()
        currentConversation = ChatConversation()
        // Add welcome message
        let welcome = ChatMessage(
            content: "Hi! I'm your AI fitness coach. How can I help you today?",
            isUser: false
        )
        currentConversation.addMessage(welcome)
    }
    
    func selectConversation(_ conversation: ChatConversation) {
        saveCurrentConversation()
        currentConversation = conversation
    }
    
    func sendMessage(_ content: String) {
        // ... existing logic ...
        
        // After receiving response, save conversation
        saveCurrentConversation()
    }
}
```

### 3.4 Update AICoachView

**Update: `Views/AICoach/AICoachView.swift`**

Add:
- Conversation list sidebar/sheet
- "New Chat" button
- Conversation title display
- Swipe to delete conversations

---

## Phase 4: Workout Plans Feature

### Goal
Add a "Workout Plans" tab where users can view, create, and follow structured workout programs.

### 4.1 Create Workout Plan Models

**New: `Models/WorkoutPlan.swift`**

```swift
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
    
    init(
        id: UUID = UUID(),
        name: String,
        description: String? = nil,
        goal: FitnessGoal? = nil,
        difficulty: PlanDifficulty = .intermediate,
        durationWeeks: Int = 4,
        daysPerWeek: Int = 4,
        workoutTemplates: [WorkoutTemplate] = [],
        createdBy: PlanCreator = .user
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
```

### 4.2 Create Workout Plans Service

**New: `Services/WorkoutPlanService.swift`**

```swift
import Foundation
import FirebaseFirestore
import FirebaseAuth

@MainActor
class WorkoutPlanService: ObservableObject {
    @Published var plans: [WorkoutPlan] = []
    @Published var activePlan: WorkoutPlan?
    
    private let firestore = FirestoreService.shared
    private let auth = AuthService.shared
    
    func loadPlans() async {
        guard let user = auth.user else { return }
        
        do {
            plans = try await firestore.fetchWorkoutPlans(userId: user.uid)
            activePlan = plans.first { $0.isActive }
        } catch {
            print("Error loading workout plans: \(error)")
        }
    }
    
    func savePlan(_ plan: WorkoutPlan) async throws {
        guard let user = auth.user else { return }
        try await firestore.saveWorkoutPlan(userId: user.uid, plan: plan)
        await loadPlans()
    }
    
    func setActivePlan(_ plan: WorkoutPlan) async throws {
        guard let user = auth.user else { return }
        
        // Deactivate all other plans
        for var existingPlan in plans where existingPlan.isActive {
            existingPlan.isActive = false
            try await firestore.updateWorkoutPlan(userId: user.uid, plan: existingPlan)
        }
        
        // Activate selected plan
        var updatedPlan = plan
        updatedPlan.isActive = true
        try await firestore.updateWorkoutPlan(userId: user.uid, plan: updatedPlan)
        
        await loadPlans()
    }
    
    func deletePlan(_ plan: WorkoutPlan) async throws {
        guard let user = auth.user, let planId = plan.planId else { return }
        try await firestore.deleteWorkoutPlan(userId: user.uid, planId: planId)
        await loadPlans()
    }
}
```

### 4.3 Add Firestore Methods

**Update: `Services/FirestoreService.swift`**

Add CRUD methods for workout plans:

```swift
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
    
    try await planRef.setData(data, merge: true)
}

func deleteWorkoutPlan(userId: String, planId: String) async throws {
    try await db.collection("users").document(userId)
        .collection("workoutPlans").document(planId)
        .delete()
}
```

### 4.4 Create Workout Plans Views

**New: `Views/Workouts/WorkoutPlansView.swift`**

Main view showing:
- Active plan (if any) with quick-start button
- List of all saved plans
- "Create Plan" button
- "Generate with AI" button

**New: `Views/Workouts/WorkoutPlanDetailView.swift`**

Shows full plan details:
- Plan overview (name, goal, duration, days/week)
- List of workout days with exercises
- "Start Today's Workout" button
- Edit/Delete options

**New: `Views/Workouts/CreateWorkoutPlanView.swift`**

Manual plan creation:
- Plan name, description
- Goal selection
- Add workout days
- Add exercises to each day

### 4.5 Update Workout Tab Navigation

**Update: `Views/Workouts/WorkoutListView.swift`**

Add a segmented control or tab bar at the top:

```swift
enum WorkoutTab: String, CaseIterable {
    case history = "History"
    case plans = "Plans"
}

struct WorkoutListView: View {
    @State private var selectedTab: WorkoutTab = .history
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Tab selector
                Picker("", selection: $selectedTab) {
                    ForEach(WorkoutTab.allCases, id: \.self) { tab in
                        Text(tab.rawValue).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .padding()
                
                // Content
                switch selectedTab {
                case .history:
                    WorkoutHistoryView(viewModel: viewModel)
                case .plans:
                    WorkoutPlansView()
                }
            }
            .navigationTitle("Workouts")
        }
    }
}
```

---

## Phase 5: AI-Generated Workout Plans

### Goal
Allow the AI Coach to generate personalized workout plans based on user profile, goals, and preferences.

### 5.1 Add Plan Generation to ChatGPTService

**Update: `Services/ChatGPTService.swift`**

```swift
func generateWorkoutPlan(
    goal: FitnessGoal,
    experience: TrainingExperience,
    daysPerWeek: Int,
    split: TrainingSplit?,
    equipment: [String]?,
    constraints: String?
) async throws -> WorkoutPlan {
    let prompt = """
    Generate a \(daysPerWeek)-day per week workout plan for someone with the following profile:
    - Goal: \(goal.rawValue)
    - Experience: \(experience.rawValue)
    - Preferred Split: \(split?.rawValue ?? "Any")
    - Available Equipment: \(equipment?.joined(separator: ", ") ?? "Full gym")
    - Constraints: \(constraints ?? "None")
    
    Return the plan as JSON with this exact structure:
    {
        "name": "Plan name",
        "description": "Brief description",
        "durationWeeks": 4,
        "workoutTemplates": [
            {
                "name": "Day 1: Push",
                "dayNumber": 1,
                "exercises": [
                    {
                        "name": "Exercise name",
                        "targetSets": 3,
                        "targetReps": "8-12",
                        "restSeconds": 90,
                        "notes": "Optional coaching cue",
                        "alternatives": ["Alt exercise 1", "Alt exercise 2"]
                    }
                ],
                "notes": "Optional day notes"
            }
        ]
    }
    
    Include 4-6 exercises per day. Provide alternatives for each exercise.
    """
    
    // Send to API and parse response into WorkoutPlan
    // Similar to estimateFood() parsing
}
```

### 5.2 Create AI Plan Generator View

**New: `Views/Workouts/GeneratePlanView.swift`**

A form where users specify:
- Goal (bulk, cut, strength, etc.)
- Days per week (3-6)
- Preferred split (or let AI decide)
- Available equipment
- Any constraints (injuries, time limits)

Then generates and previews the plan before saving.

### 5.3 Add Generation from AI Coach Chat

Users can also ask the AI Coach to generate a plan in conversation:
- "Create me a 4-day push/pull/legs program for muscle building"
- AI responds with plan summary and offers to save it

**Update: `AICoachViewModel.swift`**

Add intent detection for workout plan requests and trigger generation flow.

---

## Data Models

### New Files to Create

| File | Purpose |
|------|---------|
| `Models/WeightTrend.swift` | Weight entry and trend tracking |
| `Models/NutritionSummary.swift` | Weekly/monthly nutrition summaries |
| `Models/TrainingSummary.swift` | Weekly training summary |
| `Models/ChatConversation.swift` | Chat history models |
| `Models/WorkoutPlan.swift` | Workout plan and template models |

### Models to Update

| File | Changes |
|------|---------|
| `Models/Food.swift` (UserProfile) | Add goal, training, diet, and coaching preference fields |
| `Models/Workout.swift` | Add `WeeklyTrainingSummary` computed property helper |

---

## File Changes Summary

### New Files

```
Models/
├── WeightTrend.swift
├── NutritionSummary.swift
├── TrainingSummary.swift
├── ChatConversation.swift
└── WorkoutPlan.swift

Services/
├── ChatStorageService.swift
└── WorkoutPlanService.swift

Views/
├── Profile/
│   └── GoalsSettingsView.swift
├── Workouts/
│   ├── WorkoutPlansView.swift
│   ├── WorkoutPlanDetailView.swift
│   ├── CreateWorkoutPlanView.swift
│   └── GeneratePlanView.swift
└── AICoach/
    └── ConversationListView.swift
```

### Updated Files

```
Models/
└── Food.swift (or UserProfile.swift) - Extended profile

ViewModels/
├── AICoachViewModel.swift - Chat persistence
├── WorkoutViewModel.swift - Training summary
├── HomeViewModel.swift - Weekly nutrition summary
└── ProfileViewModel.swift - Extended profile handling

Services/
├── UserContextService.swift - Full context building
├── FirestoreService.swift - Workout plans CRUD
└── ChatGPTService.swift - Plan generation

Views/
├── Workouts/WorkoutListView.swift - Tab navigation
├── AICoach/AICoachView.swift - Conversation UI
└── Profile/ProfileView.swift - Goals link
```

---

## Implementation Order

### Sprint 1: Foundation (Week 1)
1. ✅ Create extended `UserProfile` model with all new fields
2. ✅ Create `GoalsSettingsView` for users to set goals
3. ✅ Update `ProfileViewModel` to handle new fields
4. ✅ Update Firestore to persist extended profile

### Sprint 2: Context Enhancement (Week 2)
1. ✅ Create `WeeklyTrainingSummary` and add to `WorkoutViewModel`
2. ✅ Create `WeeklyNutritionSummary` and add calculation to `HomeViewModel`
3. ✅ Create `WeightTrend` model and tracking
4. ✅ Update `UserContextService` with all new context

### Sprint 3: Chat Persistence (Week 3)
1. ✅ Create `ChatConversation` and `ChatMessage` models
2. ✅ Create `ChatStorageService` for local persistence
3. ✅ Update `AICoachViewModel` with conversation management
4. ✅ Update `AICoachView` with conversation list UI

### Sprint 4: Workout Plans (Week 4)
1. ✅ Create `WorkoutPlan` models
2. ✅ Create `WorkoutPlanService`
3. ✅ Add Firestore methods for plans
4. ✅ Create basic `WorkoutPlansView` and `WorkoutPlanDetailView`
5. ✅ Update `WorkoutListView` with tab navigation

### Sprint 5: AI Plan Generation (Week 5)
1. ✅ Add plan generation to `ChatGPTService`
2. ✅ Create `GeneratePlanView`
3. ✅ Create `CreateWorkoutPlanView` for manual creation
4. ✅ Add plan generation from chat intent detection

### Sprint 6: Polish & Testing (Week 6)
1. ✅ End-to-end testing of all features
2. ✅ UI polish and animations
3. ✅ Error handling and edge cases
4. ✅ Performance optimization

---

## Future Considerations

### Cloud Sync for Chat History
- Currently using local cache
- Future: Sync to Firestore for cross-device access
- Consider privacy implications

### Pre-built Plan Templates
- Add curated workout plan templates
- "Beginner Full Body", "PPL Hypertrophy", "5/3/1 Strength"
- Users can use as-is or customize

### Plan Progress Tracking
- Track which weeks/days user has completed
- Show progress through the program
- Auto-suggest next workout

### Smart Recommendations
- AI suggests when to deload
- Recommends plan changes based on progress
- Alerts if user is over/under training

---

*Document Version: 1.0*
*Last Updated: December 2024*

