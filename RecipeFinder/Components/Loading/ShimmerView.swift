//
//  ShimmerView.swift
//  RecipeFinder
//
//  Reusable shimmer effect for loading states
//

import SwiftUI

// MARK: - Shimmer Modifier

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
                    .rotationEffect(.degrees(30))
                    .offset(x: phase)
                    .clipped()
            )
            .onAppear {
                withAnimation(
                    .linear(duration: 1.5)
                    .repeatForever(autoreverses: false)
                ) {
                    phase = 400
                }
            }
    }
}

extension View {
    func shimmer() -> some View {
        self.modifier(ShimmerModifier())
    }
}

// MARK: - Skeleton Shapes

struct SkeletonRectangle: View {
    let cornerRadius: CGFloat
    
    init(cornerRadius: CGFloat = 8) {
        self.cornerRadius = cornerRadius
    }
    
    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(Color.gray.opacity(0.3))
            .shimmer()
    }
}

struct SkeletonCircle: View {
    var body: some View {
        Circle()
            .fill(Color.gray.opacity(0.3))
            .shimmer()
    }
}

struct SkeletonCapsule: View {
    var body: some View {
        Capsule()
            .fill(Color.gray.opacity(0.3))
            .shimmer()
    }
}

// MARK: - Common Loading Skeletons

struct RecipeCardSkeleton: View {
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacingMD) {
            // Image placeholder
            SkeletonRectangle(cornerRadius: 12)
                .frame(height: 180)
            
            VStack(alignment: .leading, spacing: AppTheme.spacingSM) {
                // Title
                SkeletonRectangle(cornerRadius: 6)
                    .frame(height: 20)
                    .frame(maxWidth: .infinity)
                
                // Subtitle
                SkeletonRectangle(cornerRadius: 6)
                    .frame(width: 150, height: 14)
                
                // Tags
                HStack(spacing: AppTheme.spacingSM) {
                    SkeletonCapsule()
                        .frame(width: 60, height: 24)
                    SkeletonCapsule()
                        .frame(width: 80, height: 24)
                }
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 12)
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(AppTheme.adaptiveCard(for: colorScheme))
        )
    }
}

struct RecipeDetailSkeleton: View {
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(spacing: AppTheme.spacingXL) {
            // Header
            VStack(spacing: AppTheme.spacingMD) {
                SkeletonRectangle(cornerRadius: 8)
                    .frame(height: 28)
                    .frame(maxWidth: 250)
                
                SkeletonRectangle(cornerRadius: 6)
                    .frame(height: 16)
                    .frame(maxWidth: 180)
            }
            .padding(.top, 20)
            
            // Info cards
            HStack(spacing: AppTheme.spacingMD) {
                ForEach(0..<3) { _ in
                    VStack(spacing: AppTheme.spacingSM) {
                        SkeletonCircle()
                            .frame(width: 40, height: 40)
                        SkeletonRectangle(cornerRadius: 4)
                            .frame(height: 14)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(AppTheme.adaptiveCard(for: colorScheme))
                    )
                }
            }
            .padding(.horizontal, 20)
            
            // Sections
            ForEach(0..<2) { _ in
                VStack(alignment: .leading, spacing: AppTheme.spacingMD) {
                    SkeletonRectangle(cornerRadius: 6)
                        .frame(width: 120, height: 20)
                    
                    ForEach(0..<3) { _ in
                        SkeletonRectangle(cornerRadius: 8)
                            .frame(height: 50)
                    }
                }
                .padding(AppTheme.spacingLG)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(AppTheme.adaptiveCard(for: colorScheme))
                )
                .padding(.horizontal, 20)
            }
            
            Spacer()
        }
    }
}

struct ListItemSkeleton: View {
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack(spacing: AppTheme.spacingMD) {
            SkeletonCircle()
                .frame(width: 40, height: 40)
            
            VStack(alignment: .leading, spacing: AppTheme.spacing6) {
                SkeletonRectangle(cornerRadius: 4)
                    .frame(height: 16)
                    .frame(maxWidth: .infinity)
                
                SkeletonRectangle(cornerRadius: 4)
                    .frame(width: 100, height: 12)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(AppTheme.adaptiveCard(for: colorScheme))
        )
    }
}

// MARK: - Loading State View

struct LoadingStateView: View {
    let message: String
    let progress: Double?
    @AppStorage("appTheme") private var selectedTheme: AppTheme.ThemeType = .teal
    
    init(message: String, progress: Double? = nil) {
        self.message = message
        self.progress = progress
    }
    
    var body: some View {
        VStack(spacing: AppTheme.spacingXL) {
            // Animated spinner
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: AppTheme.accentColor(for: selectedTheme)))
                .scaleEffect(1.5)
            
            // Message
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            // Progress bar if available
            if let progress = progress {
                VStack(spacing: AppTheme.spacingSM) {
                    ProgressView(value: progress, total: 1.0)
                        .progressViewStyle(LinearProgressViewStyle(tint: AppTheme.accentColor(for: selectedTheme)))
                        .frame(width: 200)
                    
                    Text("\(Int(progress * 100))%")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(AppTheme.spacing4XL)
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: AppTheme.spacingXL) {
        RecipeCardSkeleton()
            .padding()
        
        ListItemSkeleton()
            .padding()
        
        LoadingStateView(message: "Loading recipes...", progress: 0.6)
    }
    .background(Color.gray.opacity(0.1))
}
