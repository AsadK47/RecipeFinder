import CoreTransferable
import Kingfisher
import SwiftUI
import UIKit
import UniformTypeIdentifiers

/// Shares one My Cookbook page as a picture: the dish, its name, when it was made and its stars, with the app's name
/// small at the foot. The card is drawn once when the sheet opens, so the preview is exactly what gets sent.
struct CookbookShareSheet: View {
    let page: CookbookPage

    @State private var card: UIImage?
    @State private var shared: CookbookShareImage?
    @State private var renderFailed = false
    @State private var caption = ""

    fileprivate static let logger = AppLogger.logger(category: "CookbookShare")

    var body: some View {
        VStack(spacing: AppTheme.spacing20) {
            if let card, let shared {
                Image(uiImage: card)
                    .resizable()
                    .scaledToFit()
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius16, style: .continuous))
                    .shadow(color: .black.opacity(0.25), radius: 12, y: 6)
                    .frame(maxHeight: .infinity)
                    .accessibilityLabel("\(page.name), \(page.line)")
                    .accessibilityIdentifier("cookbook.share.preview")
                ShareLink(
                    item: shared,
                    message: Text(caption),
                    preview: SharePreview(page.name, image: Image(uiImage: card))
                ) {
                    Label("Share", systemImage: "square.and.arrow.up")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(AppTheme.onAccent)
                        .padding(.horizontal, AppTheme.spacing20)
                        .padding(.vertical, AppTheme.spacing12)
                        .background(Capsule().fill(AppTheme.accentColor))
                }
                .accessibilityIdentifier("cookbook.share.send")
            } else if renderFailed {
                Spacer()
                Text("This page couldn't be turned into a picture this time.")
                    .font(.subheadline)
                    .adaptiveSecondaryForeground()
                    .multilineTextAlignment(.center)
                PrimaryButton("Try again", systemImage: "arrow.clockwise") {
                    renderFailed = false
                    Task { await renderCard() }
                }
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
        let picture = await CookbookShareCard.picture(for: page.imageName)
        let now = Date()
        caption = MyCookbook.shareCaption(for: page, now: now)
        if let image = CookbookShareCard.render(page: page, picture: picture, now: now),
           let jpeg = image.jpegData(compressionQuality: 0.9) {
            card = image
            shared = CookbookShareImage(jpeg: jpeg)
        } else {
            Self.logger.error("Couldn't render the cookbook share card")
            renderFailed = true
        }
    }
}

/// The picture that gets shared. Fixed sizes rather than Dynamic Type: it's an image for other people's screens.
struct CookbookShareCard: View {
    /// Points; at `scale` it's 1080 × 1350 px, a 4:5 portrait that fills a feed post or a message without cropping.
    static let size = CGSize(width: 360, height: 450)
    static let scale: CGFloat = 3

    let page: CookbookPage
    let picture: UIImage?
    /// "Made 3 times · 16 Nov", worked out once by the caller so the card and its caption agree.
    let line: String

    /// Draws the card as a bitmap; nil if the renderer couldn't.
    @MainActor
    static func render(page: CookbookPage, picture: UIImage?, now: Date = Date()) -> UIImage? {
        let card = CookbookShareCard(page: page, picture: picture, line: MyCookbook.shareLine(for: page, now: now))
        // Twice at most: on a stalled simulator the renderer twice handed back a bitmap with nothing drawn (corner
        // alpha 0, CI runs 45101329693 and 45135500689). Nil → the sheet's "Try again", never a blank card.
        for attempt in 1...2 {
            let renderer = ImageRenderer(content: card)
            renderer.scale = scale
            renderer.proposedSize = ProposedViewSize(size)
            if let image = renderer.uiImage, isDrawn(image) { return image }
            CookbookShareSheet.logger.info("Cookbook share card came back undrawn (attempt \(attempt))")
        }
        return nil
    }

    /// The card's black background makes every drawn card solid, so a see-through corner means nothing was drawn.
    static func isDrawn(_ image: UIImage) -> Bool {
        guard let cgImage = image.cgImage else { return false }
        var rgba = [UInt8](repeating: 0, count: 4)
        let read: Bool = rgba.withUnsafeMutableBytes { buffer in
            guard let context = CGContext(data: buffer.baseAddress, width: 1, height: 1, bitsPerComponent: 8,
                                          bytesPerRow: 4, space: CGColorSpaceCreateDeviceRGB(),
                                          bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else {
                return false
            }
            // The pixel 2 in from the top-left corner (Core Graphics counts y from the bottom).
            context.draw(cgImage, in: CGRect(x: -2, y: -(cgImage.height - 3), width: cgImage.width,
                                              height: cgImage.height))
            return true
        }
        return read && rgba[3] == 255
    }

    /// The page's picture as a bitmap (photo, kept web copy, built-in art or asset); nil → the card draws the
    /// recipe's illustrated placeholder, as the page itself does.
    static func picture(for imageName: String?) async -> UIImage? {
        if let source = RecipeImageView.resolvedSource(for: imageName) {
            // Fill crops a landscape photo to the card's 4:5, so its short side must still cover 1350 px: a long-side
            // cap of 1350 left 4:3 photos 1012 px tall and soft once filled.
            let longSide = size.height * scale * 2
            do {
                return try await KingfisherManager.shared.retrieveImage(
                    with: source,
                    options: [.processor(DownsamplingImageProcessor(size: CGSize(width: longSide, height: longSide))),
                              .cacheMemoryOnly]
                ).image
            } catch {
                CookbookShareSheet.logger.info("Cookbook share card uses the placeholder: \(error.localizedDescription)")
                return nil
            }
        }
        guard let imageName, !imageName.isEmpty else { return nil }
        return UIImage(named: imageName)
    }

    var body: some View {
        let size = Self.size
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
                Text(line)
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
            .padding(.top, AppTheme.spacing24)
            .frame(width: size.width, alignment: .leading)
            // Fades in above the text and is already dark behind the name, so a pale dish never washes it out
            // (same 0.35 floor as the page on Me).
            .background(
                LinearGradient(stops: [.init(color: .black.opacity(0), location: 0),
                                       .init(color: .black.opacity(0.4), location: 0.2),
                                       .init(color: .black.opacity(0.8), location: 1)],
                               startPoint: .top, endPoint: .bottom)
            )
        }
        .frame(width: size.width, height: size.height)
        .background(Color.black)
        // The same card whatever the sender's appearance setting.
        .environment(\.colorScheme, .dark)
    }
}

/// The card as a JPEG, so what's sent is exactly 1080 × 1350 and a few hundred KB rather than whatever the system
/// makes of a SwiftUI `Image`.
struct CookbookShareImage: Transferable {
    let jpeg: Data

    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: .jpeg) { item in item.jpeg }
    }
}
