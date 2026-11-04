import SwiftUI

struct SubstituteSheetView: View {
    let ingredientName: String
    let substitutes: [String]

    var body: some View {
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
        .sheetDismissButton()
        .sheetScaffold("Substitute for \(ingredientName)")
    }

    private func substituteRow(_ text: String, number: Int) -> some View {
        HStack(alignment: .top, spacing: AppTheme.spacing12) {
            // White-on-accent step badge — accent text on the frosted card was low-contrast.
            Text("\(number)")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundStyle(.white)
                .frame(width: 22, height: 22)
                .background(Circle().fill(AppTheme.accentColor))
                .padding(.top, AppTheme.spacing2)

            Text(text)
                .font(.subheadline)
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(AppTheme.spacing16)
        .appCard(elevated: true)
    }
}
