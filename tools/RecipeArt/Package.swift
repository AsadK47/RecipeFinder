// swift-tools-version:6.0
import PackageDescription

// Owner-run, once, on a Mac with Apple Intelligence: draws one illustration per bundled recipe with Image Playground.
// Not part of the app build. Run from the repo root: tools/RecipeArt/run.sh (wraps the binary in a real .app —
// Image Playground refuses a bare command-line process as "background" / "language not supported").
let package = Package(
    name: "RecipeArt",
    platforms: [.macOS("15.4")],
    targets: [
        .executableTarget(name: "RecipeArt", path: "Sources/RecipeArt")
    ]
)
