import SwiftUI
import UIKit

// Reusable "add photo" chooser (Take Photo shown only if a camera exists) so every photo entry point offers the same options; returns the chosen `UIImage` via `onPick`.
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
            // ImagePicker self-dismisses on selection; deliver once the image lands.
            .onChange(of: libraryImage) { _, newValue in
                if let newValue {
                    onPick(newValue)
                    libraryImage = nil
                }
            }
    }
}
