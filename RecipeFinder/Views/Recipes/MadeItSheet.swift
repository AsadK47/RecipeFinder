import PhotosUI
import SwiftUI
import UIKit

/// Snapshot of a just-logged cook for the "Made it" sheet. Identifiable so it drives `.sheet(item:)`.
struct MadeItSummary: Identifiable, Equatable {
    let id = UUID()
    /// Total cooks across the library, including this one.
    let cookNumber: Int
    let streakWeeks: Int
    let rating: Int
    let milestone: CookingMilestoneProgress?
}

/// The one post-cook moment: cook number, streak, rating, optional dish photo and next-badge progress.
/// The caller persists the rating and photo; the sheet stays open after either so both can be done.
struct MadeItSheet: View {
    let summary: MadeItSummary
    let onRate: (Int) -> Void
    let onPhotoSelected: (UIImage) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var rating: Int
    @State private var selectedItem: PhotosPickerItem?
    @State private var showPhotoPicker = false
    @State private var showCamera = false
    @State private var photoAdded = false
    @State private var loadError: String?

    init(summary: MadeItSummary, onRate: @escaping (Int) -> Void, onPhotoSelected: @escaping (UIImage) -> Void) {
        self.summary = summary
        self.onRate = onRate
        self.onPhotoSelected = onPhotoSelected
        _rating = State(initialValue: summary.rating)
    }

    var body: some View {
        ZStack {
            AppBackground()

            ScrollView {
                VStack(spacing: AppTheme.spacing20) {
                    header
                    statsCard
                    photoSection
                }
                .padding(.horizontal, AppTheme.spacing24)
                .padding(.top, AppTheme.spacing32)
                .padding(.bottom, AppTheme.spacing24)
            }
            // Pinned, not in the scroll content: at the medium detent the content runs past the fold, and a Done
            // you have to scroll to find (UI tests couldn't reach it either) traps the user in the sheet.
            .safeAreaInset(edge: .bottom) {
                PrimaryButton("Done", systemImage: "checkmark", fillWidth: true) { dismiss() }
                    .accessibilityIdentifier("madeIt.done")
                    .padding(.horizontal, AppTheme.spacing24)
                    .padding(.vertical, AppTheme.spacing12)
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
        .photosPicker(isPresented: $showPhotoPicker, selection: $selectedItem, matching: .images)
        .fullScreenCover(isPresented: $showCamera) {
            CameraPicker { image in
                addPhoto(image)
            }
        }
        .onChange(of: selectedItem) { _, newItem in
            guard let newItem else { return }
            Task {
                if let data = try? await newItem.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    addPhoto(image)
                } else {
                    // Don't fail silently — tell the user the photo didn't load.
                    loadError = "That photo couldn't be loaded. Please try another."
                }
                selectedItem = nil
            }
        }
        .errorAlert("Couldn't load photo", message: $loadError)
    }

    private func addPhoto(_ image: UIImage) {
        onPhotoSelected(image)
        photoAdded = true
    }

    private var header: some View {
        VStack(spacing: AppTheme.spacing8) {
            IconBadge(systemName: "checkmark", tint: .green, diameter: 72, iconSize: 30, weight: .bold)
            Text("Cook #\(summary.cookNumber)")
                .font(.title.bold())
                .adaptiveForegroundColor()
                .accessibilityIdentifier("madeIt.cookNumber")
            Text("Nice cooking!")
                .font(.subheadline)
                .adaptiveSecondaryForeground()
        }
        .accessibilityElement(children: .combine)
    }

    private var statsCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacing12) {
            if summary.streakWeeks > 0 {
                HStack(spacing: AppTheme.spacing8) {
                    Image(systemName: "flame.fill")
                        .foregroundStyle(.orange)
                        .accessibilityHidden(true)
                    Text(summary.streakWeeks == 1 ? "1-week cooking streak" : "\(summary.streakWeeks)-week cooking streak")
                        .font(.subheadline.weight(.semibold))
                        .adaptiveForegroundColor()
                }
                Divider()
            }

            HStack {
                Text("How was it?")
                    .font(.subheadline)
                    .adaptiveSecondaryForeground()
                Spacer()
                StarRatingView(rating: rating) { newRating in
                    rating = newRating
                    onRate(newRating)
                }
                .accessibilityIdentifier("madeIt.rating")
            }

            if let milestone = summary.milestone {
                Divider()
                HStack(spacing: AppTheme.spacing8) {
                    Image(systemName: milestone.badge.badge.icon)
                        .foregroundStyle(Badge.color(for: milestone.badge.badge.color))
                        .accessibilityHidden(true)
                    Text(milestone.text)
                        .font(.subheadline)
                        .adaptiveForegroundColor()
                }
                .accessibilityIdentifier("madeIt.milestone")
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .appCard(elevated: true)
    }

    @ViewBuilder
    private var photoSection: some View {
        if photoAdded {
            Label("Photo added", systemImage: "checkmark.circle.fill")
                .font(.subheadline.weight(.semibold))
                .adaptiveForegroundColor()
        } else {
            HStack(spacing: AppTheme.spacing8) {
                PrimaryButton("Add photo", systemImage: "photo.on.rectangle", fillWidth: true, variant: .secondary) {
                    showPhotoPicker = true
                }
                if UIImagePickerController.isSourceTypeAvailable(.camera) {
                    PrimaryButton("Take photo", systemImage: "camera", fillWidth: true, variant: .secondary) {
                        showCamera = true
                    }
                }
            }
            .lineLimit(1)
            .minimumScaleFactor(0.8)
        }
    }
}

/// The Made it sheet's shared state. The recipe screen that logged the cook presents it (always the topmost
/// screen, so it also works inside the Collections sheet); the app root reads `isBusy` so a badge celebration from the
/// same cook waits until the sheet has fully closed — two sheets presenting at once showed neither.
@MainActor
protocol MadeItPresenting: AnyObject {
    var request: MadeItPresenter.Request? { get }
    var isBusy: Bool { get }
    func request(for recipeId: UUID) -> MadeItPresenter.Request?
    func present(_ request: MadeItPresenter.Request)
    func hold(_ request: MadeItPresenter.Request)
    func presentHeld()
    func dismiss()
    func didDismiss()
}

@MainActor @Observable
final class MadeItPresenter: MadeItPresenting {
    static let shared = MadeItPresenter()

    struct Request: Identifiable {
        let recipeId: UUID
        let summary: MadeItSummary
        let onRate: (Int) -> Void
        let onPhotoSelected: (UIImage) -> Void
        var id: UUID { summary.id }
    }

    /// The sheet on screen.
    private(set) var request: Request?
    /// Parked while cooking mode's full-screen cover is still up — a sheet can't present over a dismissing cover.
    private(set) var held: Request?
    /// Closed but still animating out; presenting the badge sheet now would be dropped.
    private(set) var isDismissing = false

    /// True while a Made it sheet is showing, waiting to show, or still closing.
    var isBusy: Bool { request != nil || held != nil || isDismissing }

    func request(for recipeId: UUID) -> Request? {
        request?.recipeId == recipeId ? request : nil
    }

    func present(_ request: Request) { self.request = request }

    func hold(_ request: Request) { held = request }

    func presentHeld() {
        guard let held else { return }
        self.held = nil
        request = held
    }

    func dismiss() {
        guard request != nil else { return }
        request = nil
        isDismissing = true
    }

    func didDismiss() { isDismissing = false }
}

private struct MadeItPresenterKey: EnvironmentKey {
    // SwiftUI reads environment defaults on the main actor; the app shares one presenter.
    static var defaultValue: any MadeItPresenting {
        MainActor.assumeIsolated { MadeItPresenter.shared }
    }
}

extension EnvironmentValues {
    var madeItPresenter: any MadeItPresenting {
        get { self[MadeItPresenterKey.self] }
        set { self[MadeItPresenterKey.self] = newValue }
    }
}
