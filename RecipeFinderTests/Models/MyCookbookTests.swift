import Foundation
import Testing
import UIKit
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
        let pages = MyCookbook.pages(
            from: [recipe("Chicken Curry", cookCount: 3, lastCookedAt: Self.date(2026, 11, 2))],
            now: now, calendar: Self.calendar, locale: Self.locale
        )
        #expect(pages.count == 1)
        #expect(pages.first.map { MyCookbook.shareCaption(for: $0, now: now, calendar: Self.calendar, locale: Self.locale) }
                == "Chicken Curry · Made 3 times · 2 Nov — from my cookbook in RecipeFinder")
    }

    @Test("a shared page gives the date, never today or yesterday, since the picture is seen later", arguments: [
        (16, "Made once · 16 Nov"), (15, "Made once · 15 Nov")
    ])
    func shareLineIsAbsolute(day: Int, expected: String) {
        let now = Self.date(2026, 11, 16, hour: 21)
        let pages = MyCookbook.pages(from: [recipe("Dal", cookCount: 1, lastCookedAt: Self.date(2026, 11, day))],
                                     now: now, calendar: Self.calendar, locale: Self.locale)
        #expect(pages.first?.line != expected)   // the page itself still says today / yesterday
        #expect(pages.first.map { MyCookbook.shareLine(for: $0, now: now, calendar: Self.calendar, locale: Self.locale) }
                == expected)
    }

    @Test("a shared page from an earlier year keeps its year")
    func shareLineOtherYear() {
        let now = Self.date(2026, 11, 16)
        let pages = MyCookbook.pages(from: [recipe("Dal", cookCount: 2, lastCookedAt: Self.date(2025, 12, 30))],
                                     now: now, calendar: Self.calendar, locale: Self.locale)
        #expect(pages.first.map { MyCookbook.shareLine(for: $0, now: now, calendar: Self.calendar, locale: Self.locale) }
                == "Made 2 times · 30 Dec 2025")
    }
}

/// The shared picture itself: drawn at full size, opaque, with the dish photo when there is one.
@Suite("Cookbook share card")
@MainActor
struct CookbookShareCardTests {

    private let page = CookbookPage(
        id: UUID(), name: "Chicken Curry", imageName: nil, category: "Main", cuisine: "Indian",
        lastCookedAt: Date(timeIntervalSince1970: 1_700_000_000), timesCooked: 3, rating: 4, line: "Made 3 times · today"
    )

    private static func solid(_ color: UIColor, size: CGSize) -> UIImage {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        return UIGraphicsImageRenderer(size: size, format: format).image { context in
            color.setFill()
            context.fill(CGRect(origin: .zero, size: size))
        }
    }

    /// Alpha and red of one pixel (x, y from the top-left) of the rendered card, read back through a bitmap context.
    private static func pixel(_ image: UIImage, x: Int, y: Int) -> (alpha: UInt8, red: UInt8)? {
        guard let cgImage = image.cgImage else { return nil }
        var bytes = [UInt8](repeating: 0, count: 4)
        let drawn: Bool = bytes.withUnsafeMutableBytes { buffer in
            guard let context = CGContext(data: buffer.baseAddress, width: 1, height: 1, bitsPerComponent: 8,
                                          bytesPerRow: 4, space: CGColorSpaceCreateDeviceRGB(),
                                          bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return false }
            context.draw(cgImage, in: CGRect(x: -x, y: -(cgImage.height - 1 - y), width: cgImage.width,
                                              height: cgImage.height))
            return true
        }
        return drawn ? (bytes[3], bytes[0]) : nil
    }

    @Test("the card renders 1080 × 1350 pixels, a 4:5 portrait that fits feeds and messages")
    func cardPixelSize() throws {
        let card = try #require(CookbookShareCard.render(page: page, picture: nil))
        let cgImage = try #require(card.cgImage)
        #expect(cgImage.width == 1080)
        #expect(cgImage.height == 1350)
    }

    @Test("a card without a photo is still fully opaque, not see-through placeholder tints")
    func placeholderCardIsOpaque() throws {
        let card = try #require(CookbookShareCard.render(page: page, picture: nil))
        let corner = try #require(Self.pixel(card, x: 2, y: 2))
        #expect(corner.alpha == 255)
    }

    @Test("the card shows the dish photo, filling the top of the card")
    func cardShowsPhoto() throws {
        let photo = Self.solid(.red, size: CGSize(width: 400, height: 300))
        let card = try #require(CookbookShareCard.render(page: page, picture: photo))
        let top = try #require(Self.pixel(card, x: 540, y: 20))
        #expect(top.red > 200)
        #expect(top.alpha == 255)
    }

    @Test("the card is drawn the right way up: photo bright at the top, darkened behind the name at the foot")
    func cardIsUpright() throws {
        let photo = Self.solid(.red, size: CGSize(width: 400, height: 300))
        let card = try #require(CookbookShareCard.render(page: page, picture: photo))
        let top = try #require(Self.pixel(card, x: 540, y: 20))
        let foot = try #require(Self.pixel(card, x: 1070, y: 1340))
        #expect(top.red > 200)
        #expect(foot.red < 120)
        #expect(foot.alpha == 255)
    }

    @Test("the card's photo is loaded from a file on the phone")
    func pictureLoadsFromFile() async throws {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: folder) }
        let file = folder.appendingPathComponent("dish.jpg")
        let jpeg = try #require(Self.solid(.green, size: CGSize(width: 64, height: 48))
            .jpegData(compressionQuality: 0.9))
        try jpeg.write(to: file)
        let picture = await CookbookShareCard.picture(for: file.path)
        #expect(picture != nil)
    }

    @Test("no picture name means the placeholder art")
    func noPictureName() async {
        #expect(await CookbookShareCard.picture(for: nil) == nil)
        #expect(await CookbookShareCard.picture(for: "") == nil)
    }
}

