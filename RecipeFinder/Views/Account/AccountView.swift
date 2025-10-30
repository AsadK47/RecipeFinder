import SwiftUI

struct AccountView: View {
    @StateObject private var accountManager = AccountManager.shared
    @State private var showingEditProfile = false
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.appTheme) var appTheme
    @AppStorage("cardStyle") private var cardStyle: CardStyle = .frosted
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.backgroundGradient(for: appTheme, colorScheme: colorScheme)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Profile Header
                        profileHeader
                        
                        // Stats Section
                        statsSection
                        
                        // Account Actions
                        accountActionsSection
                        
                        // Data Management
                        dataManagementSection
                        
                        // About Section
                        aboutSection
                    }
                    .padding(.vertical, 20)
                    .padding(.horizontal, 20)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Account")
                        .font(.system(size: 34, weight: .bold))
                        .foregroundColor(.white)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingEditProfile = true }) {
                        Image(systemName: "pencil.circle")
                            .font(.title3)
                            .foregroundColor(.white)
                    }
                }
            }
            .sheet(isPresented: $showingEditProfile) {
                EditProfileSheet(accountManager: accountManager)
            }
        }
    }
    
    // MARK: - Profile Header
    private var profileHeader: some View {
        VStack(spacing: 16) {
            // Avatar
            Circle()
                .fill(AppTheme.accentColor(for: appTheme))
                .frame(width: 100, height: 100)
                .overlay(
                    Text(accountManager.initials)
                        .font(.system(size: 40, weight: .bold))
                        .foregroundColor(.white)
                )
                .shadow(color: AppTheme.accentColor(for: appTheme).opacity(0.3), radius: 10)
            
            VStack(spacing: 4) {
                Text(accountManager.fullName)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                HStack(spacing: 6) {
                    Image(systemName: accountManager.chefType.icon)
                        .font(.caption)
                    Text(accountManager.chefType.rawValue)
                        .font(.subheadline)
                }
                .foregroundColor(.white.opacity(0.8))
                
                if !accountManager.email.isEmpty {
                    Text(accountManager.email)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
    }
    
    // MARK: - Stats Section
    private var statsSection: some View {
        HStack(spacing: 16) {
            StatCard(
                title: "Recipes",
                value: "\(accountManager.recipeCount)",
                icon: "book.fill",
                color: .purple
            )
            
            StatCard(
                title: "Kitchen Items",
                value: "\(accountManager.kitchenItemCount)",
                icon: "refrigerator.fill",
                color: .green
            )
            
            StatCard(
                title: "Shopping List",
                value: "\(accountManager.shoppingListCount)",
                icon: "cart.fill",
                color: .orange
            )
        }
    }
    
    // MARK: - Account Actions
    private var accountActionsSection: some View {
        VStack(spacing: 12) {
            SectionHeader(title: "Account", icon: "person.fill")
            
            AccountActionCard(
                title: "Edit Profile",
                subtitle: "Update your personal information",
                icon: "person.circle",
                iconColor: .blue,
                action: { showingEditProfile = true }
            )
            
            // Profile Details Card
            VStack(spacing: 0) {
                if !accountManager.uuid.isEmpty {
                    ProfileDetailRow(icon: "number", label: "UUID", value: String(accountManager.uuid.prefix(8)) + "...")
                    Divider().padding(.leading, 52)
                }
                
                if !accountManager.address.isEmpty {
                    ProfileDetailRow(icon: "location.fill", label: "Address", value: accountManager.address)
                    Divider().padding(.leading, 52)
                }
                
                ProfileDetailRow(icon: accountManager.chefType.icon, label: "Chef Type", value: accountManager.chefType.rawValue)
            }
            .background {
                if cardStyle == .solid {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(colorScheme == .dark ? AppTheme.cardBackgroundDark : AppTheme.cardBackground)
                } else {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.regularMaterial)
                }
            }
            
            AccountActionCard(
                title: "Preferences",
                subtitle: "Manage app settings",
                icon: "slider.horizontal.3",
                iconColor: .purple,
                destination: AnyView(SettingsView())
            )
        }
    }
    
    // MARK: - Data Management
    private var dataManagementSection: some View {
        VStack(spacing: 12) {
            SectionHeader(title: "Data", icon: "externaldrive.fill")
            
            AccountActionCard(
                title: "Export Data",
                subtitle: "Save your recipes and lists",
                icon: "square.and.arrow.up",
                iconColor: .green,
                action: { accountManager.exportData() }
            )
            
            AccountActionCard(
                title: "Clear All Data",
                subtitle: "Reset app to default state",
                icon: "trash.fill",
                iconColor: .red,
                showAlert: true,
                action: { accountManager.clearAllData() }
            )
        }
    }
    
    // MARK: - About Section
    private var aboutSection: some View {
        VStack(spacing: 12) {
            SectionHeader(title: "About", icon: "info.circle.fill")
            
            AccountInfoCard(
                title: "Version",
                value: "1.0.0",
                icon: "app.badge"
            )
            
            AccountInfoCard(
                title: "Build",
                value: "2025.10.30",
                icon: "hammer"
            )
        }
    }
}

// MARK: - Supporting Views

struct SectionHeader: View {
    let title: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(.white.opacity(0.6))
            
            Text(title.uppercased())
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.white.opacity(0.6))
            
            Spacer()
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    @Environment(\.colorScheme) var colorScheme
    @AppStorage("cardStyle") private var cardStyle: CardStyle = .frosted
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(colorScheme == .dark ? .white : .black)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background {
            if cardStyle == .solid {
                RoundedRectangle(cornerRadius: 16)
                    .fill(colorScheme == .dark ? AppTheme.cardBackgroundDark : AppTheme.cardBackground)
            } else {
                RoundedRectangle(cornerRadius: 16)
                    .fill(.regularMaterial)
            }
        }
    }
}

struct AccountActionCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let iconColor: Color
    var destination: AnyView?
    var showAlert: Bool = false
    var action: (() -> Void)?
    
    @State private var showingAlert = false
    @Environment(\.colorScheme) var colorScheme
    @AppStorage("cardStyle") private var cardStyle: CardStyle = .frosted
    
    var body: some View {
        Group {
            if let destination = destination {
                NavigationLink(destination: destination) {
                    cardContent
                }
            } else {
                Button(action: {
                    if showAlert {
                        showingAlert = true
                    } else {
                        action?()
                    }
                }) {
                    cardContent
                }
            }
        }
        .alert("Are you sure?", isPresented: $showingAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Confirm", role: .destructive) {
                action?()
            }
        } message: {
            Text("This action cannot be undone.")
        }
    }
    
    private var cardContent: some View {
        HStack(spacing: 16) {
            Circle()
                .fill(iconColor.opacity(0.2))
                .frame(width: 48, height: 48)
                .overlay(
                    Image(systemName: icon)
                        .foregroundColor(iconColor)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(colorScheme == .dark ? .white : .black)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
                .font(.caption)
        }
        .padding(16)
        .background {
            if cardStyle == .solid {
                RoundedRectangle(cornerRadius: 12)
                    .fill(colorScheme == .dark ? AppTheme.cardBackgroundDark : AppTheme.cardBackground)
            } else {
                RoundedRectangle(cornerRadius: 12)
                    .fill(.regularMaterial)
            }
        }
    }
}

struct AccountInfoCard: View {
    let title: String
    let value: String
    let icon: String
    @Environment(\.colorScheme) var colorScheme
    @AppStorage("cardStyle") private var cardStyle: CardStyle = .frosted
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .foregroundColor(.gray)
                .font(.title3)
            
            Text(title)
                .font(.body)
                .foregroundColor(colorScheme == .dark ? .white : .black)
            
            Spacer()
            
            Text(value)
                .font(.body)
                .foregroundColor(.gray)
        }
        .padding(16)
        .background {
            if cardStyle == .solid {
                RoundedRectangle(cornerRadius: 12)
                    .fill(colorScheme == .dark ? AppTheme.cardBackgroundDark : AppTheme.cardBackground)
            } else {
                RoundedRectangle(cornerRadius: 12)
                    .fill(.regularMaterial)
            }
        }
    }
}

// MARK: - Edit Profile Sheet

struct EditProfileSheet: View {
    @ObservedObject var accountManager: AccountManager
    @State private var firstName: String = ""
    @State private var middleName: String = ""
    @State private var lastName: String = ""
    @State private var email: String = ""
    @State private var address: String = ""
    @State private var chefType: ChefType = .homeCook
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(colorScheme == .dark ? .black : .white)
                    .ignoresSafeArea()
                
                Form {
                    Section("Basic Information") {
                        TextField("First Name", text: $firstName)
                        TextField("Middle Name (Optional)", text: $middleName)
                        TextField("Last Name", text: $lastName)
                    }
                    
                    Section("Contact Information") {
                        TextField("Email", text: $email)
                            .keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never)
                        
                        TextField("Address", text: $address, axis: .vertical)
                            .lineLimit(3...5)
                    }
                    
                    Section("Chef Profile") {
                        Picker("Chef Type", selection: $chefType) {
                            ForEach(ChefType.allCases, id: \.self) { type in
                                HStack {
                                    Image(systemName: type.icon)
                                    Text(type.rawValue)
                                }
                                .tag(type)
                            }
                        }
                        .pickerStyle(.navigationLink)
                        
                        if chefType != .homeCook {
                            HStack {
                                Image(systemName: "info.circle")
                                    .foregroundColor(.blue)
                                Text(chefType.description)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    
                    Section("Account ID") {
                        HStack {
                            Text("UUID")
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(accountManager.uuid)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                                .truncationMode(.middle)
                        }
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        accountManager.updateProfile(
                            firstName: firstName,
                            middleName: middleName,
                            lastName: lastName,
                            email: email,
                            address: address,
                            chefType: chefType
                        )
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(firstName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .onAppear {
                firstName = accountManager.firstName
                middleName = accountManager.middleName
                lastName = accountManager.lastName
                email = accountManager.email
                address = accountManager.address
                chefType = accountManager.chefType
            }
        }
    }
}

// MARK: - Profile Detail Row

struct ProfileDetailRow: View {
    let icon: String
    let label: String
    let value: String
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.gray)
                .font(.body)
                .frame(width: 24)
            
            Text(label)
                .font(.body)
                .foregroundColor(colorScheme == .dark ? .white.opacity(0.8) : .black.opacity(0.7))
            
            Spacer()
            
            Text(value)
                .font(.body)
                .foregroundColor(colorScheme == .dark ? .white : .black)
                .lineLimit(1)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

#Preview {
    AccountView()
        .environment(\.appTheme, .teal)
}
