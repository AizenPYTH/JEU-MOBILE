#if os(iOS)
import SwiftUI
import CaseEngine

/// CONCLUDE design (« TRACE » v2 handoff) — « dossier d'enquête ». Paper outside, glass inside: everything that belongs to
/// the investigator (folders, files, exhibits, notebook, hints, forms, report) is paper on a dark
/// desk; the seized phone alone stays a modern glass OS (the `Theme` tokens).
/// Tokens follow design_handoff_trace/README.md §3.
enum Trace {
    enum Colors {
        // Desk
        static let desk = Color(hex: 0x121110)
        static let deskLight = Color(hex: 0x1F1D1A)
        static let graphite = Color(hex: 0x2A2825)
        static let tabBar = Color(hex: 0x0E0D0C)
        // Paper
        static let paper = Color(hex: 0xECE5D3)
        static let paperAged = Color(hex: 0xE3DAC4)
        static let print = Color(hex: 0xF4F0E6)
        static let notebook = Color(hex: 0xEFE9DA)
        static let noteYellow = Color(hex: 0xFBF3C8)
        static let label = Color(hex: 0xF7F3E8)
        // Kraft
        static let kraft = Color(hex: 0xC3AC80)
        static let kraftDark = Color(hex: 0xB8A077)
        static let kraftLight = Color(hex: 0xC9B387)
        static let kraftMid = Color(hex: 0xBEA67B)
        static let kraftSealed = Color(hex: 0x8E7D5C)
        static let kraftInk = Color(hex: 0x2B2519)
        static let kraftLabel = Color(hex: 0x5A4C33)
        // Ink
        static let ink = Color(hex: 0x1C1A17)
        static let inkSoft = Color(hex: 0x5B5448)
        static let inkFaint = Color(hex: 0x8A8174)
        // Text on the desk
        static let bone = Color(hex: 0xEFEBE3)
        static let bone2 = Color(hex: 0xA9A397)
        static let bone3 = Color(hex: 0x6F6A61)
        // Stamps and pens
        static let stamp = Color(hex: 0xA3261E)
        static let stampOnDark = Color(hex: 0xD0493C)
        static let stampDeep = Color(hex: 0x3A1512)
        static let stampText = Color(hex: 0xF2E9E4)
        static let pen = Color(hex: 0x2E3A57)
        static let metal = Color(hex: 0x9A978F)
        static let tape = Color(hex: 0xE2D6B4, opacity: 0.8)
        static let ruled = Color(hex: 0x1C1A17, opacity: 0.065)
        static let notebookRule = Color(hex: 0x3C5078, opacity: 0.13)
        static let marginRed = Color(hex: 0xA3261E, opacity: 0.45)
        static let highlight = Color(hex: 0xC8573F, opacity: 0.16)
        static let shadow = Color(hex: 0x000000, opacity: 0.4)
        // Loading screen bar (sampled from loading_main: the bar drawn in the artwork)
        static let loadingTrack = Color(hex: 0x060606)
        static let loadingRim = Color(hex: 0x7A7470, opacity: 0.85)
        static let loadingRedDeep = Color(hex: 0x6A0000)
        static let loadingRed = Color(hex: 0xA80A08)
        static let loadingRedHot = Color(hex: 0xE0181C)
    }

    enum FontName {
        static let serif = "Newsreader-Regular"
        static let serifMedium = "Newsreader-Medium"
        static let serifSemibold = "Newsreader-SemiBold"
        static let serifItalic = "Newsreader-Italic"
        static let mono = "IBMPlexMono-Regular"
        static let monoMedium = "IBMPlexMono-Medium"
        static let monoSemibold = "IBMPlexMono-SemiBold"
        static let monoBold = "IBMPlexMono-Bold"
        static let hand = "Caveat-Medium"
    }

    enum Fonts {
        static let wordmark = Font.custom(FontName.monoBold, fixedSize: 22)
        static let caseTitle = Font.custom(FontName.serifSemibold, size: 32, relativeTo: .largeTitle)
        static let screenTitle = Font.custom(FontName.serifMedium, size: 34, relativeTo: .largeTitle)
        static let name = Font.custom(FontName.serifSemibold, size: 20, relativeTo: .title3)
        static let nameLarge = Font.custom(FontName.serifSemibold, size: 24, relativeTo: .title2)
        static let prose = Font.custom(FontName.serif, size: 16, relativeTo: .body)
        static let proseSmall = Font.custom(FontName.serif, size: 14, relativeTo: .callout)
        static let quote = Font.custom(FontName.serifItalic, size: 18, relativeTo: .body)
        static let quoteLarge = Font.custom(FontName.serifItalic, size: 22, relativeTo: .title3)
        static let fieldLabel = Font.custom(FontName.monoMedium, size: 9.5, relativeTo: .caption2)
        static let fieldValue = Font.custom(FontName.monoSemibold, size: 12, relativeTo: .caption)
        static let fieldValueLarge = Font.custom(FontName.monoSemibold, size: 14, relativeTo: .callout)
        static let pieceNumber = Font.custom(FontName.monoBold, size: 10, relativeTo: .caption2)
        static let pieceTitle = Font.custom(FontName.monoBold, size: 20, relativeTo: .title3)
        static let button = Font.custom(FontName.monoSemibold, size: 12.5, relativeTo: .callout)
        static let mono = Font.custom(FontName.mono, size: 12, relativeTo: .caption)
        static let monoSmall = Font.custom(FontName.mono, size: 10.5, relativeTo: .caption2)
        static let hand = Font.custom(FontName.hand, size: 22, relativeTo: .title3)
        static let handSmall = Font.custom(FontName.hand, size: 18, relativeTo: .body)
        static let ui = Font.custom(Theme.FontName.regular, size: 14, relativeTo: .callout)
        static let uiSmall = Font.custom(Theme.FontName.medium, size: 11, relativeTo: .caption2)
        static let score = Font.custom(FontName.monoBold, fixedSize: 72)
        static func stamp(_ size: CGFloat) -> Font { .custom(FontName.monoBold, fixedSize: size) }
    }

    enum Motion {
        static let standard = Animation.timingCurve(0.32, 0.72, 0, 1, duration: 0.3)
        static let emphasized = Animation.timingCurve(0.2, 0.8, 0.2, 1, duration: 0.42)
        static let dramatic = Animation.timingCurve(0.65, 0, 0.35, 1, duration: 0.6)
        static let stamp = Animation.timingCurve(0.5, 0, 0.75, 0, duration: 0.14)
        static let tab = Animation.spring(response: 0.3, dampingFraction: 0.82)
        static let sheet = Animation.spring(response: 0.26, dampingFraction: 0.86)
        /// Hold to close a case (ms in the handoff: 1 200).
        static let holdToClose: Double = 1.2
        /// Verification typewriter: 2.4 s in total.
        static let verification: Double = 2.4
    }

    /// Deterministic small rotation from an id: the same piece always lies the same way.
    static func tilt(_ seed: String, range: Double = 2) -> Double {
        var hash: UInt64 = 1469598103934665603
        for byte in seed.utf8 { hash = (hash ^ UInt64(byte)) &* 1099511628211 }
        return (Double(hash % 1000) / 1000 * 2 - 1) * range
    }
}

// MARK: - Materials

extension View {
    /// A sheet of paper lying on the desk: colour, subtle grain, drop shadow.
    func paper(_ color: Color = Trace.Colors.paper, radius: CGFloat = 2, lifted: Bool = false) -> some View {
        background(
            RoundedRectangle(cornerRadius: radius, style: .continuous)
                .fill(color)
                .overlay(PaperGrain().clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous)))
                .shadow(color: .black.opacity(lifted ? 0.45 : 0.4), radius: lifted ? 20 : 10, y: lifted ? 18 : 8)
        )
    }

    /// Kraft folder body.
    func kraft(radius: CGFloat = 10, color: Color = Trace.Colors.kraft) -> some View {
        background(
            UnevenRoundedRectangle(topLeadingRadius: 0, bottomLeadingRadius: radius, bottomTrailingRadius: radius, topTrailingRadius: radius)
                .fill(color)
                .overlay(PaperGrain(intensity: 0.05).clipShape(RoundedRectangle(cornerRadius: radius)))
                .shadow(color: .black.opacity(0.55), radius: 22, y: 22)
        )
    }

    /// Deterministic rotation of a paper item (−range…range degrees).
    func tilt(_ seed: String, range: Double = 2) -> some View {
        rotationEffect(.degrees(Trace.tilt(seed, range: range)))
    }

    /// Ink text for field labels: mono caps with tracking.
    func fieldLabel(_ color: Color = Trace.Colors.inkSoft) -> some View {
        font(Trace.Fonts.fieldLabel).tracking(1.5).foregroundStyle(color).textCase(.uppercase)
    }

    /// A small press effect for paper buttons.
    func pressable() -> some View { buttonStyle(PressableStyle()) }
}

/// Paper grain: very light monochrome noise (3 %), drawn once per size.
struct PaperGrain: View {
    var intensity: Double = 0.035

    var body: some View {
        Canvas(rendersAsynchronously: true) { context, size in
            var rng = SeededRandom(seed: "grain")
            let count = Int(size.width * size.height / 38)
            for _ in 0..<min(count, 9000) {
                let x = rng.next() * size.width, y = rng.next() * size.height
                context.fill(Path(CGRect(x: x, y: y, width: 1, height: 1)),
                             with: .color(Trace.Colors.ink.opacity(intensity * Double(0.5 + rng.next()))))
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

/// The desk: dark charcoal with the pool of an office lamp at the top.
struct TraceDesk: View {
    var body: some View {
        ZStack {
            Trace.Colors.desk
            RadialGradient(colors: [Trace.Colors.deskLight, Trace.Colors.desk], center: .top, startRadius: 0, endRadius: 520)
                .scaleEffect(x: 1.3, y: 1, anchor: .top)
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }
}

/// Horizontal ruled lines (fiches, suspect files) — or a spiral notebook's blue lines with its red margin.
struct RuledLines: View {
    var spacing: CGFloat = 28
    var color: Color = Trace.Colors.ruled
    var margin: CGFloat? = nil

    var body: some View {
        Canvas { context, size in
            var y = spacing
            while y < size.height {
                context.fill(Path(CGRect(x: 0, y: y, width: size.width, height: 1)), with: .color(color))
                y += spacing
            }
            if let margin {
                context.fill(Path(CGRect(x: margin, y: 0, width: 1.2, height: size.height)), with: .color(Trace.Colors.marginRed))
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

// MARK: - Office objects

/// A staple across the top edge of a sheet.
struct Staple: View {
    var body: some View {
        Capsule()
            .fill(LinearGradient(colors: [Trace.Colors.metal, Trace.Colors.metal.opacity(0.6)], startPoint: .top, endPoint: .bottom))
            .frame(width: 26, height: 4)
            .shadow(color: .black.opacity(0.35), radius: 1, y: 1)
            .accessibilityHidden(true)
    }
}

/// A piece of tape holding a print.
struct Tape: View {
    var width: CGFloat = 54
    var body: some View {
        Rectangle()
            .fill(Trace.Colors.tape)
            .frame(width: width, height: 16)
            .rotationEffect(.degrees(-4))
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
            context.stroke(p, with: .color(Trace.Colors.metal), style: StrokeStyle(lineWidth: 2, lineCap: .round))
        }
        .frame(width: 16, height: 40)
        .shadow(color: .black.opacity(0.3), radius: 1, y: 1)
        .accessibilityHidden(true)
    }
}

/// A photo print: white border, the picture, optional caption in the bottom margin.
struct PhotoPrint<Content: View>: View {
    var caption: String? = nil
    var border: CGFloat = 5
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            content.clipped()
            if let caption {
                Text(caption).font(Trace.Fonts.monoSmall).foregroundStyle(Trace.Colors.inkSoft).lineLimit(1)
            }
        }
        .padding(border)
        .padding(.bottom, caption == nil ? border : 0)
        .background(Trace.Colors.print)
        .shadow(color: .black.opacity(0.45), radius: 9, y: 8)
    }
}

/// An identity photo printed for the file: white 3 pt border. The delivered photo is desaturated by
/// 15 % (handoff « Portraits » §1.1); without one, initials on tinted stripes, desaturated further.
struct IDPhoto: View {
    let contact: Contact?
    var width: CGFloat = 70
    var height: CGFloat = 84
    @Environment(\.caseNumber) private var caseNumber

    var body: some View {
        let real = ArtLibrary.portrait(case: caseNumber, contact: contact) != nil
        PhotoPrint(border: 3) {
            Portrait(contact: contact, width: width, height: height)
                .clipShape(Rectangle())
                .saturation(real ? 0.85 : 0.35)
        }
    }
}

// MARK: - Stamps

/// An administrative stamp: framed caps, tilted, slightly irregular ink. `dashed` = not classified.
struct StampMark: View {
    let text: String
    var color: Color = Trace.Colors.stamp
    var size: CGFloat = 12
    var dashed = false
    var angle: Double = -6
    var filled = false

    var body: some View {
        Text(text.uppercased())
            .font(Trace.Fonts.stamp(size))
            .tracking(size * 0.16)
            .foregroundStyle(filled ? Trace.Colors.stampText : color)
            .padding(.horizontal, size * 0.55)
            .padding(.vertical, size * 0.25)
            .background(filled ? color : .clear)
            .overlay(
                RoundedRectangle(cornerRadius: 2)
                    .strokeBorder(color, style: StrokeStyle(lineWidth: max(1.2, size * 0.13), dash: dashed ? [size * 0.4, size * 0.25] : []))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 1)
                    .strokeBorder(color.opacity(dashed || filled ? 0 : 0.6), lineWidth: 0.8)
                    .padding(size * 0.14)
            )
            .opacity(0.86)
            .rotationEffect(.degrees(angle))
            .accessibilityLabel(Text(L10n.f("a11y.stamp", text)))
    }
}

/// A stamp that falls on the paper (scale 1.6 → 1, fade in, heavy haptic, dull thud).
struct FallingStamp: View {
    let text: String
    var color: Color = Trace.Colors.stamp
    var size: CGFloat = 40
    var dashed = false
    var delay: Double = 0.2
    var sound = true
    @State private var down = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        StampMark(text: text, color: color, size: size, dashed: dashed, angle: -8)
            .scaleEffect(down || reduceMotion ? 1 : 1.6)
            .opacity(down || reduceMotion ? 1 : 0)
            .task {
                try? await Task.sleep(for: .seconds(delay))
                withAnimation(Trace.Motion.stamp) { down = true }
                if sound { AudioDirector.shared.play(.stamp, volume: 0.9) }
                Haptics.stamp(heavy: !dashed)
            }
    }
}

// MARK: - Fields, meters, labels

/// LABEL / VALUE on a form line.
struct FieldRow: View {
    let label: String
    let value: String
    var valueColor: Color = Trace.Colors.ink
    var divider = true

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label).fieldLabel()
            Text(value).font(Trace.Fonts.fieldValue).foregroundStyle(valueColor).textCase(.uppercase)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 6)
        .overlay(alignment: .bottom) { if divider { Rectangle().fill(Trace.Colors.ruled.opacity(2)).frame(height: 1) } }
        .accessibilityElement(children: .combine)
    }
}

/// LABEL ........ VALUE on one line (report, closure form).
struct LedgerRow: View {
    let label: String
    let value: String
    var valueColor: Color = Trace.Colors.ink

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(label).font(Trace.Fonts.mono).tracking(0.8).foregroundStyle(Trace.Colors.inkSoft).textCase(.uppercase)
            Spacer(minLength: 12)
            Text(value).font(Trace.Fonts.fieldValue).foregroundStyle(valueColor).multilineTextAlignment(.trailing)
        }
        .padding(.vertical, 10)
        .overlay(alignment: .bottom) { Rectangle().fill(Trace.Colors.ruled.opacity(2)).frame(height: 1) }
        .accessibilityElement(children: .combine)
    }
}

/// Difficulty: n filled squares out of 5.
struct DifficultyMeter: View {
    let level: Int
    var color: Color = Trace.Colors.ink

    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<5, id: \.self) { i in
                Rectangle()
                    .fill(i < level ? color : .clear)
                    .overlay(Rectangle().strokeBorder(color, lineWidth: 1))
                    .frame(width: 9, height: 9)
            }
            Text("\(level)/5").font(Trace.Fonts.monoSmall).foregroundStyle(color).padding(.leading, 4)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(L10n.f("a11y.difficulty", level)))
    }
}

/// A small paper label glued on a page ("P.04 Golf 22:08").
struct EvidenceLabel: View {
    let text: String
    var seed: String = ""

    var body: some View {
        Text(text)
            .font(Trace.Fonts.monoSmall.weight(.semibold))
            .foregroundStyle(Trace.Colors.ink)
            .lineLimit(1)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(Trace.Colors.label)
            .shadow(color: .black.opacity(0.2), radius: 1.5, y: 1)
            .tilt(seed.isEmpty ? text : seed, range: 2)
    }
}

/// Handwriting (Caveat, or Newsreader italic if the player asked for legible handwriting).
struct Handwritten: View {
    let text: String
    var color: Color = Trace.Colors.pen
    var size: CGFloat = 22
    var angle: Double = -2
    @AppStorage(Preferences.legibleHandwritingKey) private var legible = false

    var body: some View {
        Text(text)
            .font(legible ? .custom(Trace.FontName.serifItalic, size: size * 0.8) : .custom(Trace.FontName.hand, size: size))
            .foregroundStyle(color)
            .rotationEffect(.degrees(angle))
    }
}

// MARK: - Buttons

/// Ink button on paper or desk: dark block, bone mono caps.
struct InkButtonStyle: ButtonStyle {
    var height: CGFloat = 56
    var fill: Color = Trace.Colors.ink
    var text: Color = Trace.Colors.bone
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Trace.Fonts.button)
            .tracking(1.6)
            .textCase(.uppercase)
            .foregroundStyle(text)
            .frame(maxWidth: .infinity, minHeight: height)
            .background(RoundedRectangle(cornerRadius: 6).fill(fill))
            .opacity(isEnabled ? 1 : 0.45)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .shadow(color: .black.opacity(configuration.isPressed ? 0.15 : 0.35), radius: configuration.isPressed ? 2 : 8, y: configuration.isPressed ? 1 : 5)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

/// Paper button: ivory card with ink mono caps (on the desk), or an outlined one (on paper).
struct PaperButtonStyle: ButtonStyle {
    var height: CGFloat = 54
    var outlined = false
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Trace.Fonts.button)
            .tracking(1.6)
            .textCase(.uppercase)
            .foregroundStyle(Trace.Colors.ink)
            .frame(maxWidth: .infinity, minHeight: height)
            .background(RoundedRectangle(cornerRadius: 6).fill(outlined ? .clear : Trace.Colors.paper))
            .overlay(RoundedRectangle(cornerRadius: 6).strokeBorder(Trace.Colors.ink, lineWidth: outlined ? 1.5 : 0))
            .opacity(isEnabled ? 1 : 0.45)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

/// A light press on any paper element.
struct PressableStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
            .brightness(configuration.isPressed ? -0.03 : 0)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

// MARK: - Divider tabs (intercalaires)

/// The divider tabs of an open folder: the active one takes the colour of the sheet.
struct DividerTabs<Value: Hashable>: View {
    let tabs: [(value: Value, label: String)]
    @Binding var selection: Value
    var identifier: String? = nil
    var sheetColor: Color = Trace.Colors.paper

    private let shades: [Color] = [Trace.Colors.kraftLight, Trace.Colors.kraftMid, Trace.Colors.kraftDark, Trace.Colors.kraft]

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .bottom, spacing: 3) {
                    ForEach(Array(tabs.enumerated()), id: \.offset) { index, tab in
                        let active = tab.value == selection
                        Button {
                            withAnimation(Trace.Motion.tab) { selection = tab.value }
                            AudioDirector.shared.play(.paper, volume: 0.35)
                            Haptics.selection()
                        } label: {
                            Text(tab.label)
                                .font(Trace.Fonts.pieceNumber)
                                .tracking(1.2)
                                .textCase(.uppercase)
                                .foregroundStyle(active ? Trace.Colors.ink : Trace.Colors.kraftInk.opacity(0.75))
                                .padding(.horizontal, 12)
                                .frame(height: active ? 30 : 26)
                                .background(UnevenRoundedRectangle(topLeadingRadius: 7, topTrailingRadius: 7)
                                    .fill(active ? sheetColor : shades[index % shades.count]))
                                .shadow(color: .black.opacity(active ? 0 : 0.15), radius: 2, y: -1)
                        }
                        .buttonStyle(.plain)
                        .id(index)
                        .accessibilityAddTraits(active ? .isSelected : [])
                        .accessibilityIdentifier(identifier.map { "\($0).\(index)" } ?? "")
                    }
                }
                .padding(.horizontal, 12)
            }
            .onChange(of: selection) { _, value in
                if let i = tabs.firstIndex(where: { $0.value == value }) { withAnimation { proxy.scrollTo(i, anchor: .center) } }
            }
        }
    }
}

// MARK: - Desk tab bar

enum DeskTab: Hashable { case bureau, archives, investigator }

/// Bureau · Archives · Enquêteur — Geist, the navigation stays modern.
struct DeskTabBar: View {
    let selected: DeskTab
    let onSelect: (DeskTab) -> Void

    var body: some View {
        HStack(spacing: 0) {
            item(.bureau, symbol: "rectangle.fill", title: L10n.t("tab.bureau"), id: "tab.bureau")
            item(.archives, symbol: "archivebox", title: L10n.t("tab.archives"), id: "menu.cases")
            item(.investigator, symbol: "person.text.rectangle", title: L10n.t("tab.investigator"), id: "tab.investigator")
        }
        .padding(.top, 10)
        .frame(maxWidth: .infinity)
        .background(Trace.Colors.tabBar.ignoresSafeArea(edges: .bottom))
        .overlay(alignment: .top) { Rectangle().fill(Trace.Colors.graphite).frame(height: 1) }
    }

    private func item(_ tab: DeskTab, symbol: String, title: String, id: String) -> some View {
        let on = tab == selected
        return Button { onSelect(tab) } label: {
            VStack(spacing: 4) {
                Image(systemName: symbol).font(.system(size: 18, weight: on ? .semibold : .regular))
                Text(title).font(Trace.Fonts.uiSmall)
            }
            .foregroundStyle(on ? Trace.Colors.bone : Trace.Colors.bone3)
            .frame(maxWidth: .infinity, minHeight: 48)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(on ? .isSelected : [])
        .accessibilityIdentifier(id)
    }
}

// MARK: - Pages

/// Empty page: the support's own paper, one line, a handwritten tip.
struct EmptyPage: View {
    let title: String
    let tip: String

    var body: some View {
        VStack(alignment: .leading, spacing: Trace.Spacing.m) {
            Text(title).font(Trace.Fonts.prose).foregroundStyle(Trace.Colors.inkSoft)
            Handwritten(text: tip, color: Trace.Colors.stamp, size: 20)
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
#endif
