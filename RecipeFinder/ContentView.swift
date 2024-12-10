//
//  ContentView.swift
//  RecipeFinder
//
//  Created by asad.e.khan on 10/12/2024.
//

import SwiftUI
import SwiftData

// Recipe model
struct Recipe: Identifiable {
    let id = UUID()
    let name: String
    let prepTime: String
    let ingredients: [String]
    let instructions: String
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

struct ContentView: View {
    @State private var searchText = ""
    @State private var recipes = [
        Recipe(name: "Spaghetti", prepTime: "30 min", ingredients: ["Pasta", "Tomato Sauce"], instructions: "Boil pasta, add sauce"),
        Recipe(name: "Pancakes", prepTime: "20 min", ingredients: ["Flour", "Milk", "Eggs"], instructions: "Mix ingredients and fry"),
        Recipe(name: "Salad", prepTime: "15 min", ingredients: ["Lettuce", "Tomatoes", "Cucumber"], instructions: "Chop ingredients and mix")
    ]
    
    var filteredRecipes: [Recipe] {
        if searchText.isEmpty {
            return recipes
        } else {
            return recipes.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                SearchBar(text: $searchText)
                
                List(filteredRecipes) { recipe in
                    NavigationLink(destination: RecipeDetailView(recipe: recipe)) {
                        Text(recipe.name)
                    }
                }
                .listStyle(PlainListStyle())
                .navigationTitle("Recipes")
                
            }
        }
    }
}

struct RecipeDetailView: View {
    let recipe: Recipe
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text(recipe.name)
                    .font(.title)
                    .bold()
                Text("Prep time: \(recipe.prepTime)")
                    .font(.subheadline)
                Divider()
                Text("Ingredients")
                    .font(.headline)
                ForEach(recipe.ingredients, id: \.self) { ingredient in
                    Text("* \(ingredient)")
                }
                Divider()
                Text("Instructions")
                    .font(.headline)
                Text(recipe.instructions)
            }
            .padding()
        }
        .navigationTitle(recipe.name)
    }
}

#Preview {
    ContentView()
}
