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
                
                VStack(spacing: 24) {
                    Spacer()
                    
                    // Lock Icon
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.1))
                            .frame(width: 100, height: 100)
                        
                        Image(systemName: "lock.shield.fill")
                            .font(.system(size: 50))
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
                    .padding(.bottom, 8)
                    
                    VStack(spacing: 12) {
                        Text("Verify Your Identity")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text("Enter your password to update account details")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.85))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }
                    
                    // Email Display
                    HStack(spacing: 8) {
                        Image(systemName: "envelope.fill")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                        Text(email)
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.white.opacity(0.9))
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(0.15))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
                            )
                    )
                    
                    // Password Field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Password")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.white.opacity(0.9))
                        
                        SecureField("Enter your password", text: $password)
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
                            .focused($isPasswordFocused)
                            .textContentType(.password)
                            .submitLabel(.done)
                            .onSubmit {
                                verifyPassword()
                            }
                    }
                    .padding(.horizontal, 32)
                    .padding(.top, 8)
                    
                    if showError {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.red)
                            Text(errorMessage)
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                        .transition(.opacity)
                    }
                    
                    // Verify Button
                    Button(action: verifyPassword) {
                        Group {
                            if isVerifying {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                HStack(spacing: 12) {
                                    Image(systemName: "checkmark.shield.fill")
                                    Text("Verify & Continue")
                                        .fontWeight(.semibold)
                                }
                            }
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(AppTheme.accentColor(for: selectedTheme))
                                .shadow(color: AppTheme.accentColor(for: selectedTheme).opacity(0.4), radius: 10, x: 0, y: 5)
                        )
                    }
                    .disabled(password.isEmpty || isVerifying)
                    .opacity((password.isEmpty || isVerifying) ? 0.6 : 1.0)
                    .padding(.horizontal, 32)
                    .padding(.top, 8)
                    
                    Spacer()
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
            .onAppear {
                // Auto-focus password field after a small delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
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
            // Verify password using SecureCredentialManager
            let credentialManager = SecureCredentialManager.shared
            let isValid = credentialManager.verifyCredentials(email: email, password: password)
            
            await MainActor.run {
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
