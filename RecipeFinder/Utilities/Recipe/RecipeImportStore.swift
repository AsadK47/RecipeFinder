import Foundation

/// Where an imported recipe came from — determines which "first import" badge is awarded.
enum ImportSource { case link, photo, paste, wizard }

/// The decision after attempting to persist an imported recipe. Pure so the success/failure branching —
/// surface an error (no phantom recipe) on a failed persist, award the right badge on success — is unit-tested
/// rather than trapped inside `ImportView`.
enum RecipeImportStore {
    enum Outcome: Equatable {
        /// Persisted; `badge` is the first-import badge to award (nil for the manual wizard).
        case saved(badge: BadgeType?)
        /// Persist failed; the UI should alert with this recipe name and show nothing new.
        case failed(recipeName: String)
    }

    static func outcome(didPersist: Bool, recipeName: String, source: ImportSource) -> Outcome {
        guard didPersist else { return .failed(recipeName: recipeName) }
        switch source {
        case .link:           return .saved(badge: .firstImport)
        case .photo:          return .saved(badge: .firstPhotoImport)
        // Paste is typed text, not a web import — "Link Master" ("from the web", "pasting a URL") would mislabel it.
        case .paste, .wizard: return .saved(badge: nil)
        }
    }
}
