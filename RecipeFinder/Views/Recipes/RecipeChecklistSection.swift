import SwiftUI

// Collapsible titled section (Pre-Prep/Instructions/Notes); parent owns expansion state.
struct RecipeChecklistSection<Content: View>: View {
    let title: String
    let icon: String
    let isExpanded: Bool
    let colorScheme: ColorScheme
    let onToggle: () -> Void
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacing12) {
            Button(
                action: onToggle,
                label: {
                    HStack(spacing: AppTheme.spacing8) {
                        Image(systemName: icon)
                            .adaptiveForegroundColor()
                            .font(.title3)
                        Text(title)
                            .font(.title2)
                            .fontWeight(.bold)
                            .adaptiveForegroundColor()

                        Spacer()

                        Image(systemName: "chevron.down")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundStyle(AppTheme.adaptiveHighEmphasis(for: colorScheme))
                            .rotationEffect(.degrees(isExpanded ? 0 : -90))
                            .animation(.spring(response: 0.3), value: isExpanded)
                    }
                    .padding(.top, AppTheme.spacing24)
                }
            )
            .buttonStyle(PlainButtonStyle())

            if isExpanded {
                GlassCard {
                    content()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(AppTheme.spacing24)
                }
                .transition(.asymmetric(
                    insertion: .scale(scale: AppTheme.transitionScaleDown).combined(with: .opacity),
                    removal: .scale(scale: AppTheme.transitionScaleDown).combined(with: .opacity)
                ))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, AppTheme.spacing20)
    }
}

// Tappable instruction/pre-prep step row with a checkmark.
struct RecipeInstructionRow: View {
    let text: String
    let isChecked: Bool
    let toggle: () -> Void

    var body: some View {
        Button(action: toggle, label: {
            HStack(alignment: .center, spacing: AppTheme.spacing12) {
                Text(text)
                    .font(.body)
                    .foregroundStyle(.primary)
                    .strikethrough(isChecked, color: .primary)
                    .opacity(isChecked ? 0.5 : 1.0)
                    .fixedSize(horizontal: false, vertical: true)
                    .multilineTextAlignment(.leading)

                Spacer(minLength: 0)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        })
        .buttonStyle(.plain)
    }
}
