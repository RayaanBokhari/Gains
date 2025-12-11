//
//  CommunityView.swift
//  Gains
//
//  Created by Rayaan Bokhari on 11/20/25.
//

import SwiftUI
import FirebaseAuth

struct CommunityView: View {
    @StateObject private var viewModel = CommunityViewModel()
    @State private var showCreatePost = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // App background gradient
                Color.gainsAppBackground
                    .ignoresSafeArea()
                
                if viewModel.isLoading && viewModel.posts.isEmpty {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .gainsPrimary))
                } else {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: GainsDesign.sectionSpacing) {
                            // Header
                            headerSection
                            
                            // Stories
                            storiesSection
                            
                            // Feed Posts
                            postsSection
                        }
                        .padding(.bottom, 100)
                    }
                    .refreshable {
                        await viewModel.refreshPosts()
                    }
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showCreatePost) {
                CreatePostView(
                    isPresented: $showCreatePost,
                    viewModel: viewModel
                )
            }
        }
    }
    
    private var headerSection: some View {
        HStack {
            Text("Community")
                .font(.system(size: 34, weight: .bold))
                .foregroundColor(.white)
            
            Spacer()
            
            Button {
                showCreatePost = true
            } label: {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.gainsPrimary, Color.gainsAccentTeal],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
        }
        .padding(.horizontal, GainsDesign.paddingHorizontal)
        .padding(.top, GainsDesign.titlePaddingTop)
    }
    
    private var storiesSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                ForEach(viewModel.stories, id: \.self) { story in
                    StoryCircle(name: story)
                }
            }
            .padding(.horizontal, GainsDesign.paddingHorizontal)
        }
    }
    
    private var postsSection: some View {
        Group {
            if viewModel.posts.isEmpty {
                emptyState
            } else {
                LazyVStack(spacing: 16) {
                    ForEach(viewModel.posts) { post in
                        CommunityPostCard(
                            post: post,
                            onLike: {
                                Task {
                                    await viewModel.likePost(post)
                                }
                            },
                            onDelete: {
                                Task {
                                    await viewModel.deletePost(post)
                                }
                            }
                        )
                    }
                }
                .padding(.horizontal, GainsDesign.paddingHorizontal)
            }
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(Color.gainsBgTertiary)
                    .frame(width: 80, height: 80)
                
                Image(systemName: "person.3.fill")
                    .font(.system(size: 32))
                    .foregroundColor(.gainsTextMuted)
            }
            
            VStack(spacing: 8) {
                Text("No Posts Yet")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(.white)
                
                Text("Be the first to share your progress!")
                    .font(.system(size: 15))
                    .foregroundColor(.gainsTextSecondary)
            }
            
            Button {
                showCreatePost = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "plus")
                        .font(.system(size: 14, weight: .semibold))
                    Text("Share Progress")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 28)
                .padding(.vertical, 14)
                .background(
                    LinearGradient(
                        colors: [Color.gainsPrimary, Color.gainsAccentBlue],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(14)
                .shadow(color: Color.gainsPrimary.opacity(0.3), radius: 12, x: 0, y: 6)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }
}

struct StoryCircle: View {
    let name: String
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                // Gradient ring
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [Color.gainsPrimary, Color.gainsAccentPurple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2
                    )
                    .frame(width: 68, height: 68)
                
                Circle()
                    .fill(Color.gainsCardSurface)
                    .frame(width: 60, height: 60)
                    .overlay(
                        Text(String(name.prefix(1)))
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.white)
                    )
            }
            
            Text(name)
                .font(.system(size: 12))
                .foregroundColor(.gainsTextSecondary)
                .lineLimit(1)
                .frame(width: 68)
        }
    }
}

struct CommunityPostCard: View {
    let post: CommunityPost
    let onLike: () -> Void
    let onDelete: (() -> Void)?
    @State private var showDeleteConfirmation = false
    
    init(post: CommunityPost, onLike: @escaping () -> Void, onDelete: (() -> Void)? = nil) {
        self.post = post
        self.onLike = onLike
        self.onDelete = onDelete
    }
    
    private var isLiked: Bool {
        guard let userId = AuthService.shared.user?.uid else { return false }
        return post.likes.contains(userId)
    }
    
    private var canDelete: Bool {
        guard let userId = AuthService.shared.user?.uid else { return false }
        return post.userId == userId
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // User Header
            HStack(spacing: 12) {
                // Avatar with gradient ring
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.gainsPrimary.opacity(0.3), Color.gainsAccentPurple.opacity(0.3)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 44, height: 44)
                    
                    Text(String(post.userName.prefix(1)))
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(post.userName)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Text(post.timeAgo)
                        .font(.system(size: 12))
                        .foregroundColor(.gainsTextMuted)
                }
                
                Spacer()
                
                if canDelete {
                    Menu {
                        Button(role: .destructive, action: {
                            showDeleteConfirmation = true
                        }) {
                            Label("Delete", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 16))
                            .foregroundColor(.gainsTextSecondary)
                            .frame(width: 32, height: 32)
                            .background(Color.gainsBgTertiary)
                            .cornerRadius(8)
                    }
                }
            }
            
            // Post Text
            Text(post.text)
                .font(.system(size: 16))
                .foregroundColor(.white)
                .lineSpacing(4)
            
            // Post Image/Metrics (placeholder)
            if post.imageUrl != nil || post.calories != nil {
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.gainsBgTertiary)
                    .frame(height: 180)
                    .overlay(
                        VStack {
                            if post.calories != nil {
                                HStack(spacing: 16) {
                                    if let calories = post.calories {
                                        MetricBadge(value: "\(calories)", unit: "cal", color: .gainsAccentOrange)
                                    }
                                    if let protein = post.protein {
                                        MetricBadge(value: "\(Int(protein))", unit: "g P", color: Color(hex: "FF6B6B"))
                                    }
                                    if let carbs = post.carbs {
                                        MetricBadge(value: "\(Int(carbs))", unit: "g C", color: .gainsPrimary)
                                    }
                                    if let fats = post.fats {
                                        MetricBadge(value: "\(Int(fats))", unit: "g F", color: Color(hex: "FFD93D"))
                                    }
                                }
                            }
                        }
                    )
            }
            
            // Like Button
            HStack(spacing: 16) {
                Button(action: onLike) {
                    HStack(spacing: 6) {
                        Image(systemName: isLiked ? "heart.fill" : "heart")
                            .font(.system(size: 18))
                            .foregroundColor(isLiked ? .gainsAccentRed : .gainsTextSecondary)
                        
                        Text("\(post.likeCount)")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.gainsTextSecondary)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Color.gainsBgTertiary)
                    .cornerRadius(20)
                }
                
                Spacer()
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: GainsDesign.cornerRadiusLarge)
                .fill(Color.gainsCardSurface)
        )
        .confirmationDialog("Delete Post", isPresented: $showDeleteConfirmation, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                onDelete?()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to delete this post?")
        }
    }
}

struct MetricBadge: View {
    let value: String
    let unit: String
    var color: Color = .gainsPrimary
    
    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(color)
            
            Text(unit)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.gainsTextSecondary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color.gainsCardSurface.opacity(0.8))
        .cornerRadius(10)
    }
}

#Preview {
    CommunityView()
}
