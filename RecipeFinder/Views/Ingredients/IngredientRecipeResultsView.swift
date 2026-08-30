import SwiftUI

/// The recipe results shown after selecting an ingredient: a header with a back
/// button and a list/grid of matching recipes. Extracted from
/// `IngredientSearchView`.
struct IngredientRecipeResultsView: View {
    @Binding var selectedIngredient: String?
    @Binding var viewMode: RecipeViewMode
    let filteredRecipes: [RecipeModel]
    let cardStyle: CardStyle
    let colorScheme: ColorScheme

    private var gridColumns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: AppTheme.spacing12), count: viewMode.columns)
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button(
                    action: {
                        withAnimation(.spring(response: 0.3)) {
                            selectedIngredient = nil
                        }
                    },
                    label: {
                        HStack(spacing: AppTheme.spacing8) {
                            Image(systemName: "chevron.left")
                                .font(.body)
                            Text("Back")
                                .font(.body)
                        }
                        .adaptiveForegroundColor()
                    }
                )
                .padding(.horizontal, AppTheme.spacing20)
                .padding(.vertical, AppTheme.spacing12)
                
                Spacer()
                
                if !filteredRecipes.isEmpty {
                    Menu {
                        ForEach(RecipeViewMode.allCases, id: \.self) { mode in
                            Button(
                                action: {
                                    withAnimation(.spring(response: 0.3)) {
                                        viewMode = mode
                                    }
                                },
                                label: {
                                    Label(mode.rawValue, systemImage: mode.icon)
                                }
                            )
                        }
                    } label: {
                        Image(systemName: viewMode.icon)
                            .font(.title2)
                            .foregroundColor(cardStyle == .solid && colorScheme == .light ? .black : .white)
                            .padding(AppTheme.spacing12)
                            .background {
                                if cardStyle == .solid {
                                    Circle()
                                        .fill(AppTheme.cardBackground(for: colorScheme))
                                } else {
                                    Circle()
                                        .fill(.regularMaterial)
                                }
                            }
                    }
                    .padding(.horizontal, AppTheme.spacing20)
                }
            }
            
            if let ingredient = selectedIngredient {
                HStack(spacing: AppTheme.spacing12) {
                    Image(systemName: "leaf.fill")
                        .adaptiveForegroundColor()
                        .font(.title3)
                    
                    Text(ingredient)
                        .font(.title2)
                        .fontWeight(.bold)
                        .adaptiveForegroundColor()
                    
                    Spacer()
                    
                    Text("\(filteredRecipes.count) recipe\(filteredRecipes.count == 1 ? "" : "s")")
                        .font(.subheadline)
                        .adaptiveForegroundColor(opacity: AppTheme.highEmphasisOpacity)
                }
                .padding(.horizontal, AppTheme.spacing20)
                .padding(.bottom, AppTheme.spacing16)
            }
            
            ScrollView {
                if viewMode == .list {
                    LazyVStack(spacing: AppTheme.spacing16) {
                        ForEach(filteredRecipes) { recipe in
                            NavigationLink(destination: RecipeDetailView(recipe: recipe)) {
                                RecipeCard(recipe: recipe, viewMode: .list)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.horizontal, AppTheme.spacing20)
                } else {
                    LazyVGrid(columns: gridColumns, spacing: AppTheme.spacing16) {
                        ForEach(filteredRecipes) { recipe in
                            NavigationLink(destination: RecipeDetailView(recipe: recipe)) {
                                CompactRecipeCard(recipe: recipe)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.horizontal, AppTheme.spacing20)
                    .padding(.vertical, AppTheme.spacing8)
                }
            }
        }
    }
}
