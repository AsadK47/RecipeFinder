import SwiftUI

/// Shown while the recipe library loads after sign-in: real card chrome filled
/// with dimmed shimmering shapes, so the wait reads as "content is coming"
/// rather than an empty library (which would otherwise flash the empty state).
/// Non-interactive and hidden from VoiceOver.
struct RecipeListSkeleton: View {
    private let placeholderCount = 6

    var body: some View {
        ScrollView {
            LazyVStack(spacing: AppTheme.cardVerticalSpacing) {
                ForEach(0..<placeholderCount, id: \.self) { _ in
                    RecipeCardSkeleton()
                }
            }
            .padding(.horizontal, AppTheme.cardHorizontalPadding)
            .padding(.bottom, AppTheme.cardHorizontalPadding)
        }
        .scrollDisabled(true)
        .accessibilityHidden(true)
    }
}

/// One skeleton row mirroring `RecipeCard`'s list layout: a square image block
/// plus a title bar and a shorter metadata bar.
private struct RecipeCardSkeleton: View {
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("cardStyle") private var cardStyle: CardStyle = .frosted

    var body: some View {
        HStack(spacing: AppTheme.cardVerticalSpacing) {
            RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius * AppTheme.goldenRatioInverse)
                .fill(blockColor)
                .frame(width: AppTheme.cardImageSize, height: AppTheme.cardImageSize)

            VStack(alignment: .leading, spacing: AppTheme.spacing10) {
                RoundedRectangle(cornerRadius: AppTheme.cornerRadius4)
                    .fill(blockColor)
                    .frame(height: AppTheme.fontSize16)
                    .frame(maxWidth: .infinity, alignment: .leading)

                RoundedRectangle(cornerRadius: AppTheme.cornerRadius4)
                    .fill(blockColor)
                    .frame(width: AppTheme.cardImageSize * 1.6, height: AppTheme.fontSize13)
            }

            Spacer(minLength: 0)
        }
        .padding(AppTheme.spacing16)
        .background { cardBackground }
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius))
        .shimmering()
    }

    private var blockColor: Color {
        Color.primary.opacity(colorScheme == .dark ? 0.14 : 0.10)
    }

    @ViewBuilder
    private var cardBackground: some View {
        if cardStyle == .solid {
            RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius)
                .fill(AppTheme.cardBackground(for: colorScheme))
        } else {
            RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius)
                .fill(.ultraThinMaterial)
        }
    }
}
