import PhotosUI
import SwiftUI
import UIKit

// Post-cook card inviting a dish photo; caller persists the returned UIImage.
struct PostCookPhotoSheet: View {
    let onPhotoSelected: (UIImage) -> Void
    @Environment(\.dismiss) private var dismiss

    @State private var selectedItem: PhotosPickerItem?
    @State private var showCamera = false
    @State private var loadError: String?

    var body: some View {
        ZStack {
            AppBackground()

            VStack(spacing: AppTheme.spacing24) {
                cookIcon
                headerText
                actionButtons
                Spacer()
            }
            .padding(.top, AppTheme.spacing32)
        }
        .presentationDetents([.height(360)])
        .presentationDragIndicator(.visible)
        .fullScreenCover(isPresented: $showCamera) {
            CameraPicker { image in
                onPhotoSelected(image)
                dismiss()
            }
        }
        .onChange(of: selectedItem) { _, newItem in
            guard let newItem else { return }
            Task {
                if let data = try? await newItem.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    onPhotoSelected(image)
                    dismiss()
                } else {
                    // Don't fail silently — tell the user the photo didn't load.
                    loadError = "That photo couldn't be loaded. Please try another."
                }
            }
        }
        .errorAlert("Couldn't load photo", message: $loadError)
    }

    private var cookIcon: some View {
        IconBadge(systemName: "checkmark", tint: .green, diameter: 80, iconSize: 32, weight: .bold)
    }

    private var headerText: some View {
        VStack(spacing: AppTheme.spacing8) {
            Text("Nice cook!")
                .font(.title2.bold())
                .adaptiveForegroundColor()
            Text("Add a photo of your finished dish?")
                .font(.subheadline)
                .adaptiveSecondaryForeground()
                .multilineTextAlignment(.center)
        }
    }

    private var actionButtons: some View {
        VStack(spacing: AppTheme.spacing12) {
            PhotosPicker(selection: $selectedItem, matching: .images) {
                Label("Choose Photo", systemImage: "photo.on.rectangle")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AppTheme.spacing14)
                    .background(
                        RoundedRectangle(cornerRadius: AppTheme.cornerRadius12)
                            .fill(AppTheme.accentColor)
                    )
                    .foregroundStyle(.white)
                    .font(.subheadline.weight(.semibold))
            }
            .buttonStyle(.plain)

            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                Button { showCamera = true } label: {
                    Label("Take Photo", systemImage: "camera")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, AppTheme.spacing14)
                        .background(
                            RoundedRectangle(cornerRadius: AppTheme.cornerRadius12)
                                .fill(Color.white.opacity(AppTheme.overlayLightOpacity))
                        )
                        .adaptiveForegroundColor()
                        .font(.subheadline.weight(.semibold))
                }
                .buttonStyle(.plain)
            }

            Button("Skip") { dismiss() }
                .font(.subheadline)
                .adaptiveSecondaryForeground()
                .padding(.top, AppTheme.spacing4)
        }
        .padding(.horizontal, AppTheme.spacing24)
    }
}
