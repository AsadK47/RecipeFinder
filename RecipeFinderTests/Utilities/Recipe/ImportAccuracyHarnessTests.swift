import Testing
import Foundation
@testable import RecipeFinder

/// Measurement harness (not a pass/fail gate): scores `RecipeParser` against an auto-labelled corpus
/// built by tools/import-corpus/fetch_and_label.py. Ground truth = each page's own JSON-LD Recipe.
/// It scores two paths per page: the full HTML, and a JSON-LD-stripped copy that forces our
/// microdata/WPRM/free-text fallbacks — the path that actually decides real-world reliability.
/// Skips cleanly when no corpus is present (so CI without a corpus stays green). Point `RF_CORPUS`
/// at the corpus dir; default `/private/tmp/rf_import_corpus`.
@Suite("Import accuracy harness")
struct ImportAccuracyHarnessTests {

    struct Truth: Codable {
        let name: String
        let ingredients: [String]
        let instructionCount: Int
        let hasInstructions: Bool
    }

    private func normalize(_ s: String) -> String {
        let scalars = s.lowercased().unicodeScalars.map {
            CharacterSet.alphanumerics.contains($0) ? Character($0) : " "
        }
        return String(scalars).split(separator: " ").joined(separator: " ")
    }

    private func tokens(_ s: String) -> Set<String> {
        Set(normalize(s).split(separator: " ").map(String.init).filter { $0.count >= 3 })
    }

    private func nameMatches(_ parsed: String?, _ truth: String) -> Bool {
        guard let parsed, !normalize(parsed).isEmpty else { return false }
        let p = normalize(parsed), t = normalize(truth)
        if t.isEmpty { return false }
        if p == t || p.contains(t) || t.contains(p) { return true }
        let tt = tokens(truth)
        guard !tt.isEmpty else { return false }
        return Double(tokens(parsed).intersection(tt).count) / Double(tt.count) >= 0.6
    }

    /// Fraction of truth ingredients matched by some parsed ingredient (≥60% token overlap).
    private func ingredientRecall(parsed: [String], truth: [String]) -> Double {
        guard !truth.isEmpty else { return 1 }
        let parsedTokens = parsed.map { tokens($0) }
        var matched = 0
        for ing in truth {
            let tt = tokens(ing)
            if tt.isEmpty { matched += 1; continue }
            if parsedTokens.contains(where: { Double($0.intersection(tt).count) / Double(tt.count) >= 0.6 }) {
                matched += 1
            }
        }
        return Double(matched) / Double(truth.count)
    }

    private func pad(_ s: String, _ w: Int) -> String {
        s.count >= w ? String(s.prefix(w)) : s + String(repeating: " ", count: w - s.count)
    }

    @Test("Measure parser accuracy + latency against the auto-labelled corpus")
    func measure() throws {
        let fm = FileManager.default
        let candidates = [
            ProcessInfo.processInfo.environment["RF_CORPUS"],
            "/private/tmp/rf_import_corpus",
            "/tmp/rf_import_corpus"
        ].compactMap { $0 }
        guard let dir = candidates.first(where: { fm.fileExists(atPath: $0) }),
              let all = try? fm.contentsOfDirectory(atPath: dir) else {
            print("‼️ No import corpus found (looked in \(candidates)). Run tools/import-corpus/fetch_and_label.py. Skipping.")
            return
        }
        let truthFiles = all.filter { $0.hasSuffix(".truth.json") }.sorted()
        guard !truthFiles.isEmpty else { print("‼️ Corpus \(dir) has no labels. Skipping."); return }

        var fullClean = 0, fallbackClean = 0
        var fallbackRecalls: [Double] = []
        var latenciesMs: [Double] = []

        print("\n=== Import accuracy — \(truthFiles.count) auto-labelled pages (\(dir)) ===")
        print(pad("recipe", 34) + pad("full", 6) + pad("nojsonld", 10) + pad("recall", 8) + "ms")

        for tf in truthFiles {
            let id = String(tf.dropLast(".truth.json".count))
            guard let td = fm.contents(atPath: "\(dir)/\(tf)"),
                  let truth = try? JSONDecoder().decode(Truth.self, from: td),
                  let fullHTML = try? String(contentsOfFile: "\(dir)/\(id).html", encoding: .utf8),
                  let noHTML = try? String(contentsOfFile: "\(dir)/\(id).nojsonld.html", encoding: .utf8)
            else { continue }

            let start = Date()
            let full = RecipeParser.parse(html: fullHTML)
            latenciesMs.append(Date().timeIntervalSince(start) * 1000)
            let fb = RecipeParser.parse(html: noHTML)

            let fullOK = nameMatches(full.name, truth.name)
                && ingredientRecall(parsed: full.ingredients, truth: truth.ingredients) >= 0.8
                && (!truth.hasInstructions || !full.instructions.isEmpty)
            let fbRecall = ingredientRecall(parsed: fb.ingredients, truth: truth.ingredients)
            let fbOK = nameMatches(fb.name, truth.name)
                && fbRecall >= 0.8
                && (!truth.hasInstructions || !fb.instructions.isEmpty)

            fallbackRecalls.append(fbRecall)
            if fullOK { fullClean += 1 }
            if fbOK { fallbackClean += 1 }

            print(pad(truth.name, 34) + pad(fullOK ? "OK" : "MISS", 6)
                  + pad(fbOK ? "OK" : "MISS", 10)
                  + pad(String(format: "%.0f%%", fbRecall * 100), 8)
                  + String(format: "%.0f", latenciesMs.last ?? 0))
        }

        let n = truthFiles.count
        func pct(_ x: Int) -> String { String(format: "%.0f%%", Double(x) / Double(n) * 100) }
        let sortedLat = latenciesMs.sorted()
        func p(_ q: Double) -> Double { sortedLat.isEmpty ? 0 : sortedLat[min(sortedLat.count - 1, Int(q * Double(sortedLat.count)))] }
        let avgFb = fallbackRecalls.isEmpty ? 0 : fallbackRecalls.reduce(0, +) / Double(fallbackRecalls.count)

        print("\n--- Summary ---")
        print("pages:                     \(n)")
        print("full-HTML clean import:    \(fullClean)/\(n)  (\(pct(fullClean)))")
        print("fallback (JSON-LD removed): \(fallbackClean)/\(n)  (\(pct(fallbackClean)))")
        print(String(format: "fallback ingredient recall: %.0f%% avg", avgFb * 100))
        print(String(format: "parse latency:             p50 %.1f ms   p95 %.1f ms", p(0.5), p(0.95)))
        print("================================================\n")
    }
}
