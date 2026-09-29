#if os(iOS)
import SwiftUI

// Tokens of the story mode on the V4 « Dossier lisible » palette (docs/design_v4): the story is
// played on the dark wooden desk (lamp), its screens are kraft folders and ivory sheets written in
// ink, short capital labels in Plex Mono, titles in Newsreader. No 3D (owner's decision): a scene
// is an interview report laid on the desk (StoryScenePlayer).

extension Trace {
    enum Story {
        // Paper and ink (every sheet of the story).
        static let paper = Trace.Colors.paper
        static let card = Trace.Colors.paperCard
        static let ink = Trace.Colors.ink
        static let inkSecondary = Trace.Colors.ink2
        static let rule = Trace.Colors.ink.opacity(0.14)
        static let folder = Trace.Colors.kraft
        static let folderLight = Trace.Colors.kraftLight
        // Older names, kept for callers: now paper and ink.
        static let alibiPaper = Trace.Colors.paperCard
        static let alibiInk = Trace.Colors.ink
        static let alibiInkSecondary = Trace.Colors.ink2
        static let kraftInk = Trace.Colors.ink
        static let greyStamp = Trace.Colors.ink2
        static let selection = Trace.Colors.paperSelected
        /// The dialogue on its sheet; the player's own lines in ink2 (italic).
        static let dialogue = Trace.Colors.ink
        static let playerLine = Trace.Colors.ink2
        /// The journal and the settings: paper.
        static let journal = Trace.Colors.paper
        static let settingsRow = Trace.Colors.paper
        /// Behind everything: the desk; the fades go to its darkest wood.
        static let desk = Trace.Colors.desk
        static let sceneVoid = Trace.Colors.bgDeep
        /// A hairline on the desk.
        static let deskRule = Trace.Colors.ivory.opacity(0.28)

        // The lamp's pool for every mode (V4 `deskLamp`).
        static let deskInvestigations: [Color] = Trace.Colors.deskLamp
        static let deskAlibi: [Color] = Trace.Colors.deskLamp
        static let deskStory: [Color] = Trace.Colors.deskLamp
        static let deskMain: [Color] = Trace.Colors.deskLamp
    }

    // Type (V4 §2 « Typographie »).
    enum StoryFonts {
        static let h1 = Font.custom(FontName.serifSemibold, size: 30, relativeTo: .largeTitle)
        static let h1Hero = Font.custom(FontName.serifSemibold, size: 32, relativeTo: .largeTitle)
        static let h2 = Font.custom(FontName.serifSemibold, size: 24, relativeTo: .title)
        static let h3 = Font.custom(FontName.serifSemibold, size: 20, relativeTo: .title3)
        /// Short capital labels: Plex Mono 11/700 (use with tracking and caps: `StoryLabel`).
        static let label = Font.custom(FontName.monoBold, size: 11, relativeTo: .caption)
        static let body = Font.custom(FontName.sans, size: 16, relativeTo: .body)
        static let uiBody = Font.custom(FontName.sans, size: 15, relativeTo: .body)
        static let caption = Font.custom(FontName.sans, size: 13, relativeTo: .footnote)
        static let technical = Font.custom(FontName.monoSemibold, size: 12, relativeTo: .caption)
        /// A line of the interview report: Newsreader 20 (19–22 with the subtitle size).
        static let dialogue = Font.custom(FontName.serif, size: 20, relativeTo: .title3)
        static let dialogueQuestion = Font.custom(FontName.serif, size: 19, relativeTo: .title3)
        static let dialogueName = Font.custom(FontName.monoBold, size: 12, relativeTo: .caption)
        static let dialogueRole = Font.custom(FontName.sans, size: 12, relativeTo: .caption)
        static let choice = Font.custom(FontName.sans, size: 16, relativeTo: .body)
        static let choiceSilent = Font.custom(FontName.serifItalic, size: 16, relativeTo: .body)
        static let choicePrefix = Font.custom(FontName.monoBold, size: 12, relativeTo: .caption)
        static let note = Font.custom(FontName.sans, size: 16, relativeTo: .body)
        static let button = Trace.Fonts.cta
        static let number = Font.custom(FontName.monoSemibold, size: 24, relativeTo: .title)
        static let next = Font.custom(FontName.monoBold, size: 13, relativeTo: .callout)
        static let stamp = Font.custom(FontName.monoBold, size: 12, relativeTo: .caption)

        /// The dialogue at the chosen subtitle size (small 19, medium 20, large 22).
        static func dialogueFont(size: CGFloat, italic: Bool = false) -> Font {
            .custom(italic ? FontName.serifItalic : FontName.serif, size: size, relativeTo: .title3)
        }
    }

    enum StoryMotion {
        /// Spring « paper »: response 0.42, damping 0.86.
        static let paper = Trace.Motion.paper
        static let typeSpeedNormal = 0.028
        static let typeSpeedSlow = 0.045
        /// Auto-advance: 1.2 s + 45 ms per character.
        static func autoDelay(_ text: String) -> Double { 1.2 + 0.045 * Double(text.count) }
    }
}

/// The desk under the lamp (V4 `deskLamp`), whatever the mode.
struct ModeBackdrop: View {
    var colors: [Color] = Trace.Colors.deskLamp

    var body: some View {
        RadialGradient(colors: colors.count >= 2 ? colors : Trace.Colors.deskLamp,
                       center: .init(x: 0.5, y: 0.12), startRadius: 0, endRadius: 720)
            .ignoresSafeArea()
            .accessibilityHidden(true)
    }
}

/// A short capital label: Plex Mono 11/700 caps +10 % (V4). ink2 on paper by default; pass
/// `ivory2` on the desk.
struct StoryLabel: View {
    let text: String
    var color: Color = Trace.Colors.ink2

    var body: some View {
        Text(text)
            .fieldLabel(color)
    }
}

/// A state stamped on a sheet (NOUVEAU, CLASSÉ…): the code stamp (red 2 pt frame, Plex Mono,
/// −8°), in `color`.
struct StateStamp: View {
    let text: String
    var color: Color = Trace.Colors.red
    var size: CGFloat = 12

    var body: some View {
        StampMark(text: text, color: color, size: size)
    }
}

/// StepBar: n segments of 2 pt, 6 pt apart — ink on paper, ivory on the desk.
struct StepBar: View {
    let count: Int
    let done: Int
    var color: Color = Trace.Colors.ivory

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<count, id: \.self) { i in
                Capsule().fill(color.opacity(i < done ? 1 : 0.22)).frame(height: 2)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(L10n.f("story.a11y.step", done, count)))
    }
}

/// ProgressBoxes (h17): one box per case the next rank needs, drawn in ink on the sheet; a solved
/// one is crossed in red.
struct ProgressBoxes: View {
    let total: Int
    let done: Int

    var body: some View {
        // As many 26 pt boxes per row as the sheet allows.
        let columns = [GridItem(.adaptive(minimum: 26, maximum: 26), spacing: 8)]
        LazyVGrid(columns: columns, alignment: .leading, spacing: 8) {
            ForEach(0..<total, id: \.self) { i in
                ZStack {
                    Rectangle().strokeBorder(Trace.Colors.ink2, lineWidth: 1.2)
                    if i < done {
                        BoxCross()
                            .stroke(Trace.Colors.red, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                            .padding(5)
                    }
                }
                .frame(width: 26, height: 26)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(L10n.f("story.progress.a11y", done, total)))
    }
}

/// The two strokes of a box ticked by hand.
private struct BoxCross: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.minX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        p.move(to: CGPoint(x: rect.maxX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        return p
    }
}

/// A group of settings (h19): a Plex Mono label on the desk, then a paper sheet of 48 pt rows in ink.
struct SettingsGroup<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            StoryLabel(text: title, color: Trace.Colors.ivory2)
                .padding(.leading, 2)
                .accessibilityAddTraits(.isHeader)
            VStack(spacing: 0) { content }
                .paper(Trace.Colors.paper)
        }
    }
}

/// Hold to confirm (« Commencer ma carrière », 1.2 s; « Réinitialiser l'histoire », 1.6 s): the V4
/// hold — track #2A2522 filled in red while held; letting go too early empties it. VoiceOver: a
/// double tap confirms.
struct StoryHoldButton: View {
    let title: String
    var seconds: Double = 1.2
    var destructive = false
    var onPaper = false
    var identifier = "hold.confirm"
    let action: () -> Void

    var body: some View {
        BenHoldButton(title: title, seconds: seconds, identifier: identifier, action: action)
    }
}

/// « ‹ Histoire »: the previous screen's name, 44 pt, top left — ivory on the desk (default), ink
/// on paper.
struct BackChevron: View {
    var label: String? = nil
    var color: Color = Trace.Colors.ivoryMid
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

/// The bottom of a story screen (V4 `bar`): the one main button, and its link, 16 pt from the edges.
struct StoryFooter<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        VStack(spacing: 2) { content }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 10)
            .frame(maxWidth: .infinity)
            .background(Trace.Colors.bar.ignoresSafeArea(edges: .bottom))
            .overlay(alignment: .top) { Rectangle().fill(Trace.Colors.line).frame(height: 1).accessibilityHidden(true) }
    }
}

/// A rank stamp: the delivered PNG (`stamp_<rank>_rouge`) when its printed word is exactly the
/// title shown (« Enquêteur », « Inspecteur »), else the code stamp with the agreed title
/// (« Enquêtrice », « Inspecteur senior »).
struct StoryRankStamp: View {
    let rank: String
    let title: String
    var width: CGFloat = 150
    var angle: Double = -8

    /// The words printed on the PNG stamps.
    private static let printed: [String: String] = [
        "enqueteur": "ENQUÊTEUR", "inspecteur": "INSPECTEUR", "senior": "SENIOR", "experimente": "EXPÉRIMENTÉ",
    ]

    var body: some View {
        let upper = title.uppercased()
        if let word = Self.printed[rank], upper == word {
            StampImage(asset: "stamp_\(rank)_rouge", label: title, width: width, angle: angle)
        } else {
            StampMark(text: title, size: max(11, width / 9), angle: angle)
        }
    }
}

/// A small kraft folder tab (8 8 0 0) with a Plex Mono label in ink, laid on top of a `.kraft()`
/// body.
struct StoryFolderTab: View {
    let text: String

    var body: some View {
        Text(text)
            .fieldLabel(Trace.Colors.ink)
            .lineLimit(1)
            .minimumScaleFactor(0.8)
            .padding(.horizontal, 14)
            .frame(height: 30)
            .background(
                UnevenRoundedRectangle(topLeadingRadius: Trace.Radius.folderTab, bottomLeadingRadius: 0,
                                       bottomTrailingRadius: 0, topTrailingRadius: Trace.Radius.folderTab)
                    .fill(Trace.Colors.kraft)
            )
    }
}

/// The player's print: initials on `photoBg` (no portrait: the story has no 3D and no generated
/// face), white border, an optional staple.
struct StoryPlayerPrint: View {
    let initials: String
    var width: CGFloat = 78
    var height: CGFloat = 98
    var stapled = true
    var label: String = ""

    var body: some View {
        PhotoPrint(border: 4) {
            PortraitOrInitials(image: nil, initials: initials, width: width, height: height)
        }
        .overlay(alignment: .top) { if stapled { Staple().offset(y: -4) } }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(label))
        .accessibilityAddTraits(.isImage)
    }
}
#endif
