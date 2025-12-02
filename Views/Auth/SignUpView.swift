//
//  SignUpView.swift
//  Gains
//
//  Created by Rayaan Bokhari on 12/2/25.
//

import SwiftUI

struct SignUpView: View {
    @EnvironmentObject var authService: AuthService
    @Environment(\.dismiss) var dismiss
    
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var isLoading = false
    @State private var isGoogleLoading = false
    @State private var errorMessage: String?
    @State private var agreeToTerms = false
    
    private var isFormValid: Bool {
        !name.isEmpty &&
        !email.isEmpty &&
        password.count >= 6 &&
        password == confirmPassword &&
        agreeToTerms
    }
    
    private var passwordStrength: PasswordStrength {
        if password.count < 6 {
            return .weak
        } else if password.count < 10 {
            return .medium
        } else {
            return .strong
        }
    }
    
    var body: some View {
        ZStack {
            // Background
            Color.gainsBackground.ignoresSafeArea()
            
            // Decorative elements
            GeometryReader { geometry in
                Circle()
                    .fill(Color.gainsPrimary.opacity(0.08))
                    .frame(width: 200, height: 200)
                    .blur(radius: 40)
                    .offset(x: geometry.size.width - 80, y: -50)
            }
            
            ScrollView {
                VStack(spacing: 28) {
                    // Header
                    VStack(spacing: 12) {
                        HStack {
                            Button {
                                dismiss()
                            } label: {
                                Image(systemName: "xmark")
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundColor(.gainsSecondaryText)
                                    .padding(10)
                                    .background(Color.gainsCardBackground)
                                    .clipShape(Circle())
                            }
                            Spacer()
                        }
                        
                        Text("Create Account")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(.gainsText)
                        
                        Text("Start your fitness journey today")
                            .font(.system(size: 16))
                            .foregroundColor(.gainsSecondaryText)
                    }
                    .padding(.horizontal)
                    .padding(.top, 16)
                    
                    // Sign Up Form
                    VStack(spacing: 20) {
                        // Name Field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Full Name")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.gainsSecondaryText)
                            
                            HStack(spacing: 12) {
                                Image(systemName: "person.fill")
                                    .foregroundColor(.gainsSecondaryText)
                                    .frame(width: 20)
                                
                                TextField("", text: $name)
                                    .placeholder(when: name.isEmpty) {
                                        Text("Your name")
                                            .foregroundColor(.gainsSecondaryText.opacity(0.5))
                                    }
                                    .textContentType(.name)
                                    .autocapitalization(.words)
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
                                        Text("Min. 6 characters")
                                            .foregroundColor(.gainsSecondaryText.opacity(0.5))
                                    }
                                    .textContentType(.newPassword)
                                    .foregroundColor(.gainsText)
                            }
                            .padding()
                            .background(Color.gainsCardBackground)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.gainsSecondaryText.opacity(0.2), lineWidth: 1)
                            )
                            
                            // Password strength indicator
                            if !password.isEmpty {
                                PasswordStrengthView(strength: passwordStrength)
                            }
                        }
                        
                        // Confirm Password Field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Confirm Password")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.gainsSecondaryText)
                            
                            HStack(spacing: 12) {
                                Image(systemName: "lock.fill")
                                    .foregroundColor(.gainsSecondaryText)
                                    .frame(width: 20)
                                
                                SecureField("", text: $confirmPassword)
                                    .placeholder(when: confirmPassword.isEmpty) {
                                        Text("Repeat password")
                                            .foregroundColor(.gainsSecondaryText.opacity(0.5))
                                    }
                                    .textContentType(.newPassword)
                                    .foregroundColor(.gainsText)
                                
                                if !confirmPassword.isEmpty {
                                    Image(systemName: password == confirmPassword ? "checkmark.circle.fill" : "xmark.circle.fill")
                                        .foregroundColor(password == confirmPassword ? .green : .red)
                                }
                            }
                            .padding()
                            .background(Color.gainsCardBackground)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(
                                        !confirmPassword.isEmpty && password != confirmPassword ?
                                        Color.red.opacity(0.5) : Color.gainsSecondaryText.opacity(0.2),
                                        lineWidth: 1
                                    )
                            )
                            
                            if !confirmPassword.isEmpty && password != confirmPassword {
                                Text("Passwords don't match")
                                    .font(.system(size: 12))
                                    .foregroundColor(.red)
                            }
                        }
                        
                        // Terms Agreement
                        Button {
                            agreeToTerms.toggle()
                        } label: {
                            HStack(alignment: .top, spacing: 12) {
                                Image(systemName: agreeToTerms ? "checkmark.square.fill" : "square")
                                    .font(.system(size: 20))
                                    .foregroundColor(agreeToTerms ? .gainsPrimary : .gainsSecondaryText)
                                
                                Text("I agree to the Terms of Service and Privacy Policy")
                                    .font(.system(size: 14))
                                    .foregroundColor(.gainsSecondaryText)
                                    .multilineTextAlignment(.leading)
                                
                                Spacer()
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
                        
                        // Create Account Button
                        Button {
                            signUp()
                        } label: {
                            HStack {
                                if isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    Text("Create Account")
                                        .font(.system(size: 17, weight: .semibold))
                                }
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                LinearGradient(
                                    colors: isFormValid ?
                                        [Color.gainsPrimary, Color.gainsPrimary.opacity(0.8)] :
                                        [Color.gray, Color.gray.opacity(0.8)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(12)
                            .shadow(
                                color: isFormValid ? Color.gainsPrimary.opacity(0.4) : Color.clear,
                                radius: 10,
                                y: 5
                            )
                        }
                        .disabled(!isFormValid || isLoading)
                        
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
                        .padding(.vertical, 4)
                        
                        // Google Sign-In Button
                        Button {
                            signInWithGoogle()
                        } label: {
                            HStack(spacing: 12) {
                                if isGoogleLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .gainsText))
                                } else {
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
                        
                        // Already have account
                        HStack {
                            Text("Already have an account?")
                                .font(.system(size: 15))
                                .foregroundColor(.gainsSecondaryText)
                            
                            Button {
                                dismiss()
                            } label: {
                                Text("Sign In")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(.gainsPrimary)
                            }
                        }
                        .padding(.top, 8)
                    }
                    .padding(.horizontal)
                    
                    Spacer()
                        .frame(height: 40)
                }
            }
        }
    }
    
    private func signUp() {
        guard isFormValid else { return }
        
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                // Check if there's an anonymous user to link
                if authService.isAnonymous {
                    try await authService.linkAnonymousAccount(email: email, password: password, name: name)
                } else {
                    try await authService.signUp(email: email, password: password, name: name)
                }
                dismiss()
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
        
        Task {
            do {
                try await authService.signInWithGoogle()
                dismiss()
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
}

// MARK: - Password Strength

enum PasswordStrength {
    case weak, medium, strong
    
    var color: Color {
        switch self {
        case .weak: return .red
        case .medium: return .orange
        case .strong: return .green
        }
    }
    
    var label: String {
        switch self {
        case .weak: return "Weak"
        case .medium: return "Medium"
        case .strong: return "Strong"
        }
    }
    
    var progress: Double {
        switch self {
        case .weak: return 0.33
        case .medium: return 0.66
        case .strong: return 1.0
        }
    }
}

struct PasswordStrengthView: View {
    let strength: PasswordStrength
    
    var body: some View {
        HStack(spacing: 8) {
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.gainsCardBackground)
                        .frame(height: 4)
                        .cornerRadius(2)
                    
                    Rectangle()
                        .fill(strength.color)
                        .frame(width: geometry.size.width * strength.progress, height: 4)
                        .cornerRadius(2)
                        .animation(.easeInOut(duration: 0.3), value: strength)
                }
            }
            .frame(height: 4)
            
            Text(strength.label)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(strength.color)
        }
    }
}

#Preview {
    SignUpView()
        .environmentObject(AuthService.shared)
}

