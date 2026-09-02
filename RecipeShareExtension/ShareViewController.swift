import UIKit
import UniformTypeIdentifiers

/// Receives a URL (or text) from the share sheet and tries to complete the
/// import right here — fetching and parsing the page so the recipe is simply
/// there next time the app opens. On success it stashes the parsed
/// `ExtractedRecipeData` in the shared App Group via `SharedImportInbox`; when
/// the import can't finish (no network, unparseable page, plain-text share) it
/// falls back to storing the raw URL/text for the app to handle interactively.
final class ShareViewController: UIViewController {

    private let card = UIView()
    private let label = UILabel()
    private let spinner = UIActivityIndicatorView(style: .medium)
    private let checkmark = UIImageView(image: UIImage(systemName: "checkmark.circle.fill"))

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.35)
        configureCard()
        handleSharedContent()
    }

    private func configureCard() {
        card.backgroundColor = .secondarySystemBackground
        card.layer.cornerRadius = 16
        card.layer.cornerCurve = .continuous
        card.translatesAutoresizingMaskIntoConstraints = false
        card.alpha = 0
        view.addSubview(card)

        checkmark.tintColor = .systemGreen
        checkmark.contentMode = .scaleAspectFit
        checkmark.isHidden = true
        checkmark.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(checkmark)

        spinner.startAnimating()
        spinner.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(spinner)

        label.text = "Importing…"
        label.font = .preferredFont(forTextStyle: .subheadline)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = .label
        label.numberOfLines = 0
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(label)

        NSLayoutConstraint.activate([
            card.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            card.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            card.widthAnchor.constraint(lessThanOrEqualTo: view.widthAnchor, constant: -64),
            card.widthAnchor.constraint(greaterThanOrEqualToConstant: 220),

            checkmark.topAnchor.constraint(equalTo: card.topAnchor, constant: 24),
            checkmark.centerXAnchor.constraint(equalTo: card.centerXAnchor),
            checkmark.widthAnchor.constraint(equalToConstant: 44),
            checkmark.heightAnchor.constraint(equalToConstant: 44),

            spinner.centerXAnchor.constraint(equalTo: checkmark.centerXAnchor),
            spinner.centerYAnchor.constraint(equalTo: checkmark.centerYAnchor),

            label.topAnchor.constraint(equalTo: checkmark.bottomAnchor, constant: 12),
            label.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 20),
            label.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -20),
            label.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -24)
        ])

        UIView.animate(withDuration: 0.2) { self.card.alpha = 1 }
    }

    private func handleSharedContent() {
        guard let item = extensionContext?.inputItems.first as? NSExtensionItem,
              let attachments = item.attachments, !attachments.isEmpty else {
            finish(message: "Couldn't read the shared content")
            return
        }

        if let urlProvider = attachments.first(where: { $0.hasItemConformingToTypeIdentifier(UTType.url.identifier) }) {
            urlProvider.loadItem(forTypeIdentifier: UTType.url.identifier, options: nil) { [weak self] loaded, _ in
                let url = loaded as? URL
                DispatchQueue.main.async { self?.handle(url: url) }
            }
            return
        }

        if let textProvider = attachments.first(where: { $0.hasItemConformingToTypeIdentifier(UTType.plainText.identifier) }) {
            textProvider.loadItem(forTypeIdentifier: UTType.plainText.identifier, options: nil) { [weak self] loaded, _ in
                let text = loaded as? String
                DispatchQueue.main.async { self?.handle(text: text) }
            }
            return
        }

        finish(message: "Couldn't read the shared content")
    }

    private func handle(url: URL?) {
        guard let url else {
            finish(message: "Couldn't read the shared content")
            return
        }
        importInExtension(from: url, rawURLFallback: url.absoluteString)
    }

    private func handle(text: String?) {
        guard let text, !text.isEmpty else {
            finish(message: "Couldn't read the shared content")
            return
        }

        // A caption with an embedded recipe link can still be fetched here;
        // otherwise hand the raw text to the app's text parser.
        if let link = firstURL(in: text), let url = URL(string: link) {
            importInExtension(from: url, rawURLFallback: link)
        } else {
            SharedImportInbox.storeText(text)
            finish(message: "Saved — open RecipeFinder to import")
        }
    }

    /// Fetches + parses the page off the main actor. On success stores the parsed
    /// recipe; on any failure stores the raw URL so the app can import it
    /// interactively — the share never fails outright.
    private func importInExtension(from url: URL, rawURLFallback: String) {
        Task { @MainActor in
            do {
                let outcome = try await RecipeImportPipeline().fetchAndParse(from: url)
                if SharedImportInbox.storeExtractedRecipe(outcome.data) {
                    finish(message: "Recipe saved to RecipeFinder")
                } else {
                    SharedImportInbox.storeURL(rawURLFallback)
                    finish(message: "Saved — open RecipeFinder to import")
                }
            } catch {
                SharedImportInbox.storeURL(rawURLFallback)
                finish(message: "Saved — open RecipeFinder to import")
            }
        }
    }

    private func firstURL(in text: String) -> String? {
        guard let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue) else {
            return nil
        }
        let range = NSRange(text.startIndex..., in: text)
        return detector.firstMatch(in: text, options: [], range: range)?.url?.absoluteString
    }

    private func finish(message: String) {
        spinner.stopAnimating()
        spinner.isHidden = true
        checkmark.isHidden = false
        label.text = message

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.1) {
            self.extensionContext?.completeRequest(returningItems: nil)
        }
    }
}
