//
//  AICoachView.swift
//  Gains
//
//  Created by Rayaan Bokhari on 11/20/25.
//

import SwiftUI
import FirebaseAuth

struct AICoachView: View {
    @StateObject private var viewModel = AICoachViewModel()
    @StateObject private var nutritionViewModel = NutritionViewModel()
    @StateObject private var profileViewModel = ProfileViewModel()
    @StateObject private var homeViewModel = HomeViewModel()
    @StateObject private var workoutViewModel = WorkoutViewModel()
    @State private var messageText = ""
    @State private var showConversations = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Gradient background
                LinearGradient(
                    colors: [Color(hex: "0D0E14"), Color(hex: "0A0A0B")],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header
                    headerSection
                    
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
                                    .padding(.horizontal, GainsDesign.paddingHorizontal)
                                }
                            }
                            .padding(.vertical, 16)
                        }
                        .onChange(of: viewModel.currentConversation.messages.count) { _ in
                            if let lastMessage = viewModel.currentConversation.messages.last {
                                withAnimation {
                                    proxy.scrollTo(lastMessage.id, anchor: .bottom)
                                }
                            }
                        }
                        .onChange(of: viewModel.isLoading) { _ in
                            if viewModel.isLoading {
                                withAnimation {
                                    proxy.scrollTo("typing", anchor: .bottom)
                                }
                            }
                        }
                    }
                    
                    // Input Area
                    inputSection
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                // Connect ViewModels to provide context
                viewModel.setNutritionViewModel(nutritionViewModel)
                viewModel.setProfileViewModel(profileViewModel)
                viewModel.setHomeViewModel(homeViewModel)
                viewModel.setWorkoutViewModel(workoutViewModel)
                
                // Load context data
                Task {
                    await profileViewModel.loadProfile()
                    await homeViewModel.loadTodayIfPossible()
                    await workoutViewModel.loadWorkouts()
                    
                    // Update context service with summaries
                    if let summary = await homeViewModel.calculateWeeklySummary() {
                        await MainActor.run {
                            viewModel.userContextService.weeklyNutritionSummary = summary
                        }
                    }
                    
                    await MainActor.run {
                        viewModel.userContextService.weeklyTrainingSummary = workoutViewModel.weeklyTrainingSummary
                    }
                    
                    // Load streak and achievements
                    await loadStreakAndAchievements()
                }
            }
            .task {
                // Refresh conversations list on appear
                await viewModel.refreshConversationsList()
            }
            .sheet(isPresented: $showConversations) {
                ConversationListView(viewModel: viewModel)
            }
        }
    }
    
    private var headerSection: some View {
        HStack(spacing: 16) {
            Button {
                showConversations = true
            } label: {
                Image(systemName: "list.bullet")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.gainsPrimary)
                    .frame(width: 36, height: 36)
                    .background(Color.gainsCardSurface)
                    .cornerRadius(10)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 12))
                        .foregroundColor(.gainsPrimary)
                    
                    Text("AI Coach")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.gainsTextSecondary)
                }
                
                Text(viewModel.currentConversation.title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(1)
            }
            
            Spacer()
            
            Button {
                viewModel.startNewConversation()
            } label: {
                Image(systemName: "square.and.pencil")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.gainsPrimary)
                    .frame(width: 36, height: 36)
                    .background(Color.gainsCardSurface)
                    .cornerRadius(10)
            }
            
            if viewModel.isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .gainsPrimary))
            }
        }
        .padding(.horizontal, GainsDesign.paddingHorizontal)
        .padding(.vertical, 14)
        .background(
            Rectangle()
                .fill(.ultraThinMaterial)
                .environment(\.colorScheme, .dark)
        )
    }
    
    private var inputSection: some View {
        HStack(spacing: 12) {
            TextField("Ask anything...", text: $messageText)
                .textFieldStyle(PlainTextFieldStyle())
                .font(.system(size: 16))
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(Color.gainsCardSurface)
                .cornerRadius(GainsDesign.cornerRadiusSmall)
                .foregroundColor(.white)
                .disabled(viewModel.isLoading)
            
            Button(action: sendMessage) {
                if viewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .frame(width: 48, height: 48)
                        .background(Color.gainsTextMuted)
                        .cornerRadius(GainsDesign.cornerRadiusSmall)
                } else {
                    Image(systemName: "paperplane.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.white)
                        .frame(width: 48, height: 48)
                        .background(
                            Group {
                                if messageText.isEmpty {
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
                        .cornerRadius(GainsDesign.cornerRadiusSmall)
                }
            }
            .disabled(viewModel.isLoading || messageText.isEmpty)
        }
        .padding(.horizontal, GainsDesign.paddingHorizontal)
        .padding(.vertical, 12)
        .background(
            Rectangle()
                .fill(.ultraThinMaterial)
                .environment(\.colorScheme, .dark)
        )
    }
    
    private func sendMessage() {
        guard !messageText.isEmpty && !viewModel.isLoading else { return }
        let text = messageText
        messageText = ""
        viewModel.sendMessage(text)
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
    }
}

struct ConversationListView: View {
    @ObservedObject var viewModel: AICoachViewModel
    @Environment(\.dismiss) var dismiss
    @State private var showDeleteAlert = false
    @State private var conversationToDelete: ChatConversation?
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.gainsBgPrimary.ignoresSafeArea()
                
                List {
                    // Current conversation always at top
                    if !viewModel.conversations.contains(where: { $0.id == viewModel.currentConversation.id }) {
                        Button {
                            dismiss()
                        } label: {
                            conversationRow(viewModel.currentConversation, isCurrent: true)
                        }
                        .listRowBackground(Color.gainsCardSurface)
                    }
                    
                    ForEach(viewModel.conversations) { conversation in
                        Button {
                            viewModel.selectConversation(conversation)
                            dismiss()
                        } label: {
                            conversationRow(conversation, isCurrent: conversation.id == viewModel.currentConversation.id)
                        }
                        .listRowBackground(Color.gainsCardSurface)
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                conversationToDelete = conversation
                                showDeleteAlert = true
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
                .scrollContentBackground(.hidden)
                .refreshable {
                    await viewModel.refreshConversationsList()
                }
            }
            .navigationTitle("Conversations")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.gainsPrimary)
                }
            }
            .alert("Delete Conversation", isPresented: $showDeleteAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    if let conversation = conversationToDelete {
                        Task {
                            await viewModel.deleteConversation(conversation)
                        }
                    }
                }
            } message: {
                Text("Are you sure you want to delete this conversation?")
            }
        }
    }
    
    private func conversationRow(_ conversation: ChatConversation, isCurrent: Bool) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(conversation.title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                
                Spacer()
                
                if isCurrent {
                    Text("Current")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.gainsPrimary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.gainsPrimary.opacity(0.15))
                        .cornerRadius(6)
                }
            }
            
            if let lastMessage = conversation.messages.last {
                Text(lastMessage.content)
                    .font(.system(size: 14))
                    .foregroundColor(.gainsTextSecondary)
                    .lineLimit(2)
            }
            
            Text(conversation.lastUpdated, style: .relative)
                .font(.system(size: 12))
                .foregroundColor(.gainsTextMuted)
        }
        .padding(.vertical, 4)
    }
}

struct TypingIndicator: View {
    @State private var animationPhase = 0
    @State private var timer: Timer?
    
    var body: some View {
        HStack(spacing: 5) {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(Color.gainsTextSecondary)
                    .frame(width: 8, height: 8)
                    .opacity(animationPhase == index ? 1.0 : 0.3)
                    .animation(.easeInOut(duration: 0.3), value: animationPhase)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color.gainsCardSurface)
        .cornerRadius(18)
        .id("typing")
        .onAppear {
            timer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: true) { _ in
                animationPhase = (animationPhase + 1) % 3
            }
        }
        .onDisappear {
            timer?.invalidate()
            timer = nil
        }
    }
}

struct MessageBubble: View {
    let message: ChatMessage
    
    var body: some View {
        HStack {
            if message.isUser {
                Spacer()
            }
            
            VStack(alignment: message.isUser ? .trailing : .leading, spacing: 6) {
                Text(message.content)
                    .font(.system(size: 16))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        message.isUser
                            ? LinearGradient(
                                colors: [Color.gainsPrimary, Color.gainsAccentBlue],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                            : LinearGradient(
                                colors: [Color.gainsCardSurface, Color.gainsCardSurface],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                    )
                    .cornerRadius(18)
                
                Text(message.timestamp, style: .time)
                    .font(.system(size: 11))
                    .foregroundColor(.gainsTextMuted)
            }
            .frame(maxWidth: UIScreen.main.bounds.width * 0.75, alignment: message.isUser ? .trailing : .leading)
            
            if !message.isUser {
                Spacer()
            }
        }
        .padding(.horizontal, GainsDesign.paddingHorizontal)
    }
}

#Preview {
    AICoachView()
}
