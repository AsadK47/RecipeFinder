import AppKit
import ImagePlayground
import SwiftUI
import UniformTypeIdentifiers

/// Draws one Image Playground illustration per bundled recipe into `tools/RecipeArt/Output/<recipe id>.jpg`.
/// Resumable: recipes that already have a file are skipped, so it can be stopped and run again.
/// Image Playground only creates images for a foreground app, so this is a small window app, not a plain script.
@main
struct RecipeArtApp: App {
    var body: some Scene {
        WindowGroup("Recipe Art") {
            ProgressScreen()
                .frame(minWidth: 460, minHeight: 320)
        }
    }
}

struct SeedRecipe: Decodable {
    struct Ingredient: Decodable { let name: String }
    let id: String
    let name: String
    let ingredients: [Ingredient]
}

@MainActor
final class Generator: ObservableObject {
    @Published var status = "Starting…"
    @Published var done = 0
    @Published var total = 0
    @Published var skipped = 0
    @Published var failures: [String] = []
    @Published var finished = false
    @Published var lastImage: NSImage?

    static let seedPath = "RecipeFinder/RecipeSeed/recipes_seed.json"
    static let outputPath = "tools/RecipeArt/Output"
    /// Longest edge of the saved JPEG; the app bundle step compresses further.
    static let maxEdge: CGFloat = 1024

    func run() async {
        let fm = FileManager.default
        guard fm.fileExists(atPath: Self.seedPath) else {
            status = "Run this from the RecipeFinder folder (couldn't find \(Self.seedPath))."
            finished = true
            return
        }
        let recipes: [SeedRecipe]
        do {
            recipes = try JSONDecoder().decode([SeedRecipe].self, from: Data(contentsOf: URL(fileURLWithPath: Self.seedPath)))
        } catch {
            status = "Couldn't read the recipes: \(error.localizedDescription)"
            finished = true
            return
        }
        do {
            try fm.createDirectory(atPath: Self.outputPath, withIntermediateDirectories: true)
        } catch {
            status = "Couldn't create \(Self.outputPath): \(error.localizedDescription)"
            finished = true
            return
        }

        let creator: ImageCreator
        do {
            creator = try await ImageCreator()
        } catch {
            status = "Image Playground isn't available: \(error.localizedDescription)\nTurn on Apple Intelligence in System Settings, wait for it to finish downloading, then run again."
            finished = true
            return
        }
        let style: ImagePlaygroundStyle = creator.availableStyles.contains(.illustration)
            ? .illustration : (creator.availableStyles.first ?? .illustration)

        total = recipes.count
        for recipe in recipes {
            let url = URL(fileURLWithPath: "\(Self.outputPath)/\(recipe.id).jpg")
            if fm.fileExists(atPath: url.path) {
                skipped += 1
                done += 1
                continue
            }
            status = "Drawing \(recipe.name)…"
            do {
                var cgImage: CGImage?
                for try await created in creator.images(for: [.text(Self.prompt(for: recipe))], style: style, limit: 1) {
                    cgImage = created.cgImage
                }
                guard let cgImage else { throw ArtError.noImage }
                try Self.saveJPEG(cgImage, to: url)
                lastImage = NSImage(cgImage: cgImage, size: .zero)
            } catch {
                failures.append("\(recipe.name): \(error.localizedDescription)")
            }
            done += 1
        }
        status = failures.isEmpty
            ? "All done. Commit and push tools/RecipeArt/Output."
            : "Done with \(failures.count) failures — run again to retry them, then commit and push tools/RecipeArt/Output."
        finished = true
    }

    /// The dish itself, plated, from its name and first few ingredients — no people or text.
    static func prompt(for recipe: SeedRecipe) -> String {
        let key = recipe.ingredients.prefix(4).map(\.name)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        let with = key.isEmpty ? "" : ", made with \(key.joined(separator: ", "))"
        return "A beautifully plated dish of \(recipe.name)\(with), on a table, viewed from slightly above"
    }

    enum ArtError: LocalizedError {
        case noImage, writeFailed
        var errorDescription: String? {
            switch self {
            case .noImage: "No image was created"
            case .writeFailed: "Couldn't save the image"
            }
        }
    }

    static func saveJPEG(_ image: CGImage, to url: URL) throws {
        let scale = min(1, maxEdge / CGFloat(max(image.width, image.height)))
        let width = Int(CGFloat(image.width) * scale), height = Int(CGFloat(image.height) * scale)
        guard let context = CGContext(
            data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: 0,
            space: CGColorSpace(name: CGColorSpace.sRGB) ?? CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
        ) else { throw ArtError.writeFailed }
        context.interpolationQuality = .high
        context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
        guard let resized = context.makeImage(),
              let destination = CGImageDestinationCreateWithURL(url as CFURL, UTType.jpeg.identifier as CFString, 1, nil)
        else { throw ArtError.writeFailed }
        CGImageDestinationAddImage(destination, resized, [kCGImageDestinationLossyCompressionQuality: 0.82] as CFDictionary)
        guard CGImageDestinationFinalize(destination) else { throw ArtError.writeFailed }
    }
}

struct ProgressScreen: View {
    @StateObject private var generator = Generator()

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recipe Art").font(.title2.bold())
            if generator.total > 0 {
                ProgressView(value: Double(generator.done), total: Double(generator.total))
                Text("\(generator.done) of \(generator.total)" + (generator.skipped > 0 ? " (\(generator.skipped) already done)" : ""))
                    .font(.callout).foregroundStyle(.secondary)
            }
            Text(generator.status).fixedSize(horizontal: false, vertical: true)
            if let image = generator.lastImage {
                Image(nsImage: image).resizable().scaledToFit().frame(maxHeight: 160).clipShape(.rect(cornerRadius: 10))
            }
            if !generator.failures.isEmpty {
                Text("Failed (\(generator.failures.count)):").font(.callout.bold())
                ScrollView { Text(generator.failures.joined(separator: "\n")).font(.caption).frame(maxWidth: .infinity, alignment: .leading) }
            }
            if generator.finished {
                Button("Quit") { NSApp.terminate(nil) }
            }
        }
        .padding(20)
        .task {
            // A SwiftPM executable starts as a background process; Image Playground needs a foreground app.
            NSApp.setActivationPolicy(.regular)
            NSApp.activate()
            await generator.run()
        }
    }
}
