import Foundation

/// Structured recipe data pulled from a web page, before it's turned into a
/// `RecipeModel`. Foundation-only and `Codable` so the share extension can
/// produce one, hand it to the app through the App Group, and the app can build
/// the final recipe on next launch.
struct ExtractedRecipeData: Equatable, Sendable, Codable {
    let name: String
    let description: String?
    let matchedIngredients: [String]
    let rawIngredients: [String]
    let rawText: String
    let instructions: [String]
    let sourceURL: URL

    let cookTimeMinutes: Int?
    let prepTimeMinutes: Int?
    let servings: Int?
    let difficulty: String?
    let category: String?
    let cuisine: String?
    let imageURL: String?
}

struct RecipeImportOutcome: Equatable, Sendable {
    let data: ExtractedRecipeData
    let confidence: Double
}

enum RecipeImportError: LocalizedError, Equatable {
    case invalidResponse
    case invalidEncoding
    case missingRequiredData(String)
    case tooManyRedirects

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Could not connect to the website. The site may be blocking automated requests or experiencing issues. Please try copying the recipe manually."
        case .invalidEncoding:
            return "Could not read the webpage content"
        case .missingRequiredData(let detail):
            return "Missing required data: \(detail)"
        case .tooManyRedirects:
            return "Too many redirects. Please try a different URL."
        }
    }
}

/// Pure fetch-and-parse core shared by the app's `RecipeImporter` (which wraps it
/// in observable UI state) and the share extension (which runs it headless and
/// stashes the result). Foundation-only and free of app singletons so it compiles
/// into the extension target without dragging the UI/model layer along.
struct RecipeImportPipeline: Sendable {
    private let fetcher: HTMLFetching

    init(fetcher: HTMLFetching = URLSessionHTMLFetcher()) {
        self.fetcher = fetcher
    }

    /// Fetches the page and parses it into an outcome, following up to five
    /// redirects. Runs off any actor and touches no UI state, so it's unit-testable
    /// with a fake `HTMLFetching`.
    func fetchAndParse(from url: URL, redirectCount: Int = 0) async throws -> RecipeImportOutcome {
        guard redirectCount < 5 else {
            throw RecipeImportError.tooManyRedirects
        }

        var request = URLRequest(url: url)
        request.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1", forHTTPHeaderField: "User-Agent")
        request.setValue("text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8", forHTTPHeaderField: "Accept")
        request.setValue("en-US,en;q=0.9", forHTTPHeaderField: "Accept-Language")
        request.timeoutInterval = 30

        let (data, httpResponse) = try await fetcher.fetch(request)

        if httpResponse.statusCode == 301 || httpResponse.statusCode == 302 {
            if let location = httpResponse.value(forHTTPHeaderField: "Location"),
               let redirectURL = URL(string: location, relativeTo: url) {
                return try await fetchAndParse(from: redirectURL, redirectCount: redirectCount + 1)
            }
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw RecipeImportError.invalidResponse
        }

        let html = Self.decodeHTML(data, response: httpResponse)

        let parsed = RecipeParser.parse(html: html)

        guard let name = parsed.name, !name.isEmpty else {
            throw RecipeImportError.missingRequiredData("Recipe name not found")
        }

        guard !parsed.ingredients.isEmpty else {
            throw RecipeImportError.missingRequiredData("No ingredients found")
        }

        // Instructions are optional — many sites structure them in ways the parser misses
        let instructions = parsed.instructions.isEmpty ? ["See original recipe for instructions."] : parsed.instructions

        let extracted = ExtractedRecipeData(
            name: name,
            description: parsed.description,
            matchedIngredients: [],
            rawIngredients: parsed.ingredients,
            rawText: parsed.ingredients.joined(separator: "\n"),
            instructions: instructions,
            sourceURL: url,
            cookTimeMinutes: parsed.cookTime,
            prepTimeMinutes: parsed.prepTime,
            servings: parsed.servings,
            difficulty: parsed.difficulty,
            category: parsed.category,
            cuisine: parsed.cuisine,
            imageURL: parsed.imageURL
        )

        return RecipeImportOutcome(data: extracted, confidence: parsed.confidence)
    }

    /// Decodes fetched bytes into HTML text. Recipe blogs are frequently served as
    /// ISO-8859-1 / Windows-1252, for which a strict UTF-8 decode returns nil and
    /// used to kill the import (`.invalidEncoding`). Honour the response's declared
    /// charset first, then try UTF-8 and the common legacy encodings, and finally
    /// fall back to a lossy UTF-8 decode so a single stray byte can never sink the
    /// whole import.
    static func decodeHTML(_ data: Data, response: HTTPURLResponse) -> String {
        if let charset = response.textEncodingName {
            let cfEncoding = CFStringConvertIANACharSetNameToEncoding(charset as CFString)
            if cfEncoding != kCFStringEncodingInvalidId {
                let encoding = String.Encoding(rawValue: CFStringConvertEncodingToNSStringEncoding(cfEncoding))
                if let decoded = String(data: data, encoding: encoding) {
                    return decoded
                }
            }
        }

        for encoding in [String.Encoding.utf8, .windowsCP1252, .isoLatin1] {
            if let decoded = String(data: data, encoding: encoding) {
                return decoded
            }
        }

        // Lossy UTF-8 never fails; last resort so import degrades instead of dying.
        return String(decoding: data, as: UTF8.self)
    }
}
