import SwiftUI

struct AddButtonView: View {
    let isEnabled: Bool
    let selectedTheme: AppTheme.ThemeType
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                Text("Add Snack")
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                AppTheme.accentColor(for: selectedTheme)
                    .opacity(isEnabled ? AppTheme.fullOpacity : AppTheme.glassLightOpacity)
            )
            .adaptiveForegroundColor()
            .cornerRadius(AppTheme.cornerRadius12)
        }
        .disabled(!isEnabled)
    }
}
