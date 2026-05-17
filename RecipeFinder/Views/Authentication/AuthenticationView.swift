
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
            
            VStack(spacing: AppTheme.spacing40) {
                Spacer()
                
                VStack(spacing: AppTheme.spacing16) {
                    Image(systemName: "fork.knife.circle.fill")
                        .font(.system(size: AppTheme.fontSize80))
                        .foregroundStyle(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    AppTheme.textColor(for: colorScheme),
                                    AppTheme.textColor(for: colorScheme).opacity(AppTheme.highEmphasisOpacity)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: colorScheme == .dark ? .black.opacity(AppTheme.overlayLightOpacity) : .clear, radius: 10, x: 0, y: 5)
                    
                    Text("RecipeFinder")
                        .font(.system(size: AppTheme.fontSize42, weight: .bold, design: .rounded))
                        .adaptiveForegroundColor()
                    
                    Text("Discover, Create, Cook")
                        .font(.system(size: AppTheme.fontSize18, weight: .medium))
                        .foregroundColor(colorScheme == .dark ? .white.opacity(AppTheme.highEmphasisOpacity) : .black.opacity(0.7))
                }
                .padding(.bottom, AppTheme.spacing20)
                
                Spacer()
                
                VStack(spacing: AppTheme.spacing16) {
                    if authManager.biometricsAvailable && biometricsEnabled {
                        Button(action: {
                            Task {
                                try? await authManager.authenticateWithBiometrics()
                            }
                        }) {
                            HStack(spacing: AppTheme.spacing12) {
                                Image(systemName: authManager.biometricType == "Face ID" ? "faceid" : "touchid")
                                    .font(.system(size: AppTheme.fontSize22))
                                Text("Sign In with \(authManager.biometricType)")
                                    .fontWeight(.bold)
                                    .font(.system(size: AppTheme.fontSize17))
                            }
                            .adaptiveForegroundColor()
                            .frame(maxWidth: .infinity)
                            .frame(height: AppTheme.height56)
                            .background(
                                ZStack {
                                    RoundedRectangle(cornerRadius: AppTheme.cornerRadius14)
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
                                    
                                    RoundedRectangle(cornerRadius: AppTheme.cornerRadius14)
                                        .stroke(Color.white.opacity(AppTheme.shadowDarkOpacity), lineWidth: 1.5)
                                }
                            )
                            .shadow(color: AppTheme.accentColor(for: selectedTheme).opacity(0.4), radius: 15, x: 0, y: 8)
                        }
                    }
                    
                    NavigationLink(destination: EmailSignInView()) {
                        HStack {
                            Image(systemName: "envelope.fill")
                                .font(.system(size: AppTheme.fontSize20))
                            Text("Sign In with Email")
                                .fontWeight(.semibold)
                        }
                        .adaptiveForegroundColor()
                        .frame(maxWidth: .infinity)
                        .frame(height: AppTheme.height50)
                        .background(
                            RoundedRectangle(cornerRadius: AppTheme.cornerRadius12)
                                .fill(Color.white.opacity(AppTheme.overlayLightOpacity))
                                .overlay(
                                    RoundedRectangle(cornerRadius: AppTheme.cornerRadius12)
                                        .stroke(Color.white.opacity(AppTheme.shadowDarkOpacity), lineWidth: 1)
                                )
                        )
                    }

                    // TODO: Uncomment when Apple Developer account is active
//                    SignInWithAppleButton(.signIn) { request in
//                        request.requestedScopes = [.fullName, .email]
//                    } onCompletion: { result in
//                        if case .failure(let error) = result {
//                            appleSignInManager.errorMessage = error.localizedDescription
//                        } else {
//                            appleSignInManager.signIn()
//                        }
//                    }
//                    .signInWithAppleButtonStyle(colorScheme == .dark ? .white : .black)
//                    .frame(height: AppTheme.height50)
//                    .cornerRadius(AppTheme.cornerRadius12)

                    Button(action: { showSignUp = true }) {
                        Text("Don't have an account? **Sign Up**")
                            .font(.subheadline)
                            .adaptiveForegroundColor()
                    }
                    .padding(.top, AppTheme.spacing8)
                }
                .padding(.horizontal, AppTheme.spacing32)
                .padding(.bottom, AppTheme.spacing50)
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
                DispatchQueue.main.asyncAfter(deadline: .now() + AppTheme.animationDelayShort) {
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
            if newValue && !hasBeenPromptedForBiometrics && !biometricsEnabled {
                if authManager.biometricsAvailable {
                    DispatchQueue.main.asyncAfter(deadline: .now() + AppTheme.animationDelayLong) {
                        showBiometricSetup = true
                        hasBeenPromptedForBiometrics = true
                    }
                }
            }
        }
    }
}

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

    #if DEBUG
    private let testEmail = "test@recipefinder.com"
    private let testPassword = "test123"
    #endif

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
                VStack(spacing: AppTheme.spacing24) {
                    VStack(spacing: AppTheme.spacing8) {
                        Image(systemName: "person.crop.circle.fill")
                            .font(.system(size: AppTheme.fontSize60))
                            .adaptiveForegroundColor(opacity: AppTheme.veryHighEmphasisOpacity)
                            .padding(.top, AppTheme.spacing40)
                        
                        Text("Welcome Back")
                            .font(.system(size: AppTheme.fontSize32, weight: .bold))
                            .adaptiveForegroundColor()
                        
                        Text("Sign in to continue")
                            .font(.subheadline)
                            .adaptiveForegroundColor(opacity: AppTheme.highEmphasisOpacity)
                    }
                    .padding(.bottom, AppTheme.spacing20)
                    
                    VStack(spacing: AppTheme.spacing16) {
                        VStack(alignment: .leading, spacing: AppTheme.spacing8) {
                            Text("Email")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .adaptiveForegroundColor(opacity: AppTheme.veryHighEmphasisOpacity)
                            
                            TextField("", text: $email)
                                .textFieldStyle(AuthTextFieldStyle())
                                .keyboardType(.emailAddress)
                                .textContentType(.username)
                                .autocapitalization(.none)
                                .autocorrectionDisabled()
                            
                            if !email.isEmpty && !isValidEmail {
                                Text("Please enter a valid email address")
                                    .font(.caption)
                                    .foregroundColor(.orange.opacity(AppTheme.veryHighEmphasisOpacity))
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: AppTheme.spacing8) {
                            Text("Password")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .adaptiveForegroundColor(opacity: AppTheme.veryHighEmphasisOpacity)
                            
                            SecureField("", text: $password)
                                .textFieldStyle(AuthTextFieldStyle())
                                .textContentType(.password)
                                .submitLabel(.go)
                                .onSubmit {
                                    if canSignIn {
                                        signIn()
                                    }
                                }
                        }
                        
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
                            .adaptiveForegroundColor()
                            .frame(maxWidth: .infinity)
                            .frame(height: AppTheme.height50)
                            .background(
                                RoundedRectangle(cornerRadius: AppTheme.cornerRadius12)
                                    .fill(AppTheme.accentColor(for: selectedTheme))
                            )
                        }
                        .disabled(!canSignIn || isLoading)
                        .opacity((!canSignIn || isLoading) ? 0.6 : 1.0)
                        .padding(.top, AppTheme.spacing8)
                    }
                    .padding(.horizontal, AppTheme.spacing32)
                    
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
                    
                    if authManager.biometricsAvailable && !UserDefaults.standard.bool(forKey: "biometricsEnabled") {
                        DispatchQueue.main.asyncAfter(deadline: .now() + AppTheme.animationDelayMedium) {
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
                    VStack(spacing: AppTheme.spacing24) {
                        VStack(spacing: AppTheme.spacing8) {
                            Image(systemName: "person.crop.circle.badge.plus")
                                .font(.system(size: AppTheme.fontSize60))
                                .adaptiveForegroundColor(opacity: AppTheme.veryHighEmphasisOpacity)
                                .padding(.top, AppTheme.spacing40)
                            
                            Text("Create Account")
                                .font(.system(size: AppTheme.fontSize32, weight: .bold))
                                .adaptiveForegroundColor()
                            
                            Text("Join RecipeFinder today")
                                .font(.subheadline)
                                .adaptiveForegroundColor(opacity: AppTheme.highEmphasisOpacity)
                        }
                        .padding(.bottom, AppTheme.spacing20)
                        
                        VStack(spacing: AppTheme.spacing16) {
                            VStack(alignment: .leading, spacing: AppTheme.spacing8) {
                                Text("Full Name")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .adaptiveForegroundColor(opacity: AppTheme.veryHighEmphasisOpacity)
                                
                                TextField("", text: $fullName)
                                    .textFieldStyle(AuthTextFieldStyle())
                                    .textContentType(.name)
                                    .autocorrectionDisabled()
                            }
                            
                            VStack(alignment: .leading, spacing: AppTheme.spacing8) {
                                Text("Email")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .adaptiveForegroundColor(opacity: AppTheme.veryHighEmphasisOpacity)
                                
                                TextField("", text: $email)
                                    .textFieldStyle(AuthTextFieldStyle())
                                    .keyboardType(.emailAddress)
                                    .textContentType(.emailAddress)
                                    .autocapitalization(.none)
                                    .autocorrectionDisabled()
                                
                                if !email.isEmpty && !isValidEmail {
                                    Text("Please enter a valid email address")
                                        .font(.caption)
                                        .foregroundColor(.orange.opacity(AppTheme.veryHighEmphasisOpacity))
                                }
                            }
                            
                            VStack(alignment: .leading, spacing: AppTheme.spacing8) {
                                Text("Password")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .adaptiveForegroundColor(opacity: AppTheme.veryHighEmphasisOpacity)
                                
                                SecureField("", text: $password)
                                    .textFieldStyle(AuthTextFieldStyle())
                                    .textContentType(.newPassword)
                                
                                if !password.isEmpty && !isPasswordStrong {
                                    VStack(alignment: .leading, spacing: AppTheme.spacing4) {
                                        Text("Password must contain:")
                                            .font(.caption2)
                                            .adaptiveForegroundColor(opacity: AppTheme.highEmphasisOpacity)
                                        Text("• 8+ characters")
                                            .font(.caption2)
                                            .foregroundColor(password.count >= 8 ? .green : .red.opacity(AppTheme.highEmphasisOpacity))
                                        Text("• Uppercase & lowercase letters")
                                            .font(.caption2)
                                            .foregroundColor((password.rangeOfCharacter(from: .uppercaseLetters) != nil && password.rangeOfCharacter(from: .lowercaseLetters) != nil) ? .green : .red.opacity(AppTheme.highEmphasisOpacity))
                                        Text("• At least one number")
                                            .font(.caption2)
                                            .foregroundColor(password.rangeOfCharacter(from: .decimalDigits) != nil ? .green : .red.opacity(AppTheme.highEmphasisOpacity))
                                        Text("• Special character (!@#$%^&* etc.)")
                                            .font(.caption2)
                                            .foregroundColor(password.rangeOfCharacter(from: CharacterSet(charactersIn: "!@#$%^&*()_+-=[]{}|;:',.<>?/~`")) != nil ? .green : .red.opacity(AppTheme.highEmphasisOpacity))
                                    }
                                    .padding(.top, AppTheme.spacing4)
                                }
                            }
                            
                            VStack(alignment: .leading, spacing: AppTheme.spacing8) {
                                Text("Confirm Password")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .adaptiveForegroundColor(opacity: AppTheme.veryHighEmphasisOpacity)
                                
                                SecureField("", text: $confirmPassword)
                                    .textFieldStyle(AuthTextFieldStyle())
                                    .textContentType(.newPassword)
                                    .submitLabel(.go)
                                    .onSubmit {
                                        if isFormValid {
                                            signUp()
                                        }
                                    }
                                
                                if !confirmPassword.isEmpty && password != confirmPassword {
                                    Text("Passwords do not match")
                                        .font(.caption)
                                        .foregroundColor(.red.opacity(AppTheme.highEmphasisOpacity))
                                }
                            }
                            
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
                                .adaptiveForegroundColor()
                                .frame(maxWidth: .infinity)
                                .frame(height: AppTheme.height50)
                                .background(
                                    RoundedRectangle(cornerRadius: AppTheme.cornerRadius12)
                                        .fill(AppTheme.accentColor(for: selectedTheme))
                                )
                            }
                            .disabled(!isFormValid || isLoading)
                            .opacity((!isFormValid || isLoading) ? 0.6 : 1.0)
                            .padding(.top, AppTheme.spacing8)
                        }
                        .padding(.horizontal, AppTheme.spacing32)
                        
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
                    .adaptiveForegroundColor()
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
                try await authManager.signUpWithoutLogin(email: email, password: password, fullName: fullName)
                DispatchQueue.main.async {
                    HapticManager.shared.success()
                    isLoading = false
                    dismiss()
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

struct AuthTextFieldStyle: TextFieldStyle {
    @Environment(\.colorScheme) var colorScheme
    
    func _body(configuration: TextField<_Label>) -> some View {
        configuration
            .padding()
            .background(
                RoundedRectangle(cornerRadius: AppTheme.cornerRadius12)
                    .fill(AppTheme.textColor(for: colorScheme, opacity: 0.15))
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.cornerRadius12)
                            .stroke(AppTheme.textColor(for: colorScheme, opacity: 0.3), lineWidth: 1)
                    )
            )
            .adaptiveForegroundColor()
            .tint(AppTheme.textColor(for: colorScheme))
    }
}

#Preview {
    AuthenticationView()
}
