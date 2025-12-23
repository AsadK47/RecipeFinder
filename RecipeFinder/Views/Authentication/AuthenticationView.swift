//
//  AuthenticationView.swift
//  RecipeFinder
//
//  Native iOS authentication interface
//

import SwiftUI
import AuthenticationServices

struct AuthenticationView: View {
    @StateObject private var authManager = AuthenticationManager.shared
    @StateObject private var appleSignInManager = AppleSignInManager.shared
    @State private var showSignUp = false
    @State private var showSignIn = false
    @State private var showBiometricSetup = false
    @State private var newUserEmail = ""
    @State private var showWelcomeSplash = false
    @AppStorage("appTheme") private var selectedTheme: AppTheme.ThemeType = .teal
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
                    // Biometric Sign In (preferred if available and enabled)
                    if authManager.biometricsAvailable && biometricsEnabled {
                        Button(action: {
                            Task {
                                try? await authManager.authenticateWithBiometrics()
                            }
                        }) {
                            HStack(spacing: 12) {
                                Image(systemName: authManager.biometricType == "Face ID" ? "faceid" : "touchid")
                                    .font(.system(size: 22))
                                Text("Sign In with \(authManager.biometricType)")
                                    .fontWeight(.bold)
                                    .font(.system(size: 17))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(
                                ZStack {
                                    RoundedRectangle(cornerRadius: 14)
                                        .fill(
                                            LinearGradient(
                                                gradient: Gradient(colors: [
                                                    AppTheme.accentColor(for: selectedTheme),
                                                    AppTheme.accentColor(for: selectedTheme).opacity(0.85)
                                                ]),
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                    
                                    RoundedRectangle(cornerRadius: 14)
                                        .stroke(Color.white.opacity(0.3), lineWidth: 1.5)
                                }
                            )
                            .shadow(color: AppTheme.accentColor(for: selectedTheme).opacity(0.4), radius: 15, x: 0, y: 8)
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
            SignUpView(onSignUpSuccess: { email in
                newUserEmail = email
                showWelcomeSplash = true
            })
        }
        .sheet(isPresented: $showSignIn) {
            EmailSignInView(prefillEmail: newUserEmail)
        }
        .fullScreenCover(isPresented: $showWelcomeSplash) {
            WelcomeSplashView(email: newUserEmail) {
                showWelcomeSplash = false
                // Small delay then show sign-in
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                    showSignIn = true
                }
            }
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
        .onChange(of: authManager.isAuthenticated) { oldValue, newValue in
            // Onboarding is now handled by RecipeFinderApp
            // Only handle biometric setup prompt here
            if newValue && !hasBeenPromptedForBiometrics && !biometricsEnabled {
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
    let prefillEmail: String
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
    
    init(prefillEmail: String = "") {
        self.prefillEmail = prefillEmail
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
                                .textContentType(.username) // Changed from .emailAddress for better autofill
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
                                .submitLabel(.go) // Allow quick submission with keyboard
                                .onSubmit {
                                    if canSignIn {
                                        signIn()
                                    }
                                }
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
        .onAppear {
            if !prefillEmail.isEmpty {
                email = prefillEmail
            }
        }
    }
    
    private func signIn() {
        isLoading = true
        HapticManager.shared.light()
        
        Task {
            do {
                try await authManager.signIn(email: email, password: password)
                DispatchQueue.main.async {
                    HapticManager.shared.success()
                    dismiss()
                    
                    // Prompt for biometric setup if not already enabled
                    if authManager.biometricsAvailable && !UserDefaults.standard.bool(forKey: "biometricsEnabled") {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            // This will be caught by the parent view's onChange
                            UserDefaults.standard.set(true, forKey: "shouldPromptBiometrics")
                        }
                    }
                }
            } catch {
                DispatchQueue.main.async {
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
    let onSignUpSuccess: (String) -> Void
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
        isPasswordStrong
    }
    
    // Industry-standard password strength check
    private var isPasswordStrong: Bool {
        let hasUppercase = password.rangeOfCharacter(from: .uppercaseLetters) != nil
        let hasLowercase = password.rangeOfCharacter(from: .lowercaseLetters) != nil
        let hasNumber = password.rangeOfCharacter(from: .decimalDigits) != nil
        let specialCharacters = CharacterSet(charactersIn: "!@#$%^&*()_+-=[]{}|;:',.<>?/~`")
        let hasSpecialChar = password.rangeOfCharacter(from: specialCharacters) != nil
        
        return password.count >= 8 && hasUppercase && hasLowercase && hasNumber && hasSpecialChar
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
                                    .textContentType(.username) // Changed for better autofill on new accounts
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
                                
                                if !password.isEmpty && !isPasswordStrong {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Password must contain:")
                                            .font(.caption2)
                                            .foregroundColor(.white.opacity(0.8))
                                        Text("• 8+ characters")
                                            .font(.caption2)
                                            .foregroundColor(password.count >= 8 ? .green : .red.opacity(0.8))
                                        Text("• Uppercase & lowercase letters")
                                            .font(.caption2)
                                            .foregroundColor((password.rangeOfCharacter(from: .uppercaseLetters) != nil && password.rangeOfCharacter(from: .lowercaseLetters) != nil) ? .green : .red.opacity(0.8))
                                        Text("• At least one number")
                                            .font(.caption2)
                                            .foregroundColor(password.rangeOfCharacter(from: .decimalDigits) != nil ? .green : .red.opacity(0.8))
                                        Text("• Special character (!@#$%^&* etc.)")
                                            .font(.caption2)
                                            .foregroundColor(password.rangeOfCharacter(from: CharacterSet(charactersIn: "!@#$%^&*()_+-=[]{}|;:',.<>?/~`")) != nil ? .green : .red.opacity(0.8))
                                    }
                                    .padding(.top, 4)
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
                                    .submitLabel(.go) // Allow quick submission with keyboard
                                    .onSubmit {
                                        if isFormValid {
                                            signUp()
                                        }
                                    }
                                
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
        }
    }
    
    private func signUp() {
        isLoading = true
        HapticManager.shared.light()
        
        Task {
            do {
                // Create account WITHOUT auto-login (defensive programming)
                try await authManager.signUpWithoutLogin(email: email, password: password, fullName: fullName)
                DispatchQueue.main.async {
                    HapticManager.shared.success()
                    isLoading = false
                    dismiss()
                    // Notify parent with email for welcome splash
                    onSignUpSuccess(email)
                }
            } catch {
                DispatchQueue.main.async {
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
