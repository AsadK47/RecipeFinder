import SwiftUI

/// One-time introduction shown the first time the full recipe wizard opens.
/// Explains the save-anytime, jump-to-any-section model so the editor doesn't
/// feel like a rigid form. Dismissed via "Get started"; the caller records that
/// it's been seen so it never shows again.
struct WizardIntroSheet: View {
    let onDismiss: () -> Void

    @Environment(\.appTheme) private var appTheme
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("appTheme") private var selectedTheme: AppTheme.ThemeType = .teal

    private struct Point: Identifiable {
        let id = UUID()
        let icon: String
        let title: String
        let detail: String
    }

    private let points: [Point] = [
        Point(icon: "square.and.arrow.down",
              title: "Save anytime",
              detail: "Add what you have now — a name and one ingredient is enough. Fill in the rest whenever."),
        Point(icon: "list.bullet.indent",
              title: "Jump to any section",
              detail: "No forced steps. Scroll straight to ingredients, timings, or notes in any order."),
        Point(icon: "hand.tap",
              title: "Tap to edit later",
              detail: "On a saved recipe, tap an ingredient's amount to edit it, or its name to check it off while cooking."),
    ]

    var body: some View {
        ZStack {
            AppTheme.backgroundGradient(for: selectedTheme, colorScheme: colorScheme)
                .ignoresSafeArea()

            VStack(spacing: AppTheme.spacing24) {
                Spacer(minLength: 0)

                Image(systemName: "wand.and.stars")
                    .font(.system(size: AppTheme.fontSize42))
                    .foregroundStyle(AppTheme.accentColor(for: selectedTheme))
                    .accessibilityHidden(true)

                Text("Build a recipe, your way")
                    .font(.title.bold())
                    .adaptiveForegroundColor()
                    .multilineTextAlignment(.center)

                VStack(alignment: .leading, spacing: AppTheme.spacing20) {
                    ForEach(points) { point in
                        HStack(alignment: .top, spacing: AppTheme.spacing16) {
                            Image(systemName: point.icon)
                                .font(.title3)
                                .foregroundStyle(AppTheme.accentColor(for: selectedTheme))
                                .frame(width: AppTheme.spacing32)
                                .accessibilityHidden(true)
                            VStack(alignment: .leading, spacing: AppTheme.spacing4) {
                                Text(point.title)
                                    .font(.headline)
                                    .adaptiveForegroundColor()
                                Text(point.detail)
                                    .font(.subheadline)
                                    .adaptiveSecondaryForeground()
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                        .accessibilityElement(children: .combine)
                    }
                }
                .padding(.horizontal, AppTheme.spacing8)

                Spacer(minLength: 0)

                Button(action: onDismiss) {
                    Text("Get started")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: AppTheme.height50)
                        .background(
                            RoundedRectangle(cornerRadius: AppTheme.cornerRadius14)
                                .fill(AppTheme.accentColor(for: selectedTheme))
                        )
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, AppTheme.spacing24)
            .padding(.vertical, AppTheme.spacing32)
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }
}
