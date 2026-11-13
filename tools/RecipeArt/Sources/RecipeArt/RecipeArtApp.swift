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
    let category: String?
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
    /// Shown so a "language not supported" failure can be matched against System Settings.
    @Published var languages = ""

    static let seedPath = "RecipeFinder/RecipeSeed/recipes_seed.json"
    static let outputPath = "tools/RecipeArt/Output"
    /// Longest edge of the saved JPEG; the app bundle step compresses further.
    static let maxEdge: CGFloat = 1024

    func run() async {
        let fm = FileManager.default
        // Launched as an .app by run.sh, which passes the repo root (an app starts in "/").
        if CommandLine.arguments.count > 1 {
            fm.changeCurrentDirectoryPath(CommandLine.arguments[1])
        }
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
        languages = Locale.preferredLanguages.prefix(3).joined(separator: ", ")
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
                let cgImage = try await draw(recipe, with: creator, style: style)
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


    /// Tries each prompt in turn (full → name only → plain description). Image Playground only draws for the app in
    /// front: if the window isn't active, or creation is refused for being in the background, wait until it is and
    /// retry the same prompt instead of failing the recipe.
    private func draw(_ recipe: SeedRecipe, with creator: ImageCreator, style: ImagePlaygroundStyle) async throws -> CGImage {
        var lastError: Error = ArtError.noImage
        for prompt in Self.prompts(for: recipe) {
            var backgroundRetries = 0
            while true {
                await waitUntilFrontmost(recipe)
                do {
                    for try await created in creator.images(for: [.text(prompt)], style: style, limit: 1) {
                        return created.cgImage
                    }
                    throw ArtError.noImage
                } catch let error as ImageCreator.Error {
                    lastError = error
                    if case .backgroundCreationForbidden = error, backgroundRetries < 20 {
                        backgroundRetries += 1
                        continue
                    }
                    if case .creationFailed = error, backgroundRetries == 0 {
                        backgroundRetries += 1   // one plain retry for a one-off failure
                        continue
                    }
                    break   // try the next, simpler prompt
                } catch {
                    lastError = error
                    break
                }
            }
        }
        throw lastError
    }

    private func waitUntilFrontmost(_ recipe: SeedRecipe) async {
        guard !NSApp.isActive else { return }
        status = "Paused — click this window to carry on (Image Playground only draws for the app in front)."
        while !NSApp.isActive {
            try? await Task.sleep(for: .milliseconds(500))
        }
        status = "Drawing \(recipe.name)…"
    }

    /// Simplest-last: the full description, then the dish name alone, then the name without brackets/extra words.
    static func prompts(for recipe: SeedRecipe) -> [String] {
        let plainName = recipe.name
            .replacingOccurrences(of: #"\s*\([^)]*\)"#, with: "", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        // Image Playground rejects any non-English word ("achari", "gochujang", "ragu"…) and can read a dish name as
        // a person ("Mei Fun"), so the last two describe the dish in plain English without its name.
        let dish = dishPhrase(for: recipe)
        let protein = mainProtein(in: recipe.name.lowercased())
        var list = [prompt(for: recipe), "A plated dish of \(recipe.name)", "A plated dish of \(plainName)"]
        if let protein { list.append("\(dish) with \(protein), on a table") }
        list.append("\(dish), on a table")
        var seen = Set<String>()
        list = list.filter { seen.insert($0).inserted }
        return list
    }


    /// The kind of dish in plain English, from words in its name, else its category.
    static func dishPhrase(for recipe: SeedRecipe) -> String {
        let name = recipe.name.lowercased()
        let kinds: [(words: [String], phrase: String)] = [
            (["dal", "dhal", "daal"], "A bowl of lentil stew"),
            (["curry", "masala", "korma", "gosht", "achari", "haleem", "kulambu", "sabzi", "bharta", "jalfrezi", "bhuna", "karahi", "rogan", "vindaloo", "saag"], "A bowl of curry"),
            (["noodle", "mein", "ramen", "udon", "japchae", "biang", "mei fun", "pho", "pad thai", "spaghetti", "pasta", "ragu", "lasagne", "kottu"], "A bowl of noodles"),
            (["congee", "porridge"], "A bowl of rice porridge"),
            (["rice", "biryani", "jollof", "pulao", "pilau", "risotto", "paella"], "A plate of rice"),
            (["soup", "dashi", "broth", "ramen"], "A bowl of soup"),
            (["salad", "kachumber"], "A bowl of salad"),
            (["pancake", "hotteok", "apam", "crepe", "dosa"], "A stack of pancakes"),
            (["cake", "brownie", "gao", "kurtos", "kürtős", "muffin", "cupcake"], "A slice of cake"),
            (["bread", "roti", "flatbread", "naan", "paratha", "bun", "tangzhong", "loaf"], "Freshly baked bread"),
            (["chai", "tea", "frappe", "milkshake", "latte", "lassi", "smoothie", "coffee"], "A drink in a glass"),
            (["kulfi", "ice cream", "sorbet", "gelato"], "A frozen dessert"),
            (["mousse", "kunafa", "jalebi", "rugelach", "tangyuan", "pudding", "halwa", "kheer", "tart", "pie", "crumble"], "A dessert"),
            (["sauce", "chutney", "dip", "salsa"], "A bowl of sauce"),
            (["wing", "drumstick", "kebab", "tikki", "kofta", "pakora", "samosa", "goujon", "nugget"], "A plate of fried snacks"),
            (["tofu"], "A plate of tofu"),
            (["leg", "roast", "steak", "chop"], "A plated roast"),
        ]
        for kind in kinds where kind.words.contains(where: { name.contains($0) }) {
            return kind.phrase
        }
        switch (recipe.category ?? "").lowercased() {
        case let c where c.contains("dessert") || c.contains("baking") || c.contains("sweet"): return "A dessert"
        case let c where c.contains("drink") || c.contains("beverage"): return "A drink in a glass"
        case let c where c.contains("breakfast"): return "A plated breakfast"
        case let c where c.contains("side") || c.contains("snack") || c.contains("starter"): return "A small plate of food"
        default: return "A plated main dish"
        }
    }

    /// An English protein named in the dish, if any.
    static func mainProtein(in name: String) -> String? {
        ["chicken", "lamb", "beef", "pork", "turkey", "salmon", "cod", "fish", "prawn", "shrimp", "egg", "potato", "aubergine", "eggplant", "chickpea", "lentil", "paneer", "tofu", "vegetables", "mushroom"]
            .first { name.contains($0) }
            .map { $0 == "paneer" ? "cheese" : $0 }
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
            if !generator.languages.isEmpty {
                Text("Mac languages: \(generator.languages)").font(.caption).foregroundStyle(.secondary)
            }
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
