import SwiftUI

struct EmojiSelectorView: View {
    @Binding var selectedEmoji: String
    @Binding var showEmojiPicker: Bool
    let cardStyle: CardStyle
    let colorScheme: ColorScheme
    let selectedTheme: AppTheme.ThemeType

    let emojiOptions = [
        "🍎", "🍌", "🍊", "🍇", "🍓", "🫐", "🍒", "🍑", "🥝", "🥑",
        "🥕", "🥒", "🥦", "🌽", "🍅", "🥔", "🫑", "🥜", "🌰", "🥐",
        "🥖", "🥯", "🧀", "🥚", "🍗", "🥓", "🌭", "🍕", "🍔", "🌮",
        "🍿", "🧃", "🥤", "🍵", "☕️", "🍪", "🍩", "🍰", "🧁", "🍫",
        "🍬", "🍭", "🥨", "🥪", "🌯", "🥗", "🍜", "🍝", "🍱", "🍙"
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacing12) {
            Text("Icon")
                .font(.headline)
                .adaptiveForegroundColor()

            Button(action: {
                showEmojiPicker.toggle()
                HapticManager.shared.light()
            }) {
                HStack {
                    Text(selectedEmoji)
                        .font(.system(size: AppTheme.fontSize50))

                    Spacer()

                    Image(systemName: "chevron.down")
                        .adaptiveForegroundColor(opacity: AppTheme.glassLightOpacity)
                        .rotationEffect(.degrees(showEmojiPicker ? 180 : 0))
                }
                .padding()
                .snackCardBackground(cardStyle: cardStyle, colorScheme: colorScheme)
            }
            .accessibilityLabel("Selected emoji: \(selectedEmoji)")
            .accessibilityHint("Double tap to choose a different emoji icon")
            .accessibilityAddTraits(.isButton)

            if showEmojiPicker {
                LazyVGrid(
                    columns: Array(
                        repeating: GridItem(.flexible(), spacing: AppTheme.spacing8),
                        count: QuickSnackLayout.emojiGridColumnCount
                    ),
                    spacing: AppTheme.spacing8
                ) {
                    ForEach(emojiOptions, id: \.self) { emoji in
                        Button(action: {
                            selectedEmoji = emoji
                            showEmojiPicker = false
                            HapticManager.shared.light()
                        }) {
                            Text(emoji)
                                .font(.system(size: AppTheme.fontSize32))
                                .frame(
                                    width: QuickSnackLayout.emojiGridItemSize,
                                    height: QuickSnackLayout.emojiGridItemSize
                                )
                                .background {
                                    if selectedEmoji == emoji {
                                        RoundedRectangle(cornerRadius: AppTheme.cornerRadius8)
                                            .fill(AppTheme.accentColor(for: selectedTheme).opacity(0.3))
                                    }
                                }
                        }
                    }
                }
                .padding()
                .background {
                    if cardStyle == .solid {
                        RoundedRectangle(cornerRadius: AppTheme.cornerRadius12)
                            .fill(AppTheme.adaptiveCardHigh(for: colorScheme))
                    } else {
                        RoundedRectangle(cornerRadius: AppTheme.cornerRadius12)
                            .fill(.ultraThinMaterial)
                    }
                }
                .transition(.scale.combined(with: .opacity))
            }
        }
    }
}
