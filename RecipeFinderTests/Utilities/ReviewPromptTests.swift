import Testing
@testable import RecipeFinder

@Suite("ReviewPrompt")
struct ReviewPromptTests {

    @Test("Prompts only on the exact threshold cook, so it fires once — not before, not again after",
          arguments: [
            (1, false),
            (2, false),
            (3, true),
            (4, false),
            (10, false),
            (0, false),
          ])
    func shouldRequestReview(cookCount: Int, expected: Bool) {
        #expect(ReviewPrompt.shouldRequestReview(afterCookCount: cookCount) == expected)
    }
}
