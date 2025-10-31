import SwiftUI
import AuthenticationServices

struct AccountView: View {
    @StateObject private var accountManager = AccountManager.shared
    @StateObject private var authManager = AuthenticationManager.shared
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("appTheme") private var selectedTheme: AppTheme.ThemeType = .teal
    @AppStorage("cardStyle") private var cardStyle: CardStyle = .frosted
    
    @State private var showingEditProfile = false
    @State private var showingSignOutAlert = false
    @State private var showingDeleteAccountAlert = false
    @State private var showingPrivacyPolicy = false
    @State private var showingDataDownload = false
    @State private var showingAuthError = false
    @State private var authErrorMessage = ""
    
    private var isGuestMode: Bool {
        authManager.isGuestMode
    }
    
    private var displayName: String {
        if let user = authManager.currentUser {
            return user.displayName
        }
        return accountManager.fullName
    }
    
    private var displayEmail: String {
        if let user = authManager.currentUser {
            return user.email ?? ""
        }
        return accountManager.email
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
            
            ScrollView {
                VStack(spacing: 20) {
                    // Profile Card
                    profileCard
                    
                    // Quick Actions
                    if !isGuestMode {
                        quickActionsSection
                    }
                    
                    // Privacy Section
                    privacySection
                    
                    // Account Actions
                    accountActionsSection
                }
                .padding(.top, 20)
                .padding(.horizontal, 20)
                .padding(.bottom, 100)
            }
        }
        .navigationTitle("Account")
        .navigationBarTitleDisplayMode(.large)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .sheet(isPresented: $showingEditProfile) {
            EditProfileView()
        }
        .sheet(isPresented: $showingPrivacyPolicy) {
            PrivacyPolicyView()
        }
        .sheet(isPresented: $showingDataDownload) {
            DataDownloadView()
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
    }
    
    // Profile Card
    
    private var profileCard: some View {
        VStack(spacing: 16) {
            // Avatar
            ZStack {
                Circle()
                    .fill(AppTheme.accentColor(for: selectedTheme))
                    .frame(width: 80, height: 80)
                
                Text(displayInitials)
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.white)
            }
            
            // Name
            Text(displayName)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(colorScheme == .dark ? .white : .primary)
            
            // Chef Badge
            HStack(spacing: 6) {
                Image(systemName: accountManager.chefType.icon)
                    .font(.caption)
                Text(accountManager.chefType.rawValue)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(AppTheme.accentColor(for: selectedTheme).opacity(0.15))
            .foregroundColor(AppTheme.accentColor(for: selectedTheme))
            .cornerRadius(20)
            
            // Edit Button
            if !isGuestMode {
                Button {
                    showingEditProfile = true
                    HapticManager.shared.light()
                } label: {
                    Text("Edit Profile")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(AppTheme.accentColor(for: selectedTheme))
                        .padding(.horizontal, 24)
                        .padding(.vertical, 10)
                        .background(AppTheme.accentColor(for: selectedTheme).opacity(0.15))
                        .cornerRadius(20)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background {
            if cardStyle == .solid {
                RoundedRectangle(cornerRadius: 20)
                    .fill(colorScheme == .dark ? Color(white: 0.15) : Color.white)
            } else {
                RoundedRectangle(cornerRadius: 20)
                    .fill(.ultraThinMaterial)
            }
        }
    }
    
    // Quick Actions
    
    private var quickActionsSection: some View {
        VStack(spacing: 0) {
            ActionButton(
                icon: "person.fill",
                title: "Personal Info",
                subtitle: displayName,
                action: { showingEditProfile = true }
            )
            
            if !displayEmail.isEmpty {
                Divider()
                    .padding(.leading, 60)
                
                ActionButton(
                    icon: "envelope.fill",
                    title: "Email",
                    subtitle: displayEmail,
                    action: {}
                )
            }
        }
        .background {
            if cardStyle == .solid {
                RoundedRectangle(cornerRadius: 16)
                    .fill(colorScheme == .dark ? Color(white: 0.15) : Color.white)
            } else {
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
            }
        }
    }
    
    // Privacy Section
    
    private var privacySection: some View {
        VStack(spacing: 0) {
            ActionButton(
                icon: "hand.raised.fill",
                iconColor: .blue,
                title: "Privacy Policy",
                showChevron: true,
                action: { showingPrivacyPolicy = true }
            )
            
            Divider()
                .padding(.leading, 60)
            
            ActionButton(
                icon: "square.and.arrow.down",
                iconColor: .green,
                title: "Download Your Data",
                showChevron: true,
                action: { showingDataDownload = true }
            )
            
            Divider()
                .padding(.leading, 60)
            
            NavigationLink {
                DataPrivacyView()
            } label: {
                ActionButton(
                    icon: "shield.fill",
                    iconColor: .purple,
                    title: "Data & Privacy",
                    showChevron: true,
                    action: {}
                )
            }
        }
        .background {
            if cardStyle == .solid {
                RoundedRectangle(cornerRadius: 16)
                    .fill(colorScheme == .dark ? Color(white: 0.15) : Color.white)
            } else {
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
            }
        }
    }
    
    // Account Actions
    
    private var accountActionsSection: some View {
        VStack(spacing: 12) {
            Button {
                showingSignOutAlert = true
                HapticManager.shared.light()
            } label: {
                Text(isGuestMode ? "Exit Guest Mode" : "Sign Out")
                    .font(.body)
                    .fontWeight(.semibold)
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background {
                        if cardStyle == .solid {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(colorScheme == .dark ? Color(white: 0.15) : Color.white)
                        } else {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(.ultraThinMaterial)
                        }
                    }
            }
            
            if !isGuestMode {
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
                                    .fill(colorScheme == .dark ? Color(white: 0.15) : Color.white)
                            } else {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(.ultraThinMaterial)
                            }
                        }
                }
            }
        }
    }
    
    // Helper Functions
    
    private func signOut() {
        #if DEBUG
        print("🔓 [AccountView] Sign out button tapped")
        #endif
        authManager.signOut()
        // Navigation handled automatically by app root view
    }
    
    private func deleteAccount() async {
        do {
            #if DEBUG
            print("🗑️ [AccountView] Delete account requested")
            #endif
            try await authManager.deleteAccount()
            // Navigation handled automatically by app root view
        } catch {
            print("Error deleting account: \(error)")
        }
    }
}

// Action Button Component

struct ActionButton: View {
    let icon: String
    var iconColor: Color?
    let title: String
    var subtitle: String?
    var showChevron: Bool = false
    let action: () -> Void
    
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(iconColor ?? (colorScheme == .dark ? .white : .primary))
                    .frame(width: 28)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.body)
                        .foregroundColor(colorScheme == .dark ? .white : .primary)
                    
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                if showChevron {
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
    }
}

// Privacy Policy View

struct PrivacyPolicyView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Privacy Policy")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Last updated: \(Date().formatted(date: .long, time: .omitted))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("""
                    RecipeFinder is committed to protecting your privacy and complying with UK GDPR and Data Protection Act 2018.
                    
                    **Data We Collect:**
                    • Account information (name, email)
                    • Recipe data and preferences
                    • App usage information
                    
                    **How We Use Your Data:**
                    • To provide and improve our services
                    • To personalize your experience
                    • To communicate with you about the app
                    
                    **Your Rights:**
                    • Access your personal data
                    • Request data correction or deletion
                    • Export your data
                    • Withdraw consent
                    
                    **Data Security:**
                    All data is encrypted and stored securely on your device. We do not share your personal information with third parties.
                    
                    **Contact:**
                    For privacy concerns, contact us within the app.
                    """)
                    .font(.body)
                }
                .padding()
            }
            .navigationTitle("Privacy Policy")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

struct DataDownloadView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var isExporting = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Image(systemName: "arrow.down.doc.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
                
                Text("Download Your Data")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("In compliance with GDPR, you can download all your personal data. This includes recipes, preferences, and account information.")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                
                Button {
                    exportData()
                } label: {
                    HStack {
                        if isExporting {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Image(systemName: "square.and.arrow.down")
                            Text("Download Data (JSON)")
                        }
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
                }
                .disabled(isExporting)
                .padding(.horizontal)
                
                Spacer()
            }
            .padding(.top, 40)
            .navigationTitle("Data Export")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
    
    private func exportData() {
        isExporting = true
        // Implement actual export logic
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            isExporting = false
            dismiss()
        }
    }
}

struct DataPrivacyView: View {
    var body: some View {
        List {
            Section("Data Collection") {
                Toggle("Share Usage Data", isOn: .constant(false))
                Toggle("Personalized Recommendations", isOn: .constant(true))
            }
            
            Section("Data Storage") {
                Text("All data is stored locally on your device")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Section(footer: Text("Changes to these settings will take effect immediately.")) {
                EmptyView()
            }
        }
        .navigationTitle("Data & Privacy")
        .navigationBarTitleDisplayMode(.inline)
    }
}
