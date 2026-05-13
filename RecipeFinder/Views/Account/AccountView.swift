import SwiftUI
import AuthenticationServices

private let logger = AppLogger.logger(category: "Account")

enum AccountSheet: Identifiable {
    case privacyPolicy
    case imagePicker
    case passwordVerification
    case badge(Badge)
    
    var id: String {
        switch self {
        case .privacyPolicy: return "privacyPolicy"
        case .imagePicker: return "imagePicker"
        case .passwordVerification: return "passwordVerification"
        case .badge(let badge): return "badge_\(badge.id)"
        }
    }
}

struct AccountView: View {
    @StateObject private var accountManager = AccountManager.shared
    @StateObject private var authManager = AuthenticationManager.shared
    @StateObject private var badgeManager = BadgeManager.shared
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("appTheme") private var selectedTheme: AppTheme.ThemeType = .teal
    @AppStorage("cardStyle") private var cardStyle: CardStyle = .frosted
    
    @State private var activeSheet: AccountSheet?
    @State private var showSignOutAlert = false
    @State private var showDeleteAccountAlert = false
    @State private var profileImage: UIImage?
    @State private var editingName = false
    @State private var tempName = ""
    @State private var showSuccessFeedback = false
    @State private var badgesSectionExpanded = true
    
    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @State private var selectedChefType: ChefType = .homeCook
    
    private var displayName: String {
        if let user = authManager.currentUser {
            return user.displayName
        }
        return accountManager.fullName
    }
    
    private var displayEmail: String {
        authManager.currentUser?.email ?? ""
    }
    
    private var displayInitials: String {
        if let user = authManager.currentUser {
            return user.initials
        }
        return accountManager.initials
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
                    .frame(height: 44)
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                
                ScrollView {
                    VStack(spacing: AppTheme.spacing24) {
                        profileAvatar
                        
                        personalInfoSection
                        
                        badgesSection
                        
                        chefTypeSection
                        
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
                        .padding(.top, 8)
                        
                        if showSuccessFeedback {
                            HStack(spacing: AppTheme.spacing8) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                Text("Profile saved successfully!")
                                    .fontWeight(.medium)
                            }
                            .padding()
                            .background(AppTheme.success.opacity(0.1))
                            .cornerRadius(AppTheme.cornerRadius12)
                            .transition(.scale.combined(with: .opacity))
                        }
                        
                        accountActionsSection
                    }
                    .padding(.top, 16)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 100)
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
        .animation(.spring(response: 0.3), value: editingName)
        .animation(.spring(response: 0.3), value: showSuccessFeedback)
        .onAppear {
            loadCurrentProfile()
        }
        .onChange(of: profileImage) { _, newImage in
            accountManager.saveProfileImage(newImage)
        }
    }
    
    private var profileAvatar: some View {
        VStack(spacing: AppTheme.spacing12) {
            Button(action: {
                activeSheet = .imagePicker
                HapticManager.shared.light()
            }) {
                ZStack(alignment: .bottomTrailing) {
                    if let profileImage = profileImage {
                        Image(uiImage: profileImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 100, height: 100)
                            .clipShape(Circle())
                    } else {
                        ZStack {
                            Circle()
                                .fill(AppTheme.accentColor(for: selectedTheme))
                                .frame(width: 100, height: 100)
                            
                            Text(getInitials())
                                .font(.system(size: AppTheme.fontSize42, weight: .bold))
                                .adaptiveForegroundColor()
                        }
                    }
                    
                    ZStack {
                        Circle()
                            .fill(colorScheme == .dark ? Color(white: AppTheme.cardDarkOpacity) : .white)
                            .frame(width: 28, height: 28)
                        
                        Image(systemName: "camera.fill")
                            .font(.system(size: AppTheme.fontSize12, weight: .semibold))
                            .foregroundColor(AppTheme.accentColor(for: selectedTheme))
                    }
                }
            }
            
            HStack(spacing: AppTheme.spacing6) {
                Image(systemName: selectedChefType.icon)
                    .font(.caption)
                Text(selectedChefType.rawValue)
                    .font(.subheadline)
            }
            .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }
    
    private var personalInfoSection: some View {
        VStack(spacing: 0) {
            HStack {
                Image(systemName: "person.fill")
                    .adaptiveForegroundColor()
                Text("Personal Information")
                    .font(.headline)
                    .adaptiveForegroundColor()
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(Color.secondary.opacity(0.1))
            
            VStack(spacing: 0) {
                ProfileTextField(
                    icon: "person.circle",
                    label: "First Name",
                    text: $firstName,
                    placeholder: "John",
                    colorScheme: colorScheme
                )
                
                Divider()
                    .background(Color.secondary.opacity(0.1))
                    .padding(.leading, 60)
                
                ProfileTextField(
                    icon: "person.crop.circle",
                    label: "Last Name",
                    text: $lastName,
                    placeholder: "Doe",
                    colorScheme: colorScheme
                )
                
                if !displayEmail.isEmpty {
                    Divider()
                        .background(Color.secondary.opacity(0.1))
                        .padding(.leading, 60)
                    
                    HStack(spacing: AppTheme.spacing16) {
                        Image(systemName: "envelope.fill")
                            .font(.title3)
                            .foregroundColor(.secondary)
                            .frame(width: 28)
                        
                        VStack(alignment: .leading, spacing: AppTheme.spacing4) {
                            Text("Email")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text(displayEmail)
                                .font(.body)
                                .adaptiveForegroundColor()
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                }
            }
        }
        .background {
            if cardStyle == .solid {
                RoundedRectangle(cornerRadius: 16)
                    .fill(AppTheme.adaptiveCard(for: colorScheme))
            } else {
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
            }
        }
    }
    
    private var chefTypeSection: some View {
        VStack(spacing: AppTheme.spacing12) {
            HStack {
                Image(systemName: "fork.knife.circle.fill")
                    .adaptiveForegroundColor()
                Text("Chef Type")
                    .font(.headline)
                    .adaptiveForegroundColor()
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: AppTheme.spacing12) {
                ForEach(ChefType.allCases, id: \.self) { type in
                    ChefTypeCard(
                        chefType: type,
                        isSelected: selectedChefType == type,
                        selectedTheme: selectedTheme
                    ) {
                        withAnimation(.spring(response: 0.3)) {
                            selectedChefType = type
                            HapticManager.shared.light()
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 16)
        }
        .background {
            if cardStyle == .solid {
                RoundedRectangle(cornerRadius: 16)
                    .fill(AppTheme.adaptiveCard(for: colorScheme))
            } else {
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
            }
        }
    }

    private var accountActionsSection: some View {
        VStack(spacing: AppTheme.spacing12) {
            if authManager.currentUser?.appleUserID == nil {
                VStack(spacing: AppTheme.spacing8) {
                    Button {
                        HapticManager.shared.light()
                    } label: {
                        HStack(spacing: AppTheme.spacing12) {
                            Image(systemName: "applelogo")
                                .font(.system(size: AppTheme.fontSize16 + 2, weight: .semibold))
                            Text("Link Apple ID")
                                .font(.body)
                                .fontWeight(.semibold)
                        }
                        .adaptiveForegroundColor(opacity: 0.5)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background {
                            if cardStyle == .solid {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.black.opacity(AppTheme.shadowDarkOpacity))
                            } else {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.black.opacity(AppTheme.lowEmphasisOpacity))
                            }
                        }
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.orange.opacity(0.4), lineWidth: 1)
                        )
                    }
                    .disabled(true)
                    
                    HStack(spacing: AppTheme.spacing4) {
                        Image(systemName: "wrench.and.screwdriver.fill")
                            .font(.system(size: AppTheme.fontSize11))
                        Text("Under Construction • Please Wait Patiently")
                            .font(.system(size: AppTheme.fontSize11, weight: .medium))
                    }
                    .foregroundColor(.orange.opacity(0.8))
                }
            }
            
            if authManager.biometricsAvailable {
                NavigationLink(destination: PrivacySettingsView()) {
                    HStack(spacing: AppTheme.spacing12) {
                        Image(systemName: authManager.biometricType == "Face ID" ? "faceid" : "touchid")
                            .font(.system(size: AppTheme.fontSize16 + 2, weight: .semibold))
                        Text("Configure \(authManager.biometricType)")
                            .font(.body)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(AppTheme.accentColor(for: selectedTheme))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background {
                        if cardStyle == .solid {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(colorScheme == .dark ? Color(white: AppTheme.cardDarkOpacity) : Color.white.opacity(AppTheme.highEmphasisOpacity))
                        } else {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(.ultraThinMaterial)
                        }
                    }
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(AppTheme.accentColor(for: selectedTheme).opacity(0.3), lineWidth: 1)
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            Button {
                showSignOutAlert = true
                HapticManager.shared.light()
            } label: {
                Text("Sign Out")
                    .font(.body)
                    .fontWeight(.semibold)
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background {
                        if cardStyle == .solid {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(colorScheme == .dark ? Color(white: AppTheme.cardDarkOpacity) : Color.white)
                        } else {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(.ultraThinMaterial)
                        }
                    }
            }
            
            Button {
                showDeleteAccountAlert = true
                    HapticManager.shared.light()
                } label: {
                    Text("Delete Account")
                        .font(.body)
                        .fontWeight(.semibold)
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background {
                            if cardStyle == .solid {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(colorScheme == .dark ? Color(white: AppTheme.cardDarkOpacity) : Color.white)
                            } else {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(.ultraThinMaterial)
                            }
                        }
                }
                .buttonStyle(PlainButtonStyle())
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
            logger.debug("Error deleting account: \(error)")
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
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            showSuccessFeedback = false
        }
    }
    
    var badgesSection: some View {
        VStack(spacing: 0) {
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    badgesSectionExpanded.toggle()
                }
                HapticManager.shared.light()
            }) {
                HStack {
                    Image(systemName: "trophy.fill")
                        .adaptiveForegroundColor()
                    Text("Achievements")
                        .font(.headline)
                        .adaptiveForegroundColor()
                    Spacer()
                    Image(systemName: badgesSectionExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(.secondary)
                        .font(.caption)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(Color.secondary.opacity(0.1))
            }
            .buttonStyle(PlainButtonStyle())
            
            if badgesSectionExpanded {
                VStack(alignment: .leading, spacing: AppTheme.spacing12) {
                    let recipeCount = PersistenceController.shared.getRecipeCount()
                    let allBadges = badgeManager.getAllBadges(recipeCount: recipeCount)
                        .sorted { $0.isUnlocked && !$1.isUnlocked }
                    
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: AppTheme.spacing12) {
                        ForEach(allBadges) { badge in
                            Button(action: {
                                activeSheet = .badge(badge)
                                HapticManager.shared.light()
                            }) {
                                BadgeCard(badge: badge, colorScheme: colorScheme, cardStyle: cardStyle)
                            }
                            .buttonStyle(PlainButtonStyle())
                            .accessibilityLabel(badge.title)
                            .accessibilityHint(badge.isUnlocked ? "Unlocked badge. Double tap for details" : "Locked badge. \(badge.description)")
                            .accessibilityAddTraits(.isButton)
                        }
                    }
                }
                .padding(AppTheme.spacing24)
            }
        }
        .background {
            if cardStyle == .solid {
                RoundedRectangle(cornerRadius: 16)
                    .fill(AppTheme.adaptiveCard(for: colorScheme))
            } else {
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
            }
        }
    }
}
