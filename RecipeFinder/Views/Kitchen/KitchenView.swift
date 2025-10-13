import SwiftUI

enum KitchenTab: String, CaseIterable {
    case ingredients = "Browse"
    case pantry = "My Pantry"
}

struct KitchenView: View {
    @Binding var recipes: [RecipeModel]
    @ObservedObject var shoppingListManager: ShoppingListManager
    @StateObject private var pantryManager = PantryManager()
    @State private var selectedTab: KitchenTab = .ingredients
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.backgroundGradient(for: colorScheme)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Custom segmented control
                    HStack(spacing: 0) {
                        ForEach(KitchenTab.allCases, id: \.self) { tab in
                            Button(action: {
                                withAnimation(.spring(response: 0.3)) {
                                    selectedTab = tab
                                }
                            }) {
                                VStack(spacing: 8) {
                                    Text(tab.rawValue)
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(selectedTab == tab ? .white : .white.opacity(0.6))
                                    
                                    Rectangle()
                                        .fill(selectedTab == tab ? .white : .clear)
                                        .frame(height: 3)
                                }
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .background(
                        Color.clear
                    )
                    
                    // Content
                    TabView(selection: $selectedTab) {
                        IngredientSearchView(
                            recipes: $recipes,
                            shoppingListManager: shoppingListManager,
                            pantryManager: pantryManager
                        )
                        .tag(KitchenTab.ingredients)
                        
                        PantryView(
                            recipes: $recipes,
                            pantryManager: pantryManager
                        )
                        .tag(KitchenTab.pantry)
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
        }
    }
}
