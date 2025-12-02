//
//  CommunityViewModel.swift
//  Gains
//
//  Created by Rayaan Bokhari on 11/20/25.
//

import Foundation
import SwiftUI
import Combine
import FirebaseAuth

@MainActor
class CommunityViewModel: ObservableObject {
    @Published var posts: [CommunityPost] = []
    @Published var stories: [String] = ["Stories", "Noles", "Sioma", "Han", "Utte"]
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let firestore = FirestoreService.shared
    private let auth = AuthService.shared
    
    init() {
        Task {
            await loadPosts()
        }
    }
    
    func loadPosts() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        do {
            posts = try await firestore.fetchPosts(limit: 50)
        } catch {
            errorMessage = "Failed to load posts: \(error.localizedDescription)"
            print("Error loading posts: \(error)")
        }
    }
    
    func refreshPosts() async {
        await loadPosts()
    }
    
    func likePost(_ post: CommunityPost) async {
        guard let user = auth.user,
              let postId = post.postId else { return }
        
        do {
            try await firestore.likePost(postId: postId, userId: user.uid)
            await loadPosts() // Refresh to get updated like count
        } catch {
            errorMessage = "Failed to like post: \(error.localizedDescription)"
            print("Error liking post: \(error)")
        }
    }
    
    func deletePost(_ post: CommunityPost) async {
        guard let user = auth.user,
              let postId = post.postId,
              post.userId == user.uid else { return }
        
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        do {
            try await firestore.deletePost(postId: postId, userId: user.uid)
            await loadPosts()
        } catch {
            errorMessage = "Failed to delete post: \(error.localizedDescription)"
            print("Error deleting post: \(error)")
        }
    }
    
    func createPost(text: String, imageUrl: String? = nil, calories: Int? = nil, protein: Double? = nil, carbs: Double? = nil, fats: Double? = nil) async throws {
        guard let user = auth.user else {
            throw NSError(domain: "CommunityViewModel", code: 1, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        // Get user profile for name and avatar
        let profile = try? await firestore.fetchUserProfile(userId: user.uid)
        let userName = profile?.name ?? "User"
        
        let post = CommunityPost(
            userId: user.uid,
            userName: userName,
            userAvatar: nil, // Could be added from profile
            timestamp: Date(),
            text: text,
            imageUrl: imageUrl,
            calories: calories,
            protein: protein,
            carbs: carbs,
            fats: fats
        )
        
        try await firestore.createPost(userId: user.uid, post: post)
        await loadPosts()
    }
}

