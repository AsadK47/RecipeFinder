import SwiftUI
import SwiftData
import ConfettiSwiftUI

// MARK: - Main Content View
struct ContentView: View {
    @State private var recipes: [RecipeModel] = []
    @State private var selectedTab: Int = 0
    @State private var shoppingListItems: [ShoppingListItem] = []
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        ZStack {
            AppTheme.backgroundGradient(for: colorScheme)
                .ignoresSafeArea()
            
            TabView(selection: $selectedTab) {
                RecipeSearchView(recipes: $recipes)
                    .tabItem {
                        Label("Recipes", systemImage: "book.fill")
                    }
                    .tag(0)

                IngredientSearchView(recipes: $recipes)
                    .tabItem {
                        Label("Ingredients", systemImage: "leaf.fill")
                    }
                    .tag(1)

                ShoppingListView(shoppingListItems: $shoppingListItems)
                    .tabItem {
                        Label("Shopping", systemImage: "cart.fill")
                    }
                    .tag(2)

                SettingsView()
                    .tabItem {
                        Label("Settings", systemImage: "gearshape.fill")
                    }
                    .tag(3)
            }
            .tint(AppTheme.accentColor)
        }
        .onAppear(perform: loadRecipes)
    }

    private func loadRecipes() {
        PersistenceController.shared.clearDatabase()
        PersistenceController.shared.populateDatabase()
        recipes = PersistenceController.shared.fetchRecipes()
    }
}

#Preview {
    ContentView()
}
