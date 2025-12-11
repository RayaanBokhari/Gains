//
//  AICoachFloatingPanel.swift
//  Gains
//
//  Liquid glass floating AI Coach panel (Apple Maps style)
//

import SwiftUI
import FirebaseAuth

// MARK: - Panel State

enum AICoachPanelState: Equatable {
    case collapsed      // Small pill at bottom
    case preview        // Medium height with quick actions
    case expanded       // Full chat interface
    
    var height: CGFloat {
        switch self {
        case .collapsed: return 56
        case .preview: return 320
        case .expanded: return UIScreen.main.bounds.height * 0.85
        }
    }
}

// MARK: - Quick Action Type

enum AICoachAction: String, CaseIterable, Identifiable {
    case dietPlan = "Diet Plan"
    case workoutPlan = "Workout Plan"
    case chat = "Chat"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .dietPlan: return "leaf.fill"
        case .workoutPlan: return "dumbbell.fill"
        case .chat: return "bubble.left.and.bubble.right.fill"
        }
    }
    
    var description: String {
        switch self {
        case .dietPlan: return "Generate a personalized meal plan"
        case .workoutPlan: return "Create a custom workout routine"
        case .chat: return "Ask anything about fitness"
        }
    }
    
    var gradient: [Color] {
        switch self {
        case .dietPlan: return [Color(hex: "34C759"), Color(hex: "30D158")]
        case .workoutPlan: return [Color.gainsPrimary, Color.gainsAccentBlue]
        case .chat: return [Color(hex: "BF5AF2"), Color(hex: "AF52DE")]
        }
    }
    
    var prompt: String {
        switch self {
        case .dietPlan:
            return "Generate a personalized diet plan for me based on my goals, preferences, and current nutrition data. Include daily meals with specific foods and portions."
        case .workoutPlan:
            return "Create a personalized workout plan for me based on my fitness goals, experience level, and available equipment. Include exercises, sets, reps, and rest periods."
        case .chat:
            return ""
        }
    }
}

// MARK: - Floating Panel

struct AICoachFloatingPanel: View {
    @StateObject private var viewModel = AICoachViewModel()
    @StateObject private var nutritionViewModel = NutritionViewModel()
    @StateObject private var profileViewModel = ProfileViewModel()
    @StateObject private var homeViewModel = HomeViewModel()
    @StateObject private var workoutViewModel = WorkoutViewModel()
    
    @State private var panelState: AICoachPanelState = .collapsed
    @State private var messageText = ""
    @State private var dragOffset: CGFloat = 0
    @State private var selectedAction: AICoachAction?
    @State private var showConversations = false
    
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    private let collapsedHeight: CGFloat = 56
    private let previewHeight: CGFloat = 320
    private var expandedHeight: CGFloat { UIScreen.main.bounds.height * 0.85 }
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                Spacer()
                
                panelContent
                    .frame(height: currentHeight + dragOffset)
                    .frame(maxWidth: .infinity)
                    .background(panelBackground)
                    .clipShape(RoundedRectangle(cornerRadius: panelCornerRadius, style: .continuous))
                    .overlay(panelBorder)
                    .shadow(color: Color.black.opacity(0.3), radius: 20, x: 0, y: -5)
                    .gesture(dragGesture)
                    .animation(reduceMotion ? nil : .spring(response: 0.35, dampingFraction: 0.8), value: panelState)
                    .animation(reduceMotion ? nil : .spring(response: 0.35, dampingFraction: 0.8), value: dragOffset)
            }
            .padding(.horizontal, panelState == .expanded ? 0 : 12)
            .padding(.bottom, panelState == .expanded ? 0 : 8)
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .onAppear {
            setupViewModels()
        }
        .sheet(isPresented: $showConversations) {
            ConversationListView(viewModel: viewModel)
        }
    }
    
    // MARK: - Panel Content
    
    @ViewBuilder
    private var panelContent: some View {
        VStack(spacing: 0) {
            // Drag handle
            dragHandle
            
            switch panelState {
            case .collapsed:
                collapsedContent
            case .preview:
                previewContent
            case .expanded:
                expandedContent
            }
        }
    }
    
    // MARK: - Drag Handle
    
    private var dragHandle: some View {
        VStack(spacing: 0) {
            RoundedRectangle(cornerRadius: 3)
                .fill(Color.white.opacity(0.3))
                .frame(width: 36, height: 5)
                .padding(.top, 8)
                .padding(.bottom, 6)
        }
        .frame(maxWidth: .infinity)
        .contentShape(Rectangle())
        .onTapGesture {
            cycleState()
        }
    }
    
    // MARK: - Collapsed Content
    
    private var collapsedContent: some View {
        HStack(spacing: 12) {
            // Sparkle icon
            Image(systemName: "sparkles")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.gainsPrimary, Color.gainsAccentBlue],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            Text("AI Coach")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.white)
            
            Spacer()
            
            // Quick action indicators
            HStack(spacing: 8) {
                ForEach(AICoachAction.allCases) { action in
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: action.gradient,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 8, height: 8)
                }
            }
            
            Image(systemName: "chevron.up")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.gainsTextSecondary)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 12)
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation {
                panelState = .preview
            }
        }
    }
    
    // MARK: - Preview Content
    
    private var previewContent: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 12))
                            .foregroundColor(.gainsPrimary)
                        Text("AI Coach")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.gainsTextSecondary)
                    }
                    Text("What can I help with?")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                // Conversations button
                Button {
                    showConversations = true
                } label: {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.gainsTextSecondary)
                        .frame(width: 36, height: 36)
                        .background(Color.white.opacity(0.1))
                        .clipShape(Circle())
                }
            }
            .padding(.horizontal, 20)
            
            // Quick Action Cards
            VStack(spacing: 10) {
                ForEach(AICoachAction.allCases) { action in
                    QuickActionCard(action: action) {
                        handleAction(action)
                    }
                }
            }
            .padding(.horizontal, 20)
            
            Spacer()
        }
        .padding(.top, 4)
    }
    
    // MARK: - Expanded Content (Chat)
    
    private var expandedContent: some View {
        VStack(spacing: 0) {
            // Header
            expandedHeader
            
            // Messages
            ScrollViewReader { proxy in
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        ForEach(viewModel.currentConversation.messages) { message in
                            MessageBubble(message: message)
                                .id(message.id)
                        }
                        
                        if viewModel.isLoading {
                            HStack {
                                TypingIndicator()
                                Spacer()
                            }
                            .padding(.horizontal, 20)
                        }
                    }
                    .padding(.vertical, 16)
                }
                .onChange(of: viewModel.currentConversation.messages.count) { _, _ in
                    if let lastMessage = viewModel.currentConversation.messages.last {
                        withAnimation {
                            proxy.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
            }
            
            // Input
            expandedInput
        }
    }
    
    private var expandedHeader: some View {
        HStack(spacing: 12) {
            // Back button
            Button {
                withAnimation {
                    panelState = .preview
                }
            } label: {
                Image(systemName: "chevron.down")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.gainsTextSecondary)
                    .frame(width: 32, height: 32)
                    .background(Color.white.opacity(0.1))
                    .clipShape(Circle())
            }
            
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 10))
                        .foregroundColor(.gainsPrimary)
                    Text("AI Coach")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.gainsTextSecondary)
                }
                
                Text(viewModel.currentConversation.title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(1)
            }
            
            Spacer()
            
            // New conversation
            Button {
                viewModel.startNewConversation()
            } label: {
                Image(systemName: "square.and.pencil")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.gainsTextSecondary)
                    .frame(width: 32, height: 32)
                    .background(Color.white.opacity(0.1))
                    .clipShape(Circle())
            }
            
            // Conversations list
            Button {
                showConversations = true
            } label: {
                Image(systemName: "list.bullet")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.gainsTextSecondary)
                    .frame(width: 32, height: 32)
                    .background(Color.white.opacity(0.1))
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }
    
    private var expandedInput: some View {
        HStack(spacing: 10) {
            TextField("Ask anything...", text: $messageText)
                .textFieldStyle(PlainTextFieldStyle())
                .font(.system(size: 15))
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(Color.white.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .foregroundColor(.white)
                .disabled(viewModel.isLoading)
            
            Button(action: sendMessage) {
                Group {
                    if viewModel.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Image(systemName: "arrow.up")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                    }
                }
                .frame(width: 40, height: 40)
                .background(
                    Group {
                        if messageText.isEmpty || viewModel.isLoading {
                            Color.gainsTextMuted
                        } else {
                            LinearGradient(
                                colors: [Color.gainsPrimary, Color.gainsAccentBlue],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        }
                    }
                )
                .clipShape(Circle())
            }
            .disabled(viewModel.isLoading || messageText.isEmpty)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.black.opacity(0.3))
    }
    
    // MARK: - Panel Background
    
    private var panelBackground: some View {
        ZStack {
            // Base blur
            Rectangle()
                .fill(.ultraThinMaterial)
                .environment(\.colorScheme, .dark)
            
            // Dark tint overlay
            Rectangle()
                .fill(Color.black.opacity(0.4))
            
            // Subtle gradient
            LinearGradient(
                colors: [
                    Color.white.opacity(0.05),
                    Color.clear
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }
    
    private var panelBorder: some View {
        RoundedRectangle(cornerRadius: panelCornerRadius, style: .continuous)
            .stroke(
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.2),
                        Color.white.opacity(0.05)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                ),
                lineWidth: 0.5
            )
    }
    
    // MARK: - Computed Properties
    
    private var currentHeight: CGFloat {
        panelState.height
    }
    
    private var panelCornerRadius: CGFloat {
        panelState == .expanded ? 0 : 28
    }
    
    // MARK: - Drag Gesture
    
    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                let translation = -value.translation.height
                dragOffset = translation * 0.5 // Dampen the drag
            }
            .onEnded { value in
                let translation = -value.translation.height
                let velocity = -value.predictedEndTranslation.height
                
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    dragOffset = 0
                    
                    // Determine target state based on drag direction and velocity
                    if translation > 50 || velocity > 300 {
                        // Dragging up
                        switch panelState {
                        case .collapsed:
                            panelState = .preview
                        case .preview:
                            panelState = .expanded
                        case .expanded:
                            break
                        }
                    } else if translation < -50 || velocity < -300 {
                        // Dragging down
                        switch panelState {
                        case .collapsed:
                            break
                        case .preview:
                            panelState = .collapsed
                        case .expanded:
                            panelState = .preview
                        }
                    }
                }
            }
    }
    
    // MARK: - Actions
    
    private func cycleState() {
        withAnimation {
            switch panelState {
            case .collapsed:
                panelState = .preview
            case .preview:
                panelState = .collapsed
            case .expanded:
                panelState = .preview
            }
        }
    }
    
    private func handleAction(_ action: AICoachAction) {
        selectedAction = action
        
        withAnimation {
            panelState = .expanded
        }
        
        // If it's a generation action, send the prompt
        if !action.prompt.isEmpty {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                viewModel.sendMessage(action.prompt)
            }
        }
    }
    
    private func sendMessage() {
        guard !messageText.isEmpty && !viewModel.isLoading else { return }
        let text = messageText
        messageText = ""
        viewModel.sendMessage(text)
    }
    
    // MARK: - Setup
    
    private func setupViewModels() {
        viewModel.setNutritionViewModel(nutritionViewModel)
        viewModel.setProfileViewModel(profileViewModel)
        viewModel.setHomeViewModel(homeViewModel)
        viewModel.setWorkoutViewModel(workoutViewModel)
        
        Task {
            await profileViewModel.loadProfile()
            await homeViewModel.loadTodayIfPossible()
            await workoutViewModel.loadWorkouts()
            
            if let summary = await homeViewModel.calculateWeeklySummary() {
                await MainActor.run {
                    viewModel.userContextService.weeklyNutritionSummary = summary
                }
            }
            
            await MainActor.run {
                viewModel.userContextService.weeklyTrainingSummary = workoutViewModel.weeklyTrainingSummary
            }
            
            await loadStreakAndAchievements()
        }
        
        Task {
            await viewModel.refreshConversationsList()
        }
    }
    
    private func loadStreakAndAchievements() async {
        guard let userId = AuthService.shared.user?.uid else { return }
        
        do {
            let streak = try await FirestoreService.shared.fetchStreak(userId: userId)
            let achievements = try await FirestoreService.shared.fetchAchievements(userId: userId)
            let mealTemplates = try await FirestoreService.shared.fetchMealTemplates(userId: userId)
            
            await MainActor.run {
                viewModel.userContextService.streakData = streak
                viewModel.userContextService.achievements = achievements
                viewModel.userContextService.mealTemplates = mealTemplates
            }
        } catch {
            print("Error loading streak/achievements: \(error)")
        }
        
        await loadPlans()
    }
    
    private func loadPlans() async {
        guard let userId = AuthService.shared.user?.uid else { return }
        
        do {
            let dietaryPlans = try await FirestoreService.shared.fetchDietaryPlans(userId: userId)
            let activeDietaryPlan = dietaryPlans.first { $0.isActive }
            
            let workoutPlans = try await FirestoreService.shared.fetchWorkoutPlans(userId: userId)
            let activeWorkoutPlan = workoutPlans.first { $0.isActive }
            
            await MainActor.run {
                viewModel.userContextService.activeDietaryPlan = activeDietaryPlan
                viewModel.userContextService.activeWorkoutPlan = activeWorkoutPlan
            }
        } catch {
            print("Error loading plans: \(error)")
        }
    }
}

// MARK: - Quick Action Card

struct QuickActionCard: View {
    let action: AICoachAction
    let onTap: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                // Icon
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: action.gradient,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: action.icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                }
                
                // Text
                VStack(alignment: .leading, spacing: 3) {
                    Text(action.rawValue)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Text(action.description)
                        .font(.system(size: 12))
                        .foregroundColor(.gainsTextSecondary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                // Arrow
                Image(systemName: "arrow.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.gainsTextTertiary)
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.white.opacity(isPressed ? 0.12 : 0.08))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.white.opacity(0.08), lineWidth: 0.5)
            )
            .scaleEffect(isPressed ? 0.98 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: .infinity, pressing: { pressing in
            withAnimation(.easeInOut(duration: 0.15)) {
                isPressed = pressing
            }
        }, perform: {})
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.gainsBgPrimary.ignoresSafeArea()
        
        VStack {
            Text("Main Content")
                .foregroundColor(.white)
            Spacer()
        }
        
        AICoachFloatingPanel()
    }
}

