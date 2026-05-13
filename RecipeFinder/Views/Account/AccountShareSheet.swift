import SwiftUI

struct AccountShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)

        if let popover = controller.popoverPresentationController,
           let windowScene = UIApplication.shared.connectedScenes
               .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene,
           let window = windowScene.windows.first(where: { $0.isKeyWindow }) {
            popover.sourceView = window
            popover.sourceRect = CGRect(x: window.bounds.midX, y: window.bounds.midY, width: 0, height: 0)
            popover.permittedArrowDirections = []
        }

        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
