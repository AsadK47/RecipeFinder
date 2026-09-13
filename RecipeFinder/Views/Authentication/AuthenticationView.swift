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
    @AppStorage("guestModeEnabled") private var guestModeEnabled = false
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
                    .accessibilityIdentifier("auth.showSignUp")

                    Button(action: { guestModeEnabled = true }) {
                        Text("Browse first")
                            .font(.footnote)
                            .foregroundStyle(.secondary.opacity(0.65))
                    }
                    .padding(.top, AppTheme.spacing4)
                    .accessibilityLabel("Browse recipes without an account")
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

#Preview {
    AuthenticationView()
}
