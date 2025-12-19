//
//  AdaptiveSpacing.swift
//  RecipeFinder
//
//  Created for adaptive, geometry-aware spacing and sizing
//

import SwiftUI

/// Provides adaptive spacing and sizing values based on screen geometry
/// Eliminates magic numbers and ensures consistent, responsive layouts
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
    
    // MARK: - Spacing Values
    
    /// Extra small spacing (typically ~4-6pt)
    var xxs: CGFloat {
        max(4, height * 0.005)
    }
    
    /// Extra small spacing (typically ~6-8pt)
    var xs: CGFloat {
        max(6, height * 0.008)
    }
    
    /// Small spacing (typically ~8-12pt)
    var sm: CGFloat {
        max(8, height * 0.012)
    }
    
    /// Medium spacing (typically ~12-16pt)
    var md: CGFloat {
        max(12, height * 0.015)
    }
    
    /// Large spacing (typically ~16-20pt)
    var lg: CGFloat {
        max(16, height * 0.02)
    }
    
    /// Extra large spacing (typically ~20-24pt)
    var xl: CGFloat {
        max(20, height * 0.025)
    }
    
    /// Extra extra large spacing (typically ~24-32pt)
    var xxl: CGFloat {
        max(24, height * 0.03)
    }
    
    // MARK: - Icon and Button Sizes
    
    /// Small icon size (typically ~20-24pt)
    var iconSmall: CGFloat {
        max(20, min(width, height) * 0.03)
    }
    
    /// Medium icon size (typically ~24-28pt)
    var iconMedium: CGFloat {
        max(24, min(width, height) * 0.035)
    }
    
    /// Large icon size (typically ~32-36pt)
    var iconLarge: CGFloat {
        max(32, min(width, height) * 0.045)
    }
    
    /// Standard button height (typically ~44-56pt)
    var buttonHeight: CGFloat {
        max(44, height * 0.055)
    }
    
    /// Large button height (typically ~56-62pt)
    var buttonHeightLarge: CGFloat {
        max(56, height * 0.065)
    }
    
    /// Small button/touch target (typically ~32-40pt)
    var touchTargetSmall: CGFloat {
        max(32, min(width, height) * 0.05)
    }
    
    /// Standard touch target (typically ~44-50pt)
    var touchTarget: CGFloat {
        max(44, min(width, height) * 0.06)
    }
    
    // MARK: - Image and Content Sizes
    
    /// Small image/content size (typically ~60-80pt)
    var imageSmall: CGFloat {
        max(60, min(width, height) * 0.1)
    }
    
    /// Medium image/content size (typically ~100-120pt)
    var imageMedium: CGFloat {
        max(100, min(width, height) * 0.15)
    }
    
    /// Large image/content size (typically ~160-180pt)
    var imageLarge: CGFloat {
        max(160, min(width, height) * 0.22)
    }
    
    /// Extra large image/content size (typically ~200-240pt)
    var imageXLarge: CGFloat {
        max(200, min(width, height) * 0.28)
    }
    
    /// Hero/feature image size (typically ~240-280pt)
    var imageHero: CGFloat {
        max(240, min(width, height) * 0.33)
    }
    
    // MARK: - Padding Values
    
    /// Screen edge padding (typically ~16-20pt)
    var screenEdge: CGFloat {
        max(16, width * 0.04)
    }
    
    /// Card padding (typically ~12-16pt)
    var cardPadding: CGFloat {
        max(12, width * 0.035)
    }
    
    /// Compact padding (typically ~8-12pt)
    var compactPadding: CGFloat {
        max(8, width * 0.025)
    }
    
    // MARK: - Custom Computed Values
    
    /// Compute a height percentage with minimum value
    func heightPercent(_ percent: CGFloat, min minValue: CGFloat) -> CGFloat {
        max(minValue, height * percent)
    }
    
    /// Compute a width percentage with minimum value
    func widthPercent(_ percent: CGFloat, min minValue: CGFloat) -> CGFloat {
        max(minValue, width * percent)
    }
    
    /// Compute based on smallest dimension (useful for square elements)
    func minDimensionPercent(_ percent: CGFloat, min minValue: CGFloat) -> CGFloat {
        max(minValue, min(width, height) * percent)
    }
    
    /// Compute with scaling based on both dimensions
    func scaledValue(base: CGFloat, widthScale: CGFloat = 0.01, heightScale: CGFloat = 0.01) -> CGFloat {
        base + (width * widthScale) + (height * heightScale)
    }
}

// MARK: - View Extension for Convenience

extension View {
    /// Provides adaptive spacing for the current geometry
    func adaptiveSpacing(_ geometry: GeometryProxy) -> AdaptiveSpacing {
        AdaptiveSpacing(geometry: geometry)
    }
}

// MARK: - Environment Key for Global Access

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
    /// Injects adaptive spacing into the environment
    func withAdaptiveSpacing(_ geometry: GeometryProxy) -> some View {
        environment(\.adaptiveSpacing, AdaptiveSpacing(geometry: geometry))
    }
}
