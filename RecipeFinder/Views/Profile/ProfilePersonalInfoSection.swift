import SwiftUI

/// "Personal Information" card (first/last name fields) on the Profile screen.
struct ProfilePersonalInfoSection: View {
    @Binding var firstName: String
    @Binding var lastName: String

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Image(systemName: "person.fill")
                    .adaptiveForegroundColor()
                Text("Personal Information")
                    .font(.headline)
                    .adaptiveForegroundColor()
                Spacer()
            }
            .padding(.horizontal, AppTheme.cardHorizontalPadding)
            .padding(.vertical, AppTheme.spacing12)
            .background(Color.secondary.opacity(AppTheme.shadowLightOpacity))
            
            VStack(spacing: 0) {
                ProfileTextField(
                    icon: "person.circle",
                    label: "First Name",
                    text: $firstName,
                    placeholder: "John"
                )
                
                Divider()
                    .background(Color.secondary.opacity(AppTheme.shadowLightOpacity))
                    .padding(.leading, AppTheme.spacing60)
                
                ProfileTextField(
                    icon: "person.crop.circle",
                    label: "Last Name",
                    text: $lastName,
                    placeholder: "Doe"
                )
            }
        }
        .appCard(cornerRadius: AppTheme.cornerRadius16)
    }
}
