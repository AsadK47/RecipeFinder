import SwiftUI

/// Settings › Profile: your photo and first/last name. The name is also edited in place on Me's hero; badges and chef
/// type live in Me › Profile.
struct ProfileSettingsView: View {
    @Environment(\.profile) private var profileManager

    @State private var firstName = ""
    @State private var lastName = ""
    @State private var profileImage: UIImage?
    @State private var activeSheet: ProfileSheet?
    /// Shows "Saved" until the next edit.
    @State private var saved = false

    var body: some View {
        SettingsScreen("Profile") {
            ProfileAvatar(
                image: profileImage,
                initials: initials,
                chefType: profileManager.chefType,
                onTap: {
                    activeSheet = .imagePicker
                    HapticManager.shared.light()
                }
            )

            ProfilePersonalInfoSection(firstName: $firstName, lastName: $lastName)

            PrimaryButton(saved && !hasChanges ? "Saved" : "Save", systemImage: "checkmark.circle.fill", fillWidth: true, action: save)
                .disabled(!hasChanges)
                .opacity(hasChanges ? 1 : AppTheme.mediumEmphasisOpacity)
                .accessibilityIdentifier("settings.profile.save")
        }
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .privacyPolicy:
                PrivacyPolicyView()
            case .imagePicker:
                ImagePicker(image: $profileImage)
            }
        }
        .onAppear {
            firstName = profileManager.firstName
            lastName = profileManager.lastName
            profileImage = profileManager.loadProfileImage()
        }
        .onChange(of: profileImage) { _, newImage in
            profileManager.saveProfileImage(newImage)
        }
    }

    /// Empty with no name — the avatar then shows initials only once there's something to show.
    private var initials: String {
        let first = firstName.trimmed.first.map(String.init) ?? ""
        let last = lastName.trimmed.first.map(String.init) ?? ""
        return "\(first)\(last)".uppercased()
    }

    private var hasChanges: Bool {
        firstName.trimmed != profileManager.firstName || lastName.trimmed != profileManager.lastName
    }

    private func save() {
        profileManager.updateProfile(firstName: firstName, lastName: lastName, chefType: profileManager.chefType)
        firstName = profileManager.firstName
        lastName = profileManager.lastName
        saved = true
        HapticManager.shared.success()
    }
}

#Preview {
    NavigationStack {
        ProfileSettingsView()
    }
}
