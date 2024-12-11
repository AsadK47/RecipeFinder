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
                    Text("Recipe finder")
                        .font(.largeTitle)
                        .padding(.top, 40)
                    SearchBar(text: $searchText)
                        .padding(.horizontal)
                }
            
                List(filteredRecipes) { recipe in
                    NavigationLink(destination: RecipeDetailView(recipe: recipe)) {
                        Text(recipe.name)
                            .foregroundColor(.primary)
//                            .padding(5)
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
