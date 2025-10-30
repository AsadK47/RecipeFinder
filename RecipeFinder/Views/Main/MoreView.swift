import SwiftUI

struct MoreView: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.appTheme) var appTheme
    @AppStorage("cardStyle") private var cardStyle: CardStyle = .frosted
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Themed background gradient
                AppTheme.backgroundGradient(for: appTheme, colorScheme: colorScheme)
                    .ignoresSafeArea()
                
                List {
                    NavigationLink(destination: AccountView()) {
                        Label("Account", systemImage: "person.fill")
                            .foregroundColor(AppTheme.accentColor(for: appTheme))
                    }
                    .listRowBackground(
                        cardStyle == .solid
                            ? (colorScheme == .dark ? AppTheme.cardBackgroundDark : AppTheme.cardBackground)
                            : Color.clear
                    )
                    
                    NavigationLink(destination: SettingsView()) {
                        Label("Settings", systemImage: "gearshape.fill")
                            .foregroundColor(AppTheme.accentColor(for: appTheme))
                    }
                    .listRowBackground(
                        cardStyle == .solid
                            ? (colorScheme == .dark ? AppTheme.cardBackgroundDark : AppTheme.cardBackground)
                            : Color.clear
                    )
                }
                .scrollContentBackground(.hidden)
                .navigationTitle("More")
                .navigationBarTitleDisplayMode(.large)
            }
        }
    }
}

#Preview {
    MoreView()
        .environment(\.appTheme, .teal)
}
