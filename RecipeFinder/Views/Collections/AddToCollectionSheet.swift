import SwiftUI

/// Multi-select sheet for adding a recipe to one or more collections.
/// Presented from `RecipeDetailToolbar` via a binding on the detail view.
struct AddToCollectionSheet: View {
    let recipe: RecipeModel
    @ObservedObject private var manager = CollectionManager.shared
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("appTheme") private var selectedTheme: AppTheme.ThemeType = .teal
    @State private var showNewCollection = false

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.backgroundGradient(for: selectedTheme, colorScheme: colorScheme)
                    .ignoresSafeArea()

                Group {
                    if manager.collections.isEmpty {
                        emptyState
                    } else {
                        collectionList
                    }
                }
            }
            .navigationTitle("Add to Collection")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showNewCollection = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("New Collection")
                }
            }
            .sheet(isPresented: $showNewCollection) {
                NewCollectionSheet(manager: manager)
            }
        }
    }

    private var collectionList: some View {
        List(manager.collections) { collection in
            let isMember = collection.contains(recipe.id)
            Button {
                manager.toggle(recipeID: recipe.id, in: collection)
            } label: {
                HStack(spacing: AppTheme.spacing12) {
                    Circle()
                        .fill(collection.colorName.swiftUIColor)
                        .frame(width: 28, height: 28)
                        .overlay(
                            Image(systemName: "rectangle.stack.fill")
                                .font(.caption)
                                .foregroundColor(.white)
                        )

                    VStack(alignment: .leading, spacing: AppTheme.spacing2) {
                        Text(collection.name)
                            .font(.body)
                            .foregroundColor(.primary)

                        let count = collection.recipeIDs.count
                        Text(count == 1 ? "1 recipe" : "\(count) recipes")
                            .font(.caption)
                            .adaptiveSecondaryForeground()
                    }

                    Spacer()

                    Image(systemName: isMember ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(isMember ? collection.colorName.swiftUIColor : .secondary.opacity(0.4))
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
        VStack(spacing: AppTheme.spacing16) {
            Image(systemName: "rectangle.stack")
                .font(.system(size: AppTheme.fontSize50))
                .foregroundColor(.secondary.opacity(0.5))

            Text("No Collections Yet")
                .font(.title3.weight(.semibold))

            Button {
                showNewCollection = true
            } label: {
                Label("Create your first collection", systemImage: "plus")
                    .font(.subheadline)
                    .padding(.horizontal, AppTheme.spacing20)
                    .padding(.vertical, AppTheme.spacing12)
                    .background(.ultraThinMaterial, in: Capsule())
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
