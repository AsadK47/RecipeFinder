//
//  ContentView.swift
//  RecipeFinder
//
//  Created by asad.e.khan on 10/12/2024.
//

import SwiftUI
import SwiftData
import ConfettiSwiftUI

struct ShoppingListItem: Identifiable {
    let id = UUID()
    var name: String
    var isChecked: Bool
    var quantity: Int
}

struct ContentView: View {
    @State private var recipes: [RecipeModel] = []
    @State private var selectedTab: Int = 0
    @State private var shoppingListItems: [ShoppingListItem] = []

    var body: some View {
        VStack {
            ZStack {
                if selectedTab == 0 {
                    RecipeSearchView(recipes: $recipes)
                } else if selectedTab == 1 {
                    IngredientSearchView(recipes: $recipes)
                } else if selectedTab == 2 {
                    ShoppingListView(shoppingListItems: $shoppingListItems)
                } else if selectedTab == 3 {
                    SettingsView()
                }
            }

            Divider()

            HStack {
                ForEach(0..<4, id: \.self) { index in
                    Button(action: {
                        selectedTab = index
                    }) {
                        VStack {
                            Image(systemName: getTabIcon(for: index))
                                .foregroundColor(selectedTab == index ? .blue : .gray)
                            Text(getTabLabel(for: index))
                                .foregroundColor(selectedTab == index ? .blue : .gray)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color(UIColor.systemBackground))
        }
        .onAppear {
            loadRecipes()
        }
    }

    private func loadRecipes() {
        PersistenceController.shared.clearDatabase()
        PersistenceController.shared.populateDatabase()
        recipes = PersistenceController.shared.fetchRecipes()
    }

    private func getTabIcon(for index: Int) -> String {
        switch index {
        case 0: return "book"
        case 1: return "leaf"
        case 2: return "cart"
        case 3: return "gearshape"
        default: return "questionmark.circle"
        }
    }

    private func getTabLabel(for index: Int) -> String {
        switch index {
        case 0: return "Recipes"
        case 1: return "Ingredients"
        case 2: return "Shopping"
        case 3: return "Settings"
        default: return "Unknown"
        }
    }
}

struct RecipeSearchView: View {
    @Binding var recipes: [RecipeModel]
    @State private var searchText = ""
    @Environment(\.colorScheme) var colorScheme

    var filteredRecipes: [RecipeModel] {
        if searchText.isEmpty {
            return recipes
        } else {
            return recipes.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
    }

    var body: some View {
        NavigationStack {
            VStack {
                VStack {
                    Spacer().frame(height: 5)
                    Text("Recipe Finder")
                        .font(.largeTitle)
                    RecipeSearchBar(text: $searchText)
                        .padding(.horizontal)
                    Spacer().frame(height: 15)
                }

                List(filteredRecipes) { recipe in
                    NavigationLink(destination: RecipeDetailView(recipe: recipe)) {
                        Text(recipe.name)
                            .foregroundColor(.primary)
                            .background(colorScheme == .dark ? Color.black : Color.white)
                            .cornerRadius(8)
                    }
                    .listRowSeparator(.hidden)
                }
                .listStyle(PlainListStyle())
            }
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct IngredientSearchView: View {
    @Binding var recipes: [RecipeModel]
    @State private var searchText = ""
    @Environment(\.colorScheme) var colorScheme
    @State private var expandedSections: Set<String> = []
    
    var groupedIngredients: [String: [String]] {
        Dictionary(grouping: Set(recipes.flatMap { $0.ingredients.map {$0.name }})) { ingredient in
            String(ingredient.prefix(1).uppercased())
        }
        .mapValues { $0.sorted() }
        .sorted { $0.key < $1.key }
        .reduce(into: [String: [String]]()) { $0[$1.key] = $1.value }
    }

    var filteredRecipes: [RecipeModel] {
        if searchText.isEmpty {
            return recipes
        } else {
            return recipes.filter { recipe in
                recipe.ingredients.contains { $0.name.localizedCaseInsensitiveContains(searchText) }
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                VStack {
                    Spacer().frame(height: 5)
                    Text("Search by ingredient")
                        .font(.largeTitle)
                    IngredientSearchBar(text: $searchText)
                        .padding(.horizontal)
                    Spacer().frame(height: 15)
                }
                
                if searchText.isEmpty {
                    if groupedIngredients.isEmpty {
                        Text("No ingredients available")
                            .foregroundColor(.gray)
                            .padding()
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 10) {
                                ForEach(groupedIngredients.keys.sorted(), id: \.self) { letter in
                                    DisclosureGroup(
                                        isExpanded: Binding(
                                            get: { expandedSections.contains(letter) },
                                            set: { isExpanded in
                                                if isExpanded {
                                                    expandedSections.insert(letter)
                                                } else {
                                                    expandedSections.remove(letter)
                                                }
                                            }
                                        ),
                                        content: {
                                            LazyVStack(spacing: 10) {
                                                ForEach(groupedIngredients[letter] ?? [], id: \.self) { ingredient in
                                                    IngredientButton(ingredient: ingredient) {
                                                        searchText = ingredient
                                                    }
                                                }
                                            }
                                        },
                                        label: {
                                            Text(letter)
                                                .font(.headline)
                                                .padding(.leading, 10)
                                                .frame(maxWidth: .infinity, alignment: .leading)
                                        }
                                    )
                                    .padding(.vertical, 5)
                                }
                            }
                            .padding()
                        }
                    }
                } else {
                    List(filteredRecipes) { recipe in
                        NavigationLink(destination: RecipeDetailView(recipe: recipe)) {
                            Text(recipe.name)
                                .foregroundColor(.primary)
                                .background(colorScheme == .dark ? Color.black : Color.white)
                                .cornerRadius(8)
                        }
                        .listRowSeparator(.hidden)
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct IngredientButton: View {
    let ingredient: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(ingredient)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(UIColor.systemGray5))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.gray, lineWidth: 1)
                )
        }
    }
}

struct RecipeDetailView: View {
    @State private var recipe: RecipeModel
    @State private var ingredientsState: [Bool]
    
    init(recipe: RecipeModel) {
        self.recipe = recipe
        _ingredientsState = State(initialValue: Array(repeating: false, count: recipe.ingredients.count))
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text(recipe.name)
                    .font(.title)
                    .bold()
                    .frame(maxWidth: .infinity, alignment: .center)
                
                Divider()
                
                HStack {
                    VStack(alignment: .leading) {
                        Text("Prep time")
                            .font(.headline)
                            .frame(maxWidth: .infinity, alignment: .center)
                        Text("\(recipe.prepTime)")
                            .frame(maxWidth: .infinity, alignment: .center)
                    }.frame(maxWidth: .infinity)
                    
                    Divider().frame(height: 50)
                    
                    VStack(alignment: .leading) {
                        Text("Cooking time").font(.headline).frame(maxWidth: .infinity, alignment: .center)
                        Text("\(recipe.cookingTime)").frame(maxWidth: .infinity, alignment: .center)
                    }.frame(maxWidth: .infinity)
                }
                
                Divider()
                
                HStack {
                    VStack(alignment: .leading) {
                        Text("Difficulty")
                            .font(.headline)
                            .frame(maxWidth: .infinity, alignment: .center)
                        Text("\(recipe.difficulty)")
                            .frame(maxWidth: .infinity, alignment: .center)
                    }.frame(maxWidth: .infinity)
                    
                    Divider().frame(height: 50)
                    
                    VStack(alignment: .leading) {
                        Text("Category")
                            .font(.headline)
                            .frame(maxWidth: .infinity, alignment: .center)
                        Text("\(recipe.category)")
                            .frame(maxWidth: .infinity, alignment: .center)
                    }.frame(maxWidth: .infinity)
                }
                
                Divider()
                
                HStack {
                    Text("Servings")
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .center)
                    Spacer()
                    Stepper(value: $recipe.currentServings, in: 1...100, step: 1) {
                        Text("\(recipe.currentServings)")
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                    .onChange(of: recipe.currentServings) { oldValue, newValue in
                        adjustIngredients(for: newValue)
                    }
                }
                
                Divider()
                
                Text("Ingredients")
                    .font(.headline)
                
                ForEach(recipe.ingredients.indices, id: \.self) { index in
                    HStack {
                        // Checkmark toggle
                        Image(systemName: ingredientsState[index] ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(ingredientsState[index] ? .green : .primary)
                            .onTapGesture {
                                withAnimation {
                                    ingredientsState[index].toggle()
                                }
                            }
                        
                        // Ingredient details
                        Text("\(String(format: "%.2f", recipe.ingredients[index].quantity)) \(recipe.ingredients[index].unit) \(recipe.ingredients[index].name)")
                            .padding(.leading, 4)
                            .foregroundColor(.primary)
                            .strikethrough(ingredientsState[index])
                    }
                }
       
                Divider()
                
                Text("Pre-Prep Instructions")
                    .font(.headline)
                ForEach(recipe.prePrepInstructions.indices, id: \.self) { index in
                    Text("\(index + 1). \(recipe.prePrepInstructions[index])")
                }
                
                Divider()
                
                Text("Instructions")
                    .font(.headline)
                ForEach(recipe.instructions.indices, id: \.self) { index in
                    Text("\(index + 1). \(recipe.instructions[index])")
                }
                
                Divider()
                
                Text("Notes")
                    .font(.headline)
                ForEach(recipe.notes.split(separator: "."), id: \.self) { sentence in
                    if !sentence.trimmingCharacters(in: .whitespaces).isEmpty {
                        HStack(alignment: .top) {
                            Text("•")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.primary)
                            Text(sentence.trimmingCharacters(in: .whitespaces))
                                .padding(.leading, 2)
                                .foregroundColor(.primary)
                        }
                    }
                }
            }
            .padding()
        }
        .navigationTitle(recipe.name)
    }
    
    private func adjustIngredients(for newServings: Int) {
        let factor = Double(newServings) / Double(recipe.baseServings)
        recipe.ingredients = recipe.ingredients.map { ingredient in
            var updatedIngredient = ingredient
            updatedIngredient.quantity = ingredient.baseQuantity * factor
            return updatedIngredient
        }
    }
}

struct ShoppingListView: View {
    @Binding var shoppingListItems: [ShoppingListItem]
    @State private var newItem: String = ""
    
    var body: some View {
        NavigationStack {
            VStack {
                Text("Shopping List")
                    .font(.largeTitle)
                    .padding()
                
                HStack {
                    TextField("Add item...", text: $newItem)
                        .padding(7)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    
                    Button(action: addItem) {
                        Text("Add")
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(8)
                    }
                }.padding()
                
                List {
                    ForEach(shoppingListItems.indices, id: \.self) { index in
                        HStack {
                            Image(systemName: shoppingListItems[index].isChecked ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(shoppingListItems[index].isChecked ? .green : .gray)
                                .onTapGesture {
                                    toggleItem(at: index)
                                }
                            
                            Text(shoppingListItems[index].name)
                                .strikethrough(shoppingListItems[index].isChecked, color: .gray)
                                .foregroundColor(shoppingListItems[index].isChecked ? .gray : .primary)
                            
                            Spacer()
                            
                            Stepper(value: $shoppingListItems[index].quantity, in: 0...100, step: 1) {
                                Text("\(shoppingListItems[index].quantity)")
                            }.frame(width: 120)
                            
                        }
                    }.onDelete(perform: deleteItems)
                }
            }.navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private func addItem() {
        guard !newItem.isEmpty else { return }
        let newShoppingItem = ShoppingListItem(name: newItem, isChecked: false, quantity: 0)
        shoppingListItems.append(newShoppingItem)
        newItem = ""
    }

    private func deleteItems(at offsets: IndexSet) {
        shoppingListItems.remove(atOffsets: offsets)
    }

    private func toggleItem(at index: Int) {
        shoppingListItems[index].isChecked.toggle()
    }
}

struct RecipeSearchBar: View {
    @Binding var text: String
    var body: some View {
        HStack {
            TextField("What would you like to eat...?", text: $text)
                .padding(7)
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .padding(.horizontal)
            if !text.isEmpty {
                Button("Cancel") {
                    text = ""
                }
                .padding(.trailing, 10)
                .transition(.move(edge: .trailing))
                .animation(.default, value: text.isEmpty)
            }
        }
    }
}

struct IngredientSearchBar: View {
    @Binding var text: String
    var body: some View {
        HStack {
            TextField("What's in the fridge...?", text: $text)
                .padding(7)
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .padding(.horizontal)
            if !text.isEmpty {
                Button("Cancel") {
                    text = ""
                }
                .padding(.trailing, 10)
                .transition(.move(edge: .trailing))
                .animation(.default, value: text.isEmpty)
            }
        }
    }
}

struct SettingsView: View {
    @State private var fireworkTrigger: Int = 0
    
    var body: some View {
        VStack {
            Text("Settings")
                .font(.largeTitle)
                .padding()
            
            Button(action: {
                fireworkTrigger += 1
            }) {
                Text("Party time!")
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding()
            .confettiCannon(trigger: $fireworkTrigger)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    ContentView()
}
