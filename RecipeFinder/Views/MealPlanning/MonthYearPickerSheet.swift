import SwiftUI

struct MonthYearPickerSheet: View {
    @Binding var selectedDate: Date
    @Environment(\.dismiss) var dismiss
    @AppStorage("cardStyle") private var cardStyle: CardStyle = .frosted
    @AppStorage("appTheme") private var selectedTheme: AppTheme.ThemeType = .teal
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        NavigationView {
            ZStack {
                AppTheme.backgroundGradient(for: selectedTheme, colorScheme: colorScheme)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    DatePicker(
                        "Select Month and Year",
                        selection: $selectedDate,
                        displayedComponents: [.date]
                    )
                    .datePickerStyle(.graphical)
                    .padding()
                    .background {
                        if cardStyle == .solid {
                            RoundedRectangle(cornerRadius: AppTheme.cornerRadius16)
                                .fill(colorScheme == .dark ? Color.white.opacity(AppTheme.glassSubtleOpacity) : Color.white.opacity(AppTheme.cardDarkOpacity))
                        } else {
                            RoundedRectangle(cornerRadius: AppTheme.cornerRadius16)
                                .fill(.ultraThinMaterial)
                        }
                    }
                    .padding()
                    
                    Spacer()
                }
                .padding(.top, AppTheme.spacing20)
            }
            .navigationTitle("Select Date")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(AppTheme.accentColor(for: selectedTheme))
                }
            }
        }
    }
}
