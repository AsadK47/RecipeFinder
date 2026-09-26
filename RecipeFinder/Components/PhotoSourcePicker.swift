import SwiftUI
import UIKit

/// A reusable "add photo" source chooser. Presents a Take Photo / Choose from
/// Library action sheet (the camera option only appears when the device has a
/// camera), then the matching picker, and hands the chosen `UIImage` back via
/// `onPick`.
///
/// Consolidates what were two divergent flows: the post-cook photo sheet offered
/// camera + library, while the recipe wizard's "+" buttons offered library only.
/// Both now route through this modifier so every photo entry point gives the same
/// options.
extension View {
    func photoSourcePicker(
        isPresented: Binding<Bool>,
        onPick: @escaping (UIImage) -> Void
    ) -> some View {
        modifier(PhotoSourcePickerModifier(isPresented: isPresented, onPick: onPick))
    }
}

private struct PhotoSourcePickerModifier: ViewModifier {
    @Binding var isPresented: Bool
    let onPick: (UIImage) -> Void

    @State private var showLibrary = false
    @State private var showCamera = false
    @State private var libraryImage: UIImage?

    private var cameraAvailable: Bool {
        UIImagePickerController.isSourceTypeAvailable(.camera)
    }

    func body(content: Content) -> some View {
        content
            .confirmationDialog("Add Photo", isPresented: $isPresented, titleVisibility: .visible) {
                if cameraAvailable {
                    Button("Take Photo") { showCamera = true }
                }
                Button("Choose from Library") { showLibrary = true }
                Button("Cancel", role: .cancel) {}
            }
            .sheet(isPresented: $showLibrary) {
                ImagePicker(image: $libraryImage) {
                    HapticManager.shared.light()
                }
            }
            .fullScreenCover(isPresented: $showCamera) {
                CameraPicker { image in
                    HapticManager.shared.light()
                    onPick(image)
                }
                .ignoresSafeArea()
            }
            // ImagePicker dismisses itself on selection; deliver once the image lands.
            .onChange(of: libraryImage) { _, newValue in
                if let newValue {
                    onPick(newValue)
                    libraryImage = nil
                }
            }
    }
}
