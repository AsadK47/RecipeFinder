import SwiftUI

/// The "Personal Information" card (first/last name fields and email) on the
/// Account screen. Extracted from `AccountView`.
struct AccountPersonalInfoSection: View {
    @Binding var firstName: String
    @Binding var lastName: String
    let email: String
    let cardStyle: CardStyle
    let colorScheme: ColorScheme

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
                    placeholder: "John",
                    colorScheme: colorScheme
                )
                
                Divider()
                    .background(Color.secondary.opacity(AppTheme.shadowLightOpacity))
                    .padding(.leading, AppTheme.spacing60)
                
                ProfileTextField(
                    icon: "person.crop.circle",
                    label: "Last Name",
                    text: $lastName,
                    placeholder: "Doe",
                    colorScheme: colorScheme
                )
                
                if !email.isEmpty {
                    Divider()
                        .background(Color.secondary.opacity(AppTheme.shadowLightOpacity))
                        .padding(.leading, AppTheme.spacing60)
                    
                    HStack(spacing: AppTheme.spacing16) {
                        Image(systemName: "envelope.fill")
                            .font(.title3)
                            .adaptiveForegroundColor()
                            .frame(width: AppTheme.iconSize28)
                        
                        VStack(alignment: .leading, spacing: AppTheme.spacing4) {
                            Text("Email")
                                .font(.caption)
                                .foregroundStyle(.primary)
                            
                            Text(email)
                                .font(.body)
                                .adaptiveForegroundColor()
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal, AppTheme.cardHorizontalPadding)
                    .padding(.vertical, AppTheme.spacing16)
                }
            }
        }
        .background {
            if cardStyle == .solid {
                RoundedRectangle(cornerRadius: AppTheme.cornerRadius16)
                    .fill(AppTheme.adaptiveCard(for: colorScheme))
            } else {
                RoundedRectangle(cornerRadius: AppTheme.cornerRadius16)
                    .fill(.ultraThinMaterial)
            }
        }
    }
}
