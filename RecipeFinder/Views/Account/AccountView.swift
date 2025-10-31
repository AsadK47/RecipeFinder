import SwiftUI

/// Account view following Apple's native iOS Settings design patterns
/// Uses grouped list style with native navigation and animations
struct AccountView: View {
    @StateObject private var accountManager = AccountManager.shared
    @StateObject private var authManager = AuthenticationManager.shared
    @State private var showingEditProfile = false
    @State private var showingDeleteAlert = false
    @State private var showingSignOutAlert = false
    @State private var showingDeleteAccountAlert = false
    @State private var showingUpgradeFromGuest = false
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("appTheme") private var selectedTheme: AppTheme.ThemeType = .teal
    @AppStorage("cardStyle") private var cardStyle: CardStyle = .frosted
    
    // Check if user is in guest mode
    private var isGuestMode: Bool {
        UserDefaults.standard.bool(forKey: "isGuestMode")
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Themed background gradient
                AppTheme.backgroundGradient(for: selectedTheme, colorScheme: colorScheme)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Header
                        Text("Account")
                            .font(.system(size: 34, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 20)
                            .padding(.top, 20)
                        
                        VStack(spacing: 16) {
                            // Profile Header Card
                            CardView {
                                profileHeaderRow
                            }
                            
                            // Stats Grid Card
                            CardView {
                                statsGrid
                                    .padding(.vertical, 8)
                            }
                            
                            // Profile Details (if not default user)
                            if accountManager.fullName != "Recipe Chef" {
                                CardView {
                                    VStack(spacing: 0) {
                                        sectionHeader("Profile Information")
                                        
                                        DetailRow(
                                            label: "Name",
                                            value: accountManager.fullName,
                                            icon: "person.fill"
                                        )
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 12)
                                        
                                        Divider()
                                            .padding(.horizontal, 16)
                                        
                                        if !accountManager.email.isEmpty {
                                            DetailRow(
                                                label: "Email",
                                                value: accountManager.email,
                                                icon: "envelope.fill"
                                            )
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 12)
                                            
                                            Divider()
                                                .padding(.horizontal, 16)
                                        }
                                        
                                        DetailRow(
                                            label: "Chef Type",
                                            value: accountManager.chefType.rawValue,
                                            icon: accountManager.chefType.icon
                                        )
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 12)
                                        
                                        if !accountManager.address.isEmpty {
                                            Divider()
                                                .padding(.horizontal, 16)
                                            
                                            DetailRow(
                                                label: "Address",
                                                value: accountManager.address,
                                                icon: "location.fill"
                                            )
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 12)
                                        }
                                    }
                                }
                            }
                            
                            // Settings Card
                            CardView {
                                VStack(spacing: 0) {
                                    sectionHeader("Settings")
                                    
                                    NavigationLink {
                                        SettingsTabView()
                                    } label: {
                                        SettingsRowLabel(
                                            icon: "gear",
                                            iconColor: AppTheme.accentColor(for: selectedTheme),
                                            title: "Preferences"
                                        )
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 12)
                                    }
                                }
                            }
                            
                            // Data Management Card
                            CardView {
                                VStack(spacing: 0) {
                                    sectionHeader("Data")
                                    
                                    Button {
                                        exportData()
                                    } label: {
                                        SettingsRowLabel(
                                            icon: "square.and.arrow.up",
                                            iconColor: .blue,
                                            title: "Export Data"
                                        )
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 12)
                                    }
                                    
                                    Divider()
                                        .padding(.horizontal, 16)
                                    
                                    Button(role: .destructive) {
                                        showingDeleteAlert = true
                                    } label: {
                                        SettingsRowLabel(
                                            icon: "trash",
                                            iconColor: .red,
                                            title: "Clear All Data"
                                        )
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 12)
                                    }
                                    
                                    Text("Clearing all data will reset the app to its default state and restore sample recipes.")
                                        .font(.caption)
                                        .foregroundStyle(.white.opacity(0.7))
                                        .padding(.horizontal, 16)
                                        .padding(.top, 8)
                                        .padding(.bottom, 12)
                                    
                                    if !accountManager.uuid.isEmpty {
                                        Text("Account ID: \(accountManager.uuid)")
                                            .font(.caption2)
                                            .foregroundStyle(.white.opacity(0.5))
                                            .padding(.horizontal, 16)
                                            .padding(.bottom, 12)
                                    }
                                }
                            }
                            
                            // Account Actions Card
                            CardView {
                                VStack(spacing: 0) {
                                    sectionHeader("Account")
                                    
                                    // Show "Create Account" if in guest mode
                                    if isGuestMode {
                                        Button {
                                            showingUpgradeFromGuest = true
                                        } label: {
                                            HStack {
                                                Spacer()
                                                Label("Create Account", systemImage: "person.badge.plus")
                                                    .fontWeight(.semibold)
                                                    .foregroundStyle(.green)
                                                Spacer()
                                            }
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 12)
                                        }
                                        
                                        Divider()
                                            .padding(.horizontal, 16)
                                    }
                                    
                                    Button {
                                        showingSignOutAlert = true
                                    } label: {
                                        HStack {
                                            Spacer()
                                            Text(isGuestMode ? "Exit Guest Mode" : "Sign Out")
                                                .fontWeight(.semibold)
                                                .foregroundStyle(.red)
                                            Spacer()
                                        }
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 12)
                                    }
                                    
                                    if !isGuestMode {
                                        Divider()
                                            .padding(.horizontal, 16)
                                        
                                        Button(role: .destructive) {
                                            showingDeleteAccountAlert = true
                                        } label: {
                                            HStack {
                                                Spacer()
                                                Text("Delete Account")
                                                    .fontWeight(.semibold)
                                                Spacer()
                                            }
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 12)
                                        }
                                    }
                                    
                                    if isGuestMode {
                                        Text("You're currently using guest mode. Create an account to sync your data and access all features.")
                                            .font(.caption)
                                            .foregroundStyle(.white.opacity(0.7))
                                            .padding(.horizontal, 16)
                                            .padding(.top, 8)
                                            .padding(.bottom, 12)
                                    } else {
                                        Text("Deleting your account will permanently remove all your data and cannot be undone.")
                                            .font(.caption)
                                            .foregroundStyle(.white.opacity(0.7))
                                            .padding(.horizontal, 16)
                                            .padding(.top, 8)
                                            .padding(.bottom, 12)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 100)
                    }
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showingEditProfile) {
                EditProfileSheet(accountManager: accountManager)
            }
            .sheet(isPresented: $showingUpgradeFromGuest) {
                SignUpView()
            }
            .alert("Clear All Data?", isPresented: $showingDeleteAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Clear", role: .destructive) {
                    withAnimation {
                        accountManager.clearAllData()
                    }
                    HapticManager.shared.success()
                }
            } message: {
                Text("This will delete all your data and restore sample recipes. This action cannot be undone.")
            }
            .alert("Sign Out?", isPresented: $showingSignOutAlert) {
                Button("Cancel", role: .cancel) { }
                Button(isGuestMode ? "Exit" : "Sign Out", role: .destructive) {
                    if isGuestMode {
                        UserDefaults.standard.set(false, forKey: "isGuestMode")
                    }
                    authManager.signOut()
                    HapticManager.shared.success()
                }
            } message: {
                if isGuestMode {
                    Text("Exit guest mode? Your local data will remain on this device.")
                } else {
                    Text("Are you sure you want to sign out?")
                }
            }
            .alert("Delete Account?", isPresented: $showingDeleteAccountAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    Task {
                        try? await authManager.deleteAccount()
                        HapticManager.shared.success()
                    }
                }
            } message: {
                Text("This will permanently delete your account and all associated data. This action cannot be undone.")
            }
        }
    }
    
    // MARK: - Section Header
    
    @ViewBuilder
    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.subheadline)
            .fontWeight(.semibold)
            .foregroundStyle(.white.opacity(0.7))
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 8)
    }
    
    // MARK: - Profile Header Row
    
    private var profileHeaderRow: some View {
        Button {
            showingEditProfile = true
        } label: {
            HStack(spacing: 16) {
                // Avatar Circle with theme colors
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                AppTheme.accentColor(for: selectedTheme),
                                AppTheme.accentColor(for: selectedTheme).opacity(0.7)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 72, height: 72)
                    .overlay {
                        Text(accountManager.initials)
                            .font(.system(size: 28, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(accountManager.fullName)
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundStyle(colorScheme == .dark ? .white : .primary)
                        
                        if isGuestMode {
                            Text("GUEST")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundStyle(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(
                                    Capsule()
                                        .fill(.orange.gradient)
                                )
                        }
                    }
                    
                    HStack(spacing: 4) {
                        Image(systemName: accountManager.chefType.icon)
                            .font(.caption)
                        Text(accountManager.chefType.rawValue)
                            .font(.subheadline)
                    }
                    .foregroundStyle(colorScheme == .dark ? .white.opacity(0.7) : .secondary)
                    
                    Text("Edit Profile")
                        .font(.callout)
                        .foregroundStyle(AppTheme.accentColor(for: selectedTheme))
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(colorScheme == .dark ? .white.opacity(0.5) : .gray)
            }
            .padding(16)
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Stats Grid
    
    private var statsGrid: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                StatTile(
                    title: "Recipes",
                    value: "\(accountManager.recipeCount)",
                    icon: "book.fill",
                    color: .orange,
                    colorScheme: colorScheme
                )
                
                StatTile(
                    title: "Kitchen",
                    value: "\(accountManager.kitchenItemCount)",
                    icon: "refrigerator.fill",
                    color: .green,
                    colorScheme: colorScheme
                )
            }
            
            HStack(spacing: 12) {
                StatTile(
                    title: "Shopping",
                    value: "\(accountManager.shoppingListCount)",
                    icon: "cart.fill",
                    color: .blue,
                    colorScheme: colorScheme
                )
                
                StatTile(
                    title: "Level",
                    value: accountManager.chefType == .homeCook ? "Beginner" : "Expert",
                    icon: "star.fill",
                    color: AppTheme.accentColor(for: selectedTheme),
                    colorScheme: colorScheme
                )
            }
        }
        .padding(4)
    }
    
    // MARK: - Helper Methods
    
    private func exportData() {
        accountManager.exportData()
        HapticManager.shared.success()
    }
}

// MARK: - Supporting Views

/// Native iOS Settings-style row label with colored icon
struct SettingsRowLabel: View {
    let icon: String
    let iconColor: Color
    let title: String
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(iconColor)
                    .frame(width: 28, height: 28)
                
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.white)
            }
            
            Text(title)
                .foregroundStyle(.primary)
        }
    }
}

/// Detail row showing label-value pairs
struct DetailRow: View {
    let label: String
    let value: String
    let icon: String
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack {
            Label {
                Text(label)
                    .foregroundStyle(colorScheme == .dark ? .white : .primary)
            } icon: {
                Image(systemName: icon)
                    .foregroundStyle(.blue)
                    .frame(width: 20)
            }
            
            Spacer()
            
            Text(value)
                .foregroundStyle(colorScheme == .dark ? .white.opacity(0.7) : .secondary)
                .lineLimit(1)
        }
    }
}

/// Stat tile showing metric with icon and color
struct StatTile: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    let colorScheme: ColorScheme
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(color.opacity(0.2))
                    .frame(width: 48, height: 48)
                
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundStyle(color)
            }
            
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundStyle(colorScheme == .dark ? .white : .primary)
            
            Text(title)
                .font(.caption)
                .foregroundStyle(colorScheme == .dark ? .white.opacity(0.7) : .secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(colorScheme == .dark ? Color(white: 0.15) : .white.opacity(0.9))
        }
    }
}

// MARK: - Edit Profile Sheet

/// Native iOS-style profile editor using Form
struct EditProfileSheet: View {
    @ObservedObject var accountManager: AccountManager
    @State private var firstName: String = ""
    @State private var middleName: String = ""
    @State private var lastName: String = ""
    @State private var email: String = ""
    @State private var address: String = ""
    @State private var chefType: ChefType = .homeCook
    @Environment(\.dismiss) private var dismiss
    
    private var canSave: Bool {
        !firstName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var body: some View {
        NavigationStack {
            Form {
                // Name Section
                Section {
                    TextField("First Name", text: $firstName)
                        .textContentType(.givenName)
                    
                    TextField("Middle Name", text: $middleName)
                        .textContentType(.middleName)
                    
                    TextField("Last Name", text: $lastName)
                        .textContentType(.familyName)
                } header: {
                    Text("Name")
                } footer: {
                    Text("Your first name is required.")
                }
                
                // Contact Section
                Section {
                    TextField("Email", text: $email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    
                    TextField("Address", text: $address, axis: .vertical)
                        .textContentType(.fullStreetAddress)
                        .lineLimit(2...4)
                } header: {
                    Text("Contact")
                }
                
                // Chef Profile Section
                Section {
                    Picker("Type", selection: $chefType) {
                        ForEach(ChefType.allCases, id: \.self) { type in
                            Label(type.rawValue, systemImage: type.icon)
                                .tag(type)
                        }
                    }
                } header: {
                    Text("Chef Profile")
                } footer: {
                    Text(chefType.description)
                }
                
                // Account ID Section
                Section {
                    HStack {
                        Text("Account ID")
                            .foregroundStyle(.secondary)
                        
                        Spacer()
                        
                        Text(accountManager.uuid.prefix(8) + "...")
                            .font(.system(.caption, design: .monospaced))
                            .foregroundStyle(.tertiary)
                    }
                } footer: {
                    Text("Your unique account identifier for data management.")
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveProfile()
                    }
                    .fontWeight(.semibold)
                    .disabled(!canSave)
                }
            }
            .onAppear(perform: loadProfile)
        }
    }
    
    private func loadProfile() {
        firstName = accountManager.firstName
        middleName = accountManager.middleName
        lastName = accountManager.lastName
        email = accountManager.email
        address = accountManager.address
        chefType = accountManager.chefType
    }
    
    private func saveProfile() {
        accountManager.updateProfile(
            firstName: firstName,
            middleName: middleName,
            lastName: lastName,
            email: email,
            address: address,
            chefType: chefType
        )
        
        HapticManager.shared.success()
        dismiss()
    }
}

#Preview("Account View") {
    AccountView()
}

#Preview("Edit Profile") {
    EditProfileSheet(accountManager: .shared)
}

