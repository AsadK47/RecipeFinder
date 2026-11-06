import SwiftUI

/// Multi-select sheet for adding a recipe to collections; presented from `RecipeDetailToolbar`.
struct AddToCollectionSheet: View {
    let recipe: RecipeModel
    @Environment(\.collections) private var manager
    @State private var showNewCollection = false

    var body: some View {
        Group {
            if manager.collections.isEmpty {
                emptyState
            } else {
                collectionList
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showNewCollection = true
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("New Collection")
            }
        }
        .sheetDismissButton(placement: .cancellationAction)
        .sheet(isPresented: $showNewCollection) {
            NewCollectionSheet(manager: manager)
        }
        .sheetScaffold("Add to Collection")
    }

    private var collectionList: some View {
        List(manager.collections) { collection in
            let isMember = collection.contains(recipe.id)
            Button {
                manager.toggle(recipeID: recipe.id, in: collection)
            } label: {
                HStack(spacing: AppTheme.spacing12) {
                    CollectionDot(color: collection.colorName.swiftUIColor, iconFont: .caption)

                    VStack(alignment: .leading, spacing: AppTheme.spacing2) {
                        Text(collection.name)
                            .font(.body)
                            .foregroundStyle(.primary)

                        let count = collection.recipeIDs.count
                        Text(count == 1 ? "1 recipe" : "\(count) recipes")
                            .font(.caption)
                            .adaptiveSecondaryForeground()
                    }

                    Spacer()

                    Image(systemName: isMember ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(isMember ? collection.colorName.swiftUIColor : .secondary.opacity(0.4))
                        .font(.title3)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }

    private var emptyState: some View {
        EmptyStateView(
            icon: "rectangle.stack",
            title: "No Collections Yet",
            message: "Create a collection to group your recipes.",
            actionTitle: "Create Collection",
            actionIcon: "plus",
            onAction: { showNewCollection = true }
        )
        .frame(maxHeight: .infinity)
    }
}
