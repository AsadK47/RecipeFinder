import Testing
import CoreData
import Foundation
import UIKit
@testable import RecipeFinder

/// Store-recovery durability: a corrupt/unreadable store must be moved aside and preserved, never silently deleted, so a failed migration can't wipe recipes — the app starts fresh but the original bytes stay on disk.
@MainActor
@Suite struct PersistenceRecoveryTests {

    @Test func corruptStoreIsPreservedNotDeleted() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        // A file that Core Data cannot open as a store → triggers recovery.
        let storeURL = directory.appendingPathComponent("RecipeModel.sqlite")
        try Data("this is not a valid sqlite store".utf8).write(to: storeURL)

        let controller = PersistenceController(storeURL: storeURL, backupDirectory: directory.appendingPathComponent("StoreBackups"))

        // Recovery started a fresh, usable store...
        #expect(controller.isStoreLoaded)
        // ...and the unreadable original was preserved, not destroyed.
        let preserved = try FileManager.default
            .contentsOfDirectory(atPath: directory.path)
            .filter { $0.hasPrefix("RecipeModel.sqlite.corrupt-") }
        #expect(!preserved.isEmpty)
    }

    /// Before first unlock the store's file can't be read; that's a locked device, not a broken store, so it must
    /// stay where it is (moving it aside makes the library look empty after unlock).
    @Test func lockedDeviceLeavesTheStoreInPlace() throws {
        let directory = try Self.makeDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let storeURL = try Self.unreadableStore(in: directory)

        let controller = PersistenceController(
            storeURL: storeURL, isProtectedDataAvailable: { false }, notificationCenter: NotificationCenter()
        )

        #expect(!controller.isStoreLoaded)
        #expect(FileManager.default.fileExists(atPath: storeURL.path))
        #expect(try Self.preservedCopies(in: directory).isEmpty)
    }

    /// Once the cook unlocks, the store is opened again; one that still won't open is recovered as before.
    @Test func unlockOpensTheStoreAgain() throws {
        let directory = try Self.makeDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let storeURL = try Self.unreadableStore(in: directory)
        let center = NotificationCenter()
        let device = DeviceLock()

        let controller = PersistenceController(
            storeURL: storeURL, isProtectedDataAvailable: { device.isUnlocked }, notificationCenter: center
        )
        device.isUnlocked = true
        center.post(name: UIApplication.protectedDataDidBecomeAvailableNotification, object: nil)

        #expect(controller.isStoreLoaded)
        #expect(try !Self.preservedCopies(in: directory).isEmpty)
    }

    /// A healthy store that was unreadable while locked opens in place after unlock — nothing is moved aside.
    @Test func unlockOpensAHealthyStoreInPlace() throws {
        let directory = try Self.makeDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let healthy = directory.appendingPathComponent("Healthy", isDirectory: true)
        try FileManager.default.createDirectory(at: healthy, withIntermediateDirectories: true)
        let healthyURL = healthy.appendingPathComponent("RecipeModel.sqlite")
        _ = PersistenceController(storeURL: healthyURL)
        let storeURL = try Self.unreadableStore(in: directory)
        let center = NotificationCenter()
        let device = DeviceLock()

        let controller = PersistenceController(
            storeURL: storeURL, isProtectedDataAvailable: { device.isUnlocked }, notificationCenter: center
        )
        try FileManager.default.removeItem(at: storeURL)
        for sidecar in ["", "-wal", "-shm"] where FileManager.default.fileExists(atPath: healthyURL.path + sidecar) {
            try FileManager.default.copyItem(atPath: healthyURL.path + sidecar, toPath: storeURL.path + sidecar)
        }
        device.isUnlocked = true
        center.post(name: UIApplication.protectedDataDidBecomeAvailableNotification, object: nil)

        #expect(controller.isStoreLoaded)
        #expect(try Self.preservedCopies(in: directory).isEmpty)
    }

    /// Readers that found the store closed at launch hear when it opens after unlock.
    @Test func unlockTellsWaitersTheStoreOpened() throws {
        let directory = try Self.makeDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let storeURL = try Self.unreadableStore(in: directory)
        let center = NotificationCenter()
        let device = DeviceLock()
        let controller = PersistenceController(
            storeURL: storeURL, isProtectedDataAvailable: { device.isUnlocked }, notificationCenter: center
        )
        var heard = 0
        controller.whenStoreOpensLate { heard += 1 }

        device.isUnlocked = true
        center.post(name: UIApplication.protectedDataDidBecomeAvailableNotification, object: nil)

        #expect(heard == 1)
    }

    /// A store that opened at launch never sends a late-open signal, so lists don't load twice.
    @Test func aStoreOpenAtLaunchSendsNoLateOpen() throws {
        let center = NotificationCenter()
        let controller = PersistenceController(inMemory: true, notificationCenter: center)
        var heard = 0
        controller.whenStoreOpensLate { heard += 1 }

        center.post(name: UIApplication.protectedDataDidBecomeAvailableNotification, object: nil)

        #expect(controller.isStoreLoaded)
        #expect(heard == 0)
    }

    /// The library loads once the store opens after unlock, instead of staying empty until relaunch.
    @Test func recipeStoreLoadsWhenTheStoreOpensAfterUnlock() async throws {
        let directory = try Self.makeDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let storeURL = try Self.unreadableStore(in: directory)
        let center = NotificationCenter()
        let device = DeviceLock()
        let controller = PersistenceController(
            storeURL: storeURL, isProtectedDataAvailable: { device.isUnlocked }, notificationCenter: center
        )
        let store = RecipeStore(persistence: controller)

        device.isUnlocked = true
        center.post(name: UIApplication.protectedDataDidBecomeAvailableNotification, object: nil)
        for _ in 0..<1000 where store.isLoading {
            try await Task.sleep(for: .milliseconds(10))
        }

        #expect(!store.isLoading)
    }

    @MainActor private final class DeviceLock {
        var isUnlocked = false
    }

    private static func makeDirectory() throws -> URL {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }

    /// A file Core Data can't open, standing in for a store the locked device won't let it read.
    private static func unreadableStore(in directory: URL) throws -> URL {
        let storeURL = directory.appendingPathComponent("RecipeModel.sqlite")
        try Data("this is not a valid sqlite store".utf8).write(to: storeURL)
        return storeURL
    }

    private static func preservedCopies(in directory: URL) throws -> [String] {
        try FileManager.default.contentsOfDirectory(atPath: directory.path)
            .filter { $0.hasPrefix("RecipeModel.sqlite.corrupt-") }
    }
}
