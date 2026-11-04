import SwiftUI

/// Sheet for adding kitchen ingredients by searching foods or browsing by category.
struct AddIngredientSheet: View {
    @Environment(\.dismiss) var dismiss
    @State private var searchText = ""
    @State private var selectedCategory: String? = nil
    
    var filteredCategories: [String] {
        if !searchText.isEmpty {
            return []
        }
        return FoodsList.categories
    }
    
    var searchResults: [String] {
        if searchText.isEmpty {
            return []
        }
        return FoodsList.searchFoods(query: searchText)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            SearchBar(text: $searchText, placeholder: "Search Foods...")
                .padding(.horizontal, AppTheme.spacing20)
                .padding(.top, AppTheme.spacing16)
                .padding(.bottom, AppTheme.spacing12)

            if !searchText.isEmpty {
                ScrollView {
                    LazyVStack(spacing: AppTheme.spacing8) {
                        ForEach(searchResults, id: \.self) { food in
                            foodButton(food)
                        }
                    }
                    .padding(.horizontal, AppTheme.spacing20)
                    .padding(.vertical, AppTheme.spacing12)
                }
            } else if let category = selectedCategory {
                ScrollView {
                    VStack(alignment: .leading, spacing: AppTheme.spacing16) {
                        Button(action: {
                            withAnimation {
                                selectedCategory = nil
                                HapticManager.shared.light()
                            }
                        }) {
                            HStack {
                                Image(systemName: "chevron.left")
                                Text("Back to Categories")
                            }
                            .foregroundStyle(AppTheme.accentColor)
                            .padding(.horizontal, AppTheme.spacing20)
                            .padding(.vertical, AppTheme.spacing8)
                        }

                        Text(category)
                            .font(.title2)
                            .fontWeight(.bold)
                            .adaptiveForegroundColor()
                            .padding(.horizontal, AppTheme.spacing20)

                        LazyVStack(spacing: AppTheme.spacing8) {
                            ForEach(FoodsList.getFoods(forCategory: category), id: \.self) { food in
                                foodButton(food)
                            }
                        }
                        .padding(.horizontal, AppTheme.spacing20)
                    }
                    .padding(.vertical, AppTheme.spacing12)
                }
            } else {
                ScrollView {
                    LazyVStack(spacing: AppTheme.spacing12) {
                        ForEach(filteredCategories, id: \.self) { category in
                            categoryButton(category)
                        }
                    }
                    .padding(.horizontal, AppTheme.spacing20)
                    .padding(.vertical, AppTheme.spacing12)
                }
            }
        }
        .sheetDismissButton()
        .sheetScaffold("Add Ingredients")
    }
    
    private func categoryButton(_ category: String) -> some View {
        Button(action: {
            withAnimation {
                selectedCategory = category
                HapticManager.shared.light()
            }
        }) {
            HStack(spacing: AppTheme.spacing12) {
                Image(systemName: CategoryClassifier.categoryIcon(for: category))
                    .font(.title3)
                    .foregroundStyle(CategoryClassifier.categoryColor(for: category))
                    .frame(width: AppTheme.iconSize40)
                
                VStack(alignment: .leading, spacing: AppTheme.spacing4) {
                    Text(category)
                        .font(.headline)
                        .adaptiveForegroundColor()
                    
                    Text("\(FoodsList.getFoods(forCategory: category).count) items")
                        .font(.caption)
                        .adaptiveSecondaryForeground()
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .adaptiveSecondaryForeground()
                    .font(.caption)
            }
            .padding(AppTheme.spacing16)
            .appCard(cornerRadius: AppTheme.cornerRadius12)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func foodButton(_ food: String) -> some View {
        let isInKitchen = KitchenInventoryManager.shared.hasItem(food)
        let category = FoodsList.getCategoryForFood(food) ?? "Other"
        
        return Button(action: {
            withAnimation(.appSpring) {
                let adding = !KitchenInventoryManager.shared.hasItem(food)
                KitchenInventoryManager.shared.toggleItem(food)
                HapticManager.shared.light()
                if adding {
                    dismiss()
                }
            }
        }) {
            HStack(spacing: AppTheme.spacing12) {
                Image(systemName: CategoryClassifier.categoryIcon(for: category))
                    .foregroundStyle(CategoryClassifier.categoryColor(for: category))
                    .font(.body)
                
                Text(food)
                    .font(.body)
                    .adaptiveForegroundColor()
                
                Spacer()
                
                Image(systemName: isInKitchen ? "checkmark.circle.fill" : "plus.circle")
                    .foregroundStyle(isInKitchen ? .green : AppTheme.accentColor)
                    .font(.title3)
            }
            .padding(.horizontal, AppTheme.spacing16)
            .padding(.vertical, AppTheme.spacing14)
            .appCard(cornerRadius: AppTheme.cornerRadius12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
