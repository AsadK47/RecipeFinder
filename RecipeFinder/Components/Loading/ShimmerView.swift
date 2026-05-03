
import SwiftUI

struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = 0
    
    func body(content: Content) -> some View {
        content
            .overlay(
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [
                                .clear,
                                .white.opacity(AppTheme.lowEmphasisOpacity),
                                .clear
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .rotationEffect(.degrees(AppTheme.shimmerRotation))
                    .offset(x: phase)
                    .clipped()
            )
            .onAppear {
                withAnimation(
                    .linear(duration: AppTheme.shimmerDuration)
                    .repeatForever(autoreverses: false)
                ) {
                    phase = AppTheme.shimmerPhaseDistance
                }
            }
    }
}

extension View {
    func shimmer() -> some View {
        self.modifier(ShimmerModifier())
    }
}

struct SkeletonRectangle: View {
    let cornerRadius: CGFloat
    
    init(cornerRadius: CGFloat = AppTheme.cornerRadius8) {
        self.cornerRadius = cornerRadius
    }
    
    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(Color.gray.opacity(AppTheme.shimmerOpacity))
            .shimmer()
    }
}

struct SkeletonCircle: View {
    var body: some View {
        Circle()
            .fill(Color.gray.opacity(AppTheme.shimmerOpacity))
            .shimmer()
    }
}

struct SkeletonCapsule: View {
    var body: some View {
        Capsule()
            .fill(Color.gray.opacity(AppTheme.shimmerOpacity))
            .shimmer()
    }
}

struct RecipeCardSkeleton: View {
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacing12) {
            SkeletonRectangle(cornerRadius: AppTheme.cornerRadius12)
                .frame(height: AppTheme.height180)
            
            VStack(alignment: .leading, spacing: AppTheme.spacing8) {
                SkeletonRectangle(cornerRadius: AppTheme.cornerRadius6)
                    .frame(height: AppTheme.height20)
                    .frame(maxWidth: .infinity)
                
                SkeletonRectangle(cornerRadius: AppTheme.cornerRadius6)
                    .frame(width: AppTheme.width150, height: AppTheme.height14)
                
                HStack(spacing: AppTheme.spacing8) {
                    SkeletonCapsule()
                        .frame(width: AppTheme.width60, height: AppTheme.height24)
                    SkeletonCapsule()
                        .frame(width: AppTheme.width80, height: AppTheme.height24)
                }
            }
            .padding(.horizontal, AppTheme.spacing12)
            .padding(.bottom, AppTheme.spacing12)
        }
        .background(
            RoundedRectangle(cornerRadius: AppTheme.cornerRadius16)
                .fill(AppTheme.adaptiveCard(for: colorScheme))
        )
    }
}

struct RecipeDetailSkeleton: View {
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(spacing: AppTheme.spacing20) {
            VStack(spacing: AppTheme.spacing12) {
                SkeletonRectangle(cornerRadius: AppTheme.cornerRadius8)
                    .frame(height: AppTheme.height28)
                    .frame(maxWidth: AppTheme.width250)
                
                SkeletonRectangle(cornerRadius: AppTheme.cornerRadius6)
                    .frame(height: AppTheme.height16)
                    .frame(maxWidth: AppTheme.height180)
            }
            .padding(.top, AppTheme.spacing20)
            
            HStack(spacing: AppTheme.spacing12) {
                ForEach(0..<3) { _ in
                    VStack(spacing: AppTheme.spacing8) {
                        SkeletonCircle()
                            .frame(width: AppTheme.iconSize40, height: AppTheme.iconSize40)
                        SkeletonRectangle(cornerRadius: AppTheme.cornerRadius4)
                            .frame(height: AppTheme.height14)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: AppTheme.cornerRadius12)
                            .fill(AppTheme.adaptiveCard(for: colorScheme))
                    )
                }
            }
            .padding(.horizontal, AppTheme.spacing20)
            
            ForEach(0..<2) { _ in
                VStack(alignment: .leading, spacing: AppTheme.spacing12) {
                    SkeletonRectangle(cornerRadius: AppTheme.cornerRadius6)
                        .frame(width: AppTheme.width120, height: AppTheme.height20)
                    
                    ForEach(0..<3) { _ in
                        SkeletonRectangle(cornerRadius: AppTheme.cornerRadius8)
                            .frame(height: AppTheme.height50)
                    }
                }
                .padding(AppTheme.spacing16)
                .background(
                    RoundedRectangle(cornerRadius: AppTheme.cornerRadius12)
                        .fill(AppTheme.adaptiveCard(for: colorScheme))
                )
                .padding(.horizontal, AppTheme.spacing20)
            }
            
            Spacer()
        }
    }
}

struct ListItemSkeleton: View {
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack(spacing: AppTheme.spacing12) {
            SkeletonCircle()
                .frame(width: AppTheme.iconSize40, height: AppTheme.iconSize40)
            
            VStack(alignment: .leading, spacing: AppTheme.spacing6) {
                SkeletonRectangle(cornerRadius: AppTheme.cornerRadius4)
                    .frame(height: AppTheme.height16)
                    .frame(maxWidth: .infinity)
                
                SkeletonRectangle(cornerRadius: AppTheme.cornerRadius4)
                    .frame(width: AppTheme.width100, height: AppTheme.height12)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: AppTheme.cornerRadius12)
                .fill(AppTheme.adaptiveCard(for: colorScheme))
        )
    }
}

struct LoadingStateView: View {
    let message: String
    let progress: Double?
    @AppStorage("appTheme") private var selectedTheme: AppTheme.ThemeType = .teal
    
    init(message: String, progress: Double? = nil) {
        self.message = message
        self.progress = progress
    }
    
    var body: some View {
        VStack(spacing: AppTheme.spacing20) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: AppTheme.accentColor(for: selectedTheme)))
                .scaleEffect(AppTheme.shimmerDuration)
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            if let progress = progress {
                VStack(spacing: AppTheme.spacing8) {
                    ProgressView(value: progress, total: 1.0)
                        .progressViewStyle(LinearProgressViewStyle(tint: AppTheme.accentColor(for: selectedTheme)))
                        .frame(width: AppTheme.width200)
                    
                    Text("\(Int(progress * 100))%")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(AppTheme.spacing40)
    }
}

#Preview {
    VStack(spacing: AppTheme.spacing20) {
        RecipeCardSkeleton()
            .padding()
        
        ListItemSkeleton()
            .padding()
        
        LoadingStateView(message: "Loading recipes...", progress: 0.6)
    }
    .background(Color.gray.opacity(AppTheme.dividerOpacity))
}
