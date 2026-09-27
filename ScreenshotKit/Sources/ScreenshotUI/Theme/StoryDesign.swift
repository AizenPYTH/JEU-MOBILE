#if os(iOS)
import SwiftUI

// Tokens of the story mode and of the three-mode Bureau (docs/design_story/DESIGN_SYSTEM_STORY.md).
// Everything else (paper, ink, stamps, buttons) is the final design's: Trace.* and ConcludeKit.

extension Trace {
    enum Story {
        // §2 Colours.
        static let alibiPaper = Color(hex: 0xDCDFE2)
        static let alibiInk = Color(hex: 0x1F2530)
        static let alibiInkSecondary = Color(hex: 0x4A5260)
        static let folder = Color(hex: 0x2A3240)
        static let folderLight = Color(hex: 0x333D4C)
        static let ink = Color(hex: 0xE4E7EA)
        static let inkSecondary = Color(hex: 0x9AA3AE)
        static let sceneVoid = Color(hex: 0x0A0B0D)
        static let scrim = Color(hex: 0x0A0908)
        static let renderTop = Color(hex: 0x2A313B)
        static let renderMid = Color(hex: 0x12151A)
        /// Dialogue text, the player's own lines, the journal sheet, the settings rows.
        static let dialogue = Color(hex: 0xEFEBE3)
        static let playerLine = Color(hex: 0xC9C3B6)
        static let journal = Color(hex: 0x141311)
        static let settingsRow = Color(hex: 0x1A1816)
        static let hud = Color(hex: 0x0A0908, opacity: 0.55)
        static let hotspotLabel = Color(hex: 0x0A0908, opacity: 0.7)
        static let selection = Color(hex: 0xECE5D3)
        static let greyStamp = Color(hex: 0x5B5448)
        /// ENQUÊTES folder (kraft) ink.
        static let kraftInk = Color(hex: 0x2B2519)

        // Backdrops per mode (radial 90 % × 45 %).
        static let deskInvestigations: [Color] = [Color(hex: 0x3A2D20), Color(hex: 0x15110D), Color(hex: 0x0B0A09)]
        static let deskAlibi: [Color] = [Color(hex: 0x1D2229), Color(hex: 0x101215), Color(hex: 0x0A0A0B)]
        static let deskStory: [Color] = [Color(hex: 0x20252D), Color(hex: 0x101215), Color(hex: 0x0A0A0B)]
        static let deskMain: [Color] = [Color(hex: 0x2E261D), Color(hex: 0x12100E), Color(hex: 0x0A0908)]
    }

    // §3 Typography.
    enum StoryFonts {
        static let h1 = Font.custom(FontName.serifMedium, size: 30, relativeTo: .largeTitle)
        static let h1Hero = Font.custom(FontName.serifMedium, size: 34, relativeTo: .largeTitle)
        static let h2 = Font.custom(FontName.serifSemibold, size: 26, relativeTo: .title)
        static let h3 = Font.custom(FontName.serifMedium, size: 20.5, relativeTo: .title3)
        static let label = Font.custom(FontName.monoBold, fixedSize: 10)
        static let body = Font.custom(FontName.serif, size: 15.5, relativeTo: .body)
        static let uiBody = Font.custom(Theme.FontName.regular, size: 15, relativeTo: .body)
        static let caption = Font.custom(Theme.FontName.regular, size: 13, relativeTo: .footnote)
        static let technical = Font.custom(FontName.monoMedium, fixedSize: 11)
        static let dialogue = Font.custom(FontName.serif, size: 22, relativeTo: .title2)
        static let dialogueQuestion = Font.custom(FontName.serif, size: 19, relativeTo: .title3)
        static let dialogueName = Font.custom(FontName.monoBold, fixedSize: 11)
        static let dialogueRole = Font.custom(FontName.mono, fixedSize: 10)
        static let choice = Font.custom(FontName.serif, size: 16, relativeTo: .body)
        static let choiceSilent = Font.custom(FontName.serifItalic, size: 16, relativeTo: .body)
        static let choicePrefix = Font.custom(FontName.monoBold, fixedSize: 11)
        static let note = Font.custom(FontName.hand, size: 21, relativeTo: .title3)
        static let button = Font.custom(FontName.monoBold, fixedSize: 13)
        static let number = Font.custom(FontName.serif, size: 28, relativeTo: .title)
        static let next = Font.custom(FontName.mono, fixedSize: 12)
        static let stamp = Font.custom(FontName.monoBold, fixedSize: 9)
    }

    enum StoryMotion {
        /// Spring « paper »: response 0.42, damping 0.86.
        static let paper = Animation.spring(response: 0.42, dampingFraction: 0.86)
        static let typeSpeedNormal = 0.028
        static let typeSpeedSlow = 0.045
        /// Auto-advance: 1.2 s + 45 ms per character.
        static func autoDelay(_ text: String) -> Double { 1.2 + 0.045 * Double(text.count) }
    }
}

/// The radial backdrop of a Bureau (90 % × 45 %), per mode.
struct ModeBackdrop: View {
    let colors: [Color]

    var body: some View {
        GeometryReader { geo in
            EllipticalGradient(colors: colors, center: .init(x: 0.5, y: 0.08),
                               startRadiusFraction: 0, endRadiusFraction: 0.9)
                .frame(width: geo.size.width, height: geo.size.height)
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }
}

/// LABEL: Plex Mono 10/700, +16 %, caps.
struct StoryLabel: View {
    let text: String
    var color: Color = Trace.Colors.bone2

    var body: some View {
        Text(text.uppercased())
            .font(Trace.StoryFonts.label)
            .tracking(1.6)
            .foregroundStyle(color)
    }
}

/// A folder-state stamp (§6): rotation −7°, 2 pt border, Plex Mono 9/700.
struct StateStamp: View {
    let text: String
    var color: Color = Trace.Colors.stamp

    var body: some View {
        Text(text.uppercased())
            .font(Trace.StoryFonts.stamp)
            .tracking(1.4)
            .foregroundStyle(color)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .overlay(RoundedRectangle(cornerRadius: 2).strokeBorder(color, lineWidth: 2))
            .rotationEffect(.degrees(-7))
            .accessibilityLabel(Text(L10n.f("a11y.stamp", text)))
    }
}

/// StepBar: 4 segments of 2 pt, 6 pt apart.
struct StepBar: View {
    let count: Int
    let done: Int

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<count, id: \.self) { i in
                Capsule().fill(Trace.Story.dialogue.opacity(i < done ? 1 : 0.18)).frame(height: 2)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(L10n.f("story.a11y.step", done, count)))
    }
}

/// ProgressBoxes (h17): one box per case the next rank needs, crossed in red when solved.
struct ProgressBoxes: View {
    let total: Int
    let done: Int

    var body: some View {
        let columns = Array(repeating: GridItem(.fixed(26), spacing: 8), count: min(10, max(1, total)))
        LazyVGrid(columns: columns, alignment: .leading, spacing: 8) {
            ForEach(0..<total, id: \.self) { i in
                ZStack {
                    Rectangle().strokeBorder(Trace.Colors.ink, lineWidth: 1.5)
                    if i < done {
                        Text("×").font(.custom(Trace.FontName.monoBold, fixedSize: 18)).foregroundStyle(Trace.Colors.stamp)
                    }
                }
                .frame(width: 26, height: 26)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(L10n.f("story.progress.a11y", done, total)))
    }
}

/// A group of settings rows (h19): LABEL header, #1A1816 block, 48 pt rows.
struct SettingsGroup<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            StoryLabel(text: title)
                .padding(.leading, 4)
            VStack(spacing: 0) { content }
                .background(RoundedRectangle(cornerRadius: 10).fill(Trace.Story.settingsRow))
        }
    }
}

/// Hold to confirm (DESIGN_SYSTEM_STORY §7: only « Commencer ma carrière », 1.2 s, and
/// « Réinitialiser l'histoire », 1.6 s — conclusions keep their own control). The fill grows while
/// held; letting go too early empties it. VoiceOver: a double tap confirms.
struct StoryHoldButton: View {
    let title: String
    var seconds: Double = 1.2
    var destructive = false
    var onPaper = false
    let action: () -> Void
    @State private var progress: CGFloat = 0

    private var fill: Color { destructive ? Trace.Colors.stampOnDark : (onPaper ? Trace.Colors.ink : Trace.Story.dialogue) }
    private var text: Color { destructive ? Trace.Colors.criticalText : (onPaper ? Trace.Colors.bone : Trace.Colors.ink) }

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: 6, style: .continuous)
        ZStack(alignment: .leading) {
            shape.strokeBorder(fill, lineWidth: 1.5)
            GeometryReader { geo in
                shape.fill(fill).frame(width: geo.size.width * progress)
            }
            Text(title.uppercased())
                .font(Trace.StoryFonts.button)
                .tracking(2)
                .foregroundStyle(progress > 0.5 ? text : fill)
                .frame(maxWidth: .infinity)
        }
        .frame(height: 56)
        .clipShape(shape)
        .contentShape(shape)
        .onLongPressGesture(minimumDuration: seconds, maximumDistance: 40) {
            Haptics.rigid()
            action()
        } onPressingChanged: { pressing in
            if pressing {
                withAnimation(.linear(duration: seconds)) { progress = 1 }
            } else {
                withAnimation(.linear(duration: 0.2)) { progress = 0 }
            }
        }
        .accessibilityElement()
        .accessibilityLabel(Text(title))
        .accessibilityHint(Text(L10n.t("story.a11y.hold")))
        .accessibilityAddTraits(.isButton)
        .accessibilityAction { action() }
    }
}

/// A 44 pt back chevron « ‹ » with an optional label.
struct BackChevron: View {
    var label: String? = nil
    var color: Color = Trace.Colors.bone
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: "chevron.left").font(.system(size: 17, weight: .semibold))
                if let label { Text(label).font(Trace.StoryFonts.uiBody) }
            }
            .foregroundStyle(color)
            .frame(minWidth: 44, minHeight: 44, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(label ?? L10n.t("common.back")))
    }
}
#endif
