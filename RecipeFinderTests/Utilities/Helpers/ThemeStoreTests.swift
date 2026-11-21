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
        defaults.set("Teal", forKey: ThemeStore.storageKey)
        #expect(ThemeStore(defaults: defaults).theme == .teal)
    }

    @Test("A theme saved under an old name opens as its new theme and is saved under the new name")
    func migratesOldName() {
        let defaults = freshDefaults()
        defaults.set("Purple", forKey: ThemeStore.storageKey)
        #expect(ThemeStore(defaults: defaults).theme == .plum)
        #expect(defaults.string(forKey: ThemeStore.storageKey) == "Plum")
    }

    @Test("Gold and Yellow both become Honey")
    func goldAndYellowMerge() {
        for old in ["Gold", "Yellow"] {
            let defaults = freshDefaults()
            defaults.set(old, forKey: ThemeStore.storageKey)
            #expect(ThemeStore(defaults: defaults).theme == .honey)
        }
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
        ThemeStore(defaults: defaults).theme = .honey
        #expect(ThemeStore(defaults: defaults).theme == .honey)
    }

    @Test("The app-wide accent follows the selected theme (was hard-coded teal)")
    func accentFollowsTheme() {
        let store = ThemeStore.shared
        let original = store.theme
        defer { store.theme = original }
        store.theme = .plum
        #expect(AppTheme.accentColor == AppTheme.accentColor(for: .plum))
    }
}
