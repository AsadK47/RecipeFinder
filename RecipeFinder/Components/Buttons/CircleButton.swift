import SwiftUI

struct CircleButton: View {
    let icon: String
    let action: () -> Void


    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(AppTheme.adaptiveEmphasis())
                .padding(AppTheme.spacing12)
                .appCard(in: Circle())
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityAddTraits(.isButton)
    }
}

#Preview {
    ZStack {
        Color.blue
        HStack {
            CircleButton(icon: "plus.circle.fill") {}
            CircleButton(icon: "ellipsis.circle.fill") {}
        }
    }
}
