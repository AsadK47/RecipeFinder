import SwiftUI
import UIKit

struct SignUpView: View {
    @Environment(\.auth) private var authManager
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
        Validator.isValidEmail(email)
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
    
    private var isUITesting: Bool {
        ProcessInfo.processInfo.arguments.contains("-ui-testing")
    }

    /// Under UI testing, suppress the strong-password AutoFill overlay so typed
    /// credentials aren't intercepted or replaced (see RecipeFinderApp's
    /// `-ui-testing` hooks). Harmless in release — the argument is never present.
    private var passwordContentType: UITextContentType? {
        isUITesting ? nil : .newPassword
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
                                    .accessibilityIdentifier("signup.fullName")
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
                                    .accessibilityIdentifier("signup.email")
                                
                                if !email.isEmpty && !isValidEmail {
                                    Text("Please enter a valid email address")
                                        .font(.caption)
                                        .foregroundStyle(.orange.opacity(AppTheme.veryHighEmphasisOpacity))
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
                                .textContentType(passwordContentType)
                                .autocorrectionDisabled()
                                .accessibilityIdentifier("signup.password")
                                
                                if !password.isEmpty && !isPasswordStrong && !isUITesting {
                                    VStack(alignment: .leading, spacing: AppTheme.spacing4) {
                                        Text("Password must contain:")
                                            .font(.caption2)
                                            .adaptiveForegroundColor(opacity: AppTheme.highEmphasisOpacity)
                                        Text("• 8+ characters")
                                            .font(.caption2)
                                            .foregroundStyle(password.count >= 8 ? .green : .red.opacity(AppTheme.highEmphasisOpacity))
                                        Text("• Uppercase & lowercase letters")
                                            .font(.caption2)
                                            .foregroundStyle((password.rangeOfCharacter(from: .uppercaseLetters) != nil && password.rangeOfCharacter(from: .lowercaseLetters) != nil) ? .green : .red.opacity(AppTheme.highEmphasisOpacity))
                                        Text("• At least one number")
                                            .font(.caption2)
                                            .foregroundStyle(password.rangeOfCharacter(from: .decimalDigits) != nil ? .green : .red.opacity(AppTheme.highEmphasisOpacity))
                                        Text("• Special character (!@#$%^&* etc.)")
                                            .font(.caption2)
                                            .foregroundStyle(password.rangeOfCharacter(from: CharacterSet(charactersIn: "!@#$%^&*()_+-=[]{}|;:',.<>?/~`")) != nil ? .green : .red.opacity(AppTheme.highEmphasisOpacity))
                                    }
                                    .padding(.top, AppTheme.spacing4)
                                }
                            }
                            
                            VStack(alignment: .leading, spacing: AppTheme.spacing8) {
                                Text("Confirm Password")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .adaptiveForegroundColor(opacity: AppTheme.veryHighEmphasisOpacity)
                                
                                Group {
                                    if isUITesting {
                                        TextField("", text: $confirmPassword)
                                    } else {
                                        SecureField("", text: $confirmPassword)
                                    }
                                }
                                .textFieldStyle(AuthTextFieldStyle())
                                .textContentType(passwordContentType)
                                .autocorrectionDisabled()
                                .submitLabel(.go)
                                .onSubmit {
                                    if isFormValid {
                                        signUp()
                                    }
                                }
                                .accessibilityIdentifier("signup.confirmPassword")
                                
                                if !confirmPassword.isEmpty && password != confirmPassword {
                                    Text("Passwords do not match")
                                        .font(.caption)
                                        .foregroundStyle(.red.opacity(AppTheme.highEmphasisOpacity))
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
                            .accessibilityIdentifier("signup.submit")
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
