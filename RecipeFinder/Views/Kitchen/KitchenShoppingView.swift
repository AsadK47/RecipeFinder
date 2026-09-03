import SwiftUI

/// Merged "Kitchen & Shopping" tab: two views of the same food-item world —
/// what you need to buy (Shopping) and what you already have (Kitchen) — under a
/// single segmented switch and one navigation container.
struct KitchenShoppingView: View {
    @Binding var recipes: [RecipeModel]

    @State private var segment: Segment = .shopping
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("appTheme") private var selectedTheme: AppTheme.ThemeType = .teal

    private enum Segment: String, CaseIterable, Identifiable {
        case shopping = "Shopping"
        case kitchen = "Kitchen"
        var id: String { rawValue }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.backgroundGradient(for: selectedTheme, colorScheme: colorScheme)
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    Picker("View", selection: $segment) {
                        ForEach(Segment.allCases) { segment in
                            Text(segment.rawValue).tag(segment)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, AppTheme.spacing20)
                    .padding(.top, AppTheme.spacing12)
                    .padding(.bottom, AppTheme.spacing8)
                    .onChange(of: segment) { _, _ in HapticManager.shared.selection() }

                    switch segment {
                    case .shopping:
                        ShoppingListView()
                    case .kitchen:
                        KitchenView(recipes: $recipes)
                    }
                }
            }
            .toolbar(.hidden, for: .navigationBar)
        }
    }
}

#Preview {
    KitchenShoppingView(recipes: .constant([]))
        .environment(\.appTheme, .teal)
}
