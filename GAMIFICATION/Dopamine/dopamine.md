This is a fantastic suite of gamification features. Implementing all of them will create a comprehensive "Game Loop" that targets different psychological needs: daily satisfaction (Mosaic), fear of loss (Heat Streak), long-term vision (Marble), mastery (Skill Tree), and milestone celebration (Shatter).

Here are the detailed design specifications for each feature, tailored to your Gains app architecture.

1. Daily Dietary Goals: "The Macro Mosaic"
Location: Home Screen (Replaces standard progress rings)

Visual Design

The Container: A dark, glass-morphism Hexagon in the center of the "Calories" card. It starts empty with a faint grey outline (Color.gainsBgTertiary).

The Shards:

Protein: Sharp, angular shards. Color: Color.gainsAccentRed (or custom "Meat" red).

Carbs: Smooth, rounded shards. Color: Color.gainsPrimary (Blue).

Fats: Small, circular droplets. Color: Color.gainsAccentOrange (Yellow/Gold).

The Animation:

When a user logs food, the shards don't just appear; they fly in from the "Log Food" button location into the hexagon.

They settle loosely at the bottom, simulating physics (using SpriteKit or SwiftUI Canvas).

The "Lock-In" Event

Trigger: When DailyLog.protein, DailyLog.carbs, and DailyLog.fats are all within ±5g of the user's UserProfile.macros.

Visual Sequence:

Compression: The loose shards are pulled magnetically to the center.

Flash: A bright white flash (Color.white) overlays the hexagon.

Fusion: The flash fades to reveal a solid, glowing, multi-faceted Gemstone.

Glow: The gem emits a breathing neon glow (using .shadow with a pulsing radius).

Audio/Haptic:

Sound: A high-pitched, resonant "crystal chime."

Haptic: A sharp, crisp tap (UIImpactFeedbackGenerator(style: .rigid)).

Technical Implementation

Data Source: HomeViewModel.dailyNutrition

State: Use a computed property isMacroGemLocked to trigger the animation state.



3. Long-Term Workout Goals: "The Marble Block"
Location: Workouts Tab (Plans Section)

Visual Design

The Object: A 3D-rendered cube in the center of the screen.

Material: Rough, grey stone texture.

The Statue: Hidden inside is a "Golden Athlete" (or a specific shape based on the plan, e.g., a Shield for a strength plan).

Progress Mapping:

Total Workouts in Plan = Total "Health" of the block.

1 Workout = 1 Chisel Strike.

The Interaction

Trigger: Completing a workout in ActiveWorkoutView.

Animation:

The user hits "Finish Workout."

A virtual chisel strikes the block.

Physics: 3D debris particles fly off the block (using SceneKit or SpriteKit particles).

Reveal: A specific chunk of the block disappears, revealing a piece of the Golden Statue underneath.

Milestones:

At 25%, 50%, and 75% completion, a larger chunk falls off with a heavier sound effect, revealing a major body part of the statue (e.g., the face or the arm).

Technical Implementation

Data Source: WorkoutPlan. You need to track workoutsCompleted vs totalWorkouts.

Storage: Store the statueRevealState index in Firestore to ensure the visual persists between sessions.

4. Strength/Performance: "The Skill Tree"
Location: Profile View (Achievements Tab)

Visual Design

The Map: A constellation of nodes overlaying a human body silhouette.

Nodes: Chest, Back, Legs, Shoulders, Arms, Cardio, Core.

States:

Locked: A dim, hollow gray circle.

Level 1 (Novice): A thin blue outline.

Level 5 (Elite): Filled with "Liquid Gold" animation.

Maxed: Emits particle effects (sparks).

The "XP" System

Logic: Volume (Weight × Reps) acts as XP.

Example: 10,000 lbs volume on Chest = Level 1.

The Animation:

After a workout, show a summary screen: "Chest XP +1,200."

An orb of light flies from the summary text to the "Chest" node on the body map.

The node fills up like a liquid gauge.

The Supernova:

When a node levels up, it pulses rapidly, then explodes with a shockwave effect that ripples across the UI.

Reward: A badge unlock overlay appears: "Titan Chest Unlocked."

Technical Implementation

Data Source: Exercise model. You need to aggregate volume by MuscleGroup.

Service: StatsService to calculate total historical volume per muscle group.

5. Weight/Metric Goals: "The Shatter"
Location: Progress View (Weight Chart Overlay)

Visual Design

The Overlay: A glass texture layered over the user's current weight card.

The Goal: The target weight (e.g., "180 lbs") is etched onto the glass.

The Current: The user's current weight is displayed behind the glass.

The Visual Trigger (The Cracks)

Logic: Calculate % distance to goal.

50% there: Small stress fractures appear on the corners.

90% there: A large spiderweb crack spreads across the center.

99% there: The glass looks barely intact, held together by tension.

The Dopamine Moment (The Break)

Trigger: Logging a weight entry that meets or beats the goal.

Animation:

Slow Motion: The screen pauses.

Impact: An invisible force strikes the center.

Shatter: The glass explodes outward in 3D shards (towards the user).

Clarity: The shards fade away, leaving the "Goal Weight" glowing in pure, unobstructed Gold text.

Confetti: Subtle gold dust falls in the background.

Shareable: A button appears: "Share Replay" (generates a GIF of the shatter).

Technical Implementation

Data Source: ProfileViewModel (weight vs targetWeight).

Library: SpriteKit is best for the shard physics, overlaid on the SwiftUI view.





Calendar layout: Love this direction—that “tiny hit of dopamine when I open the app” is exactly what makes people keep logging.

Let’s layer **rewarding glow + streak energy** on top of your current liquid-glass look without going full neon rave.

---

## 1. Calendar Glow System (Dark Mode, Liquid Glass)

Think of **three visual states per day**:

1. **No workout logged**

   * Background: pure liquid glass, very subtle border
   * Text: secondary gray
   * No glow

2. **Workout logged (isolated day, no streak yet)**

   * Background: slightly brighter glass pill (e.g. #1C1C1F)
   * Thin inner stroke in your accent blue
   * Soft *inner* glow, hardly any outer glow
   * Small dot or tiny bar under the date (indicating volume)

3. **Streak day (part of 2+ consecutive days)**

   * Background: brighter pill with **gradient glass** (blue → soft indigo)
   * Outer “bloom” glow, but blurred + low opacity
   * Slight scale-up (e.g. 1.05x) on the current day in the streak
   * Optional: a faint “connecting trail” between consecutive days

You stay liquid-glass overall, but streaks give you a **gentle aura** and feel “charged up.”

---

## 2. Streak Intensity Levels (More Days → More Glow)

Map streak length to intensity:

* **1–2 days** → subtle glow, pill just a bit brighter
* **3–6 days** → visible glow, gradient glass, tiny pulse when opening
* **7+ days** → full “hero” treatment:

  * Slight pulsing outer glow on open
  * Perhaps a tiny ember animation behind the pill (barely moving)
  * “🔥 7-day streak” chip above/below the calendar

This way the **brain sees progress** even if weight/strength hasn’t changed yet.

---

## 3. Micro-Interactions (Dopamine Moments)

When they log today’s workout and it extends a streak:

1. **Calendar micro-anim**

   * Today’s date pill:

     * Scales up 1.1x, then gently springs back
     * Glow quickly brightens then settles
   * A small streak line animates in between yesterday and today

2. **Haptics**

   * Light impact for “logged workout”
   * Medium “success” impact when a new streak threshold is hit (3, 7, 14 days)

3. **Tiny banner / chip**

   * “3-day streak 🔥 Keep it going!” appears just under “December 2025” for 2 seconds, then fades out.

---

## 4. Layout Tweaks to Sell the Streak

Under the calendar, before the list of workouts:

* **Streak summary row:**

> 🔥 **Current streak: 5 days**
> Longest streak: 12 days

* Use a small pill with a **glass gradient** and a tiny flame/bolt icon, matching your accent color.

This becomes the **narrative hook**: “I don’t want to break this.”

---
* For **streaks**:

  * Add:

    * connecting faint line between days in the same week row
    * slightly brighter glow on those pills
* Under the calendar, show:

  * “🔥 4-day streak • Longest: 9 days” row
  * Then your grouped daily workouts (like “December 2, 2025 → Push, Push — Quick Session”).

---

## 6. If You Want Quick SwiftUI Hooks (high-level)

You don’t need full code here, but conceptually:

```swift
struct StreakDayStyle {
    var baseColor: Color
    var glowOpacity: Double
    var scale: CGFloat
}

func styleForStreak(length: Int) -> StreakDayStyle {
    switch length {
    case 0:  return .init(baseColor: .clear, glowOpacity: 0,   scale: 1.0)
    case 1...2: return .init(baseColor: .gainsGlass1, glowOpacity: 0.15, scale: 1.0)
    case 3...6: return .init(baseColor: .gainsGlass2, glowOpacity: 0.3,  scale: 1.03)
    default:    return .init(baseColor: .gainsGlass3, glowOpacity: 0.45, scale: 1.05)
    }
}
```

Use that to drive your **background gradient + shadow/blur** per day cell.

---
⭐ 1. Visual Sketch of the Combined Screen
Imagine your Progress tab with an elegant, liquid-glass top section.
🔥 Top Section: 30-Day Heat Streak Bar (scrollable)
A horizontally scrollable heatmap row:
⬛⬛🟦🟩🟧🟧🟨🟨🟦⬜❄⬛🟧🟧🟧🟧🟧
Where each tile reflects activity intensity:
Intensity Level	Color / Texture	Meaning
❄ Frozen	Frosted grey-blue, cracked texture	Missed day
▫ Cold	Very dim blue-gray	Logged nothing
🟦 Low	GainsPrimary blue	Logged food only
🟪 Medium	GainsPurple	Logged food OR workout
🟧 High	GainsOrange	Logged workout AND macros on target
🔥 Supernova	White-hot center → orange halo	Streak > 7
Tiles use liquid glass gloss, not neon:
Soft blur, subtle bloom, rounded corners, matte transparency.
🔥 The Streak Row Behavior
On a streak (like 10 days), tiles 5–14 glow with a soft light bloom.
The selected day (today) slightly scales (1.05×) and has a brighter rim.
The tiles are grouped visually using soft linking shadows.
❄🔥 The Thaw / Heat Interaction (Combined Visual)
Here’s the fused effect:
Scenario shown in mockup:
Yesterday: ❄ Frozen tile with cracked ice texture
Today: 🔥 Supernova tile (user logged perfect day)
Animation you see in the screenshot:
Today’s tile erupts in a white-orange heat bloom
A gradient wave of warmth leaks leftwards
The frost texture on yesterday’s tile begins to melt—
turning into a wet neutral-grey “Recovered” tile
This visually saves the streak (psychologically rewarding).
A small chip above the row reads:
🔥 10-day streak · Longest: 28 days
Typography is clean Apple SF Rounded, medium weight.
