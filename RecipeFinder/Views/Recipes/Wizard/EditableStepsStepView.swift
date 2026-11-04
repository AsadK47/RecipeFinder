import SwiftUI

/// Reusable wizard step for editing an ordered `EditableStep` list; used by both pre-prep and cooking-instructions (only labels differ).
struct EditableStepsStepView: View {
    @Binding var steps: [EditableStep]
    let title: String
    let subtitle: String
    let illustration: String
    let fieldPlaceholder: String
    let addButtonTitle: String
    let colorScheme: ColorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacing24) {
            WizardStepHeader(
                title: title,
                subtitle: subtitle,
                illustration: illustration
            )

            WizardCard {
                VStack(spacing: AppTheme.spacing12) {
                    ForEach($steps) { $step in
                        VStack(alignment: .leading, spacing: AppTheme.spacing4) {
                            HStack {
                                Text("Step \(number(of: step))")
                                    .font(.caption)
                                    .adaptiveSecondaryForeground()

                                Spacer()

                                if steps.count > 1 {
                                    Button(action: {
                                        HapticManager.shared.light()
                                        steps.removeAll { $0.id == step.id }
                                    }) {
                                        Image(systemName: "minus.circle.fill")
                                            .foregroundStyle(AppTheme.error)
                                    }
                                }
                            }

                            TextField(fieldPlaceholder, text: $step.text, axis: .vertical)
                                .textFieldStyle(.plain)
                                .lineLimit(2...5)
                                .appInputField()
                        }

                        if step.id != steps.last?.id {
                            Divider()
                        }
                    }

                    Button(action: {
                        HapticManager.shared.light()
                        steps.append(EditableStep())
                    }) {
                        Label(addButtonTitle, systemImage: "plus.circle.fill")
                            .foregroundStyle(AppTheme.accentColor)
                            .frame(maxWidth: .infinity)
                            .padding()
                    }
                }
                .padding()
            }
        }
    }

    private func number(of step: EditableStep) -> Int {
        (steps.firstIndex(where: { $0.id == step.id }) ?? 0) + 1
    }
}
