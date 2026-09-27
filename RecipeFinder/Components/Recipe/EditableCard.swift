import SwiftUI

/// Makes an info card tappable to edit with a top-trailing pencil affordance; used by recipe-detail cards so tapping opens the pre-filled editor.
extension View {
    func editableCard(onEdit: @escaping () -> Void, hint: String) -> some View {
        modifier(EditableCardModifier(onEdit: onEdit, hint: hint))
    }
}

private struct EditableCardModifier: ViewModifier {
    let onEdit: () -> Void
    let hint: String

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .topTrailing) {
                Image(systemName: "pencil")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .padding(AppTheme.spacing10)
                    .accessibilityHidden(true)
            }
            .contentShape(Rectangle())
            .onTapGesture { onEdit() }
            .accessibilityAddTraits(.isButton)
            .accessibilityHint(hint)
    }
}
