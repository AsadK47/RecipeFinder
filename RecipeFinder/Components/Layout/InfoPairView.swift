import SwiftUI

struct InfoPairView: View {
    let label1: String
    let value1: String
    let icon1: String
    let label2: String
    let value2: String
    let icon2: String

    private enum Layout {
        static let dividerHeight: CGFloat = 60
    }

    var body: some View {
        HStack(spacing: 0) {
            InfoItem(icon: icon1, label: label1, value: value1)

            Divider()
                .frame(height: Layout.dividerHeight)
                .padding(.horizontal)

            InfoItem(icon: icon2, label: label2, value: value2)
        }
    }
}
