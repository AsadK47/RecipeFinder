import SwiftUI
import AuthenticationServices

private let logger = AppLogger.logger(category: "Account")

struct AccountView: View {
    @Environment(\.account) private var accountManager
    @Environment(\.auth) private var authManager
    @Environment(\.badges) private var badgeManager
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("appTheme") private var selectedTheme: AppTheme.ThemeType = .teal
    @AppStorage("cardStyle") private var cardStyle: CardStyle = .frosted

    @State private var activeSheet: AccountSheet?
    @State private var showSignOutAlert = false
    @State private var showDeleteAccountAlert = false
    @State private var showDeleteError = false
    @State private var profileImage: UIImage?
    @State private var editingName = false
    @State private var tempName = ""
    @State private var showSuccessFeedback = false
    @State private var badgesSectionExpanded = true

    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @State private var selectedChefType: ChefType = .homeCook

    private var displayEmail: String {
        authManager.currentUser?.email ?? ""
    }

    var body: some View {
        ZStack {
            AppTheme.backgroundGradient(for: selectedTheme, colorScheme: colorScheme)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                VStack(spacing: AppTheme.spacing12) {
                    GeometryReader { geometry in
                        HStack(spacing: 0) {
                            Spacer()

                            Text("Account")
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
                        AccountProfileAvatar(
                            image: profileImage,
                            initials: getInitials(),
                            chefType: selectedChefType,
                            selectedTheme: selectedTheme,
                            colorScheme: colorScheme,
                            onTap: {
                                activeSheet = .imagePicker
                                HapticManager.shared.light()
                            }
                        )

                        AccountPersonalInfoSection(
                            firstName: $firstName,
                            lastName: $lastName,
                            email: displayEmail,
                            colorScheme: colorScheme
                        )

                        AccountBadgesSection(
                            badgeManager: badgeManager,
                            isExpanded: $badgesSectionExpanded,
                            colorScheme: colorScheme,
                            cardStyle: cardStyle,
                            onSelectBadge: { badge in
                                activeSheet = .badge(badge)
                            }
                        )

                        AccountChefTypeSection(
                            selectedChefType: $selectedChefType,
                            selectedTheme: selectedTheme
                        )

                        Button(action: {
                            activeSheet = .passwordVerification
                        }) {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                Text("Save Profile")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(AppTheme.accentColor(for: selectedTheme))
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

                        AccountActionsSection(
                            // Hidden until Apple-ID linking is a real entitlement (needs paid Apple account);
                            // the "Under Construction" row shipped to users otherwise. Flip back to
                            // `authManager.currentUser?.appleUserID == nil` when the feature is live.
                            showLinkAppleID: false,
                            biometricsAvailable: authManager.biometricsAvailable,
                            biometricType: authManager.biometricType,
                            selectedTheme: selectedTheme,
                            cardStyle: cardStyle,
                            colorScheme: colorScheme,
                            onSignOut: {
                                showSignOutAlert = true
                                HapticManager.shared.light()
                            },
                            onDeleteAccount: {
                                showDeleteAccountAlert = true
                                HapticManager.shared.light()
                            }
                        )
                    }
                    .padding(.top, AppTheme.spacing16)
                    .padding(.horizontal, AppTheme.cardHorizontalPadding)
                    .padding(.bottom, AppTheme.spacing100)
                }
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .privacyPolicy:
                PrivacyPolicyView()
            case .imagePicker:
                ImagePicker(image: $profileImage)
            case .passwordVerification:
                PasswordVerificationSheet(email: displayEmail) {
                    saveProfile()
                }
            case .badge(let badge):
                BadgeDetailView(badge: badge)
                    .presentationDetents([.large])
                    .presentationDragIndicator(.hidden)
            }
        }
        .alert("Sign Out", isPresented: $showSignOutAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Sign Out", role: .destructive) { signOut() }
        } message: {
            Text("Are you sure you want to sign out?")
        }
        .alert("Delete Account", isPresented: $showDeleteAccountAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                Task { await deleteAccount() }
            }
        } message: {
            Text("This action cannot be undone. All your data will be permanently deleted.")
        }
        .alert("Couldn't Delete Account", isPresented: $showDeleteError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Something went wrong while deleting your account. Please try again.")
        }
        .animation(.spring(response: 0.3), value: editingName)
        .animation(.spring(response: 0.3), value: showSuccessFeedback)
        .onAppear {
            loadCurrentProfile()
        }
        .onChange(of: profileImage) { _, newImage in
            accountManager.saveProfileImage(newImage)
        }
    }

    private func signOut() {
        logger.debug("🔓 [AccountView] Sign out button tapped")
        authManager.signOut()
    }

    private func deleteAccount() async {
        do {
            logger.debug("🗑️ [AccountView] Delete account requested")
            try await authManager.deleteAccount()
        } catch {
            logger.error("❌ Account deletion failed: \(error)")
            showDeleteError = true
        }
    }

    private func getInitials() -> String {
        let firstInitial = firstName.first.map(String.init) ?? ""
        let lastInitial = lastName.first.map(String.init) ?? ""
        return "\(firstInitial)\(lastInitial)".uppercased()
    }

    private func loadCurrentProfile() {
        firstName = accountManager.firstName
        lastName = accountManager.lastName
        selectedChefType = accountManager.chefType

        profileImage = accountManager.loadProfileImage()
    }

    private func saveProfile() {
        accountManager.updateProfile(
            firstName: firstName,
            lastName: lastName,
            chefType: selectedChefType
        )

        if let currentUser = authManager.currentUser {
            let fullName = [firstName, lastName]
                .filter { !$0.isEmpty }
                .joined(separator: " ")

            let updatedUser = AuthenticationManager.User(
                id: currentUser.id,
                email: currentUser.email,
                fullName: fullName,
                givenName: firstName,
                familyName: lastName,
                appleUserID: currentUser.appleUserID,
                createdAt: currentUser.createdAt,
                lastLoginAt: Date()
            )

            authManager.updateCurrentUser(updatedUser)
        }

        showSuccessFeedback = true
        HapticManager.shared.success()

        DispatchQueue.main.asyncAfter(deadline: .now() + AppTheme.animationDelayFeedback) {
            showSuccessFeedback = false
        }
    }
}
