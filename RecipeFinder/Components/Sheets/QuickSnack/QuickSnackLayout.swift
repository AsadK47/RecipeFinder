import SwiftUI

// MARK: - Layout Constants

enum QuickSnackLayout {
    static let headerHorizontalPadding: CGFloat = AppTheme.spacing20
    static let headerTopPadding: CGFloat = AppTheme.spacing20
    static let headerBottomPadding: CGFloat = AppTheme.spacing8
    static let addButtonTopPadding: CGFloat = AppTheme.spacing8
    static let scrollBottomPadding: CGFloat = 100
    static let emojiGridColumnCount = 8
    static let emojiGridItemSize: CGFloat = AppTheme.iconSize40
    static let snackCardWidth: CGFloat = AppTheme.width80
    static let snackCardHeight: CGFloat = 100
    static let maxVisibleSnacks = 20
    static let servingsDisplayMinWidth: CGFloat = 50
    static let minimumServings = 1
}

// MARK: - Card Background Modifier

struct QuickSnackCardBackgroundModifier: ViewModifier {
    let cardStyle: CardStyle
    let colorScheme: ColorScheme

    func body(content: Content) -> some View {
        content.background {
            if cardStyle == .solid {
                RoundedRectangle(cornerRadius: AppTheme.cornerRadius12)
                    .fill(AppTheme.adaptiveCardMedium(for: colorScheme))
            } else {
                RoundedRectangle(cornerRadius: AppTheme.cornerRadius12)
                    .fill(.ultraThinMaterial)
            }
        }
    }
}

extension View {
    func snackCardBackground(cardStyle: CardStyle, colorScheme: ColorScheme) -> some View {
        modifier(QuickSnackCardBackgroundModifier(cardStyle: cardStyle, colorScheme: colorScheme))
    }
}
