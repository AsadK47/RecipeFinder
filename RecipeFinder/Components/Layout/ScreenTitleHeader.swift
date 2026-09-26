import SwiftUI

// Consistent main-tab title bar: centred bold title with balanced gutters and an optional trailing action, so tabs read as one app.
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
                // Reserve trailing-button space both sides to keep title centred; no lineLimit so it wraps at large Dynamic Type (a11y requirement).
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
