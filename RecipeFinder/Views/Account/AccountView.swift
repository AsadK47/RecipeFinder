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
                Text(accountManager.name)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                if !accountManager.email.isEmpty {
                    Text(accountManager.email)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))
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
                subtitle: "Update your name and email",
                icon: "person.circle",
                iconColor: .blue,
                action: { showingEditProfile = true }
            )
            
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
    var destination: AnyView? = nil
    var showAlert: Bool = false
    var action: (() -> Void)? = nil
    
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
    @State private var name: String = ""
    @State private var email: String = ""
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(colorScheme == .dark ? .black : .white)
                    .ignoresSafeArea()
                
                Form {
                    Section("Profile Information") {
                        TextField("Name", text: $name)
                        TextField("Email", text: $email)
                            .keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never)
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
                        accountManager.updateProfile(name: name, email: email)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .onAppear {
                name = accountManager.name
                email = accountManager.email
            }
        }
    }
}

#Preview {
    AccountView()
        .environment(\.appTheme, .teal)
}
