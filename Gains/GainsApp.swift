//
//  GainsApp.swift
//  Gains
//
//  Created by Rayaan Bokhari on 11/20/25.
//

import SwiftUI
import FirebaseCore
import FirebaseAuth
import FirebaseFirestore
import GoogleSignIn

// MARK: - App Delegate for Firebase & Google Sign-In

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        FirebaseApp.configure()
        
        // Enable Firestore offline persistence with unlimited cache size
        // This allows the app to work offline and sync when back online
        let settings = FirestoreSettings()
        settings.cacheSettings = PersistentCacheSettings(sizeBytes: FirestoreCacheSizeUnlimited as NSNumber)
        Firestore.firestore().settings = settings
        
        return true
    }
    
    func application(_ app: UIApplication,
                     open url: URL,
                     options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        // Handle Google Sign-In
        if GIDSignIn.sharedInstance.handle(url) {
            return true
        }
        
        // Handle workout deep links
        return handleWorkoutURL(url)
    }
    
    private func handleWorkoutURL(_ url: URL) -> Bool {
        guard url.scheme == "gains" else { return false }
        
        // Handle workout actions from Live Activity
        if url.host == "workout" {
            let path = url.path
            
            Task { @MainActor in
                switch path {
                case "/complete":
                    // Log the current set with last values
                    ActiveWorkoutManager.shared.quickCompleteSet()
                    
                case "/skiprest":
                    // Skip the rest timer
                    ActiveWorkoutManager.shared.skipRestTimer()
                    
                case "/next":
                    // Move to next exercise
                    ActiveWorkoutManager.shared.nextExercise()
                    
                case "/previous":
                    // Move to previous exercise
                    ActiveWorkoutManager.shared.previousExercise()
                    
                case "/end":
                    // This will be handled by the UI - just open the app
                    // The app will show the finish confirmation
                    NotificationCenter.default.post(
                        name: NSNotification.Name("ShowEndWorkoutConfirmation"),
                        object: nil
                    )
                    
                default:
                    // Just open to the active workout
                    break
                }
            }
            return true
        }
        
        return false
    }
}

// MARK: - Main App

@main
struct GainsApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var authService = AuthService.shared
    @StateObject private var workoutManager = ActiveWorkoutManager.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authService)
                .environmentObject(workoutManager)
                .preferredColorScheme(.dark)
                .onOpenURL { url in
                    // Handle Google Sign-In URLs
                    if url.scheme == "com.googleusercontent.apps" || url.host?.contains("google") == true {
                        GIDSignIn.sharedInstance.handle(url)
                        return
                    }
                    
                    // Handle workout deep links from Live Activity
                    handleWorkoutDeepLink(url)
                }
        }
    }
    
    private func handleWorkoutDeepLink(_ url: URL) {
        guard url.scheme == "gains", url.host == "workout" else { return }
        
        let path = url.path
        
        Task { @MainActor in
            switch path {
            case "/complete":
                ActiveWorkoutManager.shared.quickCompleteSet()
                
            case "/skiprest":
                ActiveWorkoutManager.shared.skipRestTimer()
                
            case "/next":
                ActiveWorkoutManager.shared.nextExercise()
                
            case "/previous":
                ActiveWorkoutManager.shared.previousExercise()
                
            case "/end":
                NotificationCenter.default.post(
                    name: NSNotification.Name("ShowEndWorkoutConfirmation"),
                    object: nil
                )
                
            default:
                break
            }
        }
    }
}
