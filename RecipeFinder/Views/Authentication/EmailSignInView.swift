import SwiftUI

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

    private var isUITesting: Bool {
        ProcessInfo.processInfo.arguments.contains("-ui-testing")
    }

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
                                .accessibilityIdentifier("signin.email")
                            
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
                            
                            Group {
                                if isUITesting {
                                    TextField("", text: $password)
                                } else {
                                    SecureField("", text: $password)
                                }
                            }
                            .textFieldStyle(AuthTextFieldStyle())
                            .textContentType(.password)
                            .submitLabel(.go)
                            .onSubmit {
                                if canSignIn {
                                    signIn()
                                }
                            }
                            .accessibilityIdentifier("signin.password")
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
                        .accessibilityIdentifier("signin.submit")
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
