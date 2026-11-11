import Foundation

/// A heads-up on Today that a meal planned for tomorrow needs starting tonight (marinate, soak, defrost, prove…).
struct PrepAheadNudge: Equatable {
    let recipe: RecipeModel
    let mealTime: MealTime
    /// The verb to show, e.g. "Marinate".
    let cue: String

    var message: String { "\(cue) tonight for tomorrow's \(mealTime.rawValue.lowercased())" }
}

/// Spots recipe steps that need a long lead time. Pure so the wording rules are testable.
enum PrepAhead {
    /// Long-lead verbs, checked in order; the first one found in the step names the cue.
    private static let verbs: [(pattern: String, cue: String)] = [
        (#"\bmarinat"#, "Marinate"),
        (#"\bsoak"#, "Soak"),
        (#"\b(defrost|thaw)"#, "Defrost"),
        (#"\b(prove|proof|rise)"#, "Prove"),
        (#"\b(chill(ed|ing|s)?\b|refrigerat)"#, "Chill")
    ]

    /// A long-lead verb followed (within the same sentence) by a wait of 2+ hours, e.g. "marinate for at least 4 hours".
    private static let longWait =
        #"\b(marinat\w*|soak\w*|prove|proof\w*|rise|chill(?:ed|ing|s)?|refrigerat\w*)\b[^.]{0,40}?\b([2-9]|[1-9][0-9])\s*(hours?|hrs?)\b"#

    /// The cue for the first step that needs starting the day before, else nil.
    static func cue(for recipe: RecipeModel) -> String? {
        for step in recipe.prePrepInstructions + recipe.instructions {
            if let cue = cue(forStep: step) { return cue }
        }
        return nil
    }

    /// "Overnight", any defrost/thaw, or a long-lead verb with a 2+ hour wait. Short soaks/chills ("soak for
    /// 10 minutes") and "no need to thaw" don't count — those fit in tonight's cooking.
    static func cue(forStep step: String) -> String? {
        let text = step.lowercased()
        let needsLead = text.contains("overnight")
            || matches(text, #"(?<!no need to )\b(defrost|thaw)"#)
            || matches(text, longWait)
        guard needsLead else { return nil }
        return verbs.first { matches(text, $0.pattern) }?.cue ?? "Prep"
    }

    /// Tomorrow's open plans whose recipe needs starting tonight, in meal order; one nudge per recipe.
    static func nudges(recipes: [RecipeModel], tomorrowsPlans: [MealPlanModel]) -> [PrepAheadNudge] {
        var seen = Set<UUID>()
        return tomorrowsPlans
            .filter { !$0.isCompleted }
            .sorted { $0.mealTime.sortOrder < $1.mealTime.sortOrder }
            .compactMap { plan in
                guard !seen.contains(plan.recipeId),
                      let recipe = recipes.first(where: { $0.id == plan.recipeId }),
                      let cue = cue(for: recipe) else { return nil }
                seen.insert(plan.recipeId)
                return PrepAheadNudge(recipe: recipe, mealTime: plan.mealTime, cue: cue)
            }
    }

    private static func matches(_ text: String, _ pattern: String) -> Bool {
        text.range(of: pattern, options: .regularExpression) != nil
    }
}
