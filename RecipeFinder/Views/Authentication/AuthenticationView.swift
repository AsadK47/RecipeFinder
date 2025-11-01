//
//  AuthenticationView.swift
//  RecipeFinder
//
//  Native iOS authentication interface
//

import SwiftUI

struct AuthenticationView: View {
    @StateObject private var authManager = AuthenticationManager.shared
    @State private var showSignUp = false
    @State private var showOnboarding = false
    @State private var showAppleSignInInfo = false
    @State private var showBiometricSetup = false
    @AppStorage("appTheme") private var selectedTheme: AppTheme.ThemeType = .teal
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @AppStorage("hasBeenPromptedForBiometrics") private var hasBeenPromptedForBiometrics = false
    @AppStorage("biometricsEnabled") private var biometricsEnabled: Bool = false
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ZStack {
            AppTheme.backgroundGradient(for: selectedTheme, colorScheme: colorScheme)
                .ignoresSafeArea()
            
            VStack(spacing: 40) {
                Spacer()
                
                // App Logo and Title
                VStack(spacing: 16) {
                    Image(systemName: "fork.knife.circle.fill")
                        .font(.system(size: 80))
                        .foregroundStyle(
                            LinearGradient(
                                gradient: Gradient(colors: [.white, .white.opacity(0.8)]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
                    
                    Text("RecipeFinder")
                        .font(.system(size: 42, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text("Discover, Create, Cook")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                }
                .padding(.bottom, 20)
                
                Spacer()
                
                // Authentication Options
                VStack(spacing: 16) {
                    // Apple Sign In Placeholder
                    Button(action: { showAppleSignInInfo = true }) {
                        HStack(spacing: 8) {
                            Image(systemName: "applelogo")
                                .font(.system(size: 20))
                            Text("Sign In with Apple")
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.black.opacity(colorScheme == .dark ? 0.3 : 0.8))
                        )
                    }
                    
                    // Biometric Sign In (if available and user exists)
                    if authManager.biometricsAvailable && UserDefaults.standard.bool(forKey: "isAuthenticated") {
                        Button(action: {
                            Task {
                                try? await authManager.authenticateWithBiometrics()
                            }
                        }) {
                            HStack {
                                Image(systemName: authManager.biometricType == "Face ID" ? "faceid" : "touchid")
                                    .font(.system(size: 20))
                                Text("Sign In with \(authManager.biometricType)")
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.white.opacity(0.2))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                    )
                            )
                        }
                    }
                    
                    // Email Sign In Button
                    NavigationLink(destination: EmailSignInView()) {
                        HStack {
                            Image(systemName: "envelope.fill")
                                .font(.system(size: 20))
                            Text("Sign In with Email")
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white.opacity(0.2))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                )
                        )
                    }
                    
                    // Sign Up Link
                    Button(action: { showSignUp = true }) {
                        Text("Don't have an account? **Sign Up**")
                            .font(.subheadline)
                            .foregroundColor(.white)
                    }
                    .padding(.top, 8)
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 50)
            }
        }
        .sheet(isPresented: $showSignUp) {
            SignUpView()
        }
        .fullScreenCover(isPresented: $showOnboarding) {
            OnboardingView()
        }
        .sheet(isPresented: $showBiometricSetup) {
            BiometricSetupView()
        }
        .alert("Authentication Error", isPresented: .constant(authManager.authError != nil)) {
            Button("OK") {
                authManager.authError = nil
            }
        } message: {
            if let error = authManager.authError {
                Text(error.localizedDescription)
            }
        }
        .alert("Sign In with Apple", isPresented: $showAppleSignInInfo) {
            Button("Got it!", role: .cancel) {}
        } message: {
            Text("🍎 An Apple ID a day keeps the doctor away!\n\nLooking to implement soon. Hold on to your hats!")
        }
        .onChange(of: authManager.isAuthenticated) { oldValue, newValue in
            if newValue && !hasSeenOnboarding && !authManager.isGuestMode {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    showOnboarding = true
                    hasSeenOnboarding = true
                }
            } else if newValue && !authManager.isGuestMode && !hasBeenPromptedForBiometrics && !biometricsEnabled {
                // After successful sign in, prompt for biometrics if available and not yet enabled
                if authManager.biometricsAvailable {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        showBiometricSetup = true
                        hasBeenPromptedForBiometrics = true
                    }
                }
            }
        }
    }
}

// Email Sign In View

struct EmailSignInView: View {
    @StateObject private var authManager = AuthenticationManager.shared
    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    @AppStorage("appTheme") private var selectedTheme: AppTheme.ThemeType = .teal
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss
    
    // Test credentials for easy sign-in
    private let testEmail = "test@recipefinder.com"
    private let testPassword = "test123"
    
    // Email validation
    private var isValidEmail: Bool {
        let emailRegex = "^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    private var canSignIn: Bool {
        !email.isEmpty && !password.isEmpty && isValidEmail
    }
    
    var body: some View {
        ZStack {
            AppTheme.backgroundGradient(for: selectedTheme, colorScheme: colorScheme)
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: "person.crop.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.white.opacity(0.9))
                            .padding(.top, 40)
                        
                        Text("Welcome Back")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text("Sign in to continue")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .padding(.bottom, 20)
                    
                    // Form
                    VStack(spacing: 16) {
                        // Email Field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Email")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.white.opacity(0.9))
                            
                            TextField("", text: $email)
                                .textFieldStyle(AuthTextFieldStyle())
                                .keyboardType(.emailAddress)
                                .textContentType(.emailAddress)
                                .autocapitalization(.none)
                                .autocorrectionDisabled()
                            
                            if !email.isEmpty && !isValidEmail {
                                Text("Please enter a valid email address")
                                    .font(.caption)
                                    .foregroundColor(.orange.opacity(0.9))
                            }
                        }
                        
                        // Password Field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Password")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.white.opacity(0.9))
                            
                            SecureField("", text: $password)
                                .textFieldStyle(AuthTextFieldStyle())
                                .textContentType(.password)
                        }
                        
                        // Sign In Button
                        Button(action: signIn) {
                            Group {
                                if isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    Text("Sign In")
                                        .fontWeight(.semibold)
                                }
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(AppTheme.accentColor(for: selectedTheme))
                            )
                        }
                        .disabled(!canSignIn || isLoading)
                        .opacity((!canSignIn || isLoading) ? 0.6 : 1.0)
                        .padding(.top, 8)
                    }
                    .padding(.horizontal, 32)
                    
                    Spacer()
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .alert("Sign In Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }
    
    private func signIn() {
        isLoading = true
        HapticManager.shared.light()
        
        Task {
            do {
                try await authManager.signIn(email: email, password: password)
                await MainActor.run {
                    HapticManager.shared.success()
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = error.localizedDescription
                    showError = true
                    HapticManager.shared.error()
                }
            }
        }
    }
}

// Sign Up View

struct SignUpView: View {
    @StateObject private var authManager = AuthenticationManager.shared
    @State private var fullName = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showWelcomeSplash = false
    @AppStorage("appTheme") private var selectedTheme: AppTheme.ThemeType = .teal
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss
    
    // Email validation
    private var isValidEmail: Bool {
        let emailRegex = "^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    var isFormValid: Bool {
        !fullName.isEmpty &&
        !email.isEmpty &&
        isValidEmail &&
        !password.isEmpty &&
        password == confirmPassword &&
        password.count >= 6
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.backgroundGradient(for: selectedTheme, colorScheme: colorScheme)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        VStack(spacing: 8) {
                            Image(systemName: "person.crop.circle.badge.plus")
                                .font(.system(size: 60))
                                .foregroundColor(.white.opacity(0.9))
                                .padding(.top, 40)
                            
                            Text("Create Account")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(.white)
                            
                            Text("Join RecipeFinder today")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.8))
                        }
                        .padding(.bottom, 20)
                        
                        // Form
                        VStack(spacing: 16) {
                            // Full Name Field
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Full Name")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.white.opacity(0.9))
                                
                                TextField("", text: $fullName)
                                    .textFieldStyle(AuthTextFieldStyle())
                                    .textContentType(.name)
                                    .autocorrectionDisabled()
                            }
                            
                            // Email Field
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Email")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.white.opacity(0.9))
                                
                                TextField("", text: $email)
                                    .textFieldStyle(AuthTextFieldStyle())
                                    .keyboardType(.emailAddress)
                                    .textContentType(.emailAddress)
                                    .autocapitalization(.none)
                                    .autocorrectionDisabled()
                                
                                if !email.isEmpty && !isValidEmail {
                                    Text("Please enter a valid email address")
                                        .font(.caption)
                                        .foregroundColor(.orange.opacity(0.9))
                                }
                            }
                            
                            // Password Field
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Password")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.white.opacity(0.9))
                                
                                SecureField("", text: $password)
                                    .textFieldStyle(AuthTextFieldStyle())
                                    .textContentType(.newPassword)
                                
                                if !password.isEmpty && password.count < 6 {
                                    Text("Password must be at least 6 characters")
                                        .font(.caption)
                                        .foregroundColor(.red.opacity(0.8))
                                }
                            }
                            
                            // Confirm Password Field
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Confirm Password")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.white.opacity(0.9))
                                
                                SecureField("", text: $confirmPassword)
                                    .textFieldStyle(AuthTextFieldStyle())
                                    .textContentType(.newPassword)
                                
                                if !confirmPassword.isEmpty && password != confirmPassword {
                                    Text("Passwords do not match")
                                        .font(.caption)
                                        .foregroundColor(.red.opacity(0.8))
                                }
                            }
                            
                            // Sign Up Button
                            Button(action: signUp) {
                                Group {
                                    if isLoading {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    } else {
                                        Text("Create Account")
                                            .fontWeight(.semibold)
                                    }
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(AppTheme.accentColor(for: selectedTheme))
                                )
                            }
                            .disabled(!isFormValid || isLoading)
                            .opacity((!isFormValid || isLoading) ? 0.6 : 1.0)
                            .padding(.top, 8)
                        }
                        .padding(.horizontal, 32)
                        
                        Spacer()
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
            .toolbarBackground(.hidden, for: .navigationBar)
            .alert("Sign Up Error", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
            .fullScreenCover(isPresented: $showWelcomeSplash) {
                WelcomeSplashView(email: email) {
                    showWelcomeSplash = false
                    dismiss()
                }
            }
        }
    }
    
    private func signUp() {
        isLoading = true
        HapticManager.shared.light()
        
        Task {
            do {
                // Create account WITHOUT auto-login (defensive programming)
                try await authManager.signUpWithoutLogin(email: email, password: password, fullName: fullName)
                await MainActor.run {
                    HapticManager.shared.success()
                    isLoading = false
                    // Show welcome splash screen
                    showWelcomeSplash = true
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = error.localizedDescription
                    showError = true
                    HapticManager.shared.error()
                }
            }
        }
    }
}

// Custom Text Field Style

struct AuthTextFieldStyle: TextFieldStyle {
    typealias _Body = AnyView
    
    func _body(configuration: TextField<Self._Label>) -> AnyView {
        AnyView(
            configuration
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(0.15))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white.opacity(0.3), lineWidth: 1)
                        )
                )
                .foregroundColor(.white)
                .accentColor(.white)
        )
    }
}

#Preview {
    AuthenticationView()
}
