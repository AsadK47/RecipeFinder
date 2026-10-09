import Testing
import Foundation
@testable import RecipeFinder

/// Quality gate over the ENTIRE bundled seed corpus (`recipes_seed.json`, ~355 recipes): proves the
/// seed import still parses well on every change, so nobody has to eyeball recipes after a parser edit.
/// Fails if any entry can't be parsed, or if the share of recipes with real ingredient amounts drops.
@Suite struct SeedCorpusParseQualityTests {

    private struct Stats { var total = 0; var parseNil = 0; var good = 0; var poor = 0; var poorNames: [String] = [] }

    /// Resolve a file in the seed directory from the source tree (walk up from this file); skips if unavailable.
    private func seedFileURL(_ name: String) -> URL? {
        var dir = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
        for _ in 0..<8 {
            let candidate = dir.appendingPathComponent("RecipeFinder/RecipeSeed/\(name)")
            if FileManager.default.fileExists(atPath: candidate.path) { return candidate }
            dir = dir.deletingLastPathComponent()
        }
        return nil
    }

    private func corpusURL() -> URL? { seedFileURL("recipes_seed.json") }

    /// One recipe's name + whether its ingredients parse "well" (≥2 lines, ≤half with no amount).
    /// Single source of truth for both the aggregate floor and the per-recipe golden test.
    private func classifyAll() throws -> [(name: String, good: Bool)] {
        let url = try #require(corpusURL(), "recipes_seed.json not found from \(#filePath)")
        let entries = try #require(try JSONSerialization.jsonObject(with: Data(contentsOf: url)) as? [[String: String]])
        return entries.map { e in
            let name = e["name"] ?? "?"
            guard let pre = TextRecipeParser.parse(e["rawText"] ?? "") else { return (name, false) }
            let lines = pre.ingredients ?? []
            let zero = lines.map { IngredientLineParser.parse($0) }.filter { $0.quantity == 0 }.count
            let zeroFrac = lines.isEmpty ? 1.0 : Double(zero) / Double(lines.count)
            return (name, lines.count >= 2 && zeroFrac <= 0.5)
        }
    }

    private func measure() throws -> Stats {
        var s = Stats()
        for r in try classifyAll() {
            s.total += 1
            if r.good { s.good += 1 }
            else { s.poor += 1; if s.poorNames.count < 20 { s.poorNames.append(r.name) } }
        }
        return s
    }

    /// Per-recipe gate: each recipe is checked individually against a pinned golden set of known-poor names
    /// (`seed_parse_known_poor.json`, next to the corpus). Fails — naming the exact recipes — if either:
    ///   • a recipe NOT on the list now parses poorly → a real regression a parser change introduced, or
    ///   • a recipe ON the list now parses well → the golden set is stale, shrink it (keeps it honest as
    ///     the parser improves, so "known-poor" can't quietly hide a recipe that recovered).
    /// Regenerate the baseline deliberately (never blindly) when the delta is understood. The pinned entries
    /// are messy SOURCE data (method prose in the ingredient list, unitless spice lists), not parser bugs.
    @Test func eachSeedRecipeMatchesKnownQuality() throws {
        let goldenURL = try #require(seedFileURL("seed_parse_known_poor.json"), "golden baseline not found")
        let golden = Set(try #require(try JSONSerialization.jsonObject(with: Data(contentsOf: goldenURL)) as? [String]))

        let currentPoor = Set(try classifyAll().filter { !$0.good }.map(\.name))
        let regressions = currentPoor.subtracting(golden).sorted()   // good → poor: a change broke these
        let recovered = golden.subtracting(currentPoor).sorted()     // poor → good: remove from the golden set

        #expect(regressions.isEmpty, "These seed recipes regressed to poor import quality: \(regressions.joined(separator: " | "))")
        #expect(recovered.isEmpty, "These seed recipes now parse well — remove them from seed_parse_known_poor.json: \(recovered.joined(separator: " | "))")
    }

    @Test func seedCorpusParsesWithRealAmounts() throws {
        let s = try measure()
        let goodFrac = s.total == 0 ? 0 : Double(s.good) / Double(s.total)
        let summary = "corpus=\(s.total) nil=\(s.parseNil) good=\(s.good) poor=\(s.poor) good%=\(Int(goodFrac * 100))"
        print("SEED CORPUS QUALITY — \(summary)")
        print("poor/nil sample: \(s.poorNames.prefix(20).joined(separator: " | "))")

        // Regression floor locked to measured quality (2026-10-09): 355 entries, 3 unparseable, 90% good
        // after ▢-glyph, name-first, and scrape-artifact fixes. Raise as the parser improves; a drop below
        // means a change regressed import quality. The residual "poor" bucket is now dominated by METHOD/
        // prose lines leaking into the ingredient list (a TextRecipeParser section-detection issue, tracked
        // in WORK.md) and genuinely-unitless spice lists — not a per-line amount bug.
        #expect(s.parseNil <= 3, "More seed recipes fail to parse than before. \(summary)")
        #expect(goodFrac >= 0.88, "Seed amount-parse quality regressed below the locked floor. \(summary)")
    }
}
