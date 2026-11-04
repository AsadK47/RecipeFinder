import SwiftUI

/// Field-by-field diff of saved vs. freshly-fetched upstream recipe; user toggles fields to accept, personal data always preserved.
struct RecipeRefreshSheet: View {
    let diff: RecipeDiff
    let sourceURL: URL
    @State private var selectedFields: Set<RecipeDiffField>
    let onApply: (RecipeModel) -> Void
    @Environment(\.dismiss) private var dismiss

    init(diff: RecipeDiff, sourceURL: URL, onApply: @escaping (RecipeModel) -> Void) {
        self.diff = diff
        self.sourceURL = sourceURL
        _selectedFields = State(initialValue: diff.changed)
        self.onApply = onApply
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()
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
            .appNavigationTitle("Update from Source")
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
                        .foregroundStyle(AppTheme.accentColor)   // colour cue stays on the icon
                    Text(newValue(for: field))
                        .font(.caption.weight(.medium))
                        .adaptiveForegroundColor()               // readable on the gradient; accent text was near-invisible
                        .lineLimit(1)
                }
            }
            Spacer(minLength: 0)
            Toggle("", isOn: Binding(
                get: { selectedFields.contains(field) },
                set: { included in
                    if included { selectedFields.insert(field) } else { selectedFields.remove(field) }
                }
            ))
            .labelsHidden()
            .tint(AppTheme.accentColor)   // default tint rendered "on" as a dark, off-looking track on the gradient
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
