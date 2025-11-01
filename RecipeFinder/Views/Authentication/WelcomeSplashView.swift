import SwiftUI

struct WelcomeSplashView: View {
    @Environment(\.appTheme) var appTheme
    @Environment(\.colorScheme) var colorScheme
    @State private var scale: CGFloat = 0.8
    @State private var opacity: Double = 0
    @State private var iconRotation: Double = 0
    let email: String
    let onContinue: () -> Void
    
    var body: some View {
        ZStack {
            AppTheme.backgroundGradient(for: appTheme, colorScheme: colorScheme)
                .ignoresSafeArea()
            
            VStack(spacing: 32) {
                Spacer()
                
                // App Icon
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.1))
                        .frame(width: 120, height: 120)
                        .scaleEffect(scale)
                    
                    Image(systemName: "fork.knife.circle.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    AppTheme.accentColor(for: appTheme),
                                    AppTheme.accentColor(for: appTheme).opacity(0.7)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .rotationEffect(.degrees(iconRotation))
                        .opacity(opacity)
                    
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 35))
                        .foregroundColor(.green)
                        .background(
                            Circle()
                                .fill(Color.white)
                                .frame(width: 40, height: 40)
                        )
                        .offset(x: 40, y: 40)
                        .scaleEffect(scale)
                }
                
                VStack(spacing: 20) {
                    Text("Thanks for signing up to RecipeFinder!")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .opacity(opacity)
                        .padding(.horizontal, 32)
                    
                    VStack(spacing: 12) {
                        Text("Your one stop shop for all your recipe related needs")
                            .font(.system(size: 17))
                            .foregroundColor(.white.opacity(0.9))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                        
                        VStack(spacing: 8) {
                            Text("Let's get started!")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.white)
                            
                            Text("Sign in to continue :)")
                                .font(.system(size: 16))
                                .foregroundColor(.white.opacity(0.85))
                        }
                        .padding(.top, 8)
                    }
                    .opacity(opacity)
                    
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
                    .opacity(opacity)
                }
                
                Spacer()
                
                // Continue Button
                Button(action: {
                    HapticManager.shared.medium()
                    onContinue()
                }) {
                    HStack(spacing: 12) {
                        Text("Continue to Sign In")
                            .fontWeight(.semibold)
                        Image(systemName: "arrow.right.circle.fill")
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(AppTheme.accentColor(for: appTheme))
                            .shadow(color: AppTheme.accentColor(for: appTheme).opacity(0.4), radius: 10, x: 0, y: 5)
                    )
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 40)
                .opacity(opacity)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                scale = 1.0
                iconRotation = 360
            }
            withAnimation(.easeOut(duration: 0.6).delay(0.1)) {
                opacity = 1.0
            }
        }
    }
}

#Preview {
    WelcomeSplashView(email: "user@example.com", onContinue: {})
        .environment(\.appTheme, .teal)
}
