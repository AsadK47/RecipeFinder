//
//  FilterComponents.swift
//  RecipeFinder
//
//  Shared filter UI components
//

import SwiftUI

// MARK: - Filter Chip Component
struct FilterChip: View {
    let label: String
    let icon: String
    let onRemove: () -> Void
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption2)
            Text(label)
                .font(.caption)
                .fontWeight(.semibold)
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.caption)
                    .foregroundColor(colorScheme == .dark ? .white.opacity(0.8) : .black.opacity(0.6))
            }
        }
        .foregroundColor(colorScheme == .dark ? .white : .black)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(colorScheme == .dark ? Color(white: 0.2).opacity(0.8) : Color(white: 0.9).opacity(0.9))
        )
    }
}

// MARK: - Filter Button Component
struct FilterButton: View {
    let label: String
    let icon: String
    let color: Color
    let isSelected: Bool
    let action: () -> Void
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        Button {
            action()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(isSelected ? .white : color)
                
                Text(label)
                    .font(.subheadline)
                    .fontWeight(isSelected ? .semibold : .regular)
                    .foregroundColor(isSelected ? .white : (colorScheme == .dark ? .white : .black))
                    .lineLimit(1)
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.white)
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? color : (colorScheme == .dark ? Color(white: 0.2).opacity(0.8) : Color(white: 0.9).opacity(0.9)))
            )
        }
    }
}
