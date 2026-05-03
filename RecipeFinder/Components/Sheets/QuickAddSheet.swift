
import SwiftUI

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

struct ShoppingQuickAddSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) var colorScheme
    @AppStorage("appTheme") private var selectedTheme: AppTheme.ThemeType = .teal
    @AppStorage("cardStyle") private var cardStyle: CardStyle = .frosted
    @StateObject private var shoppingManager = ShoppingListManager.shared
    @StateObject private var kitchenManager = KitchenInventoryManager.shared
    
    var body: some View {
        ZStack {
            AppTheme.backgroundGradient(for: selectedTheme, colorScheme: colorScheme)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                HStack {
                    Text("Quick Add")
                        .font(.title2)
                        .fontWeight(.bold)
                        .adaptiveForegroundColor()
                        .shadow(color: .black.opacity(AppTheme.shadowDarkOpacity), radius: 2, x: 0, y: 1)
                    
                    Spacer()
                    
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .adaptiveForegroundColor(opacity: 0.9)
                            .shadow(color: .black.opacity(AppTheme.shadowDarkOpacity), radius: 2, x: 0, y: 1)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 16)
                
                ScrollView {
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: AppTheme.spacing12) {
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
            HStack(spacing: AppTheme.spacing8) {
                Text(item)
                    .font(.subheadline)
                    .adaptiveForegroundColor()
                
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

struct KitchenQuickAddSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) var colorScheme
    @AppStorage("appTheme") private var selectedTheme: AppTheme.ThemeType = .teal
    @AppStorage("cardStyle") private var cardStyle: CardStyle = .frosted
    @StateObject private var kitchenManager = KitchenInventoryManager.shared
    
    var body: some View {
        ZStack {
            AppTheme.backgroundGradient(for: selectedTheme, colorScheme: colorScheme)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                HStack {
                    Text("Quick Add")
                        .font(.title2)
                        .fontWeight(.bold)
                        .adaptiveForegroundColor()
                        .shadow(color: .black.opacity(AppTheme.shadowDarkOpacity), radius: 2, x: 0, y: 1)
                    
                    Spacer()
                    
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .adaptiveForegroundColor(opacity: 0.9)
                            .shadow(color: .black.opacity(AppTheme.shadowDarkOpacity), radius: 2, x: 0, y: 1)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 16)
                
                ScrollView {
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: AppTheme.spacing12) {
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
            HStack(spacing: AppTheme.spacing8) {
                Text(item)
                    .font(.subheadline)
                    .adaptiveForegroundColor()
                
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
