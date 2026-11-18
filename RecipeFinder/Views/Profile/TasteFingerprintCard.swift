import SwiftUI

/// Me's "Your taste" card: a five-point shape of what the cook actually makes (spicy, comforting, quick, baking,
/// fresh), a one-line headline, and one row per trait that opens the recipes behind it.
struct TasteFingerprintCard: View {
    let fingerprint: TasteFingerprint

    @ScaledMetric(relativeTo: .body) private var shapeSize: CGFloat = 150

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacing12) {
            VStack(alignment: .leading, spacing: AppTheme.spacing2) {
                Label("Your taste", systemImage: "sparkles")
                    .font(.headline)
                    .adaptiveForegroundColor()
                    .accessibilityAddTraits(.isHeader)
                Text(fingerprint.headline)
                    .font(.subheadline.weight(.semibold))
                    .adaptiveSecondaryForeground()
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier("taste.headline")
            }

            TasteShape(shares: fingerprint.shares)
                .frame(width: shapeSize, height: shapeSize)
                .frame(maxWidth: .infinity)
                // The rows below say the same thing in words; the shape is for the eye.
                .accessibilityHidden(true)

            VStack(spacing: AppTheme.spacing8) {
                ForEach(fingerprint.shares) { share in
                    if share.cooks > 0 {
                        NavigationLink(value: share.trait) {
                            TasteRow(share: share, opensRecipes: true)
                        }
                        .buttonStyle(.plain)
                        .tasteRowAccessibility(share)
                        .accessibilityAddTraits(.isButton)
                        .accessibilityHint("Shows the recipes behind it")
                    } else {
                        TasteRow(share: share, opensRecipes: false)
                            .tasteRowAccessibility(share)
                    }
                }
            }
        }
        .padding(AppTheme.spacing16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .appCard(cornerRadius: AppTheme.cornerRadius16)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("taste.card")
    }
}

extension TasteTrait {
    /// Icon and bar colour — on icons and fills only, never on text (DesignSystem: accent text vanishes on glass).
    var tint: Color {
        switch self {
        case .spicy: AppTheme.redOrange
        case .comforting: AppTheme.orangeWarm
        case .quick: AppTheme.yellowAmber
        case .baking: AppTheme.pinkHot
        case .fresh: AppTheme.greenVibrant
        }
    }
}

/// One trait: icon, name, a bar for its share and "40%".
private struct TasteRow: View {
    let share: TasteShare
    let opensRecipes: Bool

    var body: some View {
        HStack(spacing: AppTheme.spacing12) {
            IconBadge(systemName: share.trait.icon, tint: share.trait.tint, diameter: 32)
            VStack(alignment: .leading, spacing: AppTheme.spacing4) {
                HStack {
                    Text(share.trait.title)
                        .font(.subheadline.weight(.semibold))
                        .adaptiveForegroundColor()
                    Spacer(minLength: AppTheme.spacing8)
                    Text("\(share.percent)%")
                        .font(.subheadline.monospacedDigit())
                        .adaptiveSecondaryForeground()
                }
                GeometryReader { proxy in
                    ZStack(alignment: .leading) {
                        Capsule().fill(AppTheme.subtleFill)
                        Capsule().fill(share.trait.tint)
                            .frame(width: proxy.size.width * share.share)
                    }
                }
                .frame(height: 6)
            }
            if opensRecipes {
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .adaptiveSecondaryForeground()
            }
        }
        .contentShape(Rectangle())
    }
}

private extension View {
    /// On the outermost element (the link when there is one), so VoiceOver and UI tests see one control per trait.
    func tasteRowAccessibility(_ share: TasteShare) -> some View {
        accessibilityElement(children: .ignore)
            .accessibilityLabel(share.trait.title)
            .accessibilityValue(share.cooks == 1 ? "\(share.percent) percent, 1 meal"
                                    : "\(share.percent) percent, \(share.cooks) meals")
            .accessibilityIdentifier("taste.row.\(share.trait.rawValue)")
    }
}

/// The fingerprint itself: five spokes, a faint outline, and the cook's shape scaled so the biggest trait reaches
/// the rim — a cook who mostly makes one thing still sees a shape, not a dot.
private struct TasteShape: View {
    let shares: [TasteShare]

    var body: some View {
        let top = shares.map(\.share).max() ?? 0
        let values = shares.map { top > 0 ? max($0.share / top, 0.06) : 0 }
        ZStack {
            Polygon(values: Array(repeating: 1, count: shares.count))
                .stroke(AppTheme.subtleStroke, lineWidth: 1)
            Polygon(values: Array(repeating: 0.5, count: shares.count))
                .stroke(AppTheme.subtleStroke, lineWidth: 0.5)
            Polygon(values: values)
                .fill(AppTheme.accentColor.opacity(0.35))
            Polygon(values: values)
                .stroke(AppTheme.accentColor, lineWidth: 2)
            GeometryReader { proxy in
                let radius = min(proxy.size.width, proxy.size.height) / 2
                ForEach(Array(shares.enumerated()), id: \.element.id) { index, share in
                    let point = Polygon.point(index: index, count: shares.count, radius: radius + 4,
                                              center: CGPoint(x: proxy.size.width / 2, y: proxy.size.height / 2))
                    Image(systemName: share.trait.icon)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(share.trait.tint)
                        .position(point)
                }
            }
        }
        .padding(AppTheme.spacing12)
    }
}

/// A closed shape with one corner per value, each at `value` × radius along its spoke, starting at the top.
private struct Polygon: Shape {
    let values: [Double]

    func path(in rect: CGRect) -> Path {
        var path = Path()
        guard values.count > 2 else { return path }
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        for (index, value) in values.enumerated() {
            let point = Self.point(index: index, count: values.count, radius: radius * value, center: center)
            if index == 0 { path.move(to: point) } else { path.addLine(to: point) }
        }
        path.closeSubpath()
        return path
    }

    static func point(index: Int, count: Int, radius: CGFloat, center: CGPoint) -> CGPoint {
        let angle = -Double.pi / 2 + 2 * Double.pi * Double(index) / Double(max(count, 1))
        return CGPoint(x: center.x + radius * cos(angle), y: center.y + radius * sin(angle))
    }
}

/// The recipes behind one trait, most cooked first; a row opens the recipe to cook it again.
struct TasteTraitRecipesView: View {
    let trait: TasteTrait
    let recipes: [RecipeModel]

    var body: some View {
        ZStack {
            AppBackground()
            ScrollView {
                LazyVStack(spacing: AppTheme.cardVerticalSpacing) {
                    ForEach(recipes) { recipe in
                        RecipeLink(recipe: recipe) {
                            RecipeRow(recipe: recipe)
                        }
                    }
                }
                .padding(.horizontal, AppTheme.spacing16)
                .padding(.vertical, AppTheme.spacing12)
                .padding(.bottom, AppTheme.spacing100)
            }
        }
        .appNavigationTitle(trait.title)
        // Me hides its bar for its own header; a pushed list needs it back for the title and Back.
        .toolbar(.visible, for: .navigationBar)
    }
}
