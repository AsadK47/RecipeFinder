import SwiftUI

/// An expandable category section in the ingredient browser. Groups similar
/// ingredients and lets the user drill into variations or add them to the
/// shopping list.
struct CategoryCard: View {
    let category: String
    let ingredients: [String]
    @Binding var addedIngredients: Set<String>
    let onSelectIngredient: (String) -> Void
    let onAddToShoppingList: (String) -> Void
    let getVariations: (String) -> [String]
    @State private var isExpanded = false
    @State private var expandedIngredients: Set<String> = []
    @Environment(\.colorScheme) var colorScheme
    @AppStorage("cardStyle") private var cardStyle: CardStyle = .frosted
    
    var categoryIcon: String {
        switch category {
        case "Meat": return "fork.knife.circle.fill"
        case "Seafood": return "fish.fill"
        case "Proteins": return "fork.knife"
        case "Vegetables": return "carrot.fill"
        case "Spices & Herbs": return "leaf.fill"
        case "Dairy & Eggs": return "cup.and.saucer.fill"
        case "Grains & Noodles": return "takeoutbag.and.cup.and.straw.fill"
        case "Sauces & Condiments": return "drop.fill"
        default: return "bag.fill"
        }
    }
    
    var categoryColor: Color {
        switch category {
        case "Meat": return .red
        case "Seafood": return .blue
        case "Proteins": return .red
        case "Vegetables": return .green
        case "Spices & Herbs": return .orange
        case "Dairy & Eggs": return .blue
        case "Grains & Noodles": return .yellow
        case "Sauces & Condiments": return .purple
        default: return AppTheme.accentColor
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            Button(
                action: {
                    withAnimation(.spring(response: 0.3)) {
                        isExpanded.toggle()
                    }
                },
                label: {
                    HStack(spacing: AppTheme.spacing16) {
                        ZStack {
                            Circle()
                                .fill(categoryColor.opacity(AppTheme.shadowDarkOpacity))
                                .frame(width: AppTheme.buttonHeight, height: AppTheme.height44)
                            
                            Image(systemName: categoryIcon)
                                .foregroundColor(categoryColor)
                                .font(.title3)
                        }
                        
                        VStack(alignment: .leading, spacing: AppTheme.spacing2) {
                            Text(category)
                                .font(.headline)
                                .adaptiveForegroundColor()
                            
                            Text("\(ingredients.count) ingredient\(ingredients.count == 1 ? "" : "s")")
                                .font(.caption)
                                .foregroundColor(AppTheme.adaptiveSubtitle(for: colorScheme))
                        }
                        
                        Spacer()
                        
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .foregroundColor(AppTheme.adaptiveSubtitle(for: colorScheme))
                            .font(.caption)
                    }
                    .padding(AppTheme.spacing16)
                    .background {
                        if cardStyle == .solid {
                            RoundedRectangle(cornerRadius: AppTheme.cornerRadius12)
                                .fill(AppTheme.cardBackground(for: colorScheme))
                        } else {
                            RoundedRectangle(cornerRadius: AppTheme.cornerRadius12)
                                .fill(.regularMaterial)
                        }
                    }
                }
            )
            .buttonStyle(PlainButtonStyle())
            
            if isExpanded {
                VStack(spacing: AppTheme.spacing8) {
                    ForEach(ingredients, id: \.self) { mainIngredient in
                        ingredientGroup(mainIngredient)
                    }
                }
                .padding(.top, AppTheme.spacing8)
            }
        }
    }
    
    private func ingredientGroup(_ mainIngredient: String) -> some View {
        let variations = getVariations(mainIngredient)
        let isGroupExpanded = expandedIngredients.contains(mainIngredient)
        
        return VStack(spacing: AppTheme.spacing4) {
            HStack(spacing: 0) {
                Button(
                    action: {
                        if variations.count > 1 {
                            withAnimation(.spring(response: 0.3)) {
                                if isGroupExpanded {
                                    expandedIngredients.remove(mainIngredient)
                                } else {
                                    expandedIngredients.insert(mainIngredient)
                                }
                            }
                        } else if variations.count == 1 {
                        onSelectIngredient(variations[0])
                    }
                }) {
                    HStack(spacing: AppTheme.spacing12) {
                        Text(mainIngredient)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(colorScheme == .dark ? .white.opacity(AppTheme.cardLightHighOpacity) : .black.opacity(0.9))
                        
                        if variations.contains(where: { KitchenInventoryManager.shared.hasItem($0) }) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.caption)
                                .foregroundColor(.green)
                        }
                        
                        if variations.count > 1 {
                            Text("(\(variations.count))")
                                .font(.caption)
                                .foregroundColor(AppTheme.adaptiveMediumEmphasis(for: colorScheme))
                        }
                        
                        Spacer()
                        
                        if variations.count > 1 {
                            Image(systemName: isGroupExpanded ? "chevron.up" : "chevron.down")
                                .font(.caption2)
                                .foregroundColor(AppTheme.adaptiveMediumEmphasis(for: colorScheme))
                        }
                    }
                    .padding(.horizontal, AppTheme.spacing16)
                    .padding(.vertical, AppTheme.spacing12)
                }
                .buttonStyle(PlainButtonStyle())
                
                if variations.count == 1 {
                    let ingredient = variations[0]
                    let isAdded = addedIngredients.contains(ingredient)
                    
                    Button(
                        action: {
                            onAddToShoppingList(ingredient)
                        },
                        label: {
                            Image(systemName: isAdded ? "basket.fill" : "basket")
                                .foregroundColor(isAdded ? AppTheme.accentColor : (AppTheme.adaptiveSubtitle(for: colorScheme)))
                                .font(.system(size: AppTheme.fontSize18))
                                .frame(width: AppTheme.buttonHeight, height: AppTheme.height44)
                                .scaleEffect(isAdded ? 1.2 : 1.0)
                                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isAdded)
                        }
                    )
                    .buttonStyle(PlainButtonStyle())
                    .padding(.trailing, AppTheme.spacing12)
                }
            }
            .background {
                if cardStyle == .solid {
                    RoundedRectangle(cornerRadius: AppTheme.cornerRadius8)
                        .fill(AppTheme.cardBackground(for: colorScheme))
                } else {
                    RoundedRectangle(cornerRadius: AppTheme.cornerRadius8)
                        .fill(.regularMaterial)
                }
            }
            
            if isGroupExpanded && variations.count > 1 {
                VStack(spacing: AppTheme.spacing4) {
                    ForEach(variations, id: \.self) { variation in
                        variationRow(variation)
                    }
                }
                .padding(.leading, AppTheme.spacing20)
            }
        }
    }
    
    private func variationRow(_ ingredient: String) -> some View {
        let isAdded = addedIngredients.contains(ingredient)
        
        return HStack(spacing: 0) {
            Button(
                action: {
                    onSelectIngredient(ingredient)
                },
                label: {
                    HStack(spacing: AppTheme.spacing12) {
                        Image(systemName: "circle.fill")
                            .font(.system(size: AppTheme.fontSize4))
                            .foregroundColor(AppTheme.adaptiveSecondaryIndicator(for: colorScheme))
                        
                        Text(ingredient)
                            .font(.subheadline)
                            .fontWeight(.regular)
                            .foregroundColor(AppTheme.adaptiveEmphasis(for: colorScheme, level: colorScheme == .dark ? 0.85 : 0.75))
                        
                        Spacer()
                    }
                    .padding(.horizontal, AppTheme.spacing16)
                    .padding(.vertical, AppTheme.spacing12)
                }
            )
            .buttonStyle(PlainButtonStyle())
            
            Button(
                action: {
                    onAddToShoppingList(ingredient)
                },
                label: {
                    Image(systemName: isAdded ? "basket.fill" : "basket")
                        .foregroundColor(isAdded ? AppTheme.accentColor : (AppTheme.adaptiveSubtitle(for: colorScheme)))
                        .font(.system(size: AppTheme.fontSize18))
                        .frame(width: AppTheme.buttonHeight, height: AppTheme.height44)
                        .scaleEffect(isAdded ? 1.2 : 1.0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isAdded)
                }
            )
            .buttonStyle(PlainButtonStyle())
            .padding(.trailing, AppTheme.spacing12)
        }
        .background {
            if cardStyle == .solid {
                RoundedRectangle(cornerRadius: AppTheme.cornerRadius8)
                    .fill(AppTheme.cardBackground(for: colorScheme))
            } else {
                RoundedRectangle(cornerRadius: AppTheme.cornerRadius8)
                    .fill(.regularMaterial)
            }
        }
    }
}
