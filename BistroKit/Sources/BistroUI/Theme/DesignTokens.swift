import SwiftUI

/// Single source of truth for the look of the game.
///
/// **Rule:** views never hard-code a color, font, size, radius, shadow or duration.
/// They read `Theme.*`. When the Claude Design handoff arrives, only this file (and the
/// asset catalog) change. Values below are provisional placeholders.
public enum Theme {

    // MARK: Colors (semantic names, not "brown2")

    public enum Colors {
        public static let background = Color(hex: 0xFBF4EA)       // warm paper
        public static let surface = Color(hex: 0xFFFFFF)
        public static let surfaceMuted = Color(hex: 0xF3E6D3)
        public static let primary = Color(hex: 0xC8553D)          // terracotta
        public static let primaryPressed = Color(hex: 0xA8432E)
        public static let secondary = Color(hex: 0x588B8B)        // sage
        public static let accent = Color(hex: 0xF2B134)           // mustard
        public static let adReward = Color(hex: 0x6C5B9E)         // rewarded-ad buttons
        public static let textPrimary = Color(hex: 0x3B2A20)
        public static let textSecondary = Color(hex: 0x7A6656)
        public static let textOnPrimary = Color(hex: 0xFFFFFF)
        public static let coins = Color(hex: 0xE0A526)
        public static let gems = Color(hex: 0x4FA3C7)
        public static let success = Color(hex: 0x5E9E5B)
        public static let warning = Color(hex: 0xE38B29)
        public static let danger = Color(hex: 0xC0392B)
        public static let affinity = Color(hex: 0xE07A8B)
        public static let placeholderStroke = Color(hex: 0x3B2A20).opacity(0.35)
        public static let scrim = Color.black.opacity(0.4)
    }

    // MARK: Typography

    public enum Typography {
        public static let display = Font.system(size: 34, weight: .bold, design: .rounded)
        public static let title = Font.system(size: 24, weight: .bold, design: .rounded)
        public static let headline = Font.system(size: 18, weight: .semibold, design: .rounded)
        public static let body = Font.system(size: 16, weight: .regular, design: .rounded)
        public static let caption = Font.system(size: 13, weight: .medium, design: .rounded)
        public static let tiny = Font.system(size: 10, weight: .medium, design: .rounded)
        /// Currency counters and timers: monospaced digits so numbers don't jiggle.
        public static let number = Font.system(size: 18, weight: .bold, design: .rounded).monospacedDigit()
    }

    // MARK: Spacing (4-pt grid)

    public enum Spacing {
        public static let xxs: CGFloat = 2
        public static let xs: CGFloat = 4
        public static let sm: CGFloat = 8
        public static let md: CGFloat = 12
        public static let lg: CGFloat = 16
        public static let xl: CGFloat = 24
        public static let xxl: CGFloat = 32
    }

    // MARK: Corner radii

    public enum Radius {
        public static let sm: CGFloat = 8
        public static let md: CGFloat = 14
        public static let lg: CGFloat = 22
        public static let pill: CGFloat = 999
    }

    // MARK: Sizes

    public enum Size {
        public static let minTapTarget: CGFloat = 44
        public static let iconSm: CGFloat = 20
        public static let iconMd: CGFloat = 32
        public static let iconLg: CGFloat = 56
        public static let ingredientTile: CGFloat = 72
        public static let portrait: CGFloat = 96
        public static let buttonHeight: CGFloat = 52
    }

    // MARK: Shadows

    public struct ShadowToken: Sendable {
        public let color: Color
        public let radius: CGFloat
        public let x: CGFloat
        public let y: CGFloat
    }

    public enum Shadow {
        public static let card = ShadowToken(color: Color(hex: 0x3B2A20).opacity(0.10), radius: 6, x: 0, y: 3)
        public static let elevated = ShadowToken(color: Color(hex: 0x3B2A20).opacity(0.18), radius: 14, x: 0, y: 6)
    }

    // MARK: Motion (seconds)

    public enum Motion {
        public static let fast: Double = 0.15
        public static let normal: Double = 0.25
        public static let slow: Double = 0.45
        public static let celebration: Double = 1.2

        public static var standard: Animation { .easeInOut(duration: normal) }
        public static var bouncy: Animation { .spring(response: 0.35, dampingFraction: 0.6) }
    }
}

public extension View {
    func themeShadow(_ token: Theme.ShadowToken) -> some View {
        shadow(color: token.color, radius: token.radius, x: token.x, y: token.y)
    }
}

public extension Color {
    /// `Color(hex: 0xRRGGBB)` – only used inside `Theme`.
    init(hex: UInt32, opacity: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: opacity
        )
    }
}
