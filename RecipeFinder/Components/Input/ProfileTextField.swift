import SwiftUI

struct ProfileTextField: View {
    let icon: String
    let label: String
    @Binding var text: String
    let placeholder: String

    var body: some View {
        HStack(spacing: AppTheme.spacing16) {
            Image(systemName: icon)
                .font(.title3)
                .adaptiveForegroundColor()
                .frame(width: AppTheme.iconSize28)

            VStack(alignment: .leading, spacing: AppTheme.spacing4) {
                Text(label)
                    .font(.caption)
                    .foregroundStyle(.primary)

                TextField(placeholder, text: $text)
                    .adaptiveForegroundColor()
                    .autocapitalization(.words)
            }
        }
        .padding(.horizontal, AppTheme.cardHorizontalPadding)
        .padding(.vertical, AppTheme.spacing16)
    }
}
