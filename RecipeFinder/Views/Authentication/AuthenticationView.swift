import SwiftUI
import AuthenticationServices

private let logger = AppLogger.logger(category: "Auth")

struct AuthenticationView: View {
    @Environment(\.auth) private var authManager
    @Environment(\.appleSignIn) private var appleSignInManager
    @State private var showSignUp = false
    @State private var showSignIn = false
    @State private var showBiometricSetup = false
    @State private var newUserEmail = ""
    @State private var showWelcomeSplash = false
    @AppStorage("appTheme") private var selectedTheme: AppTheme.ThemeType = .teal
    @AppStorage("hasBeenPromptedForBiometrics") private var hasBeenPromptedForBiometrics = false
    @AppStorage("biometricsEnabled") private var biometricsEnabled: Bool = false
    @AppStorage("guestModeEnabled") private var guestModeEnabled = false
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            AppTheme.backgroundGradient(for: selectedTheme, colorScheme: colorScheme)
                .ignoresSafeArea()

            VStack(spacing: AppTheme.spacing40) {
                Spacer()

                VStack(spacing: AppTheme.spacing16) {
                    Image(systemName: "fork.knife.circle.fill")
                        .accessibilityHidden(true)
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
                        .font(.system(.largeTitle, design: .rounded).weight(.bold))
                        .adaptiveForegroundColor()

                    Text("Discover, Create, Cook")
                        .font(.body.weight(.medium))
                        .adaptiveForegroundColor()
                        .lineLimit(nil)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.bottom, AppTheme.spacing20)

                Spacer()

                VStack(spacing: AppTheme.spacing16) {
                    if authManager.biometricsAvailable && biometricsEnabled {
                        Button(action: {
                            Task {
                                do {
                                    try await authManager.authenticateWithBiometrics()
                                } catch {
                                    logger.debug("Biometric auth declined or failed: \(error)")
                                }
                            }
                        }) {
                            HStack(spacing: AppTheme.spacing12) {
                                Image(systemName: authManager.biometricType == "Face ID" ? "faceid" : "touchid")
                                    .font(.system(size: AppTheme.fontSize22))
                                Text("Sign In with \(authManager.biometricType)")
                                    .font(.body.weight(.bold))
                                    .lineLimit(nil)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .adaptiveForegroundColor()
                            .frame(maxWidth: .infinity)
                            .frame(minHeight: AppTheme.height56)
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
                                .accessibilityHidden(true)
                            Text("Sign In with Email")
                                .font(.body.weight(.semibold))
                                .lineLimit(nil)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .adaptiveForegroundColor()
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: AppTheme.height50)
                        .background(
                            RoundedRectangle(cornerRadius: AppTheme.cornerRadius12)
                                .fill(Color.white.opacity(AppTheme.overlayLightOpacity))
                                .overlay(
                                    RoundedRectangle(cornerRadius: AppTheme.cornerRadius12)
                                        .stroke(Color.white.opacity(AppTheme.shadowDarkOpacity), lineWidth: 1)
                                )
                        )
                    }
                    .accessibilityIdentifier("auth.showSignIn")

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
                            .lineLimit(nil)
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(maxWidth: .infinity)
                    }
                    .frame(minHeight: 44)
                    .contentShape(Rectangle())
                    .padding(.top, AppTheme.spacing8)
                    .accessibilityIdentifier("auth.showSignUp")

                    Button(action: { guestModeEnabled = true; dismiss() }) {
                        Text("Browse first")
                            .font(.footnote)
                            // Primary (not secondary) adaptive colour: small muted text
                            // over the gradient dips below the contrast-audit threshold.
                            .adaptiveForegroundColor()
                            .lineLimit(nil)
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(maxWidth: .infinity)
                    }
                    .frame(minHeight: 44)
                    .contentShape(Rectangle())
                    .padding(.top, AppTheme.spacing4)
                    .accessibilityLabel("Browse recipes without an account")
                }
                .padding(.horizontal, AppTheme.spacing32)
                .padding(.bottom, AppTheme.spacing50)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
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

#Preview {
    AuthenticationView()
}
