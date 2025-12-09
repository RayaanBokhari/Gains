//
//  Colors.swift
//  Gains
//  Created by Rayaan Bokhari on 11/20/25.
//

import SwiftUI

extension Color {
    // MARK: - Background Layers (Apple Fitness Dark Mode Hierarchy)
    static let gainsBgPrimary = Color(hex: "000000")       // Pure black base
    static let gainsBgSecondary = Color(hex: "0D0D0D")     // Slightly elevated
    static let gainsBgTertiary = Color(hex: "1C1C1E")      // Apple's systemGray6
    
    // MARK: - Card & Surface Colors (Elevated with translucency feel)
    static let gainsCardSurface = Color(hex: "1C1C1E")     // Primary card bg
    static let gainsCardElevated = Color(hex: "2C2C2E")    // Higher elevation
    static let gainsCardGradientStart = Color(hex: "151515")
    static let gainsCardGradientEnd = Color(hex: "1A1A1C")
    
    // MARK: - Legacy compatibility (mapped to new system)
    static let gainsBackground = gainsBgPrimary
    static let gainsCardBackground = gainsCardSurface
    
    // MARK: - Fitness Blue Accent (Apple Fitness Primary)
    static let gainsPrimary = Color(hex: "0A84FF")         // Apple Blue
    static let gainsPrimaryLight = Color(hex: "409CFF")    // Lighter blue for gradients
    static let gainsPrimaryDark = Color(hex: "0066CC")     // Deeper blue
    static let gainsAccent = gainsPrimary
    static let gainsAccentBlue = Color(hex: "157AFF")      // Slightly deeper blue
    
    // MARK: - Secondary Accent Colors (Apple System Colors)
    static let gainsSecondary = Color(hex: "64D2FF")       // Apple Teal / Cyan
    static let gainsAccentGreen = Color(hex: "30D158")     // Apple Green - for success/finish
    static let gainsAccentGreenSoft = Color(hex: "34C759") // Softer green
    static let gainsAccentOrange = Color(hex: "FF9F0A")    // Apple Orange
    static let gainsAccentRed = Color(hex: "FF453A")       // Apple Red
    static let gainsAccentPurple = Color(hex: "BF5AF2")    // Apple Purple
    static let gainsAccentTeal = Color(hex: "64D2FF")      // Apple Teal
    static let gainsAccentPink = Color(hex: "FF375F")      // Apple Pink
    
    // MARK: - Semantic Colors
    static let gainsSuccess = gainsAccentGreen
    static let gainsWarning = gainsAccentOrange
    static let gainsError = gainsAccentRed
    
    // MARK: - Text Colors (iOS Typography Standards)
    static let gainsText = Color(hex: "FFFFFF")            // Primary text - pure white
    static let gainsTextPrimary = Color(hex: "FFFFFF")
    static let gainsTextSecondary = Color(hex: "8E8E93")   // Apple's secondaryLabel
    static let gainsSecondaryText = gainsTextSecondary
    static let gainsTextTertiary = Color(hex: "636366")    // Apple's tertiaryLabel
    static let gainsTextFaded = Color(hex: "545458")       // quaternaryLabel
    static let gainsTextMuted = Color(hex: "48484A")       // separator equivalent
    
    // MARK: - Interactive Elements
    static let gainsInputBackground = Color(hex: "1C1C1E") // Text field background
    static let gainsInputBorder = Color(hex: "38383A")     // Subtle border
    static let gainsSeparator = Color(hex: "38383A")       // Apple separator
    
    // MARK: - Progress & Indicators
    static let gainsProgressBackground = Color(hex: "2C2C2E")
    static let gainsProgressBlue = gainsPrimary.opacity(0.9)
    
    // MARK: - Icon Backgrounds (Soft tinted containers)
    static let gainsIconBgBlue = Color(hex: "0A84FF").opacity(0.15)
    static let gainsIconBgGreen = Color(hex: "30D158").opacity(0.15)
    static let gainsIconBgOrange = Color(hex: "FF9F0A").opacity(0.15)
    static let gainsIconBgPurple = Color(hex: "BF5AF2").opacity(0.15)
    
    // MARK: - Gradient Definitions
    static var gainsHeaderGradient: LinearGradient {
        LinearGradient(
            colors: [Color(hex: "000000"), Color(hex: "0A0A0A")],
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
            colors: [Color(hex: "000000"), Color(hex: "0D0D0D")],
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
    static var gainsPrimaryGradient: LinearGradient {
        LinearGradient(
            colors: [gainsPrimaryLight, gainsPrimary],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    static var gainsFinishGradient: LinearGradient {
        LinearGradient(
            colors: [Color(hex: "34C759"), Color(hex: "30D158")],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
    
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

// MARK: - Apple Fitness Design System Constants
struct GainsDesign {
    // MARK: - Corner Radius (Apple HIG inspired)
    static let cornerRadiusXS: CGFloat = 8
    static let cornerRadiusSmall: CGFloat = 12
    static let cornerRadiusMedium: CGFloat = 16
    static let cornerRadiusLarge: CGFloat = 22
    static let cornerRadiusXL: CGFloat = 26
    static let cornerRadiusPill: CGFloat = 100
    
    // MARK: - Spacing (8-point grid)
    static let spacingXXS: CGFloat = 2
    static let spacingXS: CGFloat = 4
    static let spacingS: CGFloat = 8
    static let spacingM: CGFloat = 12
    static let spacingL: CGFloat = 16
    static let spacingXL: CGFloat = 20
    static let spacingXXL: CGFloat = 24
    static let spacingXXXL: CGFloat = 32
    
    // MARK: - Padding
    static let paddingHorizontal: CGFloat = 20
    static let paddingVertical: CGFloat = 16
    static let titlePaddingTop: CGFloat = 16
    static let sectionSpacing: CGFloat = 24
    static let cardPadding: CGFloat = 18
    static let cardSpacing: CGFloat = 14
    
    // MARK: - Card Properties
    static let cardShadowRadius: CGFloat = 24
    static let cardShadowY: CGFloat = 8
    static let cardShadowOpacity: CGFloat = 0.12
    static let cardBorderWidth: CGFloat = 0.5
    
    // MARK: - Typography Sizes
    static let titleLarge: CGFloat = 34
    static let titleMedium: CGFloat = 28
    static let titleSmall: CGFloat = 22
    static let headline: CGFloat = 17
    static let body: CGFloat = 16
    static let callout: CGFloat = 15
    static let subheadline: CGFloat = 14
    static let footnote: CGFloat = 13
    static let caption: CGFloat = 12
    static let captionSmall: CGFloat = 11
    
    // MARK: - Button Heights
    static let buttonHeightSmall: CGFloat = 36
    static let buttonHeightMedium: CGFloat = 44
    static let buttonHeightLarge: CGFloat = 54
    
    // MARK: - Icon Sizes
    static let iconSmall: CGFloat = 16
    static let iconMedium: CGFloat = 20
    static let iconLarge: CGFloat = 24
    static let iconXL: CGFloat = 32
    static let iconContainerSmall: CGFloat = 36
    static let iconContainerMedium: CGFloat = 44
    static let iconContainerLarge: CGFloat = 56
}

// MARK: - View Modifiers for Apple Fitness Style
struct GainsCardStyle: ViewModifier {
    var padding: CGFloat = GainsDesign.cardPadding
    var cornerRadius: CGFloat = GainsDesign.cornerRadiusLarge
    
    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Color.gainsCardSurface)
                    .shadow(
                        color: Color.black.opacity(GainsDesign.cardShadowOpacity),
                        radius: GainsDesign.cardShadowRadius,
                        x: 0,
                        y: GainsDesign.cardShadowY
                    )
            )
    }
}

struct GlassCardStyle: ViewModifier {
    var cornerRadius: CGFloat = GainsDesign.cornerRadiusLarge
    
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(.ultraThinMaterial)
                    .environment(\.colorScheme, .dark)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(Color.white.opacity(0.06), lineWidth: GainsDesign.cardBorderWidth)
            )
    }
}

struct PillInputStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.system(size: GainsDesign.body, weight: .medium))
            .multilineTextAlignment(.center)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: GainsDesign.cornerRadiusSmall)
                    .fill(Color.gainsInputBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: GainsDesign.cornerRadiusSmall)
                    .stroke(Color.gainsInputBorder, lineWidth: 0.5)
            )
            .foregroundColor(.gainsText)
    }
}

extension View {
    func gainsCard(padding: CGFloat = GainsDesign.cardPadding, cornerRadius: CGFloat = GainsDesign.cornerRadiusLarge) -> some View {
        modifier(GainsCardStyle(padding: padding, cornerRadius: cornerRadius))
    }
    
    func glassCard(cornerRadius: CGFloat = GainsDesign.cornerRadiusLarge) -> some View {
        modifier(GlassCardStyle(cornerRadius: cornerRadius))
    }
    
    func pillInput() -> some View {
        modifier(PillInputStyle())
    }
}
