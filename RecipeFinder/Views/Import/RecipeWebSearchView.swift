import SwiftUI
import WebKit

/// Import → "Search the web": search on the cook's chosen engine in an in-app browser, then import the page they're
/// on with the existing link importer. Pages load straight from the site; browsing data isn't kept (non-persistent store).
struct RecipeWebSearchView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("webSearchEngine") private var engineRaw = WebRecipeSearchEngine.default.rawValue

    @State private var query = ""
    @State private var pageURL: URL?
    @State private var currentURL: URL?
    @State private var hasRecipe = false
    @State private var importTarget: ImportTarget?
    @FocusState private var queryFocused: Bool

    var existingNames: [String] = []
    var onImport: (RecipeModel) -> Void

    private var engine: WebRecipeSearchEngine { WebRecipeSearchEngine(rawValue: engineRaw) ?? .default }

    /// Identifiable wrapper so the importer is presented with `.sheet(item:)` (never stale on first present).
    struct ImportTarget: Identifiable {
        let url: URL
        var id: String { url.absoluteString }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: AppTheme.spacing8) {
                TextField("Search \(engine.displayName) for a recipe", text: $query)
                    .textFieldStyle(.plain)
                    .appInputField()
                    .submitLabel(.search)
                    .focused($queryFocused)
                    .onSubmit(search)
                    .accessibilityIdentifier("webSearch.query")
                Menu {
                    Picker("Search engine", selection: $engineRaw) {
                        ForEach(WebRecipeSearchEngine.allCases) { Text($0.displayName).tag($0.rawValue) }
                    }
                } label: {
                    Image(systemName: "magnifyingglass.circle")
                        .font(.title2)
                        .frame(width: AppTheme.height44, height: AppTheme.height44)
                }
                .accessibilityLabel("Search engine: \(engine.displayName)")
            }
            .padding(AppTheme.spacing12)

            if let pageURL {
                RecipeWebView(url: pageURL, currentURL: $currentURL, hasRecipe: $hasRecipe)
                    .overlay(alignment: .bottom) { importBar }
            } else {
                ContentUnavailableView {
                    Label("Find a recipe online", systemImage: "globe")
                } description: {
                    Text("Search, open a recipe page, then tap Import this recipe.")
                } actions: {
                    Button("Search") { search() }.disabled(query.isBlank)
                }
            }
        }
        .onAppear { queryFocused = true }
        .sheetDismissButton("Done", placement: .cancellationAction)
        .sheetScaffold("Search the Web")
        .sheet(item: $importTarget) { target in
            RecipeImportView(initialURL: target.url.absoluteString, existingNames: existingNames) { recipe in
                onImport(recipe)
                dismiss()
            }
        }
    }

    private var importBar: some View {
        Button {
            guard let currentURL else { return }
            HapticManager.shared.light()
            importTarget = ImportTarget(url: currentURL)
        } label: {
            Label(hasRecipe ? "Recipe found ✓ — Import this recipe" : "Import this recipe",
                  systemImage: hasRecipe ? "checkmark.seal.fill" : "square.and.arrow.down")
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity, minHeight: AppTheme.height44)
        }
        .buttonStyle(.borderedProminent)
        .tint(hasRecipe ? .green : .orange)
        .disabled(currentURL == nil)
        .padding(AppTheme.spacing16)
        .accessibilityIdentifier("webSearch.import")
    }

    private func search() {
        guard let url = engine.searchURL(for: query) else { return }
        queryFocused = false
        hasRecipe = false
        pageURL = url
    }
}

/// `WKWebView` (not `SFSafariViewController`, which can't report the page back) with a non-persistent data store.
/// Reports the current URL and whether the loaded page carries schema.org Recipe data.
private struct RecipeWebView: UIViewRepresentable {
    let url: URL
    @Binding var currentURL: URL?
    @Binding var hasRecipe: Bool

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.websiteDataStore = .nonPersistent()
        let view = WKWebView(frame: .zero, configuration: config)
        view.navigationDelegate = context.coordinator
        view.allowsBackForwardNavigationGestures = true
        view.load(URLRequest(url: url))
        return view
    }

    func updateUIView(_ view: WKWebView, context: Context) {
        if context.coordinator.requestedURL != url {
            context.coordinator.requestedURL = url
            view.load(URLRequest(url: url))
        }
    }

    @MainActor
    final class Coordinator: NSObject, WKNavigationDelegate {
        var parent: RecipeWebView
        var requestedURL: URL?

        init(_ parent: RecipeWebView) {
            self.parent = parent
            self.requestedURL = parent.url
        }

        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            parent.hasRecipe = false
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            parent.currentURL = webView.url
            Task { @MainActor in
                // A page we can't read just shows no badge — Import still works on its URL.
                let html = (try? await webView.evaluateJavaScript("document.documentElement.outerHTML")) as? String
                parent.hasRecipe = html.map(RecipeParser.hasRecipeData(html:)) ?? false
            }
        }
    }
}
