import SwiftUI
import Kingfisher

struct MealTimeCard: View {
    let mealTime: MealTime
    let recipe: RecipeModel?
    let cardStyle: CardStyle
    let colorScheme: ColorScheme
    var onRemove: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: AppTheme.spacing16) {
            MealThumbnail(
                imageName: recipe?.imageName ?? "",
                fallbackIcon: mealTime.icon,
                colorScheme: colorScheme
            )

            VStack(alignment: .leading, spacing: AppTheme.spacing6) {
                Text(mealTime.rawValue)
                    .font(.system(size: AppTheme.fontSize18, weight: .semibold))
                    .adaptiveForegroundColor()

                HStack(spacing: AppTheme.spacing4) {
                    Image(systemName: "clock")
                        .font(.caption2)
                    Text(mealTime.timeRange)
                        .font(.caption)
                }
                .foregroundColor(AppTheme.adaptiveMediumEmphasis(for: colorScheme))

                if let recipe = recipe {
                    HStack(spacing: AppTheme.spacing6) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption2)
                            .foregroundColor(.green)
                        Text(recipe.name)
                            .font(.caption)
                            .lineLimit(1)
                    }
                    .adaptiveForegroundColor(opacity: AppTheme.veryHighEmphasisOpacity)
                } else {
                    HStack(spacing: AppTheme.spacing6) {
                        Image(systemName: "fork.knife")
                            .font(.caption2)
                        Text("Tap to add recipe")
                            .font(.caption)
                    }
                    .adaptiveForegroundColor(opacity: AppTheme.glassLightOpacity)
                }
            }

            Spacer()

            HStack(spacing: AppTheme.spacing8) {
                if let onRemove, recipe != nil {
                    Button(action: onRemove) {
                        Image(systemName: "trash")
                            .font(.system(size: AppTheme.fontSize14, weight: .semibold))
                            .foregroundColor(.red.opacity(0.7))
                    }
                    .buttonStyle(.plain)
                }
                if recipe == nil {
                    Image(systemName: "chevron.right")
                        .font(.system(size: AppTheme.fontSize14, weight: .semibold))
                        .adaptiveForegroundColor(opacity: AppTheme.lowEmphasisOpacity)
                }
            }
        }
        .padding(AppTheme.spacing16)
        .background {
            if cardStyle == .solid {
                RoundedRectangle(cornerRadius: AppTheme.cornerRadius16)
                    .fill(colorScheme == .dark
                        ? Color.white.opacity(AppTheme.glassSubtleOpacity)
                        : Color.white.opacity(AppTheme.cardDarkOpacity))
            } else {
                RoundedRectangle(cornerRadius: AppTheme.cornerRadius16)
                    .fill(.ultraThinMaterial)
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.cornerRadius16)
                .stroke(recipe != nil ? AppTheme.success.opacity(0.3) : Color.white.opacity(0.1), lineWidth: 1)
        )
    }
}

/// 52×52 recipe photo thumbnail with a meal-time icon circle as fallback.
/// Resolves HTTP URLs and local file paths via Kingfisher; named assets via UIImage.
/// When no valid image is available the original icon circle is shown instead.
private struct MealThumbnail: View {
    let imageName: String
    let fallbackIcon: String
    let colorScheme: ColorScheme

    private static let size: CGFloat = 52
    @State private var loadFailed = false

    private var kfSource: Source? {
        guard !imageName.isEmpty else { return nil }
        if imageName.hasPrefix("http"), let url = URL(string: imageName) {
            return .network(url)
        }
        if imageName.hasPrefix("/") {
            return .provider(LocalFileImageDataProvider(fileURL: URL(fileURLWithPath: imageName)))
        }
        return nil
    }

    var body: some View {
        if let source = kfSource, !loadFailed {
            KFImage(source: source)
                .onFailure { _ in loadFailed = true }
                .setProcessor(DownsamplingImageProcessor(size: CGSize(
                    width: Self.size * UIScreen.main.scale,
                    height: Self.size * UIScreen.main.scale
                )))
                .scaleFactor(UIScreen.main.scale)
                .cacheOriginalImage()
                .resizable()
                .scaledToFill()
                .frame(width: Self.size, height: Self.size)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius12))
        } else if !imageName.isEmpty, let uiImage = UIImage(named: imageName) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
                .frame(width: Self.size, height: Self.size)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius12))
        } else {
            ZStack {
                Circle()
                    .fill(colorScheme == .dark
                        ? Color.white.opacity(AppTheme.cardDarkOpacity)
                        : Color.black.opacity(AppTheme.cardDarkOpacity))
                Image(systemName: fallbackIcon)
                    .font(.system(size: AppTheme.fontSize22, weight: .semibold))
                    .foregroundColor(colorScheme == .dark
                        ? .white.opacity(AppTheme.cardLightOpacity)
                        : .black.opacity(0.9))
            }
            .frame(width: Self.size, height: Self.size)
        }
    }
}
