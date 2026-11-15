import Foundation

/// Snapshot of a just-logged cook for the "Made it" sheet. Identifiable so it drives `.sheet(item:)`.
struct MadeItSummary: Identifiable, Equatable {
    let id = UUID()
    /// Total cooks across the library, including this one.
    let cookNumber: Int
    let streakWeeks: Int
    let cooksThisWeek: Int
    let rating: Int
    let milestone: CookingMilestoneProgress?
    let recipeName: String
    /// This recipe's cooks, including this one.
    let timesCooked: Int
    /// The recipe already has a photo the cook took — the sheet then offers another quietly instead of asking.
    let hasCookPhoto: Bool
    /// The dish picture shown at the top (the cook's photo, the web picture or the built-in art).
    let imageName: String?
    let category: String
    let cuisine: String?

    /// Built from the recipe *after* the cook was recorded, so `cookCount` already includes it.
    init(recipe: RecipeModel, cookNumber: Int, streakWeeks: Int, cooksThisWeek: Int,
         milestone: CookingMilestoneProgress?) {
        self.cookNumber = cookNumber
        self.streakWeeks = streakWeeks
        self.cooksThisWeek = cooksThisWeek
        self.rating = recipe.rating
        self.milestone = milestone
        self.recipeName = recipe.name
        self.timesCooked = recipe.cookCount
        self.hasCookPhoto = !recipe.photoNames.isEmpty
        self.imageName = recipe.heroImageName
        self.category = recipe.category
        self.cuisine = recipe.cuisine
    }
}

/// What the Made it moment says and how it moves (`docs/PLAY.md` §7, Spoons and levels left out). Pure so tests pin it.
enum MadeItMoment {
    /// "First time making Dal!" or "Dal · made 4 times" — the dish, not just a count.
    static func subtitle(recipeName: String, timesCooked: Int) -> String {
        let name = recipeName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return "Nice cooking!" }
        return timesCooked <= 1 ? "First time making \(name)!" : "\(name) · made \(timesCooked) times"
    }

    /// Cooks this week — the number the north star counts, shown back to the cook.
    static func weekLine(cooksThisWeek: Int) -> String? {
        switch cooksThisWeek {
        case ...0: nil
        case 1: "Your first cook this week"
        default: "\(cooksThisWeek) cooks this week"
        }
    }

    static func streakLine(weeks: Int) -> String? {
        weeks > 0 ? "\(weeks)-week cooking streak" : nil
    }

    enum PhotoNudge: Equatable {
        /// No photo of this dish yet: say why one is worth taking.
        case firstPhoto
        /// Already has one: the buttons stay, without a prompt.
        case another

        var prompt: String? {
            switch self {
            case .firstPhoto: "Add a photo to remember this one"
            case .another: nil
            }
        }
    }

    static func photoNudge(hasCookPhoto: Bool) -> PhotoNudge {
        hasCookPhoto ? .another : .firstPhoto
    }

    /// Reduce Motion keeps the moment (words, haptic) and drops the confetti and the picture's pop.
    struct Motion: Equatable {
        let firesConfetti: Bool
        let popsIn: Bool
    }

    static func motion(reduceMotion: Bool) -> Motion {
        Motion(firesConfetti: !reduceMotion, popsIn: !reduceMotion)
    }

    /// One sentence per reward, so VoiceOver hears everything the screen celebrates.
    static func announcement(cookNumber: Int, recipeName: String, timesCooked: Int, streakWeeks: Int,
                             cooksThisWeek: Int) -> String {
        let parts = [
            "Made it!",
            "Cook number \(cookNumber).",
            subtitle(recipeName: recipeName, timesCooked: timesCooked),
            streakLine(weeks: streakWeeks).map { "\($0)." },
            weekLine(cooksThisWeek: cooksThisWeek).map { "\($0)." },
        ]
        return parts.compactMap { $0 }.joined(separator: " ")
    }
}
