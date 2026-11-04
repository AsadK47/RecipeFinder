import SwiftUI

/// The app's search field. Pass `isFocused` when the parent needs to drive focus (keyboard toolbars, submit);
/// omit it in sheets and the field manages its own.
struct AppSearchField: View {
    @Binding var text: String
    var placeholder: String
    var onSubmit: (() -> Void)?
    /// Applied to the inner `TextField` only, so UI tests can target it without matching other screens' fields.
    var accessibilityID: String?

    private let externalFocus: FocusState<Bool>.Binding?
    @FocusState private var ownFocus: Bool

    private var isFocused: FocusState<Bool>.Binding { externalFocus ?? $ownFocus }

    init(
        text: Binding<String>,
        placeholder: String,
        isFocused: FocusState<Bool>.Binding? = nil,
        onSubmit: (() -> Void)? = nil,
        accessibilityID: String? = nil
    ) {
        _text = text
        self.placeholder = placeholder
        self.externalFocus = isFocused
        self.onSubmit = onSubmit
        self.accessibilityID = accessibilityID
    }

    var body: some View {
        HStack(spacing: AppTheme.spacing12) {
            HStack(spacing: AppTheme.spacing12) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(AppTheme.adaptiveHighEmphasis)
                    .font(.system(size: AppTheme.fontSize18, weight: .medium))

                ZStack(alignment: .leading) {
                    if text.isEmpty {
                        Text(placeholder)
                            .font(.callout)
                            .foregroundStyle(AppTheme.textColor(opacity: AppTheme.disabledEmphasisOpacity))
                    }
                    TextField("", text: $text)
                        .focused(isFocused)
                        .autocorrectionDisabled()
                        .submitLabel(.done)
                        .onSubmit { onSubmit?() }
                        .font(.callout)
                        .adaptiveForegroundColor()
                        .tint(AppTheme.textColor())
                        .accessibilityIdentifier(accessibilityID ?? "")
                }

                if !text.isEmpty {
                    Button(action: { text = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: AppTheme.fontSize18))
                            .foregroundStyle(AppTheme.adaptiveSubtitle)
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
