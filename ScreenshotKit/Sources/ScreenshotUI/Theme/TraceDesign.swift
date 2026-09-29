#if os(iOS)
import SwiftUI
import UIKit
import CaseEngine

/// CONCLUDE design — handoff UX V3 « Digital Investigation Interface » (docs/design_ux_v3).
/// The BEN is professional investigation software: dark blue-graphite, flat surfaces, Newsreader
/// for titles, IBM Plex Sans for the interface, IBM Plex Mono for data only (times, numbers, timer).
/// No texture, no rotation, no drop shadow on dark. The seized phone is the only light thing (the
/// `Theme` tokens). Paper survives only as content: a document of the case shown in a piece.
///
/// The former « paper » names (paper, kraft, ink, bone, stamp…) are kept as aliases of the V3
/// tokens so every screen reads the same palette; new code uses the V3 names (`bg`, `surface`,
/// `text`, `ben`…).
enum Trace {
    enum Colors {
        // MARK: V3 tokens (§3)
        /// Background of the BEN screens.
        static let bg = Color(hex: 0x0B0E13)
        /// Conclusion, verification: the solemn moment.
        static let bgDeep = Color(hex: 0x07090C)
        /// Cards.
        static let surface = Color(hex: 0x141A22)
        /// Controls, secondary buttons, fields.
        static let surface2 = Color(hex: 0x1C242F)
        /// Active segment, fallback avatars.
        static let surface3 = Color(hex: 0x2A3442)
        /// Rules and card borders (1 pt, inset).
        static let line = Color(hex: 0xD6E0EC, opacity: 0.08)
        /// Main text.
        static let text = Color(hex: 0xEEF1F4)
        /// Secondary text (7.6:1 on bg).
        static let text2 = Color(hex: 0x9AA6B4)
        /// Disabled, tertiary meta (≥ 14 pt only).
        static let text3 = Color(hex: 0x6F7C8C)
        /// Main action (white text, 4.9:1), selection.
        static let ben = Color(hex: 0x3F6FC2)
        static let benPressed = Color(hex: 0x345EA8)
        /// Links, file and piece numbers, « ‹ Retour ».
        static let benText = Color(hex: 0x8FB2EE)
        /// Accusation, failure, error, the phone's unread badge.
        static let critical = Color(hex: 0xE5484D)
        static let criticalOnDark = Color(hex: 0xF07B7F)
        /// Filed, solved.
        static let success = Color(hex: 0x3FB27F)
        static let successText = Color(hex: 0x6FD3A4)
        /// Contradiction, missed clue, the timer under 01:00.
        static let warning = Color(hex: 0xE8A03A)
        /// White text on a filled button.
        static let onFill = Color(hex: 0xFFFFFF)

        /// Background of a semantic badge: the colour at 16 %.
        static func tint(_ color: Color) -> Color { color.opacity(0.16) }

        // MARK: Former names (aliases of the V3 tokens)
        static let desk = bg
        static let launch = bg
        static let deskLight = surface
        static let graphite = surface2
        static let tabBar = bg
        static let paper = surface
        static let paperAged = surface
        static let print = surface2
        static let notebook = surface
        static let noteYellow = surface2
        static let label = surface2
        static let kraft = surface
        static let kraftDark = surface
        static let kraftLight = surface2
        static let kraftMid = surface2
        static let kraftSealed = surface3
        static let kraftInk = text
        static let kraftLabel = text2
        static let ink = text
        static let inkSoft = text2
        static let inkFaint = text3
        static let bone = text
        static let bone2 = text2
        static let bone3 = text3
        /// The former red accent: now the BEN's accent (links, numbers, kickers). Real failure
        /// and accusation use `critical`.
        static let stamp = benText
        static let stampOnDark = criticalOnDark
        static let stampDeep = surface2
        static let stampText = onFill
        static let pen = benText
        static let metal = text3
        static let tape = Color.clear
        static let ruled = line
        static let notebookRule = Color.clear
        static let marginRed = Color.clear
        static let highlight = ben.opacity(0.16)
        static let shadow = Color.clear
    }

    enum FontName {
        static let serif = "Newsreader-Regular"
        static let serifMedium = "Newsreader-Medium"
        static let serifSemibold = "Newsreader-SemiBold"
        static let serifItalic = "Newsreader-Italic"
        static let sans = "IBMPlexSans"
        static let sansMedium = "IBMPlexSans-Medm"
        static let sansSemibold = "IBMPlexSans-SmBld"
        static let sansBold = "IBMPlexSans-Bold"
        static let mono = "IBMPlexMono-Regular"
        static let monoMedium = "IBMPlexMono-Medium"
        static let monoSemibold = "IBMPlexMono-SemiBold"
        static let monoBold = "IBMPlexMono-Bold"
        /// Handwriting is gone (V3): the player's own words are Plex Sans.
        static let hand = sans
    }

    /// Type roles (§3 « Typographie »). Three families; the system font is the phone's.
    enum Fonts {
        // V3 roles
        /// Newsreader 36/500: the conclusion's question.
        static let display = Font.custom(FontName.serifMedium, size: 36, relativeTo: .largeTitle)
        /// Newsreader 31/500: screen and case titles.
        static let title = Font.custom(FontName.serifMedium, size: 31, relativeTo: .title)
        /// Plex Sans 18/600: a suspect's name, a card title.
        static let headline = Font.custom(FontName.sansSemibold, size: 18, relativeTo: .headline)
        /// Plex Sans 16: context, mission.
        static let body = Font.custom(FontName.sans, size: 16, relativeTo: .body)
        /// Plex Sans 15: card content.
        static let callout = Font.custom(FontName.sans, size: 15, relativeTo: .callout)
        /// Plex Sans 12/600 caps +8 %: section headers — the only capitals.
        static let section = Font.custom(FontName.sansSemibold, size: 12, relativeTo: .caption)
        /// Plex Sans 13: meta.
        static let caption = Font.custom(FontName.sans, size: 13, relativeTo: .footnote)
        /// Plex Mono 12/600: PIÈCE 03, #001.
        static let data = Font.custom(FontName.monoSemibold, size: 12, relativeTo: .caption)
        /// Plex Mono 20/500: the timer, big figures.
        static let dataLarge = Font.custom(FontName.monoMedium, size: 20, relativeTo: .title3)

        // Former names, mapped on the V3 roles
        static let wordmark = Font.custom(FontName.monoSemibold, fixedSize: 15)
        static let caseTitle = title
        static let screenTitle = title
        static let name = headline
        static let nameLarge = Font.custom(FontName.serifMedium, size: 26, relativeTo: .title2)
        static let prose = body
        static let proseSmall = Font.custom(FontName.sans, size: 14, relativeTo: .callout)
        static let quote = Font.custom(FontName.serif, size: 19, relativeTo: .body)
        static let quoteLarge = Font.custom(FontName.serif, size: 22, relativeTo: .title3)
        static let fieldLabel = section
        static let fieldValue = data
        static let fieldValueLarge = Font.custom(FontName.monoSemibold, size: 14, relativeTo: .callout)
        static let pieceNumber = Font.custom(FontName.monoSemibold, size: 11, relativeTo: .caption2)
        static let pieceTitle = Font.custom(FontName.monoMedium, size: 19, relativeTo: .title3)
        static let button = Font.custom(FontName.sansSemibold, size: 17, relativeTo: .body)
        static let mono = Font.custom(FontName.mono, size: 12, relativeTo: .caption)
        static let monoSmall = Font.custom(FontName.mono, size: 11, relativeTo: .caption2)
        static let hand = Font.custom(FontName.sans, size: 17, relativeTo: .body)
        static let handSmall = Font.custom(FontName.sans, size: 15, relativeTo: .callout)
        static let ui = Font.custom(FontName.sans, size: 14, relativeTo: .callout)
        static let uiSmall = Font.custom(FontName.sansMedium, size: 11, relativeTo: .caption2)
        static let score = Font.custom(FontName.monoMedium, fixedSize: 64)
        static func stamp(_ size: CGFloat) -> Font { .custom(FontName.sansSemibold, fixedSize: max(11, size)) }
    }

    /// Radii (§3): badge 13 (pill) · segmented 12 (segment 9) · button 14 · card 16 · large card 20 · sheet 20.
    enum Radius {
        static let badge: CGFloat = 13
        static let segmented: CGFloat = 12
        static let segment: CGFloat = 9
        static let button: CGFloat = 14
        static let card: CGFloat = 16
        static let largeCard: CGFloat = 20
        static let sheet: CGFloat = 20
        static let node: CGFloat = 12
    }

    /// Heights (§3).
    enum Height {
        static let button: CGFloat = 56
        static let hold: CGFloat = 60
        static let row: CGFloat = 50
        static let segment: CGFloat = 40
        static let tabBar: CGFloat = 82
        static let investigationBar: CGFloat = 92
        static let badge: CGFloat = 26
        static let hit: CGFloat = 44
    }

    enum Motion {
        static let standard = Animation.timingCurve(0.32, 0.72, 0, 1, duration: 0.3)
        static let emphasized = Animation.timingCurve(0.2, 0.8, 0.2, 1, duration: 0.42)
        static let dramatic = Animation.timingCurve(0.65, 0, 0.35, 1, duration: 0.6)
        static let stamp = Animation.easeIn(duration: 0.18)
        /// Carnet tab: 250 ms spring.
        static let tab = Animation.spring(response: 0.25, dampingFraction: 0.85)
        static let sheet = Animation.spring(response: 0.26, dampingFraction: 0.86)
        /// Screen content and cards: spring(0.35, 0.9).
        static let paper = Animation.spring(response: 0.35, dampingFraction: 0.9)
        /// Hold to conclude: 1.6 s (§8).
        static let holdToClose: Double = 1.6
        /// Verification: 1.8 s, three lines every 0.5 s.
        static let verification: Double = 1.8
    }

    /// Items no longer lie crooked (V3: no rotation). Kept for callers: always 0.
    static func tilt(_ seed: String, range: Double = 2) -> Double { 0 }
}

// MARK: - Surfaces

extension View {
    /// A card (V3 §3 « Profondeur »): flat fill, 1 pt `line` border inset, no shadow. The former
    /// paper sheet: `radius` under 8 means « the default card radius ».
    func paper(_ color: Color = Trace.Colors.surface, radius: CGFloat = 2, lifted: Bool = false) -> some View {
        let r = radius < 8 ? Trace.Radius.card : radius
        return background(
            RoundedRectangle(cornerRadius: r, style: .continuous)
                .fill(color)
                .overlay(RoundedRectangle(cornerRadius: r, style: .continuous).strokeBorder(Trace.Colors.line, lineWidth: 1))
        )
    }

    /// A card: `surface` with its inset rule.
    func benCard(_ color: Color = Trace.Colors.surface, radius: CGFloat = Trace.Radius.card) -> some View {
        paper(color, radius: radius)
    }

    /// The former kraft folder: a large card.
    func kraft(radius: CGFloat = 10, color: Color = Trace.Colors.surface) -> some View {
        paper(color, radius: Trace.Radius.largeCard)
    }

    /// No rotation any more (V3); kept for callers.
    func tilt(_ seed: String, range: Double = 2) -> some View { self }

    /// Section header style: Plex Sans 12/600, caps, +8 %.
    func fieldLabel(_ color: Color = Trace.Colors.text2) -> some View {
        font(Trace.Fonts.section).tracking(1).foregroundStyle(color).textCase(.uppercase)
    }

    /// Pressed state of a tappable card: scale 0.98 + darker, 90 ms.
    func pressable() -> some View { buttonStyle(PressableStyle()) }
}

/// Paper grain is gone (V3: no texture on the interface). Kept as an empty layer for callers.
struct PaperGrain: View {
    var intensity: Double = 0.035
    var texture = "tex_paper_grain"

    var body: some View {
        Color.clear.allowsHitTesting(false).accessibilityHidden(true)
    }
}

/// The BEN background: flat `bg`.
struct TraceDesk: View {
    var body: some View {
        Trace.Colors.bg.ignoresSafeArea().accessibilityHidden(true)
    }
}

/// Ruled lines are gone (V3). Kept as an empty layer for callers.
struct RuledLines: View {
    var spacing: CGFloat = 28
    var color: Color = Trace.Colors.ruled
    var margin: CGFloat? = nil

    var body: some View {
        Color.clear.allowsHitTesting(false).accessibilityHidden(true)
    }
}

// MARK: - Office objects (gone in V3: no staple, tape or clip on the interface)

struct Staple: View {
    var body: some View { EmptyView() }
}

struct Tape: View {
    var width: CGFloat = 54
    var body: some View { EmptyView() }
}

struct Paperclip: View {
    var body: some View { EmptyView() }
}

/// A photo in a card: rounded 12 pt corners, an optional caption under it (no white border).
struct PhotoPrint<Content: View>: View {
    var caption: String? = nil
    var border: CGFloat = 5
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            content
                .clipShape(RoundedRectangle(cornerRadius: Trace.Radius.node, style: .continuous))
            if let caption {
                Text(caption).font(Trace.Fonts.caption).foregroundStyle(Trace.Colors.text2).lineLimit(1)
            }
        }
    }
}

/// An identity photo: the delivered photo, or the initials on `surface3` (never a drawn face).
struct IDPhoto: View {
    let contact: Contact?
    var width: CGFloat = 70
    var height: CGFloat = 84
    @Environment(\.caseNumber) private var caseNumber

    var body: some View {
        let image = ArtLibrary.portrait(case: caseNumber, contact: contact)
        PortraitOrInitials(image: image, initials: Self.initials(of: contact?.name ?? ""), width: width, height: height)
            .clipShape(RoundedRectangle(cornerRadius: Trace.Radius.node, style: .continuous))
    }

    /// « Emma Roussel » → « ER »
    static func initials(of name: String) -> String {
        name.split(separator: " ").prefix(2).compactMap { $0.first.map { String($0).uppercased() } }.joined()
    }
}

// MARK: - Status badges (the former stamps)

/// StatusBadge (§5): a 26 pt pill, symbol + label, the colour at 16 % behind — never the colour
/// alone. The former administrative stamp: same call, no rotation, no ink. The only real stamp
/// left is the RÉSOLU PNG on a case card (`StampImage`).
struct StampMark: View {
    let text: String
    var color: Color = Trace.Colors.benText
    var size: CGFloat = 12
    var dashed = false
    var angle: Double = -6
    var filled = false
    /// A leading symbol (● ◐ # ✓ ✕ ↑ ↓ ≠); by default from the colour's meaning.
    var symbol: String? = nil

    var body: some View {
        StatusBadge(text: text, color: color, symbol: symbol)
    }
}

struct StatusBadge: View {
    let text: String
    var color: Color = Trace.Colors.benText
    var symbol: String? = nil

    var body: some View {
        HStack(spacing: 5) {
            if let symbol {
                Text(verbatim: symbol).font(Trace.Fonts.section)
            }
            Text(text)
                .font(Trace.Fonts.section)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .foregroundStyle(color)
        .padding(.horizontal, 10)
        .frame(minHeight: Trace.Height.badge)
        .background(Capsule().fill(Trace.Colors.tint(color)))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(text))
    }
}

/// A badge that appears (fade + 6 pt rise, 200 ms). The former falling stamp.
struct FallingStamp: View {
    let text: String
    var color: Color = Trace.Colors.benText
    var size: CGFloat = 40
    var dashed = false
    var delay: Double = 0.2
    var sound = true
    @State private var shown = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        StatusBadge(text: text, color: color)
            .offset(y: shown || reduceMotion ? 0 : 6)
            .opacity(shown ? 1 : 0)
            .task {
                try? await Task.sleep(for: .seconds(delay))
                withAnimation(.easeOut(duration: 0.2)) { shown = true }
            }
    }
}

// MARK: - Fields, meters, labels

/// LABEL / VALUE on a card line.
struct FieldRow: View {
    let label: String
    let value: String
    var valueColor: Color = Trace.Colors.text
    var divider = true

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(label).font(Trace.Fonts.caption).foregroundStyle(Trace.Colors.text2)
            Text(value).font(Trace.Fonts.callout).foregroundStyle(valueColor)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 8)
        .overlay(alignment: .bottom) { if divider { Rectangle().fill(Trace.Colors.line).frame(height: 1) } }
        .accessibilityElement(children: .combine)
    }
}

/// Label ........ value on one line (report, forms).
struct LedgerRow: View {
    let label: String
    let value: String
    var valueColor: Color = Trace.Colors.text

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(label).font(Trace.Fonts.callout).foregroundStyle(Trace.Colors.text2)
            Spacer(minLength: 12)
            Text(value).font(Trace.Fonts.data).foregroundStyle(valueColor).multilineTextAlignment(.trailing)
        }
        .frame(minHeight: Trace.Height.row)
        .overlay(alignment: .bottom) { Rectangle().fill(Trace.Colors.line).frame(height: 1) }
        .accessibilityElement(children: .combine)
    }
}

/// Difficulty: n filled dots out of 5, then « n/5 ».
struct DifficultyMeter: View {
    let level: Int
    var color: Color = Trace.Colors.benText

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<5, id: \.self) { i in
                Circle()
                    .fill(i < level ? color : Trace.Colors.surface3)
                    .frame(width: 7, height: 7)
            }
            Text(verbatim: "\(level)/5").font(Trace.Fonts.data).foregroundStyle(Trace.Colors.text2).padding(.leading, 4)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(L10n.f("a11y.difficulty", level)))
    }
}

/// A small data label (« P.04 Golf 22:08 »): Plex Mono on `surface2`.
struct EvidenceLabel: View {
    let text: String
    var seed: String = ""

    var body: some View {
        Text(text)
            .font(Trace.Fonts.data)
            .foregroundStyle(Trace.Colors.benText)
            .lineLimit(1)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(RoundedRectangle(cornerRadius: 6).fill(Trace.Colors.surface2))
    }
}

/// The player's own words (notes, marks): Plex Sans in the accent blue. Handwriting is gone in V3.
struct Handwritten: View {
    let text: String
    var color: Color = Trace.Colors.benText
    var size: CGFloat = 22
    var angle: Double = -2

    var body: some View {
        Text(text)
            .font(.custom(Trace.FontName.sans, size: max(14, size * 0.75), relativeTo: .body))
            .foregroundStyle(color)
    }
}

// MARK: - Buttons (ActionButton, §5)

/// The former ink button: the main action (ben).
struct InkButtonStyle: ButtonStyle {
    var height: CGFloat = 56
    var fill: Color = Trace.Colors.ben
    var text: Color = Trace.Colors.onFill

    func makeBody(configuration: Configuration) -> some View {
        CTAButtonStyle(kind: .primary, height: height).makeBody(configuration: configuration)
    }
}

/// The former paper button: a secondary action (surface2), or tertiary (outlined).
struct PaperButtonStyle: ButtonStyle {
    var height: CGFloat = 54
    var outlined = false

    func makeBody(configuration: Configuration) -> some View {
        CTAButtonStyle(kind: outlined ? .tertiary : .outline, height: height).makeBody(configuration: configuration)
    }
}

/// Pressed state of any tappable card: scale 0.98 + slightly darker, 90 ms.
struct PressableStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .brightness(configuration.isPressed ? -0.04 : 0)
            .animation(.easeOut(duration: 0.09), value: configuration.isPressed)
    }
}

// MARK: - Segmented control (NotebookTab, modes)

/// A segmented control (§5 NotebookTab): 40 pt segments in a `surface` track (radius 12), the
/// active one on `surface3` (radius 9) with `text`/600; the background slides from one to the
/// other (250 ms spring). Each segment has a 44 pt target. The former divider tabs.
struct DividerTabs<Value: Hashable>: View {
    let tabs: [(value: Value, label: String)]
    @Binding var selection: Value
    var identifier: String? = nil
    var sheetColor: Color = Trace.Colors.surface
    /// A count shown after each label (Plex Mono 10), by index; nil = none.
    var counts: [Int?] = []
    @Namespace private var slider

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(tabs.enumerated()), id: \.offset) { index, tab in
                let active = tab.value == selection
                Button {
                    withAnimation(Trace.Motion.tab) { selection = tab.value }
                    Haptics.selection()
                } label: {
                    HStack(spacing: 5) {
                        Text(tab.label)
                            .font(active ? .custom(Trace.FontName.sansSemibold, size: 14, relativeTo: .subheadline)
                                         : .custom(Trace.FontName.sans, size: 14, relativeTo: .subheadline))
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                        if index < counts.count, let count = counts[index] {
                            Text(verbatim: "\(count)")
                                .font(.custom(Trace.FontName.monoSemibold, fixedSize: 10))
                                .foregroundStyle(Trace.Colors.text2)
                        }
                    }
                    .foregroundStyle(active ? Trace.Colors.text : Trace.Colors.text2)
                    .frame(maxWidth: .infinity, minHeight: Trace.Height.segment)
                    .background {
                        if active {
                            RoundedRectangle(cornerRadius: Trace.Radius.segment, style: .continuous)
                                .fill(Trace.Colors.surface3)
                                .matchedGeometryEffect(id: "segment", in: slider)
                        }
                    }
                    .frame(minHeight: Trace.Height.hit)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(active ? .isSelected : [])
                .accessibilityIdentifier(identifier.map { "\($0).\(index)" } ?? "")
            }
        }
        .padding(2)
        .background(RoundedRectangle(cornerRadius: Trace.Radius.segmented, style: .continuous).fill(Trace.Colors.surface))
    }
}

// MARK: - Tab bar

enum DeskTab: Hashable { case bureau, archives, investigator }

/// BUREAU · ARCHIVES · ENQUÊTEUR (§4): the BEN's tab bar, outside an investigation only.
struct DeskTabBar: View {
    let selected: DeskTab
    let onSelect: (DeskTab) -> Void

    var body: some View {
        HStack(spacing: 0) {
            item(.bureau, symbol: "square.grid.2x2", title: L10n.t("tab.bureau"), id: "tab.bureau")
            item(.archives, symbol: "archivebox", title: L10n.t("tab.archives"), id: "menu.cases")
            item(.investigator, symbol: "person.crop.circle", title: L10n.t("tab.investigator"), id: "tab.investigator")
        }
        .padding(.top, 8)
        .frame(maxWidth: .infinity)
        .background(Trace.Colors.bg.ignoresSafeArea(edges: .bottom))
        .overlay(alignment: .top) { Rectangle().fill(Trace.Colors.line).frame(height: 1) }
    }

    private func item(_ tab: DeskTab, symbol: String, title: String, id: String) -> some View {
        let on = tab == selected
        return Button { onSelect(tab) } label: {
            VStack(spacing: 4) {
                Image(systemName: on ? symbol + ".fill" : symbol).font(.system(size: 20, weight: on ? .semibold : .regular))
                Text(title).font(Trace.Fonts.uiSmall)
            }
            .foregroundStyle(on ? Trace.Colors.benText : Trace.Colors.text2)
            .frame(maxWidth: .infinity, minHeight: 49)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(on ? .isSelected : [])
        .accessibilityIdentifier(id)
    }
}

// MARK: - Empty states (§6-13)

/// An empty state: a title, one line of help (the former handwritten tip).
struct EmptyPage: View {
    let title: String
    let tip: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(Trace.Fonts.headline).foregroundStyle(Trace.Colors.text)
            Text(tip).font(Trace.Fonts.callout).foregroundStyle(Trace.Colors.text2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 24)
        .accessibilityElement(children: .combine)
    }
}

extension Trace {
    enum Spacing {
        static let xs: CGFloat = 4
        static let s: CGFloat = 8
        static let m: CGFloat = 12
        static let l: CGFloat = 16
        static let xl: CGFloat = 20
        static let xxl: CGFloat = 24
        static let sheet: CGFloat = 20
        static let edge: CGFloat = 10
    }
}

/// The game's name (logo: docs/brand/). Not translated.
enum Brand {
    static let name = "CONCLUDE"
    static let tagline = "ENQUÊTES"
    static let full = "CONCLUDE : ENQUÊTES"
}

/// "001" style case number.
func dossierNumber(_ n: Int) -> String { n < 10 ? "00\(n)" : n < 100 ? "0\(n)" : "\(n)" }
/// The number shown on a file: ALIBI checks are numbered from 101 in the data (one namespace for
/// saves and assets), « ALIBI #001 » on screen.
func shownNumber(_ n: Int) -> String { dossierNumber(n > 200 ? n - 200 : n > 100 ? n - 100 : n) }
/// « DOSSIER #004 » / « ALIBI #001 » / « DOSSIER BEN #001 » (a story case).
func fileLabel(_ n: Int) -> String {
    L10n.f(n > 200 ? "story.caseNumber" : n > 100 ? "alibi.number" : "dossier.number", shownNumber(n))
}
#endif
