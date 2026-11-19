import Foundation
import Testing
@testable import RecipeFinder

@Suite("CookingResumeMemory")
@MainActor
struct CookingResumeMemoryTests {

    private final class Clock {
        var date = Date(timeIntervalSince1970: 1_800_000_000)
    }

    private let recipe = UUID()
    private let content = ["First, gather your ingredients.", "Boil", "Simmer", "onion", "rice"]

    private func memory(_ clock: Clock) -> CookingResumeMemory {
        CookingResumeMemory(now: { clock.date })
    }

    @Test("Reopening a recipe returns the step and ticks it was left on")
    func resumesSamePlace() {
        let m = memory(Clock())
        let place = CookingResumeMemory.Place(index: 2, checkedIngredients: [0, 1])
        m.remember(place, for: recipe, content: content)
        #expect(m.place(for: recipe, content: content, itemCount: 3) == place)
    }

    @Test("Nothing saved means starting from the top")
    func nothingSaved() {
        #expect(memory(Clock()).place(for: recipe, content: content, itemCount: 3) == nil)
    }

    @Test("Each recipe keeps its own place")
    func perRecipe() {
        let m = memory(Clock())
        let other = UUID()
        m.remember(.init(index: 1, checkedIngredients: []), for: recipe, content: content)
        m.remember(.init(index: 2, checkedIngredients: []), for: other, content: content)
        #expect(m.place(for: recipe, content: content, itemCount: 3)?.index == 1)
        #expect(m.place(for: other, content: content, itemCount: 3)?.index == 2)
    }

    @Test("Leaving on the ingredient list with ticks still resumes the ticks")
    func ticksOnFirstItem() {
        let m = memory(Clock())
        m.remember(.init(index: 0, checkedIngredients: [3]), for: recipe, content: content)
        #expect(m.place(for: recipe, content: content, itemCount: 3)?.checkedIngredients == [3])
    }

    @Test("Leaving at the very start clears an older place")
    func startClears() {
        let m = memory(Clock())
        m.remember(.init(index: 2, checkedIngredients: []), for: recipe, content: content)
        m.remember(.init(index: 0, checkedIngredients: []), for: recipe, content: content)
        #expect(m.place(for: recipe, content: content, itemCount: 3) == nil)
    }

    @Test("A recipe edited since leaving starts from the top")
    func editedRecipe() {
        let m = memory(Clock())
        m.remember(.init(index: 2, checkedIngredients: [1]), for: recipe, content: content)
        var edited = content
        edited[1] = "Boil for 10 minutes"
        #expect(m.place(for: recipe, content: edited, itemCount: 3) == nil)
        #expect(m.place(for: recipe, content: content, itemCount: 3) == nil, "a stale place is dropped, not kept")
    }

    @Test("An index past the end is never returned", arguments: [3, 7])
    func outOfRange(index: Int) {
        let m = memory(Clock())
        m.remember(.init(index: index, checkedIngredients: []), for: recipe, content: content)
        #expect(m.place(for: recipe, content: content, itemCount: 3) == nil)
    }

    @Test("A place up to 12 hours old resumes; older starts from the top")
    func expiry() {
        let clock = Clock()
        let m = memory(clock)
        m.remember(.init(index: 1, checkedIngredients: []), for: recipe, content: content)
        clock.date.addTimeInterval(CookingResumeMemory.maxAge)
        #expect(m.place(for: recipe, content: content, itemCount: 3)?.index == 1)
        clock.date.addTimeInterval(1)
        #expect(m.place(for: recipe, content: content, itemCount: 3) == nil)
    }

    @Test("Finishing forgets the place")
    func forget() {
        let m = memory(Clock())
        m.remember(.init(index: 2, checkedIngredients: []), for: recipe, content: content)
        m.forget(recipe)
        #expect(m.place(for: recipe, content: content, itemCount: 3) == nil)
    }

    @Test("The resume fingerprint changes when an ingredient or step changes")
    func fingerprint() {
        func make(_ ingredient: String, steps: [String]) -> RecipeModel {
            RecipeModel(name: "Rice", category: "Main", difficulty: "Basic", prepTime: "5", cookingTime: "10",
                        baseServings: 2, ingredients: [Ingredient(baseQuantity: 1, unit: "cup", name: ingredient)],
                        prePrepInstructions: [], instructions: steps, notes: "")
        }
        let a = make("rice", steps: ["Boil"])
        let b = make("basmati rice", steps: ["Boil"])
        let c = make("rice", steps: ["Boil", "Rest"])
        #expect(CookingModeView.resumeContent(for: a) == CookingModeView.resumeContent(for: a))
        #expect(CookingModeView.resumeContent(for: a) != CookingModeView.resumeContent(for: b))
        #expect(CookingModeView.resumeContent(for: a) != CookingModeView.resumeContent(for: c))
    }
}
