#if os(iOS)
import SwiftUI
import UIKit
import CaseEngine

/// CONCLUDE design — handoff V4 « Dossier lisible » (docs/design_v4), on the UX of V3
/// (docs/design_ux_v3). The physical case file is the interface, laid flat and readable: kraft
/// folders, ivory sheets, stapled prints, evidence labels, the seal, red thread and pins, stamps,
/// handwritten notes, on a dark wooden desk. The seized phone alone is a real, light phone (the
/// `Theme` tokens). Rotations stay under 1.5° and only on prints, piece slips and the « pièce
/// versée » slip; reading sheets, buttons and long text are never tilted nor textured.
///
/// The V3 names (`bg`, `surface`, `text`, `ben`…) still exist: they now give the dark wooden desk
/// (text in ivory), so a screen not yet laid out on paper stays readable. New code uses the V4 names
/// (`desk`, `paper`, `ink`, `kraft`, `red`, `pen`…).
enum Trace {
    enum Colors {
        // MARK: V4 tokens (§2)
        /// Screens: the dark wooden desk.
        static let desk = Color(hex: 0x1A140F)
        /// The lamp's pool on the Bureau and the seal (radial, centre → edge).
        static let deskLamp: [Color] = [Color(hex: 0x3A2D20), Color(hex: 0x1A140F), Color(hex: 0x0C0A08)]
        /// The accusation.
        static let deskDeepGradient: [Color] = [Color(hex: 0x2A2119), Color(hex: 0x100D0A), Color(hex: 0x080706)]
        /// Bottom bars outside the phone.
        static let bar = Color(hex: 0x110E0B)
        /// Folders, the investigation rim, the « Verser » label.
        static let kraft = Color(hex: 0xC3AC80)
        /// The red-thread board.
        static let kraftDark = Color(hex: 0x8C7456)
        /// The evidence board.
        static let kraftBoard = Color(hex: 0x3A2F24)
        /// Reading sheets.
        static let paper = Color(hex: 0xECE5D3)
        /// Piece slips, suspect sheets.
        static let paperCard = Color(hex: 0xF4F0E6)
        static let paperCardLight = Color(hex: 0xF8F4EA)
        /// Border of a print.
        static let photoBorder = Color(hex: 0xFBF9F4)
        /// Behind an identity photo, and behind its initials.
        static let photoBg = Color(hex: 0x6F7A86)
        static let portraitInitials = Color(hex: 0xE4E7EA)
        /// Text on paper (13:1).
        static let ink = Color(hex: 0x1C1A17)
        /// Secondary text on paper (≥ 5.5:1).
        static let ink2 = Color(hex: 0x5B5448)
        /// Text on the desk; the main button on the desk.
        static let ivory = Color(hex: 0xEFEBE3)
        static let ivory2 = Color(hex: 0xA9A397)
        static let ivoryMid = Color(hex: 0xC9C3B6)
        /// Thread, pins, stamps, the mission, the accusation, « contre » — on paper…
        static let red = Color(hex: 0xA3261E)
        /// … and on the desk.
        static let redOnDesk = Color(hex: 0xD0493C)
        /// « En faveur ».
        static let green = Color(hex: 0x2E6B4A)
        /// Handwritten notes (the player's, Lacaze's, the thread's words).
        static let pen = Color(hex: 0x2B3A5A)
        /// Staples, neutral pins.
        static let staple = Color(hex: 0x8E8B84)
        /// Inactive Carnet dividers.
        static let tabs: [Color] = [Color(hex: 0xB9B2A1), Color(hex: 0xAFA897), Color(hex: 0xA59E8D), Color(hex: 0x9B9483)]
        /// Inactive folder tab on the Bureau.
        static let tabInactive = Color(hex: 0x3A332B)
        /// Folders of the other cases (stubs at the bottom of the Bureau).
        static let stubGrey = Color(hex: 0x9A9A94)
        static let stubKraft = Color(hex: 0xB8A57E)
        static let stubAlibi = Color(hex: 0xDCDFE2)
        /// Error post-it.
        static let postIt = Color(hex: 0xFBF3C8)
        static let tapeColor = Color(red: 235 / 255, green: 225 / 255, blue: 190 / 255, opacity: 0.8)
        /// Hold-to-confirm track (filled in red).
        static let holdTrack = Color(hex: 0x2A2522)
        /// Ruled page lines, every 28 pt.
        static let ruledLine = Color(red: 52 / 255, green: 66 / 255, blue: 84 / 255, opacity: 0.12)
        /// The seal's clear bag.
        static let sealBag = Color(red: 220 / 255, green: 225 / 255, blue: 230 / 255, opacity: 0.18)

        /// Background of a small semantic label: the colour at 16 %.
        static func tint(_ color: Color) -> Color { color.opacity(0.16) }

        // MARK: V3 names — the dark wooden desk (ivory text), for screens not laid on paper
        static let bg = desk
        static let bgDeep = Color(hex: 0x0C0A08)
        static let surface = Color(hex: 0x241C15)
        static let surface2 = Color(hex: 0x2E251C)
        static let surface3 = kraftBoard
        static let line = Color(hex: 0xEFEBE3, opacity: 0.10)
        static let text = ivory
        static let text2 = ivoryMid
        static let text3 = ivory2
        /// The former blue accent: the red of stamps and thread, with ivory text on it.
        static let ben = red
        static let benPressed = Color(hex: 0x8A1F18)
        /// Links and numbers on the desk.
        static let benText = kraft
        static let critical = redOnDesk
        static let criticalOnDark = redOnDesk
        static let success = green
        static let successText = Color(hex: 0x86C09C)
        static let warning = Color(hex: 0xD9A441)
        static let onFill = ivory

        // MARK: Older names (TRACE v2 / final V3 paper), on the V4 palette
        static let launch = desk
        static let deskLight = Color(hex: 0x2A2119)
        static let graphite = Color(hex: 0x2A2825)
        static let tabBar = bar
        static let paperAged = Color(hex: 0xE3DAC4)
        static let print = photoBorder
        static let notebook = Color(hex: 0xEFE9DA)
        static let noteYellow = postIt
        static let label = Color(hex: 0xF7F3E8)
        static let kraftLight = Color(hex: 0xC9B387)
        static let kraftMid = Color(hex: 0xBEA67B)
        static let kraftSealed = Color(hex: 0x8E7D5C)
        static let kraftInk = Color(hex: 0x2B2519)
        static let kraftLabel = Color(hex: 0x5A4C33)
        static let inkSoft = ink2
        static let inkFaint = Color(hex: 0x8A8174)
        static let bone = ivory
        static let bone2 = ivory2
        static let bone3 = Color(hex: 0x6F6A61)
        static let stamp = red
        static let stampOnDark = redOnDesk
        static let stampDeep = Color(hex: 0x3A1512)
        static let stampText = ivory
        static let metal = staple
        static let tape = tapeColor
        static let ruled = Color(hex: 0x1C1A17, opacity: 0.065)
        static let notebookRule = ruledLine
        static let marginRed = Color(hex: 0xA3261E, opacity: 0.45)
        static let highlight = Color(hex: 0xC8573F, opacity: 0.16)
        static let shadow = Color.black.opacity(0.4)
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
        /// Caveat: ONLY the player's notes, Lacaze's, and the words on the thread — never
        /// information the player needs (§2 « Typographie »).
        static let hand = "Caveat-Medium"
    }

    /// Type roles (§2). IBM Plex Sans for interface and reading, Newsreader for titles, names and
    /// quotes, IBM Plex Mono for numbers, times, the timer and short capital labels, Caveat for
    /// handwritten notes only.
    enum Fonts {
        /// Newsreader 36/500: « Qui est responsable ? ».
        static let display = Font.custom(FontName.serifMedium, size: 36, relativeTo: .largeTitle)
        /// Newsreader 30/600: screen and case titles.
        static let title = Font.custom(FontName.serifSemibold, size: 30, relativeTo: .title)
        /// Plex Sans 17/600: card titles, buttons.
        static let headline = Font.custom(FontName.sansSemibold, size: 17, relativeTo: .headline)
        /// Newsreader 20/600: a suspect's name.
        static let personName = Font.custom(FontName.serifSemibold, size: 20, relativeTo: .title3)
        /// Plex Sans 16: context, mission, reading.
        static let body = Font.custom(FontName.sans, size: 16, relativeTo: .body)
        /// Plex Sans 14: card content.
        static let callout = Font.custom(FontName.sans, size: 14, relativeTo: .callout)
        /// Plex Mono 11/700 caps +10 %: short labels (CONTEXTE, VOTRE MISSION…).
        static let section = Font.custom(FontName.monoBold, size: 11, relativeTo: .caption)
        /// Plex Sans 13: meta.
        static let caption = Font.custom(FontName.sans, size: 13, relativeTo: .footnote)
        /// Plex Mono 13/700: DOSSIER #001, PIÈCE 03.
        static let data = Font.custom(FontName.monoBold, size: 13, relativeTo: .footnote)
        /// Plex Mono 19/600: the timer.
        static let dataLarge = Font.custom(FontName.monoSemibold, size: 19, relativeTo: .title3)
        /// Caveat 20/500: notes.
        static let note = Font.custom(FontName.hand, size: 20, relativeTo: .title3)

        // Older names, mapped on the V4 roles
        static let wordmark = Font.custom(FontName.monoBold, fixedSize: 15)
        static let caseTitle = Font.custom(FontName.serifSemibold, size: 32, relativeTo: .largeTitle)
        static let screenTitle = title
        static let name = personName
        static let nameLarge = Font.custom(FontName.serifSemibold, size: 24, relativeTo: .title2)
        static let prose = body
        static let proseSmall = callout
        static let quote = Font.custom(FontName.serif, size: 19, relativeTo: .body)
        static let quoteLarge = Font.custom(FontName.serif, size: 22, relativeTo: .title3)
        static let fieldLabel = section
        static let fieldValue = Font.custom(FontName.monoSemibold, size: 12, relativeTo: .caption)
        static let fieldValueLarge = Font.custom(FontName.monoSemibold, size: 14, relativeTo: .callout)
        static let pieceNumber = Font.custom(FontName.monoBold, size: 11, relativeTo: .caption2)
        static let pieceTitle = Font.custom(FontName.monoBold, size: 15, relativeTo: .callout)
        static let button = Font.custom(FontName.sansSemibold, size: 16, relativeTo: .body)
        static let mono = Font.custom(FontName.mono, size: 12, relativeTo: .caption)
        static let monoSmall = Font.custom(FontName.mono, size: 11, relativeTo: .caption2)
        static let hand = note
        static let handSmall = Font.custom(FontName.hand, size: 18, relativeTo: .body)
        static let ui = callout
        static let uiSmall = Font.custom(FontName.sansMedium, size: 11, relativeTo: .caption2)
        static let score = Font.custom(FontName.serifSemibold, fixedSize: 40)
        static func stamp(_ size: CGFloat) -> Font { .custom(FontName.monoBold, fixedSize: max(9, size)) }
    }

    /// Shapes (§2 « Formes »).
    enum Radius {
        /// Sheets have square corners.
        static let sheet: CGFloat = 0
        /// Folder bottom corners (0 0 12 12); its tabs 8 8 0 0.
        static let folder: CGFloat = 12
        static let folderTab: CGFloat = 8
        static let button: CGFloat = 9
        /// Cards on the desk (V3 names).
        static let card: CGFloat = 12
        static let largeCard: CGFloat = 12
        static let badge: CGFloat = 13
        static let segmented: CGFloat = 8
        static let segment: CGFloat = 8
        static let node: CGFloat = 2
    }

    /// Heights.
    enum Height {
        static let button: CGFloat = 56
        static let hold: CGFloat = 60
        static let row: CGFloat = 50
        static let segment: CGFloat = 40
        static let folderTab: CGFloat = 40
        static let tabBar: CGFloat = 82
        /// The kraft investigation rim.
        static let investigationBar: CGFloat = 96
        static let badge: CGFloat = 26
        static let evidenceTag: CGFloat = 32
        static let hit: CGFloat = 44
    }

    /// Drop shadows (§2 « Ombres »).
    enum Shadow {
        static let folder = (color: Color.black.opacity(0.6), radius: CGFloat(25), y: CGFloat(26))
        static let slip = (color: Color.black.opacity(0.42), radius: CGFloat(6), y: CGFloat(5))
        static let print = (color: Color.black.opacity(0.25), radius: CGFloat(5), y: CGFloat(4))
        static let modal = (color: Color.black.opacity(0.55), radius: CGFloat(25), y: CGFloat(24))
    }

    enum Motion {
        static let standard = Animation.timingCurve(0.32, 0.72, 0, 1, duration: 0.3)
        static let emphasized = Animation.timingCurve(0.2, 0.8, 0.2, 1, duration: 0.42)
        static let dramatic = Animation.timingCurve(0.65, 0, 0.35, 1, duration: 0.6)
        /// A stamp falling: 180 ms, then a 60 ms settle.
        static let stamp = Animation.easeIn(duration: 0.18)
        static let tab = Animation.spring(response: 0.25, dampingFraction: 0.85)
        static let sheet = Animation.spring(response: 0.26, dampingFraction: 0.86)
        /// The V4 spring « paper »: response 0.42, damping 0.86.
        static let paper = Animation.spring(response: 0.42, dampingFraction: 0.86)
        /// Hold to conclude: 1.6 s (owner's decision).
        static let holdToClose: Double = 1.6
        /// Verification: 1.8 s (owner's decision); typed at 22 ms per character.
        static let verification: Double = 1.8
        static let typewriterCharacter: Double = 0.022
    }

    /// Deterministic small rotation from an id (the same print always lies the same way), at most
    /// ±1.5° (§2). Use the `.tilt(_:)` modifier: it drops the rotation when « Augmenter le contraste »
    /// is on.
    static func tilt(_ seed: String, range: Double = 1.5) -> Double {
        var hash: UInt64 = 1469598103934665603
        for byte in seed.utf8 { hash = (hash ^ UInt64(byte)) &* 1099511628211 }
        return (Double(hash % 1000) / 1000 * 2 - 1) * min(range, 1.5)
    }
}

// MARK: - Materials

extension View {
    /// A sheet of paper: square corners, grain in multiply (none with « Augmenter le contraste »),
    /// the slip shadow. `radius` is ignored (sheets have square corners), kept for callers.
    func paper(_ color: Color = Trace.Colors.paper, radius: CGFloat = 0, lifted: Bool = false) -> some View {
        modifier(PaperSurface(color: color, lifted: lifted))
    }

    /// A card on the dark desk (V3 layouts): flat wood-dark fill, thin ivory rule.
    func benCard(_ color: Color = Trace.Colors.surface, radius: CGFloat = Trace.Radius.card) -> some View {
        background(
            RoundedRectangle(cornerRadius: radius, style: .continuous)
                .fill(color)
                .overlay(RoundedRectangle(cornerRadius: radius, style: .continuous).strokeBorder(Trace.Colors.line, lineWidth: 1))
        )
    }

    /// A kraft folder body: corners 0 0 12 12, fibres in multiply, the folder shadow.
    func kraft(radius: CGFloat = Trace.Radius.folder, color: Color = Trace.Colors.kraft) -> some View {
        modifier(KraftSurface(color: color, radius: radius))
    }

    /// A small deterministic rotation (±1.5° max) — prints, piece slips, the « pièce versée » slip
    /// only; none with « Augmenter le contraste » or reduced motion.
    func tilt(_ seed: String, range: Double = 1.5) -> some View {
        modifier(TiltModifier(degrees: Trace.tilt(seed, range: range)))
    }

    /// A short capital label: Plex Mono 11/700, caps, +10 %.
    func fieldLabel(_ color: Color = Trace.Colors.ink2) -> some View {
        font(Trace.Fonts.section).tracking(1.1).foregroundStyle(color).textCase(.uppercase)
    }

    /// Pressed state of a tappable card: scale 0.98 + slightly darker, 90 ms.
    func pressable() -> some View { buttonStyle(PressableStyle()) }
}

struct PaperSurface: ViewModifier {
    let color: Color
    var lifted = false
    @Environment(\.colorSchemeContrast) private var contrast

    func body(content: Content) -> some View {
        content.background(
            Rectangle()
                .fill(color)
                .overlay { if contrast != .increased { PaperGrain() } }
                .shadow(color: .black.opacity(lifted ? 0.55 : 0.42), radius: lifted ? 25 : 6, y: lifted ? 24 : 5)
        )
    }
}

struct KraftSurface: ViewModifier {
    let color: Color
    let radius: CGFloat
    @Environment(\.colorSchemeContrast) private var contrast

    func body(content: Content) -> some View {
        let shape = UnevenRoundedRectangle(topLeadingRadius: 0, bottomLeadingRadius: radius,
                                           bottomTrailingRadius: radius, topTrailingRadius: 0)
        content.background(
            shape
                .fill(color)
                .overlay { if contrast != .increased { PaperGrain(intensity: 0.04, texture: "tex_kraft_fibers").clipShape(shape) } }
                .shadow(color: Trace.Shadow.folder.color, radius: Trace.Shadow.folder.radius, y: Trace.Shadow.folder.y)
        )
    }
}

struct TiltModifier: ViewModifier {
    let degrees: Double
    @Environment(\.colorSchemeContrast) private var contrast
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content.rotationEffect(.degrees(contrast == .increased ? 0 : degrees))
    }
}

/// Paper grain: the delivered texture (`tex_paper_grain`, or `tex_kraft_fibers` on kraft), tiled in
/// multiply. Purely decorative: hidden from VoiceOver.
struct PaperGrain: View {
    var intensity: Double = 0.06
    var texture = "tex_paper_grain"

    var body: some View {
        Group {
            if let image = ArtLibrary.image(texture) {
                Image(uiImage: image.cgImage.map { UIImage(cgImage: $0, scale: 3, orientation: .up) } ?? image)
                    .resizable(resizingMode: .tile)
                    .blendMode(.multiply)
                    .opacity(texture == "tex_kraft_fibers" ? 0.45 : min(1, intensity * 14))
            } else {
                Color.clear
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

/// The dark wooden desk with the lamp's pool (§2 `deskLamp`).
struct TraceDesk: View {
    var body: some View {
        RadialGradient(colors: Trace.Colors.deskLamp, center: .init(x: 0.5, y: 0.12), startRadius: 0, endRadius: 720)
            .ignoresSafeArea()
            .accessibilityHidden(true)
    }
}

/// A ruled page: lines every 28 pt, an optional red margin rule (the chronology's, at 56 pt).
struct RuledLines: View {
    var spacing: CGFloat = 28
    var color: Color = Trace.Colors.ruledLine
    var margin: CGFloat? = nil

    var body: some View {
        Canvas { context, size in
            var y = spacing
            while y < size.height {
                context.fill(Path(CGRect(x: 0, y: y, width: size.width, height: 1)), with: .color(color))
                y += spacing
            }
            if let margin {
                context.fill(Path(CGRect(x: margin, y: 0, width: 1, height: size.height)), with: .color(Trace.Colors.marginRed))
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

// MARK: - Office objects (§2 « Accessoires »)

/// A staple: 26 × 9 pt, `staple` grey.
struct Staple: View {
    var width: CGFloat = 26
    var body: some View {
        RoundedRectangle(cornerRadius: 1.5)
            .fill(LinearGradient(colors: [Trace.Colors.staple, Trace.Colors.staple.opacity(0.65)], startPoint: .top, endPoint: .bottom))
            .frame(width: width, height: 4)
            .overlay(RoundedRectangle(cornerRadius: 1.5).strokeBorder(Color.black.opacity(0.18), lineWidth: 0.5))
            .shadow(color: .black.opacity(0.3), radius: 1, y: 1)
            .frame(height: 9)
            .accessibilityHidden(true)
    }
}

/// A piece of tape: 44 × 16 pt.
struct Tape: View {
    var width: CGFloat = 44
    var body: some View {
        Rectangle()
            .fill(Trace.Colors.tapeColor)
            .frame(width: width, height: 16)
            .rotationEffect(.degrees(-3))
            .accessibilityHidden(true)
    }
}

/// A pin: 13 pt head (red, or `staple` when neutral) with a highlight.
struct Pin: View {
    var color: Color = Trace.Colors.red
    var size: CGFloat = 13

    var body: some View {
        Circle()
            .fill(RadialGradient(colors: [color.opacity(0.75), color], center: .init(x: 0.35, y: 0.3), startRadius: 0, endRadius: size * 0.6))
            .frame(width: size, height: size)
            .overlay(Circle().fill(Color.white.opacity(0.5)).frame(width: size * 0.25, height: size * 0.25).offset(x: -size * 0.15, y: -size * 0.15))
            .shadow(color: .black.opacity(0.4), radius: 1.5, y: 1.5)
            .accessibilityHidden(true)
    }
}

/// A paperclip (outline).
struct Paperclip: View {
    var body: some View {
        Canvas { context, size in
            var p = Path()
            let w = size.width, h = size.height
            p.move(to: CGPoint(x: w * 0.3, y: h * 0.25))
            p.addLine(to: CGPoint(x: w * 0.3, y: h * 0.8))
            p.addArc(center: CGPoint(x: w * 0.5, y: h * 0.8), radius: w * 0.2, startAngle: .degrees(180), endAngle: .degrees(0), clockwise: true)
            p.addLine(to: CGPoint(x: w * 0.7, y: h * 0.15))
            p.addArc(center: CGPoint(x: w * 0.5, y: h * 0.15), radius: w * 0.2, startAngle: .degrees(0), endAngle: .degrees(180), clockwise: true)
            p.addLine(to: CGPoint(x: w * 0.3, y: h * 0.65))
            context.stroke(p, with: .color(Trace.Colors.staple), style: StrokeStyle(lineWidth: 2, lineCap: .round))
        }
        .frame(width: 16, height: 40)
        .accessibilityHidden(true)
    }
}

/// A print: `photoBorder` edge (`border` pt, three times more at the bottom for a caption), the
/// print shadow; an optional handwritten caption in the bottom margin.
struct PhotoPrint<Content: View>: View {
    var caption: String? = nil
    var border: CGFloat = 5
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            content.clipped()
            if let caption {
                Text(caption).font(Trace.Fonts.handSmall).foregroundStyle(Trace.Colors.pen).lineLimit(1)
            }
        }
        .padding(border)
        .padding(.bottom, caption == nil ? border * 2 : 0)
        .background(Trace.Colors.photoBorder)
        .shadow(color: Trace.Shadow.print.color, radius: Trace.Shadow.print.radius, y: Trace.Shadow.print.y)
    }
}

/// IdPhoto (§3): a print on `photoBg`; the delivered portrait, else the initials in Plex Sans 600.
struct IDPhoto: View {
    let contact: Contact?
    var width: CGFloat = 70
    var height: CGFloat = 84
    var stapled = false
    @Environment(\.caseNumber) private var caseNumber

    var body: some View {
        let image = ArtLibrary.portrait(case: caseNumber, contact: contact)
        PhotoPrint(border: 4) {
            PortraitOrInitials(image: image, initials: Self.initials(of: contact?.name ?? ""), width: width, height: height)
        }
        .overlay(alignment: .top) { if stapled { Staple().offset(y: -4) } }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(contact?.name ?? ""))
    }

    /// « Emma Roussel » → « ER »
    static func initials(of name: String) -> String {
        name.split(separator: " ").prefix(2).compactMap { $0.first.map { String($0).uppercased() } }.joined()
    }
}

// MARK: - Stamps

/// A stamp rendered in code (§2 « Tampons » : VERSÉE, OUVERT…): a red 2 pt frame, Plex Mono 700
/// caps, rotation −8° (none with « Augmenter le contraste »).
struct StampMark: View {
    let text: String
    var color: Color = Trace.Colors.red
    var size: CGFloat = 12
    var dashed = false
    var angle: Double = -8
    var filled = false
    var symbol: String? = nil

    var body: some View {
        Text(text.uppercased())
            .font(Trace.Fonts.stamp(size))
            .tracking(size * 0.12)
            .foregroundStyle(filled ? Trace.Colors.ivory : color)
            .padding(.horizontal, size * 0.55)
            .padding(.vertical, size * 0.28)
            .background(filled ? color : .clear)
            .overlay(RoundedRectangle(cornerRadius: 2)
                .strokeBorder(color, style: StrokeStyle(lineWidth: max(1.5, min(2.5, size * 0.15)), dash: dashed ? [size * 0.4, size * 0.25] : [])))
            .opacity(0.9)
            .modifier(TiltModifier(degrees: angle))
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text(L10n.f("a11y.stamp", text)))
    }
}

/// A small state label (V3 layouts on the desk): symbol + text in a tinted capsule.
struct StatusBadge: View {
    let text: String
    var color: Color = Trace.Colors.kraft
    var symbol: String? = nil

    var body: some View {
        HStack(spacing: 5) {
            if let symbol { Text(verbatim: symbol) }
            Text(text).lineLimit(1).minimumScaleFactor(0.8)
        }
        .font(.custom(Trace.FontName.sansSemibold, size: 12, relativeTo: .caption))
        .foregroundStyle(color)
        .padding(.horizontal, 10)
        .frame(minHeight: Trace.Height.badge)
        .background(Capsule().fill(color.opacity(0.16)))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(text))
    }
}

/// A stamp that falls (§5): scale 1.35 → 1 in 180 ms, then a 60 ms settle; rigid haptic. With
/// reduced motion it just appears.
struct FallingStamp: View {
    let text: String
    var color: Color = Trace.Colors.red
    var size: CGFloat = 40
    var dashed = false
    var delay: Double = 0.2
    var sound = true
    @State private var phase = 0
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    @AppStorage(Preferences.reduceMotionKey) private var appReduceMotion = false
    private var reduceMotion: Bool { systemReduceMotion || appReduceMotion }

    var body: some View {
        StampMark(text: text, color: color, size: size, dashed: dashed)
            .scaleEffect(reduceMotion ? 1 : (phase == 0 ? 1.35 : phase == 1 ? 0.98 : 1))
            .opacity(phase > 0 ? 1 : 0)
            .task {
                try? await Task.sleep(for: .seconds(delay))
                if reduceMotion {
                    withAnimation(.easeOut(duration: 0.2)) { phase = 2 }
                } else {
                    withAnimation(Trace.Motion.stamp) { phase = 1 }
                    try? await Task.sleep(for: .milliseconds(180))
                    withAnimation(.easeOut(duration: 0.06)) { phase = 2 }
                }
                if sound { AudioDirector.shared.play(.stamp, volume: 0.9) }
                Haptics.rigid()
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

/// A small paper label glued on a piece (« P.04 Golf 22:08 »): Plex Mono on `label` paper, ink,
/// a slight tilt.
struct EvidenceLabel: View {
    let text: String
    var seed: String = ""

    var body: some View {
        Text(text)
            .font(Trace.Fonts.pieceNumber)
            .foregroundStyle(Trace.Colors.ink)
            .lineLimit(1)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(Trace.Colors.label)
            .shadow(color: .black.opacity(0.2), radius: 1.5, y: 1)
            .tilt(seed.isEmpty ? text : seed)
    }
}

/// A handwritten note (Caveat, `pen` blue) — only the player's notes, Lacaze's and the thread's
/// words, never information the player needs; its words are also in the VoiceOver label.
struct Handwritten: View {
    let text: String
    var color: Color = Trace.Colors.pen
    var size: CGFloat = 20
    var angle: Double = 0

    var body: some View {
        Text(text)
            .font(.custom(Trace.FontName.hand, size: size, relativeTo: .title3))
            .foregroundStyle(color)
            .modifier(TiltModifier(degrees: max(-1.5, min(1.5, angle))))
            .accessibilityLabel(Text(text))
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
        .background(Trace.Colors.bar.ignoresSafeArea(edges: .bottom))
        .overlay(alignment: .top) { Rectangle().fill(Trace.Colors.line).frame(height: 1) }
    }

    private func item(_ tab: DeskTab, symbol: String, title: String, id: String) -> some View {
        let on = tab == selected
        return Button { onSelect(tab) } label: {
            VStack(spacing: 4) {
                Image(systemName: on ? symbol + ".fill" : symbol).font(.system(size: 20, weight: on ? .semibold : .regular))
                Text(title).font(Trace.Fonts.uiSmall)
            }
            .foregroundStyle(on ? Trace.Colors.ivory : Trace.Colors.ivory2)
            .frame(maxWidth: .infinity, minHeight: 49)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(on ? .isSelected : [])
        .accessibilityIdentifier(id)
    }
}

// MARK: - Empty states (§6-13)

/// An empty state (V4 §4): the V3 text, written in Caveat (`pen`) on a ruled page, centred — or,
/// on the desk (`onPaper: false`), ivory title and a Caveat line in kraft.
struct EmptyPage: View {
    let title: String
    let tip: String
    var onPaper = false

    var body: some View {
        VStack(spacing: 6) {
            Text(title)
                .font(.custom(Trace.FontName.hand, size: 22, relativeTo: .title3))
                .foregroundStyle(onPaper ? Trace.Colors.pen : Trace.Colors.ivory)
            Text(tip)
                .font(.custom(Trace.FontName.hand, size: 19, relativeTo: .body))
                .foregroundStyle(onPaper ? Trace.Colors.pen.opacity(0.85) : Trace.Colors.kraft)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
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
