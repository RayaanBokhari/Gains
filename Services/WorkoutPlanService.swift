//
//  WorkoutPlanService.swift
//  Gains
//
//  Created by Rayaan Bokhari on 12/20/25.
//

import Foundation
import Combine
import FirebaseFirestore
import FirebaseAuth

@MainActor
class WorkoutPlanService: ObservableObject {
    @Published var plans: [WorkoutPlan] = []
    @Published var activePlan: WorkoutPlan?
    
    private let firestore = FirestoreService.shared
    private let auth = AuthService.shared
    
    func loadPlans() async {
        guard let user = auth.user else { return }
        
        do {
            plans = try await firestore.fetchWorkoutPlans(userId: user.uid)
            activePlan = plans.first { $0.isActive }
        } catch {
            print("Error loading workout plans: \(error)")
        }
    }
    
    func savePlan(_ plan: WorkoutPlan) async throws {
        guard let user = auth.user else { return }
        try await firestore.saveWorkoutPlan(userId: user.uid, plan: plan)
        await loadPlans()
    }
    
    func setActivePlan(_ plan: WorkoutPlan) async throws {
        guard let user = auth.user else { return }
        
        // Deactivate all other plans
        for var existingPlan in plans where existingPlan.isActive {
            existingPlan.isActive = false
            try await firestore.updateWorkoutPlan(userId: user.uid, plan: existingPlan)
        }
        
        // Activate selected plan
        var updatedPlan = plan
        updatedPlan.isActive = true
        try await firestore.updateWorkoutPlan(userId: user.uid, plan: updatedPlan)
        
        await loadPlans()
    }
    
    func deletePlan(_ plan: WorkoutPlan) async throws {
        guard let user = auth.user, let planId = plan.planId else { return }
        try await firestore.deleteWorkoutPlan(userId: user.uid, planId: planId)
        await loadPlans()
    }
}

