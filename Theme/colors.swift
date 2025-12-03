//
//  Colors.swift
//  Gains
//  Created by Rayaan Bokhari on 11/20/25.
//

import SwiftUI

extension Color {
    // MARK: - Background Layers (Proper depth hierarchy)
    static let gainsBgPrimary = Color(hex: "0B0B0D")      // Almost black, slightly blue
    static let gainsBgSecondary = Color(hex: "111113")    // Slightly lighter
    static let gainsBgTertiary = Color(hex: "1A1A1D")     // Even lighter for depth
    
    // MARK: - Card & Surface Colors
    static let gainsCardSurface = Color(hex: "161618")    // Card background - lighter than bg
    static let gainsCardGradientStart = Color(hex: "131316")
    static let gainsCardGradientEnd = Color(hex: "1A1A1D")
    
    // MARK: - Legacy compatibility (mapped to new system)
    static let gainsBackground = gainsBgPrimary
    static let gainsCardBackground = gainsCardSurface
    
    // MARK: - Accent Colors (Apple-style)
    static let gainsPrimary = Color(hex: "0A84FF")        // Apple Blue
    static let gainsAccent = gainsPrimary
    static let gainsAccentBlue = Color(hex: "157AFF")     // Slightly deeper blue
    static let gainsAccentGreen = Color(hex: "30D158")    // Apple Green
    static let gainsAccentOrange = Color(hex: "FF9F0A")   // Apple Orange
    static let gainsAccentRed = Color(hex: "FF453A")      // Apple Red
    static let gainsAccentPurple = Color(hex: "BF5AF2")   // Apple Purple
    static let gainsAccentTeal = Color(hex: "64D2FF")     // Apple Teal
    
    // MARK: - Text Colors (Semantic)
    static let gainsText = Color.white
    static let gainsTextPrimary = Color.white
    static let gainsTextSecondary = Color(hex: "B5B5B8")  // Muted gray
    static let gainsSecondaryText = gainsTextSecondary    // Legacy compatibility
    static let gainsTextFaded = Color(hex: "7A7A7D")      // Very muted
    static let gainsTextMuted = Color(hex: "636366")      // System gray 3
    
    // MARK: - Progress Bar Colors
    static let gainsProgressBackground = Color(hex: "242428")
    static let gainsProgressBlue = Color(hex: "157AFF").opacity(0.85)
    
    // MARK: - Gradient Definitions
    static var gainsHeaderGradient: LinearGradient {
        LinearGradient(
            colors: [Color(hex: "0D0E14"), Color(hex: "0A0A0B")],
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
    static var gainsCardGradient: LinearGradient {
        LinearGradient(
            colors: [gainsCardGradientStart, gainsCardGradientEnd],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    static var gainsBackgroundGradient: LinearGradient {
        LinearGradient(
            colors: [Color(hex: "0D0E11"), Color(hex: "0A0A0B")],
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
    // MARK: - Flame/Fire Gradient for calories
    static var gainsFlameGradient: LinearGradient {
        LinearGradient(
            colors: [Color(hex: "FF6B35"), Color(hex: "FF9500")],
            startPoint: .bottom,
            endPoint: .top
        )
    }
}

// MARK: - Hex Color Extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Design System Constants
struct GainsDesign {
    // Corner Radius
    static let cornerRadiusSmall: CGFloat = 12
    static let cornerRadiusMedium: CGFloat = 16
    static let cornerRadiusLarge: CGFloat = 20
    static let cornerRadiusPill: CGFloat = 24
    
    // Spacing
    static let spacingXS: CGFloat = 4
    static let spacingS: CGFloat = 8
    static let spacingM: CGFloat = 12
    static let spacingL: CGFloat = 16
    static let spacingXL: CGFloat = 24
    static let spacingXXL: CGFloat = 32
    
    // Padding
    static let paddingHorizontal: CGFloat = 20
    static let paddingVertical: CGFloat = 16
    static let titlePaddingTop: CGFloat = 32
    static let sectionSpacing: CGFloat = 24
    static let cardSpacing: CGFloat = 14
    
    // Card
    static let cardShadowRadius: CGFloat = 20
    static let cardShadowY: CGFloat = 4
    static let cardShadowOpacity: CGFloat = 0.2
    
    // Button Heights
    static let buttonHeightSmall: CGFloat = 36
    static let buttonHeightMedium: CGFloat = 44
    static let buttonHeightLarge: CGFloat = 52
}
