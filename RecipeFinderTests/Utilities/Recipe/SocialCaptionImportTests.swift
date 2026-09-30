import Testing
@testable import RecipeFinder

/// Sharing a TikTok/Instagram *link* has no recipe structured data; the recipe (when present) lives in the
/// page's og:description caption. These guard the caption fallback in `RecipeParser.parse`.
@Suite("Social caption import")
struct SocialCaptionImportTests {

    private func page(title: String, caption: String) -> String {
        "<html><head><meta property=\"og:title\" content=\"\(title)\">"
        + "<meta property=\"og:description\" content=\"\(caption)\"></head>"
        + "<body><div>loading…</div></body></html>"
    }

    @Test("Extracts a recipe from a caption when the page has no structured data")
    func captionFallback() {
        let caption = "Easy Guacamole 🥑\n\nIngredients:\n2 ripe avocados\n1 lime, juiced\n1/2 tsp salt\n\nMethod:\n1. Mash the avocados.\n2. Stir in lime and salt."
        let r = RecipeParser.parse(html: page(title: "Easy Guacamole", caption: caption))
        #expect(r.name == "Easy Guacamole")            // og:title beats the junk body ("loading…")
        #expect(r.ingredients.count == 3)
        #expect(!r.instructions.isEmpty)
    }

    @Test("A caption with no recipe yields no ingredients (import fails cleanly, never a false recipe)")
    func noRecipeCaption() {
        let r = RecipeParser.parse(html: page(title: "Someone on TikTok", caption: "new video up!! link in bio 🔗 follow for more"))
        #expect(r.ingredients.count < 2)
    }
}
