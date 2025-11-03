import SwiftUI

struct WelcomeSplashView: View {
    @Environment(\.appTheme) var appTheme
    @Environment(\.colorScheme) var colorScheme
    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 0
    @State private var checkmarkScale: CGFloat = 0
    @State private var contentOpacity: Double = 0
    let email: String
    let onContinue: () -> Void
    
    var body: some View {
        ZStack {
            AppTheme.backgroundGradient(for: appTheme, colorScheme: colorScheme)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                Spacer()
                
                // Success Icon - Apple style
                ZStack {
                    // Background circle with subtle pulsing
                    Circle()
                        .fill(Color.white.opacity(0.15))
                        .frame(width: 100, height: 100)
                        .scaleEffect(scale)
                    
                    // Checkmark
                    Image(systemName: "checkmark")
                        .font(.system(size: 50, weight: .semibold))
                        .foregroundColor(.white)
                        .scaleEffect(checkmarkScale)
                }
                .padding(.bottom, 40)
                
                // Welcome Message - Clean and minimal
                VStack(spacing: 16) {
                    Text("Welcome to RecipeFinder")
                        .font(.system(size: 34, weight: .bold, design: .default))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .opacity(contentOpacity)
                    
                    Text("Your account has been created")
                        .font(.system(size: 19, weight: .regular))
                        .foregroundColor(.white.opacity(0.85))
                        .multilineTextAlignment(.center)
                        .opacity(contentOpacity)
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 24)
                
                // Email confirmation - Subtle
                Text(email)
                    .font(.system(size: 17, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(
                        Capsule()
                            .fill(Color.white.opacity(0.12))
                    )
                    .opacity(contentOpacity)
                
                Spacer()
                Spacer()
                
                // Sign In Button - Prominent
                Button(action: {
                    HapticManager.shared.light()
                    onContinue()
                }) {
                    Text("Sign In")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(AppTheme.accentColor(for: appTheme))
                        )
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 50)
                .opacity(contentOpacity)
            }
        }
        .onAppear {
            // Smooth entrance animation sequence
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                scale = 1.0
            }
            
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6).delay(0.15)) {
                checkmarkScale = 1.0
                opacity = 1.0
            }
            
            withAnimation(.easeOut(duration: 0.6).delay(0.3)) {
                contentOpacity = 1.0
            }
        }
    }
}

#Preview {
    WelcomeSplashView(email: "user@example.com", onContinue: {})
        .environment(\.appTheme, .teal)
}
