import Foundation

/// Deals `DiscoveryPool` chapters page by page, forever: no recipe repeats within a cycle; once the pool is spent a
/// new cycle starts with a fresh chapter order, layouts and recipe order (owner 2026-11-15: "we have enough recipes to
/// loop"), and never repeats a recipe from the chapter just before. Pure value type, seeded, so paging is testable.
struct DiscoveryPager {
    private(set) var pool: DiscoveryPool
    let seed: UInt64
    /// How many times the pool has been reshuffled.
    private(set) var cycle = 0
    private var seen: Set<UUID> = []
    /// The previous chapter's recipes, kept out of the next one even across a reshuffle.
    private var lastDealt: Set<UUID> = []
    /// Source indices in this cycle's chapter order.
    private var order: [Int] = []
    /// Each source's candidates in this cycle's dealing order.
    private var decks: [[RecipeModel]] = []
    /// Per deck, how many leading recipes are already seen this cycle — `seen` only grows until the decks are rebuilt,
    /// so dealing skips them instead of rescanning the whole deck for every chapter.
    private var spent: [Int] = []
    private var cursor = 0
    private var nextID = 0

    /// A chapter needs at least this many fresh recipes; fewer wait for the next cycle.
    static let minimumChapterSize = 2

    /// `alreadyShown`: recipes on screen above the feed (Recently cooked, the library preview), kept out of the first
    /// cycle so the opening chapters don't repeat them.
    init(pool: DiscoveryPool, seed: UInt64, alreadyShown: Set<UUID> = []) {
        self.pool = pool
        self.seed = seed
        seen = alreadyShown
        order = chapterOrder(cycle: 0)
        rebuildDecks()
    }

    /// The next `count` chapters (fewer only when the library is too small to fill any chapter).
    mutating func next(_ count: Int) -> [DiscoveryChapter] {
        var chapters: [DiscoveryChapter] = []
        while chapters.count < count, let chapter = nextChapter() {
            chapters.append(chapter)
        }
        return chapters
    }

    /// Swaps in a pool rebuilt after a library change, keeping what's been seen so the feed carries on, not restarts.
    /// Always swaps (no equality short-cut): `RecipeModel ==` ignores names and times, so an "equal" pool can still
    /// hold stale copies. Same seed and cycle → same deck order, so the swap is invisible otherwise.
    mutating func replacePool(_ newPool: DiscoveryPool) {
        pool = newPool
        order = chapterOrder(cycle: cycle)
        rebuildDecks()
        cursor = order.isEmpty ? 0 : cursor % order.count
    }

    private mutating func nextChapter() -> DiscoveryChapter? {
        guard !order.isEmpty else { return nil }
        for attempt in 0..<3 {
            for _ in 0..<order.count {
                let index = order[cursor]
                cursor = (cursor + 1) % order.count
                let excluded = seen, previous = lastDealt
                var start = spent[index]
                while start < decks[index].count, excluded.contains(decks[index][start].id) { start += 1 }
                spent[index] = start
                let fresh = Array(decks[index][start...].lazy
                    .filter { !excluded.contains($0.id) && !previous.contains($0.id) }
                    .prefix(DiscoveryChapter.Layout.row.size))
                guard fresh.count >= Self.minimumChapterSize else { continue }
                let layout = layout(fitting: fresh.count)
                let picks = Array(fresh.prefix(layout.size))
                let ids = Set(picks.map(\.id))
                seen.formUnion(ids)
                lastDealt = ids
                let id = nextID
                nextID += 1
                return DiscoveryChapter(id: id, kind: pool.sources[index].kind, layout: layout, recipes: picks)
            }
            // A whole pass with nothing fresh: the pool is spent, so reshuffle and go round again. If even that finds
            // nothing, one chapter holds the whole library — let it follow itself rather than end the feed.
            if attempt == 0 { startCycle() } else { lastDealt = [] }
        }
        return nil
    }

    private mutating func startCycle() {
        cycle += 1
        seen = []
        order = chapterOrder(cycle: cycle)
        rebuildDecks()
        cursor = 0
    }

    /// Layouts rotate chapter by chapter (offset each cycle); a chapter too small for its turn takes one that fits.
    private func layout(fitting count: Int) -> DiscoveryChapter.Layout {
        let all = DiscoveryChapter.Layout.allCases
        let preferred = all[(nextID + cycle) % all.count]
        if preferred.size <= count { return preferred }
        if count >= DiscoveryChapter.Layout.wall.size { return .wall }
        return count >= DiscoveryChapter.Layout.feature.size ? .feature : .row
    }

    /// The pool's own interleaved order first; a seeded shuffle for every reshuffle after.
    private func chapterOrder(cycle: Int) -> [Int] {
        let indices = Array(pool.sources.indices)
        guard cycle > 0 else { return indices }
        var generator = SeededGenerator(seed: Self.mix(seed, UInt64(cycle)))
        return indices.shuffled(using: &generator)
    }

    private mutating func rebuildDecks() {
        decks = makeDecks()
        spent = Array(repeating: 0, count: decks.count)
    }

    private func makeDecks() -> [[RecipeModel]] {
        pool.sources.map { source in
            guard !source.isRanked else { return source.candidates }
            return source.candidates
                .map { ($0, Self.rank($0.id, seed: seed, cycle: cycle)) }
                .sorted { $0.1 < $1.1 }
                .map(\.0)
        }
    }

    /// Stable across launches (FNV-1a over the id, mixed with seed and cycle) — Swift's `Hasher` is seeded per launch.
    static func rank(_ id: UUID, seed: UInt64, cycle: Int) -> UInt64 {
        var hash: UInt64 = 0xcbf29ce484222325
        for byte in id.uuidString.utf8 {
            hash ^= UInt64(byte)
            hash = hash &* 0x100000001b3
        }
        return mix(hash, mix(seed, UInt64(cycle)))
    }

    /// SplitMix64 finaliser: spreads two inputs into one well-mixed value.
    static func mix(_ a: UInt64, _ b: UInt64) -> UInt64 {
        var z = a &+ (b &* 0x9e3779b97f4a7c15) &+ 0x9e3779b97f4a7c15
        z = (z ^ (z >> 30)) &* 0xbf58476d1ce4e5b9
        z = (z ^ (z >> 27)) &* 0x94d049bb133111eb
        return z ^ (z >> 31)
    }
}

/// Deterministic generator so a reshuffle is reproducible in tests.
struct SeededGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) { state = seed }

    mutating func next() -> UInt64 {
        state &+= 0x9e3779b97f4a7c15
        return DiscoveryPager.mix(state, 0)
    }
}

extension DiscoveryChapter {
    /// This chapter with each recipe's latest copy (after an edit or favourite), deleted ones dropped; nil when emptied.
    func refreshed(with recipesByID: [UUID: RecipeModel]) -> DiscoveryChapter? {
        let current = recipes.compactMap { recipesByID[$0.id] }
        guard !current.isEmpty else { return nil }
        return DiscoveryChapter(id: id, kind: kind, layout: layout, recipes: current)
    }
}
