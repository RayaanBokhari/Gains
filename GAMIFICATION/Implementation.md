Nice, this is a perfect fit for your app’s vibe. Let’s redesign the **Workouts** tab around that “Calendar Glow System,” then I’ll give you a concrete step-by-step guide you can paste into Cursor.

---

## 1. New Workouts Tab Layout (high-level)

Keep your current dark / liquid-glass aesthetic, but reframe the tab like this:

**Top: Streak & Summary**

* A horizontal pill card:

  * “Current Streak: 4 days 🔥”
  * “Longest: 12 days” in smaller text
  * Tiny spark / flame icon glowing when streak > 0

**Middle: Calendar Glow Strip/Grid**

* At least a **full month grid** (7 columns, 5–6 rows) or a **2-week strip** if you want it shorter.
* Each day is a **glass pill** with three visual states (below).
* Tap a day → shows workouts logged that day in the section below.

**Bottom: Selected Day Detail**

* “Today’s Workout” or “Workouts on Dec 10”
* List of workouts (similar to your current cells) but simplified:

  * Title, # of exercises, total volume, duration.

This gives a quick dopamine hit: streak at the top, glowing calendar in the middle, details at the bottom.

---

## 2. Calendar Glow System – Visual Spec

For each day, you’ll use a `DayState` enum:

```swift
enum WorkoutDayState {
    case empty          // no workout logged
    case logged(volumeScore: Double)
    case streak(volumeScore: Double, isCurrentDay: Bool)
}
```

### Shared base style

* **Shape:** Rounded rectangle / capsule with 12–16 corner radius.
* **Base background:** dark glass

  * `Color.black.opacity(0.45)` over a blur / material
  * Border: `Color.white.opacity(0.04)`
* **Date label:** SF font, `footnote` or `caption`, semi-bold.

---

### State 1 – No workout logged

* Background:

  * Very transparent glass: `Color.white.opacity(0.04)` over dark.
  * Border: hairline `Color.white.opacity(0.05)`.
* Text:

  * `Color.white.opacity(0.35)`
* Effects:

  * **No glow**, no shadow.
  * Optional very subtle highlight on hover/tap only.

---

### State 2 – Logged (isolated)

* Background:

  * Slightly brighter glass pill: e.g. `Color(red: 0.11, green: 0.11, blue: 0.12)` (~#1C1C1F).
* Stroke:

  * Inner stroke in your **accent blue** (thin, 1 pt) with low opacity.
* Glow:

  * Soft **inner glow**: gradient overlay from blue at center to transparent edges.
  * Very subtle outer shadow: `Color.blue.opacity(0.25)`, radius 6, y: 0.
* Volume indicator:

  * Under date, a tiny bar or dot:

    * Width proportional to `volumeScore` (e.g. 0–1 mapped to 10–24 pt).
    * Color: your **Gains orange** for dopamine, but low opacity in this state.

---

### State 3 – Streak day (2+ consecutive)

* Background:

  * Brighter gradient glass: `LinearGradient(colors: [accentBlue, indigo], startPoint: .topLeading, endPoint: .bottomTrailing)` with opacity ~0.45 over dark.
* Outer glow:

  * “Bloom” behind pill:

    * `shadow(color: orange.opacity(0.55), radius: 16, x: 0, y: 0)`
    * Optional second `shadow(color: blue.opacity(0.4), radius: 24, x: 0, y: 8)`
* Scale:

  * If it’s **today**: `.scaleEffect(1.05)` with spring animation.
* Connecting trail:

  * For consecutive streak neighbors, draw a faint rounded rect between them:

    * Color: blue/indigo at 0.25 opacity.
    * Stacked behind the pills, so it feels like a glowing path.
* Volume indicator:

  * Same bar under date, but:

    * Color: bright orange.
    * Slight blur/shadow to look “charged.”

---

## 3. SwiftUI Implementation Sketch

Here’s a concrete structure Cursor can drop into your codebase.

### 3.1 Models & Helpers

```swift
import SwiftUI

enum WorkoutDayState {
    case empty
    case logged(volumeScore: Double)
    case streak(volumeScore: Double, isCurrentDay: Bool)
}

struct WorkoutDay: Identifiable {
    let id = UUID()
    let date: Date
    let state: WorkoutDayState
}
```

**Streak detection idea:**

* You probably already have something like `[Workout]` with a `date` property.
* Aggregate workouts → dictionary `[DateOnly: VolumeScore]`.
* Sort dates, walk them to compute streaks (runs of consecutive days).

Pseudo-logic:

```swift
func buildWorkoutDays(for month: Date, sessions: [WorkoutSession]) -> [WorkoutDay] {
    // 1. Map workouts by day & compute volumeScore in 0...1 range.
    // 2. Create all days in the visible month.
    // 3. Walk days in order and mark streaks where there are 2+ neighbors.
}
```

Cursor can flesh this out once it sees your actual models.

---

### 3.2 Day Pill View

```swift
struct WorkoutDayPillView: View {
    let day: WorkoutDay
    let isSelected: Bool
    
    private var dayNumber: String {
        let comps = Calendar.current.dateComponents([.day], from: day.date)
        return "\(comps.day ?? 0)"
    }
    
    var body: some View {
        VStack(spacing: 4) {
            Text(dayNumber)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(foregroundColor)
            
            volumeIndicator
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 10)
        .background(backgroundView)
        .overlay(innerStroke)
        .scaleEffect(scale)
        .shadow(color: outerGlowColor, radius: outerGlowRadius)
        .animation(.spring(response: 0.28, dampingFraction: 0.8), value: isSelected)
    }
    
    // MARK: - Subviews & Styling
    
    private var volumeIndicator: some View {
        switch day.state {
        case .empty:
            return AnyView(Spacer().frame(height: 3))
        case .logged(let volume), .streak(let volume, _):
            let width: CGFloat = 10 + CGFloat(volume) * 16 // 0...1 -> 10...26
            return AnyView(
                RoundedRectangle(cornerRadius: 999)
                    .fill(volumeBarColor)
                    .frame(width: width, height: 3)
                    .opacity(0.85)
            )
        }
    }
    
    private var backgroundView: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.black.opacity(0.45))
            
            switch day.state {
            case .empty:
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.white.opacity(0.03))
            case .logged:
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color(red: 0.11, green: 0.11, blue: 0.12))
            case .streak:
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color("GainsBlue"), Color.indigo],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .opacity(0.7)
            }
        }
        .background(.ultraThinMaterial.opacity(0.35))
    }
    
    private var innerStroke: some View {
        RoundedRectangle(cornerRadius: 12, style: .continuous)
            .stroke(innerStrokeColor, lineWidth: 1)
    }
    
    private var foregroundColor: Color {
        switch day.state {
        case .empty:
            return Color.white.opacity(0.35)
        default:
            return .white
        }
    }
    
    private var innerStrokeColor: Color {
        switch day.state {
        case .empty:
            return Color.white.opacity(0.05)
        case .logged:
            return Color("GainsBlue").opacity(0.4)
        case .streak:
            return Color.white.opacity(0.18)
        }
    }
    
    private var outerGlowColor: Color {
        switch day.state {
        case .streak:
            return Color("GainsOrange").opacity(0.55)
        default:
            return .clear
        }
    }
    
    private var outerGlowRadius: CGFloat {
        switch day.state {
        case .streak:
            return 16
        default:
            return 0
        }
    }
    
    private var volumeBarColor: Color {
        switch day.state {
        case .empty, .logged:
            return Color("GainsOrange").opacity(0.6)
        case .streak:
            return Color("GainsOrange")
        }
    }
    
    private var scale: CGFloat {
        switch day.state {
        case .streak(_, let isCurrentDay) where isCurrentDay:
            return 1.05
        default:
            return 1.0
        }
    }
}
```

---

### 3.3 Calendar Grid View

```swift
struct WorkoutCalendarView: View {
    let days: [WorkoutDay]
    @Binding var selectedDate: Date
    
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 7)
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: 8) {
            ForEach(days) { day in
                Button {
                    selectedDate = day.date
                } label: {
                    WorkoutDayPillView(
                        day: day,
                        isSelected: Calendar.current.isDate(day.date, inSameDayAs: selectedDate)
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.black.opacity(0.65))
                .background(.ultraThinMaterial.opacity(0.25))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.white.opacity(0.06), lineWidth: 1)
        )
        .padding(.horizontal, 16)
    }
}
```

Connecting trails between streak days can be done by drawing a background `Canvas` behind the grid using the same `days` array—Cursor can add that as a polish step.

---

## 4. Guide for Cursor to Implement in Your Repo

Here’s a concrete sequence you can feed into Cursor as tasks/prompts.

---

### Step 1 – Create calendar data + streak logic

**Prompt to Cursor in your repo:**

> Create a new Swift file `WorkoutCalendarModels.swift` in the Gains app target.
> Define:
>
> * `enum WorkoutDayState { case empty; case logged(volumeScore: Double); case streak(volumeScore: Double, isCurrentDay: Bool) }`
> * `struct WorkoutDay: Identifiable { let id = UUID(); let date: Date; let state: WorkoutDayState }`
>
> Then, add a helper on my existing workout data layer to:
>
> * Take all existing `WorkoutSession` items (or whatever model we use) from the last 60–90 days.
> * Group them by day.
> * Compute a normalized `volumeScore` value between 0 and 1 based on either total sets, total reps, or total duration.
> * Build `[WorkoutDay]` for the currently visible month.
> * Detect streaks: consecutive days that have workouts are part of a streak. Mark them with `.streak(volumeScore:isCurrentDay:)` when the streak length is ≥ 2, otherwise `.logged`.
> * Expose a reusable function, e.g. `func makeWorkoutDays(for month: Date, sessions: [WorkoutSession]) -> [WorkoutDay]`.

---

### Step 2 – Add the Day Pill and Calendar views

**Prompt:**

> Add a new SwiftUI view `WorkoutDayPillView` exactly like the spec below:
>
> * It takes `WorkoutDay` and `isSelected: Bool`.
> * It implements three visual states:
>
>   * `.empty`: very subtle glass background, gray text, no glow.
>   * `.logged`: brighter glass (#1C1C1F), thin inner stroke with accent blue, soft inner glow, small orange volume bar below the date.
>   * `.streak`: gradient background (accent blue → indigo), orange “bloom” shadow, scale up slightly if `isCurrentDay` is true, same volume bar but brighter.
> * Use our existing color assets `GainsBlue` and `GainsOrange` if they exist, otherwise create them in Assets using our primary blue and orange.
>
> Then add `WorkoutCalendarView`:
>
> * Accepts `[WorkoutDay]` and `@Binding var selectedDate: Date`.
> * Renders a 7-column `LazyVGrid` of `WorkoutDayPillView` instances.
> * Wrap the grid in a rounded glass container with:
>
>   * dark background
>   * `ultraThinMaterial` overlay
>   * subtle border and corner radius 24
> * Tapping a day updates `selectedDate`.

You can paste in the code I gave above and have Cursor adapt it to your current color names if needed.

---

### Step 3 – Integrate into Workouts tab

**Prompt:**

> Open the `WorkoutsView` / `WorkoutsTabView` (the main root view for the Workouts tab).
> Replace the current top list so that the new layout is:
>
> 1. A streak summary header at the top:
>
>    * Show current streak in days, longest streak, and maybe total workouts this month.
>    * Style it as a glass card with our accent colors.
> 2. The new `WorkoutCalendarView` below the streak header.
> 3. Under the calendar, a section that shows workouts for the selected date using the existing workout row style.
>
> Use the streak information from the new helper to populate the header (current streak and longest streak).
> Use `@State var selectedDate` initialized to today, and filter workouts for that date in the bottom list.

---

### Step 4 – Micro-interactions & dopamine polish

**Prompt:**

> Add subtle animations:
>
> * When `selectedDate` changes, animate the `WorkoutDayPillView` with a spring.
> * When the user logs a new workout:
>
>   * If that creates or extends a streak, animate the corresponding pill with a short “pop” (scale 1.1 then back).
>   * Optionally, show a brief toast “New streak: X days 🔥”.
>
> Ensure animations respect reduced-motion (check `accessibilityReduceMotion` if you want to be extra polished).

---

### Step 5 – Theming & Cleanup

**Prompt:**

> Make sure the new calendar works in light/dark mode, but optimize for dark:
>
> * In light mode, reduce glow intensity and tweak background opacities so it doesn’t look muddy.
> * Reuse existing text styles and spacing from the Home / Progress tabs so the Workouts tab feels consistent.
> * Adjust padding so the calendar doesn’t crowd the bottom list on small devices (e.g. iPhone SE).

---

If you’d like, next step I can help you:

* Integrate the calendar with your **AI Coach** (e.g. “You’re on a 5-day streak, want to push it to 7?”), or
* Design the actual streak header card to match the Home “calories remaining” block.
