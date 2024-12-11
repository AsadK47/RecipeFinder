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
    @State private var searchText = ""
    @State private var recipes: [RecipeModel] = []
    
    var filteredRecipes: [RecipeModel] {
        if searchText.isEmpty {
            return recipes
        } else {
            return recipes.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                VStack {
                    Spacer()
                        .frame(height: 5)
                    
                    Text("Recipe finder")
                        .font(.largeTitle)
                    
                    SearchBar(text: $searchText)
                        .padding(.horizontal)
                    
                    Spacer()
                        .frame(height: 15)
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
            .onAppear{
                loadRecipes()
            }
        }
    }
    
    private func loadRecipes() {
        PersistenceController.shared.clearDatabase()
        PersistenceController.shared.populateDatabaseIfNeeded()
        recipes = PersistenceController.shared.fetchRecipes()
    }
}

struct RecipeDetailView: View {
    let recipe: RecipeModel
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text(recipe.name)
                    .font(.title)
                    .bold()
                Divider()
                Text("Prep time")
                    .font(.headline)
                Text("\(recipe.prepTime)")
                Divider()
                Text("Cooking time")
                    .font(.headline)
                Text("\(recipe.cookingTime)")
                Divider()
                Text("Ingredients")
                    .font(.headline)
                HStack {
                    Text("Number of ingredients: ")
                        .font(.headline)
                    Text("\(recipe.ingredients.count)")
                        .font(.body)
                }
                ForEach(recipe.ingredients, id: \.self) { ingredient in
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.primary)
                        Text(ingredient)
                            .padding(.leading, 4)
                            .foregroundColor(.primary)
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
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.primary)
                            Text("\(sentence.trimmingCharacters(in: .whitespaces))")
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
