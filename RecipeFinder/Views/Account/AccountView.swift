import SwiftUI
import AuthenticationServices
import UniformTypeIdentifiers

private let logger = AppLogger.logger(category: "Account")


struct AccountView: View {
    @StateObject private var accountManager = AccountManager.shared
    @StateObject private var authManager = AuthenticationManager.shared
    @StateObject private var badgeManager = BadgeManager.shared
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("appTheme") private var selectedTheme: AppTheme.ThemeType = .teal
    @AppStorage("cardStyle") private var cardStyle: CardStyle = .frosted
    
    @State private var editingName = false
    @State private var tempName = ""
    @State private var showingSignOutAlert = false
    @State private var showingDeleteAccountAlert = false
    @State private var showingPrivacyPolicy = false
    @State private var showingAuthError = false
    @State private var authErrorMessage = ""
    @State private var showSuccessFeedback = false
    @State private var showImagePicker = false
    @State private var profileImage: UIImage?
    @State private var showPasswordVerification = false
    @State private var badgesSectionExpanded = true // Collapsible badges
    @State private var selectedBadge: Badge? = nil
    
    // Profile fields
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
                // Header
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
                        // Profile Avatar
                        profileAvatar
                        
                        // Personal Information Section
                        personalInfoSection
                        
                        // Achievements/Badges Section (collapsible)
                        badgesSection
                        
                        // Chef Type Section
                        chefTypeSection
                        
                        // Save Button
                        Button(action: {
                            // Show password verification first
                            showPasswordVerification = true
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
                        
                        // Success Feedback
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
                        
                        // Account Actions
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
        .sheet(isPresented: $showingPrivacyPolicy) {
            PrivacyPolicyView()
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(image: $profileImage)
        }
        .sheet(isPresented: $showPasswordVerification) {
            PasswordVerificationSheet(email: displayEmail) {
                saveProfile()
            }
        }
        .sheet(item: $selectedBadge) { badge in
            BadgeDetailView(badge: badge)
                .presentationDetents([.large])
                .presentationDragIndicator(.hidden)
        }
        .alert("Sign Out", isPresented: $showingSignOutAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Sign Out", role: .destructive) {
                signOut()
            }
        } message: {
            Text("Are you sure you want to sign out?")
        }
        .alert("Delete Account", isPresented: $showingDeleteAccountAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                Task {
                    await deleteAccount()
                }
            }
        } message: {
            Text("This action cannot be undone. All your data will be permanently deleted.")
        }
        .alert("Sign In Error", isPresented: $showingAuthError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(authErrorMessage)
        }
        .animation(.spring(response: 0.3), value: editingName)
        .animation(.spring(response: 0.3), value: showSuccessFeedback)
        .onAppear {
            loadCurrentProfile()
        }
        .onChange(of: profileImage) { _, newImage in
            // Save profile image whenever it changes
            accountManager.saveProfileImage(newImage)
        }
    }
    
    // MARK: - Profile Avatar
    
    private var profileAvatar: some View {
        VStack(spacing: AppTheme.spacing12) {
            Button(action: {
                showImagePicker = true
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
    
    // MARK: - Personal Information Section
    
    private var personalInfoSection: some View {
        VStack(spacing: 0) {
            // Section Header
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
    
    // MARK: - Chef Type Section
    
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
    
    // MARK: - Profile Display Card
    
    private var profileDisplayCard: some View {
        Button(action: {
            HapticManager.shared.light()
        }) {
            VStack(spacing: AppTheme.spacing24) {
                // Avatar
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
                            
                            Text(displayInitials)
                                .font(.system(size: AppTheme.fontSize42, weight: .semibold))
                                .adaptiveForegroundColor()
                        }
                    }
                    
                    ZStack {
                        Circle()
                            .fill(colorScheme == .dark ? Color(white: AppTheme.cardDarkOpacity) : .white)
                            .frame(width: 32, height: 32)
                        
                        Image(systemName: "pencil")
                            .font(.system(size: AppTheme.fontSize14, weight: .semibold))
                            .foregroundColor(AppTheme.accentColor(for: selectedTheme))
                    }
                }
                
                // Name & Chef Type
                VStack(spacing: AppTheme.spacing8) {
                    Text(displayName.isEmpty ? "Set Your Name" : displayName)
                        .font(.title2)
                        .fontWeight(.bold)
                        .adaptiveForegroundColor()
                    
                    HStack(spacing: AppTheme.spacing8) {
                        Image(systemName: accountManager.chefType.icon)
                            .font(.caption)
                        Text(accountManager.chefType.rawValue)
                            .font(.subheadline)
                    }
                    .foregroundColor(.secondary)
                }
                
                // Edit Hint
                HStack(spacing: AppTheme.spacing6) {
                    Image(systemName: "info.circle.fill")
                        .font(.caption)
                    Text("Tap to edit profile")
                        .font(.caption)
                }
                .foregroundColor(.secondary)
                .padding(.top, 4)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 32)
        }
        .buttonStyle(PlainButtonStyle())
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
    
    // MARK: - Account Actions
    
    private var accountActionsSection: some View {
        VStack(spacing: AppTheme.spacing12) {
            // Sign in with Apple (if not already using it) - Under Construction
            if authManager.currentUser?.appleUserID == nil {
                VStack(spacing: AppTheme.spacing8) {
                    Button {
                        // Disabled during testing
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
            
            // Face ID / Touch ID Settings
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
                showingSignOutAlert = true
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
                showingDeleteAccountAlert = true
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
    
    // MARK: - Helper Functions
    
    private func signOut() {
        logger.debug("🔓 [AccountView] Sign out button tapped")
        authManager.signOut()
        // Navigation handled automatically by app root view
    }
    
    private func deleteAccount() async {
        do {
            logger.debug("🗑️ [AccountView] Delete account requested")
            try await authManager.deleteAccount()
            // Navigation handled automatically by app root view
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
        // Load current values from AccountManager
        firstName = accountManager.firstName
        lastName = accountManager.lastName
        selectedChefType = accountManager.chefType
        
        // Load profile image
        profileImage = accountManager.loadProfileImage()
        
    }
    
    private func saveProfile() {
        // Save to AccountManager using the updateProfile method
        accountManager.updateProfile(
            firstName: firstName,
            lastName: lastName,
            chefType: selectedChefType
        )
        
        // Update AuthManager if signed in
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
        
        // Show success feedback
        showSuccessFeedback = true
        HapticManager.shared.success()
        
        // Hide after 2 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            showSuccessFeedback = false
        }
    }
    
    // MARK: - Badges Section
    
    var badgesSection: some View {
        VStack(spacing: 0) {
            // Collapsible Header
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
            
            // Collapsible Content
            if badgesSectionExpanded {
                VStack(alignment: .leading, spacing: AppTheme.spacing12) {
                    let recipeCount = PersistenceController.shared.getRecipeCount()
                    let allBadges = badgeManager.getAllBadges(recipeCount: recipeCount)
                        .sorted { $0.isUnlocked && !$1.isUnlocked } // Unlocked first
                    
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: AppTheme.spacing12) {
                        ForEach(allBadges) { badge in
                            Button(action: {
                                selectedBadge = badge
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

// MARK: - Account Row Button Component

struct AccountRowButton: View {
    let icon: String
    var iconColor: Color = .blue
    let title: String
    var subtitle: String?
    var showChevron: Bool = false
    let action: () -> Void
    
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: AppTheme.spacing16) {
                // Icon with background circle
                ZStack {
                    Circle()
                        .fill(iconColor)
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: icon)
                        .font(.system(size: AppTheme.fontSize16 + 2, weight: .semibold))
                        .adaptiveForegroundColor()
                }
                
                VStack(alignment: .leading, spacing: AppTheme.spacing4) {
                    Text(title)
                        .font(.body)
                        .foregroundColor(colorScheme == .dark ? .white : .primary)
                    
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                if showChevron {
                    Image(systemName: "chevron.right")
                        .font(.system(size: AppTheme.fontSize13, weight: .semibold))
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Data Privacy View

// MARK: - Data Download View

struct StatBadge: View {
    let icon: String
    let count: Int
    let label: String
    
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(spacing: AppTheme.spacing4) {
            HStack(spacing: AppTheme.spacing4) {
                Image(systemName: icon)
                    .font(.caption2)
                Text("\(count)")
                    .font(.subheadline)
                    .fontWeight(.bold)
            }
            .foregroundColor(colorScheme == .dark ? .white : .primary)
            
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.secondary.opacity(0.1))
        )
    }
}

// Account Share Sheet

struct AccountShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        
        // Configure for iPad if needed
        if let popover = controller.popoverPresentationController,
           let windowScene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene,
           let window = windowScene.windows.first(where: { $0.isKeyWindow }) {
            popover.sourceView = window
            popover.sourceRect = CGRect(x: window.bounds.midX, y: window.bounds.midY, width: 0, height: 0)
            popover.permittedArrowDirections = []
        }
        
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Data Import View

struct DataImportView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showingDocumentPicker = false
    @State private var isImporting = false
    @State private var importResult: ImportResult?
    @State private var mergeMode: MergeMode = .replace
    
    enum ImportResult {
        case success(String)
        case error(String)
    }
    
    enum MergeMode: String, CaseIterable {
        case replace = "Replace All"
        case merge = "Merge (Keep Both)"
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: AppTheme.spacing32) {
                Spacer()
                
                Image(systemName: "square.and.arrow.up.fill")
                    .font(.system(size: AppTheme.fontSize60))
                    .foregroundColor(.orange)
                
                Text("Import Your Data")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Restore your recipes, preferences, and data from a previous backup. Select a JSON file exported from RecipeFinder.")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                
                // Merge Mode Picker
                VStack(alignment: .leading, spacing: AppTheme.spacing12) {
                    Text("Import Mode")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    ForEach(MergeMode.allCases, id: \.self) { mode in
                        Button(action: {
                            mergeMode = mode
                            HapticManager.shared.selection()
                        }) {
                            HStack {
                                Image(systemName: mergeMode == mode ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(mergeMode == mode ? .orange : .secondary)
                                
                                VStack(alignment: .leading, spacing: AppTheme.spacing2) {
                                    Text(mode.rawValue)
                                        .font(.body)
                                        .foregroundColor(.primary)
                                    
                                    Text(mode == .replace ? "Delete existing data and replace with imported data" : "Keep existing data and add imported data")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                            }
                            .padding()
                            .background(Color.secondary.opacity(0.1))
                            .cornerRadius(AppTheme.cornerRadius12)
                        }
                    }
                }
                .padding(.horizontal)
                
                if let result = importResult {
                    switch result {
                    case .success(let message):
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text(message)
                                .font(.caption)
                                .foregroundColor(.green)
                        }
                        .padding(.horizontal)
                    case .error(let message):
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.red)
                            Text(message)
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                        .padding(.horizontal)
                    }
                }
                
                Button {
                    showingDocumentPicker = true
                } label: {
                    HStack {
                        if isImporting {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Image(systemName: "doc.badge.arrow.up")
                            Text("Select JSON File")
                        }
                    }
                    .font(.headline)
                    .adaptiveForegroundColor()
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.orange)
                    .cornerRadius(AppTheme.cornerRadius12)
                }
                .disabled(isImporting)
                .padding(.horizontal)
                
                Spacer()
            }
            .padding(.top, 40)
            .navigationTitle("Data Import")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .fileImporter(
                isPresented: $showingDocumentPicker,
                allowedContentTypes: [.json],
                allowsMultipleSelection: false
            ) { result in
                handleFileImport(result)
            }
        }
    }
    
    private func handleFileImport(_ result: Result<[URL], Error>) {
        isImporting = true
        importResult = nil
        
        // Capture mergeMode value before entering background thread
        let selectedMergeMode = mergeMode
        
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                guard let url = try result.get().first else {
                    throw NSError(domain: "ImportError", code: 1, userInfo: [NSLocalizedDescriptionKey: "No file selected"])
                }
                
                guard url.startAccessingSecurityScopedResource() else {
                    throw NSError(domain: "ImportError", code: 2, userInfo: [NSLocalizedDescriptionKey: "Cannot access file"])
                }
                
                defer { url.stopAccessingSecurityScopedResource() }
                
                let data = try Data(contentsOf: url)
                guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                    throw NSError(domain: "ImportError", code: 3, userInfo: [NSLocalizedDescriptionKey: "Invalid JSON format"])
                }
                
                // Import preferences
                if let preferences = json["preferences"] as? [String: Any] {
                    if let theme = preferences["theme"] as? String {
                        UserDefaults.standard.set(theme, forKey: "appTheme")
                    }
                    if let measurement = preferences["measurementSystem"] as? String {
                        UserDefaults.standard.set(measurement, forKey: "measurementSystem")
                    }
                    if let cardStyle = preferences["cardStyle"] as? String {
                        UserDefaults.standard.set(cardStyle, forKey: "cardStyle")
                    }
                }
                
                // Import favorites
                if selectedMergeMode == .replace {
                    if let favorites = json["favoriteRecipes"] as? [String] {
                        UserDefaults.standard.set(favorites, forKey: "favoriteRecipeIDs")
                    }
                } else {
                    if let newFavorites = json["favoriteRecipes"] as? [String],
                       var existingFavorites = UserDefaults.standard.array(forKey: "favoriteRecipeIDs") as? [String] {
                        existingFavorites.append(contentsOf: newFavorites)
                        let uniqueFavorites = Array(Set(existingFavorites))
                        UserDefaults.standard.set(uniqueFavorites, forKey: "favoriteRecipeIDs")
                    }
                }
                
                // Import shopping list
                if let shoppingListArray = json["shoppingList"] as? [[String: Any]] {
                    let jsonData = try JSONSerialization.data(withJSONObject: shoppingListArray)
                    if let newItems = try? JSONDecoder().decode([ShoppingListModel].self, from: jsonData) {
                        if selectedMergeMode == .replace {
                            let encoded = try JSONEncoder().encode(newItems)
                            UserDefaults.standard.set(encoded, forKey: "shoppingListItems")
                        } else {
                            if let existingData = UserDefaults.standard.data(forKey: "shoppingListItems"),
                               var existingItems = try? JSONDecoder().decode([ShoppingListModel].self, from: existingData) {
                                existingItems.append(contentsOf: newItems)
                                let encoded = try JSONEncoder().encode(existingItems)
                                UserDefaults.standard.set(encoded, forKey: "shoppingListItems")
                            }
                        }
                    }
                }
                
                // Import kitchen inventory
                if let inventoryArray = json["kitchenInventory"] as? [[String: Any]] {
                    let jsonData = try JSONSerialization.data(withJSONObject: inventoryArray)
                    if let newItems = try? JSONDecoder().decode([KitchenInventoryModel].self, from: jsonData) {
                        if selectedMergeMode == .replace {
                            let encoded = try JSONEncoder().encode(newItems)
                            UserDefaults.standard.set(encoded, forKey: "kitchenInventory")
                        } else {
                            if let existingData = UserDefaults.standard.data(forKey: "kitchenInventory"),
                               var existingItems = try? JSONDecoder().decode([KitchenInventoryModel].self, from: existingData) {
                                existingItems.append(contentsOf: newItems)
                                let encoded = try JSONEncoder().encode(existingItems)
                                UserDefaults.standard.set(encoded, forKey: "kitchenInventory")
                            }
                        }
                    }
                }
                
                // Import meal plans
                if let mealPlansArray = json["mealPlans"] as? [[String: Any]] {
                    let jsonData = try JSONSerialization.data(withJSONObject: mealPlansArray)
                    if let newPlans = try? JSONDecoder().decode([MealPlanModel].self, from: jsonData) {
                        if selectedMergeMode == .replace {
                            let encoded = try JSONEncoder().encode(newPlans)
                            UserDefaults.standard.set(encoded, forKey: "mealPlans")
                        } else {
                            if let existingData = UserDefaults.standard.data(forKey: "mealPlans"),
                               var existingPlans = try? JSONDecoder().decode([MealPlanModel].self, from: existingData) {
                                existingPlans.append(contentsOf: newPlans)
                                let encoded = try JSONEncoder().encode(existingPlans)
                                UserDefaults.standard.set(encoded, forKey: "mealPlans")
                            }
                        }
                    }
                }
                
                // Import notes
                if let notes = json["recipeNotes"] as? [String: String] {
                    if selectedMergeMode == .replace {
                        let encoded = try JSONEncoder().encode(notes)
                        UserDefaults.standard.set(encoded, forKey: "recipeNotes")
                    } else {
                        if let existingData = UserDefaults.standard.data(forKey: "recipeNotes"),
                           var existingNotes = try? JSONDecoder().decode([String: String].self, from: existingData) {
                            existingNotes.merge(notes) { _, new in new }
                            let encoded = try JSONEncoder().encode(existingNotes)
                            UserDefaults.standard.set(encoded, forKey: "recipeNotes")
                        }
                    }
                }
                
                DispatchQueue.main.async {
                    self.isImporting = false
                    self.importResult = .success("Data imported successfully!")
                    HapticManager.shared.success()
                    
                    // Auto-dismiss after 2 seconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        dismiss()
                    }
                }
                
            } catch {
                DispatchQueue.main.async {
                    self.isImporting = false
                    self.importResult = .error("Failed to import: \(error.localizedDescription)")
                    HapticManager.shared.error()
                }
            }
        }
    }
}

// MARK: - Supporting Components

struct ProfileTextField: View {
    let icon: String
    let label: String
    @Binding var text: String
    let placeholder: String
    let colorScheme: ColorScheme
    
    var body: some View {
        HStack(spacing: AppTheme.spacing16) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.secondary)
                .frame(width: 28)
            
            VStack(alignment: .leading, spacing: AppTheme.spacing4) {
                Text(label)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                TextField(placeholder, text: $text)
                    .adaptiveForegroundColor()
                    .autocapitalization(.words)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }
}

struct ChefTypeCard: View {
    let chefType: ChefType
    let isSelected: Bool
    let selectedTheme: AppTheme.ThemeType
    let action: () -> Void
    
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: AppTheme.spacing8) {
                Image(systemName: chefType.icon)
                    .font(.system(size: AppTheme.fontSize32))
                    .foregroundColor(isSelected ? AppTheme.accentColor(for: selectedTheme) : .secondary)
                
                Text(chefType.rawValue)
                    .font(.caption)
                    .fontWeight(isSelected ? .semibold : .regular)
                    .adaptiveForegroundColor()
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background {
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? AppTheme.accentColor(for: selectedTheme).opacity(0.15) : Color.secondary.opacity(0.1))
            }
            .overlay {
                if isSelected {
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(AppTheme.accentColor(for: selectedTheme), lineWidth: 2)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct BadgeCard: View {
    let badge: Badge
    let colorScheme: ColorScheme
    let cardStyle: CardStyle
    
    var badgeColor: Color {
        switch badge.color {
        case "purple": return .purple
        case "green": return .green
        case "mint": return .mint
        case "blue": return .blue
        case "orange": return .orange
        case "yellow": return .yellow
        case "gold": return .yellow
        case "teal": return .teal
        case "indigo": return .indigo
        default: return .gray
        }
    }
    
    var body: some View {
        VStack(spacing: AppTheme.spacing8) {
            ZStack {
                Circle()
                    .fill(badge.isUnlocked ? badgeColor.opacity(0.2) : AppTheme.secondaryText.opacity(0.1))
                    .frame(width: 60, height: 60)
                
                Image(systemName: badge.icon)
                    .font(.system(size: AppTheme.fontSize28))
                    .foregroundColor(badge.isUnlocked ? badgeColor : .gray.opacity(0.5))
            }
            
            Text(badge.title.components(separatedBy: " ").first ?? badge.title)
                .font(.caption2)
                .fontWeight(.semibold)
                .foregroundColor(badge.isUnlocked ? (AppTheme.adaptiveEmphasis(for: colorScheme)) : .gray)
                .lineLimit(1)
            
            if badge.isUnlocked, let date = badge.dateEarned {
                Text(date.formatted(date: .abbreviated, time: .omitted))
                    .font(.system(size: AppTheme.fontSize11))
                    .foregroundColor(.secondary)
            } else {
                Text("Locked")
                    .font(.system(size: AppTheme.fontSize11))
                    .foregroundColor(.gray)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background {
            if cardStyle == .solid {
                RoundedRectangle(cornerRadius: 12)
                    .fill(colorScheme == .dark ? Color(white: 0.1) : Color.white.opacity(AppTheme.glassLightOpacity))
            } else {
                RoundedRectangle(cornerRadius: 12)
                    .fill(.ultraThinMaterial.opacity(0.5))
            }
        }
        .overlay {
            if !badge.isUnlocked {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.black.opacity(AppTheme.shadowDarkOpacity))
            }
        }
    }
}

// MARK: - Badge Detail View

struct BadgeDetailView: View {
    let badge: Badge
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    @AppStorage("appTheme") private var selectedTheme: AppTheme.ThemeType = .teal
    @AppStorage("cardStyle") private var cardStyle: CardStyle = .frosted
    
    var badgeColor: Color {
        switch badge.color {
        case "purple": return .purple
        case "green": return .green
        case "mint": return .mint
        case "blue": return .blue
        case "orange": return .orange
        case "yellow": return .yellow
        case "gold": return .yellow
        case "teal": return .teal
        case "indigo": return .indigo
        default: return .gray
        }
    }
    
    var body: some View {
        ZStack {
            AppTheme.backgroundGradient(for: selectedTheme, colorScheme: colorScheme)
                .ignoresSafeArea()
            
            VStack(spacing: AppTheme.spacing32) {
                // Close button
                HStack {
                    Spacer()
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .adaptiveForegroundColor(opacity: 0.7)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                
                Spacer()
                
                // Badge Icon
                ZStack {
                    Circle()
                        .fill(badge.isUnlocked ? badgeColor.opacity(0.2) : AppTheme.secondaryText.opacity(0.1))
                        .frame(width: 120, height: 120)
                    
                    Image(systemName: badge.icon)
                        .font(.system(size: AppTheme.fontSize60))
                        .foregroundColor(badge.isUnlocked ? badgeColor : .gray.opacity(0.5))
                }
                .shadow(color: badge.isUnlocked ? badgeColor.opacity(0.3) : .clear, radius: 20)
                
                // Title
                Text(badge.title)
                    .font(.system(size: AppTheme.fontSize28, weight: .bold))
                    .adaptiveForegroundColor()
                    .multilineTextAlignment(.center)
                
                // Description
                Text(badge.description)
                    .font(.title3)
                    .adaptiveForegroundColor(opacity: 0.8)
                    .multilineTextAlignment(.center)
                
                // Status/Date
                if badge.isUnlocked, let date = badge.dateEarned {
                    VStack(spacing: AppTheme.spacing8) {
                        HStack(spacing: AppTheme.spacing8) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("Unlocked!")
                                .fontWeight(.semibold)
                                .foregroundColor(.green)
                        }
                        .font(.headline)
                        
                        Text("Earned on \(date.formatted(date: .long, time: .omitted))")
                            .font(.subheadline)
                            .adaptiveForegroundColor(opacity: 0.6)
                    }
                    .padding()
                    .background {
                        if cardStyle == .solid {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(AppTheme.adaptiveCard(for: colorScheme))
                        } else {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(.ultraThinMaterial)
                        }
                    }
                } else {
                    VStack(spacing: AppTheme.spacing8) {
                        HStack(spacing: AppTheme.spacing8) {
                            Image(systemName: "lock.fill")
                                .foregroundColor(.gray)
                            Text("Locked")
                                .fontWeight(.semibold)
                                .foregroundColor(.gray)
                        }
                        .font(.headline)
                        
                        if !badge.howToEarn.isEmpty {
                            Divider()
                                .padding(.vertical, 4)
                            
                            VStack(alignment: .leading, spacing: AppTheme.spacing8) {
                                Text("How to Earn:")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .adaptiveForegroundColor(opacity: 0.6)
                                    .textCase(.uppercase)
                                
                                Text(badge.howToEarn)
                                    .font(.subheadline)
                                    .adaptiveForegroundColor(opacity: 0.8)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background {
                        if cardStyle == .solid {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(AppTheme.adaptiveCard(for: colorScheme))
                        } else {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(.ultraThinMaterial)
                        }
                    }
                }
                
                Spacer()
                Spacer()
            }
            .padding(.horizontal, 20)
        }
    }
}
