import SwiftUI

/// Prep, cook, difficulty, category (and cuisine) in one slim card. These used to be two tall cards
/// that, with servings, pushed the ingredients most of a screen down. One row when every value fits at full size;
/// otherwise two rows — squeezing long values ("Intermediate", "Main course") into a row made them overlap.
struct RecipeFactsCard: View {
    let recipe: RecipeModel
    let onEdit: () -> Void

    var body: some View {
        let facts = RecipeDetailCopy.facts(for: recipe)
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .top, spacing: 0) {
                ForEach(facts) { fact($0) }
            }
            Grid(horizontalSpacing: 0, verticalSpacing: AppTheme.spacing12) {
                ForEach(RecipeDetailCopy.factRows(count: facts.count), id: \.self) { row in
                    GridRow {
                        ForEach(row, id: \.self) { fact(facts[$0]) }
                    }
                }
            }
        }
        .padding(.vertical, AppTheme.spacing12)
        .padding(.horizontal, AppTheme.spacing8)
        .appCard(elevated: true)
        .editableCard(onEdit: onEdit, hint: "Edit times, difficulty, category and cuisine")
        .accessibilityIdentifier("recipe.card.time")
    }

    private func fact(_ fact: RecipeFactText) -> some View {
        VStack(spacing: AppTheme.spacing4) {
            Image(systemName: fact.kind.icon)
                .font(.subheadline)
                .foregroundStyle(fact.kind.tint)
                .accessibilityHidden(true)
            Text(fact.value)
                .font(.subheadline.weight(.semibold))
                .adaptiveForegroundColor()
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
            Text(fact.kind.label)
                .font(.caption2)
                .adaptiveSecondaryForeground()
                .lineLimit(1)
        }
        .padding(.horizontal, AppTheme.spacing4)
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }
}

private extension RecipeFactKind {
    var tint: Color {
        switch self {
        case .prep: .orange
        case .cook: .red
        case .difficulty: .blue
        case .category: .green
        case .cuisine: .teal
        }
    }
}
