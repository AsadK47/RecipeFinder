import SwiftUI

/// "Contact Information" card (company email and website links) on the legal screen.
struct LegalContactCard: View {
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        SettingsCard {
            VStack(alignment: .leading, spacing: AppTheme.spacing16) {
                HStack {
                    Image(systemName: "envelope.fill")
                        .font(.title2)
                        .adaptiveForegroundColor()
                    
                    Text("Contact Information")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .adaptiveForegroundColor()
                }
                
                Divider()
                    .padding(.vertical, AppTheme.spacing4)
                
                Button(action: {
                    if let url = URL(string: "mailto:recipefinderlimited@icloud.com") {
                        UIApplication.shared.open(url)
                    }
                }) {
                    HStack(spacing: AppTheme.spacing12) {
                        Image(systemName: "envelope.circle.fill")
                            .adaptiveForegroundColor()
                            .font(.title3)
                        
                        VStack(alignment: .leading, spacing: AppTheme.spacing4) {
                            Text("Company Email")
                                .font(.caption)
                                .adaptiveSecondaryForeground()
                            Text("recipefinderlimited@icloud.com")
                                .font(.subheadline)
                                .adaptiveForegroundColor()
                        }
                        
                        Spacer()
                        
                        Image(systemName: "arrow.up.right.square")
                            .adaptiveSecondaryForeground()
                            .font(.caption)
                    }
                    .padding(AppTheme.spacing12)
                    .background(Color.white.opacity(colorScheme == .dark ? AppTheme.dividerOpacity : 0.05))
                    .cornerRadius(AppTheme.cornerRadius12)
                }
                .buttonStyle(PlainButtonStyle())
                
                Button(action: {
                    if let url = URL(string: "https://recipefinder.uk") {
                        UIApplication.shared.open(url)
                    }
                }) {
                    HStack(spacing: AppTheme.spacing12) {
                        Image(systemName: "globe")
                            .adaptiveForegroundColor()
                            .font(.title3)
                        
                        VStack(alignment: .leading, spacing: AppTheme.spacing4) {
                            Text("Website")
                                .font(.caption)
                                .adaptiveSecondaryForeground()
                            Text("recipefinder.uk")
                                .font(.subheadline)
                                .adaptiveForegroundColor()
                        }
                        
                        Spacer()
                        
                        Image(systemName: "arrow.up.right.square")
                            .adaptiveSecondaryForeground()
                            .font(.caption)
                    }
                    .padding(AppTheme.spacing12)
                    .background(Color.white.opacity(colorScheme == .dark ? AppTheme.dividerOpacity : 0.05))
                    .cornerRadius(AppTheme.cornerRadius12)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(AppTheme.spacing24)
        }
    }
}
