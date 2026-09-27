import Foundation
import SwiftUI

private let logger = AppLogger.logger(category: "RecipeImporter")

/// Observable wrapper driving the interactive import UI; fetch/parse lives in `RecipeImportPipeline`, this only adds `@Published` state and the network guard.
@MainActor
final class RecipeImporter: ObservableObject {
    // Concrete types live in `RecipeImportPipeline` (shared with the extension); callers/tests still reach them via `RecipeImporter`.
    typealias ExtractedRecipeData = RecipeFinder.ExtractedRecipeData
    typealias ImportOutcome = RecipeImportOutcome
    typealias ImportError = RecipeImportError

    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var extractedData: ExtractedRecipeData?
    @Published var parseConfidence: Double = 0.0

    private let pipeline: RecipeImportPipeline
    private let isNetworkAvailable: () async -> Bool

    init(
        fetcher: HTMLFetching = URLSessionHTMLFetcher(),
        isNetworkAvailable: @escaping () async -> Bool = { NetworkMonitor.shared.isConnected }
    ) {
        self.pipeline = RecipeImportPipeline(fetcher: fetcher)
        self.isNetworkAvailable = isNetworkAvailable
    }

    /// Drives observable state for one import: fetch+parse off the main actor, then publish the result or an error message.
    func importRecipe(from url: URL) async {
        isLoading = true
        errorMessage = nil
        extractedData = nil

        guard await isNetworkAvailable() else {
            isLoading = false
            errorMessage = AppError.networkUnavailable.localizedDescription
            return
        }

        do {
            let outcome = try await fetchAndParse(from: url)
            parseConfidence = outcome.confidence
            extractedData = outcome.data
            isLoading = false
            logger.debug("🎉 Import complete!")
        } catch {
            isLoading = false
            errorMessage = (error as? ImportError)?.errorDescription ?? error.localizedDescription
            logger.error("❌ Import failed: \(error.localizedDescription)")
        }
    }

    /// Delegates to the shared pipeline; kept an instance method for source/test compatibility with the pre-extraction API.
    nonisolated func fetchAndParse(from url: URL, redirectCount: Int = 0) async throws -> ImportOutcome {
        try await pipeline.fetchAndParse(from: url, redirectCount: redirectCount)
    }
}
