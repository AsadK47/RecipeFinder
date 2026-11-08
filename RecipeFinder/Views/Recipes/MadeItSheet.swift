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
                    PrimaryButton("Done", systemImage: "checkmark", fillWidth: true) { dismiss() }
                        .accessibilityIdentifier("madeIt.done")
                }
                .padding(.horizontal, AppTheme.spacing24)
                .padding(.top, AppTheme.spacing32)
                .padding(.bottom, AppTheme.spacing24)
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
