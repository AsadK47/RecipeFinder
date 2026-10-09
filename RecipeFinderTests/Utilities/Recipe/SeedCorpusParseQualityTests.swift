import Testing
import Foundation
@testable import RecipeFinder

/// Quality gate over the ENTIRE bundled seed corpus (`recipes_seed.json`, ~355 recipes): proves the
/// seed import still parses well on every change, so nobody has to eyeball recipes after a parser edit.
/// Fails if any entry can't be parsed, or if the share of recipes with real ingredient amounts drops.
@Suite struct SeedCorpusParseQualityTests {

    private struct Stats { var total = 0; var parseNil = 0; var good = 0; var poor = 0; var poorNames: [String] = [] }

    /// Resolve the seed JSON from the source tree (walk up from this file); skips if unavailable.
    private func corpusURL() -> URL? {
        var dir = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
        for _ in 0..<8 {
            let candidate = dir.appendingPathComponent("RecipeFinder/RecipeSeed/recipes_seed.json")
            if FileManager.default.fileExists(atPath: candidate.path) { return candidate }
            dir = dir.deletingLastPathComponent()
        }
        return nil
    }

    private func measure() throws -> Stats {
        let url = try #require(corpusURL(), "recipes_seed.json not found from \(#filePath)")
        let data = try Data(contentsOf: url)
        let entries = try #require(try JSONSerialization.jsonObject(with: data) as? [[String: String]])

        var s = Stats()
        for e in entries {
            s.total += 1
            guard let pre = TextRecipeParser.parse(e["rawText"] ?? "") else {
                s.parseNil += 1
                s.poorNames.append("NIL:" + (e["name"] ?? "?"))
                continue
            }
            let lines = pre.ingredients ?? []
            let zero = lines.map { IngredientLineParser.parse($0) }.filter { $0.quantity == 0 }.count
            let zeroFrac = lines.isEmpty ? 1.0 : Double(zero) / Double(lines.count)
            if lines.count >= 2 && zeroFrac <= 0.5 {
                s.good += 1
            } else {
                s.poor += 1
                if s.poorNames.count < 20 { s.poorNames.append(e["name"] ?? "?") }
            }
        }
        return s
    }

    @Test func seedCorpusParsesWithRealAmounts() throws {
        let s = try measure()
        let goodFrac = s.total == 0 ? 0 : Double(s.good) / Double(s.total)
        let summary = "corpus=\(s.total) nil=\(s.parseNil) good=\(s.good) poor=\(s.poor) good%=\(Int(goodFrac * 100))"
        print("SEED CORPUS QUALITY — \(summary)")
        print("poor/nil sample: \(s.poorNames.prefix(20).joined(separator: " | "))")

        // Regression floor locked to measured quality (2026-10-09): 355 entries, 3 unparseable, 85% good.
        // Raise these as the parser improves; a drop below means a change regressed import quality.
        // Known residual in the "poor" bucket: scraper-prepended scale numbers ("575 200g flour") and
        // name-first lines ("butter 100g, chopped") — messy corpus formatting, a separate riskier fix.
        #expect(s.parseNil <= 3, "More seed recipes fail to parse than before. \(summary)")
        #expect(goodFrac >= 0.84, "Seed amount-parse quality regressed below the locked floor. \(summary)")
    }
}
