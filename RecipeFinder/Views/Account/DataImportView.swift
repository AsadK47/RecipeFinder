import SwiftUI
import UniformTypeIdentifiers

struct DataImportView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showingDocumentPicker = false
    @State private var isImporting = false
    @State private var importResult: ImportResult?
    @State private var mergeMode: MergeMode = .replace

    enum ImportResult {
        case success(String)
        case error(String)
    }

    enum MergeMode: String, CaseIterable {
        case replace = "Replace All"
        case merge   = "Merge (Keep Both)"

        var description: String {
            switch self {
            case .replace: return "Delete existing data and replace with imported data"
            case .merge:   return "Keep existing data and add imported data"
            }
        }
    }

    var body: some View {
        NavigationView {
            VStack(spacing: AppTheme.spacing32) {
                Spacer()

                Image(systemName: "square.and.arrow.up.fill")
                    .font(.system(size: AppTheme.fontSize60))
                    .foregroundColor(.orange)

                Text("Import Your Data")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("Restore your recipes, preferences, and data from a previous backup. Select a JSON file exported from RecipeFinder.")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)

                VStack(alignment: .leading, spacing: AppTheme.spacing12) {
                    Text("Import Mode")
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    ForEach(MergeMode.allCases, id: \.self) { mode in
                        Button(action: {
                            mergeMode = mode
                            HapticManager.shared.selection()
                        }) {
                            HStack {
                                Image(systemName: mergeMode == mode ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(mergeMode == mode ? .orange : .secondary)

                                VStack(alignment: .leading, spacing: AppTheme.spacing2) {
                                    Text(mode.rawValue)
                                        .font(.body)
                                        .foregroundColor(.primary)

                                    Text(mode.description)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }

                                Spacer()
                            }
                            .padding()
                            .background(Color.secondary.opacity(AppTheme.shadowLightOpacity))
                            .cornerRadius(AppTheme.cornerRadius12)
                        }
                    }
                }
                .padding(.horizontal)

                if let result = importResult {
                    switch result {
                    case .success(let message):
                        HStack {
                            Image(systemName: "checkmark.circle.fill").foregroundColor(.green)
                            Text(message).font(.caption).foregroundColor(.green)
                        }
                        .padding(.horizontal)
                    case .error(let message):
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill").foregroundColor(.red)
                            Text(message).font(.caption).foregroundColor(.red)
                        }
                        .padding(.horizontal)
                    }
                }

                Button {
                    showingDocumentPicker = true
                } label: {
                    HStack {
                        if isImporting {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Image(systemName: "doc.badge.arrow.up")
                            Text("Select JSON File")
                        }
                    }
                    .font(.headline)
                    .adaptiveForegroundColor()
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.orange)
                    .cornerRadius(AppTheme.cornerRadius12)
                }
                .disabled(isImporting)
                .padding(.horizontal)

                Spacer()
            }
            .padding(.top, AppTheme.spacing40)
            .navigationTitle("Data Import")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .fileImporter(
                isPresented: $showingDocumentPicker,
                allowedContentTypes: [.json],
                allowsMultipleSelection: false
            ) { result in
                handleFileImport(result)
            }
        }
    }

    private func handleFileImport(_ result: Result<[URL], Error>) {
        isImporting = true
        importResult = nil

        let selectedMergeMode = mergeMode

        DispatchQueue.global(qos: .userInitiated).async {
            do {
                guard let url = try result.get().first else {
                    throw NSError(domain: "ImportError", code: 1, userInfo: [NSLocalizedDescriptionKey: "No file selected"])
                }

                guard url.startAccessingSecurityScopedResource() else {
                    throw NSError(domain: "ImportError", code: 2, userInfo: [NSLocalizedDescriptionKey: "Cannot access file"])
                }

                defer { url.stopAccessingSecurityScopedResource() }

                let data = try Data(contentsOf: url)
                guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                    throw NSError(domain: "ImportError", code: 3, userInfo: [NSLocalizedDescriptionKey: "Invalid JSON format"])
                }

                if let preferences = json["preferences"] as? [String: Any] {
                    if let theme = preferences["theme"] as? String {
                        UserDefaults.standard.set(theme, forKey: "appTheme")
                    }
                    if let measurement = preferences["measurementSystem"] as? String {
                        UserDefaults.standard.set(measurement, forKey: "measurementSystem")
                    }
                    if let cardStyle = preferences["cardStyle"] as? String {
                        UserDefaults.standard.set(cardStyle, forKey: "cardStyle")
                    }
                }

                if selectedMergeMode == .replace {
                    if let favorites = json["favoriteRecipes"] as? [String] {
                        UserDefaults.standard.set(favorites, forKey: "favoriteRecipeIDs")
                    }
                } else {
                    if let newFavorites = json["favoriteRecipes"] as? [String],
                       var existingFavorites = UserDefaults.standard.array(forKey: "favoriteRecipeIDs") as? [String] {
                        existingFavorites.append(contentsOf: newFavorites)
                        UserDefaults.standard.set(Array(Set(existingFavorites)), forKey: "favoriteRecipeIDs")
                    }
                }

                let scopedStorage = UserScopedStorage.shared

                func importCodable<T: Codable>(_ type: T.Type, from jsonArray: [[String: Any]], key: String, merge: Bool) throws {
                    let jsonData = try JSONSerialization.data(withJSONObject: jsonArray)
                    guard let newItems = try? JSONDecoder().decode([T].self, from: jsonData) else { return }
                    let items: [T]
                    if merge, let existingData = scopedStorage.data(forKey: key),
                       let existing = try? JSONDecoder().decode([T].self, from: existingData) {
                        items = existing + newItems
                    } else {
                        items = newItems
                    }
                    scopedStorage.set(try JSONEncoder().encode(items), forKey: key)
                }

                if let arr = json["shoppingList"] as? [[String: Any]] {
                    try importCodable(ShoppingListModel.self, from: arr, key: Constants.UserDefaultsKeys.shoppingListItems, merge: selectedMergeMode == .merge)
                }
                if let arr = json["kitchenInventory"] as? [[String: Any]] {
                    try importCodable(KitchenInventoryModel.self, from: arr, key: Constants.UserDefaultsKeys.kitchenItems, merge: selectedMergeMode == .merge)
                }
                if let arr = json["mealPlans"] as? [[String: Any]] {
                    try importCodable(MealPlanModel.self, from: arr, key: "mealPlansStorage", merge: selectedMergeMode == .merge)
                }

                if let notes = json["recipeNotes"] as? [String: String] {
                    if selectedMergeMode == .replace {
                        scopedStorage.set(try JSONEncoder().encode(notes), forKey: "saved_notes")
                    } else if let existingData = scopedStorage.data(forKey: "saved_notes"),
                              var existing = try? JSONDecoder().decode([String: String].self, from: existingData) {
                        existing.merge(notes) { _, new in new }
                        scopedStorage.set(try JSONEncoder().encode(existing), forKey: "saved_notes")
                    } else {
                        scopedStorage.set(try JSONEncoder().encode(notes), forKey: "saved_notes")
                    }
                }

                DispatchQueue.main.async {
                    ShoppingListManager.shared.reloadForCurrentUser()
                    KitchenInventoryManager.shared.reloadForCurrentUser()
                    MealPlanningManager.shared.reloadForCurrentUser()
                    NotesManager.shared.reloadForCurrentUser()
                    AccountManager.shared.updateStats()

                    self.isImporting = false
                    self.importResult = .success("Data imported successfully!")
                    HapticManager.shared.success()

                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) { dismiss() }
                }

            } catch {
                DispatchQueue.main.async {
                    self.isImporting = false
                    self.importResult = .error("Failed to import: \(error.localizedDescription)")
                    HapticManager.shared.error()
                }
            }
        }
    }
}
