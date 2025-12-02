//
//  AuthService.swift
//  Gains
//
//  Created by Rayaan Bokhari on 11/20/25.
//
import Foundation
import Combine
import FirebaseAuth
import FirebaseCore
import GoogleSignIn

enum AuthError: LocalizedError {
    case invalidEmail
    case weakPassword
    case emailAlreadyInUse
    case wrongPassword
    case userNotFound
    case networkError
    case googleSignInFailed
    case googleSignInCancelled
    case noRootViewController
    case unknown(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidEmail:
            return "Please enter a valid email address."
        case .weakPassword:
            return "Password must be at least 6 characters."
        case .emailAlreadyInUse:
            return "An account with this email already exists."
        case .wrongPassword:
            return "Incorrect password. Please try again."
        case .userNotFound:
            return "No account found with this email."
        case .networkError:
            return "Network error. Please check your connection."
        case .googleSignInFailed:
            return "Google Sign-In failed. Please try again."
        case .googleSignInCancelled:
            return "Google Sign-In was cancelled."
        case .noRootViewController:
            return "Unable to present sign-in screen."
        case .unknown(let message):
            return message
        }
    }
}

@MainActor
final class AuthService: ObservableObject {
    static let shared = AuthService()
    
    @Published var user: User? = nil
    @Published var isAuthenticated: Bool = false
    @Published var isLoading: Bool = true
    
    private var authStateHandler: AuthStateDidChangeListenerHandle?
    
    private init() {
        authStateHandler = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor in
                self?.user = user
                self?.isAuthenticated = user != nil && !user!.isAnonymous
                self?.isLoading = false
            }
        }
    }
    
    deinit {
        if let handler = authStateHandler {
            Auth.auth().removeStateDidChangeListener(handler)
        }
    }
    
    // MARK: - Email/Password Authentication
    
    /// Sign in with email and password
    func signIn(email: String, password: String) async throws {
        guard !email.isEmpty else {
            throw AuthError.invalidEmail
        }
        
        do {
            let result = try await Auth.auth().signIn(withEmail: email, password: password)
            self.user = result.user
            self.isAuthenticated = true
            print("✅ AuthService: User signed in: \(result.user.uid)")
        } catch let error as NSError {
            throw mapFirebaseError(error)
        }
    }
    
    /// Create a new account with email and password
    func signUp(email: String, password: String, name: String) async throws {
        guard !email.isEmpty else {
            throw AuthError.invalidEmail
        }
        guard password.count >= 6 else {
            throw AuthError.weakPassword
        }
        
        do {
            let result = try await Auth.auth().createUser(withEmail: email, password: password)
            
            // Update display name
            let changeRequest = result.user.createProfileChangeRequest()
            changeRequest.displayName = name
            try await changeRequest.commitChanges()
            
            self.user = result.user
            self.isAuthenticated = true
            print("✅ AuthService: New user created: \(result.user.uid)")
            
            // Create initial profile
            let profile = UserProfile(name: name, dateJoined: Date())
            try await FirestoreService.shared.saveUserProfile(userId: result.user.uid, profile: profile)
            print("✅ AuthService: Initial profile created for new user")
        } catch let error as NSError {
            throw mapFirebaseError(error)
        }
    }
    
    /// Sign out the current user
    func signOut() throws {
        do {
            // Sign out from Google if signed in with Google
            GIDSignIn.sharedInstance.signOut()
            
            try Auth.auth().signOut()
            self.user = nil
            self.isAuthenticated = false
            print("✅ AuthService: User signed out")
        } catch {
            print("❌ AuthService: Sign out failed: \(error)")
            throw error
        }
    }
    
    /// Send password reset email
    func resetPassword(email: String) async throws {
        guard !email.isEmpty else {
            throw AuthError.invalidEmail
        }
        
        do {
            try await Auth.auth().sendPasswordReset(withEmail: email)
            print("✅ AuthService: Password reset email sent to \(email)")
        } catch let error as NSError {
            throw mapFirebaseError(error)
        }
    }
    
    // MARK: - Google Sign-In
    
    /// Sign in with Google
    func signInWithGoogle() async throws {
        // Get the client ID from Firebase
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            throw AuthError.googleSignInFailed
        }
        
        // Create Google Sign In configuration
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config
        
        // Get the root view controller
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            throw AuthError.noRootViewController
        }
        
        do {
            // Start the sign in flow
            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController)
            
            guard let idToken = result.user.idToken?.tokenString else {
                throw AuthError.googleSignInFailed
            }
            
            let accessToken = result.user.accessToken.tokenString
            
            // Create Firebase credential
            let credential = GoogleAuthProvider.credential(
                withIDToken: idToken,
                accessToken: accessToken
            )
            
            // Check if we have an anonymous user to link
            if let currentUser = Auth.auth().currentUser, currentUser.isAnonymous {
                // Link the anonymous account with Google
                let authResult = try await currentUser.link(with: credential)
                await updateUserAfterGoogleSignIn(authResult.user, googleUser: result.user)
                print("✅ AuthService: Anonymous account linked with Google")
            } else {
                // Sign in with Firebase
                let authResult = try await Auth.auth().signIn(with: credential)
                await updateUserAfterGoogleSignIn(authResult.user, googleUser: result.user)
                print("✅ AuthService: User signed in with Google: \(authResult.user.uid)")
            }
        } catch let error as GIDSignInError {
            if error.code == .canceled {
                throw AuthError.googleSignInCancelled
            }
            throw AuthError.googleSignInFailed
        } catch let error as NSError {
            throw mapFirebaseError(error)
        }
    }
    
    /// Update user profile after Google Sign-In
    private func updateUserAfterGoogleSignIn(_ firebaseUser: User, googleUser: GIDGoogleUser) async {
        self.user = firebaseUser
        self.isAuthenticated = true
        
        // Create or update profile with Google user info
        let name = googleUser.profile?.name ?? "User"
        
        do {
            if let existingProfile = try await FirestoreService.shared.fetchUserProfile(userId: firebaseUser.uid) {
                // Profile exists, update name if it's the default
                if existingProfile.name == "User" || existingProfile.name.isEmpty {
                    var updatedProfile = existingProfile
                    updatedProfile.name = name
                    try await FirestoreService.shared.saveUserProfile(userId: firebaseUser.uid, profile: updatedProfile)
                }
            } else {
                // Create new profile
                let profile = UserProfile(name: name, dateJoined: Date())
                try await FirestoreService.shared.saveUserProfile(userId: firebaseUser.uid, profile: profile)
                print("✅ AuthService: Profile created for Google user")
            }
        } catch {
            print("⚠️ AuthService: Failed to update profile after Google Sign-In: \(error)")
        }
    }
    
    // MARK: - Anonymous Account Linking
    
    /// Link anonymous account to email/password (preserves existing data)
    func linkAnonymousAccount(email: String, password: String, name: String) async throws {
        guard let currentUser = Auth.auth().currentUser, currentUser.isAnonymous else {
            // Not anonymous, just sign up normally
            try await signUp(email: email, password: password, name: name)
            return
        }
        
        guard !email.isEmpty else {
            throw AuthError.invalidEmail
        }
        guard password.count >= 6 else {
            throw AuthError.weakPassword
        }
        
        do {
            let credential = EmailAuthProvider.credential(withEmail: email, password: password)
            let result = try await currentUser.link(with: credential)
            
            // Update display name
            let changeRequest = result.user.createProfileChangeRequest()
            changeRequest.displayName = name
            try await changeRequest.commitChanges()
            
            self.user = result.user
            self.isAuthenticated = true
            print("✅ AuthService: Anonymous account linked to email: \(email)")
            
            // Update existing profile with name if it exists, or create new one
            if var profile = try await FirestoreService.shared.fetchUserProfile(userId: result.user.uid) {
                profile.name = name
                try await FirestoreService.shared.saveUserProfile(userId: result.user.uid, profile: profile)
            } else {
                let profile = UserProfile(name: name, dateJoined: Date())
                try await FirestoreService.shared.saveUserProfile(userId: result.user.uid, profile: profile)
            }
        } catch let error as NSError {
            throw mapFirebaseError(error)
        }
    }
    
    /// Check if current user is anonymous
    var isAnonymous: Bool {
        Auth.auth().currentUser?.isAnonymous ?? false
    }
    
    /// Get user's email if available
    var userEmail: String? {
        Auth.auth().currentUser?.email
    }
    
    /// Get user's display name if available
    var displayName: String? {
        Auth.auth().currentUser?.displayName
    }
    
    // MARK: - Legacy Support (for migration)
    
    /// Sign in anonymously (legacy - keeping for potential fallback)
    @available(*, deprecated, message: "Use signIn(email:password:) or signUp instead")
    func signInAnonymously() async throws {
        do {
            let result = try await Auth.auth().signInAnonymously()
            self.user = result.user
            // Note: isAuthenticated stays false for anonymous users
            print("⚠️ AuthService: Signed in anonymously (legacy): \(result.user.uid)")
        } catch {
            print("❌ AuthService: Anonymous sign in failed: \(error)")
            throw error
        }
    }
    
    // MARK: - Private Helpers
    
    private func mapFirebaseError(_ error: NSError) -> AuthError {
        guard error.domain == AuthErrorDomain else {
            return .unknown(error.localizedDescription)
        }
        
        switch AuthErrorCode(rawValue: error.code) {
        case .invalidEmail:
            return .invalidEmail
        case .weakPassword:
            return .weakPassword
        case .emailAlreadyInUse:
            return .emailAlreadyInUse
        case .wrongPassword:
            return .wrongPassword
        case .userNotFound:
            return .userNotFound
        case .networkError:
            return .networkError
        default:
            return .unknown(error.localizedDescription)
        }
    }
}
