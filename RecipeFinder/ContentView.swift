//
//  ContentView.swift
//  RecipeFinder
//
//  Created by asad.e.khan on 10/12/2024.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.colorScheme) var colorScheme
    @State private var recipes: [RecipeModel] = []
    
    var body: some View {
        TabView {
            RecipeSearchView(recipes: $recipes)
                .tabItem {
                    Label("Recipes", systemImage: "book")
                }
            
            IngredientSearchView(recipes: $recipes)
                .tabItem {
                    Label("Ingredients", systemImage: "leaf")
                }
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
                    Text("Recipe Finder").font(.largeTitle)
                    SearchBar(text: $searchText).padding(.horizontal)
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
                    Text("Search by ingredient").font(.largeTitle)
                    SearchBar(text: $searchText).padding(.horizontal)
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

struct SearchBar: View {
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

#Preview {
    ContentView()
}
