import SwiftUI

struct DietaryFilterView: View {
    @Binding var selectedFilters: Set<DietaryTag>
    let cardStyle: CardStyle
    let colorScheme: ColorScheme

    let commonFilters: [DietaryTag] = [
        .vegan, .vegetarian, .glutenFree, .dairyFree, .nutFree,
        .keto, .paleo, .lowCarb, .highProtein, .lowCalorie
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacing12) {
            Text("Dietary Filters")
                .font(.headline)
                .adaptiveForegroundColor()

            FlowLayout(spacing: AppTheme.spacing8) {
                ForEach(commonFilters, id: \.self) { filter in
                    DietaryFilterChip(
                        filter: filter,
                        isSelected: selectedFilters.contains(filter),
                        action: { toggleFilter(filter) }
                    )
                }
            }
        }
    }

    private func toggleFilter(_ filter: DietaryTag) {
        if selectedFilters.contains(filter) {
            selectedFilters.remove(filter)
        } else {
            selectedFilters.insert(filter)
        }
        HapticManager.shared.light()
    }
}
