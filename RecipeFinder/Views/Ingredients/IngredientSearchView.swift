import SwiftUI

struct IngredientSearchView: View {
    @Binding var recipes: [RecipeModel]
    @State private var searchText = ""
    @State private var expandedSections: Set<String> = []
    @State private var viewMode: RecipeViewMode = .list
    @Environment(\.colorScheme) var colorScheme
    
    var groupedIngredients: [(key: String, value: [String])] {
        Dictionary(grouping: Set(recipes.flatMap { $0.ingredients.map { $0.name } })) {
            String($0.prefix(1).uppercased())
        }
        .mapValues { $0.sorted() }
        .sorted { $0.key < $1.key }
    }

    var filteredRecipes: [RecipeModel] {
        searchText.isEmpty ? recipes : recipes.filter { recipe in
            recipe.ingredients.contains { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    var gridColumns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: 12), count: viewMode.columns)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.backgroundGradient(for: colorScheme)
                    .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    VStack(spacing: 16) {
                        HStack {
                            // Empty spacer for alignment (only when menu is visible)
                            if !searchText.isEmpty {
                                Color.clear
                                    .frame(width: 48, height: 48)
                            }
                            
                            Spacer()
                            
                            Text("Search by Ingredient")
                                .font(.system(size: 34, weight: .bold))
                                .foregroundColor(.white)
                            
                            Spacer()
                            
                            if !searchText.isEmpty {
                                Menu {
                                    ForEach(RecipeViewMode.allCases, id: \.self) { mode in
                                        Button(action: {
                                            withAnimation(.spring(response: 0.3)) {
                                                viewMode = mode
                                            }
                                        }) {
                                            Label(mode.rawValue, systemImage: mode.icon)
                                        }
                                    }
                                } label: {
                                    Image(systemName: viewMode.icon)
                                        .font(.title2)
                                        .foregroundColor(.white)
                                        .padding(12)
                                        .background(
                                            Circle()
                                                .fill(.ultraThinMaterial)
                                        )
                                }
                            } else {
                                Color.clear
                                    .frame(width: 48, height: 48)
                            }
                        }
                        .padding(.horizontal, 20)
                        
                        ModernSearchBar(text: $searchText, placeholder: "What's in the fridge...?")
                            .padding(.horizontal, 20)
                    }
                    .padding(.top, 20)
                    
                    if searchText.isEmpty {
                        ingredientAlphabetView
                    } else {
                        recipeResultsView
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
        }
    }
    
    private var ingredientAlphabetView: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(groupedIngredients, id: \.key) { letter, ingredients in
                    CardView {
                        VStack(alignment: .leading, spacing: 0) {
                            // Header with letter
                            Button(action: {
                                withAnimation(.spring(response: 0.3)) {
                                    if expandedSections.contains(letter) {
                                        expandedSections.remove(letter)
                                    } else {
                                        expandedSections.insert(letter)
                                    }
                                }
                            }) {
                                HStack(spacing: 16) {
                                    // Letter circle icon
                                    ZStack {
                                        Circle()
                                            .fill(AppTheme.accentColor)
                                            .frame(width: 30, height: 30)
                                        
                                        Text(letter)
                                            .font(.system(size: 16, weight: .bold))
                                            .foregroundColor(.white)
                                    }
                                    
                                    Text("\(ingredients.count) ingredients")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundColor(.primary)
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.gray)
                                        .font(.caption)
                                        .rotationEffect(.degrees(expandedSections.contains(letter) ? 90 : 0))
                                        .animation(.spring(response: 0.3), value: expandedSections.contains(letter))
                                }
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            // Expanded ingredient list
                            if expandedSections.contains(letter) {
                                VStack(spacing: 0) {
                                    ForEach(Array(ingredients.enumerated()), id: \.element) { index, ingredient in
                                        VStack(spacing: 0) {
                                            Divider()
                                                .padding(.vertical, 8)
                                            
                                            Button(action: {
                                                searchText = ingredient
                                            }) {
                                                HStack(spacing: 16) {
                                                    Image(systemName: "leaf.fill")
                                                        .foregroundColor(AppTheme.accentColor.opacity(0.7))
                                                        .frame(width: 30)
                                                    
                                                    Text(ingredient)
                                                        .font(.subheadline)
                                                        .fontWeight(.medium)
                                                        .foregroundColor(.primary)
                                                    
                                                    Spacer()
                                                    
                                                    Image(systemName: "chevron.right")
                                                        .foregroundColor(AppTheme.accentColor.opacity(0.6))
                                                        .font(.caption)
                                                }
                                            }
                                            .buttonStyle(PlainButtonStyle())
                                        }
                                    }
                                }
                                .transition(.opacity.combined(with: .move(edge: .top)))
                            }
                        }
                        .padding()
                    }
                }
            }
            .padding()
        }
    }
    
    private var recipeResultsView: some View {
        ScrollView {
            if viewMode == .list {
                LazyVStack(spacing: 16) {
                    ForEach(filteredRecipes) { recipe in
                        NavigationLink(destination: RecipeDetailView(recipe: recipe)) {
                            RecipeCard(recipe: recipe, viewMode: .list)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal, 20)
            } else {
                LazyVGrid(columns: gridColumns, spacing: 16) {
                    ForEach(filteredRecipes) { recipe in
                        NavigationLink(destination: RecipeDetailView(recipe: recipe)) {
                            CompactRecipeCard(recipe: recipe)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
            }
        }
    }
}
