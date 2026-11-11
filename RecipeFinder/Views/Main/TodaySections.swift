import SwiftUI
import UIKit

/// Today's "Tonight" card: the hero recipe's photo and why it was picked. Tapping the card opens the recipe;
/// "Let's cook" goes straight into cooking mode (separate buttons — a button nested in a button's label never fires).
struct TodayHeroCard: View {
    let hero: TodayFeed.Hero
    let onOpen: () -> Void
    let onCook: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button(action: onOpen) {
                VStack(alignment: .leading, spacing: 0) {
                    RecipeImageView(imageName: hero.recipe.heroImageName, height: 180, recipeName: hero.recipe.name)
                        .frame(maxWidth: .infinity)
                        .frame(height: 180)
                        .clipped()
                        .accessibilityHidden(true)

                    VStack(alignment: .leading, spacing: AppTheme.spacing6) {
                        Label(hero.reason.caption, systemImage: icon)
                            .font(.caption.weight(.semibold))
                            .adaptiveSecondaryForeground()
                        Text(hero.recipe.name)
                            .font(.title3.weight(.bold))
                            .adaptiveForegroundColor()
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding([.horizontal, .top], AppTheme.spacing16)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Tonight: \(hero.recipe.name). \(hero.reason.caption)")
            .accessibilityHint("Opens the recipe")
            .accessibilityIdentifier("today.hero")

            Button(action: onCook) {
                HStack(spacing: AppTheme.spacing4) {
                    Text("Let's cook")
                    Image(systemName: "arrow.right")
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, AppTheme.spacing16)
                .padding(.vertical, AppTheme.spacing8)
                .background(Capsule().fill(AppTheme.accentColor))
            }
            .buttonStyle(.plain)
            .padding([.horizontal, .bottom], AppTheme.spacing16)
            .padding(.top, AppTheme.spacing10)
            .accessibilityLabel("Let's cook \(hero.recipe.name)")
            .accessibilityHint("Starts cooking mode")
            .accessibilityIdentifier("today.hero.cook")
        }
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius16))
        .appCard(elevated: true)
    }

    private var icon: String {
        switch hero.reason {
        case .planned(let time): time.icon
        case .kitchenMatch: "refrigerator.fill"
        }
    }
}

/// A titled horizontal row of recipe tiles; hidden by the caller when empty.
struct TodayShelf: View {
    let title: String
    let id: String
    let items: [(recipe: RecipeModel, caption: String?)]
    let onOpen: (RecipeModel) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacing8) {
            Text(title)
                .font(.headline)
                .adaptiveForegroundColor()
                .accessibilityAddTraits(.isHeader)

            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(alignment: .top, spacing: AppTheme.spacing12) {
                    ForEach(items, id: \.recipe.id) { item in
                        tile(item.recipe, caption: item.caption)
                    }
                }
                .padding(.vertical, AppTheme.spacing2)
            }
            .scrollClipDisabled()
        }
        .accessibilityIdentifier("today.shelf.\(id)")
    }

    private func tile(_ recipe: RecipeModel, caption: String?) -> some View {
        Button { onOpen(recipe) } label: {
            VStack(alignment: .leading, spacing: AppTheme.spacing6) {
                RecipeImageView(imageName: recipe.heroImageName, height: 100, recipeName: recipe.name)
                    .frame(width: 140, height: 100)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius12))
                    .accessibilityHidden(true)
                Text(recipe.name)
                    .font(.subheadline.weight(.semibold))
                    .adaptiveForegroundColor()
                    .lineLimit(2, reservesSpace: true)
                    .multilineTextAlignment(.leading)
                if let caption {
                    Text(caption)
                        .font(.caption)
                        .adaptiveSecondaryForeground()
                        .lineLimit(1)
                }
            }
            .frame(width: 140, alignment: .leading)
            .padding(AppTheme.spacing8)
            .appCard()
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityHint("Opens the recipe")
    }
}

/// "Prep ahead" nudge: a planned meal tomorrow that needs starting tonight. Tapping opens the recipe.
struct TodayPrepAheadRow: View {
    let nudge: PrepAheadNudge
    let onOpen: () -> Void

    var body: some View {
        Button(action: onOpen) {
            HStack(spacing: AppTheme.spacing16) {
                IconBadge(systemName: "timer", tint: .orange, diameter: 44, iconSize: AppTheme.fontSize18, style: .solid)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: AppTheme.spacing2) {
                    Text(nudge.message)
                        .font(.caption.weight(.semibold))
                        .adaptiveSecondaryForeground()
                        .fixedSize(horizontal: false, vertical: true)
                    Text(nudge.recipe.name)
                        .font(.body.weight(.semibold))
                        .adaptiveForegroundColor()
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(true)
            }
            .padding(AppTheme.spacing16)
            .appCard()
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Prep ahead: \(nudge.message). \(nudge.recipe.name)")
        .accessibilityHint("Opens the recipe")
        .accessibilityIdentifier("today.prepAhead")
    }
}

/// "Copied a recipe link?" card. The link is read only through `PasteButton` — the user's tap is the consent, so iOS
/// shows no "Allow Paste" prompt — and goes straight to the link importer.
struct TodayClipboardCard: View {
    /// Gets the first web link in what was pasted, or nil when the paste held none. Main-actor (hence Sendable)
    /// because PasteButton may call back from elsewhere.
    let onPaste: @MainActor (URL?) -> Void
    let onDismiss: () -> Void

    var body: some View {
        let handler = onPaste
        return HStack(alignment: .top, spacing: AppTheme.spacing16) {
            IconBadge(systemName: "link", tint: .blue, diameter: 44, iconSize: AppTheme.fontSize18, style: .solid)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: AppTheme.spacing8) {
                Text("Copied a recipe link?")
                    .font(.headline)
                    .adaptiveForegroundColor()
                Text("Paste it here and RecipeFinder saves the recipe for you.")
                    .font(.subheadline)
                    .adaptiveSecondaryForeground()
                    .fixedSize(horizontal: false, vertical: true)
                PasteButton(payloadType: String.self) { [handler] strings in
                    let url = ClipboardRecipeLink.url(in: strings)
                    Task { @MainActor in handler(url) }
                }
                .buttonBorderShape(.capsule)
                .labelStyle(.titleAndIcon)
                .tint(AppTheme.accentColor)
                .accessibilityIdentifier("today.clipboard.paste")
            }
            Spacer(minLength: 0)
            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .padding(.top, -AppTheme.spacing10)
            .padding(.trailing, -AppTheme.spacing10)
            .accessibilityLabel("Dismiss")
            .accessibilityIdentifier("today.clipboard.dismiss")
        }
        .padding(AppTheme.spacing20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .appCard()
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("today.clipboard")
    }
}

/// Asks whether the clipboard looks like it holds a web link without reading it: `detectPatterns` doesn't trigger the
/// "Allow Paste" prompt, so Today can offer the card without nagging.
@MainActor
enum ClipboardLinkProbe {
    nonisolated private static let logger = AppLogger.logger(category: "ClipboardLinkProbe")

    static var changeCount: Int { UIPasteboard.general.changeCount }

    static func hasWebLink() async -> Bool {
        #if DEBUG
        // Screenshots hook: the simulator's clipboard is empty in CI.
        if ProcessInfo.processInfo.arguments.contains("-fake-clipboard-link") { return true }
        #endif
        let pasteboard = UIPasteboard.general
        guard pasteboard.hasStrings || pasteboard.hasURLs else { return false }
        return await withCheckedContinuation { continuation in
            // @Sendable: the handler runs off the main queue, so it must not inherit main-actor isolation.
            pasteboard.detectPatterns(for: [.probableWebURL]) { @Sendable result in
                switch result {
                case .success(let patterns):
                    continuation.resume(returning: patterns.contains(.probableWebURL))
                case .failure(let error):
                    logger.debug("Clipboard pattern check failed: \(error.localizedDescription)")
                    continuation.resume(returning: false)
                }
            }
        }
    }
}
