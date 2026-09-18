import Testing
@testable import RecipeFinder

@Suite("RecipeParser isInstructionLine")
struct RecipeParserTextContentTests {

    // MARK: - Length guard

    @Test("rejects lines shorter than 10 characters")
    func rejectsShortLines() {
        #expect(!RecipeParser.isInstructionLine("Mix."))
        #expect(!RecipeParser.isInstructionLine("Add eggs"))
    }

    @Test("rejects lines of 500 or more characters")
    func rejectsOverlongLines() {
        #expect(!RecipeParser.isInstructionLine(String(repeating: "a", count: 500)))
    }

    // MARK: - Header label rejection

    @Test("rejects bare section header labels", arguments: [
        "instructions", "method", "directions", "steps", "preparation",
        "instructions:", "method:", "directions:"
    ])
    func rejectsSectionHeaders(label: String) {
        #expect(!RecipeParser.isInstructionLine(label))
    }

    // MARK: - Numbered steps (always accepted)

    @Test("accepts numbered steps regardless of verb content", arguments: [
        "1. The dough is ready when smooth and elastic.",
        "2) Golden brown on top means done — remove from heat.",
        "Step 3: Ready to serve at room temperature.",
    ])
    func acceptsNumberedSteps(line: String) {
        #expect(RecipeParser.isInstructionLine(line))
    }

    // MARK: - Structural cooking phrase markers

    @Test("accepts lines containing time language")
    func acceptsTimeLanguage() {
        #expect(RecipeParser.isInstructionLine("Bake for 25 minutes until the top is golden."))
        #expect(RecipeParser.isInstructionLine("Leave to rest for two hours in a warm place."))
    }

    @Test("accepts lines containing temperature language")
    func acceptsTemperatureLanguage() {
        #expect(RecipeParser.isInstructionLine("Preheat the oven to 180 degrees before starting."))
        #expect(RecipeParser.isInstructionLine("The oil should reach 170°c before you add the fish."))
    }

    // MARK: - Default acceptance within confirmed instruction section

    // These lines have no action verb from the old whitelist and no cooking phrase,
    // but are legitimate instruction sentences. The old code returned false for all
    // of them; the new code accepts anything >= 15 chars within the section.
    @Test("accepts non-verb instruction sentences of sufficient length", arguments: [
        "Rest the dough at room temperature.",
        "The bread is ready when it sounds hollow.",
        "Test the seasoning for balance before serving.",
        "Season well before bringing to the table.",
    ])
    func acceptsNonVerbInstructions(line: String) {
        #expect(RecipeParser.isInstructionLine(line))
    }

    @Test("accepts line at exactly the minimum sentence length boundary")
    func acceptsAtMinimumBoundary() {
        let line = "Season to taste"   // exactly 15 characters
        #expect(RecipeParser.isInstructionLine(line))
    }

    @Test("rejects line just below the minimum sentence length boundary")
    func rejectsBelowMinimumBoundary() {
        #expect(!RecipeParser.isInstructionLine("Stir gently."))   // 12 chars
        #expect(!RecipeParser.isInstructionLine("Drain well."))    // 11 chars
    }
}
