import SwiftUI

struct EmailConfirmationSplashView: View {
    @Environment(\.appTheme) var appTheme
    @Environment(\.colorScheme) var colorScheme
    @State private var scale: CGFloat = 0.8
    @State private var opacity: Double = 0
    let email: String
    let onContinue: () -> Void
    
    var body: some View {
        GeometryReader { geometry in
            let spacing = AdaptiveSpacing(geometry: geometry)
            
            ZStack {
                AppTheme.backgroundGradient(for: appTheme, colorScheme: colorScheme)
                    .ignoresSafeArea()
                
                VStack(spacing: spacing.screenEdge + spacing.lg) {
                    Spacer()
                    
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(AppTheme.shadowLightOpacity))
                            .frame(width: spacing.imageMedium, height: spacing.imageMedium)
                            .scaleEffect(scale)
                        
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: AppTheme.fontSize50))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.green, .mint],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .scaleEffect(scale)
                            .opacity(opacity)
                    }
                    
                    VStack(spacing: spacing.lg) {
                        Text("Account Created!")
                            .font(.system(size: AppTheme.fontSize28, weight: .bold))
                            .adaptiveForegroundColor()
                            .multilineTextAlignment(.center)
                            .opacity(opacity)
                        
                        VStack(spacing: spacing.sm) {
                            Text("You're all set.")
                                .font(.system(size: AppTheme.fontSize16))
                                .adaptiveForegroundColor(opacity: AppTheme.veryHighEmphasisOpacity)
                                .multilineTextAlignment(.center)
                            
                            Text(email)
                                .font(.system(size: AppTheme.fontSize16, weight: .semibold))
                                .adaptiveForegroundColor()
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, spacing.screenEdge + spacing.lg)
                        }
                        .opacity(opacity)
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        HapticManager.shared.medium()
                        onContinue()
                    }) {
                        HStack(spacing: spacing.md) {
                            Image(systemName: "arrow.right.circle.fill")
                            Text("Continue to Sign In")
                                .fontWeight(.semibold)
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
        }
    }
}

#Preview {
    EmailConfirmationSplashView(email: "user@example.com", onContinue: {})
        .environment(\.appTheme, .teal)
}
