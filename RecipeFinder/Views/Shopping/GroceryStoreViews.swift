import SwiftUI

/// Store picked in the Groceries filter bar or for bulk assignment; Identifiable so it can drive `.sheet(item:)`.
struct GroceryStoreSelection: Identifiable, Hashable {
    let name: String
    var id: String { name }
}

/// "Shop at" chips under the Groceries search field: All plus each of the user's stores, and a button to assign
/// items to the selected store.
struct GroceryStoreFilterBar: View {
    let stores: [String]
    /// nil = All.
    let selected: String?
    let onSelect: (String?) -> Void
    let onAssign: (String) -> Void
    let onManage: () -> Void

    var body: some View {
        HStack(spacing: AppTheme.spacing8) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppTheme.spacing8) {
                    chip("All", isSelected: selected == nil) { onSelect(nil) }
                    ForEach(stores, id: \.self) { store in
                        chip(store, isSelected: selected == store) { onSelect(store) }
                    }
                }
                .padding(.horizontal, AppTheme.spacing20)
            }

            Menu {
                if let selected {
                    Button { onAssign(selected) } label: {
                        Label("Choose Items for \(selected)…", systemImage: "checklist")
                    }
                }
                Button(action: onManage) { Label("Manage Stores…", systemImage: "storefront") }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .font(.title3)
                    .adaptiveForegroundColor()
            }
            .accessibilityLabel("Store options")
            .padding(.trailing, AppTheme.spacing20)
        }
        .padding(.bottom, AppTheme.spacing8)
    }

    private func chip(_ title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button {
            HapticManager.shared.selection()
            action()
        } label: {
            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .lineLimit(1)
                .foregroundStyle(isSelected ? Color.white : AppTheme.adaptiveEmphasis())
                .padding(.horizontal, AppTheme.spacing12)
                .padding(.vertical, AppTheme.spacing6)
                .background(Capsule().fill(isSelected ? AppTheme.accentColor : AppTheme.adaptiveFilterChip))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityHint("Shows groceries to buy at \(title)")
    }
}

/// Add, rename (tap) and delete (swipe) the user's grocery stores.
struct GroceryStoresSheet: View {
    @Environment(\.shopping) private var shopping
    @State private var newStoreName = ""
    @State private var renaming: String?
    @State private var renameText = ""
    @State private var nameError: String?

    var body: some View {
        Form {
            Section {
                HStack {
                    TextField("Add a store, e.g. Lidl", text: $newStoreName)
                        .submitLabel(.done)
                        .onSubmit(addStore)
                    Button("Add", action: addStore)
                        .disabled(newStoreName.isBlank)
                }
            } footer: {
                Text("Items without a store show under every store.")
            }

            if !shopping.stores.isEmpty {
                Section {
                    ForEach(shopping.stores, id: \.self) { store in
                        Button {
                            renameText = store
                            renaming = store
                        } label: {
                            Text(store).adaptiveForegroundColor()
                        }
                        .swipeActions {
                            Button(role: .destructive) { shopping.deleteStore(store) } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                        .accessibilityHint("Double tap to rename; swipe to delete")
                    }
                } header: {
                    Text("Your Stores")
                } footer: {
                    Text("Tap to rename. Swipe to delete — its items stay on your list.")
                }
            }
        }
        .scrollContentBackground(.hidden)
        .alert("Rename Store", isPresented: .isPresent($renaming), presenting: renaming) { store in
            TextField("Store name", text: $renameText)
            Button("Save") { rename(store) }
            Button("Cancel", role: .cancel) {}
        }
        .errorAlert("Couldn't Save Store", message: $nameError)
        .sheetDismissButton()
        .sheetScaffold("Stores")
    }

    private func addStore() {
        guard !newStoreName.isBlank else { return }
        if shopping.addStore(newStoreName) {
            newStoreName = ""
            HapticManager.shared.success()
        } else {
            nameError = "You already have a store called \(newStoreName.trimmed)."
        }
    }

    private func rename(_ store: String) {
        guard !shopping.renameStore(store, to: renameText) else { return }
        nameError = renameText.isBlank
            ? "A store needs a name."
            : "You already have a store called \(renameText.trimmed)."
    }
}

/// Tick the items to buy at one store — every item on the list, in one place, instead of a menu per row.
struct AssignStoreSheet: View {
    let store: String
    @Environment(\.shopping) private var shopping

    private var sortedItems: [ShoppingListModel] {
        shopping.items.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    var body: some View {
        Form {
            Section {
                ForEach(sortedItems) { item in
                    let isAssigned = item.stores.contains(store)
                    Button {
                        shopping.setStore(store, assigned: !isAssigned, forItemIDs: [item.id])
                    } label: {
                        HStack {
                            Text(item.name).adaptiveForegroundColor()
                            Spacer()
                            if isAssigned {
                                Image(systemName: "checkmark")
                                    .fontWeight(.semibold)
                                    .foregroundStyle(AppTheme.accentColor)
                            }
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(isAssigned ? .isSelected : [])
                }
            } footer: {
                Text("Unticked items with no store still show under every store.")
            }
        }
        .scrollContentBackground(.hidden)
        .sheetDismissButton()
        .sheetScaffold("Buy at \(store)")
    }
}
