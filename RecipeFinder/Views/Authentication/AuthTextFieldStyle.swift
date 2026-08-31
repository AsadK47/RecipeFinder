import SwiftUI

/// Shared text field style for the authentication screens.
struct AuthTextFieldStyle: TextFieldStyle {
    @Environment(\.colorScheme) var colorScheme
    
    func _body(configuration: TextField<_Label>) -> some View {
        configuration
            .padding()
            .background(
                RoundedRectangle(cornerRadius: AppTheme.cornerRadius12)
                    .fill(AppTheme.textColor(for: colorScheme, opacity: 0.15))
                    .overlay(
                        RoundedRectangle(cornerRadius: AppTheme.cornerRadius12)
                            .stroke(AppTheme.textColor(for: colorScheme, opacity: 0.3), lineWidth: 1)
                    )
            )
            .adaptiveForegroundColor()
            .tint(AppTheme.textColor(for: colorScheme))
    }
}
