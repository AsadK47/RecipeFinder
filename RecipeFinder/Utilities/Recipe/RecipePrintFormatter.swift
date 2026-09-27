import UIKit

private let logger = AppLogger.logger(category: "Print")

/// Print-ready HTML for a recipe + `UIPrintInteractionController` presentation; `html(for:)` is pure/testable, `present(for:)` is the thin untested UIKit bridge.
enum RecipePrintFormatter {

    // MARK: - Present

    @MainActor
    static func present(for recipe: RecipeModel) {
        guard UIPrintInteractionController.isPrintingAvailable else {
            logger.debug("⚠️ Printing not available on this device")
            return
        }
        let controller = UIPrintInteractionController.shared
        let formatter = UIMarkupTextPrintFormatter(markupText: html(for: recipe))
        formatter.perPageContentInsets = UIEdgeInsets(top: 72, left: 72, bottom: 72, right: 72)
        controller.printFormatter = formatter

        if UIDevice.current.userInterfaceIdiom == .pad {
            guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let window = scene.windows.first else { return }
            controller.present(from: window.frame, in: window, animated: true, completionHandler: nil)
        } else {
            controller.present(animated: true, completionHandler: nil)
        }
    }

    // MARK: - HTML generation

    static func html(for recipe: RecipeModel) -> String {
        let metaParts: [String] = [
            recipe.prepTime.isEmpty  ? nil : "Prep: \(recipe.prepTime.htmlEscaped)",
            recipe.cookingTime.isEmpty ? nil : "Cook: \(recipe.cookingTime.htmlEscaped)",
            "Serves \(recipe.baseServings)",
            recipe.difficulty.isEmpty ? nil : recipe.difficulty.htmlEscaped,
            recipe.cuisine?.htmlEscaped
        ].compactMap { $0 }
        let meta = metaParts.joined(separator: " · ")

        let ingredientItems = recipe.ingredients.map { ingredient -> String in
            let qty = FractionFormatter.format(ingredient.baseQuantity)
            let unit = ingredient.unit.isEmpty ? "" : " \(ingredient.unit.htmlEscaped)"
            return "<li>\(qty)\(unit) \(ingredient.name.htmlEscaped)</li>"
        }.joined(separator: "\n")

        var body = ""

        if !recipe.prePrepInstructions.isEmpty {
            let steps = recipe.prePrepInstructions
                .map { "<li>\($0.htmlEscaped)</li>" }
                .joined(separator: "\n")
            body += "<h2>Pre-Prep</h2><ol>\(steps)</ol>\n"
        }

        let instructionItems = recipe.instructions
            .map { "<li>\($0.htmlEscaped)</li>" }
            .joined(separator: "\n")
        body += "<h2>Instructions</h2><ol>\(instructionItems)</ol>\n"

        if !recipe.notesForDisplay.isEmpty {
            body += "<h2>Notes</h2><p class=\"notes\">\(recipe.notesForDisplay.htmlEscaped)</p>\n"
        }

        return """
        <!DOCTYPE html>
        <html>
        <head>
        <meta charset="utf-8">
        <style>
        body { font-family: -apple-system, Helvetica Neue, sans-serif; font-size: 13px; color: #111; }
        h1 { font-size: 26px; margin: 0 0 8px; }
        .meta { color: #555; margin-bottom: 24px; font-size: 12px; }
        h2 { font-size: 15px; font-weight: 600; margin: 20px 0 8px; border-bottom: 1px solid #ddd; padding-bottom: 4px; }
        .ingredients { columns: 2; column-gap: 24px; list-style: none; padding: 0; margin: 0; }
        .ingredients li { padding: 3px 0; border-bottom: 1px solid #eee; break-inside: avoid; font-size: 12px; }
        ol { padding-left: 20px; margin: 0; }
        ol li { margin-bottom: 10px; line-height: 1.5; }
        .notes { color: #444; line-height: 1.6; white-space: pre-wrap; }
        .footer { margin-top: 32px; font-size: 10px; color: #aaa; border-top: 1px solid #eee; padding-top: 6px; }
        </style>
        </head>
        <body>
        <h1>\(recipe.name.htmlEscaped)</h1>
        <p class="meta">\(meta)</p>
        <h2>Ingredients</h2>
        <ul class="ingredients">
        \(ingredientItems)
        </ul>
        \(body)<p class="footer">Printed from RecipeFinder</p>
        </body>
        </html>
        """
    }
}

private extension String {
    var htmlEscaped: String {
        replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
    }
}
