//
//  HealthKitService.swift
//  Gains
//
//  Created by Rayaan Bokhari on 12/20/25.
//

import Foundation
import HealthKit
import Combine

@MainActor
class HealthKitService: ObservableObject {
    static let shared = HealthKitService()
    
    private let healthStore = HKHealthStore()
    
    @Published var isAuthorized = false
    @Published var isHealthKitAvailable = false
    @Published var syncEnabled = false
    
    // Callback for weight updates from HealthKit
    var onWeightUpdate: ((Double) -> Void)?
    
    // Data types to read
    private let typesToRead: Set<HKObjectType> = {
        var types: Set<HKObjectType> = []
        
        if let bodyMass = HKObjectType.quantityType(forIdentifier: .bodyMass) {
            types.insert(bodyMass)
        }
        if let bodyMassIndex = HKObjectType.quantityType(forIdentifier: .bodyMassIndex) {
            types.insert(bodyMassIndex)
        }
        if let activeEnergy = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned) {
            types.insert(activeEnergy)
        }
        if let stepCount = HKObjectType.quantityType(forIdentifier: .stepCount) {
            types.insert(stepCount)
        }
        if let dietaryWater = HKObjectType.quantityType(forIdentifier: .dietaryWater) {
            types.insert(dietaryWater)
        }
        types.insert(HKObjectType.workoutType())
        
        return types
    }()
    
    // Data types to write
    private let typesToWrite: Set<HKSampleType> = {
        var types: Set<HKSampleType> = []
        
        if let bodyMass = HKObjectType.quantityType(forIdentifier: .bodyMass) {
            types.insert(bodyMass)
        }
        if let dietaryEnergy = HKObjectType.quantityType(forIdentifier: .dietaryEnergyConsumed) {
            types.insert(dietaryEnergy)
        }
        if let dietaryWater = HKObjectType.quantityType(forIdentifier: .dietaryWater) {
            types.insert(dietaryWater)
        }
        types.insert(HKObjectType.workoutType())
        
        return types
    }()
    
    private init() {
        isHealthKitAvailable = HKHealthStore.isHealthDataAvailable()
        loadSyncPreference()
        checkAuthorizationStatus()
    }
    
    // MARK: - Authorization
    
    func requestAuthorization() async throws {
        guard isHealthKitAvailable else {
            throw HealthKitError.notAvailable
        }
        
        try await healthStore.requestAuthorization(toShare: typesToWrite, read: typesToRead)
        isAuthorized = checkAuthorizationStatus()
    }
    
    func checkAuthorizationStatus() -> Bool {
        guard isHealthKitAvailable else { return false }
        
        // Check if we can read body mass as a proxy for authorization
        guard let bodyMassType = HKObjectType.quantityType(forIdentifier: .bodyMass) else {
            return false
        }
        
        let status = healthStore.authorizationStatus(for: bodyMassType)
        let authorized = status == .sharingAuthorized
        isAuthorized = authorized
        return authorized
    }
    
    // MARK: - Weight Operations
    
    func readLatestWeight() async throws -> Double? {
        guard let weightType = HKQuantityType.quantityType(forIdentifier: .bodyMass) else {
            throw HealthKitError.notAvailable
        }
        
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: weightType,
                predicate: nil,
                limit: 1,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let sample = samples?.first as? HKQuantitySample else {
                    continuation.resume(returning: nil)
                    return
                }
                
                let weightInKg = sample.quantity.doubleValue(for: .gramUnit(with: .kilo))
                continuation.resume(returning: weightInKg)
            }
            
            healthStore.execute(query)
        }
    }
    
    func readWeightHistory(days: Int = 30) async throws -> [WeightEntry] {
        guard let weightType = HKQuantityType.quantityType(forIdentifier: .bodyMass) else {
            throw HealthKitError.notAvailable
        }
        
        let startDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: Date(), options: .strictEndDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: weightType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                let entries = (samples as? [HKQuantitySample])?.map { sample in
                    WeightEntry(
                        weight: sample.quantity.doubleValue(for: .gramUnit(with: .kilo)),
                        date: sample.startDate
                    )
                } ?? []
                
                continuation.resume(returning: entries)
            }
            
            healthStore.execute(query)
        }
    }
    
    func saveWeight(_ weightKg: Double, date: Date = Date()) async throws {
        guard let weightType = HKQuantityType.quantityType(forIdentifier: .bodyMass) else {
            throw HealthKitError.notAvailable
        }
        
        let quantity = HKQuantity(unit: .gramUnit(with: .kilo), doubleValue: weightKg)
        let sample = HKQuantitySample(type: weightType, quantity: quantity, start: date, end: date)
        
        try await healthStore.save(sample)
    }
    
    // MARK: - Steps
    
    func readTodaySteps() async throws -> Int {
        guard let stepsType = HKQuantityType.quantityType(forIdentifier: .stepCount) else {
            throw HealthKitError.notAvailable
        }
        
        let startOfDay = Calendar.current.startOfDay(for: Date())
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: Date(), options: .strictStartDate)
        
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: stepsType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, result, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                let steps = result?.sumQuantity()?.doubleValue(for: .count()) ?? 0
                continuation.resume(returning: Int(steps))
            }
            
            healthStore.execute(query)
        }
    }
    
    // MARK: - Active Energy
    
    func readTodayActiveEnergy() async throws -> Double {
        guard let energyType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) else {
            throw HealthKitError.notAvailable
        }
        
        let startOfDay = Calendar.current.startOfDay(for: Date())
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: Date(), options: .strictStartDate)
        
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: energyType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, result, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                let energy = result?.sumQuantity()?.doubleValue(for: .kilocalorie()) ?? 0
                continuation.resume(returning: energy)
            }
            
            healthStore.execute(query)
        }
    }
    
    // MARK: - Write Workout
    
    func saveWorkout(name: String, duration: TimeInterval, calories: Double, date: Date) async throws {
        let workout = HKWorkout(
            activityType: .traditionalStrengthTraining,
            start: date,
            end: date.addingTimeInterval(duration),
            duration: duration,
            totalEnergyBurned: HKQuantity(unit: .kilocalorie(), doubleValue: calories),
            totalDistance: nil,
            metadata: [HKMetadataKeyWorkoutBrandName: "Gains"]
        )
        
        try await healthStore.save(workout)
    }
    
    // MARK: - Write Nutrition
    
    func saveCaloriesConsumed(_ calories: Double, date: Date = Date()) async throws {
        guard let calorieType = HKQuantityType.quantityType(forIdentifier: .dietaryEnergyConsumed) else {
            throw HealthKitError.notAvailable
        }
        
        let quantity = HKQuantity(unit: .kilocalorie(), doubleValue: calories)
        let sample = HKQuantitySample(type: calorieType, quantity: quantity, start: date, end: date)
        
        try await healthStore.save(sample)
    }
    
    func saveWaterConsumed(_ ounces: Double, date: Date = Date()) async throws {
        guard let waterType = HKQuantityType.quantityType(forIdentifier: .dietaryWater) else {
            throw HealthKitError.notAvailable
        }
        
        // Convert ounces to liters (1 oz ≈ 0.0296 liters)
        let liters = ounces * 0.0295735
        let quantity = HKQuantity(unit: .liter(), doubleValue: liters)
        let sample = HKQuantitySample(type: waterType, quantity: quantity, start: date, end: date)
        
        try await healthStore.save(sample)
    }
    
    // MARK: - Sync Preferences
    
    func enableSync() {
        syncEnabled = true
        UserDefaults.standard.set(true, forKey: "healthKitSyncEnabled")
    }
    
    func disableSync() {
        syncEnabled = false
        UserDefaults.standard.set(false, forKey: "healthKitSyncEnabled")
    }
    
    private func loadSyncPreference() {
        syncEnabled = UserDefaults.standard.bool(forKey: "healthKitSyncEnabled")
    }
    
    // MARK: - HealthKit Observer
    
    func startObservingWeightChanges() {
        guard isHealthKitAvailable,
              let weightType = HKQuantityType.quantityType(forIdentifier: .bodyMass) else {
            return
        }
        
        // Create observer query for weight changes
        let query = HKObserverQuery(sampleType: weightType, predicate: nil) { [weak self] query, completionHandler, error in
            if let error = error {
                print("HealthKit observer error: \(error)")
                completionHandler()
                return
            }
            
            Task { @MainActor in
                await self?.handleWeightUpdate()
                completionHandler()
            }
        }
        
        healthStore.execute(query)
        
        // Enable background delivery
        healthStore.enableBackgroundDelivery(for: weightType, frequency: .immediate) { success, error in
            if let error = error {
                print("Failed to enable background delivery: \(error)")
            } else {
                print("Background delivery enabled: \(success)")
            }
        }
    }
    
    private func handleWeightUpdate() async {
        do {
            if let latestWeight = try await readLatestWeight() {
                // Notify callback
                onWeightUpdate?(latestWeight)
            }
        } catch {
            print("Error reading latest weight after update: \(error)")
        }
    }
}

// MARK: - Errors

enum HealthKitError: LocalizedError {
    case notAvailable
    case authorizationDenied
    case dataNotFound
    
    var errorDescription: String? {
        switch self {
        case .notAvailable:
            return "HealthKit is not available on this device"
        case .authorizationDenied:
            return "HealthKit access was denied"
        case .dataNotFound:
            return "No data found"
        }
    }
}

