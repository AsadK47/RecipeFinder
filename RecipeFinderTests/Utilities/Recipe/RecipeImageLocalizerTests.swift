import Testing
import Foundation
@testable import RecipeFinder

/// Offline stand-in for the network: returns canned bytes or an error, counts calls, and can run a hook mid-download.
private final class FakeImageFetcher: RemoteImageFetching, @unchecked Sendable {
    private let result: Result<Data, Error>
    private let onFetch: (@Sendable () async -> Void)?
    private let lock = NSLock()
    private var calls: [URL] = []

    init(_ result: Result<Data, Error>, onFetch: (@Sendable () async -> Void)? = nil) {
        self.result = result
        self.onFetch = onFetch
    }

    var requestedURLs: [URL] { lock.withLock { calls } }

    func fetchImageData(from url: URL, maxBytes: Int) async throws -> Data {
        lock.withLock { calls.append(url) }
        await onFetch?()
        return try result.get()
    }
}

private struct OfflineError: Error {}

private func makePictureTempDirectory() throws -> URL {
    let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
    try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    return url
}

private func makePictureRecipe(imageName: String?, isSample: Bool = false) -> RecipeModel {
    RecipeModel(
        name: "Plum Cake", category: "Dessert", difficulty: "Basic",
        prepTime: "10 minutes", cookingTime: "40 minutes", baseServings: 8,
        ingredients: [Ingredient(baseQuantity: 4, unit: "", name: "plums")],
        prePrepInstructions: [], instructions: ["Bake it."], notes: "",
        imageName: imageName, isSampleRecipe: isSample
    )
}

private let webPicture = "https://example.com/plum-cake.jpg"

@Suite("RecipeImageLocalizer")
struct RecipeImageLocalizerTests {

    @Test("A downloaded picture is stored on the phone as the recipe's JPEG")
    func storesDownloadedPicture() async throws {
        let directory = try makePictureTempDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let fetcher = FakeImageFetcher(.success(RemoteImageFixtures.png(width: 2400, height: 1600)))
        let localizer = RecipeImageLocalizer(fetcher: fetcher, documentsDirectory: directory)
        let id = UUID()

        let path = try #require(await localizer.localize(reference: webPicture, recipeId: id))

        #expect(path == "RecipeImages/\(id.uuidString).jpg")
        let stored = try Data(contentsOf: directory.appendingPathComponent(path))
        let info = RemoteImageFixtures.describe(stored)
        #expect(info.type == "public.jpeg")
        #expect(info.width == 1600)
        #expect(fetcher.requestedURLs == [URL(string: webPicture)].compactMap { $0 })
    }

    @Test("Offline or a failing site leaves no picture and no file")
    func failedDownloadStoresNothing() async throws {
        let directory = try makePictureTempDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let localizer = RecipeImageLocalizer(fetcher: FakeImageFetcher(.failure(OfflineError())), documentsDirectory: directory)

        let path = await localizer.localize(reference: webPicture, recipeId: UUID())

        #expect(path == nil)
        let folder = directory.appendingPathComponent("RecipeImages")
        #expect(((try? FileManager.default.contentsOfDirectory(atPath: folder.path)) ?? []).isEmpty)
    }

    @Test("A page that isn't a picture is not stored")
    func nonImageIsNotStored() async throws {
        let directory = try makePictureTempDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let html = Data("<html>blocked</html>".utf8)
        let localizer = RecipeImageLocalizer(fetcher: FakeImageFetcher(.success(html)), documentsDirectory: directory)

        #expect(await localizer.localize(reference: webPicture, recipeId: UUID()) == nil)
    }

    @Test("Non-web references are never fetched")
    func localReferenceIsNotFetched() async throws {
        let fetcher = FakeImageFetcher(.success(RemoteImageFixtures.png(width: 10, height: 10)))
        let localizer = RecipeImageLocalizer(fetcher: fetcher, documentsDirectory: try makePictureTempDirectory())

        #expect(await localizer.localize(reference: "file:///etc/hosts", recipeId: UUID()) == nil)
        #expect(fetcher.requestedURLs.isEmpty)
    }

    @Test("A photo already saved for the recipe is never overwritten")
    func existingPhotoIsKept() async throws {
        let directory = try makePictureTempDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let id = UUID()
        let folder = directory.appendingPathComponent("RecipeImages")
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let mine = Data("my own photo".utf8)
        let photoURL = folder.appendingPathComponent("\(id.uuidString).jpg")
        try mine.write(to: photoURL)
        let fetcher = FakeImageFetcher(.success(RemoteImageFixtures.png(width: 50, height: 50)))
        let localizer = RecipeImageLocalizer(fetcher: fetcher, documentsDirectory: directory)

        #expect(await localizer.localize(reference: webPicture, recipeId: id) == nil)
        #expect(try Data(contentsOf: photoURL) == mine)
    }

    @Test("Only the cook's own recipes with a web picture need downloading", arguments: [
        (webPicture, false, true),
        (webPicture, true, false),
        ("RecipeImages/ABC.jpg", false, false),
        ("", false, false)
    ])
    func needsLocalizing(imageName: String, isSample: Bool, expected: Bool) {
        #expect(RecipeImageLocalizer.needsLocalizing(makePictureRecipe(imageName: imageName, isSample: isSample)) == expected)
    }
}

@MainActor
@Suite("RecipeStore keeps web pictures")
struct RecipeStoreWebPictureTests {

    private func makeStore(
        fetcher: FakeImageFetcher, directory: URL, persistence: PersistenceController = PersistenceController(inMemory: true)
    ) -> RecipeStore {
        RecipeStore(
            persistence: persistence,
            imageStore: RecipeImageStore(documentsDirectory: directory),
            imageLocalizer: RecipeImageLocalizer(fetcher: fetcher, documentsDirectory: directory)
        )
    }

    @Test("Importing a recipe swaps its web picture for a stored copy, saved for next launch")
    func importKeepsPicture() async throws {
        let directory = try makePictureTempDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let persistence = PersistenceController(inMemory: true)
        let store = makeStore(
            fetcher: FakeImageFetcher(.success(RemoteImageFixtures.png(width: 40, height: 40))),
            directory: directory, persistence: persistence
        )
        let recipe = makePictureRecipe(imageName: webPicture)

        #expect(store.add(recipe))
        await store.imageLocalization?.value

        let expected = "RecipeImages/\(recipe.id.uuidString).jpg"
        #expect(store.recipes.first?.imageName == expected)
        let saved = await persistence.fetchRecipesAsync()
        #expect(saved.first(where: { $0.id == recipe.id })?.imageName == expected)
    }

    @Test("When the download fails the recipe keeps its web picture")
    func failureKeepsURL() async throws {
        let directory = try makePictureTempDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = makeStore(fetcher: FakeImageFetcher(.failure(OfflineError())), directory: directory)
        let recipe = makePictureRecipe(imageName: webPicture)

        #expect(store.add(recipe))
        await store.imageLocalization?.value

        #expect(store.recipes.first?.imageName == webPicture)
    }

    @Test("Built-in sample recipes are never downloaded")
    func samplesAreSkipped() async throws {
        let directory = try makePictureTempDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let fetcher = FakeImageFetcher(.success(RemoteImageFixtures.png(width: 40, height: 40)))
        let store = makeStore(fetcher: fetcher, directory: directory)

        #expect(store.add(makePictureRecipe(imageName: webPicture, isSample: true)))
        await store.imageLocalization?.value

        #expect(fetcher.requestedURLs.isEmpty)
        #expect(store.recipes.first?.imageName == webPicture)
    }

    @Test("A photo the cook picks during the download wins")
    func cooksPhotoWinsOverDownload() async throws {
        let directory = try makePictureTempDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let recipe = makePictureRecipe(imageName: webPicture)
        let mine = "RecipeImages/mine.jpg"
        let holder = StoreHolder()
        let fetcher = FakeImageFetcher(.success(RemoteImageFixtures.png(width: 40, height: 40))) {
            await MainActor.run {
                guard let store = holder.store, var edited = store.recipes.first else { return }
                edited.imageName = mine
                store.recipes = [edited]
            }
        }
        let store = makeStore(fetcher: fetcher, directory: directory)
        holder.store = store

        #expect(store.add(recipe))
        await store.imageLocalization?.value

        #expect(store.recipes.first?.imageName == mine)
        let leftover = directory.appendingPathComponent("RecipeImages/\(recipe.id.uuidString).jpg")
        #expect(!FileManager.default.fileExists(atPath: leftover.path))
    }

    @Test("Launch downloads pictures for recipes imported before this version")
    func launchPassCoversExistingImports() async throws {
        let directory = try makePictureTempDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let fetcher = FakeImageFetcher(.success(RemoteImageFixtures.png(width: 40, height: 40)))
        let store = makeStore(fetcher: fetcher, directory: directory)
        let old = makePictureRecipe(imageName: webPicture)
        let local = makePictureRecipe(imageName: "RecipeImages/own.jpg")
        store.recipes = [old, local]

        store.keepWebPictures(of: store.recipes)
        await store.imageLocalization?.value

        #expect(fetcher.requestedURLs.count == 1)
        #expect(store.recipes.first(where: { $0.id == local.id })?.imageName == "RecipeImages/own.jpg")
        #expect(store.recipes.first(where: { $0.id == old.id })?.imageName == "RecipeImages/\(old.id.uuidString).jpg")
    }
}

@MainActor
private final class StoreHolder {
    var store: RecipeStore?
}
