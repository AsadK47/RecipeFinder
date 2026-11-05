import SwiftUI

/// Privacy policy access.
struct PrivacySettingsView: View {
    @State private var showPrivacyPolicy = false

    var body: some View {
        SettingsScreen("Privacy") {
            SettingsSection(title: "Policies", items: [
                .init(
                    row: SettingsRow(icon: "hand.raised.fill", iconColor: .blue, title: "Privacy Policy", subtitle: "View our privacy and data practices"),
                    action: {
                        showPrivacyPolicy = true
                        HapticManager.shared.light()
                    }
                )
            ])
        }
        .sheet(isPresented: $showPrivacyPolicy) {
            PrivacyPolicyView()
        }
    }
}

#Preview {
    NavigationStack {
        PrivacySettingsView()
    }
}
