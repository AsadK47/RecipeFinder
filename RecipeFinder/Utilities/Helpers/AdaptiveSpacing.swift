
import SwiftUI

struct AdaptiveSpacing {
    private let width: CGFloat
    private let height: CGFloat
    
    init(geometry: GeometryProxy) {
        self.width = geometry.size.width
        self.height = geometry.size.height
    }
    
    init(width: CGFloat, height: CGFloat) {
        self.width = width
        self.height = height
    }
    
    var xxs: CGFloat {
        max(4, height * 0.005)
    }
    
    var xs: CGFloat {
        max(6, height * 0.008)
    }
    
    var sm: CGFloat {
        max(8, height * 0.012)
    }
    
    var md: CGFloat {
        max(12, height * 0.015)
    }
    
    var lg: CGFloat {
        max(16, height * 0.02)
    }
    
    var xl: CGFloat {
        max(20, height * 0.025)
    }
    
    var xxl: CGFloat {
        max(24, height * 0.03)
    }
    
    var iconSmall: CGFloat {
        max(20, min(width, height) * 0.03)
    }
    
    var iconMedium: CGFloat {
        max(24, min(width, height) * 0.035)
    }
    
    var iconLarge: CGFloat {
        max(32, min(width, height) * 0.045)
    }
    
    var buttonHeight: CGFloat {
        max(44, height * 0.055)
    }
    
    var buttonHeightLarge: CGFloat {
        max(56, height * 0.065)
    }
    
    var touchTargetSmall: CGFloat {
        max(32, min(width, height) * 0.05)
    }
    
    var touchTarget: CGFloat {
        max(44, min(width, height) * 0.06)
    }
    
    var imageSmall: CGFloat {
        max(60, min(width, height) * 0.1)
    }
    
    var imageMedium: CGFloat {
        max(100, min(width, height) * 0.15)
    }
    
    var imageLarge: CGFloat {
        max(160, min(width, height) * 0.22)
    }
    
    var imageXLarge: CGFloat {
        max(200, min(width, height) * 0.28)
    }
    
    var imageHero: CGFloat {
        max(240, min(width, height) * 0.33)
    }
    
    var screenEdge: CGFloat {
        max(16, width * 0.04)
    }
    
    var cardPadding: CGFloat {
        max(12, width * 0.035)
    }
    
    var compactPadding: CGFloat {
        max(8, width * 0.025)
    }
    
    func heightPercent(_ percent: CGFloat, min minValue: CGFloat) -> CGFloat {
        max(minValue, height * percent)
    }
    
    func widthPercent(_ percent: CGFloat, min minValue: CGFloat) -> CGFloat {
        max(minValue, width * percent)
    }
    
    func minDimensionPercent(_ percent: CGFloat, min minValue: CGFloat) -> CGFloat {
        max(minValue, min(width, height) * percent)
    }
    
    func scaledValue(base: CGFloat, widthScale: CGFloat = 0.01, heightScale: CGFloat = 0.01) -> CGFloat {
        base + (width * widthScale) + (height * heightScale)
    }
}

extension View {
    func adaptiveSpacing(_ geometry: GeometryProxy) -> AdaptiveSpacing {
        AdaptiveSpacing(geometry: geometry)
    }
}

private struct AdaptiveSpacingKey: EnvironmentKey {
    static let defaultValue: AdaptiveSpacing? = nil
}

extension EnvironmentValues {
    var adaptiveSpacing: AdaptiveSpacing? {
        get { self[AdaptiveSpacingKey.self] }
        set { self[AdaptiveSpacingKey.self] = newValue }
    }
}

extension View {
    func withAdaptiveSpacing(_ geometry: GeometryProxy) -> some View {
        environment(\.adaptiveSpacing, AdaptiveSpacing(geometry: geometry))
    }
}
