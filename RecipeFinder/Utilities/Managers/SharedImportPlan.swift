import Foundation

/// What the Recipes tab does with the share extension's inbox, decided off the view so the rules are unit tested:
/// every finished recipe is saved, the first link or text opens a sheet (one sheet at a time), and later links/texts
/// go back into the inbox for the next foreground.
struct SharedImportPlan: Equatable {
    /// A share that needs the cook's review in a sheet.
    enum Interactive: Equatable {
        case url(String)
        case text(String)
    }

    /// Whether a finished recipe from the extension may be saved silently.
    enum Verdict: Equatable {
        case add
        /// A recipe with the same name (ignoring case and surrounding spaces) is already in the library.
        case duplicate
        /// Missing ingredients or steps — the interactive import gates on this, so the silent path must too.
        case incomplete
    }

    private(set) var extracted: [ExtractedRecipeData] = []
    private(set) var interactive: Interactive?
    /// Oldest first, as they were shared.
    private(set) var requeued: [Interactive] = []

    init(payloads: [SharedImportInbox.Payload]) {
        for payload in payloads {
            let share: Interactive
            switch payload {
            case .extracted(let data):
                extracted.append(data)
                continue
            case .url(let url): share = .url(url)
            case .text(let text): share = .text(text)
            }
            if interactive == nil {
                interactive = share
            } else {
                requeued.append(share)
            }
        }
    }

    /// Puts the shares that didn't get the sheet back into the inbox, oldest first.
    func requeue(storeURL: (String) -> Void, storeText: (String) -> Void) {
        for share in requeued {
            switch share {
            case .url(let url): storeURL(url)
            case .text(let text): storeText(text)
            }
        }
    }

    static func verdict(for recipe: RecipeModel, existingNames: [String]) -> Verdict {
        let key = nameKey(recipe.name)
        if existingNames.contains(where: { nameKey($0) == key }) { return .duplicate }
        if recipe.ingredients.isEmpty || recipe.instructions.isEmpty { return .incomplete }
        return .add
    }

    private static func nameKey(_ name: String) -> String {
        name.trimmingCharacters(in: .whitespaces).lowercased()
    }
}
