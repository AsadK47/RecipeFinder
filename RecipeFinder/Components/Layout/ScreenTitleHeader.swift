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
        GeometryReader { geometry in
            let gutter = max(AppTheme.height44, geometry.size.width * 0.15)
            HStack(spacing: 0) {
                Color.clear.frame(width: gutter)

                Spacer(minLength: AppTheme.spacing8)

                Text(title)
                    .font(.system(size: min(34, geometry.size.width * 0.085), weight: .bold))
                    .adaptiveForegroundColor()
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                Spacer(minLength: AppTheme.spacing8)

                trailing
                    .frame(width: gutter, alignment: .trailing)
            }
        }
        .frame(height: AppTheme.height44)
        .padding(.horizontal, AppTheme.spacing20)
        .padding(.top, AppTheme.spacing16)
    }
}

extension ScreenTitleHeader where Trailing == EmptyView {
    init(_ title: String) {
        self.init(title) { EmptyView() }
    }
}
