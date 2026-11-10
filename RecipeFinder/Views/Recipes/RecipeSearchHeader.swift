import SwiftUI

/// The screen title with a menu button (Collections + Filters), search field with the "+" add-recipe button, and a
/// one-time tip pointing at "+" (it replaced the Import tab).
struct RecipeSearchHeader: View {
    @Binding var searchText: String
    var isSearchFocused: FocusState<Bool>.Binding
    let activeFilterCount: Int
    /// Current cooking streak; the flame chip shows only when there's a live streak (nil/zero hides it).
    var streak: CookingStreak?
    let onToggleFilters: () -> Void
    let onShowCollections: () -> Void
    /// Tapping the streak chip opens the Cooking sheet (explains the streak + shows cooking-badge progress).
    var onShowStreak: () -> Void = {}
    /// Opens the add-recipe sheet (link, web search, paste, photo/PDF, other apps, manual).
    var onAdd: () -> Void = {}
    var showsAddTip = false
    var onDismissAddTip: () -> Void = {}

    var body: some View {
        VStack(spacing: AppTheme.spacing12) {
            headerSection
            searchBarSection
        }
    }

    private var headerSection: some View {
        ScreenTitleHeader("RecipeFinder") {
            filterMenu
        }
        // A compact flame badge floats in the top-left gutter (title stays centred, menu top-right) —
        // persistent + Duolingo-like, taking no vertical space of its own.
        .overlay(alignment: .topLeading) {
            if let streak, streak.currentWeeks > 0 {
                Button(action: onShowStreak) {
                    StreakChip(streak: streak)
                }
                .buttonStyle(.plain)
                .accessibilityHint("Shows what your cooking streak means and your badge progress")
                .padding(.leading, AppTheme.spacing20)
                .padding(.top, AppTheme.spacing16)
            }
        }
    }

    private var filterMenu: some View {
        CircleMenuButton(
            accessibilityLabel: activeFilterCount > 0 ? "Menu, ^[\(activeFilterCount) active filter](inflect: true)" : "Menu",
            badge: {
                if activeFilterCount > 0 {
                    Text("\(activeFilterCount)")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(3)
                        .background(.orange, in: Circle())
                        .offset(x: 4, y: -4)
                }
            }
        ) {
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
        }
    }

    private var searchBarSection: some View {
        VStack(spacing: AppTheme.spacing12) {
            HStack(spacing: AppTheme.spacing12) {
                AppSearchField(
                    text: $searchText,
                    placeholder: "What would you like to eat...?",
                    isFocused: isSearchFocused
                )
                CircleButton(icon: "plus", action: onAdd)
                    .accessibilityLabel("Add a recipe")
                    .accessibilityIdentifier("recipes.add")
            }
            if showsAddTip {
                addTip
            }
        }
        .padding(.horizontal, AppTheme.spacing20)
        .padding(.bottom, AppTheme.spacing12)
    }

    private var addTip: some View {
        HStack(alignment: .top, spacing: AppTheme.spacing12) {
            Image(systemName: "plus.circle.fill")
                .font(.title3)
                .foregroundStyle(.orange)
                .accessibilityHidden(true)
            Text("Add recipes with **+** — paste a link, search the web, scan a photo or PDF, bring your collection from another app, or write your own.")
                .font(.caption)
                .adaptiveForegroundColor()
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
            Button(action: onDismissAddTip) {
                Image(systemName: "xmark")
                    .font(.caption.weight(.semibold))
                    .adaptiveSecondaryForeground()
                    .frame(width: AppTheme.height44, height: AppTheme.height44)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Dismiss tip")
            .accessibilityIdentifier("recipes.addTip.dismiss")
        }
        .padding(.leading, AppTheme.spacing16)
        .appCard()
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("recipes.addTip")
    }
}
