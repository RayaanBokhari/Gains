//
//  CommunityView.swift
//  Gains
//
//  Created by Rayaan Bokhari on 11/20/25.
//

import SwiftUI

struct CommunityView: View {
    @StateObject private var viewModel = CommunityViewModel()
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.gainsBackground.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Header
                        HStack {
                            Text("Community")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.gainsText)
                            
                            Spacer()
                            
                            Button(action: {}) {
                                Image(systemName: "circle.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(.gainsPrimary)
                            }
                        }
                        .padding()
                        
                        // Stories
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 16) {
                                ForEach(viewModel.stories, id: \.self) { story in
                                    StoryCircle(name: story)
                                }
                            }
                            .padding(.horizontal)
                        }
                        
                        // Feed Posts
                        VStack(spacing: 16) {
                            ForEach(viewModel.posts) { post in
                                CommunityPostCard(post: post)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
            .navigationBarHidden(true)
        }
    }
}

struct StoryCircle: View {
    let name: String
    
    var body: some View {
        VStack(spacing: 8) {
            Circle()
                .fill(Color.gainsCardBackground)
                .frame(width: 60, height: 60)
                .overlay(
                    Text(String(name.prefix(1)))
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.gainsText)
                )
            
            Text(name)
                .font(.system(size: 12))
                .foregroundColor(.gainsSecondaryText)
        }
    }
}

struct CommunityPostCard: View {
    let post: CommunityPost
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // User Header
            HStack {
                Circle()
                    .fill(Color.gainsCardBackground)
                    .frame(width: 40, height: 40)
                    .overlay(
                        Text(String(post.userName.prefix(1)))
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.gainsText)
                    )
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(post.userName)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.gainsText)
                    
                    Text(post.timeAgo)
                        .font(.system(size: 12))
                        .foregroundColor(.gainsSecondaryText)
                }
                
                Spacer()
            }
            
            // Post Text
            Text(post.text)
                .font(.system(size: 16))
                .foregroundColor(.gainsText)
            
            // Post Image (placeholder)
            if post.imageUrl != nil || post.calories != nil {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gainsCardBackground)
                    .frame(height: 200)
                    .overlay(
                        VStack {
                            if post.calories != nil {
                                HStack(spacing: 16) {
                                    if let calories = post.calories {
                                        MetricBadge(value: "\(calories)", unit: "cal")
                                    }
                                    if let protein = post.protein {
                                        MetricBadge(value: "\(Int(protein))", unit: "g")
                                    }
                                    if let carbs = post.carbs {
                                        MetricBadge(value: "\(Int(carbs))", unit: "g")
                                    }
                                    if let fats = post.fats {
                                        MetricBadge(value: "\(Int(fats))", unit: "")
                                    }
                                }
                            }
                        }
                    )
            }
            
            // Metrics
            if post.calories != nil {
                HStack(spacing: 16) {
                    if let calories = post.calories {
                        Text("\(calories) cal")
                            .font(.system(size: 14))
                            .foregroundColor(.gainsSecondaryText)
                    }
                    if let protein = post.protein {
                        Text("\(Int(protein)) g")
                            .font(.system(size: 14))
                            .foregroundColor(.gainsSecondaryText)
                    }
                    if let carbs = post.carbs {
                        Text("\(Int(carbs))g")
                            .font(.system(size: 14))
                            .foregroundColor(.gainsSecondaryText)
                    }
                    if let fats = post.fats {
                        Text("\(Int(fats))")
                            .font(.system(size: 14))
                            .foregroundColor(.gainsSecondaryText)
                    }
                }
            }
        }
        .padding()
        .background(Color.gainsCardBackground)
        .cornerRadius(16)
    }
}

struct MetricBadge: View {
    let value: String
    let unit: String
    
    var body: some View {
        Text("\(value) \(unit)")
            .font(.system(size: 12))
            .foregroundColor(.gainsText)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.gainsBackground.opacity(0.5))
            .cornerRadius(8)
    }
}

#Preview {
    CommunityView()
}

