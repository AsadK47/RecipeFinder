import SwiftUI

struct PasswordVerificationSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("appTheme") private var selectedTheme: AppTheme.ThemeType = .teal
    
    let email: String
    let onVerified: () -> Void
    
    @State private var password: String = ""
    @State private var isVerifying: Bool = false
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""
    @FocusState private var isPasswordFocused: Bool
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.backgroundGradient(for: selectedTheme, colorScheme: colorScheme)
                    .ignoresSafeArea()
                
                VStack(spacing: AppTheme.spacing32) {
                    Spacer()
                    
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(AppTheme.dividerOpacity))
                            .frame(width: AppTheme.width100, height: AppTheme.width100)
                        
                        Image(systemName: "lock.shield.fill")
                            .font(.system(size: AppTheme.fontSize50))
                            .foregroundStyle(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        AppTheme.accentColor(for: selectedTheme),
                                        AppTheme.accentColor(for: selectedTheme).opacity(0.7)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }
                    .padding(.bottom, AppTheme.spacing8)
                    
                    VStack(spacing: AppTheme.spacing12) {
                        Text("Verify Your Identity")
                            .font(.system(size: AppTheme.fontSize28, weight: .bold))
                            .adaptiveForegroundColor()
                        
                        Text("Enter your password to update account details")
                            .font(.subheadline)
                            .adaptiveForegroundColor(opacity: AppTheme.nearSolidOpacity)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, AppTheme.spacing32)
                    }
                    
                    HStack(spacing: AppTheme.spacing8) {
                        Image(systemName: "envelope.fill")
                            .font(.caption)
                            .adaptiveForegroundColor(opacity: AppTheme.subduedEmphasisOpacity)
                        Text(email)
                            .font(.system(size: AppTheme.fontSize15, weight: .medium))
                            .adaptiveForegroundColor(opacity: AppTheme.veryHighEmphasisOpacity)
                    }
                    .padding(.horizontal, AppTheme.cardHorizontalPadding)
                    .padding(.vertical, AppTheme.spacing12)
                    .background(
                        RoundedRectangle(cornerRadius: AppTheme.cornerRadius12)
                            .fill(Color.white.opacity(AppTheme.cardDarkOpacity))
                            .overlay(
                                RoundedRectangle(cornerRadius: AppTheme.cornerRadius12)
                                    .stroke(Color.white.opacity(AppTheme.shadowDarkOpacity), lineWidth: 1)
                            )
                    )
                    
                    VStack(alignment: .leading, spacing: AppTheme.spacing8) {
                        Text("Password")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .adaptiveForegroundColor(opacity: AppTheme.veryHighEmphasisOpacity)
                        
                        SecureField("Enter your password", text: $password)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: AppTheme.cornerRadius12)
                                    .fill(Color.white.opacity(AppTheme.cardDarkOpacity))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: AppTheme.cornerRadius12)
                                            .stroke(Color.white.opacity(AppTheme.shadowDarkOpacity), lineWidth: 1)
                                    )
                            )
                            .adaptiveForegroundColor()
                            .tint(AppTheme.textColor(for: colorScheme))
                            .focused($isPasswordFocused)
                            .textContentType(.password)
                            .submitLabel(.done)
                            .onSubmit {
                                verifyPassword()
                            }
                    }
                    .padding(.horizontal, AppTheme.spacing32)
                    .padding(.top, AppTheme.spacing8)
                    
                    if showError {
                        HStack(spacing: AppTheme.spacing8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.red)
                            Text(errorMessage)
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                        .transition(.opacity)
                    }
                    
                    Button(action: verifyPassword) {
                        Group {
                            if isVerifying {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                HStack(spacing: AppTheme.spacing12) {
                                    Image(systemName: "checkmark.shield.fill")
                                    Text("Verify & Continue")
                                        .fontWeight(.semibold)
                                }
                            }
                        }
                        .adaptiveForegroundColor()
                        .frame(maxWidth: .infinity)
                        .frame(height: AppTheme.height54)
                        .background(
                            RoundedRectangle(cornerRadius: AppTheme.cornerRadius16)
                                .fill(AppTheme.accentColor(for: selectedTheme))
                                .shadow(color: AppTheme.accentColor(for: selectedTheme).opacity(AppTheme.lowEmphasisOpacity), radius: AppTheme.shadowRadiusAccent, x: 0, y: AppTheme.shadowOffsetAccent)
                        )
                    }
                    .disabled(password.isEmpty || isVerifying)
                    .opacity((password.isEmpty || isVerifying) ? AppTheme.mediumEmphasisOpacity : AppTheme.fullOpacity)
                    .padding(.horizontal, AppTheme.spacing32)
                    .padding(.top, AppTheme.spacing8)
                    
                    Spacer()
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
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + AppTheme.animationDelayMedium) {
                    isPasswordFocused = true
                }
            }
        }
    }
    
    private func verifyPassword() {
        guard !password.isEmpty else { return }
        
        isVerifying = true
        showError = false
        HapticManager.shared.light()
        
        Task {
            let credentialManager = SecureCredentialManager.shared
            let isValid = credentialManager.verifyCredentials(email: email, password: password)
            
            DispatchQueue.main.async {
                isVerifying = false
                
                if isValid {
                    HapticManager.shared.success()
                    dismiss()
                    onVerified()
                } else {
                    errorMessage = "Incorrect password. Please try again."
                    showError = true
                    password = ""
                    HapticManager.shared.error()
                }
            }
        }
    }
}

#Preview {
    PasswordVerificationSheet(email: "test@recipefinder.com", onVerified: {})
}
