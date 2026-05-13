import SwiftUI

struct PasswordReminderSplashView: View {
    @AppStorage("appTheme") private var selectedTheme: AppTheme.ThemeType = .teal
    @Environment(\.colorScheme) var colorScheme
    @State private var scale: CGFloat = 0.8
    @State private var opacity: Double = 0
    @State private var keyRotation: Double = 0
    let email: String
    let onContinue: () -> Void
    
    var body: some View {
        GeometryReader { geometry in
            let spacing = AdaptiveSpacing(geometry: geometry)
            
            ZStack {
                AppTheme.backgroundGradient(for: selectedTheme, colorScheme: colorScheme)
                    .ignoresSafeArea()
                
                VStack(spacing: spacing.screenEdge + spacing.lg) {
                    Spacer()
                    
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(AppTheme.shadowLightOpacity))
                            .frame(width: spacing.imageMedium + spacing.xl, height: spacing.imageMedium + spacing.xl)
                            .scaleEffect(scale)
                        
                        Image(systemName: "key.fill")
                            .font(.system(size: AppTheme.fontSize50))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.yellow, .orange],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .rotationEffect(.degrees(keyRotation))
                            .opacity(opacity)
                    }
                    
                    VStack(spacing: spacing.lg) {
                        Text("Remember Your Password!")
                            .font(.system(size: AppTheme.fontSize28, weight: .bold))
                            .adaptiveForegroundColor()
                            .multilineTextAlignment(.center)
                            .opacity(opacity)
                        
                        VStack(spacing: spacing.md) {
                            HStack(spacing: spacing.md) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                    .font(.system(size: spacing.iconMedium))
                                
                                VStack(alignment: .leading, spacing: spacing.xxs) {
                                Text("Account Created!")
                                    .font(.system(size: AppTheme.fontSize17, weight: .semibold))
                                    .adaptiveForegroundColor()
                                
                                Text(email)
                                    .font(.system(size: AppTheme.fontSize15))
                                    .adaptiveForegroundColor(opacity: AppTheme.highEmphasisOpacity)
                            }
                                
                                Spacer()
                            }
                            .padding(spacing.lg)
                            .background(
                                RoundedRectangle(cornerRadius: spacing.md)
                                    .fill(Color.white.opacity(AppTheme.shadowLightOpacity))
                            )
                            
                            VStack(alignment: .leading, spacing: spacing.md) {
                                HStack(spacing: spacing.sm + 2) {
                                    Image(systemName: "lock.icloud.fill")
                                        .foregroundColor(.blue)
                                        .font(.system(size: spacing.xl))
                                    
                                    Text("Use iOS Password Manager")
                                        .font(.system(size: AppTheme.fontSize16, weight: .medium))
                                        .adaptiveForegroundColor()
                                }
                                
                                Text("Your password is saved in iCloud Keychain and will auto-fill when you sign in.")
                                    .font(.system(size: AppTheme.fontSize14))
                                    .adaptiveForegroundColor(opacity: AppTheme.highEmphasisOpacity)
                                    .lineSpacing(2)
                            }
                            .padding(spacing.lg)
                            .background(
                                RoundedRectangle(cornerRadius: spacing.md)
                                    .fill(Color.blue.opacity(AppTheme.overlayLightOpacity))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: spacing.md)
                                            .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                                    )
                            )
                            
                            HStack(spacing: spacing.sm + 2) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                                
                                Text("You'll need to sign in each time you log out")
                                    .font(.system(size: AppTheme.fontSize14))
                                    .adaptiveForegroundColor(opacity: AppTheme.veryHighEmphasisOpacity)
                            }
                            .padding(spacing.md)
                            .background(
                                RoundedRectangle(cornerRadius: spacing.sm)
                                    .fill(Color.orange.opacity(AppTheme.cardDarkOpacity))
                            )
                        }
                        .opacity(opacity)
                        .padding(.horizontal, spacing.screenEdge + spacing.lg)
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        HapticManager.shared.medium()
                        onContinue()
                    }) {
                        HStack(spacing: spacing.md) {
                            Text("Got it, let's sign in!")
                                .fontWeight(.semibold)
                            Image(systemName: "arrow.right.circle.fill")
                        }
                        .adaptiveForegroundColor()
                        .frame(maxWidth: .infinity)
                        .frame(height: spacing.buttonHeight)
                        .background(
                            RoundedRectangle(cornerRadius: spacing.lg)
                                .fill(Color.white.opacity(AppTheme.overlayLightOpacity))
                                .overlay(
                                    RoundedRectangle(cornerRadius: spacing.lg)
                                        .stroke(Color.white.opacity(0.4), lineWidth: 1.5)
                                )
                        )
                    }
                    .padding(.horizontal, spacing.screenEdge + spacing.lg)
                    .padding(.bottom, spacing.xxl + spacing.xl)
                    .opacity(opacity)
                }
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                scale = 1.0
            }
            withAnimation(.easeOut(duration: AppTheme.animationDelayMedium)) {
                opacity = 1.0
            }
            withAnimation(.easeInOut(duration: AppTheme.animationDuration08).repeatForever(autoreverses: true)) {
                keyRotation = -15
            }
        }
    }
}

#Preview {
    PasswordReminderSplashView(email: "user@example.com", onContinue: {})
}
