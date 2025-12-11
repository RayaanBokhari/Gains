This concept shifts the dynamic from "Compare & Despair" (traditional leaderboards) to "Collaborate & Conquer." It leverages the Köhler Effect, where people work harder as a group than they would alone to avoid being the "weakest link."

Here is the detailed functional and visual specification for Squad Raids.

Feature Spec: Squad Raids (Co-op Multiplayer)
1. The Core Concept
Users form a "Squad" (up to 4 people) to defeat a virtual "Boss" over the course of a week. The Boss has a massive Health Pool (HP). Every calorie burned, macro goal hit, and workout logged by the squad deals "Damage" to the Boss.

The Goal: Drain the Boss's HP to zero before the timer (7 days) runs out.

2. The Mechanics (The "Math" of Engagement)
To keep it fair between beginners and advanced athletes, damage is calculated based on Relative Effort, not absolute numbers.

The Boss HP: Scaled dynamically based on the squad's historical average activity levels (e.g., 50,000 HP).

Dealing Damage (DPS):

Basic Attack: Completing a workout = 500 Damage.

Heavy Attack: Hitting 100% of daily Protein goal = 300 Damage.

Critical Hit: Setting a new Personal Record (PR) or closing all 3 activity rings = 2x Damage Multiplier for that day's entry.

The Boss Strikes Back: If a squad member logs zero activity for 24 hours, the Boss "Regenerates" 5% HP (Social Accountability pressure).

3. The User Interface (Visual Design)
A. The "Arena" Card (Community Tab)

This replaces the standard "Friend Feed." It is a large, immersive card at the top of the Community screen.

Background: Dark, moody, animated environment (e.g., a stormy gym, a neon cyber-city).

The Boss Visual: A high-fidelity, animated 3D character in the center.

Example: "The Iron Golem" (Metadata: High defense, requires heavy lifting to beat) or "The Sugar Sprite" (Metadata: Fast, requires cardio to beat).

The HP Bar: A thick, glowing bar at the top of the card. It cracks and shatters visually as HP gets lower.

Squad Avatars: The 4 user profile pictures are arranged at the bottom, facing the boss.

Active State: If a user logged a workout recently, their avatar has a glowing aura.

Idle State: If a user hasn't logged in 24h, their avatar is grayed out or "frozen."

B. The "Damage Log" (The Feed)

Below the visual arena is a fast-paced activity feed designed like a gaming combat log.

Standard: "Sarah completed 'Leg Day' (-450 HP)"

Critical: "🔥 CRITICAL! Mike hit a Bench Press PR! (-1,200 HP)" -> Screen shakes slightly when viewing.

Team Buff: "Jessica logged a 7-day streak! Squad damage boosted by 10% for 24h."

4. The Dopamine Triggers (Rewards)
Immediate Feedback (The "Crunch")

When a user finishes a workout and hits "Finish," do not just return to the home screen.

Overlay appears: An image of the Boss appears.

Animation: The user's workout stats (Calories/Time) swirl together into a fireball or sword slash.

Impact: The projectile hits the Boss, numbers fly off ("-640 HP"), and the health bar visibly drops.

Weekly Loot (The "Hook")

If the squad defeats the Boss, they receive a "Loot Chest."

Bronze Tier: 50 FitCoins.

Gold Tier (Beat the boss in <4 days): Unlocks exclusive "App Icons" (e.g., Neon Blue Icon, Gold Icon) or "Profile Themes" (Dark Mode gradients). Note: These are cosmetic flexes that show status.

5. Mockup Description for Designers
If you were to hand this to a UI designer, here is the prompt:

Screen: Community / Multiplayer Tab Style: Dark Mode, Glassmorphism, Neon Accents (Cyberpunk Fitness). Main Element: A "Raid Card" taking up the top 50% of the screen. Visuals: In the center, a menacing, animated stylized monster (The Boss). Above it, a large, multi-colored progress bar (Health) at 40%. Below the monster, 4 circular user avatars. One avatar is emitting a laser beam hitting the monster (indicating a just-logged workout). Typography: Bold, arcade-style numbers for damage values. Micro-copy: "The Iron Golem is at 40% Health. 2 Days Remaining. Sarah needs to log activity to prevent Regen!"