#if os(iOS)
import SwiftUI

/// Visual language of SCREENSHOT: a real, modern phone at night. Black, white, greys,
/// a few accents, transparency, blur, thin lines. No illustration, no cartoon.
///
/// **Rule:** views never hard-code a color, font, size or duration — they read `Theme.*`.
public enum Theme {
    public enum Colors {
        public static let background = Color.black
        public static let surface = Color(hex: 0x1C1C1E)
        public static let surfaceElevated = Color(hex: 0x2C2C2E)
        public static let surfaceHigh = Color(hex: 0x3A3A3C)
        public static let separator = Color.white.opacity(0.12)
        public static let textPrimary = Color.white
        public static let textSecondary = Color(hex: 0x8E8E93)
        public static let textTertiary = Color(hex: 0x636366)

        /// Investigation layer (timer, files, accusation) — distinct from the phone's own UI.
        public static let accent = Color(hex: 0x64D2FF)
        public static let alert = Color(hex: 0xFF453A)
        public static let success = Color(hex: 0x30D158)
        public static let warning = Color(hex: 0xFFD60A)

        /// Phone apps.
        public static let bubbleOwner = Color(hex: 0x0A84FF)
        public static let bubbleOther = Color(hex: 0x26262A)
        public static let link = Color(hex: 0x0A84FF)
        public static let missed = Color(hex: 0xFF453A)
        public static let recovered = Color(hex: 0xFFD60A)
        public static let mapBackground = Color(hex: 0x111418)
        public static let mapStreet = Color.white.opacity(0.07)
        public static let mapRiver = Color(hex: 0x16303F)
        public static let scrim = Color.black.opacity(0.6)
    }

    public enum Fonts {
        public static let wordmark = Font.system(size: 34, weight: .heavy, design: .default).width(.expanded)
        public static let display = Font.system(size: 30, weight: .bold)
        public static let title = Font.system(.title2, design: .default, weight: .bold)
        public static let headline = Font.system(.headline)
        public static let body = Font.system(.body)
        public static let callout = Font.system(.callout)
        public static let subheadline = Font.system(.subheadline)
        public static let footnote = Font.system(.footnote)
        public static let caption = Font.system(.caption)
        public static let caption2 = Font.system(.caption2)
        public static let overline = Font.system(size: 12, weight: .semibold).width(.expanded)
        /// The countdown: monospaced so digits don't jump.
        public static let timer = Font.system(size: 26, weight: .semibold, design: .monospaced)
        public static let timerSmall = Font.system(size: 15, weight: .semibold, design: .monospaced)
        public static let lockClock = Font.system(size: 64, weight: .semibold, design: .rounded)
        public static let appLabel = Font.system(size: 11, weight: .regular)
    }

    public enum Spacing {
        public static let xxs: CGFloat = 2
        public static let xs: CGFloat = 4
        public static let s: CGFloat = 8
        public static let m: CGFloat = 12
        public static let l: CGFloat = 16
        public static let xl: CGFloat = 24
        public static let xxl: CGFloat = 32
    }

    public enum Radius {
        public static let s: CGFloat = 8
        public static let m: CGFloat = 12
        public static let l: CGFloat = 18
        public static let bubble: CGFloat = 18
        public static let appIcon: CGFloat = 14
        public static let phone: CGFloat = 28
    }

    public enum Size {
        public static let hit: CGFloat = 44
        public static let appIcon: CGFloat = 60
        public static let avatarS: CGFloat = 32
        public static let avatarM: CGFloat = 44
        public static let avatarL: CGFloat = 88
        public static let photoThumb: CGFloat = 110
        public static let bannerIcon: CGFloat = 22
        public static let statusBarHeight: CGFloat = 22
        public static let homeIndicator = CGSize(width: 134, height: 5)
        public static let mapHeight: CGFloat = 300
        public static let keypadKey: CGFloat = 72
    }

    public enum Motion {
        public static let fast: Double = 0.18
        public static let normal: Double = 0.3
        public static let revealStep: Double = 0.9
        public static var spring: Animation { .spring(response: 0.35, dampingFraction: 0.85) }
        public static var snappy: Animation { .snappy(duration: 0.25) }
    }

    /// Tint of each app icon on the home screen: muted, recognisable, never childish.
    public static func appTint(_ app: AppKind) -> [Color] {
        switch app {
        case .messages: [Color(hex: 0x34C759), Color(hex: 0x248A3D)]
        case .phone: [Color(hex: 0x32D74B), Color(hex: 0x1F7A33)]
        case .photos: [Color(hex: 0xF2F2F7), Color(hex: 0xC7C7CC)]
        case .location: [Color(hex: 0x30B0C7), Color(hex: 0x1C6E7F)]
        case .calendar: [Color(hex: 0xF2F2F7), Color(hex: 0xD1D1D6)]
        case .notes: [Color(hex: 0xFFD60A), Color(hex: 0xC9A800)]
        case .browser: [Color(hex: 0x0A84FF), Color(hex: 0x0053B3)]
        case .mail: [Color(hex: 0x409CFF), Color(hex: 0x0A60D6)]
        case .contacts: [Color(hex: 0x8E8E93), Color(hex: 0x48484A)]
        case .trash: [Color(hex: 0x48484A), Color(hex: 0x1C1C1E)]
        case .settings: [Color(hex: 0x8E8E93), Color(hex: 0x3A3A3C)]
        case .notifications: [Color(hex: 0xFF453A), Color(hex: 0xB0261E)]
        }
    }
}

public extension Color {
    /// `Color(hex: 0xRRGGBB)` – only used inside `Theme`.
    init(hex: UInt32, opacity: Double = 1) {
        self.init(.sRGB,
                  red: Double((hex >> 16) & 0xFF) / 255,
                  green: Double((hex >> 8) & 0xFF) / 255,
                  blue: Double(hex & 0xFF) / 255,
                  opacity: opacity)
    }
}
#endif
