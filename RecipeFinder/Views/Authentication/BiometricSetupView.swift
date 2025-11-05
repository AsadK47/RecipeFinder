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
    @State private var iconScale: CGFloat = 0.8
    @State private var iconRotation: Double = 0
    @State private var contentOpacity: Double = 0
    @State private var shimmerOffset: CGFloat = -200
    @State private var particlesOpacity: Double = 0
    
    // Pre-computed particle data for performance
    private let securityIcons = ["lock.fill", "key.fill", "shield.fill"]
    private let particleData: [(icon: String, size: CGFloat, x: CGFloat, y: CGFloat)] = {
        (0..<15).map { _ in
            (
                icon: ["lock.fill", "key.fill", "shield.fill"].randomElement()!,
                size: CGFloat.random(in: 8...16),
                x: CGFloat.random(in: 50...350),
                y: CGFloat.random(in: 100...700)
            )
        }
    }()
    
    private var biometricIcon: String {
        switch authManager.biometricType {
        case "Face ID":
            return "faceid"
        case "Touch ID":
            return "touchid"
        default:
            return "lock.shield.fill"
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                AppTheme.backgroundGradient(for: selectedTheme, colorScheme: colorScheme)
                    .ignoresSafeArea()
                
                // Floating security particles
                ForEach(Array(particleData.enumerated()), id: \.offset) { index, particle in
                    Image(systemName: particle.icon)
                        .font(.system(size: particle.size))
                        .foregroundColor(.white.opacity(0.08))
                        .position(x: particle.x, y: particle.y)
                        .opacity(particlesOpacity)
                        .animation(
                            .easeInOut(duration: Double.random(in: 3...5))
                            .repeatForever(autoreverses: true)
                            .delay(Double(index) * 0.2),
                            value: particlesOpacity
                        )
                }
                
                VStack(spacing: 0) {
                    Spacer()
                    
                    // Enhanced Icon with animations
                    ZStack {
                    // Pulsing rings
                    ForEach(0..<3) { index in
                        Circle()
                            .stroke(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        AppTheme.accentColor(for: selectedTheme).opacity(0.4),
                                        AppTheme.accentColor(for: selectedTheme).opacity(0.0)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2
                            )
                            .frame(width: 140 + CGFloat(index * 30), height: 140 + CGFloat(index * 30))
                            .scaleEffect(iconScale + CGFloat(index) * 0.1)
                            .opacity(1.0 - Double(index) * 0.3)
                            .animation(
                                .easeInOut(duration: 2.0)
                                .repeatForever(autoreverses: true)
                                .delay(Double(index) * 0.3),
                                value: iconScale
                            )
                    }
                    
                    // Background glow
                    Circle()
                        .fill(
                            RadialGradient(
                                gradient: Gradient(colors: [
                                    AppTheme.accentColor(for: selectedTheme).opacity(0.4),
                                    AppTheme.accentColor(for: selectedTheme).opacity(0.2),
                                    Color.clear
                                ]),
                                center: .center,
                                startRadius: 0,
                                endRadius: 100
                            )
                        )
                        .frame(width: 200, height: 200)
                        .blur(radius: 20)
                    
                    // Main circle
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    AppTheme.accentColor(for: selectedTheme).opacity(0.3),
                                    AppTheme.accentColor(for: selectedTheme).opacity(0.2)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 140, height: 140)
                        .overlay(
                            Circle()
                                .stroke(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color.white.opacity(0.4),
                                            Color.white.opacity(0.2)
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 2
                                )
                        )
                        .shadow(color: AppTheme.accentColor(for: selectedTheme).opacity(0.3), radius: 20, x: 0, y: 10)
                    
                    // Icon
                    Image(systemName: biometricIcon)
                        .font(.system(size: 65, weight: .medium))
                        .foregroundStyle(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    AppTheme.accentColor(for: selectedTheme),
                                    AppTheme.accentColor(for: selectedTheme).opacity(0.8)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: .black.opacity(0.2), radius: 5, x: 0, y: 2)
                        .scaleEffect(iconScale)
                        .rotationEffect(.degrees(iconRotation))
                }
                .frame(height: 200)
                .padding(.bottom, 50)
                .opacity(contentOpacity)
                
                // Title and Description with enhanced styling
                VStack(spacing: 24) {
                    Text("Secure Your Account")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    .white,
                                    .white.opacity(0.95)
                                ]),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .multilineTextAlignment(.center)
                        .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
                    
                    VStack(spacing: 16) {
                        Text("Enable \(authManager.biometricType) for quick and secure access")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.white.opacity(0.9))
                            .multilineTextAlignment(.center)
                            .lineSpacing(4)
                        
                        // Benefits list
                        VStack(spacing: 12) {
                            BenefitRow(icon: "bolt.fill", text: "Sign in instantly")
                            BenefitRow(icon: "lock.shield.fill", text: "Enhanced security")
                            BenefitRow(icon: "hand.raised.fill", text: "No passwords needed")
                        }
                        .padding(.top, 8)
                    }
                }
                .padding(.horizontal, 36)
                .opacity(contentOpacity)
                
                Spacer()
                
                // Enhanced Buttons
                VStack(spacing: 16) {
                    // Enable Button
                    Button(action: enableBiometrics) {
                        HStack(spacing: 12) {
                            if isEnabling {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Image(systemName: biometricIcon)
                                    .font(.system(size: 20, weight: .semibold))
                                Text("Enable \(authManager.biometricType)")
                                    .font(.system(size: 18, weight: .bold))
                            }
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 58)
                        .background(
                            ZStack {
                                RoundedRectangle(cornerRadius: 16)
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
                                
                                // Shimmer effect
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(
                                        LinearGradient(
                                            gradient: Gradient(colors: [
                                                Color.clear,
                                                Color.white.opacity(0.3),
                                                Color.clear
                                            ]),
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .offset(x: shimmerOffset)
                            }
                        )
                        .shadow(color: AppTheme.accentColor(for: selectedTheme).opacity(0.5), radius: 20, x: 0, y: 10)
                    }
                    .disabled(isEnabling)
                    .opacity(isEnabling ? 0.7 : 1.0)
                    
                    // Skip Button
                    Button(action: skipSetup) {
                        Text("Maybe Later")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white.opacity(0.85))
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.white.opacity(0.15))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                    )
                            )
                    }
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 50)
                    .opacity(contentOpacity)
                }
            }
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
        .onAppear {
            // Animated entrance
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                iconScale = 1.0
                contentOpacity = 1.0
            }
            
            withAnimation(.easeInOut(duration: 0.8).delay(0.3)) {
                particlesOpacity = 1.0
            }
            
            // Continuous shimmer effect
            withAnimation(.linear(duration: 2.5).repeatForever(autoreverses: false)) {
                shimmerOffset = 400
            }
        }
    }
    
    private func enableBiometrics() {
        isEnabling = true
        HapticManager.shared.light()
        
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            iconScale = 1.1
            iconRotation = 360
        }
        
        Task {
            do {
                // Test biometric authentication
                try await authManager.authenticateWithBiometrics()
                
                // If successful, enable it
                await MainActor.run {
                    biometricsEnabled = true
                    HapticManager.shared.success()
                    
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                        iconScale = 1.2
                    }
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        dismiss()
                    }
                }
            } catch {
                await MainActor.run {
                    isEnabling = false
                    errorMessage = error.localizedDescription
                    showError = true
                    HapticManager.shared.error()
                    
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                        iconScale = 1.0
                        iconRotation = 0
                    }
                }
            }
        }
    }
    
    private func skipSetup() {
        HapticManager.shared.light()
        withAnimation(.easeOut(duration: 0.3)) {
            contentOpacity = 0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            dismiss()
        }
    }
}

// Helper view for benefit rows
struct BenefitRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white.opacity(0.9))
                .frame(width: 24)
            
            Text(text)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.white.opacity(0.85))
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

#Preview {
    BiometricSetupView()
}
