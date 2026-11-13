// swift-tools-version:6.0
import Foundation
import PackageDescription

/// Absolute, so it resolves wherever `swift run` is started from.
let infoPlist = URL(fileURLWithPath: #filePath).deletingLastPathComponent().appendingPathComponent("Info.plist").path

// Owner-run, once, on a Mac with Apple Intelligence: draws one illustration per bundled recipe with Image Playground.
// Not part of the app build. Run from the repo root: swift run --package-path tools/RecipeArt
let package = Package(
    name: "RecipeArt",
    platforms: [.macOS("15.4")],
    targets: [
        .executableTarget(
            name: "RecipeArt",
            path: "Sources/RecipeArt",
            // A bare SwiftPM binary has no Info.plist, so Image Playground can't tell the app's language ("language
            // not supported"). Embed one declaring English and a bundle identifier.
            linkerSettings: [.unsafeFlags([
                "-Xlinker", "-sectcreate", "-Xlinker", "__TEXT", "-Xlinker", "__info_plist",
                "-Xlinker", infoPlist,
            ])]
        )
    ]
)
