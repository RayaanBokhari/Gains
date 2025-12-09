//
//  DietaryPlanService.swift
//  Gains
//
//  Created by Rayaan Bokhari on 12/20/25.
//

import Foundation
import Combine
import FirebaseFirestore
import FirebaseAuth

@MainActor
class DietaryPlanService: ObservableObject {
    @Published var plans: [DietaryPlan] = []
    @Published var activePlan: DietaryPlan?
    @Published var retiredPlans: [DietaryPlan] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let db = Firestore.firestore()
    private let auth = AuthService.shared
    
    // Active and available plans (not retired)
    var activePlans: [DietaryPlan] {
        plans.filter { !$0.isRetired }
    }
    
    func loadPlans() async {
        guard let user = auth.user else { return }
        isLoading = true
        
        do {
            let snapshot = try await db.collection("users")
                .document(user.uid)
                .collection("dietaryPlans")
                .order(by: "createdAt", descending: true)
                .getDocuments()
            
            var allPlans: [DietaryPlan] = []
            for document in snapshot.documents {
                if var plan = try? document.data(as: DietaryPlan.self) {
                    plan.planId = document.documentID
                    allPlans.append(plan)
                }
            }
            
            plans = allPlans.filter { !$0.isRetired }
            retiredPlans = allPlans.filter { $0.isRetired }
            activePlan = plans.first { $0.isActive }
            isLoading = false
        } catch {
            print("Error loading dietary plans: \(error)")
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }
    
    func savePlan(_ plan: DietaryPlan) async throws {
        guard let user = auth.user else { return }
        
        try db.collection("users")
            .document(user.uid)
            .collection("dietaryPlans")
            .document(plan.id.uuidString)
            .setData(from: plan)
        
        await loadPlans()
    }
    
    func updatePlan(_ plan: DietaryPlan) async throws {
        guard let user = auth.user, let planId = plan.planId else { return }
        
        try db.collection("users")
            .document(user.uid)
            .collection("dietaryPlans")
            .document(planId)
            .setData(from: plan)
        
        await loadPlans()
    }
    
    func setActivePlan(_ plan: DietaryPlan) async throws {
        guard let user = auth.user else { return }
        
        // Deactivate all other plans
        for var existingPlan in plans where existingPlan.isActive {
            existingPlan.isActive = false
            if let planId = existingPlan.planId {
                try db.collection("users")
                    .document(user.uid)
                    .collection("dietaryPlans")
                    .document(planId)
                    .setData(from: existingPlan)
            }
        }
        
        // Activate selected plan
        var updatedPlan = plan
        updatedPlan.isActive = true
        updatedPlan.isRetired = false
        updatedPlan.retiredAt = nil
        
        if let planId = plan.planId {
            try db.collection("users")
                .document(user.uid)
                .collection("dietaryPlans")
                .document(planId)
                .setData(from: updatedPlan)
        }
        
        await loadPlans()
    }
    
    func deactivatePlan(_ plan: DietaryPlan) async throws {
        guard let user = auth.user, let planId = plan.planId else { return }
        
        var updatedPlan = plan
        updatedPlan.isActive = false
        
        try db.collection("users")
            .document(user.uid)
            .collection("dietaryPlans")
            .document(planId)
            .setData(from: updatedPlan)
        
        await loadPlans()
    }
    
    func retirePlan(_ plan: DietaryPlan) async throws {
        guard let user = auth.user, let planId = plan.planId else { return }
        
        var updatedPlan = plan
        updatedPlan.isActive = false
        updatedPlan.isRetired = true
        updatedPlan.retiredAt = Date()
        
        try db.collection("users")
            .document(user.uid)
            .collection("dietaryPlans")
            .document(planId)
            .setData(from: updatedPlan)
        
        await loadPlans()
    }
    
    func restorePlan(_ plan: DietaryPlan) async throws {
        guard let user = auth.user, let planId = plan.planId else { return }
        
        var updatedPlan = plan
        updatedPlan.isRetired = false
        updatedPlan.retiredAt = nil
        
        try db.collection("users")
            .document(user.uid)
            .collection("dietaryPlans")
            .document(planId)
            .setData(from: updatedPlan)
        
        await loadPlans()
    }
    
    func deletePlan(_ plan: DietaryPlan) async throws {
        guard let user = auth.user, let planId = plan.planId else { return }
        
        try await db.collection("users")
            .document(user.uid)
            .collection("dietaryPlans")
            .document(planId)
            .delete()
        
        await loadPlans()
    }
}

