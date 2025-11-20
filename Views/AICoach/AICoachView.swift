//
//  AICoachView.swift
//  Gains
//
//  Created by Rayaan Bokhari on 11/20/25.
//

import SwiftUI

struct AICoachView: View {
    @StateObject private var viewModel = AICoachViewModel()
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
                        
                        Button(action: {}) {
                            Image(systemName: "play.fill")
                                .font(.system(size: 16))
                                .foregroundColor(.gainsPrimary)
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
                    }
                    
                    // Input Area
                    HStack(spacing: 12) {
                        TextField("Message", text: $messageText)
                            .textFieldStyle(PlainTextFieldStyle())
                            .padding()
                            .background(Color.gainsCardBackground)
                            .cornerRadius(12)
                            .foregroundColor(.gainsText)
                        
                        Button(action: sendMessage) {
                            Image(systemName: "mic.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.gainsPrimary)
                                .frame(width: 44, height: 44)
                                .background(Color.gainsCardBackground)
                                .cornerRadius(12)
                        }
                    }
                    .padding()
                }
            }
            .navigationBarHidden(true)
        }
    }
    
    private func sendMessage() {
        guard !messageText.isEmpty else { return }
        viewModel.sendMessage(messageText)
        messageText = ""
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

