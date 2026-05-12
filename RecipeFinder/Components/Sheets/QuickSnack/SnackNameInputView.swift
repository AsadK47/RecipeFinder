import SwiftUI

struct SnackNameInputView: View {
    @Binding var snackName: String
    let cardStyle: CardStyle
    let colorScheme: ColorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacing12) {
            Text("Snack Name")
                .font(.headline)
                .adaptiveForegroundColor()

            TextField("E.g., Apple Slices", text: $snackName)
                .textFieldStyle(.plain)
                .padding()
                .snackCardBackground(cardStyle: cardStyle, colorScheme: colorScheme)
                .foregroundColor(AppTheme.adaptiveEmphasis(for: colorScheme))
        }
    }
}
