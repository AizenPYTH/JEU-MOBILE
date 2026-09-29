#if os(iOS)
import SwiftUI
import UIKit
import StoryEngine

// The entry screens of the three modes and of the story (docs/design_story/STORY_UX_FLOW.md):
// h01 the three-mode Bureau, h04 the story's hub, h05/h05b/h06 the character creator, and the
// read-only « Voir en 3D » studio. No story rule here: the coordinator and the engine decide.
// Re-skinned with the UX V3 tokens (docs/design_ux_v3 §0): flat surfaces, Plex Sans, no paper,
// grain, rotation or shadow. The 3D renders (StoryStageView, CharacterPreview) are unchanged.
// ModeDeskView (h01) is no longer routed to (the Bureau has a segmented control): kept compiling.

// MARK: - Shared metrics and helpers

private enum DeskMetrics {
    /// ModeFolder (DESIGN_SYSTEM_STORY §5): 358 pt wide, 118–156 pt tall, 26 pt apart (tabs included).
    static let folderWidth: CGFloat = 358
    static let folderMinHeight: CGFloat = 118
    static let folderGap: CGFloat = 26
    static let pill: CGFloat = 44
    /// StoryHeroRender: 470 pt, the bottom 200 pt veiled to scene.void.
    static let heroHeight: CGFloat = 470
    static let heroVeil: CGFloat = 200
    /// Creator: render 350 pt on top, paper sheet 340 pt at the bottom.
    static let renderHeight: CGFloat = 350
    static let sheetHeight: CGFloat = 340
    /// Margins (§4): 28 pt for text laid on a render, 24 pt for buttons, 16 pt for sheets.
    static let textOnRender: CGFloat = 28
    static let buttonMargin: CGFloat = 24
    static let sheetMargin: CGFloat = 16
}

private extension Trace.StoryFonts {
    /// The creator's name fields: Plex Sans 17.
    static let input = Font.custom(Trace.FontName.sans, size: 17, relativeTo: .body)
}

/// Variant names come from the data (French `label`, English `labelEn`).
private enum CreatorText {
    static var french: Bool { Locale.current.language.languageCode?.identifier == "fr" }

    static func label(_ variant: CharacterVariant) -> String {
        french ? variant.label : (variant.labelEn ?? variant.label)
    }

    /// « Parka sombre, chemise · Marine » → « Parka sombre, chemise ».
    static func outfitName(_ variant: CharacterVariant) -> String { split(label(variant)).name }

    /// « Parka sombre, chemise · Marine » → « Marine ».
    static func outfitColour(_ variant: CharacterVariant) -> String { split(label(variant)).colour }

    /// At most two annotations: the outer layer, then what is worn under it.
    static func annotations(_ variant: CharacterVariant?) -> [String] {
        guard let variant else { return [] }
        return Array(outfitName(variant).components(separatedBy: ", ").prefix(2))
    }

    private static func split(_ text: String) -> (name: String, colour: String) {
        guard let r = text.range(of: " · ") else { return (text, text) }
        return (String(text[..<r.lowerBound]), String(text[r.upperBound...]))
    }
}

/// A 2 pt progress rule (chapters): never a percentage, never a gauge label.
private struct ChapterBar: View {
    let progress: Double
    let track: Color
    let fill: Color

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Rectangle().fill(track)
                Rectangle().fill(fill).frame(width: geo.size.width * CGFloat(min(1, max(0, progress))))
            }
        }
        .frame(height: 2)
        .accessibilityHidden(true)
    }
}

// MARK: - h01 · Bureau principal (three modes)

struct ModeDeskData {
    enum Mode: Hashable { case investigations, alibi, story }
    /// « É. MOREL · ENQUÊTRICE · BEN » (already formatted by the caller).
    var investigatorLine: String
    var portrait: UIImage?
    var initials: String
    /// ENQUÊTES: meta « #004 EN COURS · 2 NOUVEAUX » (formatted by the caller) and the current/next case for the stapled print.
    var investigationsMeta: String
    var currentCaseTitle: String?
    var currentCaseNumber: String?
    /// ALIBI: nil when no check ships; meta « 3 MIN · 3 ALIBIS »; the next check's claim (person, statement) and its window « 21:00–23:00 ».
    var alibiMeta: String?
    var alibiPerson: String?
    var alibiStatement: String?
    var alibiWindow: String?
    var alibiLocked: Bool
    /// HISTOIRE: no investigator yet → « Créer votre enquêteur » / « NOUVEAU MODE ».
    var storyHasInvestigator: Bool
    var storyChapterLine: String?   // « Chapitre 1 · Première affectation »
    var storyProgress: Double       // 0…1 of the chapter (draw a 2 pt bar, no percentage text)
    var storyPortrait: UIImage?
    var storyLocked: Bool
    /// The mode in progress goes first; default order ENQUÊTES, ALIBI, HISTOIRE.
    var first: Mode
}

/// h01: the text mention of the game and the portrait pill, « Bureau » and the investigator's line,
/// then three folders of the same shape — kraft (ENQUÊTES), grey paper (ALIBI), BEN card
/// (HISTOIRE) — that differ only by their material and their visual hint. A tap anywhere on a
/// folder opens its mode (T-UI-1: the folder lifts to 1.02, the others fade).
struct ModeDeskView: View {
    let data: ModeDeskData
    let onMode: (ModeDeskData.Mode) -> Void
    let onProfile: () -> Void
    let onTab: (DeskTab) -> Void

    @State private var appeared = false
    @State private var opening: ModeDeskData.Mode?
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    @AppStorage(Preferences.reduceMotionKey) private var appReduceMotion = false

    private var still: Bool { systemReduceMotion || appReduceMotion }

    /// The mode in progress first; ALIBI only when a check ships.
    private var order: [ModeDeskData.Mode] {
        var modes: [ModeDeskData.Mode] = [.investigations, .alibi, .story]
        if data.alibiMeta == nil { modes.removeAll { $0 == .alibi } }
        if let i = modes.firstIndex(of: data.first), i > 0 {
            let mode = modes.remove(at: i)
            modes.insert(mode, at: 0)
        }
        return modes
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    header
                    VStack(spacing: DeskMetrics.folderGap) {
                        ForEach(Array(order.enumerated()), id: \.element) { index, mode in
                            folder(mode)
                                .scaleEffect(opening == mode ? 1.02 : 1)
                                .opacity(opening == nil || opening == mode ? 1 : 0)
                                .opacity(appeared ? 1 : 0)
                                .offset(y: appeared || still ? 0 : 24)
                                .animation(still ? .easeOut(duration: 0.2) : Trace.StoryMotion.paper.delay(0.07 * Double(index)),
                                           value: appeared)
                        }
                    }
                    .padding(.top, 26)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            }
            .scrollBounceBehavior(.basedOnSize)
            DeskTabBar(selected: .bureau, onSelect: onTab)
        }
        .background(ModeBackdrop(colors: Trace.Story.deskMain))
        .onAppear {
            opening = nil
            appeared = true
        }
    }

    // MARK: Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .center, spacing: 12) {
                // The brand's text mention (logo rule §H: no logo image on the Bureau).
                LogoText()
                Spacer(minLength: 8)
                Button(action: onProfile) {
                    PortraitOrInitials(image: data.portrait, initials: data.initials,
                                       width: DeskMetrics.pill, height: DeskMetrics.pill)
                        .clipShape(Circle())
                        .overlay(Circle().strokeBorder(Trace.Colors.text.opacity(0.35), lineWidth: 1))
                        .contentShape(Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text(verbatim: "\(L10n.t("tab.investigator")), \(data.investigatorLine)"))
                .accessibilityIdentifier("mode.profile")
            }
            VStack(alignment: .leading, spacing: 6) {
                Text(L10n.t("tab.bureau"))
                    .font(Trace.StoryFonts.h1)
                    .tracking(-0.3)
                    .foregroundStyle(Trace.Story.dialogue)
                    .accessibilityAddTraits(.isHeader)
                Text(data.investigatorLine)
                    .font(Trace.StoryFonts.technical)
                    .tracking(0.8)
                    .foregroundStyle(Trace.Colors.text2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.top, 8)
    }

    // MARK: Folders

    @ViewBuilder
    private func folder(_ mode: ModeDeskData.Mode) -> some View {
        switch mode {
        case .investigations:
            ModeFolder(material: .kraft,
                       tab: L10n.t("mode.investigations.tab"),
                       title: L10n.t("mode.investigations.promise"),
                       verbs: L10n.t("mode.investigations.verbs"),
                       detail: data.currentCaseTitle?.capitalizedFirst,
                       meta: data.investigationsMeta,
                       identifier: "mode.investigations",
                       action: { openMode(.investigations) }) {
                if data.currentCaseNumber != nil || data.currentCaseTitle != nil {
                    StapledPrint(number: data.currentCaseNumber, seed: data.currentCaseTitle ?? "")
                }
            }
        case .alibi:
            ModeFolder(material: .alibi,
                       tab: L10n.t("mode.alibi.tab"),
                       title: L10n.t("mode.alibi.promise"),
                       verbs: L10n.t("mode.alibi.verbs"),
                       detail: alibiDetail,
                       meta: data.alibiMeta,
                       lockedLine: data.alibiLocked ? L10n.t("mode.locked") : nil,
                       identifier: "mode.alibi",
                       action: { openMode(.alibi) }) {
                AlibiColumns(window: data.alibiWindow)
            }
        case .story:
            ModeFolder(material: .story,
                       tab: L10n.t("mode.story.tab"),
                       title: data.storyHasInvestigator ? (data.storyChapterLine ?? L10n.t("mode.story.promise")) : L10n.t("mode.story.create"),
                       verbs: L10n.t("mode.story.verbs"),
                       meta: data.storyHasInvestigator ? nil : L10n.t("mode.story.new"),
                       progress: data.storyHasInvestigator ? data.storyProgress : nil,
                       lockedLine: data.storyLocked ? L10n.t("mode.locked") : nil,
                       identifier: "mode.story",
                       action: { openMode(.story) }) {
                StoryPortraitPrint(image: data.storyPortrait, initials: data.initials, empty: !data.storyHasInvestigator)
            }
        }
    }

    /// « Mathis : « Je n'ai pas quitté la table. » »
    private var alibiDetail: String? {
        guard let statement = data.alibiStatement, !statement.isEmpty else { return nil }
        guard let person = data.alibiPerson, !person.isEmpty else { return statement }
        return L10n.f("mode.alibi.claim", person, statement)
    }

    /// T-UI-1: the touched folder lifts (1.02), the others fade out, then the mode opens.
    private func openMode(_ mode: ModeDeskData.Mode) {
        guard opening == nil else { return }
        AudioDirector.shared.play(.folder, volume: 0.4)
        Haptics.light()
        if still {
            onMode(mode)
            return
        }
        withAnimation(.easeOut(duration: 0.3)) { opening = mode }
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(220))
            onMode(mode)
            // Still on screen (nothing was pushed): the folders come back.
            try? await Task.sleep(for: .milliseconds(700))
            opening = nil
        }
    }
}

/// A folder with a tab: the same shape for the three modes (tab radius 0 10 10 10, same shadow),
/// only the material and the accessory change. Locked: 50 %, the condition in place of the meta.
private struct ModeFolder<Accessory: View>: View {
    enum Material { case kraft, alibi, story }

    let material: Material
    let tab: String
    let title: String
    let verbs: String
    var detail: String? = nil
    var meta: String? = nil
    /// HISTOIRE: the chapter's progress (a 2 pt bar).
    var progress: Double? = nil
    /// « Disponible après le dossier #001 » when locked.
    var lockedLine: String? = nil
    let identifier: String
    let action: () -> Void
    @ViewBuilder let accessory: Accessory

    private var ink: Color {
        switch material {
        case .kraft: Trace.Story.kraftInk
        case .alibi: Trace.Story.alibiInk
        case .story: Trace.Story.ink
        }
    }

    private var secondary: Color {
        switch material {
        case .kraft: Trace.Colors.text2
        case .alibi: Trace.Story.alibiInkSecondary
        case .story: Trace.Story.inkSecondary
        }
    }

    private var tabColor: Color {
        switch material {
        case .kraft: Trace.Colors.surface
        case .alibi: Trace.Story.alibiPaper
        case .story: Trace.Story.folderLight
        }
    }

    var body: some View {
        let locked = lockedLine != nil
        Button(action: action) {
            VStack(alignment: .leading, spacing: 0) {
                Text(tab.uppercased())
                    .font(Trace.StoryFonts.label)
                    .tracking(1.6)
                    .foregroundStyle(ink)
                    .padding(.horizontal, 14)
                    .frame(minWidth: 96, minHeight: 26)
                    .background(UnevenRoundedRectangle(topLeadingRadius: 8, topTrailingRadius: 8, style: .continuous).fill(tabColor))
                VStack(alignment: .leading, spacing: 8) {
                    Text(title)
                        .font(Trace.StoryFonts.h3)
                        .foregroundStyle(ink)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                    HStack(alignment: .bottom, spacing: 14) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(verbs.uppercased())
                                .font(Trace.StoryFonts.label)
                                .tracking(1.6)
                                .foregroundStyle(secondary)
                                .fixedSize(horizontal: false, vertical: true)
                            if let detail {
                                Text(detail)
                                    .font(Trace.Fonts.proseSmall)
                                    .foregroundStyle(ink.opacity(0.85))
                                    .lineLimit(2)
                                    .multilineTextAlignment(.leading)
                            }
                            if let progress, !locked {
                                ChapterBar(progress: progress, track: secondary.opacity(0.35), fill: ink)
                                    .padding(.top, 4)
                            }
                            if let line = lockedLine ?? meta, !line.isEmpty {
                                Text(line)
                                    .font(Trace.StoryFonts.technical)
                                    .tracking(0.3)
                                    .foregroundStyle(secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        accessory
                    }
                }
                .padding(16)
                .frame(maxWidth: .infinity, minHeight: DeskMetrics.folderMinHeight, alignment: .topLeading)
                .background(folderBody)
            }
            .frame(maxWidth: DeskMetrics.folderWidth)
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(PressableStyle())
        .disabled(locked)
        .opacity(locked ? 0.5 : 1)
        .accessibilityLabel(Text(verbatim: [tab, title, detail, lockedLine ?? meta].compactMap { $0 }.filter { !$0.isEmpty }
            .joined(separator: ", ")))
        .accessibilityIdentifier(identifier)
    }

    /// A flat surface for every mode (V3: no kraft, grain, gradient or shadow).
    @ViewBuilder
    private var folderBody: some View {
        let shape = UnevenRoundedRectangle(topLeadingRadius: 0, bottomLeadingRadius: 10, bottomTrailingRadius: 10,
                                           topTrailingRadius: 10, style: .continuous)
        switch material {
        case .kraft:
            shape.fill(Trace.Colors.surface)
        case .alibi:
            shape.fill(Trace.Story.alibiPaper)
        case .story:
            shape.fill(Trace.Story.folder)
        }
    }
}

/// ENQUÊTES: the print of the case in progress, stapled to the folder.
private struct StapledPrint: View {
    let number: String?
    let seed: String

    var body: some View {
        PhotoPrint(caption: number, border: 4) {
            GeneratedPhoto(scene: "street_night", seed: seed.isEmpty ? "desk" : seed)
                .frame(width: 62, height: 56)
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

/// ALIBI: the statement's window (DÉCLARÉ) over what the phone recorded (RELEVÉ), the gap in red.
/// A visual hint only: it never gives away what the check will find.
private struct AlibiColumns: View {
    let window: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            StoryLabel(text: L10n.t("mode.alibi.declared"), color: Trace.Story.alibiInk)
            bar(gap: false)
            StoryLabel(text: L10n.t("mode.alibi.recorded"), color: Trace.Story.alibiInk)
                .padding(.top, 3)
            bar(gap: true)
            if let window {
                Text(window)
                    .font(Trace.StoryFonts.technical)
                    .foregroundStyle(Trace.Story.alibiInkSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .padding(.top, 2)
            }
        }
        .frame(width: 112, alignment: .leading)
        .accessibilityHidden(true)
    }

    private func bar(gap: Bool) -> some View {
        HStack(spacing: 0) {
            Rectangle().fill(Trace.Story.alibiInk).frame(width: gap ? 44 : 112, height: 2)
            if gap {
                Rectangle().fill(Trace.Colors.benText).frame(width: 36, height: 2)
                    .overlay(alignment: .leading) { Rectangle().fill(Trace.Colors.benText).frame(width: 1.5, height: 8) }
                    .overlay(alignment: .trailing) { Rectangle().fill(Trace.Colors.benText).frame(width: 1.5, height: 8) }
                Rectangle().fill(Trace.Story.alibiInk).frame(width: 32, height: 2)
            }
        }
        .frame(height: 8)
    }
}

/// HISTOIRE: the investigator's print on the BEN card (an empty print before the creation).
private struct StoryPortraitPrint: View {
    let image: UIImage?
    let initials: String
    let empty: Bool

    var body: some View {
        Group {
            if empty {
                Rectangle().fill(Trace.Colors.surface3.opacity(0.3)).frame(width: 52, height: 65)
            } else {
                PortraitOrInitials(image: image, initials: initials, width: 52, height: 65)
            }
        }
        .padding(3)
        .background(Trace.Colors.surface2)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

// MARK: - h04 · Hub Histoire

/// h04: resume in one tap. The investigator in the BEN's corridor (3/4 back, a slow lateral
/// travelling), the name, rank and service number, the chapter in progress, [CONTINUER], and three
/// outlined buttons. ⚙ top right, ‹ Bureau top left.
struct StoryHubView: View {
    let story: StoryCoordinator
    let onBack: () -> Void
    let onContinue: () -> Void
    let onProfile: () -> Void
    let onCareer: () -> Void
    let onOffice: () -> Void
    let onSettings: () -> Void
    let onChapter: (String) -> Void

    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    @AppStorage(Preferences.reduceMotionKey) private var appReduceMotion = false

    /// « Réduire les mouvements de caméra » (h19) follows « Réduire les animations » unless set.
    private var stillCamera: Bool { StoryPreferences.reduceCameraMotion ?? (systemReduceMotion || appReduceMotion) }

    private var officeOpen: Bool { story.save?.unlocks.contains("office_01") ?? false }

    var body: some View {
        ZStack(alignment: .top) {
            Trace.Story.sceneVoid.ignoresSafeArea()
            StoryHeroRender(story: story, still: stillCamera)
                .frame(height: DeskMetrics.heroHeight)
                .frame(maxWidth: .infinity)
                .ignoresSafeArea(edges: .top)
            GeometryReader { geo in
                ScrollView {
                    details
                        .frame(maxWidth: .infinity, minHeight: geo.size.height, alignment: .bottom)
                }
                .scrollBounceBehavior(.basedOnSize)
            }
            topBar
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("story.hub")
    }

    // MARK: Top bar (HUD pills, 32 pt tall, 44 pt targets)

    private var topBar: some View {
        HStack {
            Button(action: onBack) {
                HStack(spacing: 3) {
                    Image(systemName: "chevron.left").font(.system(size: 15, weight: .semibold))
                    Text(L10n.t("tab.bureau")).font(Trace.Fonts.link)
                }
                .foregroundStyle(Trace.Colors.benText)
                .padding(.horizontal, 12)
                .frame(height: 32)
                .background(Capsule().fill(Trace.Story.hud))
                .frame(minHeight: 44)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text(L10n.t("story.hub.backToDesk")))
            .accessibilityIdentifier("story.back")
            Spacer()
            Button(action: onSettings) {
                Image(systemName: "gearshape")
                    .font(.system(size: 16, weight: .regular))
                    .foregroundStyle(Trace.Colors.text)
                    .frame(width: 32, height: 32)
                    .background(Circle().fill(Trace.Story.hud))
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text(L10n.t("story.hub.settings")))
            .accessibilityIdentifier("story.settings")
        }
        .padding(.horizontal, 12)
    }

    // MARK: Details

    private var details: some View {
        VStack(alignment: .leading, spacing: 0) {
            if story.loadError != nil {
                PostItNote(title: L10n.t("story.hub.errorTitle"), message: L10n.t("story.hub.error"))
                    .padding(.horizontal, DeskMetrics.textOnRender)
                    .padding(.bottom, 24)
                    .accessibilityIdentifier("story.hub.error")
            }
            if let player = story.player {
                VStack(alignment: .leading, spacing: 6) {
                    StoryLabel(text: L10n.t("story.hub.kicker"), color: Trace.Colors.text2)
                    Text(verbatim: "\(player.firstName) \(player.lastName)")
                        .font(Trace.StoryFonts.h1Hero)
                        .foregroundStyle(Trace.Story.dialogue)
                        .lineLimit(2)
                        .minimumScaleFactor(0.7)
                        .accessibilityAddTraits(.isHeader)
                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        Text(story.rankTitle())
                            .font(Trace.Fonts.callout)
                            .foregroundStyle(Trace.Colors.text2)
                        Text(verbatim: "·").foregroundStyle(Trace.Colors.text3).accessibilityHidden(true)
                        Text(verbatim: player.serviceNumber)
                            .font(Trace.Fonts.data)
                            .foregroundStyle(Trace.Colors.text2)
                    }
                    .accessibilityElement(children: .combine)
                }
                .padding(.horizontal, DeskMetrics.textOnRender)
            }
            chapterBlock
                .padding(.horizontal, DeskMetrics.textOnRender)
                .padding(.top, 22)
            mainButton
                .padding(.horizontal, DeskMetrics.buttonMargin)
                .padding(.top, 20)
            grid
                .padding(.horizontal, DeskMetrics.buttonMargin)
                .padding(.top, 10)
        }
        .padding(.top, 120)
        .padding(.bottom, 10)
    }

    /// Filet, « CHAPITRE 0N » / « SCÈNE n / N », the title, a 2 pt bar. End of content: a note.
    @ViewBuilder
    private var chapterBlock: some View {
        if story.endOfContent {
            VStack(alignment: .leading, spacing: 8) {
                Rectangle().fill(Trace.Colors.text.opacity(0.22)).frame(height: 1)
                StoryLabel(text: L10n.t("story.hub.endKicker"), color: Trace.Colors.text2)
                Text(L10n.t("story.hub.endOfContent"))
                    .font(Trace.StoryFonts.h3)
                    .foregroundStyle(Trace.Story.dialogue)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .accessibilityElement(children: .combine)
            .accessibilityIdentifier("story.chapterBlock")
        } else if let chapter = story.currentChapter {
            let progress = story.sceneProgress
            Button { onChapter(chapter.id) } label: {
                VStack(alignment: .leading, spacing: 8) {
                    Rectangle().fill(Trace.Colors.text.opacity(0.22)).frame(height: 1)
                    HStack(alignment: .firstTextBaseline) {
                        StoryLabel(text: L10n.f("story.hub.chapter", chapter.number), color: Trace.Colors.text2)
                        Spacer(minLength: 8)
                        if progress.total > 0 {
                            StoryLabel(text: L10n.f("story.hub.scene", progress.index, progress.total), color: Trace.Colors.text2)
                        }
                    }
                    HStack(alignment: .center, spacing: 8) {
                        Text(chapter.title.capitalizedFirst)
                            .font(Trace.StoryFonts.h3)
                            .foregroundStyle(Trace.Story.dialogue)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                        Spacer(minLength: 4)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(Trace.Colors.text2)
                            .accessibilityHidden(true)
                    }
                    ChapterBar(progress: chapterFraction(chapter), track: Trace.Colors.text.opacity(0.18), fill: Trace.Story.dialogue)
                }
                .frame(minHeight: 44)
                .contentShape(Rectangle())
            }
            .buttonStyle(PressableStyle())
            .accessibilityHint(Text(L10n.t("story.hub.chapterHint")))
            .accessibilityIdentifier("story.chapterBlock")
        }
    }

    /// Steps done in the chapter (a finished chapter is full).
    private func chapterFraction(_ chapter: StoryChapter) -> Double {
        guard let save = story.save else { return 0 }
        if save.completedChapters.contains(chapter.id) && save.position.chapterID != chapter.id { return 1 }
        guard save.position.chapterID == chapter.id, !chapter.steps.isEmpty else { return 0 }
        return min(1, Double(save.position.stepIndex) / Double(chapter.steps.count))
    }

    /// [CONTINUER] — the only filled button; [REVOIR UN CHAPITRE] at the end of the content.
    @ViewBuilder
    private var mainButton: some View {
        if story.endOfContent {
            Button(L10n.t("story.hub.replay"), action: onSettings)
                .buttonStyle(CTAButtonStyle())
                .accessibilityIdentifier("story.continue")
        } else {
            Button(L10n.t("story.hub.continue"), action: onContinue)
                .buttonStyle(CTAButtonStyle())
                .disabled(story.content == nil || story.player == nil)
                .accessibilityIdentifier("story.continue")
        }
    }

    /// MON ENQUÊTEUR · CARRIÈRE · MON BUREAU (outlined, 48 pt).
    private var grid: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Button(L10n.t("story.hub.profile"), action: onProfile)
                    .buttonStyle(HubOutlineStyle())
                    .accessibilityIdentifier("story.profile")
                Button(L10n.t("story.hub.career"), action: onCareer)
                    .buttonStyle(HubOutlineStyle())
                    .accessibilityIdentifier("story.career")
                Button(L10n.t("story.hub.office"), action: onOffice)
                    .buttonStyle(HubOutlineStyle())
                    .disabled(!officeOpen)
                    .accessibilityHint(Text(officeOpen ? "" : L10n.t("story.hub.officeLocked")))
                    .accessibilityIdentifier("story.office")
            }
            .disabled(story.player == nil)
            if !officeOpen {
                Text(L10n.t("story.hub.officeLocked"))
                    .font(Trace.StoryFonts.caption)
                    .foregroundStyle(Trace.Colors.text2)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .accessibilityHidden(true)
            }
        }
    }
}

/// A secondary button of the hub's grid (V3 ActionButton « secondaire »): `surface2`, radius 14,
/// 48 pt, Plex Sans 15/600 in sentence case (two lines if needed). Disabled: `text3`.
private struct HubOutlineStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        let shape = RoundedRectangle(cornerRadius: Trace.Radius.button, style: .continuous)
        return configuration.label
            .font(Trace.Fonts.monoStrong)
            .multilineTextAlignment(.center)
            .lineLimit(2)
            .minimumScaleFactor(0.8)
            .foregroundStyle(isEnabled ? Trace.Colors.text : Trace.Colors.text3)
            .padding(.horizontal, 6)
            .frame(maxWidth: .infinity, minHeight: 48)
            .background(shape.fill(configuration.isPressed ? Trace.Colors.surface3 : Trace.Colors.surface2))
            .contentShape(shape)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .brightness(configuration.isPressed ? -0.04 : 0)
            .animation(.easeOut(duration: 0.09), value: configuration.isPressed)
    }
}

/// StoryHeroRender (470 pt): the player alone in the BEN's corridor (anchor « hero »,
/// cam_corr_hero, MEDIUM), a slow lateral travelling unless the camera is still; the bottom 200 pt
/// veiled to scene.void. Nothing loaded: plain scene.void.
private struct StoryHeroRender: View {
    let story: StoryCoordinator
    let still: Bool

    private static let locationID = "ENV_BEN_CORRIDOR"
    private static let anchorID = "hero"
    private static let cameraID = "cam_corr_hero"

    var body: some View {
        ZStack(alignment: .bottom) {
            Trace.Story.sceneVoid
            if let content = story.content, let player = story.player, let location = content.location(Self.locationID) {
                StoryStageView(snapshot: snapshot(content: content, player: player, location: location))
            }
            LinearGradient(colors: [Trace.Story.sceneVoid.opacity(0), Trace.Story.sceneVoid],
                           startPoint: .top, endPoint: .bottom)
                .frame(height: DeskMetrics.heroVeil)
        }
        .clipped()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private func snapshot(content: StoryContent, player: StoryPlayer, location: StoryLocation) -> StageSnapshot {
        var stage = StageState()
        stage.location = Self.locationID
        if let anchor = location.anchor(Self.anchorID) {
            stage.actors["player"] = ActorState(x: anchor.x, z: anchor.z, facing: anchor.facing, visible: true, seated: false,
                                                anchor: anchor.id, pose: nil)
        }
        stage.shot = CameraShot(kind: .medium, camera: Self.cameraID)
        return StageSnapshot(stage: stage, location: location, content: content, player: player,
                             rank: story.save?.rank ?? .enqueteur, unlocks: story.save?.unlocks ?? [],
                             officeLevel: story.officeLevel, text: { story.resolve($0) },
                             reduceMotion: still, drift: !still)
    }
}

// MARK: - Studio (h05, h06)

/// The studio's backdrop (render.bg): radial #2A313B → #12151A → #0A0B0D.
private struct RenderBackdrop: View {
    var body: some View {
        RadialGradient(colors: [Trace.Story.renderTop, Trace.Story.renderMid, Trace.Story.sceneVoid],
                       center: UnitPoint(x: 0.5, y: 0.42), startRadius: 0, endRadius: 330)
            .accessibilityHidden(true)
    }
}

/// Where CharacterPreview's full-length camera puts things (50 mm, 3.6 m away, aimed at 0.92 m):
/// the frame is ≈ 2.6 m tall and its top edge at ≈ 2.22 m.
private enum StudioFraming {
    static let frameHeight: CGFloat = 2.6
    static let top: CGFloat = 2.22

    static func y(_ metres: CGFloat, scale: CGFloat) -> CGFloat { (top - metres) * scale }
}

/// The person on the studio's backdrop; the finger turns them (±180°), a damped return in 400 ms.
/// Decorative for VoiceOver (the choices are described by the controls).
private struct TurntableStudio: View {
    let appearance: CharacterAppearance
    let catalog: CharacterCatalog
    var rank: StoryRank = .enqueteur
    var closeUp = false
    /// At most two LABELs, full length only.
    var annotations: [String] = []
    /// False when the caller lays render.bg itself (to the screen's edges).
    var backdrop = true

    @State private var yaw: Double = 0
    @State private var dragBase: Double?
    @State private var settle: Task<Void, Never>?
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    @AppStorage(Preferences.reduceMotionKey) private var appReduceMotion = false

    var body: some View {
        ZStack {
            if backdrop { RenderBackdrop() }
            CharacterPreview(appearance: appearance, catalog: catalog, rank: rank, yaw: yaw, closeUp: closeUp)
            if !closeUp, !annotations.isEmpty, abs(yaw) < 4 {
                OutfitAnnotations(lines: Array(annotations.prefix(2)), feminine: appearance.presentation == "presentation_f")
            }
        }
        .clipped()
        .contentShape(Rectangle())
        .gesture(turn)
        .accessibilityHidden(true)
        .onDisappear { settle?.cancel() }
    }

    private var turn: some Gesture {
        DragGesture(minimumDistance: 6)
            .onChanged { value in
                settle?.cancel()
                let base = dragBase ?? yaw
                if dragBase == nil { dragBase = yaw }
                yaw = min(180, max(-180, base + Double(value.translation.width) * 0.75))
            }
            .onEnded { _ in
                dragBase = nil
                returnToFront()
            }
    }

    /// Back to the front, ease-out over ≈ 400 ms (at once with reduced motion).
    private func returnToFront() {
        settle?.cancel()
        let start = yaw
        guard abs(start) > 0.5, !(systemReduceMotion || appReduceMotion) else {
            yaw = 0
            return
        }
        settle = Task { @MainActor in
            let frames = 24
            for i in 1...frames {
                try? await Task.sleep(for: .milliseconds(16))
                if Task.isCancelled { return }
                let t = Double(i) / Double(frames)
                yaw = start * pow(1 - t, 3)
            }
        }
    }
}

/// Two LABELs on scrim, each linked by a 1 pt line to the part of the outfit it names.
private struct OutfitAnnotations: View {
    let lines: [String]
    let feminine: Bool

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let scale = geo.size.height / StudioFraming.frameHeight
            let height: CGFloat = feminine ? 0.96 : 1.03
            let outer = CGPoint(x: w / 2 - 0.13 * scale, y: StudioFraming.y(1.18 * height, scale: scale))
            let inner = CGPoint(x: w / 2 + 0.02 * scale, y: StudioFraming.y(1.36 * height, scale: scale))
            let edge: CGFloat = 20
            ZStack(alignment: .topLeading) {
                Path { p in
                    p.move(to: CGPoint(x: edge, y: outer.y))
                    p.addLine(to: outer)
                    if lines.count > 1 {
                        p.move(to: CGPoint(x: w - edge, y: inner.y))
                        p.addLine(to: inner)
                    }
                }
                .stroke(Trace.Colors.text.opacity(0.8), lineWidth: 1)
                Circle().fill(Trace.Colors.text).frame(width: 5, height: 5)
                    .offset(x: outer.x - 2.5, y: outer.y - 2.5)
                if lines.count > 1 {
                    Circle().fill(Trace.Colors.text).frame(width: 5, height: 5)
                        .offset(x: inner.x - 2.5, y: inner.y - 2.5)
                }
                if let first = lines.first {
                    tag(first)
                        .frame(width: max(0, outer.x - edge - 6), alignment: .leading)
                        .offset(x: edge, y: outer.y - 24)
                }
                if lines.count > 1 {
                    tag(lines[1])
                        .frame(width: max(0, w - edge - inner.x - 6), alignment: .trailing)
                        .offset(x: inner.x + 6, y: inner.y - 24)
                }
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private func tag(_ text: String) -> some View {
        StoryLabel(text: text, color: Trace.Colors.text)
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(Trace.Story.hotspotLabel)
    }
}

// MARK: - Controls of the creator (V3)

private struct SegmentOption<Value: Hashable> {
    let value: Value
    let label: String
    let id: String
}

/// A V3 segmented control (the NotebookTab look, §5): 40 pt segments in a `surface2` track (radius
/// 12), the chosen one on `surface3` (radius 9) in `text`/600, the others in `text2`; each segment
/// has a 44 pt target. Sentence case, Plex Sans 14.
private struct PaperSegmented<Value: Hashable>: View {
    let options: [SegmentOption<Value>]
    let selection: Value
    var height: CGFloat = Trace.Height.segment
    let onSelect: (Value) -> Void

    var body: some View {
        HStack(spacing: 0) {
            ForEach(options.indices, id: \.self) { i in
                let option = options[i]
                let on = option.value == selection
                Button {
                    guard !on else { return }
                    Haptics.selection()
                    onSelect(option.value)
                } label: {
                    Text(option.label)
                        .font(on ? .custom(Trace.FontName.sansSemibold, size: 14, relativeTo: .subheadline)
                                 : .custom(Trace.FontName.sans, size: 14, relativeTo: .subheadline))
                        .foregroundStyle(on ? Trace.Colors.text : Trace.Colors.text2)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .padding(.horizontal, 4)
                        .frame(maxWidth: .infinity, minHeight: height)
                        .background {
                            if on {
                                RoundedRectangle(cornerRadius: Trace.Radius.segment, style: .continuous)
                                    .fill(Trace.Colors.surface3)
                            }
                        }
                        .frame(minHeight: Trace.Height.hit)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text(option.label))
                .accessibilityAddTraits(on ? .isSelected : [])
                .accessibilityIdentifier(option.id)
            }
        }
        .padding(2)
        .background(RoundedRectangle(cornerRadius: Trace.Radius.segmented, style: .continuous).fill(Trace.Colors.surface2))
    }
}

/// A selectable chip (V3): `surface2`, a 2 pt `ben` border and `surface3` when chosen.
private struct ChipBackground: ViewModifier {
    let chosen: Bool

    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: Trace.Radius.node, style: .continuous)
        content
            .background(shape.fill(chosen ? Trace.Colors.surface3 : Trace.Colors.surface2))
            .overlay(shape.strokeBorder(chosen ? Trace.Colors.ben : Trace.Colors.line, lineWidth: chosen ? 2 : 1))
    }
}

/// CharacterOptionSwatch: a 44 pt round swatch (a colour from the data), or a 44 pt chip with the
/// option's name (shapes, haircuts). Selected: a `surface` gap of 2 pt, then a `ben` ring of 2 pt.
private struct CharacterOptionSwatch: View {
    let variant: CharacterVariant
    let selected: Bool
    let action: () -> Void

    var body: some View {
        let label = CreatorText.label(variant)
        Button(action: action) {
            Group {
                if let hex = variant.color {
                    Circle()
                        .fill(Color(uiColor: UIColor(storyHex: hex)))
                        .frame(width: 44, height: 44)
                        .overlay(Circle().strokeBorder(Trace.Colors.line, lineWidth: 1))
                        .overlay {
                            if selected {
                                ZStack {
                                    Circle().strokeBorder(Trace.Colors.surface, lineWidth: 2).padding(-2)
                                    Circle().strokeBorder(Trace.Colors.ben, lineWidth: 2).padding(-4)
                                }
                            }
                        }
                } else {
                    Text(label)
                        .font(Trace.Fonts.callout)
                        .foregroundStyle(Trace.Colors.text)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                        .padding(.horizontal, 12)
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .modifier(ChipBackground(chosen: selected))
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(PressableStyle())
        .accessibilityLabel(Text(label))
        .accessibilityAddTraits(selected ? .isSelected : [])
        .accessibilityIdentifier("creator.option.\(variant.id)")
    }
}

// MARK: - h05 · Création du personnage

/// h05 (4 steps: IDENTITÉ → APPARENCE → TENUE (h06) → CONFIRMATION (h05b)), or, when `editing`
/// (h19 « Modifier l'apparence »), only APPARENCE and TENUE, saved with [ENREGISTRER]. The 3D render
/// on top (350 pt, turned with a finger), a flat `surface` sheet at the bottom (340 pt).
struct CharacterCreatorView: View {
    let story: StoryCoordinator
    let editing: Bool
    let onClose: () -> Void

    private enum Step: Int, CaseIterable { case identity, appearance, outfit, confirmation }
    private enum NameField: Hashable { case first, last }

    @State private var step: Step = .identity
    @State private var draft: CharacterAppearance?
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var agreement: Agreement = .feminine
    @State private var template: String?
    @State private var nameError = false
    @State private var category: AppearanceSlot = .skinTone
    @State private var stamped = false
    @State private var creating = false
    @State private var created = false
    @State private var blackout: Double = 0
    @FocusState private var focus: NameField?
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    @AppStorage(Preferences.reduceMotionKey) private var appReduceMotion = false

    private var reduceMotion: Bool { systemReduceMotion || appReduceMotion }
    private var motion: Animation { reduceMotion ? .easeInOut(duration: 0.2) : Trace.StoryMotion.paper }
    /// A sheet of paper sliding in (a 200 ms fade with reduced motion).
    private var stepTransition: AnyTransition { reduceMotion ? .opacity : .opacity.combined(with: .offset(x: 24)) }
    private var steps: [Step] { editing ? [.appearance, .outfit] : Step.allCases }
    private var stepIndex: Int { steps.firstIndex(of: step) ?? 0 }
    /// Creation: every player starts from the same catalogue; editing: what the career unlocked too.
    private var unlocked: Set<String> { editing ? (story.save?.unlocks ?? []) : [] }
    private var presentation: String { draft?.presentation ?? "presentation_f" }
    private var reservedNames: [String] { (story.content?.npcs ?? []).map { "\($0.firstName) \($0.lastName)" } }

    var body: some View {
        GeometryReader { geo in
            let renderHeight = max(120, min(DeskMetrics.renderHeight, geo.size.height - DeskMetrics.sheetHeight))
            VStack(spacing: 0) {
                renderArea
                    .frame(height: renderHeight)
                sheet
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .background(Trace.Story.sceneVoid.ignoresSafeArea())
        .overlay {
            // T-UI-3: the fade to black before the first scene.
            Trace.Story.sceneVoid.opacity(blackout).ignoresSafeArea().allowsHitTesting(false)
        }
        .allowsHitTesting(!creating)
        .onAppear { prepare() }
        .onChange(of: story.catalog == nil) { _, _ in prepare() }
    }

    // MARK: Render

    private var renderArea: some View {
        ZStack(alignment: .top) {
            RenderBackdrop().ignoresSafeArea(edges: .top)
            if let catalog = story.catalog, let look = draft {
                TurntableStudio(appearance: look, catalog: catalog, rank: story.save?.rank ?? .enqueteur,
                                closeUp: step == .appearance,
                                annotations: step == .outfit ? CreatorText.annotations(catalog.variant(look.outfit)) : [],
                                backdrop: false)
            }
            topBar
        }
    }

    private var topBar: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                BackChevron(label: editing && stepIndex == 0 ? L10n.t("story.creator.close") : nil) { back() }
                    .accessibilityIdentifier("creator.back")
                Spacer(minLength: 8)
                StoryLabel(text: L10n.f("story.creator.stepLine", stepIndex + 1, steps.count, title(of: step)),
                           color: Trace.Colors.text2)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            StepBar(count: steps.count, done: stepIndex + 1)
        }
        .padding(.horizontal, DeskMetrics.sheetMargin)
        .padding(.top, 4)
    }

    private func title(of step: Step) -> String {
        switch step {
        case .identity: L10n.t("story.creator.step.identity")
        case .appearance: L10n.t("story.creator.step.appearance")
        case .outfit: L10n.t("story.creator.step.outfit")
        case .confirmation: L10n.t("story.creator.step.confirmation")
        }
    }

    // MARK: Sheet

    private var sheet: some View {
        let shape = UnevenRoundedRectangle(topLeadingRadius: Trace.Radius.sheet, topTrailingRadius: Trace.Radius.sheet,
                                           style: .continuous)
        return VStack(spacing: 0) {
            ScrollView {
                stepContent
                    .id(step)
                    .transition(stepTransition)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, DeskMetrics.sheetMargin)
                    .padding(.top, 20)
                    .padding(.bottom, 12)
            }
            .scrollBounceBehavior(.basedOnSize)
            .scrollDismissesKeyboard(.interactively)
            footer
                .padding(.horizontal, DeskMetrics.buttonMargin)
                .padding(.top, 8)
                .padding(.bottom, 10)
        }
        .background(
            shape.fill(Trace.Colors.surface)
                .ignoresSafeArea(edges: .bottom)
        )
        .overlay(alignment: .top) {
            if nameError {
                PostItNote(title: L10n.t("story.creator.nameErrorTitle"), message: L10n.t("story.creator.nameError"))
                    .padding(.horizontal, DeskMetrics.buttonMargin)
                    .offset(y: -64)
                    .onTapGesture { withAnimation(motion) { nameError = false } }
                    .transition(.opacity)
                    .accessibilityIdentifier("creator.nameError")
            }
        }
    }

    @ViewBuilder
    private var stepContent: some View {
        switch step {
        case .identity: identityStep
        case .appearance: appearanceStep
        case .outfit: outfitStep
        case .confirmation: confirmationStep
        }
    }

    @ViewBuilder
    private var footer: some View {
        switch step {
        case .confirmation:
            // §8 « Maintien 1,2 s (identité) ».
            BenHoldButton(title: L10n.t("story.creator.confirm"), seconds: 1.2, identifier: "creator.confirm") { confirm() }
        case .outfit where editing:
            Button(L10n.t("story.creator.save")) { save() }
                .buttonStyle(CTAButtonStyle())
                .disabled(draft == nil)
                .accessibilityIdentifier("creator.close")
        default:
            Button(L10n.t("story.creator.next")) { next() }
                .buttonStyle(CTAButtonStyle())
                .disabled(draft == nil)
                .accessibilityIdentifier("creator.next")
        }
    }

    // MARK: Step 1 · IDENTITÉ

    @ViewBuilder
    private var identityStep: some View {
        VStack(alignment: .leading, spacing: 14) {
            if let templates = story.catalog?.templates, !templates.isEmpty {
                StoryLabel(text: L10n.t("story.creator.template"), color: Trace.Colors.text2)
                HStack(spacing: 10) {
                    ForEach(templates) { model in
                        templateChip(model)
                    }
                }
            }
            nameField(L10n.t("story.creator.firstName"), prompt: L10n.t("story.creator.firstNamePrompt"),
                      text: $firstName, field: .first, id: "creator.firstName")
            nameField(L10n.t("story.creator.lastName"), prompt: L10n.t("story.creator.lastNamePrompt"),
                      text: $lastName, field: .last, id: "creator.lastName")
            StoryLabel(text: L10n.t("story.creator.base"), color: Trace.Colors.text2)
                .padding(.top, 4)
            PaperSegmented(options: [
                SegmentOption(value: "presentation_f", label: L10n.t("story.creator.baseFeminine"), id: "creator.base.f"),
                SegmentOption(value: "presentation_m", label: L10n.t("story.creator.baseMasculine"), id: "creator.base.m"),
            ], selection: presentation) { setBase($0) }
            StoryLabel(text: L10n.t("story.creator.agreement"), color: Trace.Colors.text2)
                .padding(.top, 4)
            PaperSegmented(options: [
                SegmentOption(value: Agreement.feminine, label: L10n.t("story.creator.agreementF"), id: "creator.agreement.f"),
                SegmentOption(value: Agreement.masculine, label: L10n.t("story.creator.agreementM"), id: "creator.agreement.m"),
                SegmentOption(value: Agreement.neutral, label: L10n.t("story.creator.agreementN"), id: "creator.agreement.n"),
            ], selection: agreement) { agreement = $0 }
        }
    }

    /// Élise Morel / Vincent Delmas: a name, a look and an agreement, all editable.
    private func templateChip(_ model: CharacterTemplate) -> some View {
        let chosen = template == model.id
        return Button { apply(model) } label: {
            Text(verbatim: "\(model.firstName) \(model.lastName)")
                .font(Trace.StoryFonts.uiBody)
                .foregroundStyle(Trace.Colors.text)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .padding(.horizontal, 12)
                .frame(maxWidth: .infinity, minHeight: 44)
                .modifier(ChipBackground(chosen: chosen))
                .contentShape(Rectangle())
        }
        .buttonStyle(PressableStyle())
        .accessibilityAddTraits(chosen ? .isSelected : [])
        .accessibilityIdentifier("creator.template.\(model.id)")
    }

    /// A 56 pt V3 field (`surface2`, radius 12): caption label, Plex Sans 17 input.
    private func nameField(_ label: String, prompt: String, text: Binding<String>, field: NameField, id: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(Trace.Fonts.caption)
                .foregroundStyle(Trace.Colors.text2)
                .accessibilityHidden(true)
            TextField("", text: text, prompt: Text(prompt).foregroundStyle(Trace.Colors.text3))
                .font(Trace.StoryFonts.input)
                .foregroundStyle(Trace.Colors.text)
                .tint(Trace.Colors.ben)
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled()
                .textContentType(field == .first ? UITextContentType.givenName : UITextContentType.familyName)
                .submitLabel(field == .first ? .next : .done)
                .focused($focus, equals: field)
                .onSubmit { focus = field == .first ? .last : nil }
                .accessibilityLabel(Text(label))
                .accessibilityIdentifier(id)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .frame(maxWidth: .infinity, minHeight: 56, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: Trace.Radius.node, style: .continuous).fill(Trace.Colors.surface2))
        .onChange(of: text.wrappedValue) { _, _ in
            if nameError { withAnimation(motion) { nameError = false } }
        }
    }

    // MARK: Step 2 · APPARENCE

    @ViewBuilder
    private var appearanceStep: some View {
        VStack(alignment: .leading, spacing: 18) {
            PaperSegmented(options: [
                SegmentOption(value: AppearanceSlot.skinTone, label: L10n.t("story.creator.categorySkin"), id: "creator.category.skinTone"),
                SegmentOption(value: AppearanceSlot.face, label: L10n.t("story.creator.categoryFace"), id: "creator.category.face"),
                SegmentOption(value: AppearanceSlot.hairStyle, label: L10n.t("story.creator.categoryHair"), id: "creator.category.hairStyle"),
                SegmentOption(value: AppearanceSlot.eyeColor, label: L10n.t("story.creator.categoryEyes"), id: "creator.category.eyeColor"),
            ], selection: category) { slot in
                withAnimation(.easeInOut(duration: 0.15)) { category = slot }
            }
            switch category {
            case .face:
                optionRow(L10n.t("story.creator.faceShape"), slot: .face)
                if presentation == "presentation_m" {
                    optionRow(L10n.t("story.creator.facialHair"), slot: .beard)
                }
            case .hairStyle:
                optionRow(L10n.t("story.creator.haircut"), slot: .hairStyle)
                optionRow(L10n.t("story.creator.hairColor"), slot: .hairColor)
            case .eyeColor:
                optionRow(nil, slot: .eyeColor)
            default:
                optionRow(nil, slot: .skinTone)
            }
        }
    }

    /// Six colour swatches in a row, or name chips on a grid.
    @ViewBuilder
    private func optionRow(_ title: String?, slot: AppearanceSlot) -> some View {
        let options = story.catalog?.options(for: slot, presentation: presentation, unlocked: unlocked) ?? []
        let selectedID = draft?[slot]
        VStack(alignment: .leading, spacing: 10) {
            if let title {
                StoryLabel(text: title, color: Trace.Colors.text2)
            }
            if !options.isEmpty, options.allSatisfy({ $0.color != nil }) {
                HStack(spacing: 10) {
                    ForEach(options) { variant in
                        CharacterOptionSwatch(variant: variant, selected: variant.id == selectedID) { select(variant) }
                    }
                }
                .padding(.vertical, 4)
                .padding(.horizontal, 4)
            } else {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: 8)], alignment: .leading, spacing: 8) {
                    ForEach(options) { variant in
                        CharacterOptionSwatch(variant: variant, selected: variant.id == selectedID) { select(variant) }
                    }
                }
            }
        }
    }

    // MARK: Step 3 · TENUE (h06)

    /// The outfits, grouped (one card, its colour variants), in the catalogue's order.
    private var outfitGroups: [[CharacterVariant]] {
        var ids: [String] = []
        var groups: [String: [CharacterVariant]] = [:]
        for variant in story.catalog?.options(for: .outfit, presentation: presentation, unlocked: unlocked) ?? [] {
            let key = variant.group ?? variant.id
            if groups[key] == nil { ids.append(key) }
            groups[key, default: []].append(variant)
        }
        return ids.compactMap { groups[$0] }
    }

    @ViewBuilder
    private var outfitStep: some View {
        let groups = outfitGroups
        let current = groups.firstIndex { group in group.contains { $0.id == draft?.outfit } } ?? 0
        if groups.indices.contains(current) {
            let variants = groups[current]
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .center, spacing: 8) {
                    carouselButton(symbol: "chevron.left", label: L10n.t("story.creator.outfitPrevious"), id: "creator.outfit.prev") {
                        moveOutfit(-1)
                    }
                    VStack(spacing: 4) {
                        StoryLabel(text: L10n.f("story.creator.outfitCount", current + 1, groups.count), color: Trace.Colors.text2)
                        Text(variants.first.map { CreatorText.outfitName($0) } ?? "")
                            .font(Trace.StoryFonts.h3)
                            .foregroundStyle(Trace.Colors.text)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity)
                    .accessibilityElement(children: .combine)
                    carouselButton(symbol: "chevron.right", label: L10n.t("story.creator.outfitNext"), id: "creator.outfit.next") {
                        moveOutfit(1)
                    }
                }
                HStack(spacing: 10) {
                    ForEach(variants) { variant in
                        variantChip(variant)
                    }
                }
                Text(L10n.t("story.creator.outfitNote"))
                    .font(Trace.StoryFonts.caption)
                    .foregroundStyle(Trace.Colors.text2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func carouselButton(symbol: String, label: String, id: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(Trace.Colors.text)
                .frame(width: 44, height: 44)
                .background(Circle().fill(Trace.Colors.surface2))
                .contentShape(Rectangle())
        }
        .buttonStyle(PressableStyle())
        .accessibilityLabel(Text(label))
        .accessibilityIdentifier(id)
    }

    /// A colour variant: its swatch and its name (« Marine »); tap to wear it.
    private func variantChip(_ variant: CharacterVariant) -> some View {
        let chosen = draft?.outfit == variant.id
        return Button { select(variant) } label: {
            HStack(spacing: 8) {
                Circle()
                    .fill(Color(uiColor: UIColor(storyHex: variant.color)))
                    .frame(width: 18, height: 18)
                    .overlay(Circle().strokeBorder(Trace.Colors.line, lineWidth: 1))
                Text(CreatorText.outfitColour(variant))
                    .font(Trace.Fonts.callout)
                    .foregroundStyle(Trace.Colors.text)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
            .padding(.horizontal, 14)
            .frame(maxWidth: .infinity, minHeight: 44)
            .modifier(ChipBackground(chosen: chosen))
            .contentShape(Rectangle())
        }
        .buttonStyle(PressableStyle())
        .accessibilityLabel(Text(CreatorText.label(variant)))
        .accessibilityAddTraits(chosen ? .isSelected : [])
        .accessibilityIdentifier("creator.variant.\(variant.id)")
    }

    // MARK: Step 4 · CONFIRMATION (h05b)

    private var confirmationStep: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    StoryLabel(text: L10n.t("story.creator.file"), color: Trace.Colors.text2)
                        .accessibilityAddTraits(.isHeader)
                    Text(verbatim: "BEN · " + L10n.t("assignment.bureau"))
                        .font(Trace.Fonts.caption)
                        .foregroundStyle(Trace.Colors.text2)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 8)
                if stamped {
                    StatusBadge(text: L10n.t("story.creator.stamp"), color: Trace.Colors.successText, symbol: "✓")
                        .transition(.opacity)
                }
            }
            Rectangle().fill(Trace.Colors.line).frame(height: 1)
            HStack(alignment: .top, spacing: 14) {
                confirmationPrint
                VStack(alignment: .leading, spacing: 0) {
                    FieldRow(label: L10n.t("story.creator.fileName"),
                             value: "\(StoryPlayer.normalized(firstName)) \(StoryPlayer.normalized(lastName))")
                    FieldRow(label: L10n.t("assignment.serviceNumber"), value: L10n.t("story.creator.numberPending"),
                             valueColor: Trace.Colors.text2)
                    FieldRow(label: L10n.t("story.creator.service"), value: "BEN", divider: false)
                }
            }
            VStack(alignment: .leading, spacing: 0) {
                FieldRow(label: L10n.t("story.creator.initialRank"),
                         value: StoryText.rankTitle(.enqueteur, form: StoryText.GrammaticalForm(agreement)))
                FieldRow(label: L10n.t("story.creator.assignment"), value: L10n.t("story.creator.unit"), divider: false)
            }
        }
    }

    /// The photo (4:5): the live bust (S4 framing) on `surface3`, rounded 12 pt.
    private var confirmationPrint: some View {
        ZStack {
            Trace.Colors.surface3
            if let catalog = story.catalog, let look = draft {
                CharacterPreview(appearance: look, catalog: catalog, rank: .enqueteur, yaw: 0, closeUp: true)
            }
        }
        .frame(width: 96, height: 120)
        .clipShape(RoundedRectangle(cornerRadius: Trace.Radius.node, style: .continuous))
        .accessibilityHidden(true)
    }

    // MARK: Actions

    /// The first look: the player's (editing), or the starting model chosen at « Qui enquête ? ».
    private func prepare() {
        guard draft == nil, let catalog = story.catalog else { return }
        if editing, let player = story.player {
            draft = catalog.fitted(player.appearance, unlocked: unlocked)
            firstName = player.firstName
            lastName = player.lastName
            agreement = player.agreement
            step = .appearance
            return
        }
        step = editing ? .appearance : .identity
        if let model = catalog.template(PlayerStore.identity.id.rawValue) ?? catalog.templates.first {
            apply(model)
        } else {
            let look = catalog.fitted(catalog.defaultAppearance, unlocked: unlocked)
            draft = look
            agreement = Agreement(presentation: look.presentation)
        }
    }

    private func apply(_ model: CharacterTemplate) {
        guard let catalog = story.catalog else { return }
        withAnimation(.easeInOut(duration: 0.15)) {
            template = model.id
            firstName = model.firstName
            lastName = model.lastName
            draft = catalog.fitted(model.appearance, unlocked: unlocked)
            agreement = model.agreement
            nameError = false
        }
    }

    /// FÉMININE / MASCULINE: the look is fitted to the base, the agreement follows it.
    private func setBase(_ base: String) {
        guard var look = draft, look.presentation != base, let catalog = story.catalog else { return }
        look.presentation = base
        draft = catalog.fitted(look, unlocked: unlocked)
        agreement = Agreement(presentation: base)
    }

    private func select(_ variant: CharacterVariant) {
        guard var look = draft, look[variant.slot] != variant.id else { return }
        look[variant.slot] = variant.id
        draft = look
        Haptics.selection()
    }

    /// ‹ ›: the next outfit, in the same colour variant (A/B) when it has one; wraps around.
    private func moveOutfit(_ delta: Int) {
        let groups = outfitGroups
        guard !groups.isEmpty, let look = draft else { return }
        let current = groups.firstIndex { group in group.contains { $0.id == look.outfit } } ?? 0
        let variantIndex = groups[current].firstIndex { $0.id == look.outfit } ?? 0
        let target = groups[(current + delta + groups.count) % groups.count]
        guard !target.isEmpty else { return }
        select(target[min(variantIndex, target.count - 1)])
        AudioDirector.shared.play(.paper, volume: 0.3)
    }

    private func go(to next: Step) {
        focus = nil
        AudioDirector.shared.play(.paper, volume: 0.35)
        withAnimation(motion) { step = next }
    }

    private func next() {
        switch step {
        case .identity:
            let first = firstName.trimmingCharacters(in: .whitespaces)
            let last = lastName.trimmingCharacters(in: .whitespaces)
            if StoryPlayer.nameProblem(firstName: first, lastName: last, reserved: reservedNames) != nil {
                focus = nil
                Haptics.warning()
                withAnimation(motion) { nameError = true }
                UIAccessibility.post(notification: .announcement, argument: L10n.t("story.creator.nameError"))
                return
            }
            nameError = false
            go(to: .appearance)
        case .appearance:
            go(to: .outfit)
        case .outfit:
            if editing { save() } else { go(to: .confirmation) }
        case .confirmation:
            break
        }
    }

    private func back() {
        focus = nil
        nameError = false
        guard stepIndex > 0 else {
            onClose()
            return
        }
        go(to: steps[stepIndex - 1])
    }

    /// Editing: the new look is saved (the portrait is printed again), then back.
    private func save() {
        if let look = draft { story.updateAppearance(look) }
        Haptics.success()
        onClose()
    }

    /// « Commencer ma carrière » held 1.2 s: the « ✓ Identité confirmée » badge appears (V3: no
    /// stamp), then T-UI-3 goes on.
    private func confirm() {
        guard !creating, draft != nil else { return }
        focus = nil
        creating = true
        withAnimation(.easeOut(duration: 0.2)) { stamped = true }
        Haptics.success()
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(250))
            stampLanded()
        }
    }

    /// Badge shown → 400 ms → fade to black (600 ms) → the investigator exists, chapter 1 starts.
    private func stampLanded() {
        guard !created, let look = draft else { return }
        created = true
        let first = StoryPlayer.normalized(firstName)
        let last = StoryPlayer.normalized(lastName)
        let chosen = agreement
        let fast = reduceMotion
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(fast ? 200 : 400))
            withAnimation(.easeIn(duration: fast ? 0.2 : 0.6)) { blackout = 1 }
            try? await Task.sleep(for: .milliseconds(fast ? 200 : 600))
            story.create(firstName: first, lastName: last, appearance: look, agreement: chosen)
            if !story.hasInvestigator {
                // Nothing could be created (content missing): never a dead end.
                withAnimation(.easeOut(duration: 0.3)) { blackout = 0 }
                stamped = false
                creating = false
                created = false
            }
        }
    }
}

// MARK: - h06 · Voir en 3D (read-only)

/// From the profile: the investigator full length in the studio, turned with a finger, the outfit's
/// name, [FERMER].
struct StoryModelViewer: View {
    let story: StoryCoordinator
    let onClose: () -> Void

    private var outfit: CharacterVariant? {
        guard let id = story.player?.appearance.outfit else { return nil }
        return story.catalog?.variant(id)
    }

    var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 4) {
                StoryLabel(text: L10n.t("story.hub.profile"), color: Trace.Colors.text2)
                if let player = story.player {
                    Text(verbatim: "\(player.firstName) \(player.lastName)")
                        .font(Trace.StoryFonts.h3)
                        .foregroundStyle(Trace.Story.dialogue)
                        .accessibilityAddTraits(.isHeader)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, DeskMetrics.textOnRender)
            .padding(.top, 12)
            .padding(.bottom, 8)
            Group {
                if let catalog = story.catalog, let player = story.player {
                    TurntableStudio(appearance: player.appearance, catalog: catalog, rank: story.save?.rank ?? .enqueteur,
                                    closeUp: false, annotations: CreatorText.annotations(outfit), backdrop: false)
                } else {
                    Color.clear
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            VStack(alignment: .leading, spacing: 6) {
                StoryLabel(text: L10n.t("story.creator.step.outfit"), color: Trace.Colors.text2)
                if let outfit {
                    Text(CreatorText.outfitName(outfit))
                        .font(Trace.StoryFonts.h3)
                        .foregroundStyle(Trace.Story.dialogue)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(CreatorText.outfitColour(outfit))
                        .font(Trace.Fonts.callout)
                        .foregroundStyle(Trace.Colors.text2)
                }
                Text(L10n.t("story.studio.dragHint"))
                    .font(Trace.StoryFonts.caption)
                    .foregroundStyle(Trace.Colors.text2)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityHidden(true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, DeskMetrics.textOnRender)
            .padding(.top, 12)
            Button(L10n.t("story.creator.close"), action: onClose)
                .buttonStyle(CTAButtonStyle())
                .accessibilityIdentifier("story.viewer.close")
                .padding(.horizontal, DeskMetrics.buttonMargin)
                .padding(.top, 14)
                .padding(.bottom, 10)
        }
        .background(
            ZStack {
                Trace.Story.sceneVoid
                RenderBackdrop()
            }
            .ignoresSafeArea()
        )
    }
}
#endif
