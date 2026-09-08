import Testing
import CoreData
import Foundation
@testable import RecipeFinder

/// Durability guard for the store-recovery path: an unreadable/corrupt store must
/// be **preserved** (moved aside), never silently deleted, so a failed migration
/// or corruption can't wipe the user's recipes. The app still recovers by starting
/// a fresh store, but the original bytes remain on disk for recovery.
@MainActor
@Suite struct PersistenceRecoveryTests {

    @Test func corruptStoreIsPreservedNotDeleted() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        // A file that Core Data cannot open as a store → triggers recovery.
        let storeURL = directory.appendingPathComponent("RecipeModel.sqlite")
        try Data("this is not a valid sqlite store".utf8).write(to: storeURL)

        let controller = PersistenceController(storeURL: storeURL, userID: { "userA" })

        // Recovery started a fresh, usable store...
        #expect(controller.isStoreLoaded)
        // ...and the unreadable original was preserved, not destroyed.
        let preserved = try FileManager.default
            .contentsOfDirectory(atPath: directory.path)
            .filter { $0.hasPrefix("RecipeModel.sqlite.corrupt-") }
        #expect(!preserved.isEmpty)
    }
}
