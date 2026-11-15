import Foundation
import Observation

/// The discovery chapters dealt so far below the library, paged as the cook scrolls. Owned by the Recipes list; the
/// ranking and paging rules live in the pure `DiscoveryPool` / `DiscoveryPager`.
@MainActor @Observable
final class DiscoveryFeedModel {
    private(set) var chapters: [DiscoveryChapter] = []
    @ObservationIgnored private var pager: DiscoveryPager?
    @ObservationIgnored private let seed: UInt64
    @ObservationIgnored private let now: () -> Date

    static let firstPage = 4
    static let pageSize = 3

    /// A fresh seed per feed, so each visit to Recipes deals something new.
    init(seed: UInt64 = UInt64.random(in: .min ... .max), now: @escaping () -> Date = Date.init) {
        self.seed = seed
        self.now = now
    }

    /// Rebuilds the pool after a library or kitchen change. The first call deals the first page; later ones keep the
    /// chapters already on screen (with fresh recipe copies, deleted ones gone) and carry on without repeats.
    func update(recipes: [RecipeModel], kitchenItemNames: [String]) {
        let pool = DiscoveryPool.make(recipes: recipes, kitchenItemNames: kitchenItemNames, now: now())
        guard var pager else {
            var fresh = DiscoveryPager(pool: pool, seed: seed)
            chapters = fresh.next(Self.firstPage)
            self.pager = fresh
            return
        }
        pager.replacePool(pool)
        self.pager = pager
        let byID = Dictionary(recipes.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        chapters = chapters.compactMap { $0.refreshed(with: byID) }
        if chapters.isEmpty { loadMore() }
    }

    /// Deals the next page once `chapter` is one of the last two on screen — the scroll is nearing the end.
    func chapterAppeared(_ chapter: DiscoveryChapter) {
        guard let index = chapters.firstIndex(where: { $0.id == chapter.id }), index >= chapters.count - 2 else { return }
        loadMore()
    }

    private func loadMore() {
        guard var pager else { return }
        let more = pager.next(Self.pageSize)
        self.pager = pager
        chapters.append(contentsOf: more)
    }
}
