import SwiftUI

/// The recipe's notes (formatted) and, for imports, a link back to the original page.
struct RecipeNotesContent: View {
    let notes: String
    let originalURL: URL?

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacing12) {
            if !notes.isEmpty {
                Text(RecipeNotesFormatter.attributedString(from: notes))
                    .font(.subheadline)
                    .foregroundStyle(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
            if let url = originalURL {
                HStack(spacing: AppTheme.spacing8) {
                    Link(destination: url) {
                        Label("View Original", systemImage: "link")
                            .font(.subheadline)
                            .foregroundStyle(AppTheme.accentColor)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}
