import SwiftUI

/// Add flow 1/3: a new or imported recipe shown as it will look once saved. Each part is a button that opens just
/// that part's editor, so the cook reviews the real recipe instead of a long form.
struct RecipeDraftView: View {
    typealias Section = RecipeWizardView.Section

    let preview: RecipeDraftPreview
    let selectedImage: UIImage?
    let imageReference: String?
    /// Sections the import couldn't read — outlined so the cook checks them first.
    let needsCheck: Set<Section>
    let onEdit: (Section) -> Void
    /// The photo goes straight to the camera/library choice — the name has its own button.
    let onPickPhoto: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacing20) {
            photo
            titleAndChips
            listCard("Ingredients", section: .ingredients, lines: preview.ingredientLines, numbered: false,
                     emptyPrompt: "Add ingredients", groupStarts: preview.ingredientGroupStarts)
            if !preview.prePrepSteps.isEmpty {
                listCard("Pre-prep", section: .prePrep, lines: preview.prePrepSteps, numbered: true,
                         emptyPrompt: "Add pre-prep")
            }
            listCard("Method", section: .instructions, lines: preview.steps, numbered: true,
                     emptyPrompt: "Add the steps")
            if let notes = preview.notes {
                listCard("Notes", section: .notes, lines: [notes], numbered: false, emptyPrompt: "Add notes")
            }
            addMore
        }
    }

    // MARK: - Parts

    private var photo: some View {
        Button(action: onPickPhoto) {
            Group {
                if let selectedImage {
                    Image(uiImage: selectedImage)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 220)
                        .frame(maxWidth: .infinity)
                        .clipped()
                } else if let imageReference, !imageReference.isEmpty {
                    RecipeImageView(imageName: imageReference, height: 220, recipeName: preview.title)
                } else {
                    RecipePlaceholderView(recipeName: preview.title)
                        .frame(height: 220)
                        .frame(maxWidth: .infinity)
                        .overlay(alignment: .bottomTrailing) {
                            Label("Add photo", systemImage: "camera.fill")
                                .font(.subheadline.weight(.semibold))
                                .adaptiveForegroundColor()
                                .padding(.horizontal, AppTheme.spacing12)
                                .padding(.vertical, AppTheme.spacing8)
                                .appCard(in: Capsule())
                                .padding(AppTheme.spacing12)
                        }
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius16))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(selectedImage == nil && (imageReference ?? "").isEmpty ? "Add photo" : "Change photo")
        .accessibilityIdentifier("draft.photo")
    }

    private var titleAndChips: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacing12) {
            Button { onEdit(.basics) } label: {
                HStack(alignment: .firstTextBaseline) {
                    Text(preview.title ?? "Add a name")
                        .font(.largeTitle.weight(.bold))
                        .foregroundStyle(preview.title == nil ? HierarchicalShapeStyle.secondary : .primary)
                        .multilineTextAlignment(.leading)
                    Spacer(minLength: AppTheme.spacing8)
                    editGlyph
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .importHighlight(needsCheck.contains(.basics))
            .accessibilityHint("Edit the name, photo and extra photos")
            .accessibilityIdentifier("draft.name")

            Button { onEdit(.details) } label: {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: AppTheme.spacing8) {
                        chip(preview.timeSummary ?? "Add times", systemImage: "clock")
                        chip(preview.servingsLabel, systemImage: "person.2")
                        ForEach(preview.detailChips, id: \.self) { chip($0, systemImage: nil) }
                    }
                }
            }
            .buttonStyle(.plain)
            .importHighlight(needsCheck.contains(.details))
            .accessibilityHint("Edit times, servings and details")
            .accessibilityIdentifier("draft.details")
        }
    }

    private func chip(_ text: String, systemImage: String?) -> some View {
        Group {
            if let systemImage {
                Label(text, systemImage: systemImage)
            } else {
                Text(text)
            }
        }
        .font(.subheadline.weight(.semibold))
        .adaptiveForegroundColor()
        .padding(.horizontal, AppTheme.spacing12)
        .padding(.vertical, AppTheme.spacing8)
        .appCard(in: Capsule())
    }

    private func listCard(
        _ title: String, section: Section, lines: [String], numbered: Bool, emptyPrompt: String,
        groupStarts: [Int: String] = [:]
    ) -> some View {
        Button { onEdit(section) } label: {
            VStack(alignment: .leading, spacing: AppTheme.spacing12) {
                HStack {
                    Text(title)
                        .font(.title3.weight(.bold))
                        .adaptiveForegroundColor()
                    Spacer()
                    editGlyph
                }
                if lines.isEmpty {
                    Label(emptyPrompt, systemImage: "plus.circle.fill")
                        .font(.subheadline.weight(.semibold))
                        .adaptiveForegroundColor()
                } else {
                    ForEach(Array(lines.enumerated()), id: \.offset) { index, line in
                        if let group = groupStarts[index] {
                            IngredientGroupHeader(title: group)
                        }
                        HStack(alignment: .firstTextBaseline, spacing: AppTheme.spacing8) {
                            Text(numbered ? "\(index + 1)." : "•")
                                .font(.body.weight(.semibold))
                                .adaptiveSecondaryForeground()
                            Text(line)
                                .font(.body)
                                .adaptiveForegroundColor()
                                .multilineTextAlignment(.leading)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .appCard()
        }
        .buttonStyle(.plain)
        .importHighlight(needsCheck.contains(section))
        .accessibilityHint("Edit \(title.lowercased())")
        .accessibilityIdentifier("draft.\(title.lowercased())")
    }

    /// Optional parts that aren't on the recipe yet, as small add buttons under it.
    private var addMore: some View {
        HStack(spacing: AppTheme.spacing8) {
            if preview.prePrepSteps.isEmpty {
                PrimaryButton("Pre-prep", systemImage: "plus", size: .compact, variant: .secondary) {
                    onEdit(.prePrep)
                }
            }
            if preview.notes == nil {
                PrimaryButton("Notes & tags", systemImage: "plus", size: .compact, variant: .secondary) {
                    onEdit(.notes)
                }
            }
        }
    }

    private var editGlyph: some View {
        Image(systemName: "pencil")
            .font(.subheadline.weight(.semibold))
            .adaptiveSecondaryForeground()
            .accessibilityHidden(true)
    }
}
