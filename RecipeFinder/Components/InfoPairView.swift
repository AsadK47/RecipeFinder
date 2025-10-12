import SwiftUI

struct InfoPairView: View {
    let label1: String
    let value1: String
    let icon1: String
    let label2: String
    let value2: String
    let icon2: String
    
    var body: some View {
        HStack(spacing: 0) {
            InfoItem(icon: icon1, label: label1, value: value1)
            
            Divider()
                .frame(height: 60)
                .padding(.horizontal)
            
            InfoItem(icon: icon2, label: label2, value: value2)
        }
    }
}

struct InfoItem: View {
    let icon: String
    let label: String
    let value: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(AppTheme.accentColor)
            Text(label)
                .font(.caption)
                .foregroundColor(AppTheme.secondaryText)
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
        }
        .frame(maxWidth: .infinity)
    }
}
