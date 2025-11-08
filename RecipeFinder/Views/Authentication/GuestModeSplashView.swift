import SwiftUI

struct GuestModeSplashView: View {
    @Environment(\.appTheme) var appTheme
    @Environment(\.colorScheme) var colorScheme
    @State private var scale: CGFloat = 0.8
    @State private var opacity: Double = 0
    let onContinue: () -> Void
    
    var body: some View {
        GeometryReader { geometry in
            let spacing = AdaptiveSpacing(geometry: geometry)
            
            ZStack {
                AppTheme.backgroundGradient(for: appTheme, colorScheme: colorScheme)
                    .ignoresSafeArea()
                
                VStack(spacing: spacing.screenEdge + spacing.lg) {
                    Spacer()
                    
                    // Construction Icon
                    Image(systemName: "hammer.fill")
                        .font(.system(size: 80))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.yellow, .orange],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .scaleEffect(scale)
                        .opacity(opacity)
                    
                    VStack(spacing: spacing.lg) {
                        Text("Profile Under Construction")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .opacity(opacity)
                        
                        Text("We're building something amazing! 🚧\n\nCheck back in a couple of weeks to see your personalized profile and stats.")
                            .font(.system(size: 17))
                            .foregroundColor(.white.opacity(0.9))
                            .multilineTextAlignment(.center)
                            .lineSpacing(4)
                            .opacity(opacity)
                            .padding(.horizontal, spacing.screenEdge + spacing.lg)
                    }
                    
                    Spacer()
                    
                    // Continue Button
                    Button(action: {
                        HapticManager.shared.medium()
                        onContinue()
                    }) {
                        HStack {
                            Text("Got it!")
                                .fontWeight(.semibold)
                            Image(systemName: "arrow.right.circle.fill")
                        }
                        .foregroundColor(.white)
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
            }
            withAnimation(.easeOut(duration: 0.5)) {
                opacity = 1.0
            }
        }
    }
}

#Preview {
    GuestModeSplashView(onContinue: {})
        .environment(\.appTheme, .teal)
}
