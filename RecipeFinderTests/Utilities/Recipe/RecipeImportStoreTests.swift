import Testing
@testable import RecipeFinder

@Suite("RecipeImportStore outcome")
struct RecipeImportStoreTests {

    // MARK: - Failed persist (the gap: a failing save surfaces an error, awards no badge, adds nothing)

    @Test("A failed persist reports the recipe name and awards no badge", arguments: [
        ImportSource.link, .photo, .paste, .wizard,
    ])
    func failedPersist_surfacesErrorForEverySource(source: ImportSource) {
        let outcome = RecipeImportStore.outcome(didPersist: false, recipeName: "Sourdough", source: source)
        #expect(outcome == .failed(recipeName: "Sourdough"))
    }

    // MARK: - Successful persist awards the right first-import badge per source

    @Test func linkImport_awardsFirstImport() {
        #expect(RecipeImportStore.outcome(didPersist: true, recipeName: "X", source: .link) == .saved(badge: .firstImport))
    }

    /// Paste is typed text, not a web import — it must not award "Link Master".
    @Test func pasteImport_awardsNoWebBadge() {
        #expect(RecipeImportStore.outcome(didPersist: true, recipeName: "X", source: .paste) == .saved(badge: nil))
    }

    @Test func photoImport_awardsFirstPhotoImport() {
        #expect(RecipeImportStore.outcome(didPersist: true, recipeName: "X", source: .photo) == .saved(badge: .firstPhotoImport))
    }

    @Test("The manual wizard saves without awarding an import badge")
    func wizard_awardsNoBadge() {
        #expect(RecipeImportStore.outcome(didPersist: true, recipeName: "X", source: .wizard) == .saved(badge: nil))
    }
}
