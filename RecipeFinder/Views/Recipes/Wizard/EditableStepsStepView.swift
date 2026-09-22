import SwiftUI

/// A reusable Recipe Wizard step for editing an ordered list of `EditableStep`s.
/// Both the pre-prep and cooking-instructions steps use this; only the labels
/// differ.
struct EditableStepsStepView: View {
    @Binding var steps: [EditableStep]
    let title: String
    let subtitle: String
    let stepNumber: Int
    let illustration: String
    let fieldPlaceholder: String
    let addButtonTitle: String
    let appTheme: AppTheme.ThemeType
    let cardStyle: CardStyle
    let colorScheme: ColorScheme
    let totalSteps: Int

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacing24) {
            WizardStepHeader(
                title: title,
                subtitle: subtitle,
                stepNumber: stepNumber,
                totalSteps: totalSteps,
                illustration: illustration
            )

            WizardCard(cardStyle: cardStyle, colorScheme: colorScheme) {
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
                                            .foregroundColor(AppTheme.error)
                                    }
                                }
                            }

                            TextField(fieldPlaceholder, text: $step.text, axis: .vertical)
                                .textFieldStyle(.roundedBorder)
                                .lineLimit(2...5)
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
                            .foregroundColor(AppTheme.accentColor(for: appTheme))
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
