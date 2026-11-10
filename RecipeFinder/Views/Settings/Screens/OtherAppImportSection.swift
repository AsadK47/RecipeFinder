import SwiftUI
import UniformTypeIdentifiers

/// Settings → Data → "Import from another app": reads a Paprika, Mela or CSV export on device, skips recipes the
/// library already has, and reports what happened ("Imported 182 recipes, skipped 3 duplicates.").
struct OtherAppImportSection: View {
    @Environment(\.recipeStore) private var recipeStore
    @State private var isPicking = false
    @State private var isImporting = false
    @State private var message: String?
    @State private var messageIsError = false

    var body: some View {
        VStack(spacing: AppTheme.spacing8) {
            SettingsSectionHeader(title: "Import from Another App")

            SettingsCard {
                VStack(alignment: .leading, spacing: AppTheme.spacing16) {
                    HStack(spacing: AppTheme.spacing12) {
                        SettingsIconTile(systemName: "tray.and.arrow.down.fill", color: .orange)
                        VStack(alignment: .leading, spacing: AppTheme.spacing2) {
                            Text("Bring Your Recipes")
                                .font(.body)
                                .adaptiveForegroundColor()
                            Text("Paprika, Mela or a CSV file")
                                .font(.caption)
                                .adaptiveSecondaryForeground()
                        }
                    }

                    Text("Export from your old app, then choose the file here. Recipes you already have are skipped, and nothing leaves your device.")
                        .font(.subheadline)
                        .adaptiveSecondaryForeground()
                        .fixedSize(horizontal: false, vertical: true)

                    Button { isPicking = true } label: {
                        Group {
                            if isImporting {
                                ProgressView()
                            } else {
                                Label("Choose Export File", systemImage: "doc.badge.plus")
                                    .font(.body.weight(.semibold))
                            }
                        }
                        .adaptiveForegroundColor()
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AppTheme.spacing12)
                        .background(Color.orange)
                        .cornerRadius(AppTheme.cornerRadius12)
                    }
                    .buttonStyle(.plain)
                    .disabled(isImporting)
                    .accessibilityIdentifier("settings.importOtherApp")
                }
                .padding(AppTheme.spacing20)
            }
        }
        // Any file: Paprika and Mela exports have no system-declared type, so the reader checks the extension.
        .fileImporter(isPresented: $isPicking, allowedContentTypes: [.data]) { result in
            switch result {
            case let .success(url): importFile(at: url)
            case .failure: show("Couldn't open that file.", isError: true)
            }
        }
        .errorAlert(messageIsError ? "Import Problem" : "Import Finished", message: $message)
        .task { await showUITestSummaryIfRequested() }
    }

    private func importFile(at url: URL) {
        let didAccess = url.startAccessingSecurityScopedResource()
        defer { if didAccess { url.stopAccessingSecurityScopedResource() } }
        let data: Data
        do {
            data = try Data(contentsOf: url)
        } catch {
            show("Couldn't read that file.", isError: true)
            return
        }
        let fileName = url.lastPathComponent
        isImporting = true
        Task {
            defer { isImporting = false }
            do {
                // Large exports can hold thousands of recipes: unzip and parse off the main actor.
                let contents = try await Task.detached { try OtherAppExportReader.read(data, fileName: fileName) }.value
                save(contents)
            } catch let error as OtherAppExportError {
                show(error.errorDescription ?? "Couldn't read that export.", isError: true)
            } catch {
                show("Couldn't read that export.", isError: true)
            }
        }
    }

    private func save(_ contents: OtherAppExportReader.Contents) {
        let plan = OtherAppImportPlanner.plan(contents.recipes, existing: recipeStore.recipes,
                                              source: contents.format.rawValue)
        let imageStore = RecipeImageStore()
        var failed = 0
        for var recipe in plan.recipes {
            if let photo = plan.photos[recipe.id], let image = UIImage(data: photo) {
                recipe.imageName = imageStore.persist(image, recipeId: recipe.id)
            }
            if !recipeStore.add(recipe) { failed += 1 }
        }
        var summary = plan.summary
        let problems = contents.unreadable + failed
        if problems > 0 { summary += " \(problems) couldn't be read." }
        show(summary, isError: plan.recipes.isEmpty && problems > 0)
        if failed == 0 { HapticManager.shared.success() } else { HapticManager.shared.error() }
    }

    private func show(_ text: String, isError: Bool) {
        messageIsError = isError
        message = text
    }

    /// Screenshots hook (`-show-other-app-import-summary`): the summary alert without driving the system file picker.
    private func showUITestSummaryIfRequested() async {
        #if DEBUG
        guard ProcessInfo.processInfo.arguments.contains("-show-other-app-import-summary") else { return }
        show("Imported 182 recipes, skipped 3 duplicates.", isError: false)
        #endif
    }
}
