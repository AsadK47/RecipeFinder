import SwiftUI

/// Sheet that presents a field-by-field diff between the saved recipe and a
/// freshly-fetched upstream version. The user toggles which fields to accept;
/// personal data (notes, tags, servings, ratings) is always preserved.
struct RecipeRefreshSheet: View {
    let diff: RecipeDiff
    let sourceURL: URL
    @State private var selectedFields: Set<RecipeDiffField>
    let onApply: (RecipeModel) -> Void
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("appTheme") private var selectedTheme: AppTheme.ThemeType = .teal

    init(diff: RecipeDiff, sourceURL: URL, onApply: @escaping (RecipeModel) -> Void) {
        self.diff = diff
        self.sourceURL = sourceURL
        _selectedFields = State(initialValue: diff.changed)
        self.onApply = onApply
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.backgroundGradient(for: selectedTheme, colorScheme: colorScheme)
                    .ignoresSafeArea()
                List {
                    Section {
                        Label {
                            Text("\(diff.changed.count) update\(diff.changed.count == 1 ? "" : "s") from ")
                            + Text(sourceURL.host ?? "source").bold()
                        } icon: {
                            Image(systemName: "arrow.clockwise.circle.fill")
                                .foregroundStyle(AppTheme.accentColor)
                        }
                        .font(.subheadline)
                        .adaptiveForegroundColor()
                        .listRowBackground(Color.clear)
                    }

                    Section("Changes") {
                        ForEach(RecipeDiffField.allCases.filter { diff.changed.contains($0) }, id: \.self) { field in
                            diffRow(for: field)
                        }
                    }

                    Section {
                        Text("Notes, tags, servings, ratings, and cook history are always preserved.")
                            .font(.caption)
                            .adaptiveSecondaryForeground()
                            .listRowBackground(Color.clear)
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Update from Source")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Not Now") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Apply \(selectedFields.count)") {
                        onApply(diff.applying(selections: selectedFields))
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(selectedFields.isEmpty)
                }
            }
        }
    }

    private func diffRow(for field: RecipeDiffField) -> some View {
        HStack(spacing: AppTheme.spacing12) {
            VStack(alignment: .leading, spacing: AppTheme.spacing4) {
                Text(field.displayName)
                    .font(.subheadline.weight(.medium))
                    .adaptiveForegroundColor()
                Text(oldValue(for: field))
                    .font(.caption)
                    .adaptiveSecondaryForeground()
                    .lineLimit(1)
                HStack(spacing: AppTheme.spacing4) {
                    Image(systemName: "arrow.right")
                        .font(.caption2.weight(.semibold))
                    Text(newValue(for: field))
                        .font(.caption.weight(.medium))
                        .lineLimit(1)
                }
                .foregroundStyle(AppTheme.accentColor)
            }
            Spacer(minLength: 0)
            Toggle("", isOn: Binding(
                get: { selectedFields.contains(field) },
                set: { included in
                    if included { selectedFields.insert(field) } else { selectedFields.remove(field) }
                }
            ))
            .labelsHidden()
        }
        .padding(.vertical, AppTheme.spacing4)
    }

    private func oldValue(for field: RecipeDiffField) -> String {
        switch field {
        case .name:         diff.stored.name
        case .ingredients:  "\(diff.stored.ingredients.count) ingredient\(diff.stored.ingredients.count == 1 ? "" : "s")"
        case .instructions: "\(diff.stored.instructions.count) step\(diff.stored.instructions.count == 1 ? "" : "s")"
        case .prepTime:     diff.stored.prepTime
        case .cookingTime:  diff.stored.cookingTime
        case .difficulty:   diff.stored.difficulty
        case .category:     diff.stored.category
        case .cuisine:      diff.stored.cuisine ?? "None"
        case .imageName:    diff.stored.imageName != nil ? "Current image" : "No image"
        }
    }

    private func newValue(for field: RecipeDiffField) -> String {
        switch field {
        case .name:         diff.upstream.name
        case .ingredients:  "\(diff.upstream.ingredients.count) ingredient\(diff.upstream.ingredients.count == 1 ? "" : "s")"
        case .instructions: "\(diff.upstream.instructions.count) step\(diff.upstream.instructions.count == 1 ? "" : "s")"
        case .prepTime:     diff.upstream.prepTime
        case .cookingTime:  diff.upstream.cookingTime
        case .difficulty:   diff.upstream.difficulty
        case .category:     diff.upstream.category
        case .cuisine:      diff.upstream.cuisine ?? "None"
        case .imageName:    diff.upstream.imageName != nil ? "New image" : "Remove image"
        }
    }
}
