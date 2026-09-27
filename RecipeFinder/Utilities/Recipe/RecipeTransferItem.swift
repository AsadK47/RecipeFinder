import CoreTransferable
import UniformTypeIdentifiers

/// Wraps a `RecipeModel` for `ShareLink`: exports a `.recipefinderrecipe` file for direct import by other users, plain text elsewhere.
struct RecipeTransferItem: Transferable {
    let recipe: RecipeModel

    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(contentType: .recipeFile) { item in
            let safeName = item.recipe.name
                .components(separatedBy: .init(charactersIn: "/:\\"))
                .joined(separator: "-")
                .trimmingCharacters(in: .whitespaces)
            let url = FileManager.default.temporaryDirectory
                .appendingPathComponent(safeName.isEmpty ? "recipe" : safeName)
                .appendingPathExtension("recipefinderrecipe")
            try RecipeFileExporter.write(item.recipe, to: url)
            return SentTransferredFile(url)
        } importing: { received in
            let data = try Data(contentsOf: received.file)
            return RecipeTransferItem(recipe: try RecipeFileExporter.decode(data))
        }

        // Plain-text fallback for Mail, Messages, Notes, etc.
        DataRepresentation(exportedContentType: .utf8PlainText) { item in
            Data(item.recipe.shareText.utf8)
        }
    }
}
