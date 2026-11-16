import SwiftUI

/// Top of Me: a swipeable book of every dish the cook has made, built from cook history. Tap a page → the recipe,
/// to cook it again. Empty → one button to go and pick something to cook.
struct MyCookbookSection: View {
    let pages: [CookbookPage]

    @State private var sharing: CookbookPage?

    /// Grows with Dynamic Type so the text over the picture is never clipped.
    @ScaledMetric(relativeTo: .title3) private var pageHeight: CGFloat = 260

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacing12) {
            // Headline under the title, so both stay whole at large text sizes.
            VStack(alignment: .leading, spacing: AppTheme.spacing2) {
                Label("My Cookbook", systemImage: "book.closed.fill")
                    .font(.headline)
                    .adaptiveForegroundColor()
                    .accessibilityAddTraits(.isHeader)
                if let headline = MyCookbook.headline(for: pages) {
                    Text(headline)
                        .font(.subheadline.weight(.semibold))
                        .adaptiveSecondaryForeground()
                        .accessibilityIdentifier("cookbook.headline")
                }
            }

            if pages.isEmpty {
                emptyPage
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: AppTheme.spacing12) {
                        ForEach(pages) { page in
                            NavigationLink(value: page.id) {
                                CookbookPageView(page: page, height: pageHeight)
                            }
                            .buttonStyle(.plain)
                            .accessibilityElement(children: .ignore)
                            .accessibilityLabel(page.name)
                            .accessibilityValue(Self.spokenDetails(page))
                            .accessibilityHint("Opens the recipe to cook it again")
                            .accessibilityAddTraits(.isButton)
                            .accessibilityIdentifier("cookbook.page")
                            // The next page peeks in, so it's clear there are more to swipe through.
                            .containerRelativeFrame(.horizontal, count: 10, span: 9, spacing: AppTheme.spacing12)
                            .overlay(alignment: .topTrailing) { shareButton(for: page) }
                        }
                    }
                    .scrollTargetLayout()
                }
                .scrollTargetBehavior(.viewAligned)
                .frame(height: pageHeight)
                .accessibilityIdentifier("cookbook.pages")
            }
        }
        .sheet(item: $sharing) { page in
            CookbookShareSheet(page: page)
        }
    }

    /// On the page itself, so sharing a dish is one tap and doesn't hide behind a long-press.
    private func shareButton(for page: CookbookPage) -> some View {
        Button {
            HapticManager.shared.light()
            sharing = page
        } label: {
            // Fixed size: the circle is a fixed 44 pt tap target, so a Dynamic Type glyph would overflow it.
            Image(systemName: "square.and.arrow.up")
                .font(.system(size: 16, weight: .semibold))
                .adaptiveForegroundColor()
                .frame(width: 44, height: 44)
                .appCard(in: Circle())
        }
        .buttonStyle(.plain)
        .padding(AppTheme.spacing8)
        .accessibilityLabel("Share \(page.name)")
        .accessibilityIdentifier("cookbook.page.share")
    }

    private static func spokenDetails(_ page: CookbookPage) -> String {
        let line = page.line
        return page.rating > 0 ? "\(line), \(page.rating) of 5 stars" : line
    }

    private var emptyPage: some View {
        VStack(spacing: AppTheme.spacing12) {
            IconBadge(systemName: "book.closed.fill", tint: AppTheme.accentColor, diameter: 56)
            Text("Cook something and it lands here")
                .font(.headline)
                .adaptiveForegroundColor()
                .multilineTextAlignment(.center)
            Text("Every dish you make gets its own page — your photo, the date and your stars.")
                .font(.subheadline)
                .adaptiveSecondaryForeground()
                .multilineTextAlignment(.center)
            PrimaryButton("Pick something to cook", systemImage: BadgeEarnAction.cook.icon) {
                NotificationCenter.default.post(name: BadgeEarnAction.cook.notification, object: nil)
            }
            .accessibilityIdentifier("cookbook.empty.cook")
        }
        .frame(maxWidth: .infinity)
        .padding(AppTheme.spacing20)
        .appCard()
        .accessibilityIdentifier("cookbook.empty")
    }
}

/// One full-bleed page: the dish picture with its name, when it was made and its stars over a soft shade.
private struct CookbookPageView: View {
    let page: CookbookPage
    let height: CGFloat

    var body: some View {
        RecipeImageView(imageName: page.imageName, height: height, recipeName: page.name,
                        category: page.category, cuisine: page.cuisine)
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .overlay(alignment: .bottomLeading) {
                VStack(alignment: .leading, spacing: AppTheme.spacing4) {
                    Text(page.name)
                        .font(.title3.weight(.bold))
                        .lineLimit(2)
                        .minimumScaleFactor(0.8)
                    Text(page.line)
                        .font(.subheadline.weight(.medium))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    if page.rating > 0 {
                        HStack(spacing: AppTheme.spacing2) {
                            ForEach(1...5, id: \.self) { star in
                                Image(systemName: star <= page.rating ? "star.fill" : "star")
                                    .font(.caption)
                            }
                        }
                    }
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(AppTheme.spacing16)
                // Dark under every line of text, so a pale dish or light art never washes the name out.
                .background(
                    LinearGradient(colors: [.black.opacity(0.35), .black.opacity(0.75)], startPoint: .top,
                                   endPoint: .bottom)
                )
            }
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius16, style: .continuous))
            .contentShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius16, style: .continuous))
    }
}
