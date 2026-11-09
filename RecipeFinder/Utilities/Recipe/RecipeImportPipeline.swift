import Foundation

/// Structured web-page recipe data before it becomes a `RecipeModel`; Foundation-only + Codable so the extension can produce one, pass it via App Group, and the app builds the recipe on next launch.
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
    /// The page's readable text (≤ 50 KB), saved on the recipe as `sourceText` for "Re-import from original".
    /// Optional + defaulted so older App Group payloads still decode.
    var pageText: String? = nil
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

/// Pure fetch-and-parse core shared by `RecipeImporter` (observable UI wrapper) and the headless share extension; Foundation-only and singleton-free so it compiles into the extension without the UI/model layer.
struct RecipeImportPipeline: Sendable {
    private let fetcher: HTMLFetching

    init(fetcher: HTMLFetching = URLSessionHTMLFetcher()) {
        self.fetcher = fetcher
    }

    /// Fetches and parses the page, following up to five redirects; actor-free and UI-free so it's testable with a fake `HTMLFetching`.
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

        // Follow 3xx redirects; only fires for an injected fetcher that surfaces them (tests/extension) since production URLSession already does.
        if [301, 302, 303, 307, 308].contains(httpResponse.statusCode) {
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

        // Instructions optional (parser misses some layouts); leave empty rather than fabricate a step — source URL stays in notes and the flow prompts the user to add steps.
        let instructions = parsed.instructions

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
            imageURL: parsed.imageURL,
            pageText: Self.pageText(fromHTML: html)
        )

        return RecipeImportOutcome(data: extracted, confidence: parsed.confidence)
    }

    /// The page as readable text (scripts/styles/tags stripped by the parser's `cleanHTML`), capped at `limit` UTF-8
    /// bytes on a character boundary so a huge page can't bloat the store.
    static func pageText(fromHTML html: String, limit: Int = 50_000) -> String {
        let text = RecipeParser.cleanHTML(html)
        guard text.utf8.count > limit else { return text }
        var end = text.startIndex
        var bytes = 0
        for index in text.indices {
            let size = text[index].utf8.count
            guard bytes + size <= limit else { break }
            bytes += size
            end = text.index(after: index)
        }
        return String(text[..<end])
    }

    /// Decodes bytes to HTML: declared charset → UTF-8/legacy encodings → lossy UTF-8, so latin-1/CP1252 blogs (once `.invalidEncoding` failures) or a stray byte can't sink the import.
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
