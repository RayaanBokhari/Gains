# **Gains – AI-Powered Fitness & Nutrition Tracker**

**Gains** is a modern SwiftUI iOS app designed to help users track calories, macros, water intake, and body metrics—powered by AI for personalized insights. Inspired by clean Apple-ecosystem design and built for seamless daily accountability, Gains blends elegant UI with intelligent nutrition analysis through ChatGPT.

---

## **📱 Features**

### **Daily Tracking**

* Log calories, macros (protein, carbs, fats), and water intake
* View progress rings and daily summaries
* Quick-add actions for food, water, and weight

### **AI Coach**

* Built-in chat tab powered by OpenAI
* Ask questions about nutrition, meal ideas, macros, or progress
* Uses a ChatGPT-style interface for easy conversation
* Future support for food estimation from text/photo

### **Social Feed**

* Share progress updates with your accountability group
* View meals, achievements, macro goals, and milestones
* Apple-style card layout for a clean social experience

### **Profile & Goals**

* Track weight, height, goals, and custom targets
* Configure calorie goals and macro splits
* Integration planned for HealthKit and Apple Watch

---

## **🎨 Design Language**

Gains uses a **blue + black modern color scheme** with:

* Clean SwiftUI components
* Rounded rectangles
* SF Symbols throughout
* Glass-like card surfaces
* Dark mode–optimized design
* Apple Fitness/Health inspired structure

Colors are defined in `Theme/colors.swift`.

---

## **🧱 Project Structure**

```
Gains
├── Theme
│   ├── colors.swift
│   └── GainsAIApp.swift
│
├── Services
│   ├── WorkoutService.swift
│   ├── ExerciseTemplateService.swift
│   └── OpenAIService.swift (planned)
│
├── Views
│   ├── Shared
│   │   ├── ContentView.swift
│   │   └── TabBarView.swift
│   │
│   ├── Workouts
│   │   ├── WorkoutListView.swift
│   │   └── WorkoutDetailView.swift
│   │
│   ├── Exercises
│   │   └── ExerciseListView.swift
│   │
│   ├── Progress
│   │   └── ProgressView.swift
│   │
│   └── Settings
│       └── SettingsView.swift
│
├── ViewModels
│   └── WorkoutViewModel.swift
│
├── Models
│   ├── Workout.swift
│   ├── Exercise.swift
│   ├── ExerciseSet.swift
│   └── ExerciseTemplate.swift
│
├── Utilities
│   ├── DateFormatter+Extensions.swift
│   └── WeightFormatter.swift
│
└── GainsApp.swift
```

This follows a clean **MVVM + Services** architecture.

---

## **🚀 Getting Started**

### **Requirements**

* Xcode 16+
* iOS 17 or later
* SwiftUI
* (Optional) OpenAI API key for AI Chat

### **Run the App**

1. Clone the repo
2. Open `Gains.xcodeproj` in Xcode
3. Select an iPhone simulator
4. Run the project (`⌘R`)

---

## **🧠 OpenAI Integration (Planned)**

The app will support:

* AI driven nutrition analysis
* Macro estimation from meals
* Intelligent reminders
* Goal recommendations
* Natural language queries in the Chat tab

Using a service file:

```
Services/OpenAIService.swift
```

---

## **🔮 Future Enhancements**

* HealthKit integration
* Food photo analysis
* Meal templates
* Custom macro plans
* Streaks and achievement system
* Deeper social features (groups, comments)

---

## **👥 Credits**

Design, development, and concept by **Rayaan Bokhari**

AI-integrated fitness platform empowering accountability and daily discipline.

---

## **📌 License**

Private / Personal Use Only (not yet published).

Contact owner before distribution.

---

If you want, I can also generate:

✅ A project logo
✅ A matching App Store description
✅ A landing page for the app
✅ A full OpenAI API integration template

Just tell me!
