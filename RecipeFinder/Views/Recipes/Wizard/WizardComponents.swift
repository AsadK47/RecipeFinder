import SwiftUI

// Shared chrome for the Recipe Wizard steps, extracted from `RecipeWizardView`.

/// Card surface for each wizard section; delegates to `.appCard()` so it matches every other card (and respects solid/frosted) instead of hand-rolling a fill.
struct WizardCard<Content: View>: View {
    @ViewBuilder let content: () -> Content

    var body: some View {
        content().appCard()
    }
}

