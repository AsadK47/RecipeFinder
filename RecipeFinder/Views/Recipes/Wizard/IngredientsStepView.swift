import SwiftUI

/// Step 3 of the Recipe Wizard: one text area, one ingredient per line (type or paste a whole block), parsed live by
/// the same `IngredientLineParser` imports use, with a preview of how each line was read.
struct IngredientsStepView: View {
    @Binding var ingredientItems: [RecipeWizardView.IngredientItem]

    @State private var text = ""
    @State private var seeded = false
    @FocusState private var editorFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacing24) {
            WizardStepHeader(
                title: "Ingredients",
                subtitle: "One per line — type or paste, e.g. “200 g flour”",
                illustration: "cart.fill"
            )

            WizardCard {
                VStack(alignment: .leading, spacing: AppTheme.spacing12) {
                    TextEditor(text: $text)
                        .focused($editorFocused)
                        .scrollContentBackground(.hidden)
                        .frame(minHeight: 160)
                        .appInputField()
                        .overlay(alignment: .topLeading) {
                            if text.isEmpty {
                                Text("200 g plain flour\n2 eggs\n1½ cups milk")
                                    .adaptiveSecondaryForeground()
                                    .padding(.horizontal, AppTheme.spacing12)
                                    .padding(.vertical, AppTheme.spacing14)
                                    .allowsHitTesting(false)
                            }
                        }
                        .accessibilityLabel("Ingredients, one per line")
                        .accessibilityIdentifier("wizard.ingredientsText")

                    let parsed = ingredientItems.filter { !$0.name.trimmed.isEmpty }
                    if !parsed.isEmpty {
                        Text("\(parsed.count) ingredient\(parsed.count == 1 ? "" : "s")")
                            .font(.caption)
                            .adaptiveSecondaryForeground()
                        ForEach(parsed) { item in
                            HStack(alignment: .firstTextBaseline, spacing: AppTheme.spacing8) {
                                Text([item.quantity, item.unit].filter { !$0.isEmpty }.joined(separator: " "))
                                    .font(.subheadline.weight(.semibold))
                                    .frame(minWidth: 64, alignment: .leading)
                                Text(item.name)
                                    .font(.subheadline)
                                    .adaptiveForegroundColor()
                            }
                            .accessibilityElement(children: .combine)
                        }
                    }
                }
                .padding()
            }
        }
        .scrollDismissesKeyboard(.interactively)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                if editorFocused {
                    Button("Done") { editorFocused = false }
                }
            }
        }
        .onAppear {
            guard !seeded else { return }
            seeded = true
            text = IngredientTextBlock.text(from: ingredientItems)
        }
        .onChange(of: text) { _, newText in
            let items = IngredientTextBlock.items(from: newText)
            ingredientItems = items.isEmpty ? [RecipeWizardView.IngredientItem()] : items
        }
    }
}
