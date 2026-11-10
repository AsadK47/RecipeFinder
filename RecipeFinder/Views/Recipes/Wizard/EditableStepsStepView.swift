import SwiftUI

/// Reusable wizard step for an ordered step list (pre-prep and cooking instructions): one text area, one step per
/// line; pasted numbering is dropped and each line becomes a numbered step in the preview.
struct EditableStepsStepView: View {
    @Binding var steps: [EditableStep]
    let title: String
    let subtitle: String
    let illustration: String
    let fieldPlaceholder: String
    let addButtonTitle: String

    @State private var text = ""
    @State private var seeded = false
    @FocusState private var editorFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacing24) {
            WizardStepHeader(
                title: title,
                subtitle: subtitle,
                illustration: illustration
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
                                Text("\(fieldPlaceholder) — one step per line")
                                    .adaptiveSecondaryForeground()
                                    .padding(.horizontal, AppTheme.spacing12)
                                    .padding(.vertical, AppTheme.spacing14)
                                    .allowsHitTesting(false)
                            }
                        }
                        .accessibilityLabel("\(title), one step per line")

                    let texts = steps.nonEmptyTexts
                    ForEach(Array(texts.enumerated()), id: \.offset) { index, step in
                        HStack(alignment: .firstTextBaseline, spacing: AppTheme.spacing8) {
                            Text("\(index + 1).")
                                .font(.subheadline.weight(.semibold))
                                .adaptiveSecondaryForeground()
                            Text(step)
                                .font(.subheadline)
                                .adaptiveForegroundColor()
                        }
                        .accessibilityElement(children: .combine)
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
            text = StepTextBlock.text(from: steps.nonEmptyTexts)
        }
        .onChange(of: text) { _, newText in
            steps = .steps(from: StepTextBlock.steps(from: newText))
        }
    }
}
