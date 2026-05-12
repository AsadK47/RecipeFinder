import SwiftUI

struct ServingsControlView: View {
    @Binding var servings: Int
    let cardStyle: CardStyle
    let colorScheme: ColorScheme
    let selectedTheme: AppTheme.ThemeType

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacing12) {
            Text("Servings")
                .font(.headline)
                .adaptiveForegroundColor()

            HStack(spacing: AppTheme.spacing16) {
                Button(action: decrementServings) {
                    Image(systemName: "minus.circle.fill")
                        .font(.title2)
                        .foregroundColor(canDecrement ? AppTheme.accentColor(for: selectedTheme) : .gray)
                }
                .disabled(!canDecrement)

                Text("\(servings)")
                    .font(.title)
                    .fontWeight(.bold)
                    .adaptiveForegroundColor()
                    .frame(minWidth: QuickSnackLayout.servingsDisplayMinWidth)

                Button(action: incrementServings) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundColor(AppTheme.accentColor(for: selectedTheme))
                }
            }
            .padding()
            .frame(maxWidth: .infinity)
            .snackCardBackground(cardStyle: cardStyle, colorScheme: colorScheme)
        }
    }

    private var canDecrement: Bool {
        servings > QuickSnackLayout.minimumServings
    }

    private func decrementServings() {
        guard canDecrement else { return }
        servings -= 1
        HapticManager.shared.light()
    }

    private func incrementServings() {
        servings += 1
        HapticManager.shared.light()
    }
}
