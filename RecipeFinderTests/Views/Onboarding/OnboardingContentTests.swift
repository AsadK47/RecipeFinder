import Testing
import SwiftUI
@testable import RecipeFinder

@Suite("OnboardingContent")
struct OnboardingContentTests {

    // MARK: - Structure

    @Test("exactly three slides")
    func slideCount() {
        #expect(OnboardingContent.slides.count == 3)
    }

    @Test("no slide has empty title, description, or icon")
    func allSlidesHaveContent() {
        for slide in OnboardingContent.slides {
            #expect(!slide.title.isEmpty,       "title is empty in '\(slide.title)'")
            #expect(!slide.description.isEmpty, "description is empty in '\(slide.title)'")
            #expect(!slide.icon.isEmpty,        "icon is empty in '\(slide.title)'")
        }
    }

    // MARK: - Actionability

    /// Each description must mention a concrete UI element or verb so new users
    /// know what to actually tap — not just feature-marketing copy.
    @Test("each description mentions a concrete UI element or action",
          arguments: 0..<OnboardingContent.slides.count)
    func descriptionIsActionable(index: Int) {
        let slide = OnboardingContent.slides[index]
        let actionTerms = ["tap", "import", "recipe", "groceries",
                           "planning", "ingredient", "link", "photo",
                           "scan", "open", "week", "calendar"]
        let lower = slide.description.lowercased()
        let isActionable = actionTerms.contains { lower.contains($0) }
        #expect(isActionable,
                "Slide \(index) '\(slide.title)': description should mention a UI element or action verb")
    }

    // MARK: - Titles are unique

    @Test("all slide titles are distinct")
    func titlesAreUnique() {
        let titles = OnboardingContent.slides.map(\.title)
        #expect(Set(titles).count == titles.count)
    }
}
