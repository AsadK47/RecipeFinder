import ConfettiSwiftUI
import SwiftData
import SwiftUI

struct ContentView: View {
    @State private var recipes: [RecipeModel] = []
    @State private var selectedTab: Int = 0
    @StateObject private var shoppingListManager = ShoppingListManager()
    @AppStorage("appTheme") private var selectedTheme: AppTheme.ThemeType = .teal // Changed to teal default
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ZStack {
            AppTheme.backgroundGradient(for: selectedTheme, colorScheme: colorScheme)
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
            .environment(\.appTheme, selectedTheme)
            .tint(AppTheme.accentColor(for: selectedTheme))
            .onChange(of: selectedTab) { _, _ in
                HapticManager.shared.selection()
            }
            .gesture(
                DragGesture(minimumDistance: 50)
                    .onEnded { value in
                        let horizontalSwipe = value.translation.width
                        
                        // Swipe right (go to previous tab)
                        if horizontalSwipe > 0 && selectedTab > 0 {
                            withAnimation {
                                selectedTab -= 1
                            }
                        }
                        // Swipe left (go to next tab)
                        else if horizontalSwipe < 0 && selectedTab < 3 {
                            withAnimation {
                                selectedTab += 1
                            }
                        }
                    }
            )
        }
        .onAppear {
            loadRecipes()
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
