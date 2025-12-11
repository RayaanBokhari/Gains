//
//  AIInsightCard.swift
//  Gains
//
//  Daily AI-generated insight card
//

import SwiftUI
import Combine
import FirebaseAuth

struct AIInsightCard: View {
    @StateObject private var viewModel = AIInsightViewModel()
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack(spacing: 10) {
                // Icon
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.gainsPrimary.opacity(0.3), Color.gainsAccentBlue.opacity(0.2)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 32, height: 32)
                    
                    Image(systemName: "sparkles")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.gainsPrimary, Color.gainsAccentBlue],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
                
                Text("AI Insight")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.gainsPrimary)
                
                Spacer()
                
                // Time indicator
                if let lastUpdated = viewModel.lastUpdated {
                    Text(timeAgoString(from: lastUpdated))
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.gainsTextTertiary)
                }
            }
            
            // Content
            if viewModel.isLoading {
                loadingState
            } else if let insight = viewModel.currentInsight {
                insightContent(insight)
            } else {
                emptyState
            }
        }
        .padding(16)
        .background(cardBackground)
        .overlay(cardBorder)
        .onAppear {
            Task {
                await viewModel.loadOrGenerateInsight()
            }
        }
    }
    
    // MARK: - Insight Content
    
    private func insightContent(_ insight: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(insight)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white)
                .lineLimit(isExpanded ? nil : 3)
                .animation(.easeInOut(duration: 0.2), value: isExpanded)
            
            // Show more/less if text is long
            if insight.count > 120 {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isExpanded.toggle()
                    }
                } label: {
                    Text(isExpanded ? "Show less" : "Show more")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.gainsPrimary)
                }
            }
        }
    }
    
    // MARK: - Loading State
    
    private var loadingState: some View {
        HStack(spacing: 12) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .gainsPrimary))
                .scaleEffect(0.8)
            
            Text("Generating insight...")
                .font(.system(size: 13))
                .foregroundColor(.gainsTextSecondary)
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
    
    // MARK: - Empty State
    
    private var emptyState: some View {
        HStack(spacing: 8) {
            Image(systemName: "lightbulb")
                .font(.system(size: 14))
                .foregroundColor(.gainsTextTertiary)
            
            Text("Check back for your daily insight")
                .font(.system(size: 13))
                .foregroundColor(.gainsTextSecondary)
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
    
    // MARK: - Background
    
    private var cardBackground: some View {
        ZStack {
            // Base
            RoundedRectangle(cornerRadius: GainsDesign.cornerRadiusMedium, style: .continuous)
                .fill(Color.gainsCardSurface)
            
            // Blue gradient overlay
            RoundedRectangle(cornerRadius: GainsDesign.cornerRadiusMedium, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.gainsPrimary.opacity(0.12),
                            Color.gainsAccentBlue.opacity(0.06),
                            Color.clear
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            // Subtle inner glow at top
            RoundedRectangle(cornerRadius: GainsDesign.cornerRadiusMedium, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.gainsPrimary.opacity(0.08),
                            Color.clear
                        ],
                        startPoint: .top,
                        endPoint: .center
                    )
                )
        }
    }
    
    private var cardBorder: some View {
        RoundedRectangle(cornerRadius: GainsDesign.cornerRadiusMedium, style: .continuous)
            .stroke(
                LinearGradient(
                    colors: [
                        Color.gainsPrimary.opacity(0.3),
                        Color.gainsPrimary.opacity(0.1),
                        Color.white.opacity(0.05)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: 1
            )
    }
    
    // MARK: - Helpers
    
    private func timeAgoString(from date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d"
            return formatter.string(from: date)
        }
    }
}

// MARK: - View Model

@MainActor
class AIInsightViewModel: ObservableObject {
    @Published var currentInsight: String?
    @Published var lastUpdated: Date?
    @Published var isLoading = false
    
    private let insightKey = "ai_daily_insight"
    private let insightDateKey = "ai_daily_insight_date"
    private let chatGPTService = ChatGPTService()
    
    func loadOrGenerateInsight() async {
        // Check if we have a cached insight from today
        if let cachedInsight = loadCachedInsight() {
            self.currentInsight = cachedInsight.insight
            self.lastUpdated = cachedInsight.date
            return
        }
        
        // Generate new insight
        await generateInsight()
    }
    
    private func loadCachedInsight() -> (insight: String, date: Date)? {
        guard let userId = Auth.auth().currentUser?.uid else { return nil }
        
        let userInsightKey = "\(insightKey)_\(userId)"
        let userDateKey = "\(insightDateKey)_\(userId)"
        
        guard let insight = UserDefaults.standard.string(forKey: userInsightKey),
              let dateTimestamp = UserDefaults.standard.object(forKey: userDateKey) as? Double else {
            return nil
        }
        
        let date = Date(timeIntervalSince1970: dateTimestamp)
        
        // Check if it's from today
        if Calendar.current.isDateInToday(date) {
            return (insight, date)
        }
        
        return nil
    }
    
    private func cacheInsight(_ insight: String) {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        let userInsightKey = "\(insightKey)_\(userId)"
        let userDateKey = "\(insightDateKey)_\(userId)"
        
        UserDefaults.standard.set(insight, forKey: userInsightKey)
        UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: userDateKey)
    }
    
    private func generateInsight() async {
        isLoading = true
        defer { isLoading = false }
        
        // Build context for the insight
        let context = await buildInsightContext()
        
        let systemPrompt = "You are a fitness coach AI. Generate ONE short, personalized daily insight (2-3 sentences max). Be encouraging, specific, and actionable. Don't use bullet points or lists - just a brief, motivating insight."
        
        let userPrompt = """
        User context:
        \(context)
        
        Generate a brief, personalized insight about their fitness journey, nutrition, progress, or a tip to help them reach their goals. Be conversational and supportive.
        """
        
        let messages = [
            ChatGPTRequest.Message(role: "system", content: systemPrompt),
            ChatGPTRequest.Message(role: "user", content: userPrompt)
        ]
        
        do {
            let response = try await chatGPTService.sendMessage(messages: messages)
            let insight = response.trimmingCharacters(in: .whitespacesAndNewlines)
            
            self.currentInsight = insight
            self.lastUpdated = Date()
            cacheInsight(insight)
        } catch {
            print("Error generating insight: \(error)")
            // Fallback insight
            self.currentInsight = "Keep pushing towards your goals! Every workout counts, and consistency is the key to lasting results. 💪"
            self.lastUpdated = Date()
        }
    }
    
    private func buildInsightContext() async -> String {
        var context: [String] = []
        
        guard let userId = Auth.auth().currentUser?.uid else {
            return "New user starting their fitness journey."
        }
        
        // Fetch user profile
        do {
            if let profile = try await FirestoreService.shared.fetchUserProfile(userId: userId) {
                if let goal = profile.primaryGoal {
                    context.append("Fitness goal: \(goal.rawValue)")
                }
                context.append("Current weight: \(Int(profile.weight)) \(profile.useMetricUnits ? "kg" : "lbs")")
                if let targetWeight = profile.targetWeight {
                    context.append("Target weight: \(Int(targetWeight)) \(profile.useMetricUnits ? "kg" : "lbs")")
                }
                if let experience = profile.trainingExperience {
                    context.append("Experience level: \(experience.rawValue)")
                }
                context.append("Daily calorie goal: \(profile.dailyCaloriesGoal)")
            }
        } catch {
            print("Error fetching profile: \(error)")
        }
        
        // Fetch streak
        do {
            if let streak = try await FirestoreService.shared.fetchStreak(userId: userId) {
                context.append("Current workout streak: \(streak.currentStreak) days")
                context.append("Longest streak: \(streak.longestStreak) days")
            }
        } catch {
            print("Error fetching streak: \(error)")
        }
        
        // Fetch recent workouts count
        do {
            let workouts = try await FirestoreService.shared.fetchWorkouts(userId: userId)
            let thisWeek = workouts.filter {
                Calendar.current.isDate($0.date, equalTo: Date(), toGranularity: .weekOfYear)
            }
            context.append("Workouts this week: \(thisWeek.count)")
            
            if let lastWorkout = workouts.first {
                let formatter = RelativeDateTimeFormatter()
                formatter.unitsStyle = .full
                let relativeDate = formatter.localizedString(for: lastWorkout.date, relativeTo: Date())
                context.append("Last workout: \(relativeDate) (\(lastWorkout.name))")
            }
        } catch {
            print("Error fetching workouts: \(error)")
        }
        
        // Get day of week for timing-based insights
        let dayOfWeek = Calendar.current.component(.weekday, from: Date())
        let dayNames = ["", "Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
        context.append("Today is \(dayNames[dayOfWeek])")
        
        return context.isEmpty ? "User is tracking their fitness journey." : context.joined(separator: "\n")
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.gainsBgPrimary.ignoresSafeArea()
        
        VStack(spacing: 20) {
            AIInsightCard()
                .padding(.horizontal, 20)
            
            Spacer()
        }
        .padding(.top, 20)
    }
}

