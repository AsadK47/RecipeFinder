import SwiftUI
import UIKit

/// Today's "Tonight" card: the hero recipe's photo, why it was picked and when to start. Tapping the card opens the
/// recipe; "Cook this" goes straight into cooking mode; Shuffle steps to the next pick (separate buttons — a button
/// nested in a button's label never fires).
struct TodayHeroCard: View {
    let hero: TodayFeed.Hero
    /// Time-aware hint ("Start by 5:40 to eat at 7"), when there's one.
    let timing: String?
    /// When dinner is eaten (minutes since midnight), picked from the "Dinner at" pill.
    @Binding var eatAt: Int
    /// Nil when there's nothing else to shuffle to.
    let onShuffle: (() -> Void)?
    let onOpen: () -> Void
    let onCook: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button(action: onOpen) {
                VStack(alignment: .leading, spacing: 0) {
                    RecipeImageView(imageName: hero.recipe.heroImageName, height: 220, recipeName: hero.recipe.name)
                        .frame(maxWidth: .infinity)
                        .frame(height: 220)
                        .clipped()
                        .accessibilityHidden(true)

                    VStack(alignment: .leading, spacing: AppTheme.spacing6) {
                        Label(hero.reason.caption, systemImage: icon)
                            .font(.caption.weight(.semibold))
                            .adaptiveSecondaryForeground()
                        Text(hero.recipe.name)
                            .font(.title2.weight(.bold))
                            .adaptiveForegroundColor()
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                        if let timing {
                            Label(timing, systemImage: "clock")
                                .font(.subheadline.weight(.medium))
                                .adaptiveForegroundColor()
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding([.horizontal, .top], AppTheme.spacing16)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityElement(children: .combine)
            .accessibilityLabel(accessibilityText)
            .accessibilityHint("Opens the recipe")
            .accessibilityIdentifier("today.hero")

            // Side by side when they fit; at large text sizes the lesser pills drop below "Cook this".
            ViewThatFits(in: .horizontal) {
                HStack(spacing: AppTheme.spacing12) {
                    cookButton
                    Spacer(minLength: 0)
                    secondaryActions
                }
                VStack(alignment: .leading, spacing: AppTheme.spacing12) {
                    cookButton
                    HStack(spacing: AppTheme.spacing12) { secondaryActions }
                }
            }
            .padding([.horizontal, .bottom], AppTheme.spacing16)
            .padding(.top, AppTheme.spacing12)
        }
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius16))
        .appCard(elevated: true)
    }

    private var cookButton: some View {
        Button(action: onCook) {
            HStack(spacing: AppTheme.spacing4) {
                Text("Cook this")
                Image(systemName: "arrow.right")
            }
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, AppTheme.spacing16)
            .padding(.vertical, AppTheme.spacing10)
            .background(Capsule().fill(AppTheme.accentColor))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Cook \(hero.recipe.name)")
        .accessibilityHint("Starts cooking mode")
        .accessibilityIdentifier("today.hero.cook")
    }

    @ViewBuilder
    private var secondaryActions: some View {
        // Its own control (not inside the open button, where it wouldn't fire), shown even when there's no
        // timing line, so a passed eat time can always be changed back.
        if TonightTiming.asksEatTime(for: hero) {
            Menu {
                Picker("Dinner at", selection: $eatAt) {
                    ForEach(TonightTiming.eatTimeChoices, id: \.self) { minute in
                        Text("\(TonightTiming.clock(minute)) pm").tag(minute)
                    }
                }
            } label: {
                Label("\(TonightTiming.clock(eatAt)) pm", systemImage: "fork.knife")
                    .font(.subheadline.weight(.semibold))
                    .adaptiveForegroundColor()
                    .padding(.horizontal, AppTheme.spacing12)
                    .padding(.vertical, AppTheme.spacing10)
                    .appCard(in: Capsule())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Dinner at \(TonightTiming.clock(eatAt)) pm")
            .accessibilityHint("Changes when you eat dinner")
            .accessibilityIdentifier("today.hero.eatAt")
        }

        if let onShuffle {
            Button(action: onShuffle) {
                Label("Shuffle", systemImage: "shuffle")
                    .font(.subheadline.weight(.semibold))
                    .adaptiveForegroundColor()
                    .padding(.horizontal, AppTheme.spacing16)
                    .padding(.vertical, AppTheme.spacing10)
                    .appCard(in: Capsule())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Shuffle")
            .accessibilityHint("Shows another idea for tonight")
            .accessibilityIdentifier("today.hero.shuffle")
        }
    }

    private var accessibilityText: String {
        ["Tonight: \(hero.recipe.name)", hero.reason.caption, timing].compactMap { $0 }.joined(separator: ". ")
    }

    private var icon: String {
        switch hero.reason {
        case .planned(let time): time.icon
        case .kitchenMatch: "refrigerator.fill"
        case .quick: "bolt.fill"
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
            // No card per tile: photos on the background keep the shelves calm under the Tonight card.
            VStack(alignment: .leading, spacing: AppTheme.spacing6) {
                RecipeImageView(imageName: recipe.heroImageName, height: 120, recipeName: recipe.name)
                    .frame(width: 160, height: 120)
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
            .frame(width: 160, alignment: .leading)
            .contentShape(Rectangle())
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
                IconBadge(systemName: "timer", tint: .orange, diameter: 44, iconSize: AppTheme.fontSize18, style: .tinted)
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
