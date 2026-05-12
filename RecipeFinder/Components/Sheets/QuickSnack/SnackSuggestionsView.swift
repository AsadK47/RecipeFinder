import SwiftUI

struct SnackSuggestionsView: View {
    let filteredSnacks: [SnackItem]
    let onSnackSelected: (SnackItem) -> Void
    let cardStyle: CardStyle
    let colorScheme: ColorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacing12) {
            HStack {
                Text("Quick Picks")
                    .font(.headline)
                    .adaptiveForegroundColor()

                Spacer()

                Text("\(filteredSnacks.count) snacks")
                    .font(.caption)
                    .adaptiveForegroundColor(opacity: AppTheme.mediumEmphasisOpacity)
            }
            .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppTheme.spacing12) {
                    ForEach(filteredSnacks.prefix(QuickSnackLayout.maxVisibleSnacks)) { snack in
                        Button(action: { onSnackSelected(snack) }) {
                            VStack(spacing: AppTheme.spacing8) {
                                Text(snack.emoji)
                                    .font(.system(size: AppTheme.fontSize32))
                                Text(snack.name)
                                    .font(.caption)
                                    .adaptiveForegroundColor()
                                    .lineLimit(2)
                                    .multilineTextAlignment(.center)

                                if let calories = snack.calories {
                                    Text("\(calories) cal")
                                        .font(.caption2)
                                        .adaptiveForegroundColor(opacity: AppTheme.mediumEmphasisOpacity)
                                }
                            }
                            .frame(
                                width: QuickSnackLayout.snackCardWidth,
                                height: QuickSnackLayout.snackCardHeight
                            )
                            .snackCardBackground(cardStyle: cardStyle, colorScheme: colorScheme)
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
        .transition(.opacity)
    }
}
