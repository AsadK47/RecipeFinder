import Testing
import Foundation
@testable import RecipeFinder

/// Guards the fix for the "old photo reappears after delete + replace" bug.
/// Recipe photos are written to a STABLE path (`RecipeImages/<id>.jpg`), so a
/// replaced photo reuses the same file URL. Kingfisher keys its cache by that
/// URL, so without a versioned key it would keep serving the stale image. The
/// key must therefore change whenever the file's contents change.
@MainActor
@Suite("RecipeImageView.imageCacheKey")
struct RecipeImageViewTests {

    private let base = "file:///Documents/RecipeImages/abc-123.jpg"

    @Test("Identical file metadata yields the same cache key (normal reads stay cached)")
    func stableForSameFile() {
        let date = Date(timeIntervalSince1970: 1_000)
        let a = RecipeImageView.imageCacheKey(base: base, modificationDate: date, size: 42)
        let b = RecipeImageView.imageCacheKey(base: base, modificationDate: date, size: 42)
        #expect(a == b)
    }

    @Test("A newer modification date changes the key (replace at same path busts the cache)")
    func changesWhenModificationDateChanges() {
        let old = RecipeImageView.imageCacheKey(base: base, modificationDate: Date(timeIntervalSince1970: 1_000), size: 42)
        let new = RecipeImageView.imageCacheKey(base: base, modificationDate: Date(timeIntervalSince1970: 2_000), size: 42)
        #expect(old != new)
    }

    @Test("A different byte size changes the key even if the timestamp is unchanged")
    func changesWhenSizeChanges() {
        let date = Date(timeIntervalSince1970: 1_000)
        let small = RecipeImageView.imageCacheKey(base: base, modificationDate: date, size: 42)
        let large = RecipeImageView.imageCacheKey(base: base, modificationDate: date, size: 99)
        #expect(small != large)
    }

    @Test("Sub-second edits are distinguished (millisecond precision)")
    func distinguishesSubSecondEdits() {
        let first = RecipeImageView.imageCacheKey(base: base, modificationDate: Date(timeIntervalSince1970: 1_000.000), size: 42)
        let second = RecipeImageView.imageCacheKey(base: base, modificationDate: Date(timeIntervalSince1970: 1_000.250), size: 42)
        #expect(first != second)
    }

    @Test("Missing metadata is tolerated and still keyed off the base URL")
    func toleratesMissingMetadata() {
        let key = RecipeImageView.imageCacheKey(base: base, modificationDate: nil, size: nil)
        #expect(key.hasPrefix(base))
    }

    @Test("Different files never collide on the same version suffix")
    func differentFilesDoNotCollide() {
        let date = Date(timeIntervalSince1970: 1_000)
        let one = RecipeImageView.imageCacheKey(base: base, modificationDate: date, size: 42)
        let two = RecipeImageView.imageCacheKey(base: "file:///Documents/RecipeImages/def-456.jpg", modificationDate: date, size: 42)
        #expect(one != two)
    }
}
