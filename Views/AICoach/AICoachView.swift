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
                Color.gainsBackground.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header
                    HStack {
                        Button {
                            showConversations = true
                        } label: {
                            Image(systemName: "list.bullet")
                                .foregroundColor(.gainsPrimary)
                        }
                        
                        Text(viewModel.currentConversation.title)
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.gainsText)
                            .lineLimit(1)
                        
                        Spacer()
                        
                        Button {
                            viewModel.startNewConversation()
                        } label: {
                            Image(systemName: "square.and.pencil")
                                .foregroundColor(.gainsPrimary)
                        }
                        
                        if viewModel.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .gainsPrimary))
                        }
                    }
                    .padding()
                    
                    // Messages
                    ScrollViewReader { proxy in
                        ScrollView {
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
                                    .padding(.horizontal)
                                }
                            }
                            .padding()
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
                    HStack(spacing: 12) {
                        TextField("Message", text: $messageText)
                            .textFieldStyle(PlainTextFieldStyle())
                            .padding()
                            .background(Color.gainsCardBackground)
                            .cornerRadius(12)
                            .foregroundColor(.gainsText)
                            .disabled(viewModel.isLoading)
                        
                        Button(action: sendMessage) {
                            if viewModel.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .gainsPrimary))
                                    .frame(width: 44, height: 44)
                            } else {
                                Image(systemName: "paperplane.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(.gainsPrimary)
                                    .frame(width: 44, height: 44)
                                    .background(Color.gainsCardBackground)
                                    .cornerRadius(12)
                            }
                        }
                        .disabled(viewModel.isLoading || messageText.isEmpty)
                    }
                    .padding()
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
            List {
                // Current conversation always at top
                if !viewModel.conversations.contains(where: { $0.id == viewModel.currentConversation.id }) {
                    Button {
                        dismiss()
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(viewModel.currentConversation.title)
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.primary)
                                Spacer()
                                Text("Current")
                                    .font(.system(size: 12))
                                    .foregroundColor(.gainsPrimary)
                            }
                            
                            if let lastMessage = viewModel.currentConversation.messages.last {
                                Text(lastMessage.content)
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)
                                    .lineLimit(2)
                            }
                        }
                    }
                }
                
                ForEach(viewModel.conversations) { conversation in
                    Button {
                        viewModel.selectConversation(conversation)
                        dismiss()
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(conversation.title)
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.primary)
                                Spacer()
                                if conversation.id == viewModel.currentConversation.id {
                                    Text("Current")
                                        .font(.system(size: 12))
                                        .foregroundColor(.gainsPrimary)
                                }
                            }
                            
                            if let lastMessage = conversation.messages.last {
                                Text(lastMessage.content)
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)
                                    .lineLimit(2)
                            }
                            
                            Text(conversation.lastUpdated, style: .relative)
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }
                    }
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
            .refreshable {
                await viewModel.refreshConversationsList()
            }
            .navigationTitle("Conversations")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
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
}

struct TypingIndicator: View {
    @State private var animationPhase = 0
    @State private var timer: Timer?
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(Color.gainsSecondaryText)
                    .frame(width: 8, height: 8)
                    .opacity(animationPhase == index ? 1.0 : 0.3)
            }
        }
        .padding()
        .background(Color.gainsCardBackground)
        .cornerRadius(16)
        .id("typing")
        .onAppear {
            timer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: true) { _ in
                withAnimation {
                    animationPhase = (animationPhase + 1) % 3
                }
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
            
            VStack(alignment: message.isUser ? .trailing : .leading, spacing: 4) {
                Text(message.content)
                    .font(.system(size: 16))
                    .foregroundColor(message.isUser ? .white : .gainsText)
                    .padding()
                    .background(message.isUser ? Color.gainsPrimary : Color.gainsCardBackground)
                    .cornerRadius(16)
                
                Text(message.timestamp, style: .time)
                    .font(.system(size: 12))
                    .foregroundColor(.gainsSecondaryText)
            }
            .frame(maxWidth: UIScreen.main.bounds.width * 0.75, alignment: message.isUser ? .trailing : .leading)
            
            if !message.isUser {
                Spacer()
            }
        }
    }
}

#Preview {
    AICoachView()
}

