//
//  EditProfileView.swift
//  RecipeFinder
//
//  Beautiful profile editing with password protection
//

import SwiftUI

struct EditProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var accountManager = AccountManager.shared
    @StateObject private var authManager = AuthenticationManager.shared
    @AppStorage("appTheme") private var selectedTheme: AppTheme.ThemeType = .teal
    @Environment(\.colorScheme) private var colorScheme
    
    // Profile fields
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
    
    // Password protection
    @State private var showPasswordPrompt = false
    @State private var password: String = ""
    @State private var showError = false
    @State private var errorMessage = ""
    
    // Track changes
    @State private var hasChanges = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.backgroundGradient(for: selectedTheme, colorScheme: colorScheme)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Avatar
                        profileAvatar
                        
                        // Personal Information
                        personalInfoSection
                        
                        // Address
                        addressSection
                        
                        // Chef Type Picker
                        chefTypeSection
                        
                        // Save Button
                        saveButton
                    }
                    .padding(20)
                    .padding(.bottom, 100)
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
            .alert("Verify Password", isPresented: $showPasswordPrompt) {
                SecureField("Password", text: $password)
                Button("Cancel", role: .cancel) {
                    password = ""
                }
                Button("Verify") {
                    verifyPasswordAndSave()
                }
            } message: {
                Text("Enter your password to save changes to personal information.")
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
            .onAppear {
                loadCurrentProfile()
            }
            .onChange(of: firstName) { _, _ in checkForChanges() }
            .onChange(of: middleName) { _, _ in checkForChanges() }
            .onChange(of: lastName) { _, _ in checkForChanges() }
            .onChange(of: addressLine1) { _, _ in checkForChanges() }
            .onChange(of: addressLine2) { _, _ in checkForChanges() }
            .onChange(of: city) { _, _ in checkForChanges() }
            .onChange(of: county) { _, _ in checkForChanges() }
            .onChange(of: postcode) { _, _ in checkForChanges() }
            .onChange(of: dateOfBirth) { _, _ in checkForChanges() }
            .onChange(of: selectedChefType) { _, _ in checkForChanges() }
        }
    }
    
    // Profile Avatar
    
    private var profileAvatar: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(AppTheme.accentColor(for: selectedTheme))
                    .frame(width: 100, height: 100)
                
                Text(getInitials())
                    .font(.system(size: 40, weight: .bold))
                    .foregroundColor(.white)
            }
            
            Text("Profile Picture")
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
        }
        .padding(.vertical, 20)
    }
    
    // Personal Information Section
    
    private var personalInfoSection: some View {
        VStack(spacing: 0) {
            // Section Header
            HStack {
                Image(systemName: "person.fill")
                    .foregroundColor(AppTheme.accentColor(for: selectedTheme))
                Text("Personal Information")
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()
                Image(systemName: "lock.fill")
                    .foregroundColor(.yellow)
                    .font(.caption)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(Color.white.opacity(0.1))
            
            // First Name
            ProfileTextField(
                icon: "person.circle",
                label: "First Name",
                text: $firstName,
                placeholder: "John"
            )
            
            Divider()
                .background(Color.white.opacity(0.1))
                .padding(.leading, 60)
            
            // Middle Name
            ProfileTextField(
                icon: "person.circle.fill",
                label: "Middle Name",
                text: $middleName,
                placeholder: "Optional"
            )
            
            Divider()
                .background(Color.white.opacity(0.1))
                .padding(.leading, 60)
            
            // Last Name
            ProfileTextField(
                icon: "person.crop.circle",
                label: "Last Name",
                text: $lastName,
                placeholder: "Doe"
            )
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
    
    // Address Section
    
    private var addressSection: some View {
        VStack(spacing: 0) {
            // Section Header
            HStack {
                Image(systemName: "mappin.and.ellipse")
                    .foregroundColor(AppTheme.accentColor(for: selectedTheme))
                Text("Address")
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()
                Text("Optional")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.5))
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(Color.white.opacity(0.1))
            
            VStack(spacing: 0) {
                // Address Line 1
                ProfileTextField(
                    icon: "house.fill",
                    label: "Address Line 1",
                    text: $addressLine1,
                    placeholder: "House number and street name"
                )
                
                Divider()
                    .background(Color.white.opacity(0.1))
                    .padding(.leading, 60)
                
                // Address Line 2
                ProfileTextField(
                    icon: "building.2.fill",
                    label: "Address Line 2",
                    text: $addressLine2,
                    placeholder: "Apartment, suite, etc. (optional)"
                )
                
                Divider()
                    .background(Color.white.opacity(0.1))
                    .padding(.leading, 60)
                
                // City
                ProfileTextField(
                    icon: "building.columns.fill",
                    label: "Town/City",
                    text: $city,
                    placeholder: "e.g. London"
                )
                
                Divider()
                    .background(Color.white.opacity(0.1))
                    .padding(.leading, 60)
                
                // County
                ProfileTextField(
                    icon: "map.fill",
                    label: "County",
                    text: $county,
                    placeholder: "e.g. Greater London (optional)"
                )
                
                Divider()
                    .background(Color.white.opacity(0.1))
                    .padding(.leading, 60)
                
                // Postcode
                ProfileTextField(
                    icon: "envelope.fill",
                    label: "Postcode",
                    text: $postcode,
                    placeholder: "e.g. SW1A 1AA"
                )
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
    
    // Chef Type Section
    
    private var chefTypeSection: some View {
        VStack(spacing: 12) {
            // Section Header
            HStack {
                Image(systemName: "fork.knife.circle.fill")
                    .foregroundColor(AppTheme.accentColor(for: selectedTheme))
                Text("Chef Type")
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            
            // Chef Type Grid
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
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
    
    // Save Button
    
    private var saveButton: some View {
        Button(action: handleSave) {
            HStack(spacing: 12) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 20))
                Text("Save Changes")
                    .fontWeight(.semibold)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(hasChanges ? AppTheme.accentColor(for: selectedTheme) : Color.gray)
            )
            .shadow(color: hasChanges ? AppTheme.accentColor(for: selectedTheme).opacity(0.3) : Color.clear, radius: 10, y: 5)
        }
        .disabled(!hasChanges)
        .opacity(hasChanges ? 1.0 : 0.6)
    }
    
    // Helper Functions
    
    private func loadCurrentProfile() {
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
    
    private func getInitials() -> String {
        let first = firstName.isEmpty ? accountManager.firstName : firstName
        let last = lastName.isEmpty ? accountManager.lastName : lastName
        
        var initials = ""
        if let firstChar = first.first {
            initials += String(firstChar)
        }
        if let lastChar = last.first {
            initials += String(lastChar)
        }
        return initials.isEmpty ? "?" : initials.uppercased()
    }
    
    private func checkForChanges() {
        let currentAddress = [addressLine1, addressLine2, city, county, postcode]
            .filter { !$0.isEmpty }
            .joined(separator: ", ")
        
        hasChanges = firstName != accountManager.firstName ||
                     middleName != accountManager.middleName ||
                     lastName != accountManager.lastName ||
                     currentAddress != accountManager.address ||
                     selectedChefType != accountManager.chefType
    }
    
    private func handleSave() {
        guard hasChanges else { return }
        
        // Check if personal info changed (requires password)
        let personalInfoChanged = firstName != accountManager.firstName ||
                                 middleName != accountManager.middleName ||
                                 lastName != accountManager.lastName
        
        if personalInfoChanged && !authManager.isGuestMode {
            // Show password prompt
            showPasswordPrompt = true
        } else {
            // Save directly (no password needed for address/chef type)
            saveProfile()
        }
    }
    
    private func verifyPasswordAndSave() {
        guard let email = authManager.currentUser?.email else {
            errorMessage = "Could not verify user email"
            showError = true
            return
        }
        
        // Verify password
        Task {
            do {
                // Try signing in with provided credentials to verify
                try await authManager.signIn(email: email, password: password)
                
                await MainActor.run {
                    password = ""
                    saveProfile()
                    HapticManager.shared.success()
                }
            } catch {
                await MainActor.run {
                    password = ""
                    errorMessage = "Incorrect password"
                    showError = true
                    HapticManager.shared.error()
                }
            }
        }
    }
    
    private func saveProfile() {
        // Combine address fields into a single formatted string
        let fullAddress = [addressLine1, addressLine2, city, county, postcode]
            .filter { !$0.isEmpty }
            .joined(separator: ", ")
        
        accountManager.updateProfile(
            firstName: firstName,
            middleName: middleName,
            lastName: lastName,
            email: accountManager.email,
            address: fullAddress,
            dateOfBirth: dateOfBirth,
            chefType: selectedChefType
        )
        
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
        
        HapticManager.shared.success()
        dismiss()
    }
}

// Profile Text Field Component

struct ProfileTextField: View {
    let icon: String
    let label: String
    @Binding var text: String
    let placeholder: String
    var multiline: Bool = false
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.white.opacity(0.7))
                .frame(width: 28)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(label)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
                
                if multiline {
                    TextField(placeholder, text: $text, axis: .vertical)
                        .lineLimit(2...4)
                        .textFieldStyle(.plain)
                        .foregroundColor(.white)
                } else {
                    TextField(placeholder, text: $text)
                        .textFieldStyle(.plain)
                        .foregroundColor(.white)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }
}

// Chef Type Card Component

struct ChefTypeCard: View {
    let chefType: ChefType
    let isSelected: Bool
    let selectedTheme: AppTheme.ThemeType
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: chefType.icon)
                    .font(.system(size: 28))
                    .foregroundColor(isSelected ? .white : .white.opacity(0.7))
                
                Text(chefType.rawValue)
                    .font(.caption)
                    .fontWeight(isSelected ? .semibold : .regular)
                    .foregroundColor(isSelected ? .white : .white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 100)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? AppTheme.accentColor(for: selectedTheme) : Color.white.opacity(0.1))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? AppTheme.accentColor(for: selectedTheme) : Color.white.opacity(0.2), lineWidth: isSelected ? 2 : 1)
            )
        }
    }
}

#Preview {
    EditProfileView()
}
