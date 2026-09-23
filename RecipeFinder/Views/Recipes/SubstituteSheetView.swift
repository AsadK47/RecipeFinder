import SwiftUI

struct SubstituteSheetView: View {
    let ingredientName: String
    let substitutes: [String]

    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("appTheme") private var selectedTheme: AppTheme.ThemeType = .teal

    var body: some View {
        ZStack {
            AppTheme.backgroundGradient(for: selectedTheme, colorScheme: colorScheme)
                .ignoresSafeArea()

            NavigationStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: AppTheme.spacing16) {
                        if substitutes.isEmpty {
                            Text("No known substitutes for \(ingredientName).")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .padding(.top, AppTheme.spacing24)
                                .frame(maxWidth: .infinity, alignment: .center)
                        } else {
                            ForEach(substitutes.indices, id: \.self) { index in
                                substituteRow(substitutes[index], number: index + 1)
                            }
                        }
                    }
                    .padding(.horizontal, AppTheme.spacing20)
                    .padding(.top, AppTheme.spacing16)
                    .padding(.bottom, AppTheme.spacing40)
                }
                .scrollContentBackground(.hidden)
                .navigationTitle("Substitute for \(ingredientName)")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") { dismiss() }
                    }
                }
                .toolbarBackground(.hidden, for: .navigationBar)
            }
        }
    }

    private func substituteRow(_ text: String, number: Int) -> some View {
        GlassCard {
            HStack(alignment: .top, spacing: AppTheme.spacing12) {
                Text("\(number)")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundStyle(AppTheme.accentColor)
                    .frame(width: 20, alignment: .center)
                    .padding(.top, AppTheme.spacing2)

                Text(text)
                    .font(.subheadline)
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(AppTheme.spacing16)
        }
    }
}
