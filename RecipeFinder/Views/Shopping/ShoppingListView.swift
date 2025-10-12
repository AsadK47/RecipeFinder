import SwiftUI

struct ShoppingListView: View {
    @Binding var shoppingListItems: [ShoppingListItem]
    @State private var newItem: String = ""
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.backgroundGradient(for: colorScheme)
                    .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    VStack(spacing: 16) {
                        HStack {
                            // Left spacer for alignment
                            Color.clear
                                .frame(width: 48, height: 48)
                            
                            Spacer()
                            
                            Text("Shopping List")
                                .font(.system(size: 34, weight: .bold))
                                .foregroundColor(.white)
                            
                            Spacer()
                            
                            // Right spacer for alignment
                            Color.clear
                                .frame(width: 48, height: 48)
                        }
                        .padding(.horizontal, 20)
                        
                        ShoppingListInputBar(text: $newItem, onAdd: addItem)
                            .padding(.horizontal, 20)
                    }
                    .padding(.top, 20)
                    
                    if shoppingListItems.isEmpty {
                        emptyStateView
                    } else {
                        shoppingListContent
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "cart")
                .font(.system(size: 80))
                .foregroundColor(.white.opacity(0.5))
            
            Text("Your shopping list is empty")
                .font(.title3)
                .foregroundColor(.white)
            
            Text("Add items to get started")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.7))
        }
        .frame(maxHeight: .infinity)
    }
    
    private var shoppingListContent: some View {
        ScrollView(.vertical, showsIndicators: true) {
            LazyVStack(spacing: 12) {
                ForEach(shoppingListItems.indices, id: \.self) { index in
                    GlassCard {
                        HStack(spacing: 16) {
                            Button(action: { toggleItem(at: index) }) {
                                ZStack {
                                    Circle()
                                        .strokeBorder(
                                            shoppingListItems[index].isChecked ? AppTheme.accentColor : Color.gray,
                                            lineWidth: 2
                                        )
                                        .frame(width: 28, height: 28)
                                    
                                    if shoppingListItems[index].isChecked {
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 14, weight: .bold))
                                            .foregroundColor(.white)
                                            .frame(width: 28, height: 28)
                                            .background(Circle().fill(AppTheme.accentColor))
                                    }
                                }
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(shoppingListItems[index].name)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .strikethrough(shoppingListItems[index].isChecked)
                                    .foregroundColor(shoppingListItems[index].isChecked ? .gray : .primary)
                                
                                if shoppingListItems[index].quantity > 0 {
                                    Text("Quantity: \(shoppingListItems[index].quantity)")
                                        .font(.caption)
                                        .foregroundColor(AppTheme.secondaryText)
                                }
                            }
                            
                            Spacer()
                            
                            Stepper("", value: Binding(
                                get: { shoppingListItems[index].quantity },
                                set: { shoppingListItems[index].quantity = $0 }
                            ), in: 0...100)
                            .labelsHidden()
                        }
                        .padding()
                    }
                    .transition(.scale.combined(with: .opacity))
                    .contextMenu {
                        Button(role: .destructive) {
                            withAnimation {
                                _ = shoppingListItems.remove(at: index)
                            }
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
            .padding()
        }
    }
    
    private func addItem() {
        guard !newItem.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        withAnimation(.spring(response: 0.3)) {
            shoppingListItems.append(ShoppingListItem(name: newItem, isChecked: false, quantity: 1))
            newItem = ""
        }
    }

    private func toggleItem(at index: Int) {
        withAnimation(.spring(response: 0.3)) {
            shoppingListItems[index].isChecked.toggle()
        }
    }
}
