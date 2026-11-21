import SwiftUI

/// Today's one "do this now" (tomorrow's prep or something going off soon). Tapping opens the recipe; a Use it up
/// nudge links to the kitchen it comes from.
struct TodayNudgeCard: View {
    let nudge: TodayNudge
    let onOpen: () -> Void
    /// Opens Groceries on At home, where the expiring items live; shown only for a nudge from the kitchen.
    let onOpenKitchen: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacing8) {
            TodaySectionHeader(title: nudge.title, id: "nudge", onOpenKitchen: nudge.linksToKitchen ? onOpenKitchen : nil)

            Button(action: onOpen) {
                HStack(spacing: AppTheme.spacing12) {
                    RecipeImageView(recipe: nudge.recipe, imageName: nudge.recipe.heroImageName, height: 56)
                        .frame(width: 56, height: 56)
                        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius10))
                        .overlay(alignment: .bottomTrailing) {
                            IconBadge(systemName: nudge.symbol, tint: .orange, diameter: 24,
                                      iconSize: AppTheme.fontSize12, style: .solid)
                                .offset(x: 6, y: 6)
                        }
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
                            .lineLimit(2)
                    }
                    Spacer(minLength: 0)
                    Image(systemName: "chevron.right")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .accessibilityHidden(true)
                }
                .padding(AppTheme.spacing16)
                .contentShape(Rectangle())
                .appCard()
            }
            .buttonStyle(.plain)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(nudge.title): \(nudge.message). \(nudge.recipe.name)")
            .accessibilityHint("Opens the recipe")
            .accessibilityIdentifier("today.nudge")
        }
        .accessibilityElement(children: .contain)
    }
}

/// A Today section title with an optional "Your kitchen →" link on the right, for a section the kitchen powers,
/// so the cook can see and change what they're built from (Kitchen you can find, owner 2026-11-17).
struct TodaySectionHeader: View {
    let title: String
    let id: String
    var onOpenKitchen: (() -> Void)?

    var body: some View {
        // Side by side when it fits; stacked at large type so neither the title nor the link truncates.
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .firstTextBaseline, spacing: AppTheme.spacing8) {
                heading
                Spacer(minLength: AppTheme.spacing8)
                link
            }
            VStack(alignment: .leading, spacing: AppTheme.spacing2) {
                heading
                link
            }
        }
    }

    private var heading: some View {
        Text(title)
            .font(.headline)
            .adaptiveForegroundColor()
            .accessibilityAddTraits(.isHeader)
    }

    @ViewBuilder
    private var link: some View {
        if let onOpenKitchen {
            Button(action: onOpenKitchen) {
                Text("Your kitchen \(Image(systemName: "arrow.right"))")
                    .font(.subheadline.weight(.semibold))
                    .adaptiveForegroundColor()
                    .fixedSize()
                    .frame(minHeight: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Your kitchen")
            .accessibilityHint("Opens what you have at home in Groceries")
            .accessibilityIdentifier("today.\(id).openKitchen")
        }
    }
}
