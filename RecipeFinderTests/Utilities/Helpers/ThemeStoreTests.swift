import Testing
import Foundation
@testable import RecipeFinder

@MainActor
@Suite("ThemeStore")
struct ThemeStoreTests {

    private func freshDefaults() -> UserDefaults {
        let name = "ThemeStoreTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: name) ?? .standard
        defaults.removePersistentDomain(forName: name)
        return defaults
    }

    @Test("Defaults to teal when nothing is stored")
    func defaultsToTeal() {
        #expect(ThemeStore(defaults: freshDefaults()).theme == .teal)
    }

    @Test("Reads the theme saved by earlier versions under the same key")
    func readsStoredTheme() {
        let defaults = freshDefaults()
        defaults.set("Purple", forKey: ThemeStore.storageKey)
        #expect(ThemeStore(defaults: defaults).theme == .purple)
    }

    @Test("Unknown stored value falls back to teal")
    func unknownFallsBack() {
        let defaults = freshDefaults()
        defaults.set("Chartreuse", forKey: ThemeStore.storageKey)
        #expect(ThemeStore(defaults: defaults).theme == .teal)
    }

    @Test("Changing the theme persists it across relaunch")
    func persistsChange() {
        let defaults = freshDefaults()
        ThemeStore(defaults: defaults).theme = .gold
        #expect(ThemeStore(defaults: defaults).theme == .gold)
    }

    @Test("The app-wide accent follows the selected theme (was hard-coded teal)")
    func accentFollowsTheme() {
        let store = ThemeStore.shared
        let original = store.theme
        defer { store.theme = original }
        store.theme = .purple
        #expect(AppTheme.accentColor == AppTheme.accentColor(for: .purple))
    }
}
