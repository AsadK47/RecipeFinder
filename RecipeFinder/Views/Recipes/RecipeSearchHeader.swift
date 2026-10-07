import SwiftUI

/// The screen title with a menu button (Collections + Filters) and search field.
struct RecipeSearchHeader: View {
    @Binding var searchText: String
    var isSearchFocused: FocusState<Bool>.Binding
    let activeFilterCount: Int
    /// Current cooking streak; the flame chip shows only when there's a live streak (nil/zero hides it).
    var streak: CookingStreak?
    let onToggleFilters: () -> Void
    let onShowCollections: () -> Void

    var body: some View {
        VStack(spacing: AppTheme.spacing12) {
            headerSection
            streakRow
            searchBarSection
        }
    }

    private var headerSection: some View {
        ScreenTitleHeader("RecipeFinder") {
            filterMenu
        }
    }

    /// Slim left-aligned streak chip under the title — persistent + compact, without crowding the centered title.
    @ViewBuilder
    private var streakRow: some View {
        if let streak, streak.currentWeeks > 0 {
            HStack {
                StreakChip(streak: streak)
                Spacer()
            }
            .padding(.horizontal, AppTheme.spacing20)
        }
    }

    private var filterMenu: some View {
        Menu {
                Button(action: onShowCollections) {
                    Label("Collections", systemImage: "square.stack")
                }
                Divider()
                Button(action: onToggleFilters) {
                    Label(
                        activeFilterCount > 0 ? "Filters (\(activeFilterCount) active)" : "Filter Recipes",
                        systemImage: "line.3.horizontal.decrease"
                    )
                }
            } label: {
                CircleButton(icon: "line.3.horizontal") {}
                    .allowsHitTesting(false)
                    .overlay(alignment: .topTrailing) {
                        if activeFilterCount > 0 {
                            Text("\(activeFilterCount)")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(.white)
                                .padding(3)
                                .background(.orange, in: Circle())
                                .offset(x: 4, y: -4)
                        }
                    }
            }
            .buttonStyle(.plain)
            .accessibilityLabel(activeFilterCount > 0 ? "Menu, \(activeFilterCount) active filters" : "Menu")
    }

    private var searchBarSection: some View {
        AppSearchField(
            text: $searchText,
            placeholder: "What would you like to eat...?",
            isFocused: isSearchFocused
        )
        .padding(.horizontal, AppTheme.spacing20)
        .padding(.bottom, AppTheme.spacing12)
    }
}
