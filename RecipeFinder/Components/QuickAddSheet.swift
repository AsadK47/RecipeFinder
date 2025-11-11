//
//  QuickAddSheet.swift
//  RecipeFinder
//
//  Created on 1/11/2025.
//

import SwiftUI

// MARK: - Shared Quick Add Items
struct QuickAddItems {
    static let items = [
        "🍎 Apples",
        "🥑 Avocado",
        "🥓 Bacon",
        "🍌 Bananas",
        "🫘 Beans",
        "🥩 Beef",
        "🍞 Bread",
        "🧈 Butter",
        "🥕 Carrots",
        "🧀 Cheese",
        "🍗 Chicken",
        "☕️ Coffee",
        "🌽 Corn",
        "🥒 Cucumber",
        "🥚 Eggs",
        "🐟 Fish",
        "🧄 Garlic",
        "🍇 Grapes",
        "🥬 Lettuce",
        "🍋 Lemons",
        "🍋 Limes",
        "🍄 Mushrooms",
        "🥛 Milk",
        "🧅 Onions",
        "🍊 Oranges",
        "🍝 Pasta",
        "🫑 Peppers",
        "🥔 Potatoes",
        "🍚 Rice",
        "🥗 Salad",
        "🧂 Salt",
        "🥤 Soda",
        "🍓 Strawberries",
        "🍬 Sugar",
        "🥫 Tomato Sauce",
        "🍅 Tomatoes",
        "🦃 Turkey",
        "🍉 Watermelon",
        "🧈 Yogurt"
    ]
}

// MARK: - Shopping List Quick Add Sheet
struct ShoppingQuickAddSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) var colorScheme
    @AppStorage("appTheme") private var selectedTheme: AppTheme.ThemeType = .teal
    @AppStorage("cardStyle") private var cardStyle: CardStyle = .frosted
    @StateObject private var shoppingManager = ShoppingListManager.shared
    @StateObject private var kitchenManager = KitchenInventoryManager.shared
    
    var body: some View {
        ZStack {
            // Background gradient
            AppTheme.backgroundGradient(for: selectedTheme, colorScheme: colorScheme)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("Quick Add")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                    
                    Spacer()
                    
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 16)
                
                // Content
                ScrollView {
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 12) {
                        ForEach(QuickAddItems.items, id: \.self) { item in
                            quickAddButton(item)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            }
        }
    }
    
    private func quickAddButton(_ item: String) -> some View {
        let ingredient = item.split(separator: " ").dropFirst().joined(separator: " ")
        let isInList = shoppingManager.items.contains { $0.name.lowercased() == ingredient.lowercased() }
        
        return Button(action: {
            shoppingManager.addItem(name: String(ingredient))
            HapticManager.shared.success()
        }) {
            HStack(spacing: 8) {
                Text(item)
                    .font(.subheadline)
                    .foregroundColor(.white)
                
                Spacer()
                
                if isInList {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.body)
                        .foregroundColor(.green)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isInList ? Color.green.opacity(0.3) : Color.white.opacity(0.15))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isInList ? Color.green.opacity(0.5) : Color.white.opacity(0.3), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Kitchen Quick Add Sheet
struct KitchenQuickAddSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) var colorScheme
    @AppStorage("appTheme") private var selectedTheme: AppTheme.ThemeType = .teal
    @AppStorage("cardStyle") private var cardStyle: CardStyle = .frosted
    @StateObject private var kitchenManager = KitchenInventoryManager.shared
    
    var body: some View {
        ZStack {
            // Background gradient
            AppTheme.backgroundGradient(for: selectedTheme, colorScheme: colorScheme)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("Quick Add")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                    
                    Spacer()
                    
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 16)
                
                // Content
                ScrollView {
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 12) {
                        ForEach(QuickAddItems.items, id: \.self) { item in
                            quickAddButton(item)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            }
        }
    }
    
    private func quickAddButton(_ item: String) -> some View {
        let ingredient = item.split(separator: " ").dropFirst().joined(separator: " ")
        let isInKitchen = kitchenManager.items.contains { $0.name.lowercased() == ingredient.lowercased() }
        
        return Button(action: {
            kitchenManager.toggleItem(String(ingredient))
            HapticManager.shared.success()
        }) {
            HStack(spacing: 8) {
                Text(item)
                    .font(.subheadline)
                    .foregroundColor(.white)
                
                Spacer()
                
                if isInKitchen {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.body)
                        .foregroundColor(.green)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isInKitchen ? Color.green.opacity(0.3) : Color.white.opacity(0.15))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isInKitchen ? Color.green.opacity(0.5) : Color.white.opacity(0.3), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}
