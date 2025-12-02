# Implementation Todos - Complete Guide

This document provides context, requirements, and step-by-step instructions for implementing all remaining features in the Gains app.

## 🎯 Quick Summary

| Todo | Complexity | Estimated Time | Priority |
|------|-----------|----------------|----------|
| Meal Templates | Low | 2-3 hours | High |
| Workout Persistence | Medium | 3-4 hours | High |
| Exercise Templates | Medium | 3-4 hours | Medium |
| Streaks & Achievements | Medium | 4-5 hours | Medium |
| Progress Tracking | High | 5-6 hours | High |
| Community Backend | High | 6-8 hours | Low |

**Recommended Order:** Meal Templates → Workout Persistence → Exercise Templates → Streaks → Progress → Community

---

## 📋 Remaining Todos

1. **Progress Tracking View** - Charts and metrics
2. **Workout Persistence** - Firestore integration
3. **Exercise Templates** - Default templates and custom ones
4. **Meal Templates** - Quick logging feature
5. **Streaks & Achievements** - Daily logging streaks
6. **Community Backend** - Real posts and social features

---

## 1. Progress Tracking View

### Current State
- `Views/Progress/ProgressView.swift` exists but only shows placeholder text
- Daily logs are stored in Firestore at `users/{userId}/dailyLogs/{dateId}`
- Meals are stored at `users/{userId}/meals/` with date field
- No weight tracking system yet (weightEntries collection exists in rules but not implemented)

### Requirements
- Display charts showing:
  - **Weight trends** over time (line chart)
  - **Calorie consumption** over time (bar/line chart)
  - **Macro progress** trends (protein, carbs, fats over time)
  - **Weekly/Monthly summaries**
- Time range selector: 7 days, 30 days, 90 days, All time
- Visual charts using SwiftUI Charts framework

### Implementation Steps

1. **Create ProgressViewModel**
   - Fetch daily logs for date range
   - Aggregate data for charts
   - Calculate averages, trends

2. **Add Firestore Methods**
   - `fetchDailyLogsRange(userId: String, from: Date, to: Date) async throws -> [DailyLog]`
   - Fetch multiple daily logs efficiently

3. **Create Chart Components**
   - WeightChartView (line chart)
   - CaloriesChartView (bar chart)
   - MacrosChartView (multi-line chart)
   - Use SwiftUI Charts framework

4. **Update ProgressView**
   - Add time range picker
   - Display charts
   - Show statistics (averages, totals, trends)

### Files to Create/Modify
- `ViewModels/ProgressViewModel.swift` (new)
- `Views/Progress/ProgressView.swift` (update)
- `Views/Progress/Charts/WeightChartView.swift` (new)
- `Views/Progress/Charts/CaloriesChartView.swift` (new)
- `Views/Progress/Charts/MacrosChartView.swift` (new)
- `Services/FirestoreService.swift` (add fetchDailyLogsRange method)

### Dependencies
- SwiftUI Charts framework (available in iOS 16+)
- Import Charts module

---

## 2. Workout Persistence

### Current State
- `Services/WorkoutService.swift` exists but only stores in memory
- `Models/Workout.swift`, `Exercise.swift`, `ExerciseSet.swift` exist
- Firestore rules already allow workouts subcollection
- No Firestore integration yet

### Requirements
- Save workouts to Firestore
- Load workouts from Firestore
- Update/delete workouts
- Persist exercise templates

### Implementation Steps

1. **Update FirestoreService**
   - `saveWorkout(userId: String, workout: Workout) async throws`
   - `fetchWorkouts(userId: String) async throws -> [Workout]`
   - `updateWorkout(userId: String, workoutId: String, workout: Workout) async throws`
   - `deleteWorkout(userId: String, workoutId: String) async throws`

2. **Update WorkoutService**
   - Replace in-memory storage with Firestore calls
   - Add async/await methods
   - Handle loading states

3. **Update WorkoutViewModel**
   - Connect to FirestoreService
   - Load workouts on init
   - Save workouts after changes

### Files to Create/Modify
- `Services/FirestoreService.swift` (add workout methods)
- `Services/WorkoutService.swift` (update to use Firestore)
- `ViewModels/WorkoutViewModel.swift` (update to load from Firestore)
- `Models/Workout.swift` (ensure Codable, add workoutId field)

### Data Structure
```
users/{userId}/workouts/{workoutId}
  - id: String (Firestore document ID)
  - workoutId: String (same as document ID for updates)
  - name: String
  - date: Timestamp
  - exercises: [Exercise] (embedded array)
    - id: UUID
    - name: String
    - sets: [ExerciseSet] (embedded array)
      - reps: Int
      - weight: Double
      - restTime: Int?
  - notes: String?
```

### Existing Models Reference
- `Workout`: Has id (UUID), name, date, exercises array, notes
- `Exercise`: Has id (UUID), name, sets array
- `ExerciseSet`: Has reps, weight, restTime
- Need to add `workoutId: String?` to Workout model for Firestore updates

---

## 3. Exercise Templates

### Current State
- `Services/ExerciseTemplateService.swift` exists but empty
- `Models/ExerciseTemplate.swift` exists
- No default templates loaded
- No persistence

### Requirements
- Load default exercise templates (common exercises)
- Allow users to create custom templates
- Save templates to Firestore
- Use templates when creating workouts

### Implementation Steps

1. **Create Default Templates**
   - Common exercises: Bench Press, Squat, Deadlift, etc.
   - Include muscle groups, equipment needed

2. **Update FirestoreService**
   - `saveExerciseTemplate(userId: String, template: ExerciseTemplate) async throws`
   - `fetchExerciseTemplates(userId: String) async throws -> [ExerciseTemplate]`
   - `deleteExerciseTemplate(userId: String, templateId: String) async throws`

3. **Update ExerciseTemplateService**
   - Load default templates on first launch
   - Load user templates from Firestore
   - Merge defaults with user templates

4. **Create Template Management UI**
   - List templates
   - Add custom template
   - Delete template

### Files to Create/Modify
- `Services/FirestoreService.swift` (add template methods)
- `Services/ExerciseTemplateService.swift` (implement)
- `Models/ExerciseTemplate.swift` (ensure Codable, add templateId)
- `Views/Exercises/ExerciseTemplateListView.swift` (update)
- `Views/Exercises/CreateTemplateView.swift` (new)

### Default Templates to Include
- **Strength**: Bench Press, Squat, Deadlift, Overhead Press, Barbell Rows, Pull-ups, Bicep Curls, Tricep Extensions, Leg Press, Calf Raises, Lunges
- **Cardio**: Running, Cycling, Rowing, Elliptical, Stair Climber
- **Flexibility**: Stretching, Yoga, Pilates

### Existing Models Reference
- `ExerciseTemplate`: Has id (UUID), name, category (enum), muscleGroups (array), equipment, instructions
- `ExerciseCategory`: Strength, Cardio, Flexibility, Other
- `MuscleGroup`: Chest, Back, Shoulders, Biceps, Triceps, Legs, Core, Full Body
- Need to add `templateId: String?` to ExerciseTemplate for Firestore updates

---

## 4. Meal Templates

### Current State
- Meals are logged individually
- No template system exists
- Food model is complete

### Requirements
- Save frequently eaten meals as templates
- Quick-add templates when logging food
- Edit/delete templates
- Templates include: name, calories, macros, optional photo

### Implementation Steps

1. **Create MealTemplate Model**
   ```swift
   struct MealTemplate: Identifiable, Codable {
       let id: UUID
       var name: String
       var calories: Int
       var protein: Double
       var carbs: Double
       var fats: Double
       var photoUrl: String?
       var mealTemplateId: String? // Firestore ID
   }
   ```

2. **Add Firestore Methods**
   - `saveMealTemplate(userId: String, template: MealTemplate) async throws`
   - `fetchMealTemplates(userId: String) async throws -> [MealTemplate]`
   - `deleteMealTemplate(userId: String, templateId: String) async throws`

3. **Update FoodLoggingView**
   - Add "Use Template" button
   - Show template picker
   - Pre-fill form from template

4. **Create Template Management**
   - Save current meal as template
   - List templates
   - Edit/delete templates

### Files to Create/Modify
- `Models/MealTemplate.swift` (new)
- `Services/FirestoreService.swift` (add template methods)
- `Views/Home/FoodLoggingView.swift` (add template selection)
- `Views/Home/MealTemplatesView.swift` (new)
- `firestore.rules` (add mealTemplates subcollection)

### Data Structure
```
users/{userId}/mealTemplates/{templateId}
  - id: String (Firestore document ID)
  - templateId: String (same as document ID)
  - name: String
  - calories: Int
  - protein: Double
  - carbs: Double
  - fats: Double
  - photoUrl: String?
  - createdAt: Timestamp
```

### Integration Points
- Add "Save as Template" button in `FoodLoggingView` after meal is logged
- Add "Use Template" button at top of `FoodLoggingView`
- Show template picker sheet
- Pre-fill all fields from template

---

## 5. Streaks & Achievements

### Current State
- Daily logs track meals
- No streak tracking
- No achievement system

### Requirements
- Track daily logging streaks
- Show current streak
- Display achievement badges
- Track milestones (7 days, 30 days, 100 days, etc.)

### Implementation Steps

1. **Create Streak Model**
   ```swift
   struct Streak: Codable {
       var currentStreak: Int
       var longestStreak: Int
       var lastLoggedDate: Date?
   }
   ```

2. **Add Streak Calculation**
   - Check if user logged meals today
   - Calculate consecutive days
   - Update streak on meal log

3. **Create Achievement System**
   - Define achievements (First Meal, Week Warrior, Month Master, etc.)
   - Track completion
   - Display badges

4. **Update FirestoreService**
   - `updateStreak(userId: String, streak: Streak) async throws`
   - `fetchStreak(userId: String) async throws -> Streak?`
   - `updateAchievements(userId: String, achievementId: String) async throws`

5. **Create UI Components**
   - Streak display card
   - Achievement badges view
   - Progress indicators

### Files to Create/Modify
- `Models/Streak.swift` (new)
- `Models/Achievement.swift` (new)
- `Services/FirestoreService.swift` (add streak/achievement methods)
- `ViewModels/HomeViewModel.swift` (update streak on meal log)
- `Views/Home/StreakCard.swift` (new)
- `Views/Profile/AchievementsView.swift` (new)
- `firestore.rules` (add streaks/achievements subcollections)

### Achievements to Implement
- First Meal (log first meal)
- Week Warrior (7-day streak)
- Month Master (30-day streak)
- Centurion (100 meals logged)
- Macro Master (hit all macros 7 days in a row)

---

## 6. Community Backend

### Current State
- `Views/Community/CommunityView.swift` exists with mock data
- `ViewModels/CommunityViewModel.swift` has mock posts
- `Models/Food.swift` has CommunityPost model
- Firestore rules allow posts collection
- No real backend integration

### Requirements
- Create real posts in Firestore
- Display posts from all users (or followed users)
- Allow users to post meals/progress updates
- Like/comment functionality (optional)

### Implementation Steps

1. **Update CommunityPost Model**
   - Add userId field
   - Add timestamp
   - Add likes array
   - Add comments array (optional)

2. **Add Firestore Methods**
   - `createPost(userId: String, post: CommunityPost) async throws`
   - `fetchPosts(limit: Int) async throws -> [CommunityPost]`
   - `likePost(postId: String, userId: String) async throws`
   - `deletePost(postId: String, userId: String) async throws`

3. **Update CommunityViewModel**
   - Load real posts from Firestore
   - Handle pagination
   - Refresh posts

4. **Create Post Creation UI**
   - Share meal as post
   - Add caption
   - Include nutrition info

5. **Update CommunityView**
   - Display real posts
   - Add pull-to-refresh
   - Show loading states

### Files to Create/Modify
- `Models/Food.swift` (update CommunityPost)
- `Services/FirestoreService.swift` (add post methods)
- `ViewModels/CommunityViewModel.swift` (connect to Firestore)
- `Views/Community/CommunityView.swift` (update to use real data)
- `Views/Community/CreatePostView.swift` (new)
- `firestore.rules` (already configured for posts)

### Data Structure
```
posts/{postId}
  - id: String (Firestore document ID)
  - userId: String
  - userName: String
  - userAvatar: String? (optional)
  - timestamp: Timestamp
  - text: String
  - imageUrl: String?
  - calories: Int?
  - protein: Double?
  - carbs: Double?
  - fats: Double?
  - likes: [String] // array of user IDs who liked
  - likeCount: Int (for easier querying)
  - comments: [Comment]? (optional, can add later)
```

### Existing Models Reference
- `CommunityPost`: Already exists in `Models/Food.swift`
- Has: id (UUID), userName, userAvatar, timeAgo (String), text, imageUrl, calories, protein, carbs, fats
- Need to update: Add userId, timestamp (Date), likes array, postId (String?)
- timeAgo can be computed from timestamp

---

## 📊 Current Data Flow

### Meal Logging Flow (Reference)
1. User taps "Log Food" → `FoodLoggingView` opens
2. User enters food details → Creates `Food` object
3. `HomeViewModel.logFood()` → `FirestoreService.saveMeal()`
4. Meal saved to `users/{userId}/meals/{mealId}`
5. Daily log updated with meal totals
6. View refreshes to show new meal

### Profile Editing Flow (Reference)
1. User taps "Edit Profile" → `EditProfileView` opens
2. User modifies fields → Updates `viewModel.profile`
3. User taps "Save" → `ProfileViewModel.saveProfile()`
4. `FirestoreService.saveUserProfile()` → Saves to `users/{userId}/profile/data`
5. View dismisses, profile updates

**Use these patterns for new features!**

---

## 📁 Project Structure Reference

```
Gains/
├── Models/
│   ├── Food.swift (contains Food, DailyNutrition, UserProfile, CommunityPost)
│   ├── DailyLog.swift
│   ├── Workout.swift
│   ├── Exercise.swift
│   ├── ExerciseSet.swift
│   ├── ExerciseTemplate.swift
│   └── MealTemplate.swift (to create)
│
├── Services/
│   ├── FirestoreService.swift (main database service)
│   ├── AuthService.swift (authentication)
│   ├── StorageService.swift (image storage)
│   ├── WorkoutService.swift (needs Firestore integration)
│   └── ExerciseTemplateService.swift (needs implementation)
│
├── ViewModels/
│   ├── HomeViewModel.swift (meal logging, daily logs)
│   ├── ProfileViewModel.swift (profile management)
│   ├── WorkoutViewModel.swift (workout management)
│   └── ProgressViewModel.swift (to create)
│
├── Views/
│   ├── Home/
│   │   ├── HomeView.swift (main home screen)
│   │   ├── FoodLoggingView.swift (log meals)
│   │   ├── MealCard.swift (meal display)
│   │   └── EditMealView.swift (edit meals)
│   ├── Progress/
│   │   └── ProgressView.swift (needs charts)
│   ├── Community/
│   │   └── CommunityView.swift (needs real data)
│   └── Profile/
│       ├── ProfileView.swift
│       └── EditProfileView.swift
```

---

## 🔧 Common Patterns Used

### Firestore Service Pattern
```swift
func saveX(userId: String, item: X) async throws {
    let ref = db
        .collection("users")
        .document(userId)
        .collection("items")
        .document()
    
    var data = try Firestore.Encoder().encode(item)
    data["id"] = ref.documentID
    
    try await ref.setData(data)
}
```

### ViewModel Pattern
```swift
@MainActor
class XViewModel: ObservableObject {
    @Published var items: [X] = []
    @Published var isLoading = false
    
    private let firestore = FirestoreService.shared
    private let auth = AuthService.shared
    
    func loadItems() async {
        guard let user = auth.user else { return }
        isLoading = true
        defer { isLoading = false }
        
        do {
            items = try await firestore.fetchX(userId: user.uid)
        } catch {
            print("Error: \(error)")
        }
    }
}
```

### UI Pattern
```swift
struct XView: View {
    @StateObject private var viewModel = XViewModel()
    
    var body: some View {
        // UI here
    }
    .task {
        await viewModel.loadItems()
    }
}
```

---

## 🔐 Firestore Security Rules

Current rules allow:
- Users can read/write their own data under `users/{userId}`
- Subcollections: dailyLogs, meals, workouts, profile, weightEntries
- Posts collection: all authenticated users can read, only owner can write

**To add for new features:**
```firestore
// Meal Templates
match /mealTemplates/{templateId} {
  allow read, write: if isOwner(userId);
}

// Streaks
match /streaks/{streakId} {
  allow read, write: if isOwner(userId);
}

// Achievements
match /achievements/{achievementId} {
  allow read, write: if isOwner(userId);
}
```

---

## 📝 Implementation Order Recommendation

1. **Meal Templates** (easiest, high value)
2. **Workout Persistence** (core feature)
3. **Exercise Templates** (complements workouts)
4. **Streaks & Achievements** (gamification)
5. **Progress Tracking** (requires data aggregation)
6. **Community Backend** (most complex, social features)

---

## 🎨 Design Guidelines

- Use `gainsCardBackground` for cards
- Use `gainsPrimary` for accents and buttons
- Use `gainsText` for primary text
- Use `gainsSecondaryText` for secondary text
- 16px corner radius for cards
- 12px corner radius for buttons
- Consistent spacing: 16px, 24px

---

## ✅ Testing Checklist

For each feature:
- [ ] Data saves to Firestore correctly
- [ ] Data loads from Firestore correctly
- [ ] UI updates reflect changes
- [ ] Error handling works
- [ ] Loading states display properly
- [ ] Empty states show when no data
- [ ] Security rules allow proper access

---

## 📚 Key Files to Reference

- `Services/FirestoreService.swift` - See existing patterns for save/fetch
- `ViewModels/HomeViewModel.swift` - See async/await patterns
- `Views/Home/HomeView.swift` - See UI patterns and state management
- `Models/Food.swift` - See Codable implementations
- `firestore.rules` - See security rule patterns

---

## 🔍 Key Code Examples

### Fetching Multiple Documents (for Progress View)
```swift
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
    
    return snapshot.documents.compactMap { doc in
        try? doc.data(as: DailyLog.self)
    }
}
```

### Saving with Embedded Arrays (for Workouts)
```swift
func saveWorkout(userId: String, workout: Workout) async throws {
    let workoutRef = db
        .collection("users")
        .document(userId)
        .collection("workouts")
        .document()
    
    var data = try Firestore.Encoder().encode(workout)
    data["id"] = workoutRef.documentID
    data["workoutId"] = workoutRef.documentID
    data["date"] = Timestamp(date: workout.date)
    
    try await workoutRef.setData(data)
}
```

### Calculating Streaks
```swift
func calculateStreak(dailyLogs: [DailyLog]) -> Int {
    let calendar = Calendar.current
    var streak = 0
    var currentDate = calendar.startOfDay(for: Date())
    
    for log in dailyLogs.sorted(by: { $0.date > $1.date }) {
        let logDate = calendar.startOfDay(for: log.date)
        if logDate == currentDate {
            streak += 1
            currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate)!
        } else if logDate < currentDate {
            break
        }
    }
    
    return streak
}
```

---

## 🚀 Quick Start Guide

### For Each Todo:

1. **Read the "Current State"** - Understand what exists
2. **Review "Requirements"** - Know what to build
3. **Follow "Implementation Steps"** - Step-by-step guide
4. **Check "Files to Create/Modify"** - Know what to change
5. **Reference "Key Code Examples"** - Copy patterns
6. **Test thoroughly** - Verify it works
7. **Update Firestore rules** - Add security rules if needed
8. **Deploy rules**: `firebase deploy --only firestore:rules`

### Recommended Order:
1. **Meal Templates** (simplest, high impact)
2. **Workout Persistence** (core feature)
3. **Exercise Templates** (complements workouts)
4. **Streaks & Achievements** (gamification)
5. **Progress Tracking** (requires data aggregation)
6. **Community Backend** (most complex)

---

## 📝 Notes

- All Firestore operations use async/await
- All ViewModels are `@MainActor` for UI updates
- Use `@Published` properties for reactive UI
- Always handle errors gracefully
- Show loading states during async operations
- Use existing color scheme and design patterns

Good luck! 🎉

