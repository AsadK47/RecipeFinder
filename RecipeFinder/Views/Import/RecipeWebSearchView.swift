import SwiftUI
import WebKit

/// Recipes + → "Search the web": search on the cook's chosen engine in an in-app browser, then import the page they're
/// on with the existing link importer. Pages load straight from the site; browsing data isn't kept (non-persistent store).
struct RecipeWebSearchView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("webSearchEngine") private var engineRaw = WebRecipeSearchEngine.default.rawValue
    @AppStorage("recentWebSearches") private var recentRaw = ""

    @State private var query = ""
    @State private var isEditing = true
    @State private var browser = WebBrowserModel()
    @State private var importTarget: ImportTarget?
    @FocusState private var queryFocused: Bool

    var existingNames: [String] = []
    var onImport: (RecipeModel) -> Void

    private var engine: WebRecipeSearchEngine { WebRecipeSearchEngine(rawValue: engineRaw) ?? .default }
    private var recent: [String] { RecentWebSearches.decode(recentRaw) }
    private var offer: WebImportOffer {
        WebSearchBrowsing.offer(for: browser.currentURL, isLoading: browser.isLoading,
                                recipeDetected: browser.recipeDetected)
    }

    /// Identifiable wrapper so the importer is presented with `.sheet(item:)` (never stale on first present).
    struct ImportTarget: Identifiable {
        let url: URL
        var id: String { url.absoluteString }
    }

    var body: some View {
        VStack(spacing: 0) {
            addressBar
            progressLine
            if let pageURL = browser.requestedURL {
                RecipeWebView(url: pageURL, model: browser)
                    .overlay(alignment: .bottom) { importOffer }
                    .animation(.appSpring, value: offer)
                navigationBar
            } else {
                startScreen
            }
        }
        .onAppear { queryFocused = isEditing }
        .onChange(of: offer) { _, new in
            if new == .recipeFound { HapticManager.shared.success() }
        }
        .sheetDismissButton("Done", placement: .cancellationAction)
        .sheetScaffold("Search the Web")
        .sheet(item: $importTarget) { target in
            RecipeImportView(initialURL: target.url.absoluteString, existingNames: existingNames) { recipe in
                onImport(recipe)
                dismiss()
            }
        }
    }

    // MARK: - Address bar

    /// Safari-style: the site name while browsing, a search field once tapped.
    @ViewBuilder
    private var addressBar: some View {
        HStack(spacing: AppTheme.spacing8) {
            if isEditing || browser.requestedURL == nil {
                Image(systemName: "magnifyingglass")
                    .adaptiveSecondaryForeground()
                    .accessibilityHidden(true)
                TextField("Search \(engine.displayName) for a recipe", text: $query)
                    .textFieldStyle(.plain)
                    .submitLabel(.search)
                    .focused($queryFocused)
                    .onSubmit { search(query) }
                    .accessibilityIdentifier("webSearch.query")
                if browser.requestedURL != nil {
                    Button("Cancel") {
                        isEditing = false
                        queryFocused = false
                    }
                    .font(.subheadline)
                }
            } else {
                Button {
                    isEditing = true
                    queryFocused = true
                } label: {
                    HStack(spacing: AppTheme.spacing6) {
                        Image(systemName: "lock.fill")
                            .font(.caption2)
                            .accessibilityHidden(true)
                        Text(WebSearchBrowsing.siteName(for: browser.currentURL ?? browser.requestedURL))
                            .font(.subheadline.weight(.medium))
                            .lineLimit(1)
                    }
                    .adaptiveForegroundColor()
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Search again")
                .accessibilityIdentifier("webSearch.address")
            }
        }
        .padding(.horizontal, AppTheme.spacing12)
        .frame(minHeight: AppTheme.height44)
        .background(.ultraThinMaterial, in: Capsule())
        .padding(.horizontal, AppTheme.spacing16)
        .padding(.vertical, AppTheme.spacing8)
    }

    /// A thin line under the address bar instead of a spinner over the page.
    private var progressLine: some View {
        GeometryReader { proxy in
            Capsule()
                .fill(AppTheme.accentColor)
                .frame(width: proxy.size.width * browser.progress)
                .opacity(browser.isLoading ? 1 : 0)
                .animation(.easeOut(duration: 0.2), value: browser.progress)
        }
        .frame(height: 2)
        .accessibilityHidden(true)
    }

    // MARK: - Start screen

    private var startScreen: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AppTheme.spacing20) {
                if !recent.isEmpty {
                    chipSection("Recent", items: recent, icon: "clock.arrow.circlepath")
                }
                chipSection("Ideas", items: WebSearchBrowsing.suggestions, icon: "sparkles")
                Text("Searches use \(engine.displayName) — change it in Settings → Recipe Search. Pages load straight from each site; nothing is kept after you close this.")
                    .font(.footnote)
                    .adaptiveSecondaryForeground()
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(AppTheme.spacing20)
        }
    }

    private func chipSection(_ title: String, items: [String], icon: String) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.spacing8) {
            Label(title, systemImage: icon)
                .font(.subheadline.weight(.semibold))
                .adaptiveSecondaryForeground()
            FlowLayout(spacing: AppTheme.spacing8) {
                ForEach(items, id: \.self) { item in
                    Button(item) {
                        query = item
                        search(item)
                    }
                    .font(.subheadline)
                    .buttonStyle(.bordered)
                    .buttonBorderShape(.capsule)
                }
            }
        }
    }

    // MARK: - Import offer and navigation

    @ViewBuilder
    private var importOffer: some View {
        switch offer {
        case .hidden:
            EmptyView()
        case .recipeFound:
            Button(action: importCurrentPage) {
                Label("Import this recipe", systemImage: "checkmark.seal.fill")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, AppTheme.spacing20)
                    .frame(minHeight: AppTheme.height44)
                    .background(Capsule().fill(Color.green.gradient))
                    .shadow(color: .black.opacity(0.2), radius: 8, y: 4)
            }
            .buttonStyle(.plain)
            .padding(.bottom, AppTheme.spacing16)
            .transition(.move(edge: .bottom).combined(with: .opacity))
            .accessibilityIdentifier("webSearch.import")
        case .tryAnyway:
            Button("Try importing this page", action: importCurrentPage)
                .font(.footnote.weight(.medium))
                .adaptiveForegroundColor()
                .padding(.horizontal, AppTheme.spacing12)
                .padding(.vertical, AppTheme.spacing6)
                .background(.ultraThinMaterial, in: Capsule())
                .padding(.bottom, AppTheme.spacing12)
                .transition(.opacity)
                .accessibilityIdentifier("webSearch.tryImport")
        }
    }

    private var navigationBar: some View {
        HStack {
            navButton("chevron.backward", label: "Back", enabled: browser.canGoBack) { browser.webView?.goBack() }
            Spacer()
            navButton("chevron.forward", label: "Forward", enabled: browser.canGoForward) { browser.webView?.goForward() }
            Spacer()
            navButton(browser.isLoading ? "xmark" : "arrow.clockwise", label: browser.isLoading ? "Stop" : "Reload",
                      enabled: true) {
                if browser.isLoading { browser.webView?.stopLoading() } else { browser.webView?.reload() }
            }
        }
        .padding(.horizontal, AppTheme.spacing32)
        .frame(height: AppTheme.height44)
        .background(.ultraThinMaterial)
    }

    private func navButton(_ icon: String, label: String, enabled: Bool,
                           action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.body.weight(.medium))
                .frame(width: AppTheme.height44, height: AppTheme.height44)
        }
        .disabled(!enabled)
        .accessibilityLabel(label)
    }

    private func importCurrentPage() {
        guard let url = browser.currentURL else { return }
        HapticManager.shared.light()
        importTarget = ImportTarget(url: url)
    }

    private func search(_ text: String) {
        guard let url = engine.searchURL(for: text) else { return }
        recentRaw = RecentWebSearches.encode(RecentWebSearches.adding(text, to: recent))
        queryFocused = false
        isEditing = false
        browser.open(url)
    }
}

/// The browser's live state, shared between the SwiftUI chrome and the web view's delegate.
@MainActor
@Observable
final class WebBrowserModel {
    /// The page SwiftUI asked for (a new search); in-page navigation updates `currentURL` instead.
    private(set) var requestedURL: URL?
    var currentURL: URL?
    var isLoading = false
    var progress: Double = 0
    var canGoBack = false
    var canGoForward = false
    var recipeDetected = false
    @ObservationIgnored weak var webView: WKWebView?

    func open(_ url: URL) {
        recipeDetected = false
        requestedURL = url
    }
}

/// `WKWebView` (not `SFSafariViewController`, which can't report the page back) with a non-persistent data store.
private struct RecipeWebView: UIViewRepresentable {
    let url: URL
    let model: WebBrowserModel

    func makeCoordinator() -> Coordinator { Coordinator(model: model, requestedURL: url) }

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.websiteDataStore = .nonPersistent()
        let view = WKWebView(frame: .zero, configuration: config)
        view.navigationDelegate = context.coordinator
        view.allowsBackForwardNavigationGestures = true
        context.coordinator.observe(view)
        model.webView = view
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
        let model: WebBrowserModel
        var requestedURL: URL?
        private var observations: [NSKeyValueObservation] = []

        init(model: WebBrowserModel, requestedURL: URL) {
            self.model = model
            self.requestedURL = requestedURL
        }

        func observe(_ view: WKWebView) {
            // KVO fires on the main thread for WKWebView; read the state back from the view we own.
            func watch<Value>(_ keyPath: KeyPath<WKWebView, Value>) -> NSKeyValueObservation {
                view.observe(keyPath) { [weak self] _, _ in
                    MainActor.assumeIsolated { self?.sync() }
                }
            }
            observations = [watch(\.estimatedProgress), watch(\.isLoading), watch(\.canGoBack),
                            watch(\.canGoForward), watch(\.url)]
        }

        private func sync() {
            guard let view = model.webView else { return }
            model.progress = view.estimatedProgress
            model.isLoading = view.isLoading
            model.canGoBack = view.canGoBack
            model.canGoForward = view.canGoForward
            model.currentURL = view.url
        }

        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            model.recipeDetected = false
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            let pageURL = webView.url
            Task { @MainActor in
                // A page we can't read just shows the quiet try-anyway link — importing still works on its URL.
                guard let html = (try? await webView.evaluateJavaScript("document.documentElement.outerHTML")) as? String
                else { return }
                // Parsing a large page is real work: keep it off the main actor.
                let found = await Task.detached { WebSearchBrowsing.looksLikeRecipe(html: html) }.value
                // Ignore a late answer for a page the cook has already left.
                if webView.url == pageURL { model.recipeDetected = found }
            }
        }
    }
}
