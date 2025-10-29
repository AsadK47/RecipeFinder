import ConfettiSwiftUI
import SwiftData
import SwiftUI

struct ContentView: View {
    @State private var recipes: [RecipeModel] = []
    @State private var selectedTab: Int = 0
    @StateObject private var shoppingListManager = ShoppingListManager()
    @AppStorage("appTheme") private var selectedTheme: AppTheme.ThemeType = .teal
    @Environment(\.colorScheme) var colorScheme
    
    // Performance: Cache the theme for the session
    private var themeBinding: AppTheme.ThemeType { selectedTheme }
    
    var body: some View {
        ZStack {
            AppTheme.backgroundGradient(for: themeBinding, colorScheme: colorScheme)
                .ignoresSafeArea()
            
            TabView(selection: $selectedTab) {
                RecipeSearchView(recipes: $recipes, shoppingListManager: shoppingListManager)
                    .tabItem {
                        Label("Recipes", systemImage: "book.fill")
                    }
                    .tag(0)

                KitchenView(recipes: $recipes, shoppingListManager: shoppingListManager)
                    .tabItem {
                        Label("Kitchen", systemImage: "refrigerator.fill")
                    }
                    .tag(1)

                ShoppingListView(manager: shoppingListManager)
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
            .environment(\.appTheme, themeBinding)
            .tint(AppTheme.accentColor(for: themeBinding))
            .onChange(of: selectedTab) { _, _ in
                HapticManager.shared.selection()
            }
        }
        .onAppear {
            // Load recipes only once on appear
            if recipes.isEmpty {
                loadRecipes()
            }
        }
    }

    private func loadRecipes() {
        recipes = PersistenceController.shared.fetchRecipes()
    }
}

#Preview {
    ContentView()
        .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
}
