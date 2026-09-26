import SwiftUI

/// Sheet for creating a new named, coloured collection.
struct NewCollectionSheet: View {
    let manager: any CollectionManaging
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("appTheme") private var selectedTheme: AppTheme.ThemeType = .teal

    @State private var name: String = ""
    @State private var selectedColor: CollectionColor = .blue

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.backgroundGradient(for: selectedTheme, colorScheme: colorScheme)
                    .ignoresSafeArea()

                Form {
                    Section("Name") {
                        TextField("Collection name", text: $name)
                    }

                    Section("Colour") {
                        colorPicker
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("New Collection")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
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
        }
    }

    private var colorPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppTheme.spacing12) {
                ForEach(CollectionColor.allCases) { color in
                    Button {
                        selectedColor = color
                        HapticManager.shared.light()
                    } label: {
                        Circle()
                            .fill(color.swiftUIColor)
                            .frame(width: 32, height: 32)
                            .overlay(
                                Circle()
                                    .strokeBorder(
                                        selectedColor == color ? Color.primary : Color.clear,
                                        lineWidth: 2
                                    )
                                    .padding(-3)
                            )
                    }
                    .accessibilityLabel(color.displayName)
                }
            }
            .padding(.vertical, AppTheme.spacing4)
            .padding(.horizontal, AppTheme.spacing16)
        }
        // Remove list-row insets so the trailing inset doesn't clip the last colour swatch.
        .listRowInsets(EdgeInsets())
    }
}

/// Sheet for renaming or recolouring an existing collection.
struct EditCollectionSheet: View {
    let collection: RecipeCollection
    let manager: any CollectionManaging
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("appTheme") private var selectedTheme: AppTheme.ThemeType = .teal

    @State private var name: String
    @State private var selectedColor: CollectionColor

    init(collection: RecipeCollection, manager: any CollectionManaging) {
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
                    }

                    Section("Colour") {
                        colorPicker
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Edit Collection")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
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
                        selectedColor = color
                        HapticManager.shared.light()
                    } label: {
                        Circle()
                            .fill(color.swiftUIColor)
                            .frame(width: 32, height: 32)
                            .overlay(
                                Circle()
                                    .strokeBorder(
                                        selectedColor == color ? Color.primary : Color.clear,
                                        lineWidth: 2
                                    )
                                    .padding(-3)
                            )
                    }
                    .accessibilityLabel(color.displayName)
                }
            }
            .padding(.vertical, AppTheme.spacing4)
            .padding(.horizontal, AppTheme.spacing16)
        }
        .listRowInsets(EdgeInsets())
    }
}
