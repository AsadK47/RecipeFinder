import SwiftUI

// 1–5 star rating; tap the active star to clear to 0 (unrated). Shared with the Made it sheet.
// VoiceOver: one adjustable element (swipe up/down); stars scale with Dynamic Type and keep 44pt targets.
struct StarRatingView: View {
    let rating: Int
    let onTap: (Int) -> Void
    @ScaledMetric(relativeTo: .body) private var starSize: CGFloat = 18

    var body: some View {
        HStack(spacing: 0) {
            ForEach(1...5, id: \.self) { star in
                Button {
                    onTap(star == rating ? 0 : star)
                } label: {
                    Image(systemName: star <= rating ? "star.fill" : "star")
                        .foregroundStyle(star <= rating ? Color.yellow : Color.secondary)
                        .font(.system(size: starSize))
                        .frame(minWidth: 44, minHeight: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Rating")
        .accessibilityValue(rating == 0 ? "Unrated" : "\(rating) of 5 stars")
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment: onTap(Self.adjusted(rating, by: 1))
            case .decrement: onTap(Self.adjusted(rating, by: -1))
            @unknown default: break
            }
        }
    }

    /// The rating one VoiceOver swipe away, clamped to 0 (unrated)…5.
    nonisolated static func adjusted(_ rating: Int, by step: Int) -> Int {
        min(5, max(0, rating + step))
    }
}
