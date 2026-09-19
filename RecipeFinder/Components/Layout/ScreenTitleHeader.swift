import SwiftUI

/// One consistent title bar for the main tabs: a centred bold title with balanced
/// side gutters and an optional trailing action (usually an overflow menu), sized
/// and padded identically everywhere. Adopt this instead of each screen rolling
/// its own title row, so the tabs read as one app.
struct ScreenTitleHeader<Trailing: View>: View {
    let title: String
    private let trailing: Trailing

    init(_ title: String, @ViewBuilder trailing: () -> Trailing) {
        self.title = title
        self.trailing = trailing()
    }

    var body: some View {
        ZStack {
            Text(title)
                .font(.largeTitle.weight(.bold))
                .adaptiveForegroundColor()
                .multilineTextAlignment(.center)
                // Reserve space for the trailing button on both sides so the title
                // stays centred. No lineLimit — titles must wrap at large Dynamic
                // Type sizes rather than clip (accessibility audit requirement).
                .padding(.horizontal, AppTheme.height44)
                .frame(maxWidth: .infinity, alignment: .center)

            HStack {
                Spacer()
                trailing
            }
        }
        .padding(.horizontal, AppTheme.spacing20)
        .padding(.top, AppTheme.spacing16)
        .padding(.bottom, AppTheme.spacing4)
    }
}

extension ScreenTitleHeader where Trailing == EmptyView {
    init(_ title: String) {
        self.init(title) { EmptyView() }
    }
}
