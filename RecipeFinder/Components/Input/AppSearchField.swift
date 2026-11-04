import SwiftUI

// Screen-header search field with external focus (parent owns it to drive keyboard toolbars/submit); `SearchBar` is the sibling for sheets that own focus themselves.
struct AppSearchField: View {
    @Binding var text: String
    var placeholder: String
    var isFocused: FocusState<Bool>.Binding
    var onSubmit: (() -> Void)?
    /// Applied to the inner `TextField` only, so UI tests can target it without matching other screens' fields.
    var accessibilityID: String?

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: AppTheme.spacing12) {
            HStack(spacing: AppTheme.spacing12) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(AppTheme.adaptiveHighEmphasis(for: colorScheme))
                    .font(.system(size: AppTheme.fontSize18, weight: .medium))

                ZStack(alignment: .leading) {
                    if text.isEmpty {
                        Text(placeholder)
                            .font(.callout)
                            .foregroundStyle(colorScheme == .dark
                                ? .white.opacity(AppTheme.disabledEmphasisOpacity)
                                : .black.opacity(AppTheme.disabledEmphasisOpacity))
                    }
                    TextField("", text: $text)
                        .focused(isFocused)
                        .autocorrectionDisabled()
                        .submitLabel(.done)
                        .onSubmit { onSubmit?() }
                        .font(.callout)
                        .adaptiveForegroundColor()
                        .tint(AppTheme.textColor(for: colorScheme))
                        .accessibilityIdentifier(accessibilityID ?? "")
                }

                if !text.isEmpty {
                    Button(action: { text = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: AppTheme.fontSize18))
                            .foregroundStyle(AppTheme.adaptiveSubtitle(for: colorScheme))
                    }
                }
            }
            .padding(.horizontal, AppTheme.spacing16)
            .padding(.vertical, AppTheme.spacing14)
            .appCard(cornerRadius: AppTheme.cornerRadius12)

            if isFocused.wrappedValue {
                Button(
                    action: {
                        text = ""
                        isFocused.wrappedValue = false
                    },
                    label: {
                        Text("Cancel")
                            .font(.system(size: AppTheme.fontSize16, weight: .semibold))
                            .adaptiveForegroundColor()
                    }
                )
                .frame(minHeight: 44)
                .contentShape(Rectangle())
                .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
        .animation(.appSpring, value: isFocused.wrappedValue)
    }
}
