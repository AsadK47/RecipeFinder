import SwiftUI

struct ProfileView: View {
    @Environment(\.profile) private var profileManager
    @Environment(\.badges) private var badgeManager

    @State private var activeSheet: ProfileSheet?
    @State private var profileImage: UIImage?
    @State private var editingName = false
    @State private var tempName = ""
    @State private var showSuccessFeedback = false
    @State private var badgesSectionExpanded = true

    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @State private var selectedChefType: ChefType = .homeCook

    var body: some View {
        ZStack {
            AppBackground()

            VStack(spacing: 0) {
                VStack(spacing: AppTheme.spacing12) {
                    GeometryReader { geometry in
                        HStack(spacing: 0) {
                            Spacer()

                            Text("Profile")
                                .font(.system(size: min(34, geometry.size.width * 0.085), weight: .bold))
                                .adaptiveForegroundColor()
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)

                            Spacer()
                        }
                    }
                    .frame(height: AppTheme.buttonHeight)
                }
                .padding(.horizontal, AppTheme.cardHorizontalPadding)
                .padding(.top, AppTheme.spacing16)

                ScrollView {
                    VStack(spacing: AppTheme.spacing24) {
                        ProfileAvatar(
                            image: profileImage,
                            initials: getInitials(),
                            chefType: selectedChefType,
                            onTap: {
                                activeSheet = .imagePicker
                                HapticManager.shared.light()
                            }
                        )

                        ProfilePersonalInfoSection(
                            firstName: $firstName,
                            lastName: $lastName
                        )

                        ProfileBadgesSection(
                            badgeManager: badgeManager,
                            isExpanded: $badgesSectionExpanded,
                            onSelectBadge: { badge in
                                activeSheet = .badge(badge)
                            }
                        )

                        ProfileChefTypeSection(
                            selectedChefType: $selectedChefType,
                        )

                        Button(action: saveProfile) {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                Text("Save Profile")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(AppTheme.accentColor)
                            .adaptiveForegroundColor()
                            .cornerRadius(AppTheme.cornerRadius12)
                        }
                        .opacity(showSuccessFeedback ? 0.6 : 1)
                        .disabled(showSuccessFeedback)
                        .padding(.top, AppTheme.spacing8)

                        if showSuccessFeedback {
                            HStack(spacing: AppTheme.spacing8) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                                Text("Profile saved successfully!")
                                    .fontWeight(.medium)
                            }
                            .padding()
                            .background(AppTheme.success.opacity(0.1))
                            .cornerRadius(AppTheme.cornerRadius12)
                            .transition(.scale.combined(with: .opacity))
                        }
                    }
                    .padding(.top, AppTheme.spacing16)
                    .padding(.horizontal, AppTheme.cardHorizontalPadding)
                    .padding(.bottom, AppTheme.spacing100)
                }
            }
        }
        .appNavigationTitle("")
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .privacyPolicy:
                PrivacyPolicyView()
            case .imagePicker:
                ImagePicker(image: $profileImage)
            case .badge(let badge):
                BadgeDetailView(badge: badge)
                    .presentationDetents([.large])
                    .presentationDragIndicator(.hidden)
            }
        }
        .animation(.appSpring, value: editingName)
        .animation(.appSpring, value: showSuccessFeedback)
        .onAppear {
            loadCurrentProfile()
        }
        .onChange(of: profileImage) { _, newImage in
            profileManager.saveProfileImage(newImage)
        }
    }

    private func getInitials() -> String {
        let firstInitial = firstName.first.map(String.init) ?? ""
        let lastInitial = lastName.first.map(String.init) ?? ""
        return "\(firstInitial)\(lastInitial)".uppercased()
    }

    private func loadCurrentProfile() {
        firstName = profileManager.firstName
        lastName = profileManager.lastName
        selectedChefType = profileManager.chefType

        profileImage = profileManager.loadProfileImage()
    }

    private func saveProfile() {
        profileManager.updateProfile(
            firstName: firstName,
            lastName: lastName,
            chefType: selectedChefType
        )

        showSuccessFeedback = true
        HapticManager.shared.success()

        DispatchQueue.main.asyncAfter(deadline: .now() + AppTheme.animationDelayFeedback) {
            showSuccessFeedback = false
        }
    }
}
