//
//  AICoachView.swift
//  Gains
//
//  Created by Rayaan Bokhari on 11/20/25.
//

import SwiftUI

struct AICoachView: View {
    @StateObject private var viewModel = AICoachViewModel()
    @StateObject private var nutritionViewModel = NutritionViewModel()
    @StateObject private var profileViewModel = ProfileViewModel()
    @State private var messageText = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.gainsBackground.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header
                    HStack {
                        Text("AI Coach")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.gainsText)
                        
                        Spacer()
                        
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
                                ForEach(viewModel.messages) { message in
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
                        .onChange(of: viewModel.messages.count) { _ in
                            if let lastMessage = viewModel.messages.last {
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
            }
        }
    }
    
    private func sendMessage() {
        guard !messageText.isEmpty && !viewModel.isLoading else { return }
        let text = messageText
        messageText = ""
        viewModel.sendMessage(text)
    }
}

struct TypingIndicator: View {
    @State private var animationPhase = 0
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3) { index in
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
            Timer.scheduledTimer(withTimeInterval: 0.3, repeats: true) { _ in
                withAnimation {
                    animationPhase = (animationPhase + 1) % 3
                }
            }
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

