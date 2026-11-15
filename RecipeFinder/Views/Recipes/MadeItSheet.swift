import ConfettiSwiftUI
import PhotosUI
import SwiftUI
import UIKit

/// The one post-cook moment: the dish, cook number, streak, cooks this week, rating, a photo nudge and next-badge
/// progress, with its own haptic and confetti (Reduce Motion drops the movement; wording in `MadeItMoment`).
/// The caller persists the rating and photo; the sheet stays open after either so both can be done.
struct MadeItSheet: View {
    let summary: MadeItSummary
    let onRate: (Int) -> Void
    let onPhotoSelected: (UIImage) -> Void
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.accessibilityVoiceOverEnabled) private var voiceOverEnabled

    @State private var rating: Int
    @State private var selectedItem: PhotosPickerItem?
    @State private var showPhotoPicker = false
    @State private var showCamera = false
    @State private var photoAdded = false
    @State private var loadError: String?
    @State private var confettiCounter = 0
    @State private var landed = false

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
        .confettiCannon(
            trigger: $confettiCounter,
            num: AppTheme.confettiCount,
            radius: AppTheme.confettiRadius,
            // The moment plays its own haptic pattern; the cannon's would land on top of it.
            hapticFeedback: false
        )
        .task { await play() }
    }

    private var motion: MadeItMoment.Motion { MadeItMoment.motion(reduceMotion: reduceMotion) }

    /// Lands the moment once the sheet is up: the picture pops in, then haptic and confetti together.
    private func play() async {
        guard !landed else { return }
        let motion = self.motion
        if motion.popsIn {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) { landed = true }
            try? await Task.sleep(for: .milliseconds(250))
        } else {
            landed = true
        }
        guard !Task.isCancelled else { return }
        if motion.playsHaptic { HapticManager.shared.madeIt() }
        if motion.firesConfetti { confettiCounter += 1 }
        if voiceOverEnabled {
            AccessibilityNotification.Announcement(MadeItMoment.announcement(
                cookNumber: summary.cookNumber, recipeName: summary.recipeName, timesCooked: summary.timesCooked,
                streakWeeks: summary.streakWeeks, cooksThisWeek: summary.cooksThisWeek
            )).post()
        }
    }

    private func addPhoto(_ image: UIImage) {
        onPhotoSelected(image)
        photoAdded = true
    }

    private var header: some View {
        VStack(spacing: AppTheme.spacing8) {
            dishPicture
            Text("Cook #\(summary.cookNumber)")
                .font(.title.bold())
                .adaptiveForegroundColor()
                .accessibilityIdentifier("madeIt.cookNumber")
            Text(MadeItMoment.subtitle(recipeName: summary.recipeName, timesCooked: summary.timesCooked))
                .font(.subheadline.weight(.semibold))
                .adaptiveSecondaryForeground()
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityIdentifier("madeIt.subtitle")
        }
        .accessibilityElement(children: .combine)
    }

    /// The dish itself, with a tick — big pictures, few words. Falls back to the recipe's illustrated art.
    private var dishPicture: some View {
        RecipeImageView(imageName: summary.imageName, height: Layout.picture, recipeName: summary.recipeName,
                        category: summary.category, cuisine: summary.cuisine)
            .frame(width: Layout.picture, height: Layout.picture)
            .clipShape(Circle())
            .overlay(alignment: .bottomTrailing) {
                IconBadge(systemName: "checkmark", tint: .green, diameter: 36, iconSize: 16, weight: .bold, style: .solid)
            }
            .scaleEffect(landed ? 1 : 0.6)
            .opacity(landed ? 1 : 0)
            .accessibilityHidden(true)
    }

    private enum Layout {
        static let picture: CGFloat = 104
    }

    private var statsCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.spacing12) {
            if let streak = MadeItMoment.streakLine(weeks: summary.streakWeeks) {
                statRow(icon: "flame.fill", tint: .orange, text: streak)
            }
            if let week = MadeItMoment.weekLine(cooksThisWeek: summary.cooksThisWeek) {
                statRow(icon: "fork.knife", tint: .green, text: week)
                    .accessibilityIdentifier("madeIt.week")
            }
            if summary.streakWeeks > 0 || summary.cooksThisWeek > 0 {
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

    private func statRow(icon: String, tint: Color, text: String) -> some View {
        HStack(spacing: AppTheme.spacing8) {
            Image(systemName: icon)
                .foregroundStyle(tint)
                .frame(width: 20)
                .accessibilityHidden(true)
            Text(text)
                .font(.subheadline.weight(.semibold))
                .adaptiveForegroundColor()
        }
    }

    @ViewBuilder
    private var photoSection: some View {
        if photoAdded {
            Label("Photo added", systemImage: "checkmark.circle.fill")
                .font(.subheadline.weight(.semibold))
                .adaptiveForegroundColor()
        } else {
            VStack(spacing: AppTheme.spacing8) {
                if let prompt = MadeItMoment.photoNudge(hasCookPhoto: summary.hasCookPhoto).prompt {
                    Text(prompt)
                        .font(.subheadline)
                        .adaptiveSecondaryForeground()
                        .multilineTextAlignment(.center)
                        .accessibilityIdentifier("madeIt.photoPrompt")
                }
                photoButtons
            }
        }
    }

    private var photoButtons: some View {
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
