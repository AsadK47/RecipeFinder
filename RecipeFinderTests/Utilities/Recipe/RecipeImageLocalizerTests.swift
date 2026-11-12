import Testing
import Foundation
@testable import RecipeFinder

/// Offline stand-in for the network: returns canned bytes or an error and records requested URLs.
private final class FakeImageFetcher: RemoteImageFetching, @unchecked Sendable {
    private let result: Result<Data, Error>
    private let lock = NSLock()
    private var calls: [URL] = []

    init(_ result: Result<Data, Error>) {
        self.result = result
    }

    var requestedURLs: [URL] { lock.withLock { calls } }

    func fetchImageData(from url: URL, maxBytes: Int) async throws -> Data {
        lock.withLock { calls.append(url) }
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
        name: "Picture Test Plum Bake", category: "Dessert", difficulty: "Basic",
        prepTime: "10 minutes", cookingTime: "40 minutes", baseServings: 8,
        ingredients: [Ingredient(baseQuantity: 4, unit: "", name: "plums")],
        prePrepInstructions: [], instructions: ["Bake it."], notes: "",
        imageName: imageName, isSampleRecipe: isSample
    )
}

private let webPicture = "https://example.com/plum-cake.jpg"

private func keptFile(_ directory: URL, for reference: String = webPicture) throws -> URL {
    directory.appendingPathComponent(try #require(RemoteRecipeImage.storedPath(for: reference)))
}

@Suite("RecipeImageLocalizer")
struct RecipeImageLocalizerTests {

    @Test("A downloaded picture is kept on the phone as a downscaled JPEG")
    func keepsDownloadedPicture() async throws {
        let directory = try makePictureTempDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let fetcher = FakeImageFetcher(.success(RemoteImageFixtures.png(width: 2400, height: 1600)))
        let localizer = RecipeImageLocalizer(fetcher: fetcher, documentsDirectory: directory)

        let path = await localizer.keep(reference: webPicture)

        #expect(path == RemoteRecipeImage.storedPath(for: webPicture))
        let info = RemoteImageFixtures.describe(try Data(contentsOf: try keptFile(directory)))
        #expect(info.type == "public.jpeg")
        #expect(info.width == 1600)
        #expect(fetcher.requestedURLs.map(\.absoluteString) == [webPicture])
    }

    @Test("Offline or a failing site leaves no file")
    func failedDownloadStoresNothing() async throws {
        let directory = try makePictureTempDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let localizer = RecipeImageLocalizer(fetcher: FakeImageFetcher(.failure(OfflineError())), documentsDirectory: directory)

        #expect(await localizer.keep(reference: webPicture) == nil)
        #expect(!FileManager.default.fileExists(atPath: try keptFile(directory).path))
    }

    @Test("A page that isn't a picture is not kept")
    func nonImageIsNotStored() async throws {
        let directory = try makePictureTempDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let html = Data("<html>blocked</html>".utf8)
        let localizer = RecipeImageLocalizer(fetcher: FakeImageFetcher(.success(html)), documentsDirectory: directory)

        #expect(await localizer.keep(reference: webPicture) == nil)
        #expect(!FileManager.default.fileExists(atPath: try keptFile(directory).path))
    }

    @Test("Non-web references are never fetched")
    func localReferenceIsNotFetched() async throws {
        let fetcher = FakeImageFetcher(.success(RemoteImageFixtures.png(width: 10, height: 10)))
        let localizer = RecipeImageLocalizer(fetcher: fetcher, documentsDirectory: try makePictureTempDirectory())

        #expect(await localizer.keep(reference: "file:///etc/hosts") == nil)
        #expect(await localizer.keep(reference: "RecipeImages/mine.jpg") == nil)
        #expect(fetcher.requestedURLs.isEmpty)
    }

    @Test("Only the cook's own recipes with a web picture and no kept copy need one", arguments: [
        (webPicture, false, true),
        (webPicture, true, false),
        ("RecipeImages/ABC.jpg", false, false),
        ("http://example.com/plain.jpg", false, false),
        ("", false, false)
    ])
    func pictureToKeep(imageName: String, isSample: Bool, expected: Bool) throws {
        let localizer = RecipeImageLocalizer(
            fetcher: FakeImageFetcher(.failure(OfflineError())), documentsDirectory: try makePictureTempDirectory()
        )
        let recipe = makePictureRecipe(imageName: imageName, isSample: isSample)
        #expect((localizer.pictureToKeep(for: recipe) != nil) == expected)
    }

    @Test("A picture already kept isn't downloaded again; removing the copy brings it back")
    func keptPictureIsNotRefetched() async throws {
        let directory = try makePictureTempDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let localizer = RecipeImageLocalizer(
            fetcher: FakeImageFetcher(.success(RemoteImageFixtures.png(width: 20, height: 20))), documentsDirectory: directory
        )
        let recipe = makePictureRecipe(imageName: webPicture)
        #expect(await localizer.keep(reference: webPicture) != nil)

        #expect(localizer.pictureToKeep(for: recipe) == nil)
        localizer.removeCopy(of: webPicture)
        #expect(!FileManager.default.fileExists(atPath: try keptFile(directory).path))
        #expect(localizer.pictureToKeep(for: recipe) == webPicture)
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

    private func pngFetcher() -> FakeImageFetcher {
        FakeImageFetcher(.success(RemoteImageFixtures.png(width: 40, height: 40)))
    }

    @Test("Importing a recipe keeps a phone copy of its picture; the recipe keeps its source URL")
    func importKeepsPicture() async throws {
        let directory = try makePictureTempDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = makeStore(fetcher: pngFetcher(), directory: directory)
        let recipe = makePictureRecipe(imageName: webPicture)

        #expect(store.add(recipe))
        await store.imageLocalization?.value

        #expect(FileManager.default.fileExists(atPath: try keptFile(directory).path))
        #expect(store.recipes.first?.imageName == webPicture)
    }

    @Test("A failing link is tried once per launch, not on every save")
    func failureIsTriedOncePerLaunch() async throws {
        let directory = try makePictureTempDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let fetcher = FakeImageFetcher(.failure(OfflineError()))
        let store = makeStore(fetcher: fetcher, directory: directory)
        var recipe = makePictureRecipe(imageName: webPicture)

        #expect(store.add(recipe))
        recipe.rating = 4
        #expect(store.save(recipe))
        await store.imageLocalization?.value

        #expect(fetcher.requestedURLs.count == 1)
        #expect(store.recipes.first?.imageName == webPicture)
    }

    @Test("Built-in sample recipes are never downloaded")
    func samplesAreSkipped() async throws {
        let directory = try makePictureTempDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let fetcher = pngFetcher()
        let store = makeStore(fetcher: fetcher, directory: directory)

        #expect(store.add(makePictureRecipe(imageName: webPicture, isSample: true)))
        await store.imageLocalization?.value

        #expect(fetcher.requestedURLs.isEmpty)
    }

    @Test("Launch keeps pictures for recipes imported before this version")
    func launchKeepsExistingImports() async throws {
        let directory = try makePictureTempDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let persistence = PersistenceController(inMemory: true)
        let old = makePictureRecipe(imageName: webPicture)
        #expect(persistence.saveRecipeModel(old))
        let fetcher = pngFetcher()
        let store = makeStore(fetcher: fetcher, directory: directory, persistence: persistence)

        store.load()
        for _ in 0..<500 where store.isLoading {
            try? await Task.sleep(for: .milliseconds(10))
        }
        await store.imageLocalization?.value

        #expect(fetcher.requestedURLs.map(\.absoluteString) == [webPicture])
        #expect(FileManager.default.fileExists(atPath: try keptFile(directory).path))
    }

    @Test("Deleting the last recipe with a picture removes its kept copy; a shared one stays")
    func deleteRemovesUnsharedCopy() async throws {
        let directory = try makePictureTempDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = makeStore(fetcher: pngFetcher(), directory: directory)
        let first = makePictureRecipe(imageName: webPicture)
        let second = makePictureRecipe(imageName: webPicture)
        #expect(store.add(first))
        #expect(store.add(second))
        await store.imageLocalization?.value
        let file = try keptFile(directory)

        store.delete(id: first.id)
        #expect(FileManager.default.fileExists(atPath: file.path))
        store.delete(id: second.id)
        #expect(!FileManager.default.fileExists(atPath: file.path))
    }
}
