import UIKit
import UniformTypeIdentifiers

/// Receives a URL (or text containing one) from the share sheet, stashes it
/// in the shared App Group, and dismisses. The main app consumes the payload
/// on next foreground and routes it into the recipe import flow.
///
/// Deliberately dumb: no parsing, no networking, no app singletons — those
/// all assume the main app's process and storage.
final class ShareViewController: UIViewController {

    private enum Inbox {
        static let appGroupID = "group.com.asadkhan.recipefinder"
        static let urlKey = "pendingSharedImportURL"
        static let textKey = "pendingSharedImportText"
    }

    private let card = UIView()
    private let label = UILabel()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.35)
        configureCard()
        extractAndStoreSharedContent()
    }

    private func configureCard() {
        card.backgroundColor = .secondarySystemBackground
        card.layer.cornerRadius = 16
        card.layer.cornerCurve = .continuous
        card.translatesAutoresizingMaskIntoConstraints = false
        card.alpha = 0
        view.addSubview(card)

        let checkmark = UIImageView(image: UIImage(systemName: "checkmark.circle.fill"))
        checkmark.tintColor = .systemGreen
        checkmark.contentMode = .scaleAspectFit
        checkmark.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(checkmark)

        label.text = "Saved — open RecipeFinder to import"
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

            label.topAnchor.constraint(equalTo: checkmark.bottomAnchor, constant: 12),
            label.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 20),
            label.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -20),
            label.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -24)
        ])
    }

    private func extractAndStoreSharedContent() {
        guard let item = extensionContext?.inputItems.first as? NSExtensionItem,
              let attachments = item.attachments, !attachments.isEmpty else {
            finish(succeeded: false)
            return
        }

        if let urlProvider = attachments.first(where: { $0.hasItemConformingToTypeIdentifier(UTType.url.identifier) }) {
            urlProvider.loadItem(forTypeIdentifier: UTType.url.identifier, options: nil) { [weak self] loaded, _ in
                let url = loaded as? URL
                DispatchQueue.main.async {
                    self?.store(urlString: url?.absoluteString, text: nil)
                }
            }
            return
        }

        if let textProvider = attachments.first(where: { $0.hasItemConformingToTypeIdentifier(UTType.plainText.identifier) }) {
            textProvider.loadItem(forTypeIdentifier: UTType.plainText.identifier, options: nil) { [weak self] loaded, _ in
                let text = loaded as? String
                DispatchQueue.main.async {
                    self?.store(urlString: nil, text: text)
                }
            }
            return
        }

        finish(succeeded: false)
    }

    private func store(urlString: String?, text: String?) {
        guard urlString != nil || text != nil,
              let defaults = UserDefaults(suiteName: Inbox.appGroupID) else {
            finish(succeeded: false)
            return
        }

        defaults.set(urlString, forKey: Inbox.urlKey)
        defaults.set(text, forKey: Inbox.textKey)
        finish(succeeded: true)
    }

    private func finish(succeeded: Bool) {
        if !succeeded {
            label.text = "Couldn't read the shared content"
        }

        UIView.animate(withDuration: 0.25) {
            self.card.alpha = 1
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.1) {
            self.extensionContext?.completeRequest(returningItems: nil)
        }
    }
}
