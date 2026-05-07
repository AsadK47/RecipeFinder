import SwiftUI

struct QuickAddSheetView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) var colorScheme
    @AppStorage("appTheme") private var selectedTheme: AppTheme.ThemeType = .teal

    let isItemAdded: (String) -> Bool
    let onAdd: (String) -> Void

    private enum Layout {
        static let headerHorizontalPadding: CGFloat = AppTheme.spacing20
        static let headerTopPadding: CGFloat = AppTheme.spacing20
        static let headerBottomPadding: CGFloat = AppTheme.spacing16
        static let gridHorizontalPadding: CGFloat = AppTheme.spacing20
        static let gridBottomPadding: CGFloat = AppTheme.spacing40
        static let buttonHorizontalPadding: CGFloat = AppTheme.spacing16
        static let buttonVerticalPadding: CGFloat = 14
        static let buttonCornerRadius: CGFloat = AppTheme.cornerRadius12
        static let buttonLineWidth: CGFloat = 1
        static let dismissButtonOpacity: Double = 0.9
        static let selectedFillOpacity: Double = 0.3
        static let unselectedFillOpacity: Double = 0.15
        static let selectedStrokeOpacity: Double = 0.5
        static let unselectedStrokeOpacity: Double = 0.3
    }

    var body: some View {
        ZStack {
            AppTheme.backgroundGradient(for: selectedTheme, colorScheme: colorScheme)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    Text("Quick Add")
                        .font(.title2)
                        .fontWeight(.bold)
                        .adaptiveForegroundColor()
                        .shadow(color: .black.opacity(AppTheme.shadowDarkOpacity), radius: AppTheme.shadowRadiusSmall, x: 0, y: AppTheme.shadowOffsetSmall)

                    Spacer()

                    Button { dismiss() } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .adaptiveForegroundColor(opacity: Layout.dismissButtonOpacity)
                            .shadow(color: .black.opacity(AppTheme.shadowDarkOpacity), radius: AppTheme.shadowRadiusSmall, x: 0, y: AppTheme.shadowOffsetSmall)
                    }
                }
                .padding(.horizontal, Layout.headerHorizontalPadding)
                .padding(.top, Layout.headerTopPadding)
                .padding(.bottom, Layout.headerBottomPadding)

                ScrollView {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: AppTheme.spacing12) {
                        ForEach(QuickAddItems.items, id: \.self) { item in
                            quickAddButton(item)
                        }
                    }
                    .padding(.horizontal, Layout.gridHorizontalPadding)
                    .padding(.bottom, Layout.gridBottomPadding)
                }
            }
        }
    }

    private func ingredientName(from item: String) -> String {
        item.split(separator: " ").dropFirst().joined(separator: " ")
    }

    private func quickAddButton(_ item: String) -> some View {
        let ingredient = ingredientName(from: item)
        let isAdded = isItemAdded(ingredient)

        return Button(action: { onAdd(ingredient) }) {
            HStack(spacing: AppTheme.spacing8) {
                Text(item)
                    .font(.subheadline)
                    .adaptiveForegroundColor()

                Spacer()

                if isAdded {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.body)
                        .foregroundColor(.green)
                }
            }
            .padding(.horizontal, Layout.buttonHorizontalPadding)
            .padding(.vertical, Layout.buttonVerticalPadding)
            .background(
                RoundedRectangle(cornerRadius: Layout.buttonCornerRadius)
                    .fill(isAdded ? Color.green.opacity(Layout.selectedFillOpacity) : Color.white.opacity(Layout.unselectedFillOpacity))
                    .overlay(
                        RoundedRectangle(cornerRadius: Layout.buttonCornerRadius)
                            .stroke(isAdded ? Color.green.opacity(Layout.selectedStrokeOpacity) : Color.white.opacity(Layout.unselectedStrokeOpacity), lineWidth: Layout.buttonLineWidth)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}
