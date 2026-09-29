#if os(iOS)
import SwiftUI

// Tokens of the story mode, re-skinned with the UX V3 tokens (docs/design_ux_v3 §0: the story
// screens keep their flows and take the BEN's palette and type). The 3D stage keeps its own
// render colours (sceneVoid, renderTop/Mid) and the dialogue text stays light on the scene.

extension Trace {
    enum Story {
        static let alibiPaper = Trace.Colors.surface
        static let alibiInk = Trace.Colors.text
        static let alibiInkSecondary = Trace.Colors.text2
        static let folder = Trace.Colors.surface
        static let folderLight = Trace.Colors.surface2
        static let ink = Trace.Colors.text
        static let inkSecondary = Trace.Colors.text2
        static let sceneVoid = Color(hex: 0x0A0B0D)
        static let scrim = Color(hex: 0x07090C)
        static let renderTop = Color(hex: 0x2A313B)
        static let renderMid = Color(hex: 0x12151A)
        /// Dialogue text on the scene, the player's own lines, the journal sheet, the settings rows.
        static let dialogue = Trace.Colors.text
        static let playerLine = Trace.Colors.text2
        static let journal = Trace.Colors.surface
        static let settingsRow = Trace.Colors.surface
        static let hud = Color(hex: 0x07090C, opacity: 0.6)
        static let hotspotLabel = Color(hex: 0x07090C, opacity: 0.75)
        static let selection = Trace.Colors.surface3
        static let greyStamp = Trace.Colors.text3
        static let kraftInk = Trace.Colors.text

        // One flat background for every mode (V3: no lamp, no gradient).
        static let deskInvestigations: [Color] = [Trace.Colors.bg, Trace.Colors.bg, Trace.Colors.bg]
        static let deskAlibi: [Color] = [Trace.Colors.bg, Trace.Colors.bg, Trace.Colors.bg]
        static let deskStory: [Color] = [Trace.Colors.bg, Trace.Colors.bg, Trace.Colors.bg]
        static let deskMain: [Color] = [Trace.Colors.bg, Trace.Colors.bg, Trace.Colors.bg]
    }

    // Type (V3 §3 roles).
    enum StoryFonts {
        static let h1 = Font.custom(FontName.serifMedium, size: 31, relativeTo: .largeTitle)
        static let h1Hero = Font.custom(FontName.serifMedium, size: 34, relativeTo: .largeTitle)
        static let h2 = Font.custom(FontName.serifMedium, size: 26, relativeTo: .title)
        static let h3 = Font.custom(FontName.sansSemibold, size: 18, relativeTo: .title3)
        static let label = Font.custom(FontName.sansSemibold, size: 12, relativeTo: .caption)
        static let body = Font.custom(FontName.sans, size: 16, relativeTo: .body)
        static let uiBody = Font.custom(FontName.sans, size: 15, relativeTo: .body)
        static let caption = Font.custom(FontName.sans, size: 13, relativeTo: .footnote)
        static let technical = Font.custom(FontName.monoMedium, size: 12, relativeTo: .caption)
        static let dialogue = Font.custom(FontName.serif, size: 22, relativeTo: .title2)
        static let dialogueQuestion = Font.custom(FontName.serif, size: 19, relativeTo: .title3)
        static let dialogueName = Font.custom(FontName.sansSemibold, size: 13, relativeTo: .footnote)
        static let dialogueRole = Font.custom(FontName.sans, size: 12, relativeTo: .caption)
        static let choice = Font.custom(FontName.sans, size: 16, relativeTo: .body)
        static let choiceSilent = Font.custom(FontName.serifItalic, size: 16, relativeTo: .body)
        static let choicePrefix = Font.custom(FontName.monoSemibold, size: 12, relativeTo: .caption)
        static let note = Font.custom(FontName.sans, size: 16, relativeTo: .body)
        static let button = Font.custom(FontName.sansSemibold, size: 17, relativeTo: .body)
        static let number = Font.custom(FontName.monoMedium, size: 24, relativeTo: .title)
        static let next = Font.custom(FontName.sans, size: 14, relativeTo: .callout)
        static let stamp = Font.custom(FontName.sansSemibold, size: 12, relativeTo: .caption)
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
        (colors.first ?? Trace.Colors.bg).ignoresSafeArea().accessibilityHidden(true)
    }
}

/// A section label: Plex Sans 12/600 caps +8 % (V3 §3 « section »).
struct StoryLabel: View {
    let text: String
    var color: Color = Trace.Colors.text2

    var body: some View {
        Text(text.uppercased())
            .font(Trace.StoryFonts.label)
            .tracking(1)
            .foregroundStyle(color)
    }
}

/// A folder state: a StatusBadge (V3: no rotated stamp).
struct StateStamp: View {
    let text: String
    var color: Color = Trace.Colors.benText

    var body: some View {
        StatusBadge(text: text, color: color)
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
        // As many 26 pt boxes per row as the sheet allows (at most 10).
        let columns = [GridItem(.adaptive(minimum: 26, maximum: 26), spacing: 8)]
        LazyVGrid(columns: columns, alignment: .leading, spacing: 8) {
            ForEach(0..<total, id: \.self) { i in
                ZStack {
                    RoundedRectangle(cornerRadius: 6).fill(i < done ? Trace.Colors.tint(Trace.Colors.success) : Trace.Colors.surface2)
                    if i < done {
                        Text(verbatim: "✓").font(.custom(Trace.FontName.sansSemibold, fixedSize: 14)).foregroundStyle(Trace.Colors.successText)
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
                .background(RoundedRectangle(cornerRadius: Trace.Radius.card).fill(Trace.Story.settingsRow))
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

    private var fill: Color { destructive ? Trace.Colors.critical : Trace.Colors.ben }

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: Trace.Radius.button, style: .continuous)
        ZStack(alignment: .leading) {
            shape.fill(Trace.Colors.surface2)
            GeometryReader { geo in
                shape.fill(fill).frame(width: geo.size.width * progress)
            }
            Text(title)
                .font(Trace.StoryFonts.button)
                .foregroundStyle(Trace.Colors.text)
                .frame(maxWidth: .infinity)
        }
        .frame(height: Trace.Height.hold)
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
    var color: Color = Trace.Colors.benText
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 3) {
                Image(systemName: "chevron.left").font(.system(size: 17, weight: .semibold))
                if let label { Text(label).font(Trace.Fonts.link) }
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
