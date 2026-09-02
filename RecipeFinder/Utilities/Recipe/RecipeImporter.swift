import Foundation
import SwiftUI

private let logger = AppLogger.logger(category: "RecipeImporter")

/// Observable wrapper around `RecipeImportPipeline` that drives the interactive
/// import UI. The fetch/parse logic itself lives in the pipeline (Foundation-only,
/// shared with the share extension); this type only adds `@Published` state and
/// the network-availability guard.
@MainActor
final class RecipeImporter: ObservableObject {
    // The concrete types moved to `RecipeImportPipeline` so the extension can
    // share them; callers and tests still reach them through `RecipeImporter`.
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

    /// Drives the observable UI state around a single import: fetches + parses
    /// off the main actor, then publishes the result (or an error message).
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

    /// Delegates to the shared pipeline. Kept as an instance method for source and
    /// test compatibility with the pre-extraction API.
    nonisolated func fetchAndParse(from url: URL, redirectCount: Int = 0) async throws -> ImportOutcome {
        try await pipeline.fetchAndParse(from: url, redirectCount: redirectCount)
    }
}
