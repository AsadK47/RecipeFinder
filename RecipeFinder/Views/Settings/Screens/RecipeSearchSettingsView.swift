import SwiftUI

/// Which engine Recipes + → "Search the web" opens. Same stored choice as the picker on the search screen.
struct RecipeSearchSettingsView: View {
    @AppStorage("webSearchEngine") private var engineRaw = WebRecipeSearchEngine.default.rawValue

    var body: some View {
        SettingsScreen("Recipe Search") {
            VStack(spacing: AppTheme.spacing8) {
                SettingsSectionHeader(title: "Search Engine")

                SettingsCard {
                    VStack(spacing: 0) {
                        ForEach(Array(WebRecipeSearchEngine.allCases.enumerated()), id: \.element) { index, engine in
                            SettingsChoiceRow(
                                icon: engine.icon,
                                iconColor: .blue,
                                title: engine.displayName,
                                subtitle: engine.settingsSubtitle,
                                isSelected: engineRaw == engine.rawValue
                            ) {
                                engineRaw = engine.rawValue
                            }

                            if index < WebRecipeSearchEngine.allCases.count - 1 {
                                SettingsRowDivider()
                            }
                        }
                    }
                }

                Text("Searches and pages load straight from the site you pick. Browsing data isn't kept.")
                    .font(.footnote)
                    .adaptiveSecondaryForeground()
                    .padding(.horizontal, AppTheme.spacing4)
            }
        }
    }
}

private extension WebRecipeSearchEngine {
    var icon: String {
        switch self {
        case .duckDuckGo: "shield.lefthalf.filled"
        case .google: "magnifyingglass"
        case .bbcGoodFood: "fork.knife"
        }
    }

    var settingsSubtitle: String {
        switch self {
        case .duckDuckGo: "Private search, no tracking"
        case .google: "Web-wide results"
        case .bbcGoodFood: "Searches BBC Good Food's recipes"
        }
    }
}

#Preview {
    NavigationStack {
        RecipeSearchSettingsView()
    }
}
