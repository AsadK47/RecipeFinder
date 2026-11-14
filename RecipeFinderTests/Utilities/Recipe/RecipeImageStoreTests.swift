import Testing
import Foundation
import UIKit
@testable import RecipeFinder

@Suite("RecipeImageStore")
struct RecipeImageStoreTests {

    /// A minimal 1×1 image so persistence has real JPEG bytes to write.
    private func makeImage() -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 1, height: 1))
        return renderer.image { context in
            UIColor.red.setFill()
            context.fill(CGRect(x: 0, y: 0, width: 1, height: 1))
        }
    }

    private func makeTempDirectory() -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    @Test("Persisting writes a JPEG under RecipeImages named for the recipe id")
    func persistsImageToDisk() throws {
        let directory = makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = RecipeImageStore(documentsDirectory: directory)
        let id = UUID()

        let path = try #require(store.persist(makeImage(), recipeId: id))

        // `persist` returns a container-relative path by design; resolve it to an
        // absolute path before asserting the file exists on disk.
        #expect(path.hasSuffix("RecipeImages/\(id.uuidString).jpg"))
        let absolutePath = try #require(store.absolutePath(for: path))
        #expect(FileManager.default.fileExists(atPath: absolutePath))
    }

    @Test("Gallery photos added after a delete never reuse an existing file name")
    func galleryNamesAreUniqueAfterDelete() throws {
        let directory = makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = RecipeImageStore(documentsDirectory: directory)
        let id = UUID()

        let first = store.persistGallery([makeImage(), makeImage()], recipeId: id)
        #expect(first.count == 2)
        store.deleteIfLocal(first[0])
        let kept = first[1]

        let added = store.persistGallery([makeImage()], recipeId: id)

        #expect(added.count == 1)
        #expect(!added.contains(kept))
        #expect(Set(first + added).count == 3)
        let keptPath = try #require(store.absolutePath(for: kept))
        #expect(FileManager.default.fileExists(atPath: keptPath))
        #expect(added.allSatisfy { $0.hasPrefix("RecipeImages/\(id.uuidString)_") })
    }

    @Test("deleteIfLocal removes an owned on-disk image file")
    func deleteIfLocalRemovesFile() throws {
        let directory = makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = RecipeImageStore(documentsDirectory: directory)
        let path = try #require(store.persist(makeImage(), recipeId: UUID()))
        let absolutePath = try #require(store.absolutePath(for: path))
        #expect(FileManager.default.fileExists(atPath: absolutePath))

        store.deleteIfLocal(path)

        #expect(!FileManager.default.fileExists(atPath: absolutePath))
    }

    @Test("deleteIfLocal ignores remote URLs")
    func deleteIfLocalIgnoresRemote() {
        let directory = makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = RecipeImageStore(documentsDirectory: directory)
        // Should simply no-op (and not crash) for a non-owned reference.
        store.deleteIfLocal("https://example.com/photo.jpg")
    }

    @Test("A freshly selected image is persisted and its path returned")
    func resolvePersistsSelectedImage() throws {
        let directory = makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = RecipeImageStore(documentsDirectory: directory)

        let reference = store.resolveReference(
            recipeId: UUID(),
            selectedImage: makeImage(),
            existingReference: nil,
            previousReference: nil
        )

        // `resolveReference` returns a container-relative path by design; resolve
        // it to an absolute path before asserting the file exists on disk.
        let path = try #require(reference)
        let absolutePath = try #require(store.absolutePath(for: path))
        #expect(FileManager.default.fileExists(atPath: absolutePath))
    }

    @Test("With no new image, an existing reference is kept")
    func resolveKeepsExistingReference() {
        let store = RecipeImageStore(documentsDirectory: makeTempDirectory())

        let reference = store.resolveReference(
            recipeId: UUID(),
            selectedImage: nil,
            existingReference: "https://example.com/photo.jpg",
            previousReference: nil
        )

        #expect(reference == "https://example.com/photo.jpg")
    }

    @Test("With nothing to keep, a stale local previous file is deleted and nil returned")
    func resolveCleansUpStaleLocalFile() throws {
        let directory = makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = RecipeImageStore(documentsDirectory: directory)

        // Seed a local file to stand in for the recipe's previous image.
        let staleURL = directory.appendingPathComponent("stale.jpg")
        try Data([0x1]).write(to: staleURL)

        let reference = store.resolveReference(
            recipeId: UUID(),
            selectedImage: nil,
            existingReference: nil,
            previousReference: staleURL.path
        )

        #expect(reference == nil)
        #expect(!FileManager.default.fileExists(atPath: staleURL.path))
    }

    @Test("A remote previous reference is treated as non-local and left untouched")
    func remoteReferenceIsNotLocal() {
        let store = RecipeImageStore(documentsDirectory: makeTempDirectory())

        #expect(store.isLocalReference("https://example.com/a.jpg") == false)
        #expect(store.isLocalReference("") == false)
    }

    @Test("Deleting all photos removes every file in RecipeImages, the cook's own and kept web copies")
    func deleteAllPhotosRemovesThePhotoFolder() throws {
        let directory = makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = RecipeImageStore(documentsDirectory: directory)
        let own = try #require(store.persist(makeImage(), recipeId: UUID()))
        let gallery = store.persistGallery([makeImage()], recipeId: UUID())
        let webCopy = directory.appendingPathComponent("RecipeImages/web-abc.jpg")
        try Data([0xFF, 0xD8]).write(to: webCopy)
        let elsewhere = directory.appendingPathComponent("RecipeFinderBackup.json")
        try Data("{}".utf8).write(to: elsewhere)

        try store.deleteAllPhotos()

        for path in [own] + gallery {
            let absolute = try #require(store.absolutePath(for: path))
            #expect(!FileManager.default.fileExists(atPath: absolute))
        }
        #expect(!FileManager.default.fileExists(atPath: webCopy.path))
        #expect(FileManager.default.fileExists(atPath: elsewhere.path))
    }

    @Test("Deleting all photos when there are none succeeds and a new photo can be saved after")
    func deleteAllPhotosWithNoFolderSucceeds() throws {
        let directory = makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = RecipeImageStore(documentsDirectory: directory)

        try store.deleteAllPhotos()

        #expect(store.persist(makeImage(), recipeId: UUID()) != nil)
    }
}
