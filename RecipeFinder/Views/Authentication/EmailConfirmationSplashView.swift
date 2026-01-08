import SwiftUI

struct EmailConfirmationSplashView: View {
    @Environment(\.appTheme) var appTheme
    @Environment(\.colorScheme) var colorScheme
    @State private var scale: CGFloat = 0.8
    @State private var opacity: Double = 0
    @State private var envelopeOffset: CGFloat = -20
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
                    
                    // Email Icon
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.1))
                            .frame(width: spacing.imageMedium, height: spacing.imageMedium)
                            .scaleEffect(scale)
                        
                        Image(systemName: "envelope.fill")
                            .font(.system(size: AppTheme.fontSizeEmoji))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.blue, .cyan],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .offset(y: envelopeOffset)
                            .opacity(opacity)
                        
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 30))
                            .foregroundColor(.green)
                            .background(Circle().fill(Color.white))
                            .offset(x: 35, y: 35)
                            .scaleEffect(scale)
                    }
                    
                    VStack(spacing: spacing.lg) {
                        Text("Check Your Email")
                            .font(.system(size: AppTheme.fontSizeTitle1, weight: .bold))
                            .adaptiveForegroundColor()
                            .multilineTextAlignment(.center)
                            .opacity(opacity)
                        
                        VStack(spacing: spacing.sm) {
                            Text("We've sent a confirmation link to:")
                                .font(.system(size: AppTheme.fontSizeBody))
                                .adaptiveForegroundColor(opacity: 0.9)
                                .multilineTextAlignment(.center)
                            
                            Text(email)
                                .font(.system(size: AppTheme.fontSizeBody, weight: .semibold))
                                .adaptiveForegroundColor()
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, spacing.screenEdge + spacing.lg)
                        }
                        .opacity(opacity)
                        
                        Text("📧 For testing purposes, email confirmation is simulated. In production, you'd receive a real email.")
                            .font(.system(size: AppTheme.fontSizeSubheadline))
                            .adaptiveForegroundColor(opacity: 0.7)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, spacing.xxl + spacing.xl)
                            .padding(.top, spacing.sm)
                            .opacity(opacity)
                    }
                    
                    Spacer()
                    
                    // Continue Button
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
                                .fill(Color.white.opacity(0.2))
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
                envelopeOffset = 0
            }
            withAnimation(.easeOut(duration: 0.5)) {
                opacity = 1.0
            }
        }
    }
}

#Preview {
    EmailConfirmationSplashView(email: "user@example.com", onContinue: {})
        .environment(\.appTheme, .teal)
}
