import Foundation

/// A recipe read from another app's export (Paprika, Mela, CSV) before it becomes a `RecipeModel`.
struct OtherAppRecipe: Equatable, Sendable {
    var name: String
    var ingredients: [String]
    var instructions: [String]
    var prepMinutes: Int?
    var cookMinutes: Int?
    var servings: Int?
    var notes: String?
    var sourceURL: String?
    var category: String?
    /// The recipe's photo when the export embeds one (base64 in Paprika and Mela).
    var photoData: Data?
}

/// Field mapping shared by the per-app parsers: exports put lists in one newline-separated string and times in prose.
enum OtherAppFields {
    /// "200 g flour\n\n2 eggs" → ["200 g flour", "2 eggs"]; blank lines dropped.
    static func lines(_ text: String?) -> [String] {
        (text ?? "")
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
    }

    /// "1 hr 15 min" → 75; empty or unreadable → nil (not 0, so the gap stays visible).
    static func minutes(_ text: String?) -> Int? {
        guard let text = text?.trimmingCharacters(in: .whitespaces), !text.isEmpty else { return nil }
        let value = TimeExtractor.extractMinutes(from: text)
        return value > 0 ? value : nil
    }

    /// "Serves 4", "4-6 servings", "4" → the first whole number.
    static func servings(_ text: String?) -> Int? {
        guard let text, let match = text.firstMatch(of: /\d+/), let value = Int(match.output), value > 0 else {
            return nil
        }
        return value
    }

    static func text(_ value: Any?) -> String? {
        guard let string = value as? String else { return nil }
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    static func base64(_ value: Any?) -> Data? {
        guard let string = value as? String, !string.isEmpty else { return nil }
        return Data(base64Encoded: string, options: .ignoreUnknownCharacters)
    }
}

/// One Paprika recipe (the gzipped JSON inside a `.paprikarecipes` export).
enum PaprikaRecipeParser {
    static func parse(json: Data) -> OtherAppRecipe? {
        guard let object = (try? JSONSerialization.jsonObject(with: json)) as? [String: Any],
              let name = OtherAppFields.text(object["name"]) else { return nil }
        return OtherAppRecipe(
            name: name,
            ingredients: OtherAppFields.lines(object["ingredients"] as? String),
            instructions: OtherAppFields.lines(object["directions"] as? String),
            prepMinutes: OtherAppFields.minutes(object["prep_time"] as? String),
            cookMinutes: OtherAppFields.minutes(object["cook_time"] as? String),
            servings: OtherAppFields.servings(object["servings"] as? String),
            notes: OtherAppFields.text(object["notes"]),
            sourceURL: OtherAppFields.text(object["source_url"]),
            category: (object["categories"] as? [String])?.first,
            photoData: OtherAppFields.base64(object["photo_data"])
        )
    }
}

/// One Mela recipe (a `.melarecipe` file, or one entry of a `.melarecipes` export).
enum MelaRecipeParser {
    static func parse(json: Data) -> OtherAppRecipe? {
        guard let object = (try? JSONSerialization.jsonObject(with: json)) as? [String: Any],
              let name = OtherAppFields.text(object["title"]) else { return nil }
        return OtherAppRecipe(
            name: name,
            ingredients: OtherAppFields.lines(object["ingredients"] as? String),
            instructions: OtherAppFields.lines(object["instructions"] as? String),
            prepMinutes: OtherAppFields.minutes(object["prepTime"] as? String),
            cookMinutes: OtherAppFields.minutes(object["cookTime"] as? String),
            servings: OtherAppFields.servings(object["yield"] as? String),
            notes: OtherAppFields.text(object["notes"]),
            sourceURL: OtherAppFields.text(object["link"]),
            category: (object["categories"] as? [String])?.first,
            photoData: OtherAppFields.base64((object["images"] as? [Any])?.first)
        )
    }
}

/// A spreadsheet export with a header row naming at least the recipe-name column; ingredient and instruction cells hold
/// one item per line. Quoted fields may contain commas, doubled quotes and newlines (RFC 4180).
enum CSVRecipeParser {
    static func parse(csv: String) -> [OtherAppRecipe] {
        let rows = records(in: csv)
        guard let header = rows.first?.map({ $0.trimmingCharacters(in: .whitespaces).lowercased() }) else { return [] }
        func column(_ names: String...) -> Int? { header.firstIndex { names.contains($0) } }
        guard let nameColumn = column("name", "title", "recipe") else { return [] }
        let ingredientsColumn = column("ingredients")
        let instructionsColumn = column("instructions", "directions", "method", "steps")
        let servingsColumn = column("servings", "yield", "serves")
        let prepColumn = column("prep time", "prep_time", "preptime")
        let cookColumn = column("cook time", "cook_time", "cooktime")
        let notesColumn = column("notes")
        let sourceColumn = column("source", "url", "source_url", "link")

        return rows.dropFirst().compactMap { row in
            func cell(_ index: Int?) -> String? {
                guard let index, row.indices.contains(index) else { return nil }
                return OtherAppFields.text(row[index])
            }
            guard let name = cell(nameColumn) else { return nil }
            return OtherAppRecipe(
                name: name,
                ingredients: OtherAppFields.lines(cell(ingredientsColumn)),
                instructions: OtherAppFields.lines(cell(instructionsColumn)),
                prepMinutes: OtherAppFields.minutes(cell(prepColumn)),
                cookMinutes: OtherAppFields.minutes(cell(cookColumn)),
                servings: OtherAppFields.servings(cell(servingsColumn)),
                notes: cell(notesColumn),
                sourceURL: cell(sourceColumn)
            )
        }
    }

    /// Splits CSV text into rows of fields, honouring quotes.
    static func records(in csv: String) -> [[String]] {
        var rows: [[String]] = []
        var row: [String] = []
        var field = ""
        var inQuotes = false
        var characters = csv.makeIterator()
        var pending: Character?

        while let character = pending ?? characters.next() {
            pending = nil
            if inQuotes {
                if character == "\"" {
                    let next = characters.next()
                    if next == "\"" {
                        field.append("\"")
                    } else {
                        inQuotes = false
                        pending = next
                    }
                } else {
                    field.append(character)
                }
                continue
            }
            switch character {
            case "\"" where field.isEmpty:
                inQuotes = true
            case ",":
                row.append(field)
                field = ""
            case "\n", "\r\n", "\r":
                row.append(field)
                field = ""
                if row.contains(where: { !$0.isEmpty }) { rows.append(row) }
                row = []
            default:
                field.append(character)
            }
        }
        row.append(field)
        if row.contains(where: { !$0.isEmpty }) { rows.append(row) }
        return rows
    }
}

/// Turns parsed recipes into library recipes, skipping ones the library (or the same export) already has.
enum OtherAppImportPlanner {
    struct Plan: Equatable {
        var recipes: [RecipeModel]
        var skippedDuplicates: Int
        /// Embedded photos by recipe id, saved alongside the recipes (image files live outside `RecipeModel`).
        var photos: [UUID: Data] = [:]

        /// "Imported 182 recipes, skipped 3 duplicates."
        var summary: String {
            let imported = recipes.count == 1 ? "1 recipe" : "\(recipes.count) recipes"
            guard skippedDuplicates > 0 else { return "Imported \(imported)." }
            let skipped = skippedDuplicates == 1 ? "1 duplicate" : "\(skippedDuplicates) duplicates"
            return "Imported \(imported), skipped \(skipped)."
        }
    }

    static func plan(_ incoming: [OtherAppRecipe], existing: [RecipeModel], source: String) -> Plan {
        var seen = Set(existing.map { key(name: $0.name, ingredients: $0.ingredients.map(\.displayName)) })
        var recipes: [RecipeModel] = []
        var photos: [UUID: Data] = [:]
        var skipped = 0
        let builder = RecipeImportBuilder()
        for recipe in incoming {
            let model = makeModel(recipe, source: source, builder: builder)
            let identity = key(name: model.name, ingredients: model.ingredients.map(\.displayName))
            guard seen.insert(identity).inserted else {
                skipped += 1
                continue
            }
            recipes.append(model)
            photos[model.id] = recipe.photoData
        }
        return Plan(recipes: recipes, skippedDuplicates: skipped, photos: photos)
    }

    /// Same recipe = same name and same ingredient names, ignoring case, spacing and order.
    static func key(name: String, ingredients: [String]) -> String {
        func normal(_ text: String) -> String {
            text.lowercased().split(whereSeparator: \.isWhitespace).joined(separator: " ")
        }
        return normal(name) + "|" + ingredients.map(normal).sorted().joined(separator: "|")
    }

    static func makeModel(_ recipe: OtherAppRecipe, source: String, builder: RecipeImportBuilder) -> RecipeModel {
        var notes = recipe.notes.map { [$0, ""] } ?? []
        notes.append("Imported from \(source)")
        if let url = recipe.sourceURL { notes.append(url) }
        return RecipeModel(
            name: recipe.name,
            category: recipe.category ?? "Main",
            difficulty: RecipeWizardBuilder.normalizeDifficulty(""),
            prepTime: "\(recipe.prepMinutes ?? 0) minutes",
            cookingTime: "\(recipe.cookMinutes ?? 0) minutes",
            baseServings: recipe.servings ?? 4,
            ingredients: builder.parseIngredients(recipe.ingredients),
            prePrepInstructions: [],
            instructions: recipe.instructions,
            notes: notes.joined(separator: "\n"),
            sourceText: sourceText(for: recipe)
        )
    }

    /// The recipe as plain text, kept as `sourceText` so "Re-import from original" can re-parse it later.
    static func sourceText(for recipe: OtherAppRecipe) -> String {
        ([recipe.name, "", "Ingredients"] + recipe.ingredients + ["", "Method"] + recipe.instructions)
            .joined(separator: "\n")
    }
}
