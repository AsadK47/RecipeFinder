import Foundation

/// One dish in My Cookbook: the cook's own picture of it, how often and when it was made, and its stars.
struct CookbookPage: Identifiable, Equatable {
    /// The recipe's id, so tapping the page opens it to cook again.
    let id: UUID
    let name: String
    let imageName: String?
    let category: String
    let cuisine: String?
    let lastCookedAt: Date?
    let timesCooked: Int
    let rating: Int
    /// "Made 3 times · 2 Nov", worked out when the pages are built rather than on every render.
    let line: String
}

/// My Cookbook builds itself from cook history — no entry. Pure so the page rules are pinned by tests.
enum MyCookbook {
    /// Every cooked dish, most recently cooked first; dishes with a count but no date (older data) follow A–Z.
    static func pages(from recipes: [RecipeModel], now: Date = Date(), calendar: Calendar = .current,
                      locale: Locale = .current) -> [CookbookPage] {
        recipes
            .filter { $0.cookCount > 0 || $0.lastCookedAt != nil }
            .map { recipe in
                let timesCooked = max(recipe.cookCount, 1)
                return CookbookPage(
                    id: recipe.id,
                    name: recipe.name,
                    // The cook's last-added photo is the memory; the web picture or built-in art stands in until then.
                    imageName: recipe.photoNames.last ?? recipe.heroImageName,
                    category: recipe.category,
                    cuisine: recipe.cuisine,
                    lastCookedAt: recipe.lastCookedAt,
                    timesCooked: timesCooked,
                    rating: recipe.rating,
                    line: pageLine(timesCooked: timesCooked, lastCookedAt: recipe.lastCookedAt, now: now,
                                   calendar: calendar, locale: locale)
                )
            }
            .sorted(by: isBefore)
    }

    /// "3 dishes · cooked 6 times" under the cookbook's title; nil while it's empty.
    static func headline(for pages: [CookbookPage]) -> String? {
        guard !pages.isEmpty else { return nil }
        let dishes = pages.count == 1 ? "1 dish" : "\(pages.count) dishes"
        return "\(dishes) · cooked \(timesText(pages.reduce(0) { $0 + $1.timesCooked }))"
    }

    /// Me's one line under the cookbook: "Home Cook · 34 cooks this year"; the chef type alone before a cook this year.
    static func meLine(chefType: ChefType, cooksThisYear: Int) -> String {
        guard cooksThisYear > 0 else { return chefType.rawValue }
        let cooks = cooksThisYear == 1 ? "1 cook" : "\(cooksThisYear) cooks"
        return "\(chefType.rawValue) · \(cooks) this year"
    }

    /// "Made 3 times · 2 Nov" on a page.
    static func pageLine(timesCooked: Int, lastCookedAt: Date?, now: Date, calendar: Calendar,
                         locale: Locale) -> String {
        let made = "Made \(timesText(timesCooked))"
        guard let cooked = lastCookedAt else { return made }
        return "\(made) · \(dayText(cooked, now: now, calendar: calendar, locale: locale))"
    }

    // MARK: - Share a page

    /// "★★★★☆" on the shared card; nil when unrated so the card leaves the line out.
    static func starText(rating: Int) -> String? {
        guard rating > 0 else { return nil }
        let filled = min(rating, 5)
        return String(repeating: "★", count: filled) + String(repeating: "☆", count: 5 - filled)
    }

    /// "Made 3 times · 16 Nov" on the shared card: always a date, never "today", because the picture is kept and
    /// seen days later.
    static func shareLine(for page: CookbookPage, now: Date = Date(), calendar: Calendar = .current,
                          locale: Locale = .current) -> String {
        let made = "Made \(timesText(page.timesCooked))"
        guard let cooked = page.lastCookedAt else { return made }
        return "\(made) · \(dayText(cooked, now: now, calendar: calendar, locale: locale, relative: false))"
    }

    /// Text that travels with the shared picture (message body, post caption).
    static func shareCaption(for page: CookbookPage, now: Date = Date(), calendar: Calendar = .current,
                             locale: Locale = .current) -> String {
        "\(page.name) · \(shareLine(for: page, now: now, calendar: calendar, locale: locale))"
            + " — from my cookbook in RecipeFinder"
    }

    private static func timesText(_ count: Int) -> String {
        count == 1 ? "once" : "\(count) times"
    }

    private static func dayText(_ date: Date, now: Date, calendar: Calendar, locale: Locale,
                                relative: Bool = true) -> String {
        if relative, calendar.isDate(date, inSameDayAs: now) { return "today" }
        if relative, let yesterday = calendar.date(byAdding: .day, value: -1, to: now),
           calendar.isDate(date, inSameDayAs: yesterday) { return "yesterday" }
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.timeZone = calendar.timeZone
        formatter.locale = locale
        let sameYear = calendar.component(.year, from: date) == calendar.component(.year, from: now)
        formatter.setLocalizedDateFormatFromTemplate(sameYear ? "dMMM" : "dMMMyyyy")
        return formatter.string(from: date)
    }

    private static func isBefore(_ lhs: CookbookPage, _ rhs: CookbookPage) -> Bool {
        switch (lhs.lastCookedAt, rhs.lastCookedAt) {
        case let (left?, right?) where left != right: left > right
        case (.some, nil): true
        case (nil, .some): false
        default: lhs.name.localizedStandardCompare(rhs.name) == .orderedAscending
        }
    }
}
