import Kingfisher
import SwiftUI
import UIKit

/// Shares one My Cookbook page as a picture: the dish, its name, when it was made and its stars, with the app's name
/// small at the foot. The card is drawn once when the sheet opens, so the preview is exactly what gets sent.
struct CookbookShareSheet: View {
    let page: CookbookPage

    @State private var card: UIImage?
    @State private var renderFailed = false

    private static let logger = AppLogger.logger(category: "CookbookShare")

    var body: some View {
        VStack(spacing: AppTheme.spacing20) {
            if let card {
                Image(uiImage: card)
                    .resizable()
                    .scaledToFit()
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius16, style: .continuous))
                    .shadow(color: .black.opacity(0.25), radius: 12, y: 6)
                    .frame(maxHeight: .infinity)
                    .accessibilityLabel("\(page.name), \(page.line)")
                    .accessibilityIdentifier("cookbook.share.preview")
                ShareLink(
                    item: Image(uiImage: card),
                    message: Text(MyCookbook.shareCaption(for: page)),
                    preview: SharePreview(page.name, image: Image(uiImage: card))
                ) {
                    Label("Share", systemImage: "square.and.arrow.up")
                        .font(.subheadline.weight(.semibold))
                        .adaptiveForegroundColor()
                        .padding(.horizontal, AppTheme.spacing20)
                        .padding(.vertical, AppTheme.spacing12)
                        .background(Capsule().fill(AppTheme.accentColor))
                }
                .accessibilityIdentifier("cookbook.share.send")
            } else if renderFailed {
                Spacer()
                Text("This page couldn't be turned into a picture. Close and try again.")
                    .font(.subheadline)
                    .adaptiveSecondaryForeground()
                    .multilineTextAlignment(.center)
                Spacer()
            } else {
                Spacer()
                ProgressView()
                Spacer()
            }
        }
        .padding(AppTheme.spacing20)
        .task { await renderCard() }
        .sheetDismissButton()
        .sheetScaffold("Share page")
    }

    private func renderCard() async {
        let picture = await Self.picture(for: page.imageName)
        let renderer = ImageRenderer(content: CookbookShareCard(page: page, picture: picture))
        renderer.scale = MyCookbook.shareCardScale
        renderer.proposedSize = ProposedViewSize(MyCookbook.shareCardSize)
        if let image = renderer.uiImage {
            card = image
        } else {
            Self.logger.error("Couldn't render the cookbook share card")
            renderFailed = true
        }
    }

    /// The page's picture as a bitmap (photo, kept web copy, built-in art or asset); nil → the card draws the
    /// recipe's illustrated placeholder, as the page itself does.
    private static func picture(for imageName: String?) async -> UIImage? {
        if let source = RecipeImageView.resolvedSource(for: imageName) {
            let longSide = max(MyCookbook.shareCardSize.width, MyCookbook.shareCardSize.height)
                * MyCookbook.shareCardScale
            do {
                return try await KingfisherManager.shared.retrieveImage(
                    with: source,
                    options: [.processor(DownsamplingImageProcessor(size: CGSize(width: longSide, height: longSide)))]
                ).image
            } catch {
                logger.info("Cookbook share card uses the placeholder: \(error.localizedDescription)")
                return nil
            }
        }
        guard let imageName, !imageName.isEmpty else { return nil }
        return UIImage(named: imageName)
    }
}

/// The picture that gets shared. Fixed sizes rather than Dynamic Type: it's an image for other people's screens.
struct CookbookShareCard: View {
    let page: CookbookPage
    let picture: UIImage?

    var body: some View {
        let size = MyCookbook.shareCardSize
        ZStack(alignment: .bottomLeading) {
            Group {
                if let picture {
                    Image(uiImage: picture)
                        .resizable()
                        .scaledToFill()
                } else {
                    RecipePlaceholderView(recipeName: page.name, category: page.category, cuisine: page.cuisine)
                }
            }
            .frame(width: size.width, height: size.height)
            .clipped()

            VStack(alignment: .leading, spacing: AppTheme.spacing6) {
                Text(page.name)
                    .font(.system(size: 28, weight: .bold))
                    .lineLimit(3)
                    .minimumScaleFactor(0.7)
                Text(page.line)
                    .font(.system(size: 16, weight: .medium))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                if let stars = MyCookbook.starText(rating: page.rating) {
                    Text(stars)
                        .font(.system(size: 18))
                }
                Label("My Cookbook · RecipeFinder", systemImage: "book.closed.fill")
                    .font(.system(size: 12, weight: .semibold))
                    .opacity(0.85)
                    .padding(.top, AppTheme.spacing8)
            }
            .foregroundStyle(.white)
            .padding(AppTheme.spacing24)
            .frame(width: size.width, alignment: .leading)
            // Dark under every line, so a pale dish or light art never washes the name out.
            .background(
                LinearGradient(colors: [.black.opacity(0), .black.opacity(0.55), .black.opacity(0.8)],
                               startPoint: .top, endPoint: .bottom)
            )
        }
        .frame(width: size.width, height: size.height)
    }
}
