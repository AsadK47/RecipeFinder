import SwiftUI

/// Category multi-select sheet for filtering the ingredient browser.
struct IngredientFilterSheet: View {
    let categories: [String]
    @Binding var selectedCategories: Set<String>
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.appTheme) var appTheme
    
    var body: some View {
        NavigationView {
            ZStack {
                AppTheme.backgroundGradient(for: appTheme, colorScheme: colorScheme)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: AppTheme.spacing32) {
                        VStack(alignment: .leading, spacing: AppTheme.spacing12) {
                            Text("Ingredient Categories")
                                .font(.headline)
                                .adaptiveForegroundColor()
                                .padding(.horizontal, AppTheme.spacing20)
                            
                            LazyVGrid(columns: [
                                GridItem(.flexible()),
                                GridItem(.flexible())
                            ], spacing: AppTheme.spacing12) {
                                ForEach(categories, id: \.self) { category in
                                    FilterButton(
                                        label: category,
                                        icon: CategoryClassifier.categoryIcon(for: CategoryClassifier.suggestCategory(for: category.lowercased())),
                                        color: CategoryClassifier.categoryColor(for: CategoryClassifier.suggestCategory(for: category.lowercased())),
                                        isSelected: selectedCategories.contains(category)
                                    ) {
                                        if selectedCategories.contains(category) {
                                            selectedCategories.remove(category)
                                        } else {
                                            selectedCategories.insert(category)
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, AppTheme.spacing20)
                        }
                    }
                    .padding(.vertical, AppTheme.spacing20)
                }
            }
            .navigationTitle("Filter Ingredients")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .adaptiveForegroundColor()
                    .fontWeight(.semibold)
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    if !selectedCategories.isEmpty {
                        Button("Clear All") {
                            selectedCategories.removeAll()
                        }
                        .adaptiveForegroundColor()
                    }
                }
            }
        }
    }
}
