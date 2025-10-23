import SwiftUI

struct RecipeDetailView: View {
    @State private var recipe: RecipeModel
    @State private var ingredientsState: [Bool]
    @State private var expandedSections: Set<String> = ["Ingredients", "Pre-Prep", "Instructions", "Notes"]
    @ObservedObject var shoppingListManager: ShoppingListManager
    @State private var addedIngredients: Set<String> = []
    @State private var showAddedFeedback: String?
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.appTheme) var appTheme
    
    init(recipe: RecipeModel, shoppingListManager: ShoppingListManager) {
        self.recipe = recipe
        self.shoppingListManager = shoppingListManager
        _ingredientsState = State(initialValue: Array(repeating: false, count: recipe.ingredients.count))
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                AppTheme.backgroundGradient(for: appTheme, colorScheme: colorScheme)
                    .ignoresSafeArea()
                
                ScrollView(.vertical, showsIndicators: true) {
                    VStack(spacing: 0) {
                        // Title directly on gradient
                        Text(recipe.name)
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.horizontal, 20)
                            .padding(.top, 8)
                            .padding(.bottom, 20)
                    
                    // All info cards with consistent spacing
                    VStack(spacing: 16) {
                        GlassCard {
                            InfoPairView(
                                label1: "Prep time", value1: recipe.prepTime, icon1: "clock",
                                label2: "Cook time", value2: recipe.cookingTime, icon2: "flame"
                            )
                            .padding()
                        }
                        
                        GlassCard {
                            InfoPairView(
                                label1: "Difficulty", value1: recipe.difficulty, icon1: "chart.bar",
                                label2: "Category", value2: recipe.category, icon2: "fork.knife"
                            )
                            .padding()
                        }
                        
                        // Updated Servings Card with Icon
                        GlassCard {
                            HStack {
                                VStack(spacing: 8) {
                                    Image(systemName: "person.2.fill")
                                        .font(.title2)
                                        .foregroundColor(.cyan)
                                    Text("Servings")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text("\(recipe.currentServings)")
                                        .font(.title2)
                                        .fontWeight(.bold)
                                        .foregroundColor(.primary)
                                }
                                .frame(maxWidth: .infinity)
                                
                                Divider()
                                    .frame(height: 60)
                                    .padding(.horizontal)
                                
                                HStack(spacing: 12) {
                                    Button(action: {
                                        if recipe.currentServings > 1 {
                                            recipe.currentServings -= 1
                                        }
                                    }) {
                                        Image(systemName: "minus")
                                            .font(.system(size: 18, weight: .semibold))
                                            .foregroundColor(.white)
                                            .frame(width: 44, height: 44)
                                            .background(
                                                Circle()
                                                    .fill(AppTheme.accentColor)
                                            )
                                    }
                                    
                                    Button(action: {
                                        recipe.currentServings += 1
                                    }) {
                                        Image(systemName: "plus")
                                            .font(.system(size: 18, weight: .semibold))
                                            .foregroundColor(.white)
                                            .frame(width: 44, height: 44)
                                            .background(
                                                Circle()
                                                    .fill(AppTheme.accentColor)
                                            )
                                    }
                                }
                                .frame(maxWidth: .infinity)
                            }
                            .padding()
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // Collapsible Ingredients section
                    collapsibleSection(title: "Ingredients", icon: "leaf.fill") {
                        VStack(spacing: 12) {
                            ForEach(recipe.ingredients.indices, id: \.self) { index in
                                IngredientRowView(
                                    ingredient: recipe.ingredients[index],
                                    isChecked: ingredientsState[index],
                                    toggle: { ingredientsState[index].toggle() },
                                    scaleFactor: recipe.scaleFactor,
                                    onAddToShopping: {
                                        addIngredientToShoppingList(recipe.ingredients[index])
                                    },
                                    isInShoppingList: isIngredientInShoppingList(recipe.ingredients[index])
                                )
                            }
                        }
                    }
                    
                    // Collapsible Pre-prep section
                    if !recipe.prePrepInstructions.isEmpty {
                        collapsibleSection(title: "Pre-Prep", icon: "list.clipboard") {
                            VStack(alignment: .leading, spacing: 12) {
                                ForEach(recipe.prePrepInstructions.indices, id: \.self) { index in
                                    instructionRow(number: index + 1, text: recipe.prePrepInstructions[index])
                                }
                            }
                        }
                    }
                    
                    // Collapsible Instructions section
                    collapsibleSection(title: "Instructions", icon: "text.alignleft") {
                        VStack(alignment: .leading, spacing: 12) {
                            ForEach(recipe.instructions.indices, id: \.self) { index in
                                instructionRow(number: index + 1, text: recipe.instructions[index])
                            }
                        }
                    }
                    
                    // Collapsible Notes section
                    if !recipe.notes.isEmpty {
                        collapsibleSection(title: "Notes", icon: "note.text") {
                            VStack(alignment: .leading, spacing: 8) {
                                ForEach(recipe.notes.split(separator: "."), id: \.self) { sentence in
                                    if !sentence.trimmingCharacters(in: .whitespaces).isEmpty {
                                        HStack(alignment: .top, spacing: 8) {
                                            Image(systemName: "circle.fill")
                                                .font(.system(size: 6))
                                                .foregroundColor(.orange)
                                                .padding(.top, 6)
                                            Text(sentence.trimmingCharacters(in: .whitespaces))
                                                .font(.subheadline)
                                                .foregroundColor(.primary)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(.bottom, 100)
                .frame(width: geometry.size.width)
            }
            .scrollBounceBehavior(.basedOnSize, axes: .vertical)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .overlay(alignment: .bottom) {
            if let feedback = showAddedFeedback {
                HStack(spacing: 12) {
                    Image(systemName: "basket.fill")
                        .foregroundColor(.white)
                    Text("\(feedback) added to shopping list")
                        .font(.subheadline)
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(
                    Capsule()
                        .fill(AppTheme.accentColor)
                        .shadow(color: .black.opacity(0.2), radius: 8, y: 4)
                )
                .padding(.bottom, 100)
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .animation(.spring(response: 0.3), value: showAddedFeedback)
            }
        }
    }
    
    // COLLAPSIBLE section view with expand/collapse animation
    private func collapsibleSection<Content: View>(title: String, icon: String, @ViewBuilder content: () -> Content) -> some View {
        let isExpanded = expandedSections.contains(title)
        
        return VStack(alignment: .leading, spacing: 12) {
            // Tappable header
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    if isExpanded {
                        expandedSections.remove(title)
                    } else {
                        expandedSections.insert(title)
                    }
                }
            }) {
                HStack(spacing: 8) {
                    Image(systemName: icon)
                        .foregroundColor(.white)
                        .font(.title3)
                    Text(title)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    // Chevron indicator
                    Image(systemName: "chevron.down")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.white.opacity(0.8))
                        .rotationEffect(.degrees(isExpanded ? 0 : -90))
                        .animation(.spring(response: 0.3), value: isExpanded)
                }
                .padding(.top, 24)
            }
            .buttonStyle(PlainButtonStyle())
            
            // Collapsible content
            if isExpanded {
                GlassCard {
                    content()
                        .frame(maxWidth: .infinity, alignment: .leading) // Force full width
                        .padding(20)
                }
                .transition(.asymmetric(
                    insertion: .scale(scale: 0.95).combined(with: .opacity),
                    removal: .scale(scale: 0.95).combined(with: .opacity)
                ))
            }
        }
        .frame(maxWidth: .infinity) // Ensure container fills width
        .padding(.horizontal, 20)
    }
    
    private func instructionRow(number: Int, text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(number)")
                .font(.headline)
                .foregroundColor(.white)
                .frame(width: 32, height: 32)
                .background(
                    Circle()
                        .fill(AppTheme.accentColor)
                )
            
            Text(text)
                .font(.subheadline)
                .foregroundColor(.primary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading) // Ensure full width alignment
    }
    
    private func addIngredientToShoppingList(_ ingredient: Ingredient) {
        // Create item with ingredient name including quantity and unit as part of the name
        let scaledQuantity = ingredient.formattedQuantity(for: recipe.scaleFactor)
        let fullName = "\(ingredient.name) (\(scaledQuantity) \(ingredient.unit))"
        shoppingListManager.addItem(name: fullName, quantity: 1, category: nil)
        addedIngredients.insert(ingredient.name)
        
        // Show feedback briefly
        showAddedFeedback = ingredient.name
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            showAddedFeedback = nil
        }
    }
    
    private func isIngredientInShoppingList(_ ingredient: Ingredient) -> Bool {
        return shoppingListManager.items.contains { item in
            item.name.lowercased() == ingredient.name.lowercased()
        }
    }
}
