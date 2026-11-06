import SwiftUI

/// Header overflow menu drawn with the `CircleButton` look, so every tab's menu matches.
struct CircleMenuButton<MenuContent: View, Badge: View>: View {
    var icon: String = "line.3.horizontal"
    let accessibilityLabel: LocalizedStringKey
    @ViewBuilder let badge: () -> Badge
    @ViewBuilder let content: () -> MenuContent

    var body: some View {
        Menu {
            content()
        } label: {
            // The Menu owns the tap; the inner button is visual only.
            CircleButton(icon: icon) {}
                .allowsHitTesting(false)
                .overlay(alignment: .topTrailing) { badge() }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
    }
}

extension CircleMenuButton where Badge == EmptyView {
    init(
        icon: String = "line.3.horizontal",
        accessibilityLabel: LocalizedStringKey,
        @ViewBuilder content: @escaping () -> MenuContent
    ) {
        self.init(icon: icon, accessibilityLabel: accessibilityLabel, badge: { EmptyView() }, content: content)
    }
}

#Preview {
    ZStack {
        Color.blue
        CircleMenuButton(accessibilityLabel: "More options") {
            Button("Action") {}
        }
    }
}
