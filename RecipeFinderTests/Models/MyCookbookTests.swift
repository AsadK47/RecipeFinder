import Foundation
import Testing
@testable import RecipeFinder

/// My Cookbook builds itself from cook history: which dishes get a page, in what order, with which picture and line.
@Suite("MyCookbook")
struct MyCookbookTests {

    private static let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/London") ?? .gmt
        return calendar
    }()
    private static let locale = Locale(identifier: "en_GB")

    private static func date(_ year: Int, _ month: Int, _ day: Int, hour: Int = 19) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour)) ?? .distantPast
    }

    private func recipe(
        _ name: String,
        cookCount: Int = 0,
        lastCookedAt: Date? = nil,
        rating: Int = 0,
        imageName: String? = nil,
        photoNames: [String] = []
    ) -> RecipeModel {
        RecipeModel(
            name: name, category: "Main", difficulty: "Easy", prepTime: "10 min", cookingTime: "20 min",
            baseServings: 2, ingredients: [], prePrepInstructions: [], instructions: ["Cook"], notes: "",
            imageName: imageName, cookCount: cookCount, lastCookedAt: lastCookedAt, rating: rating,
            photoNames: photoNames
        )
    }

    // MARK: - Pages

    @Test("a library with nothing cooked has no pages")
    func nothingCookedNoPages() {
        let pages = MyCookbook.pages(from: [recipe("Dal"), recipe("Soup")])
        #expect(pages.isEmpty)
    }

    @Test("only cooked dishes get a page")
    func onlyCookedDishes() {
        let pages = MyCookbook.pages(from: [
            recipe("Dal", cookCount: 2, lastCookedAt: Self.date(2026, 11, 10)),
            recipe("Soup"),
        ])
        #expect(pages.map(\.name) == ["Dal"])
    }

    @Test("a dish with a cook date but no count still gets a page (older data)")
    func cookDateWithoutCount() {
        let pages = MyCookbook.pages(from: [recipe("Dal", lastCookedAt: Self.date(2026, 11, 10))])
        #expect(pages.map(\.name) == ["Dal"])
        #expect(pages.first?.timesCooked == 1)
    }

    @Test("the most recently cooked dish is the first page")
    func newestFirst() {
        let pages = MyCookbook.pages(from: [
            recipe("Old", cookCount: 1, lastCookedAt: Self.date(2026, 10, 1)),
            recipe("New", cookCount: 1, lastCookedAt: Self.date(2026, 11, 14)),
            recipe("Middle", cookCount: 3, lastCookedAt: Self.date(2026, 11, 2)),
        ])
        #expect(pages.map(\.name) == ["New", "Middle", "Old"])
    }

    @Test("dishes without a cook date come after dated ones, A to Z")
    func undatedLast() {
        let pages = MyCookbook.pages(from: [
            recipe("Zest", cookCount: 1),
            recipe("Apple", cookCount: 2),
            recipe("Dated", cookCount: 1, lastCookedAt: Self.date(2026, 1, 1)),
        ])
        #expect(pages.map(\.name) == ["Dated", "Apple", "Zest"])
    }

    @Test("dishes cooked at the same moment are in A to Z order")
    func sameDateByName() {
        let when = Self.date(2026, 11, 10)
        let pages = MyCookbook.pages(from: [
            recipe("Soup", cookCount: 1, lastCookedAt: when),
            recipe("Bread", cookCount: 1, lastCookedAt: when),
        ])
        #expect(pages.map(\.name) == ["Bread", "Soup"])
    }

    @Test("a page keeps the dish's rating and cook count and points at the recipe")
    func pageCarriesDish() throws {
        let dal = recipe("Dal", cookCount: 4, lastCookedAt: Self.date(2026, 11, 10), rating: 5)
        let page = try #require(MyCookbook.pages(from: [dal]).first)
        #expect(page.id == dal.id)
        #expect(page.timesCooked == 4)
        #expect(page.rating == 5)
    }

    // MARK: - Picture: the cook's own photo first

    @Test("the cook's latest photo is the page picture, even when the recipe has a web picture")
    func ownPhotoWins() throws {
        let dal = recipe("Dal", cookCount: 1, lastCookedAt: Self.date(2026, 11, 10),
                         imageName: "https://example.com/dal.jpg", photoNames: ["first.jpg", "latest.jpg"])
        #expect(try #require(MyCookbook.pages(from: [dal]).first).imageName == "latest.jpg")
    }

    @Test("without a photo of their own the page shows the recipe picture")
    func recipePictureOtherwise() throws {
        let dal = recipe("Dal", cookCount: 1, lastCookedAt: Self.date(2026, 11, 10),
                         imageName: "https://example.com/dal.jpg")
        #expect(try #require(MyCookbook.pages(from: [dal]).first).imageName == "https://example.com/dal.jpg")
    }

    // MARK: - Lines

    @Test("the headline counts dishes and cooks", arguments: [
        ([1], "1 dish · cooked once"),
        ([3], "1 dish · cooked 3 times"),
        ([1, 1], "2 dishes · cooked 2 times"),
        ([2, 3, 1], "3 dishes · cooked 6 times"),
    ])
    func headline(counts: [Int], expected: String) {
        let recipes = counts.enumerated().map { index, count in
            recipe("Dish \(index)", cookCount: count, lastCookedAt: Self.date(2026, 11, 10))
        }
        #expect(MyCookbook.headline(for: MyCookbook.pages(from: recipes)) == expected)
    }

    @Test("an empty cookbook has no headline")
    func noHeadline() {
        #expect(MyCookbook.headline(for: []) == nil)
    }

    @Test("a page line says how often and when", arguments: [
        (1, MyCookbookTests.date(2026, 11, 15, hour: 8), "Made once · today"),
        (2, MyCookbookTests.date(2026, 11, 14), "Made 2 times · yesterday"),
        (3, MyCookbookTests.date(2026, 11, 2), "Made 3 times · 2 Nov"),
        (1, MyCookbookTests.date(2025, 12, 25), "Made once · 25 Dec 2025"),
    ])
    func pageLine(times: Int, cooked: Date, expected: String) throws {
        let page = try #require(MyCookbook.pages(
            from: [recipe("Dal", cookCount: times, lastCookedAt: cooked)],
            now: Self.date(2026, 11, 15, hour: 20), calendar: Self.calendar, locale: Self.locale
        ).first)
        #expect(page.line == expected)
    }

    @Test("a page with no cook date says only how often")
    func pageLineWithoutDate() throws {
        let page = try #require(MyCookbook.pages(from: [recipe("Dal", cookCount: 2)], now: Self.date(2026, 11, 15),
                                                 calendar: Self.calendar, locale: Self.locale).first)
        #expect(page.line == "Made 2 times")
    }

    @Test("Me's one line: chef type and cooks this year", arguments: [
        (0, "Home Cook"),
        (1, "Home Cook · 1 cook this year"),
        (34, "Home Cook · 34 cooks this year"),
    ])
    func meLine(cooks: Int, expected: String) {
        #expect(MyCookbook.meLine(chefType: .homeCook, cooksThisYear: cooks) == expected)
    }

    // MARK: - Share a page

    @Test("a shared page's stars read as filled and empty stars", arguments: [
        (1, "★☆☆☆☆"), (4, "★★★★☆"), (5, "★★★★★"), (9, "★★★★★")
    ])
    func shareStars(rating: Int, expected: String) {
        #expect(MyCookbook.starText(rating: rating) == expected)
    }

    @Test("an unrated page shares without stars", arguments: [0, -1])
    func shareNoStars(rating: Int) {
        #expect(MyCookbook.starText(rating: rating) == nil)
    }

    @Test("the share caption names the dish and when it was made")
    func shareCaption() {
        let now = Self.date(2026, 11, 16)
        let page = MyCookbook.pages(
            from: [recipe("Chicken Curry", cookCount: 3, lastCookedAt: Self.date(2026, 11, 2))],
            now: now, calendar: Self.calendar, locale: Self.locale
        )
        #expect(page.count == 1)
        #expect(page.first.map(MyCookbook.shareCaption(for:))
                == "Chicken Curry · Made 3 times · 2 Nov — from my cookbook in RecipeFinder")
    }

    @Test("the share card renders 1080 × 1350 pixels, a 4:5 portrait that fits feeds and messages")
    func shareCardPixels() {
        let size = MyCookbook.shareCardSize
        #expect(size.width * MyCookbook.shareCardScale == 1080)
        #expect(size.height * MyCookbook.shareCardScale == 1350)
    }
}
