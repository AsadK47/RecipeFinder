import SwiftUI

/// The collections grid rendered inside `RecipeSearchView`'s existing
/// `NavigationStack`. Does not own a `NavigationStack` itself — navigation
/// links push onto the parent stack.
struct CollectionsInlineView: View {
    @Binding var recipes: [RecipeModel]
    @Environment(\.collections) private var manager
    @State private var showNewCollection = false
    @State private var collectionToEdit: RecipeCollection?
    @State private var collectionToDelete: RecipeCollection?
    /// Only smart collections with at least one matching recipe.
    @State private var visibleSmartCollections: [(SmartCollection, Int)] = []

    private let columns = [
        GridItem(.flexible(), spacing: AppTheme.spacing12),
        GridItem(.flexible(), spacing: AppTheme.spacing12)
    ]

    var body: some View {
        Group {
            if visibleSmartCollections.isEmpty && manager.collections.isEmpty {
                emptyState
            } else {
                collectionGrid
            }
        }
        .onAppear { updateSmartCollections() }
        .onChange(of: recipes.count) { _, _ in updateSmartCollections() }
        .sheet(isPresented: $showNewCollection) {
            NewCollectionSheet(manager: manager)
        }
        .sheet(item: $collectionToEdit) { collection in
            EditCollectionSheet(collection: collection, manager: manager)
        }
        .alert("Delete Collection", isPresented: Binding(
            get: { collectionToDelete != nil },
            set: { if !$0 { collectionToDelete = nil } }
        )) {
            Button("Delete", role: .destructive) {
                if let c = collectionToDelete { manager.delete(c) }
                collectionToDelete = nil
            }
            Button("Cancel", role: .cancel) { collectionToDelete = nil }
        } message: {
            Text("\u{201c}\(collectionToDelete?.name ?? "")\u{201d} will be deleted. Your recipes won't be affected.")
        }
    }

    private var collectionGrid: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: AppTheme.spacing12) {

                // Smart collections first — auto-populated, read-only
                ForEach(visibleSmartCollections, id: \.0.id) { (sc, count) in
                    NavigationLink {
                        SmartCollectionDetailView(smartCollection: sc, recipes: $recipes)
                    } label: {
                        SmartCollectionCard(collection: sc, recipeCount: count)
                    }
                    .buttonStyle(.plain)
                }

                // User-created collections
                ForEach(manager.collections) { collection in
                    NavigationLink {
                        CollectionDetailView(collection: collection, recipes: $recipes)
                    } label: {
                        CollectionCard(
                            collection: collection,
                            recipeCount: collection.recipeIDs.count
                        )
                        .contextMenu {
                            Button {
                                collectionToEdit = collection
                            } label: {
                                Label("Rename / Recolour", systemImage: "pencil")
                            }
                            Button(role: .destructive) {
                                collectionToDelete = collection
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }

                Button {
                    HapticManager.shared.light()
                    showNewCollection = true
                } label: {
                    VStack(spacing: AppTheme.spacing8) {
                        Image(systemName: "plus")
                            .font(.title2.weight(.semibold))
                        Text("New Collection")
                            .font(.caption.weight(.medium))
                    }
                    .frame(maxWidth: .infinity, minHeight: 80)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: AppTheme.cornerRadius12))
                }
                .foregroundStyle(.primary.opacity(0.5))
                .buttonStyle(.plain)
                .accessibilityLabel("New Collection")
            }
            .padding(.horizontal, AppTheme.spacing16)
            .padding(.top, AppTheme.spacing8)
            .padding(.bottom, AppTheme.spacing100)
        }
    }

    private var emptyState: some View {
        EmptyStateView(
            icon: "rectangle.stack",
            title: "No Collections Yet",
            message: "Create collections to organise your recipes \u{2014} \u{201c}Weeknight Dinners\u{201d}, \u{201c}Party Food\u{201d}, whatever works for you.",
            actionTitle: "Create Collection",
            actionIcon: "plus",
            onAction: { showNewCollection = true }
        )
        .frame(maxHeight: .infinity)
    }

    private func updateSmartCollections() {
        visibleSmartCollections = SmartCollection.allCases.compactMap { sc in
            let count = sc.recipes(from: recipes).count
            return count > 0 ? (sc, count) : nil
        }
    }
}

// MARK: - Smart collection card

private struct SmartCollectionCard: View {
    let collection: SmartCollection
    let recipeCount: Int

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacing8) {
            HStack {
                Circle()
                    .fill(collection.color)
                    .frame(width: 28, height: 28)
                    .overlay(
                        Image(systemName: collection.systemImage)
                            .font(.caption2)
                            .foregroundStyle(.white)
                    )
                Spacer()
                Image(systemName: "sparkles")
                    .font(.system(size: AppTheme.fontSize8, weight: .semibold))
                    .foregroundStyle(collection.color.opacity(0.7))
            }

            Text(collection.name)
                .font(.subheadline.weight(.semibold))
                .lineLimit(2)
                .adaptiveForegroundColor()

            Text(recipeCount == 1 ? "1 recipe" : "\(recipeCount) recipes")
                .font(.caption)
                .adaptiveSecondaryForeground()
        }
        .padding(AppTheme.spacing12)
        .frame(maxWidth: .infinity, minHeight: 80, alignment: .topLeading)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: AppTheme.cornerRadius12))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.cornerRadius12)
                .strokeBorder(collection.color.opacity(0.3), lineWidth: 1)
        )
    }
}
