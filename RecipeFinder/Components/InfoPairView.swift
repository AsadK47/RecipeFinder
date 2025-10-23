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
    
    // Custom icon colors for better visibility
    private var iconColor: Color {
        switch icon {
        case "clock": return .orange
        case "flame": return .red
        case "chart.bar": return .blue
        case "fork.knife": return .green
        default: return .white
        }
    }
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(iconColor)
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
        }
        .frame(maxWidth: .infinity)
    }
}
