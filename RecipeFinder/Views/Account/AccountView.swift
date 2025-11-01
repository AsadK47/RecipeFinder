import SwiftUI
import AuthenticationServices
import UniformTypeIdentifiers

struct AccountView: View {
    @StateObject private var accountManager = AccountManager.shared
    @StateObject private var authManager = AuthenticationManager.shared
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
    @State private var showingGuestSplash = false
    @State private var showSuccessFeedback = false
    @State private var showImagePicker = false
    @State private var profileImage: UIImage?
    
    // Profile fields from EditProfileView
    @State private var firstName: String = ""
    @State private var middleName: String = ""
    @State private var lastName: String = ""
    @State private var addressLine1: String = ""
    @State private var addressLine2: String = ""
    @State private var city: String = ""
    @State private var county: String = ""
    @State private var postcode: String = ""
    @State private var dateOfBirth: Date?
    @State private var selectedChefType: ChefType = .homeCook
    
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
            AppTheme.backgroundGradient(for: selectedTheme, colorScheme: colorScheme, cardStyle: cardStyle)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header Section
                VStack(spacing: 12) {
                    GeometryReader { geometry in
                        HStack {
                            Spacer()
                            Text("Account")
                                .font(.system(size: min(34, geometry.size.width * 0.085), weight: .bold))
                                .foregroundColor(.white)
                            Spacer()
                        }
                    }
                    .frame(height: 44)
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 8)
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Profile Avatar
                        profileAvatar
                        
                        // Personal Information Section
                        personalInfoSection
                        
                        // Address Section
                        addressSection
                        
                        // Chef Type Section
                        chefTypeSection
                        
                        // Save Button
                        Button(action: {
                            saveProfile()
                        }) {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                Text("Save Profile")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(AppTheme.accentColor(for: selectedTheme))
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        .opacity(showSuccessFeedback ? 0.6 : 1)
                        .disabled(showSuccessFeedback)
                        .padding(.top, 8)
                        
                        // Success Feedback
                        if showSuccessFeedback {
                            HStack(spacing: 8) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                Text("Profile saved successfully!")
                                    .fontWeight(.medium)
                            }
                            .padding()
                            .background(Color.green.opacity(0.1))
                            .cornerRadius(10)
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
        .fullScreenCover(isPresented: $showingGuestSplash) {
            GuestModeSplashView {
                showingGuestSplash = false
            }
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
    }
    
    // MARK: - Profile Avatar
    
    private var profileAvatar: some View {
        VStack(spacing: 12) {
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
                                .font(.system(size: 40, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                    
                    ZStack {
                        Circle()
                            .fill(colorScheme == .dark ? Color(white: 0.15) : .white)
                            .frame(width: 28, height: 28)
                        
                        Image(systemName: "camera.fill")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(AppTheme.accentColor(for: selectedTheme))
                    }
                }
            }
            
            HStack(spacing: 6) {
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
                    .foregroundColor(AppTheme.accentColor(for: selectedTheme))
                Text("Personal Information")
                    .font(.headline)
                    .foregroundColor(colorScheme == .dark ? .white : .black)
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
                    icon: "person.circle.fill",
                    label: "Middle Name",
                    text: $middleName,
                    placeholder: "Optional",
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
                    
                    HStack(spacing: 16) {
                        Image(systemName: "envelope.fill")
                            .font(.title3)
                            .foregroundColor(.secondary)
                            .frame(width: 28)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Email")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text(displayEmail)
                                .foregroundColor(colorScheme == .dark ? .white : .black)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                }
            }
        }
        .background {
            if cardStyle == .solid {
                RoundedRectangle(cornerRadius: 16)
                    .fill(colorScheme == .dark ? Color(white: 0.15) : Color.white.opacity(0.9))
            } else {
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
            }
        }
    }
    
    // MARK: - Address Section
    
    private var addressSection: some View {
        VStack(spacing: 0) {
            HStack {
                Image(systemName: "mappin.and.ellipse")
                    .foregroundColor(AppTheme.accentColor(for: selectedTheme))
                Text("Address")
                    .font(.headline)
                    .foregroundColor(colorScheme == .dark ? .white : .black)
                Spacer()
                Text("Optional")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(Color.secondary.opacity(0.1))
            
            VStack(spacing: 0) {
                ProfileTextField(
                    icon: "house.fill",
                    label: "Address Line 1",
                    text: $addressLine1,
                    placeholder: "House number and street name",
                    colorScheme: colorScheme
                )
                
                Divider()
                    .background(Color.secondary.opacity(0.1))
                    .padding(.leading, 60)
                
                ProfileTextField(
                    icon: "building.2.fill",
                    label: "Address Line 2",
                    text: $addressLine2,
                    placeholder: "Apartment, suite, etc.",
                    colorScheme: colorScheme
                )
                
                Divider()
                    .background(Color.secondary.opacity(0.1))
                    .padding(.leading, 60)
                
                ProfileTextField(
                    icon: "building.columns.fill",
                    label: "Town/City",
                    text: $city,
                    placeholder: "e.g. London",
                    colorScheme: colorScheme
                )
                
                Divider()
                    .background(Color.secondary.opacity(0.1))
                    .padding(.leading, 60)
                
                ProfileTextField(
                    icon: "map.fill",
                    label: "County",
                    text: $county,
                    placeholder: "e.g. Greater London",
                    colorScheme: colorScheme
                )
                
                Divider()
                    .background(Color.secondary.opacity(0.1))
                    .padding(.leading, 60)
                
                ProfileTextField(
                    icon: "envelope.fill",
                    label: "Postcode",
                    text: $postcode,
                    placeholder: "e.g. SW1A 1AA",
                    colorScheme: colorScheme
                )
            }
        }
        .background {
            if cardStyle == .solid {
                RoundedRectangle(cornerRadius: 16)
                    .fill(colorScheme == .dark ? Color(white: 0.15) : Color.white.opacity(0.9))
            } else {
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
            }
        }
    }
    
    // MARK: - Chef Type Section
    
    private var chefTypeSection: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "fork.knife.circle.fill")
                    .foregroundColor(AppTheme.accentColor(for: selectedTheme))
                Text("Chef Type")
                    .font(.headline)
                    .foregroundColor(colorScheme == .dark ? .white : .black)
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
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
                    .fill(colorScheme == .dark ? Color(white: 0.15) : Color.white.opacity(0.9))
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
            VStack(spacing: 20) {
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
                                .font(.system(size: 40, weight: .semibold))
                                .foregroundColor(.white)
                        }
                    }
                    
                    ZStack {
                        Circle()
                            .fill(colorScheme == .dark ? Color(white: 0.15) : .white)
                            .frame(width: 32, height: 32)
                        
                        Image(systemName: "pencil")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(AppTheme.accentColor(for: selectedTheme))
                    }
                }
                
                // Name & Chef Type
                VStack(spacing: 8) {
                    Text(displayName.isEmpty ? "Set Your Name" : displayName)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(colorScheme == .dark ? .white : .black)
                    
                    HStack(spacing: 8) {
                        Image(systemName: accountManager.chefType.icon)
                            .font(.caption)
                        Text(accountManager.chefType.rawValue)
                            .font(.subheadline)
                    }
                    .foregroundColor(.secondary)
                }
                
                // Edit Hint
                HStack(spacing: 6) {
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
                    .fill(colorScheme == .dark ? Color(white: 0.15) : Color.white.opacity(0.9))
            } else {
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
            }
        }
    }
    
    // MARK: - Account Actions
    
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
    
    // MARK: - Helper Functions
    
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
    
    private func getInitials() -> String {
        let firstInitial = firstName.first.map(String.init) ?? ""
        let lastInitial = lastName.first.map(String.init) ?? ""
        return "\(firstInitial)\(lastInitial)".uppercased()
    }
    
    private func loadCurrentProfile() {
        // Load current values from AccountManager
        firstName = accountManager.firstName
        middleName = accountManager.middleName
        lastName = accountManager.lastName
        dateOfBirth = accountManager.dateOfBirth
        selectedChefType = accountManager.chefType
        
        // Parse stored address (stored as comma-separated string)
        let addressComponents = accountManager.address.components(separatedBy: ", ")
        if addressComponents.count >= 5 {
            addressLine1 = addressComponents[0]
            addressLine2 = addressComponents[1]
            city = addressComponents[2]
            county = addressComponents[3]
            postcode = addressComponents[4]
        } else if !accountManager.address.isEmpty {
            // If address doesn't match expected format, put it in line 1
            addressLine1 = accountManager.address
        }
    }
    
    private func saveProfile() {
        // Combine address fields into a single formatted string
        let fullAddress = [addressLine1, addressLine2, city, county, postcode]
            .filter { !$0.isEmpty }
            .joined(separator: ", ")
        
        // Save to AccountManager using the updateProfile method
        accountManager.updateProfile(
            firstName: firstName,
            middleName: middleName,
            lastName: lastName,
            email: accountManager.email,
            address: fullAddress,
            dateOfBirth: dateOfBirth,
            chefType: selectedChefType
        )
        
        // Update AuthManager if signed in
        if let currentUser = authManager.currentUser {
            let fullName = [firstName, middleName, lastName]
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
            HStack(spacing: 16) {
                // Icon with background circle
                ZStack {
                    Circle()
                        .fill(iconColor)
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 4) {
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
                        .font(.system(size: 13, weight: .semibold))
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

// MARK: - Data Download View

struct DataDownloadView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var isExporting = false
    @State private var shareItems: [Any] = []
    @State private var showShareSheet = false
    @State private var exportError: String?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Spacer()
                
                Image(systemName: "arrow.down.doc.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
                
                Text("Download Your Data")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("In compliance with GDPR, you can download all your personal data. This includes recipes, preferences, and account information in JSON format.")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                
                if let error = exportError {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding(.horizontal)
                }
                
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
            .sheet(isPresented: $showShareSheet) {
                AccountShareSheet(items: shareItems)
            }
        }
    }
    
    private func exportData() {
        isExporting = true
        exportError = nil
        
        // Run export on background thread
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                // Gather all user data
                let accountManager = AccountManager.shared
                
                var userData: [String: Any] = [:]
                
                // Account Info
                userData["accountInfo"] = [
                    "fullName": accountManager.fullName,
                    "email": accountManager.email,
                    "dateOfBirth": accountManager.dateOfBirth?.ISO8601Format() ?? "",
                    "chefType": accountManager.chefType.rawValue,
                    "accountCreated": Date().ISO8601Format()
                ]
                
                // App Preferences
                let measurementSystem = UserDefaults.standard.string(forKey: "measurementSystem") ?? "metric"
                let appTheme = UserDefaults.standard.string(forKey: "appTheme") ?? "teal"
                let cardStyle = UserDefaults.standard.string(forKey: "cardStyle") ?? "frosted"
                
                userData["preferences"] = [
                    "measurementSystem": measurementSystem,
                    "theme": appTheme,
                    "cardStyle": cardStyle
                ]
                
                // Favorites (recipe IDs)
                if let favorites = UserDefaults.standard.array(forKey: "favoriteRecipeIDs") as? [String] {
                    userData["favoriteRecipes"] = favorites
                }
                
                // Shopping List Items
                if let shoppingListData = UserDefaults.standard.data(forKey: "shoppingListItems"),
                   let shoppingList = try? JSONDecoder().decode([ShoppingListItem].self, from: shoppingListData) {
                    userData["shoppingList"] = shoppingList.map { item in
                        [
                            "id": item.id.uuidString,
                            "name": item.name,
                            "quantity": item.quantity,
                            "unit": item.unit,
                            "isCompleted": item.isCompleted,
                            "category": item.category,
                            "dateAdded": item.dateAdded.ISO8601Format()
                        ]
                    }
                }
                
                // Kitchen Inventory
                if let inventoryData = UserDefaults.standard.data(forKey: "kitchenInventory"),
                   let inventory = try? JSONDecoder().decode([KitchenInventoryItemModel].self, from: inventoryData) {
                    userData["kitchenInventory"] = inventory.map { item in
                        [
                            "id": item.id.uuidString,
                            "name": item.name,
                            "quantity": item.quantity,
                            "category": item.category.rawValue,
                            "storageLocation": item.storageLocation.rawValue,
                            "expiryDate": item.expiryDate?.ISO8601Format() ?? "",
                            "purchaseDate": item.purchaseDate.ISO8601Format(),
                            "needsRestock": item.needsRestock
                        ]
                    }
                }
                
                // Meal Plans
                if let mealPlanData = UserDefaults.standard.data(forKey: "mealPlans"),
                   let mealPlans = try? JSONDecoder().decode([MealPlanModel].self, from: mealPlanData) {
                    userData["mealPlans"] = mealPlans.map { plan in
                        [
                            "id": plan.id.uuidString,
                            "recipeId": plan.recipeId.uuidString,
                            "recipeName": plan.recipeName,
                            "date": plan.date.ISO8601Format(),
                            "mealTime": plan.mealTime.rawValue,
                            "servings": plan.servings,
                            "isCompleted": plan.isCompleted
                        ]
                    }
                }
                
                // Notes
                if let notesData = UserDefaults.standard.data(forKey: "recipeNotes"),
                   let notesDict = try? JSONDecoder().decode([String: String].self, from: notesData) {
                    userData["recipeNotes"] = notesDict
                }
                
                // Convert to pretty, readable JSON
                let jsonData = try JSONSerialization.data(
                    withJSONObject: userData, 
                    options: [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
                )
                
                // Create a more readable text format
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd_HH-mm"
                let dateString = dateFormatter.string(from: Date())
                let fileName = "RecipeFinder_Export_\(dateString).txt"
                let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
                
                // Format as readable text
                var readableText = """
                ═══════════════════════════════════════════════════
                        RecipeFinder Data Export
                ═══════════════════════════════════════════════════
                Export Date: \(DateFormatter.localizedString(from: Date(), dateStyle: .long, timeStyle: .medium))
                
                
                ───────────────────────────────────────────────────
                📋 ACCOUNT INFORMATION
                ───────────────────────────────────────────────────
                Name: \(accountManager.fullName)
                Email: \(accountManager.email)
                Chef Type: \(accountManager.chefType.rawValue) \(accountManager.chefType.emoji)
                Date of Birth: \(accountManager.dateOfBirth != nil ? DateFormatter.localizedString(from: accountManager.dateOfBirth!, dateStyle: .long, timeStyle: .none) : "Not set")
                
                
                ───────────────────────────────────────────────────
                ⚙️ APP PREFERENCES
                ───────────────────────────────────────────────────
                Measurement System: \(measurementSystem.capitalized)
                Theme: \(appTheme.capitalized)
                Card Style: \(cardStyle.capitalized)
                
                
                """
                
                // Add Shopping List
                if let shoppingListData = UserDefaults.standard.data(forKey: "shoppingListItems"),
                   let shoppingList = try? JSONDecoder().decode([ShoppingListItem].self, from: shoppingListData),
                   !shoppingList.isEmpty {
                    readableText += """
                    ───────────────────────────────────────────────────
                    🛒 SHOPPING LIST (\(shoppingList.count) items)
                    ───────────────────────────────────────────────────
                    
                    """
                    for item in shoppingList {
                        let status = item.isCompleted ? "✓" : "○"
                        readableText += "\(status) \(item.name) - \(item.quantity) \(item.unit)\n"
                    }
                    readableText += "\n\n"
                }
                
                // Add Kitchen Inventory
                if let inventoryData = UserDefaults.standard.data(forKey: "kitchenInventory"),
                   let inventory = try? JSONDecoder().decode([KitchenInventoryItemModel].self, from: inventoryData),
                   !inventory.isEmpty {
                    readableText += """
                    ───────────────────────────────────────────────────
                    🥘 KITCHEN INVENTORY (\(inventory.count) items)
                    ───────────────────────────────────────────────────
                    
                    """
                    for item in inventory {
                        let expiry = item.expiryDate != nil ? " (Expires: \(DateFormatter.localizedString(from: item.expiryDate!, dateStyle: .short, timeStyle: .none)))" : ""
                        readableText += "• \(item.name) - \(item.quantity) (\(item.category.rawValue))\(expiry)\n"
                    }
                    readableText += "\n\n"
                }
                
                // Add Meal Plans
                if let mealPlanData = UserDefaults.standard.data(forKey: "mealPlans"),
                   let mealPlans = try? JSONDecoder().decode([MealPlanModel].self, from: mealPlanData),
                   !mealPlans.isEmpty {
                    readableText += """
                    ───────────────────────────────────────────────────
                    📅 MEAL PLANS (\(mealPlans.count) planned meals)
                    ───────────────────────────────────────────────────
                    
                    """
                    let sortedPlans = mealPlans.sorted { $0.date < $1.date }
                    for plan in sortedPlans {
                        let dateStr = DateFormatter.localizedString(from: plan.date, dateStyle: .medium, timeStyle: .none)
                        let status = plan.isCompleted ? "✓" : "○"
                        readableText += "\(status) \(dateStr) - \(plan.mealTime.rawValue): \(plan.recipeName)\n"
                    }
                    readableText += "\n\n"
                }
                
                // Add Favorites
                if let favorites = UserDefaults.standard.array(forKey: "favoriteRecipeIDs") as? [String],
                   !favorites.isEmpty {
                    readableText += """
                    ───────────────────────────────────────────────────
                    ⭐️ FAVORITE RECIPES (\(favorites.count) favorites)
                    ───────────────────────────────────────────────────
                    (Recipe IDs saved - import this file to restore)
                    
                    
                    """
                }
                
                // Add footer with JSON data
                readableText += """
                ═══════════════════════════════════════════════════
                        RAW DATA (JSON Format)
                ═══════════════════════════════════════════════════
                
                """
                
                if let jsonString = String(data: jsonData, encoding: .utf8) {
                    readableText += jsonString
                }
                
                readableText += """
                
                
                ═══════════════════════════════════════════════════
                End of Export
                ═══════════════════════════════════════════════════
                """
                
                // Write to file
                try readableText.write(to: tempURL, atomically: true, encoding: .utf8)
                
                // Update UI on main thread
                DispatchQueue.main.async {
                    self.isExporting = false
                    self.shareItems = [tempURL]
                    self.showShareSheet = true
                    HapticManager.shared.success()
                }
                
            } catch {
                DispatchQueue.main.async {
                    self.isExporting = false
                    self.exportError = "Failed to export data: \(error.localizedDescription)"
                    HapticManager.shared.error()
                }
            }
        }
    }
}

// MARK: - Data Privacy View

struct DataPrivacyView: View {
    @AppStorage("shareUsageData") private var shareUsageData = false
    @AppStorage("personalizedRecommendations") private var personalizedRecommendations = true
    @AppStorage("analyticsEnabled") private var analyticsEnabled = false
    
    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "shield.fill")
                            .foregroundColor(.blue)
                        Text("Your Privacy Matters")
                            .font(.headline)
                    }
                    
                    Text("RecipeFinder is designed to protect your privacy. All data is stored locally on your device and never shared without your explicit permission.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 8)
            }
            
            Section("Data Collection") {
                Toggle(isOn: $shareUsageData) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Share Usage Data")
                        Text("Help improve RecipeFinder by sharing anonymous usage statistics")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Toggle(isOn: $personalizedRecommendations) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Personalized Recommendations")
                        Text("Use your recipe history to suggest relevant content")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Toggle(isOn: $analyticsEnabled) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Analytics")
                        Text("Allow collection of app performance data")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Section("Data Storage") {
                HStack {
                    Image(systemName: "lock.shield.fill")
                        .foregroundColor(.green)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Local Storage")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Text("All your recipes and preferences are stored securely on your device")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.vertical, 4)
                
                HStack {
                    Image(systemName: "key.fill")
                        .foregroundColor(.orange)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("End-to-End Encryption")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Text("Your account credentials are encrypted and stored in the iOS Keychain")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.vertical, 4)
            }
            
            Section("Your Rights") {
                Label("Access your data anytime", systemImage: "eye.fill")
                Label("Request data deletion", systemImage: "trash.fill")
                Label("Export your data", systemImage: "square.and.arrow.up.fill")
                Label("Withdraw consent", systemImage: "hand.raised.fill")
            }
            .font(.subheadline)
            
            Section {
                Text("Changes to these settings will take effect immediately. RecipeFinder complies with UK GDPR and Data Protection Act 2018.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .navigationTitle("Data & Privacy")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Data Download View

struct StatBadge: View {
    let icon: String
    let count: Int
    let label: String
    
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
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
            VStack(spacing: 24) {
                Spacer()
                
                Image(systemName: "square.and.arrow.up.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.orange)
                
                Text("Import Your Data")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Restore your recipes, preferences, and data from a previous backup. Select a JSON file exported from RecipeFinder.")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                
                // Merge Mode Picker
                VStack(alignment: .leading, spacing: 12) {
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
                                
                                VStack(alignment: .leading, spacing: 2) {
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
                            .cornerRadius(12)
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
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.orange)
                    .cornerRadius(12)
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
                if mergeMode == .replace {
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
                    if let newItems = try? JSONDecoder().decode([ShoppingListItem].self, from: jsonData) {
                        if mergeMode == .replace {
                            let encoded = try JSONEncoder().encode(newItems)
                            UserDefaults.standard.set(encoded, forKey: "shoppingListItems")
                        } else {
                            if let existingData = UserDefaults.standard.data(forKey: "shoppingListItems"),
                               var existingItems = try? JSONDecoder().decode([ShoppingListItem].self, from: existingData) {
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
                    if let newItems = try? JSONDecoder().decode([KitchenInventoryItemModel].self, from: jsonData) {
                        if mergeMode == .replace {
                            let encoded = try JSONEncoder().encode(newItems)
                            UserDefaults.standard.set(encoded, forKey: "kitchenInventory")
                        } else {
                            if let existingData = UserDefaults.standard.data(forKey: "kitchenInventory"),
                               var existingItems = try? JSONDecoder().decode([KitchenInventoryItemModel].self, from: existingData) {
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
                        if mergeMode == .replace {
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
                    if mergeMode == .replace {
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
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.secondary)
                .frame(width: 28)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(label)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                TextField(placeholder, text: $text)
                    .foregroundColor(colorScheme == .dark ? .white : .black)
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
            VStack(spacing: 8) {
                Image(systemName: chefType.icon)
                    .font(.system(size: 32))
                    .foregroundColor(isSelected ? AppTheme.accentColor(for: selectedTheme) : .secondary)
                
                Text(chefType.rawValue)
                    .font(.caption)
                    .fontWeight(isSelected ? .semibold : .regular)
                    .foregroundColor(colorScheme == .dark ? .white : .black)
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
