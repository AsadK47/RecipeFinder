//
//  BiometricSetupView.swift
//  RecipeFinder
//
//  Prompt user to enable Face ID/Touch ID after first sign in
//

import SwiftUI
import LocalAuthentication

struct BiometricSetupView: View {
    @StateObject private var authManager = AuthenticationManager.shared
    @Environment(\.dismiss) private var dismiss
    @AppStorage("appTheme") private var selectedTheme: AppTheme.ThemeType = .teal
    @AppStorage("biometricsEnabled") private var biometricsEnabled: Bool = false
    @Environment(\.colorScheme) var colorScheme
    
    @State private var isEnabling = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    private var biometricIcon: String {
        switch authManager.biometricType {
        case "Face ID":
            return "faceid"
        case "Touch ID":
            return "touchid"
        default:
            return "lock.shield"
        }
    }
    
    var body: some View {
        ZStack {
            AppTheme.backgroundGradient(for: selectedTheme, colorScheme: colorScheme)
                .ignoresSafeArea()
            
            VStack(spacing: 40) {
                Spacer()
                
                // Icon
                ZStack {
                    Circle()
                        .fill(AppTheme.accentColor(for: selectedTheme).opacity(0.2))
                        .frame(width: 120, height: 120)
                    
                    Image(systemName: biometricIcon)
                        .font(.system(size: 60))
                        .foregroundColor(AppTheme.accentColor(for: selectedTheme))
                }
                .padding(.bottom, 20)
                
                // Title and Description
                VStack(spacing: 16) {
                    Text("Enable \(authManager.biometricType)?")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                    
                    Text("Sign in faster and more securely using \(authManager.biometricType) instead of entering your password every time.")
                        .font(.body)
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, 32)
                }
                
                Spacer()
                
                // Buttons
                VStack(spacing: 16) {
                    Button(action: enableBiometrics) {
                        HStack {
                            if isEnabling {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Image(systemName: biometricIcon)
                                Text("Enable \(authManager.biometricType)")
                                    .fontWeight(.semibold)
                            }
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(AppTheme.accentColor(for: selectedTheme))
                        .cornerRadius(16)
                    }
                    .disabled(isEnabling)
                    
                    Button(action: skipSetup) {
                        Text("Not Now")
                            .fontWeight(.medium)
                            .foregroundColor(.white.opacity(0.8))
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                    }
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 50)
            }
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }
    
    private func enableBiometrics() {
        isEnabling = true
        HapticManager.shared.light()
        
        Task {
            do {
                // Test biometric authentication
                try await authManager.authenticateWithBiometrics()
                
                // If successful, enable it
                await MainActor.run {
                    biometricsEnabled = true
                    HapticManager.shared.success()
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isEnabling = false
                    errorMessage = error.localizedDescription
                    showError = true
                    HapticManager.shared.error()
                }
            }
        }
    }
    
    private func skipSetup() {
        HapticManager.shared.light()
        dismiss()
    }
}

#Preview {
    BiometricSetupView()
}
