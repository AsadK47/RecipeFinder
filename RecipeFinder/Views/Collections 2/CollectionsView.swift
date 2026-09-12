import SwiftUI

/// Grid of user-created collections. Tapping a card opens `CollectionDetailView`;
/// the "+" button creates a new one via `NewCollectionSheet`.
struct CollectionsView: View {
    @Binding var recipes: [RecipeModel]
    @ObservedObject private var manager = CollectionManager.shared
    @State private var showNewCollection = false
    @State private var collectionToEdit: RecipeCollection?
    @State private var collectionToDelete: RecipeCollection?
    @Environment(\.colorScheme) var colorScheme
    @AppStorage("appTheme") private var selectedTheme: AppTheme.ThemeType = .teal

    private let columns = [
        GridItem(.flexible(), spacing: AppTheme.spacing12),
        GridItem(.flexible(), spacing: AppTheme.spacing12)
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.backgroundGradient(for: selectedTheme, colorScheme: colorScheme)
                    .ignoresSafeArea()

                if manager.collections.isEmpty {
                    emptyState
                } else {
                    collectionGrid
                }
            }
            .navigationTitle("Collections")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        HapticManager.shared.light()
                        showNewCollection = true
                    } label: {
                        Image(systemName: "plus")
                            .adaptiveForegroundColor()
                    }
                    .accessibilityLabel("New Collection")
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
                                Label("Rename", systemImage: "pencil")
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
            }
            .padding(AppTheme.spacing16)
            .padding(.bottom, AppTheme.spacing100)
        }
    }

    private var emptyState: some View {
        VStack(spacing: AppTheme.spacing16) {
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
        }
    }
}

// MARK: - Collection Card

struct CollectionCard: View {
    let collection: RecipeCollection
    let recipeCount: Int
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacing8) {
            HStack {
                Circle()
                    .fill(collection.colorName.swiftUIColor)
                    .frame(width: 36, height: 36)
                    .overlay(
                        Image(systemName: "rectangle.stack.fill")
                            .font(.system(size: AppTheme.fontSize15))
                            .foregroundColor(.white)
                    )
                Spacer()
            }

            Spacer()

            Text(collection.name)
                .font(.subheadline.weight(.semibold))
                .adaptiveForegroundColor()
                .lineLimit(2)
                .multilineTextAlignment(.leading)

            Text(recipeCount == 1 ? "1 recipe" : "\(recipeCount) recipes")
                .font(.caption)
                .adaptiveSecondaryForeground()
        }
        .padding(AppTheme.spacing16)
        .frame(maxWidth: .infinity, minHeight: 120, alignment: .leading)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: AppTheme.cornerRadius12))
        .overlay(
            RoundedRectangle(cornerRadius: AppTheme.cornerRadius12)
                .strokeBorder(collection.colorName.swiftUIColor.opacity(0.35), lineWidth: 1)
        )
    }
}

// MARK: - New Collection Sheet

struct NewCollectionSheet: View {
    let manager: CollectionManager
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("appTheme") private var selectedTheme: AppTheme.ThemeType = .teal
    @State private var name = ""
    @State private var selectedColor: CollectionColor = .blue
    @FocusState private var nameFocused: Bool

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.backgroundGradient(for: selectedTheme, colorScheme: colorScheme)
                    .ignoresSafeArea()

                Form {
                    Section("Name") {
                        TextField("e.g. Weeknight Dinners", text: $name)
                            .focused($nameFocused)
                    }
                    Section("Colour") {
                        colorPicker
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("New Collection")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        manager.createCollection(name: name, color: selectedColor)
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .onAppear { nameFocused = true }
        }
    }

    private var colorPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppTheme.spacing12) {
                ForEach(CollectionColor.allCases) { color in
                    Button {
                        HapticManager.shared.selection()
                        selectedColor = color
                    } label: {
                        Circle()
                            .fill(color.swiftUIColor)
                            .frame(width: 32, height: 32)
                            .overlay(
                                selectedColor == color
                                    ? Image(systemName: "checkmark")
                                        .font(.caption.bold())
                                        .foregroundColor(.white)
                                    : nil
                            )
                    }
                }
            }
            .padding(.vertical, AppTheme.spacing4)
        }
    }
}

// MARK: - Edit Collection Sheet

struct EditCollectionSheet: View {
    let collection: RecipeCollection
    let manager: CollectionManager
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("appTheme") private var selectedTheme: AppTheme.ThemeType = .teal
    @State private var name: String
    @State private var selectedColor: CollectionColor
    @FocusState private var nameFocused: Bool

    init(collection: RecipeCollection, manager: CollectionManager) {
        self.collection = collection
        self.manager = manager
        _name = State(initialValue: collection.name)
        _selectedColor = State(initialValue: collection.colorName)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.backgroundGradient(for: selectedTheme, colorScheme: colorScheme)
                    .ignoresSafeArea()

                Form {
                    Section("Name") {
                        TextField("Collection name", text: $name)
                            .focused($nameFocused)
                    }
                    Section("Colour") {
                        colorPicker
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Edit Collection")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        manager.rename(collection, to: name)
                        manager.recolor(collection, to: selectedColor)
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }

    private var colorPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppTheme.spacing12) {
                ForEach(CollectionColor.allCases) { color in
                    Button {
                        HapticManager.shared.selection()
                        selectedColor = color
                    } label: {
                        Circle()
                            .fill(color.swiftUIColor)
                            .frame(width: 32, height: 32)
                            .overlay(
                                selectedColor == color
                                    ? Image(systemName: "checkmark")
                                        .font(.caption.bold())
                                        .foregroundColor(.white)
                                    : nil
                            )
                    }
                }
            }
            .padding(.vertical, AppTheme.spacing4)
        }
    }
}

// MARK: - CollectionColor + SwiftUI

extension CollectionColor {
    var swiftUIColor: Color {
        switch self {
        case .blue:   return .blue
        case .green:  return .green
        case .orange: return .orange
        case .pink:   return .pink
        case .purple: return .purple
        case .red:    return .red
        case .teal:   return .teal
        case .yellow: return Color(red: 0.9, green: 0.75, blue: 0.1)
        }
    }
}
