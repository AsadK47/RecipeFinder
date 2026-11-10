import SwiftUI

/// Me tab: profile, badges and chef type, with Settings behind the gear.
struct MeView: View {
    var body: some View {
        NavigationStack {
            ProfileView(title: "Me", showsSettingsLink: true)
        }
    }
}

#Preview {
    MeView()
}
