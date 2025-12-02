//
//  AuthenticationView.swift
//  Gains
//
//  Created by Rayaan Bokhari on 12/2/25.
//

import SwiftUI

struct AuthenticationView: View {
    @EnvironmentObject var authService: AuthService
    @State private var isShowingSignUp = false
    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var isGoogleLoading = false
    @State private var errorMessage: String?
    @State private var showForgotPassword = false
    @State private var resetEmailSent = false
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.gainsBackground,
                    Color.gainsBackground.opacity(0.95),
                    Color.gainsPrimary.opacity(0.15)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            // Decorative circles
            GeometryReader { geometry in
                Circle()
                    .fill(Color.gainsPrimary.opacity(0.1))
                    .frame(width: 300, height: 300)
                    .blur(radius: 60)
                    .offset(x: -100, y: -50)
                
                Circle()
                    .fill(Color.gainsPrimary.opacity(0.08))
                    .frame(width: 250, height: 250)
                    .blur(radius: 50)
                    .offset(x: geometry.size.width - 100, y: geometry.size.height - 200)
            }
            
            ScrollView {
                VStack(spacing: 28) {
                    Spacer()
                        .frame(height: 50)
                    
                    // Logo & Title
                    VStack(spacing: 16) {
                        // App icon
                        ZStack {
                            RoundedRectangle(cornerRadius: 24)
                                .fill(
                                    LinearGradient(
                                        colors: [Color.gainsPrimary, Color.gainsPrimary.opacity(0.7)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 80, height: 80)
                                .shadow(color: Color.gainsPrimary.opacity(0.5), radius: 20, y: 10)
                            
                            Image(systemName: "figure.strengthtraining.traditional")
                                .font(.system(size: 36, weight: .semibold))
                                .foregroundColor(.white)
                        }
                        
                        Text("Gains")
                            .font(.system(size: 42, weight: .bold, design: .rounded))
                            .foregroundColor(.gainsText)
                        
                        Text("Track your fitness journey")
                            .font(.system(size: 17, weight: .medium))
                            .foregroundColor(.gainsSecondaryText)
                    }
                    
                    Spacer()
                        .frame(height: 12)
                    
                    // Login Form
                    VStack(spacing: 16) {
                        // Email Field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Email")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.gainsSecondaryText)
                            
                            HStack(spacing: 12) {
                                Image(systemName: "envelope.fill")
                                    .foregroundColor(.gainsSecondaryText)
                                    .frame(width: 20)
                                
                                TextField("", text: $email)
                                    .placeholder(when: email.isEmpty) {
                                        Text("your@email.com")
                                            .foregroundColor(.gainsSecondaryText.opacity(0.5))
                                    }
                                    .textContentType(.emailAddress)
                                    .keyboardType(.emailAddress)
                                    .autocapitalization(.none)
                                    .autocorrectionDisabled()
                                    .foregroundColor(.gainsText)
                            }
                            .padding()
                            .background(Color.gainsCardBackground)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.gainsSecondaryText.opacity(0.2), lineWidth: 1)
                            )
                        }
                        
                        // Password Field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Password")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.gainsSecondaryText)
                            
                            HStack(spacing: 12) {
                                Image(systemName: "lock.fill")
                                    .foregroundColor(.gainsSecondaryText)
                                    .frame(width: 20)
                                
                                SecureField("", text: $password)
                                    .placeholder(when: password.isEmpty) {
                                        Text("••••••••")
                                            .foregroundColor(.gainsSecondaryText.opacity(0.5))
                                    }
                                    .textContentType(.password)
                                    .foregroundColor(.gainsText)
                            }
                            .padding()
                            .background(Color.gainsCardBackground)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.gainsSecondaryText.opacity(0.2), lineWidth: 1)
                            )
                        }
                        
                        // Forgot Password
                        HStack {
                            Spacer()
                            Button {
                                showForgotPassword = true
                            } label: {
                                Text("Forgot password?")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.gainsPrimary)
                            }
                        }
                        
                        // Error Message
                        if let error = errorMessage {
                            HStack(spacing: 8) {
                                Image(systemName: "exclamationmark.circle.fill")
                                    .foregroundColor(.red)
                                Text(error)
                                    .font(.system(size: 14))
                                    .foregroundColor(.red)
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(12)
                        }
                        
                        // Reset Email Sent Confirmation
                        if resetEmailSent {
                            HStack(spacing: 8) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                Text("Password reset email sent!")
                                    .font(.system(size: 14))
                                    .foregroundColor(.green)
                            }
                            .padding()
                            .background(Color.green.opacity(0.1))
                            .cornerRadius(12)
                        }
                        
                        // Sign In Button
                        Button {
                            signIn()
                        } label: {
                            HStack {
                                if isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    Text("Sign In")
                                        .font(.system(size: 17, weight: .semibold))
                                }
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                LinearGradient(
                                    colors: [Color.gainsPrimary, Color.gainsPrimary.opacity(0.8)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(12)
                            .shadow(color: Color.gainsPrimary.opacity(0.4), radius: 10, y: 5)
                        }
                        .disabled(isLoading || email.isEmpty || password.isEmpty)
                        .opacity(email.isEmpty || password.isEmpty ? 0.6 : 1)
                    }
                    .padding(.horizontal)
                    
                    // Divider
                    HStack {
                        Rectangle()
                            .fill(Color.gainsSecondaryText.opacity(0.3))
                            .frame(height: 1)
                        
                        Text("or")
                            .font(.system(size: 14))
                            .foregroundColor(.gainsSecondaryText)
                            .padding(.horizontal, 16)
                        
                        Rectangle()
                            .fill(Color.gainsSecondaryText.opacity(0.3))
                            .frame(height: 1)
                    }
                    .padding(.horizontal)
                    
                    // Social Sign-In Buttons
                    VStack(spacing: 12) {
                        // Google Sign-In Button
                        Button {
                            signInWithGoogle()
                        } label: {
                            HStack(spacing: 12) {
                                if isGoogleLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .gainsText))
                                } else {
                                    // Google "G" icon
                                    GoogleLogoView()
                                        .frame(width: 20, height: 20)
                                    
                                    Text("Continue with Google")
                                        .font(.system(size: 16, weight: .semibold))
                                }
                            }
                            .foregroundColor(.gainsText)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color.gainsCardBackground)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.gainsSecondaryText.opacity(0.3), lineWidth: 1)
                            )
                        }
                        .disabled(isGoogleLoading)
                    }
                    .padding(.horizontal)
                    
                    // Sign Up Link
                    VStack(spacing: 12) {
                        Text("Don't have an account?")
                            .font(.system(size: 15))
                            .foregroundColor(.gainsSecondaryText)
                        
                        Button {
                            isShowingSignUp = true
                        } label: {
                            Text("Create Account")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(.gainsPrimary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color.gainsPrimary.opacity(0.1))
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.gainsPrimary.opacity(0.3), lineWidth: 1)
                                )
                        }
                        .padding(.horizontal)
                    }
                    
                    Spacer()
                        .frame(height: 30)
                }
            }
        }
        .sheet(isPresented: $isShowingSignUp) {
            SignUpView()
                .environmentObject(authService)
        }
        .alert("Reset Password", isPresented: $showForgotPassword) {
            TextField("Email", text: $email)
                .textContentType(.emailAddress)
                .keyboardType(.emailAddress)
                .autocapitalization(.none)
            
            Button("Cancel", role: .cancel) { }
            Button("Send Reset Link") {
                sendPasswordReset()
            }
        } message: {
            Text("Enter your email address and we'll send you a link to reset your password.")
        }
    }
    
    private func signIn() {
        guard !email.isEmpty, !password.isEmpty else { return }
        
        isLoading = true
        errorMessage = nil
        resetEmailSent = false
        
        Task {
            do {
                try await authService.signIn(email: email, password: password)
            } catch let error as AuthError {
                errorMessage = error.errorDescription
            } catch {
                errorMessage = error.localizedDescription
            }
            isLoading = false
        }
    }
    
    private func signInWithGoogle() {
        isGoogleLoading = true
        errorMessage = nil
        resetEmailSent = false
        
        Task {
            do {
                try await authService.signInWithGoogle()
            } catch let error as AuthError {
                // Don't show error for cancelled sign-in
                if case .googleSignInCancelled = error {
                    // User cancelled, no need to show error
                } else {
                    errorMessage = error.errorDescription
                }
            } catch {
                errorMessage = error.localizedDescription
            }
            isGoogleLoading = false
        }
    }
    
    private func sendPasswordReset() {
        guard !email.isEmpty else {
            errorMessage = "Please enter your email address"
            return
        }
        
        Task {
            do {
                try await authService.resetPassword(email: email)
                resetEmailSent = true
                errorMessage = nil
            } catch let error as AuthError {
                errorMessage = error.errorDescription
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}

// MARK: - Google Logo View

struct GoogleLogoView: View {
    var body: some View {
        ZStack {
            // Multi-colored G using overlapping arcs
            Circle()
                .stroke(Color.clear, lineWidth: 3)
                .overlay(
                    GeometryReader { geo in
                        let size = min(geo.size.width, geo.size.height)
                        let center = CGPoint(x: size/2, y: size/2)
                        let radius = size/2 - 2
                        
                        // Red arc (top right)
                        Path { path in
                            path.addArc(center: center, radius: radius, startAngle: .degrees(-45), endAngle: .degrees(45), clockwise: false)
                        }
                        .stroke(Color(red: 0.92, green: 0.26, blue: 0.21), lineWidth: 3)
                        
                        // Yellow arc (bottom right)
                        Path { path in
                            path.addArc(center: center, radius: radius, startAngle: .degrees(45), endAngle: .degrees(135), clockwise: false)
                        }
                        .stroke(Color(red: 0.98, green: 0.74, blue: 0.02), lineWidth: 3)
                        
                        // Green arc (bottom left)
                        Path { path in
                            path.addArc(center: center, radius: radius, startAngle: .degrees(135), endAngle: .degrees(225), clockwise: false)
                        }
                        .stroke(Color(red: 0.13, green: 0.69, blue: 0.30), lineWidth: 3)
                        
                        // Blue arc (top left and top)
                        Path { path in
                            path.addArc(center: center, radius: radius, startAngle: .degrees(225), endAngle: .degrees(315), clockwise: false)
                        }
                        .stroke(Color(red: 0.26, green: 0.52, blue: 0.96), lineWidth: 3)
                        
                        // Horizontal bar of G
                        Rectangle()
                            .fill(Color(red: 0.26, green: 0.52, blue: 0.96))
                            .frame(width: size * 0.45, height: 3)
                            .position(x: size * 0.73, y: size/2)
                    }
                )
        }
    }
}

// MARK: - Placeholder Modifier

extension View {
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder placeholder: () -> Content
    ) -> some View {
        ZStack(alignment: alignment) {
            placeholder().opacity(shouldShow ? 1 : 0)
            self
        }
    }
}

#Preview {
    AuthenticationView()
        .environmentObject(AuthService.shared)
}
