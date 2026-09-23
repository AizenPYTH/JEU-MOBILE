import SwiftUI

/// Single source of truth for the look of the game — values from the Claude Design handoff
/// (docs/design, "Bistro Handoff" §02 Tokens, direction « Riso chaud »).
///
/// **Rule:** views never hard-code a color, font, size, radius, border, shadow or duration.
/// Token names mirror the handoff: `color.bg.paper` → `Theme.Colors.bgPaper`,
/// `type.title.m` → `Theme.Typography.titleM`, `radius.l` → `Theme.Radius.l`…
public enum Theme {

    // MARK: - Colors

    public enum Colors {
        // Backgrounds & surfaces
        public static let bgPaper = Color(hex: 0xF4E8D2)
        public static let bgScene = Color(hex: 0xEFDDBF)
        public static let surfaceCard = Color(hex: 0xFBF4E6)
        public static let surfaceSunk = Color(hex: 0xEADBC0)
        public static let surfaceInverse = Color(hex: 0x4A2C20)
        public static let scrim = Color(hex: 0x2A1810, opacity: 0.55)

        // Ink (text & strokes) — never pure black
        public static let inkPrimary = Color(hex: 0x4A2C20)
        public static let inkSecondary = Color(hex: 0x7A5A48)
        /// Always paired with an icon (disabled state never relies on color alone).
        public static let inkDisabled = Color(hex: 0x9C8570)
        public static let inkInverse = Color(hex: 0xFBF4E6)
        public static let lineSoft = Color(hex: 0xD5C3A4)

        // Accent inks & states
        public static let accentGold = Color(hex: 0xEBAA2F)
        public static let accentGoldSoft = Color(hex: 0xF6D27A)
        /// Shapes, badges, offset shadows. Never for body text (4.0:1).
        public static let accentSanguine = Color(hex: 0xC9533A)
        /// Rewarded ads, plants.
        public static let accentVerdigris = Color(hex: 0x3F7A6E)
        public static let stateSuccess = Color(hex: 0x33665B)
        public static let stateAlert = Color(hex: 0xA33A24)

        // Currencies
        public static let currencyCoin = Color(hex: 0xEBAA2F)
        public static let currencyGem = Color(hex: 0x3F7A6E)

        // Rarity (always with frame + dots, never color alone)
        public static let rarityCommon = Color(hex: 0x4A2C20)
        public static let rarityRare = Color(hex: 0x4A2C20)
        public static let rarityRefined = Color(hex: 0x3F7A6E)
        public static let rarityLegendary = Color(hex: 0xF6D27A)

        // Illustration inks
        public static let artWood = Color(hex: 0xD9A76A)
        public static let artCopper = Color(hex: 0xD9893A)
        public static let artGrey = Color(hex: 0xEDE2CF)
        public static let artDark = Color(hex: 0x2E2220)
    }

    // MARK: - Typography

    /// A text style: font + line height + largest Dynamic Type size allowed.
    public struct TextToken: @unchecked Sendable { // immutable; Font.TextStyle is not Sendable in every SDK
        public let fontName: String
        public let size: CGFloat
        public let lineHeight: CGFloat
        /// nil = fixed size (HUD numbers).
        public let relativeTo: Font.TextStyle?
        public let maxDynamicType: DynamicTypeSize

        public var font: Font {
            if let relativeTo {
                return .custom(fontName, size: size, relativeTo: relativeTo)
            }
            return .custom(fontName, fixedSize: size)
        }

        /// Extra spacing between lines to reach the token's line height.
        public var lineSpacing: CGFloat { max(0, lineHeight - size * 1.2) }
    }

    public enum FontName {
        public static let regular = "BricolageGrotesque-Regular"
        public static let medium = "BricolageGrotesque-Medium"
        public static let bold = "BricolageGrotesque-Bold"
        public static let extraBold = "BricolageGrotesque-ExtraBold"
        public static let monoSemiBold = "IBMPlexMono-SemiBold"
    }

    public enum Typography {
        public static let display = TextToken(fontName: FontName.extraBold, size: 34, lineHeight: 40, relativeTo: .largeTitle, maxDynamicType: .xxxLarge)
        public static let titleL = TextToken(fontName: FontName.extraBold, size: 26, lineHeight: 32, relativeTo: .title, maxDynamicType: .xxxLarge)
        public static let titleM = TextToken(fontName: FontName.bold, size: 21, lineHeight: 26, relativeTo: .title2, maxDynamicType: .xxxLarge)
        public static let titleS = TextToken(fontName: FontName.bold, size: 17, lineHeight: 22, relativeTo: .headline, maxDynamicType: .xxxLarge)
        public static let bodyL = TextToken(fontName: FontName.regular, size: 17, lineHeight: 24, relativeTo: .body, maxDynamicType: .accessibility3)
        public static let bodyM = TextToken(fontName: FontName.medium, size: 15, lineHeight: 21, relativeTo: .callout, maxDynamicType: .accessibility3)
        public static let caption = TextToken(fontName: FontName.medium, size: 13, lineHeight: 18, relativeTo: .footnote, maxDynamicType: .accessibility3)
        public static let labelButton = TextToken(fontName: FontName.extraBold, size: 17, lineHeight: 20, relativeTo: .headline, maxDynamicType: .xxLarge)
        public static let labelTab = TextToken(fontName: FontName.extraBold, size: 12, lineHeight: 14, relativeTo: .caption2, maxDynamicType: .xLarge)
        /// Monospaced digits so counters don't jiggle.
        public static let numberHud = TextToken(fontName: FontName.monoSemiBold, size: 15, lineHeight: 18, relativeTo: nil, maxDynamicType: .large)
        public static let numberL = TextToken(fontName: FontName.monoSemiBold, size: 22, lineHeight: 26, relativeTo: .title2, maxDynamicType: .xxxLarge)
        public static let numberXL = TextToken(fontName: FontName.monoSemiBold, size: 40, lineHeight: 44, relativeTo: .largeTitle, maxDynamicType: .xxxLarge)
    }

    // MARK: - Spacing (4-pt scale) & layout

    public enum Spacing {
        public static let s1: CGFloat = 4
        public static let s2: CGFloat = 8
        public static let s3: CGFloat = 12
        public static let s4: CGFloat = 16
        public static let s5: CGFloat = 20
        public static let s6: CGFloat = 24
        public static let s8: CGFloat = 32
        public static let s10: CGFloat = 40
        public static let s12: CGFloat = 48
        public static let s16: CGFloat = 64
    }

    public enum Layout {
        /// Screen side margin: 16 on small phones (SE), 20 from 390 pt wide.
        public static func margin(forWidth width: CGFloat) -> CGFloat { width >= 390 ? 20 : 16 }
        public static let defaultMargin: CGFloat = 20
        /// Minimum touch target.
        public static let hit: CGFloat = 44
    }

    // MARK: - Radii

    public enum Radius {
        /// Chips, badges.
        public static let s: CGFloat = 6
        /// Dish cards.
        public static let m: CGFloat = 12
        /// Buttons, bubbles, cards.
        public static let l: CGFloat = 16
        /// Popups.
        public static let xl: CGFloat = 24
        /// Top of bottom sheets and of the action bar.
        public static let sheet: CGFloat = 28
        public static let pill: CGFloat = 999
    }

    // MARK: - Borders

    public enum Border {
        /// Separators (with `Colors.lineSoft`).
        public static let hair: CGFloat = 1.5
        /// Cards, pills, bubbles (with `Colors.inkPrimary`).
        public static let ui: CGFloat = 2.5
        /// Buttons, popups.
        public static let strong: CGFloat = 3.5
    }

    // MARK: - Shadows

    /// Ink-offset shadow: no blur, just a copy of the shape shifted by (x, y) — the riso "misregistration".
    public struct InkShadow: Sendable {
        public let color: Color
        public let x: CGFloat
        public let y: CGFloat
    }

    public enum Shadow {
        public static let s = InkShadow(color: Colors.inkPrimary, x: 2, y: 2)
        public static let m = InkShadow(color: Colors.accentSanguine, x: 4, y: 4)
        public static let reward = InkShadow(color: Colors.accentGold, x: 4, y: 4)
        /// The only blurred shadow, for sheets and the action bar.
        public static let sheetColor = Colors.inkPrimary.opacity(0.18)
        public static let sheetRadius: CGFloat = 24
        public static let sheetY: CGFloat = -8
    }

    // MARK: - Sizes of specific components

    public enum Size {
        public static let buttonPrimaryHeight: CGFloat = 56
        public static let buttonSecondaryHeight: CGFloat = 48
        public static let hudCurrencyHeight: CGFloat = 38
        public static let hudIcon: CGFloat = 26
        public static let settingsButton: CGFloat = 40
        public static let actionBarHeight: CGFloat = 106
        public static let labButton: CGFloat = 78
        public static let labButtonOverhang: CGFloat = 36
        public static let tabIcon: CGFloat = 30
        public static let progressHeight: CGFloat = 12
        public static let badgeDot: CGFloat = 14
        public static let badgeCounter: CGFloat = 22
        public static let dishCardVisual: CGFloat = 88
        public static let menuRowHeight: CGFloat = 72
        public static let iconS: CGFloat = 20
        public static let iconM: CGFloat = 30
        public static let portraitCard: CGFloat = 64
        public static let stationThumb: CGFloat = 70
        /// Illustration of an empty state / coming-soon screen.
        public static let emptyStateArt: CGFloat = 160
        /// ui_lab_pot (150 × 128 in the lab and on the loading screen).
        public static let labPot = CGSize(width: 150, height: 128)
    }

    // MARK: - Motion

    public enum Motion {
        /// Press.
        public static let instant: Double = 0.10
        /// Exits, fades.
        public static let fast: Double = 0.16
        /// Bubble appearance.
        public static let base: Double = 0.24
        /// Sheets, hints.
        public static let slow: Double = 0.40
        /// Level up, zone opening.
        public static let celebrate: Double = 0.90
        public static let coinCollect: Double = 0.52

        public static func easeOut(_ duration: Double) -> Animation { .timingCurve(0.2, 0.8, 0.2, 1, duration: duration) }
        public static func easeIn(_ duration: Double) -> Animation { .timingCurve(0.4, 0, 1, 1, duration: duration) }
        public static func easeInOut(_ duration: Double) -> Animation { .timingCurve(0.45, 0, 0.25, 1, duration: duration) }
        /// Popups, stamps.
        public static var springPop: Animation { .spring(response: 0.35, dampingFraction: 0.68) }
        /// Cards, floating.
        public static var springSoft: Animation { .spring(response: 0.5, dampingFraction: 0.86) }
        /// What springs become with "Reduce Motion": a 160 ms fade.
        public static var reduced: Animation { .easeInOut(duration: fast) }
    }
}

// MARK: - View helpers

public extension View {
    /// Applies a text token: font, line spacing and Dynamic Type ceiling.
    func typography(_ token: Theme.TextToken) -> some View {
        font(token.font)
            .lineSpacing(token.lineSpacing)
            .dynamicTypeSize(...token.maxDynamicType)
    }

    /// Draws `shape` in the shadow ink behind the view, offset by the token (riso misregistration).
    func inkShadow<S: Shape>(_ token: Theme.InkShadow, in shape: S, pressed: Bool = false) -> some View {
        background(
            shape.fill(token.color)
                .offset(x: pressed ? 0 : token.x, y: pressed ? 0 : token.y)
        )
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
