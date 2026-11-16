import SwiftUI

/// The recipe Nutrition section's content: per-serving / whole-recipe toggle, macro bar and the UK-style label.
/// Whole-recipe multiplies per-serving by the current servings; % RI is shown per serving only.
struct RecipeNutritionLabel: View {
    let perServing: NutritionInfo
    let servings: Int
    @Binding var showsWholeRecipe: Bool

    private typealias Format = NutritionLabelFormat
    private typealias RI = NutritionLabelFormat.ReferenceIntake

    var body: some View {
        let isWhole = showsWholeRecipe
        let n = isWhole ? perServing.scaled(by: servings) : perServing
        VStack(alignment: .leading, spacing: AppTheme.spacing12) {
            Picker("Nutrition amount", selection: $showsWholeRecipe) {
                Text("Per serving").tag(false)
                Text("Whole recipe").tag(true)
            }
            .pickerStyle(.segmented)

            // Present in both modes so the macro bar below doesn't jump vertically.
            Text(isWhole
                 ? "Total for \(servings) serving\(servings == 1 ? "" : "s")"
                 : "Amount per serving")
                .font(.caption2)
                .adaptiveSecondaryForeground()

            NutritionMacroBar(nutrition: n)

            if !isWhole {
                HStack {
                    Spacer()
                    Text("% RI*")
                        .font(.caption2)
                        .adaptiveSecondaryForeground()
                }
                .padding(.bottom, -AppTheme.spacing4)
            }

            labelRow(label: "Calories", value: "\(n.calories)", unit: "kcal", hero: true,
                     percent: percent(Double(n.calories), of: RI.calories, isWhole))

            Divider()

            labelRow(label: "Fat", value: Format.macro(n.fat), unit: "g",
                     percent: percent(n.fat, of: RI.fat, isWhole))
            labelSubrow(label: "of which saturates", value: Format.macro(n.saturates), unit: "g",
                        percent: percent(n.saturates, of: RI.saturates, isWhole))

            Divider()

            labelRow(label: "Carbohydrate", value: Format.macro(n.carbs), unit: "g",
                     percent: percent(n.carbs, of: RI.carbs, isWhole))
            labelSubrow(label: "of which sugars", value: Format.macro(n.sugars), unit: "g",
                        percent: percent(n.sugars, of: RI.sugars, isWhole))

            Divider()

            labelRow(label: "Fibre", value: Format.macro(n.fibre), unit: "g")

            Divider()

            labelRow(label: "Protein", value: Format.macro(n.protein), unit: "g",
                     percent: percent(n.protein, of: RI.protein, isWhole))

            Divider()

            labelRow(label: "Salt", value: Format.salt(n.salt), unit: "g",
                     percent: percent(n.salt, of: RI.salt, isWhole))

            if n.coverage < 0.8 {
                Text("Estimated — \(Int(n.coverage * 100))% of ingredients matched")
                    .font(.caption2)
                    .adaptiveSecondaryForeground()
                    .padding(.top, AppTheme.spacing4)
            }

            if !isWhole {
                Text("* Reference intakes for an average adult (8400 kJ / 2000 kcal)")
                    .font(.caption2)
                    .adaptiveSecondaryForeground()
                    .padding(.top, AppTheme.spacing4)
            }
        }
    }

    private func percent(_ value: Double, of reference: Double, _ isWhole: Bool) -> String? {
        isWhole ? nil : Format.percent(value, of: reference)
    }

    private func labelRow(label: String, value: String, unit: String, hero: Bool = false, percent: String? = nil) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: AppTheme.spacing4) {
            Text(label)
                .font(hero ? .headline : .subheadline)
                .adaptiveForegroundColor()
            Spacer()
            Text(value)
                .font(hero ? .headline.weight(.bold) : .subheadline.weight(.semibold))
                .adaptiveForegroundColor()
            Text(unit)
                .font(hero ? .subheadline : .caption)
                .adaptiveSecondaryForeground()
                .frame(minWidth: 28, alignment: .leading)
            Text(percent ?? "")
                .font(hero ? .caption : .caption2)
                .adaptiveSecondaryForeground()
                .frame(minWidth: 36, alignment: .trailing)
                .opacity(percent == nil ? 0 : 1)
        }
    }

    private func labelSubrow(label: String, value: String, unit: String, percent: String? = nil) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: AppTheme.spacing4) {
            Text(label)
                .font(.caption)
                .adaptiveSecondaryForeground()
                .padding(.leading, AppTheme.spacing16)
            Spacer()
            Text(value)
                .font(.caption.weight(.medium))
                .adaptiveSecondaryForeground()
            Text(unit)
                .font(.caption)
                .adaptiveSecondaryForeground()
                .frame(minWidth: 28, alignment: .leading)
            Text(percent ?? "")
                .font(.caption2)
                .adaptiveSecondaryForeground()
                .frame(minWidth: 36, alignment: .trailing)
                .opacity(percent == nil ? 0 : 1)
        }
    }
}

// MARK: - Nutrition macro bar

// Proportional calorie-split bar (fat/carbs/protein), so segments reflect energy not mass.
private struct NutritionMacroBar: View {
    let nutrition: NutritionInfo

    var body: some View {
        let split = NutritionLabelFormat.energySplit(nutrition)
        VStack(alignment: .leading, spacing: AppTheme.spacing8) {
            GeometryReader { geo in
                HStack(spacing: 2) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.orange)
                        .frame(width: max(geo.size.width * split.fat - 2, 4))

                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.teal)
                        .frame(width: max(geo.size.width * split.carbs - 2, 4))

                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.blue)
                        .frame(maxWidth: .infinity)
                }
                .clipShape(Capsule())
            }
            .frame(height: 10)

            HStack(spacing: 0) {
                macroLabel(name: "Fat", value: nutrition.fat, color: .orange)
                Spacer()
                macroLabel(name: "Carbs", value: nutrition.carbs, color: .teal)
                Spacer()
                macroLabel(name: "Protein", value: nutrition.protein, color: .blue)
            }
        }
    }

    private func macroLabel(name: String, value: Double, color: Color) -> some View {
        HStack(spacing: AppTheme.spacing4) {
            Circle()
                .fill(color)
                .frame(width: 7, height: 7)
            Text("\(name) \(Int(value.rounded()))g")
                .font(.caption2)
                .adaptiveSecondaryForeground()
        }
    }
}
