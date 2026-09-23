import SwiftUI

/// Makes an info card tappable to edit, with a subtle pencil affordance in the
/// top-trailing corner so it's discoverable. Used by the recipe-detail info
/// cards (time, category/difficulty) so tapping them opens the pre-filled editor
/// — a natural alternative to hunting for the toolbar Edit button.
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
