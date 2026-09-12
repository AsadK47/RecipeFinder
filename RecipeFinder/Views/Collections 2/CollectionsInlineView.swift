import SwiftUI

/// The collections grid rendered inside `RecipeSearchView`'s existing
/// `NavigationStack`. Does not own a `NavigationStack` itself — navigation
/// links push onto the parent stack.
struct CollectionsInlineView: View {
    @Binding var recipes: [RecipeModel]
    @ObservedObject private var manager = CollectionManager.shared
    @State private var showNewCollection = false
    @State private var collectionToEdit: RecipeCollection?
    @State private var collectionToDelete: RecipeCollection?

    private let columns = [
        GridItem(.flexible(), spacing: AppTheme.spacing12),
        GridItem(.flexible(), spacing: AppTheme.spacing12)
    ]

    var body: some View {
        Group {
            if manager.collections.isEmpty {
                emptyState
            } else {
                collectionGrid
            }
        }
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
        VStack(spacing: AppTheme.spacing16) {
            Spacer()

            Image(systemName: "rectangle.stack")
                .font(.system(size: AppTheme.fontSize50))
                .foregroundColor(.secondary.opacity(0.5))

            Text("No Collections Yet")
                .font(.title3.weight(.semibold))
                .adaptiveForegroundColor()

            Text("Create collections to organise your recipes \u{2014} \u{201c}Weeknight Dinners\u{201d}, \u{201c}Party Food\u{201d}, whatever works for you.")
                .font(.subheadline)
                .adaptiveSecondaryForeground()
                .multilineTextAlignment(.center)
                .padding(.horizontal, AppTheme.spacing32)

            Button {
                HapticManager.shared.light()
                showNewCollection = true
            } label: {
                Label("Create Collection", systemImage: "plus")
                    .font(.headline)
                    .padding(.horizontal, AppTheme.spacing24)
                    .padding(.vertical, AppTheme.spacing12)
                    .background(.ultraThinMaterial, in: Capsule())
            }
            .adaptiveForegroundColor()

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
