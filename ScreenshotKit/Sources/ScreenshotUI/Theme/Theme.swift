#if os(iOS)
import SwiftUI
import CaseEngine

/// Design tokens from the SCREENSHOT handoff (docs/design/README.md §C, §D, §E, §I).
/// « OS fictif conçu pour une enquête » : stepped blacks, white as action, amber as signal.
///
/// **Rule:** views never hard-code a colour, font, size, radius or duration — they read `Theme.*`.
public enum Theme {

    // MARK: Colours (§C)

    public enum Colors {
        /// Narrative screens: intro, notebook, accusation, results.
        public static let ink0 = Color(hex: 0x050607)
        /// Background of the phone's apps.
        public static let bgBase = Color(hex: 0x08090B)
        /// Cards, sheets.
        public static let bgSurface = Color(hex: 0x0F1114)
        /// Fields, tiles, grouped cells.
        public static let bgRaised = Color(hex: 0x16191D)
        /// Received bubbles, menus, toasts.
        public static let bgBubbleIn = Color(hex: 0x1C1F24)
        /// Avatars, inner chips.
        public static let bgElevated = Color(hex: 0x1E2227)
        /// Active segment, pressed state.
        public static let bgSelected = Color(hex: 0x2A2E34)

        /// Text, primary button, sent bubbles.
        public static let textPrimary = Color(hex: 0xECEAE6)
        public static let textSecondary = Color(hex: 0xA3A29D)
        /// Timestamps, captions (≥ 11 pt, never critical text).
        public static let textTertiary = Color(hex: 0x6B6B67)
        public static let textOnLight = Color(hex: 0x0B0C0E)

        /// Pinned, unread, progress, timer ≤ 01:00.
        public static let signal = Color(hex: 0xE3B158)
        public static let signalTint = Color(hex: 0xE3B158, opacity: 0.14)
        public static let signalLine = Color(hex: 0xE3B158, opacity: 0.45)
        /// Timer ≤ 00:10, missed call, error, destructive.
        public static let alert = Color(hex: 0xE5534B)
        public static let alertText = Color(hex: 0xFF6B61)
        public static let alertTint = Color(hex: 0xE5534B, opacity: 0.16)
        /// Location, tappable addresses.
        public static let trace = Color(hex: 0x7AB4DB)
        /// Solved (end screens only).
        public static let clear = Color(hex: 0x63C58E)

        public static let line1 = Color(hex: 0xECEAE6, opacity: 0.06)
        public static let line2 = Color(hex: 0xECEAE6, opacity: 0.10)
        public static let line3 = Color(hex: 0xECEAE6, opacity: 0.20)
        public static let scrim = Color.black.opacity(0.55)

        // Functional colours (polish pass): colour carries meaning, never decoration.
        /// Information, navigation, links, "you are here".
        public static let info = Color(hex: 0x5AA9F5)
        public static let infoTint = Color(hex: 0x5AA9F5, opacity: 0.16)
        /// Confirmed / found.
        public static let clearTint = Color(hex: 0x63C58E, opacity: 0.16)
        /// Investigation element: a link between an item and a suspect, the decision.
        public static let special = Color(hex: 0xB39DFA)
        public static let specialTint = Color(hex: 0xB39DFA, opacity: 0.16)

        /// Sent message bubbles (the familiar "my messages are coloured" convention).
        public static let bubbleOut = Color(hex: 0x2F7CF6)
        public static let bubbleOutText = Color(hex: 0xF5F7FA)

        /// The seized phone's body: brushed dark metal, glass edge, camera island.
        public static let deviceFrameTop = Color(hex: 0x3A3E45)
        public static let deviceFrameBottom = Color(hex: 0x1B1D21)
        public static let deviceEdge = Color(hex: 0x6C717A)
        public static let deviceBezel = Color(hex: 0x030304)
        public static let deviceButton = Color(hex: 0x2C2F35)
        public static let deviceGlare = Color(hex: 0xFFFFFF, opacity: 0.06)
        /// Behind the phone (the "desk"): a faint cold glow so the device stands out.
        public static let deskGlow = Color(hex: 0x1C2633)

        /// Wallpaper: deep night gradient with two soft lights.
        public static let wallpaperTop = Color(hex: 0x141B2E)
        public static let wallpaperBottom = Color(hex: 0x07080C)
        public static let wallpaperLightA = Color(hex: 0x3B4E9C, opacity: 0.55)
        public static let wallpaperLightB = Color(hex: 0x7A3E6E, opacity: 0.40)

        /// Stylised map (reads as a map: land, blocks, main roads, water, parks).
        public static let mapBackground = Color(hex: 0x1A1F24)
        public static let mapBlock = Color(hex: 0x21272D)
        public static let mapStreet = Color(hex: 0x39414A)
        public static let mapMainRoad = Color(hex: 0x6B6250)
        public static let mapRiver = Color(hex: 0x1D3A55)
        public static let mapPark = Color(hex: 0x1F3A2B)
        public static let mapPin = Color(hex: 0xF0544A)
        /// App icons: glass sheen, hairline edge, and the little map drawn on the Maps icon.
        public static let iconSheen = Color(hex: 0xFFFFFF, opacity: 0.22)
        public static let iconEdge = Color(hex: 0xFFFFFF, opacity: 0.14)
        public static let iconMapPark = Color(hex: 0x4E8F63)
        public static let iconMapRiver = Color(hex: 0x5FA8E8)
        public static let iconMapRoad = Color(hex: 0xF2C14E)
        public static let iconMapStreet = Color(hex: 0xF5F5F2, opacity: 0.55)
        public static let mapLabelHalo = Color(hex: 0x0B0D10, opacity: 0.85)
        /// Primary button pressed.
        public static let primaryPressed = Color(hex: 0xC9C7C2)
    }

    // MARK: Typography (§D) — three voices: Geist (UI), JetBrains Mono (data), Instrument Serif (narrative)

    public enum FontName {
        public static let light = "Geist-Light"
        public static let regular = "Geist-Regular"
        public static let medium = "Geist-Medium"
        public static let semibold = "Geist-SemiBold"
        public static let mono = "JetBrainsMono-Regular"
        public static let monoMedium = "JetBrainsMono-Medium"
        public static let monoSemibold = "JetBrainsMono-SemiBold"
        public static let monoBold = "JetBrainsMono-Bold"
        public static let serifItalic = "InstrumentSerif-Italic"
        public static let serif = "InstrumentSerif-Regular"
    }

    public enum Fonts {
        public static let display = Font.custom(FontName.semibold, size: 40, relativeTo: .largeTitle)
        public static let titleLarge = Font.custom(FontName.semibold, size: 34, relativeTo: .largeTitle)
        public static let title2 = Font.custom(FontName.semibold, size: 30, relativeTo: .title)
        public static let title = Font.custom(FontName.semibold, size: 22, relativeTo: .title2)
        public static let headline = Font.custom(FontName.semibold, size: 17, relativeTo: .headline)
        public static let body = Font.custom(FontName.regular, size: 15, relativeTo: .body)
        public static let bodyLarge = Font.custom(FontName.regular, size: 17, relativeTo: .body)
        public static let callout = Font.custom(FontName.regular, size: 14, relativeTo: .callout)
        public static let calloutStrong = Font.custom(FontName.semibold, size: 14, relativeTo: .callout)
        public static let caption = Font.custom(FontName.regular, size: 12, relativeTo: .caption)
        public static let tabLabel = Font.custom(FontName.regular, fixedSize: 11)
        /// "AFFAIRE 001" — mono caps, +14 % tracking (apply `.tracking(Theme.Tracking.overline)`).
        public static let overline = Font.custom(FontName.monoSemibold, size: 11, relativeTo: .caption2)
        public static let data = Font.custom(FontName.mono, size: 13, relativeTo: .footnote)
        public static let dataStrong = Font.custom(FontName.monoSemibold, size: 13, relativeTo: .footnote)
        public static let dataSmall = Font.custom(FontName.mono, size: 11, relativeTo: .caption2)
        public static let timer = Font.custom(FontName.monoSemibold, fixedSize: 14)
        public static let timerCritical = Font.custom(FontName.monoBold, fixedSize: 14)
        public static let timerIntro = Font.custom(FontName.monoSemibold, fixedSize: 34)
        public static let timerTimeUp = Font.custom(FontName.monoSemibold, fixedSize: 88)
        public static let timerScore = Font.custom(FontName.monoSemibold, fixedSize: 108)
        public static let narrative = Font.custom(FontName.serifItalic, size: 25, relativeTo: .title2)
        public static let narrativeSmall = Font.custom(FontName.serifItalic, size: 20, relativeTo: .title3)
        public static let homeClock = Font.custom(FontName.light, fixedSize: 64)
        public static let appTile = Font.custom(FontName.medium, fixedSize: 21)
        public static let notificationTitle = Font.custom(FontName.semibold, size: 14, relativeTo: .subheadline)
        public static let notificationBody = Font.custom(FontName.regular, size: 14, relativeTo: .subheadline)
        public static let logo = Font.custom(FontName.semibold, fixedSize: 26)
    }

    public enum Tracking {
        public static let overline: CGFloat = 1.5
        public static let logo: CGFloat = 8.8
        public static let timeUp: CGFloat = 4
        public static let display: CGFloat = -1.4
    }

    // MARK: Spacing, radius, sizes (§E)

    public enum Spacing {
        public static let s1: CGFloat = 2
        public static let s2: CGFloat = 4
        public static let s3: CGFloat = 8
        public static let s4: CGFloat = 12
        public static let s5: CGFloat = 16
        public static let s6: CGFloat = 20
        public static let s7: CGFloat = 24
        public static let s8: CGFloat = 32
        public static let s9: CGFloat = 48
        public static let s10: CGFloat = 64
        /// Screen margins: compact apps / lists / game screens.
        public static let marginCompact: CGFloat = 16
        public static let marginList: CGFloat = 20
        public static let marginGame: CGFloat = 24
        /// Bottom inset of scrollable content, above the notebook capsule.
        public static let bottomInset: CGFloat = 110
    }

    public enum Radius {
        public static let xs: CGFloat = 6
        public static let sm: CGFloat = 12
        public static let md: CGFloat = 14
        public static let icon: CGFloat = 17
        public static let lg: CGFloat = 20
        public static let bubble: CGFloat = 19
        public static let bubbleTail: CGFloat = 6
        public static let banner: CGFloat = 22
        public static let sheet: CGFloat = 28
        public static let dock: CGFloat = 30
    }

    public enum Size {
        public static let hit: CGFloat = 44
        /// The seized phone: outer body radius, bezel, frame thickness, camera island.
        public static let deviceRadius: CGFloat = 50
        public static let deviceFrame: CGFloat = 4
        public static let deviceBezel: CGFloat = 5
        public static let island = CGSize(width: 104, height: 30)
        /// Icon inside an app header.
        public static let headerIcon: CGFloat = 30
        public static let statusBar: CGFloat = 54
        public static let timerPill: CGFloat = 26
        public static let timerDot: CGFloat = 6
        public static let progressTrack: CGFloat = 2
        public static let carnetBar: CGFloat = 46
        public static let appTile: CGFloat = 62
        public static let badge: CGFloat = 20
        public static let avatarS: CGFloat = 36
        public static let avatarM: CGFloat = 48
        public static let avatarL: CGFloat = 96
        public static let portrait: CGFloat = 120
        public static let buttonL: CGFloat = 56
        public static let buttonM: CGFloat = 52
        public static let buttonS: CGFloat = 44
        public static let conversationRow: CGFloat = 78
        public static let callRow: CGFloat = 62
        public static let evidenceRow: CGFloat = 48
        public static let searchField: CGFloat = 40
        public static let segmented: CGFloat = 38
        public static let homeIndicator = CGSize(width: 134, height: 5)
        public static let mapHeight: CGFloat = 390
        public static let keypadKey: CGFloat = 72
        public static let photoBubble: CGFloat = 200
        public static let photoThumb: CGFloat = 110
        public static let unreadDot: CGFloat = 7
        public static let pinnedDot: CGFloat = 10
        public static let captureMark: CGFloat = 14
    }

    // MARK: Motion (§I)

    public enum Motion {
        public static let fast: Double = 0.15
        public static let base: Double = 0.26
        public static let slow: Double = 0.4
        public static let hero: Double = 0.8
        public static let holdToConfirm: Double = 0.9
        public static let revealStep: Double = 0.7
        public static let timeUpHold: Double = 1.8
        public static let introLine: Double = 0.4
        public static let introGap: Double = 0.6

        /// (.32, .72, 0, 1) — navigation, search.
        public static func standard(_ d: Double = 0.3) -> Animation { .timingCurve(0.32, 0.72, 0, 1, duration: d) }
        /// (.2, .8, .2, 1) — modals, reveals, pin.
        public static func emphasized(_ d: Double = 0.42) -> Animation { .timingCurve(0.2, 0.8, 0.2, 1, duration: d) }
        /// (.65, 0, .35, 1) — time up, unlock.
        public static func dramatic(_ d: Double = 0.7) -> Animation { .timingCurve(0.65, 0, 0.35, 1, duration: d) }
        public static var springApp: Animation { .interpolatingSpring(mass: 1, stiffness: 280, damping: 30) }
        public static var springSheet: Animation { .interpolatingSpring(mass: 1, stiffness: 260, damping: 32) }
        public static var springNotification: Animation { .interpolatingSpring(mass: 1, stiffness: 300, damping: 28) }
    }

    /// App icon: background gradient (top, bottom) and glyph colour. Original TRACE icons that
    /// follow familiar conventions (green handset, blue bubbles, a calendar page, a map with a pin…)
    /// without copying any real app.
    public static func iconGradient(_ app: AppKind) -> (top: Color, bottom: Color) {
        switch app {
        case .messages: (top: Color(hex: 0x4C9BFF), bottom: Color(hex: 0x1D5FD1))
        case .phone: (top: Color(hex: 0x4FD17F), bottom: Color(hex: 0x1C8E4A))
        case .photos: (top: Color(hex: 0xFFB547), bottom: Color(hex: 0xE2436E))
        case .location: (top: Color(hex: 0x2F5F4C), bottom: Color(hex: 0x1E3F33))
        case .calendar: (top: Color(hex: 0xF4F2EE), bottom: Color(hex: 0xDEDBD4))
        case .notes: (top: Color(hex: 0xF7F1DE), bottom: Color(hex: 0xE6DCC0))
        case .browser: (top: Color(hex: 0x3CC6D8), bottom: Color(hex: 0x127A93))
        case .mail: (top: Color(hex: 0x7C8CFF), bottom: Color(hex: 0x3D46C9))
        case .contacts: (top: Color(hex: 0x9CA1AA), bottom: Color(hex: 0x5E636C))
        case .trash: (top: Color(hex: 0xE2625A), bottom: Color(hex: 0x9B2C27))
        case .settings: (top: Color(hex: 0x8E949E), bottom: Color(hex: 0x484D55))
        case .notifications: (top: Color(hex: 0xB28CFF), bottom: Color(hex: 0x6B45D1))
        }
    }

    /// Glyph colour on the icon (dark on the two light "paper" icons).
    public static func iconGlyph(_ app: AppKind) -> Color {
        switch app {
        case .calendar, .notes: Color(hex: 0x1C1D20)
        default: Color(hex: 0xFAFAF8)
        }
    }

    /// Accent of an app, readable on the dark screens (headers, section titles, selected states).
    public static func appAccent(_ app: AppKind) -> Color {
        switch app {
        case .messages: Color(hex: 0x5AA9F5)
        case .phone: Color(hex: 0x5BD48A)
        case .photos: Color(hex: 0xFFB05C)
        case .location: Color(hex: 0x6FD3A8)
        case .calendar: Color(hex: 0xFF6B61)
        case .notes: Color(hex: 0xE3B158)
        case .browser: Color(hex: 0x4FD0E0)
        case .mail: Color(hex: 0x9AA6FF)
        case .contacts: Color(hex: 0xB9BEC6)
        case .trash: Color(hex: 0xFF6B61)
        case .settings: Color(hex: 0xB9BEC6)
        case .notifications: Color(hex: 0xB39DFA)
        }
    }

    /// Avatar disc colour from a contact's hue (muted, dark enough for light initials).
    public static func avatarColor(hue: Double) -> (top: Color, bottom: Color) {
        (top: Color(hue: hue, saturation: 0.38, brightness: 0.52), bottom: Color(hue: hue, saturation: 0.45, brightness: 0.34))
    }
}

// MARK: - Elevation & state modifiers (§E)

public extension View {
    /// e0: outline only.
    func elevation0(_ radius: CGFloat) -> some View {
        overlay(RoundedRectangle(cornerRadius: radius, style: .continuous).strokeBorder(Theme.Colors.line1, lineWidth: 1))
    }

    /// e1: floating (capsule, toast).
    func elevation1<S: InsettableShape>(_ shape: S) -> some View {
        overlay(shape.strokeBorder(Theme.Colors.line2, lineWidth: 1))
            .shadow(color: .black.opacity(0.5), radius: 16, y: 12)
    }

    /// e2: banner, menu.
    func elevation2() -> some View {
        shadow(color: .black.opacity(0.7), radius: 30, y: 24)
    }

    /// Pinned element: 2 pt amber ring + 10 pt dot (state is never colour alone: the dot is a symbol).
    func pinnedRing(_ pinned: Bool, radius: CGFloat) -> some View {
        overlay {
            if pinned {
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .strokeBorder(Theme.Colors.signal, lineWidth: 2)
            }
        }
        .overlay(alignment: .topTrailing) {
            if pinned {
                Circle().fill(Theme.Colors.signal)
                    .frame(width: Theme.Size.pinnedDot, height: Theme.Size.pinnedDot)
                    .offset(x: 3, y: -3)
                    .accessibilityLabel(Text(L10n.t("a11y.pinned")))
            }
        }
    }

    /// Overline style: mono caps with +14 % tracking.
    func overline(_ color: Color = Theme.Colors.textSecondary) -> some View {
        font(Theme.Fonts.overline).tracking(Theme.Tracking.overline).foregroundStyle(color).textCase(.uppercase)
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
