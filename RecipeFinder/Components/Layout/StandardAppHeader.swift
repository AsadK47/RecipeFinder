import SwiftUI

struct StandardAppHeader<MenuContent: View>: View {
    let title: String
    var showSearch: Bool = false
    @Binding var searchText: String
    var searchPlaceholder: String = "Search..."
    @ViewBuilder var menuContent: () -> MenuContent
    
    var body: some View {
        VStack(spacing: AppTheme.spacing12) {
            GeometryReader { geometry in
                HStack(spacing: 0) {
                    Spacer(minLength: 8)
                    
                    Text(title)
                        .font(.system(size: min(34, geometry.size.width * 0.085), weight: .bold))
                        .adaptiveForegroundColor()
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    
                    Spacer(minLength: 8)
                    
                    Menu {
                        menuContent()
                    } label: {
                        ModernCircleButton(icon: "line.3.horizontal") {}
                            .allowsHitTesting(false)
                    }
                    .frame(width: max(44, geometry.size.width * 0.15))
                }
            }
            .frame(height: 44)
            .padding(.horizontal, 20)
            .padding(.top, 16)
            
            if showSearch {
                ModernSearchBar(text: $searchText, placeholder: searchPlaceholder)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 12)
            }
        }
    }
}

struct SimpleAppHeader: View {
    let title: String
    var showSearch: Bool = false
    @Binding var searchText: String
    var searchPlaceholder: String = "Search..."
    
    var body: some View {
        VStack(spacing: AppTheme.spacing12) {
            GeometryReader { geometry in
                HStack(spacing: 0) {
                    Spacer()
                    
                    Text(title)
                        .font(.system(size: min(34, geometry.size.width * 0.085), weight: .bold))
                        .adaptiveForegroundColor()
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    
                    Spacer()
                }
            }
            .frame(height: 44)
            .padding(.horizontal, 20)
            .padding(.top, 16)
            
            if showSearch {
                ModernSearchBar(text: $searchText, placeholder: searchPlaceholder)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 12)
            }
        }
    }
}
