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
        ZStack {
            AppTheme.backgroundGradient(for: appTheme, colorScheme: colorScheme)
                .ignoresSafeArea()
            
            VStack(spacing: 32) {
                Spacer()
                
                // Email Icon
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.1))
                        .frame(width: 120, height: 120)
                        .scaleEffect(scale)
                    
                    Image(systemName: "envelope.fill")
                        .font(.system(size: 50))
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
                
                VStack(spacing: 16) {
                    Text("Check Your Email")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .opacity(opacity)
                    
                    VStack(spacing: 8) {
                        Text("We've sent a confirmation link to:")
                            .font(.system(size: 16))
                            .foregroundColor(.white.opacity(0.9))
                            .multilineTextAlignment(.center)
                        
                        Text(email)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }
                    .opacity(opacity)
                    
                    Text("📧 For testing purposes, email confirmation is simulated. In production, you'd receive a real email.")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                        .padding(.top, 8)
                        .opacity(opacity)
                }
                
                Spacer()
                
                // Continue Button
                Button(action: {
                    HapticManager.shared.medium()
                    onContinue()
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: "arrow.right.circle.fill")
                        Text("Continue to Sign In")
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.white.opacity(0.2))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.white.opacity(0.4), lineWidth: 1.5)
                            )
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
