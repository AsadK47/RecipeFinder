import SwiftUI
import Kingfisher

/// Context handed to `FullScreenPhotoViewer`. Being `Identifiable` lets call sites
/// drive presentation with `.fullScreenCover(item:)` and open at the exact photo
/// the user tapped, without threading a separate `isPresented` + index pair.
struct PhotoViewerSource: Identifiable {
    let id = UUID()
    let imageNames: [String]
    let recipeName: String?
    let startIndex: Int
}

/// Full-screen, Photos-app-style viewer: swipe between a recipe's images, pinch or
/// double-tap to zoom, pan a zoomed photo, and swipe-down or tap to dismiss. Reused
/// by both the detail hero gallery and the photo-manager grid so tapping a photo
/// behaves identically everywhere.
struct FullScreenPhotoViewer: View {
    let source: PhotoViewerSource

    @State private var selection: Int
    @Environment(\.dismiss) private var dismiss

    init(source: PhotoViewerSource) {
        self.source = source
        // Clamp so an out-of-range start (e.g. a since-deleted photo) can't crash paging.
        let safeStart = min(max(source.startIndex, 0), max(source.imageNames.count - 1, 0))
        _selection = State(initialValue: safeStart)
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Color.black.ignoresSafeArea()

            TabView(selection: $selection) {
                ForEach(Array(source.imageNames.enumerated()), id: \.offset) { index, name in
                    ZoomablePhoto(imageName: name, recipeName: source.recipeName) { dismiss() }
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: source.imageNames.count > 1 ? .automatic : .never))

            closeButton
        }
        .statusBarHidden()
    }

    private var closeButton: some View {
        Button { dismiss() } label: {
            Image(systemName: "xmark")
                .font(.headline.weight(.semibold))
                .foregroundStyle(.white)
                .padding(AppTheme.spacing12)
                .background(.black.opacity(0.4), in: Circle())
        }
        .padding(AppTheme.spacing16)
        .accessibilityLabel("Close photo")
    }
}

/// A single zoomable, pannable photo. At 1× a downward drag dismisses; once zoomed
/// the same drag pans the image instead. A double-tap toggles between fit and 2.5×.
private struct ZoomablePhoto: View {
    let imageName: String
    let recipeName: String?
    let onDismiss: () -> Void

    @State private var scale: CGFloat = 1
    @State private var lastScale: CGFloat = 1
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    @State private var dragDismiss: CGFloat = 0

    private let maxScale: CGFloat = 4
    private let doubleTapScale: CGFloat = 2.5
    private let dismissThreshold: CGFloat = 120

    var body: some View {
        imageContent
            .scaledToFit()
            .scaleEffect(scale)
            .offset(x: offset.width, y: offset.height + dragDismiss)
            // Backdrop fades as the photo is dragged away, echoing the system viewer.
            .opacity(scale > 1 ? 1 : 1 - min(abs(dragDismiss) / (dismissThreshold * 3), 0.6))
            .gesture(magnification)
            .simultaneousGesture(drag)
            .onTapGesture(count: 2) { toggleZoom() }
            .onTapGesture { if scale <= 1 { onDismiss() } }
    }

    @ViewBuilder
    private var imageContent: some View {
        if let source = RecipeImageView.resolvedSource(for: imageName) {
            // No downsampling here (unlike the thumbnail path) so zoom stays sharp.
            KFImage(source: source)
                .placeholder { ProgressView().tint(.white) }
                .cacheOriginalImage()
                .resizable()
        } else if let uiImage = UIImage(named: imageName) {
            Image(uiImage: uiImage)
                .resizable()
        } else {
            // Callers filter to displayable images; this is a defensive fallback.
            Color.black
        }
    }

    private var magnification: some Gesture {
        MagnificationGesture()
            .onChanged { value in
                scale = min(max(lastScale * value, 1), maxScale)
            }
            .onEnded { _ in
                if scale <= 1 {
                    withAnimation(.spring(response: 0.3)) { resetZoom() }
                } else {
                    lastScale = scale
                }
            }
    }

    private var drag: some Gesture {
        DragGesture()
            .onChanged { value in
                if scale > 1 {
                    offset = CGSize(width: lastOffset.width + value.translation.width,
                                    height: lastOffset.height + value.translation.height)
                } else {
                    // Only vertical drag counts as dismiss so horizontal swipes still page.
                    dragDismiss = value.translation.height
                }
            }
            .onEnded { value in
                if scale > 1 {
                    lastOffset = offset
                } else if abs(value.translation.height) > dismissThreshold {
                    onDismiss()
                } else {
                    withAnimation(.spring(response: 0.3)) { dragDismiss = 0 }
                }
            }
    }

    private func toggleZoom() {
        withAnimation(.spring(response: 0.3)) {
            if scale > 1 {
                resetZoom()
            } else {
                scale = doubleTapScale
                lastScale = doubleTapScale
            }
        }
    }

    private func resetZoom() {
        scale = 1
        lastScale = 1
        offset = .zero
        lastOffset = .zero
    }
}
