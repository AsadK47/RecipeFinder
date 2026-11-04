import Testing
import Foundation
@testable import RecipeFinder

/// Renders EVERY bundled recipe through the same display code the screens use (`Ingredient.displayParts`,
/// `IngredientRowView.amount`, time labels) in Metric and Imperial, and lints what a user would actually read.
/// Fails listing each offending recipe; the full rendering of flagged recipes is written to /tmp for review.
@MainActor
@Suite("Bundled recipe render audit")
struct BundledRecipeRenderAuditTests {

    struct Finding: CustomStringConvertible {
        let recipe: String
        let problem: String
        var description: String { "\(recipe): \(problem)" }
    }

    // MARK: - Rendering (what the screen shows)

    static func renderedIngredient(_ ingredient: Ingredient, system: MeasurementSystem) -> (amount: String, name: String, note: String?) {
        let amount = IngredientRowView.amount(for: ingredient, scaleFactor: 1, system: system)
        let parts = ingredient.displayParts
        return ([amount.quantity, amount.unit].compactMap { $0 }.joined(separator: " "), parts.name, parts.note)
    }

    static func render(_ recipe: RecipeModel) -> String {
        var lines = ["## \(recipe.name)  [\(recipe.category) · \(recipe.difficulty) · prep \(recipe.prepTimeDisplay) · cook \(recipe.cookTimeDisplay) · serves \(recipe.baseServings)]"]
        for system in [MeasurementSystem.metric, .imperial] {
            lines.append("  \(system == .metric ? "Metric" : "Imperial"):")
            for ingredient in recipe.ingredients {
                let r = renderedIngredient(ingredient, system: system)
                lines.append("    • \(r.amount.isEmpty ? "" : r.amount + " ")\(r.name)\(r.note.map { " — \($0)" } ?? "")")
            }
        }
        for (index, step) in (recipe.prePrepInstructions + recipe.instructions).enumerated() {
            lines.append("  \(index + 1). \(step)")
        }
        return lines.joined(separator: "\n")
    }

    // MARK: - Lint rules

    static let measuredUnits: Set<String> = ["g", "kg", "ml", "L", "oz", "lb", "cup", "cups", "tsp", "tbsp"]
    static let unitWords = ["cup ", "cups ", "tbsp ", "tsp ", "tablespoon", "teaspoon", "grams ", "ml ", "oz ", "lb "]

    static func lint(_ recipe: RecipeModel) -> [String] {
        var problems: [String] = []
        let title = recipe.name
        if title.isEmpty || title.count > 60 { problems.append("title length \(title.count): \"\(title)\"") }
        if title.range(of: #"https?://|\d+\.\d+|PREP|COOK TIME|Serves \d"#, options: .regularExpression) != nil {
            problems.append("junk in title: \"\(title)\"")
        }
        if !(1...30).contains(recipe.baseServings) { problems.append("servings \(recipe.baseServings)") }
        let prep = TimeExtractor.extractMinutes(from: recipe.prepTime), cook = TimeExtractor.extractMinutes(from: recipe.cookingTime)
        if prep > 24 * 60 || cook > 3 * 24 * 60 { problems.append("implausible time prep \(prep) cook \(cook)") }
        if recipe.ingredients.isEmpty { problems.append("no ingredients") }
        if recipe.instructions.isEmpty { problems.append("no steps") }
        if recipe.instructions.count > 25 { problems.append("\(recipe.instructions.count) steps") }

        var seenRows = Set<String>()
        for ingredient in recipe.ingredients {
            for system in [MeasurementSystem.metric, .imperial] {
                let r = renderedIngredient(ingredient, system: system)
                let label = "\(system == .metric ? "M" : "I") \"\(r.amount) \(r.name)\(r.note.map { ", " + $0 } ?? "")\""
                if r.amount.contains(".") { problems.append("decimal amount \(label)") }
                let amountUnit = IngredientRowView.amount(for: ingredient, scaleFactor: 1, system: system)
                if amountUnit.quantity == nil, let unit = amountUnit.unit, measuredUnits.contains(unit) {
                    problems.append("unit without amount \(label)")
                }
                if system == .metric {
                    let value = UnitConversion.convert(value: ingredient.baseQuantity, unit: ingredient.unit, to: .metric,
                                                       ingredientName: ingredient.name)
                    if (["g", "ml"].contains(value.unit) && value.quantity > 5000) || (value.unit.isEmpty && value.quantity > 60) {
                        problems.append("implausible amount \(label)")
                    }
                }
            }
            let r = renderedIngredient(ingredient, system: .metric)
            let full = r.name + (r.note.map { ", " + $0 } ?? "")
            if r.name.trimmingCharacters(in: .whitespaces).isEmpty { problems.append("empty ingredient name") }
            if full.filter({ $0 == "(" }).count != full.filter({ $0 == ")" }).count { problems.append("unbalanced brackets \"\(full)\"") }
            if full.contains("http") { problems.append("URL in ingredient \"\(full)\"") }
            let words = r.name.split(separator: " ").map(String.init)
            if words.count >= 3, words.allSatisfy({ $0.first?.isUppercase == true }) { problems.append("Title Case \"\(r.name)\"") }
            if unitWords.contains(where: { r.name.lowercased().hasPrefix($0) }) { problems.append("unit word in name \"\(r.name)\"") }
            // Back-to-back duplicates ("pieces pieces", "agar agar" is a real name) — alternatives like
            // "rice vinegar or white vinegar" legitimately repeat words, so only adjacency counts.
            let tokens = full.lowercased().split(whereSeparator: { !$0.isLetter }).map(String.init)
            if let dup = zip(tokens, tokens.dropFirst()).first(where: { $0 == $1 && $0.count > 2 && $0 != "agar" && $0 != "peri" }) {
                problems.append("doubled word '\(dup.0)' in \"\(full)\"")
            }
            // Same prep word in the name and again in the note ("onion, diced, diced").
            if let note = r.note {
                let nameWords = Set(r.name.lowercased().split(separator: " ").map(String.init))
                let prepWords: Set<String> = ["diced", "chopped", "sliced", "minced", "grated", "melted", "crushed", "peeled", "pieces"]
                let noteLead = note.lowercased().split(separator: " ").first.map(String.init) ?? ""
                if let clash = nameWords.intersection(prepWords).first(where: { $0 == noteLead }) {
                    problems.append("'\(clash)' in name and note \"\(full)\"")
                }
            }
            // Same displayed text twice reads like a paste error even with different units ("oil" 1 cup / 3 tsp).
            let rowKey = full.lowercased()
            if !seenRows.insert(rowKey).inserted { problems.append("duplicate row \"\(full)\"") }
        }

        for step in recipe.prePrepInstructions + recipe.instructions {
            let trimmed = step.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.split(separator: " ").count < 2 { problems.append("very short step \"\(trimmed)\"") }
            if trimmed.contains("http") { problems.append("URL in step") }
            if trimmed.range(of: #"^(notes?|nutrition|video|calories|pin|print)\b"#, options: [.regularExpression, .caseInsensitive]) != nil {
                problems.append("junk step \"\(trimmed.prefix(40))\"")
            }
            if let last = trimmed.last, !".!?)\"'”".contains(last) { problems.append("step not finished \"…\(trimmed.suffix(40))\"") }
        }
        return problems
    }

    // MARK: - The audit

    @Test("every bundled recipe reads cleanly on screen in Metric and Imperial")
    func everyRecipeReadsCleanly() {
        let recipes = SeedRecipeProvider.recipes + BundledRecipeCatalog.load()
        #expect(recipes.count > 300)
        var findings: [Finding] = []
        var report: [String] = []
        for recipe in recipes {
            let problems = Self.lint(recipe)
            guard !problems.isEmpty else { continue }
            findings += problems.map { Finding(recipe: recipe.name, problem: $0) }
            report.append(Self.render(recipe) + "\n  PROBLEMS:\n" + problems.map { "   - \($0)" }.joined(separator: "\n"))
        }
        let path = FileManager.default.temporaryDirectory.appendingPathComponent("recipe_render_audit.txt")
        try? (report.joined(separator: "\n\n")).write(to: path, atomically: true, encoding: .utf8)
        let flagged = Set(findings.map(\.recipe)).count
        #expect(findings.isEmpty, "\(findings.count) problems in \(flagged) recipes (full renderings: \(path.path)):\n\(findings.prefix(60).map(\.description).joined(separator: "\n"))")
    }
}
