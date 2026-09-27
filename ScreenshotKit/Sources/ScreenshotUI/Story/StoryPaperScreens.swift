#if os(iOS)
import SwiftUI
import UIKit
import StoryEngine

// The paper screens of the story mode (docs/design_story/STORY_UX_FLOW.md §3): h07 the
// investigator's profile, h08 the career, h10 a chapter's folder, h15 the new case file,
// h16 → h17 → « Avancement de service » → h18 the end of a chapter, h19 the story's settings.
// They read `StoryCoordinator` and call its actions: no story rule here. Paper outside, one full
// button per screen at safeArea.bottom + 10, « ‹ » 44 × 44 at the top left, every sheet scrolls
// at large text sizes, and « Réduire les animations » turns every move into a 200 ms fade.

extension Trace.StoryFonts {
    /// The rank on the career timeline (h08): Plex Mono 12/700.
    static let careerRank = Font.custom(Trace.FontName.monoBold, fixedSize: 12)
}

// MARK: - Shared pieces

/// Pieces shared by the story's paper screens (a namespace: nothing here leaks out of the file).
private enum StoryPaper {
    private static let letters = Array("ABCDEFGHIJKLMNOPQRSTUVWXYZ")
    /// Words that keep their capitals when a title written in capitals is shown in sentence case.
    private static let acronyms: Set<String> = ["BEN", "SMS", "GPS"]

    /// « 01 », « 12 ».
    static func twoDigits(_ n: Int) -> String { n < 10 ? "0\(n)" : "\(n)" }

    /// « A », « B »… (the n-th case of a chapter).
    static func letter(_ index: Int) -> String { String(letters[max(0, min(index, letters.count - 1))]) }

    /// « PREMIÈRE AFFECTATION » → « Première affectation »: titles are written in capitals in the
    /// data. Acronyms (BEN) and references (BEN-2019-114) keep their capitals; mixed case is kept.
    static func title(_ text: String) -> String {
        guard text.contains(where: \.isLetter), text == text.uppercased() else { return text }
        var words: [String] = []
        var first = true
        for part in text.split(separator: " ", omittingEmptySubsequences: false) {
            let word = String(part)
            let bare = String(word.filter(\.isLetter))
            if acronyms.contains(bare) || word.contains(where: \.isNumber) {
                words.append(word)
            } else {
                let lower = word.lowercased()
                words.append(first ? lower.prefix(1).uppercased() + lower.dropFirst() : lower)
            }
            if !word.isEmpty { first = false }
        }
        return words.joined(separator: " ")
    }

    static func fullName(_ player: StoryPlayer?) -> String {
        guard let player else { return "—" }
        return player.firstName + " " + player.lastName
    }

    /// « É. MOREL »
    static func shortName(_ player: StoryPlayer) -> String {
        "\(player.firstName.prefix(1)). \(player.lastName.uppercased())"
    }

    static func initials(_ player: StoryPlayer?) -> String {
        guard let player else { return "" }
        return (String(player.firstName.prefix(1)) + String(player.lastName.prefix(1))).uppercased()
    }

    /// The inked stamp of a rank (Art.xcassets/Stamps).
    static func stampAsset(_ rank: StoryRank) -> String { "stamp_\(rank.rawValue)_rouge" }

    /// mm:ss (an hour counts as 60 minutes); « — » for nothing.
    static func duration(_ seconds: Int) -> String {
        guard seconds > 0 else { return "—" }
        return String(format: "%02ld:%02ld", seconds / 60, seconds % 60)
    }

    // MARK: Views

    /// A thin rule on paper.
    struct Rule: View {
        var color: Color = Trace.Colors.ink.opacity(0.18)

        var body: some View {
            Rectangle().fill(color).frame(height: 1).accessibilityHidden(true)
        }
    }

    /// The letterhead's double rule.
    struct DoubleRule: View {
        var body: some View {
            VStack(spacing: 2) {
                Rectangle().fill(Trace.Colors.ink).frame(height: 1.5)
                Rectangle().fill(Trace.Colors.ink).frame(height: 0.75)
            }
            .accessibilityHidden(true)
        }
    }

    /// BEN / BUREAU DES ENQUÊTES NUMÉRIQUES, the seal, the double rule.
    struct Letterhead: View {
        var body: some View {
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .center, spacing: 12) {
                    StampImage(asset: "seal_ben_bleu", label: L10n.t("assignment.bureau"), width: 40, onPaper: true,
                               angle: 0, color: Trace.Colors.benBlue)
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 3) {
                        StoryLabel(text: L10n.t("story.paper.ben"), color: Trace.Colors.ink)
                        StoryLabel(text: L10n.t("assignment.bureau"), color: Trace.Colors.inkSoft)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer(minLength: 0)
                }
                DoubleRule()
            }
            .accessibilityElement(children: .combine)
        }
    }

    /// Lacaze's visa: his signature (blue ink PNG) and his name, printed.
    struct Visa: View {
        var body: some View {
            VStack(alignment: .leading, spacing: 2) {
                StoryLabel(text: L10n.t("story.profile.visa"), color: Trace.Colors.inkSoft)
                if let image = ArtLibrary.image("signature_lacaze_bleu") {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 130)
                        .blendMode(.multiply)
                        .accessibilityHidden(true)
                }
                Text(L10n.t("assignment.signatory"))
                    .font(Trace.Fonts.monoSmall)
                    .foregroundStyle(Trace.Colors.inkSoft)
            }
            .accessibilityElement(children: .combine)
        }
    }

    /// « ‹ » 44 × 44 at the leading edge.
    struct TopBar: View {
        let backID: String
        let onBack: () -> Void

        var body: some View {
            HStack(spacing: 0) {
                BackChevron(action: onBack)
                    .accessibilityIdentifier(backID)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 12)
            .frame(minHeight: 44)
        }
    }

    /// The bottom of a screen: the one full button at safeArea.bottom + 10 (and its link).
    struct Footer<Content: View>: View {
        @ViewBuilder let content: Content

        var body: some View {
            VStack(spacing: 2) { content }
                .padding(.horizontal, 24)
                .padding(.top, 12)
                .padding(.bottom, 10)
                .frame(maxWidth: .infinity)
                .background(Trace.Story.sceneVoid.ignoresSafeArea(edges: .bottom))
        }
    }

    /// A screen of the story on the desk: the top bar, the scrolling content, the footer.
    struct Page<Content: View, Bottom: View>: View {
        let backID: String
        let onBack: () -> Void
        @ViewBuilder let content: Content
        @ViewBuilder let bottom: Bottom

        var body: some View {
            VStack(spacing: 0) {
                TopBar(backID: backID, onBack: onBack)
                ScrollView {
                    content
                        .padding(.horizontal, 16)
                        .padding(.top, 8)
                        .padding(.bottom, 24)
                }
                .scrollBounceBehavior(.basedOnSize)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .safeAreaInset(edge: .bottom, spacing: 0) { bottom }
        }
    }

    /// The stamp micro-interaction (TRANSITIONS §3): scale 1.35 → 1 and blur 2 → 0 in 180 ms, a
    /// 60 ms settle, the dry sound and a rigid haptic. With reduced motion, a 200 ms fade.
    struct StampDrop<Content: View>: View {
        var delay: Double = 0.3
        @ViewBuilder let content: Content
        @State private var phase = 0
        @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
        @AppStorage(Preferences.reduceMotionKey) private var appReduceMotion = false

        var body: some View {
            let still = systemReduceMotion || appReduceMotion
            content
                .scaleEffect(still ? 1 : (phase == 0 ? 1.35 : phase == 1 ? 0.98 : 1))
                .blur(radius: still || phase > 0 ? 0 : 2)
                .opacity(phase > 0 ? 1 : 0)
                .task {
                    try? await Task.sleep(for: .seconds(delay))
                    if still {
                        withAnimation(.easeOut(duration: 0.2)) { phase = 2 }
                    } else {
                        withAnimation(.easeIn(duration: 0.18)) { phase = 1 }
                        try? await Task.sleep(for: .milliseconds(180))
                        withAnimation(.easeOut(duration: 0.06)) { phase = 2 }
                    }
                    AudioDirector.shared.play(.stamp, volume: 0.8)
                    Haptics.rigid()
                }
        }
    }

    /// A value of a settings menu (h19).
    struct Choice<Value: Hashable>: Identifiable {
        let value: Value
        let label: String
        var id: Value { value }
    }

    /// « Réduire les mouvements de caméra »: the system's setting, or the player's.
    enum CameraMotion: Hashable {
        case system, reduced, full

        init(_ value: Bool?) {
            if let value {
                self = value ? .reduced : .full
            } else {
                self = .system
            }
        }

        var value: Bool? {
            switch self {
            case .system: nil
            case .reduced: true
            case .full: false
            }
        }
    }

    /// The BEN card of the reward (h18), a flat stand-in for the 3D object: the story's card
    /// material (the 160° gradient), the print, the name, the rank, the service number.
    struct BENCard: View {
        let name: String
        let rank: String
        let serviceNumber: String
        let portrait: UIImage?
        let initials: String

        var body: some View {
            let shape = RoundedRectangle(cornerRadius: 12, style: .continuous)
            VStack(spacing: 10) {
                Capsule()
                    .strokeBorder(Trace.Story.inkSecondary.opacity(0.7), lineWidth: 1.5)
                    .frame(width: 34, height: 8)
                    .padding(.top, 12)
                VStack(spacing: 3) {
                    Text(L10n.t("story.paper.ben"))
                        .font(Trace.StoryFonts.label)
                        .tracking(3)
                        .foregroundStyle(Trace.Story.ink)
                    Text(L10n.t("assignment.bureau").uppercased())
                        .font(Trace.StoryFonts.label)
                        .tracking(0.8)
                        .foregroundStyle(Trace.Story.inkSecondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .minimumScaleFactor(0.7)
                }
                PortraitOrInitials(image: portrait, initials: initials, width: 78, height: 98)
                    .overlay(Rectangle().strokeBorder(Trace.Story.ink.opacity(0.25), lineWidth: 1))
                VStack(spacing: 3) {
                    Text(name)
                        .font(Trace.StoryFonts.h3)
                        .foregroundStyle(Trace.Story.ink)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .minimumScaleFactor(0.5)
                    Text(rank.uppercased())
                        .font(Trace.StoryFonts.technical)
                        .foregroundStyle(Trace.Story.inkSecondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    Text(serviceNumber)
                        .font(Trace.StoryFonts.technical)
                        .foregroundStyle(Trace.Story.ink)
                }
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 12)
            .frame(width: 168, height: 262)
            .background(shape.fill(LinearGradient(colors: [Trace.Story.folderLight, Trace.Story.folder],
                                                  startPoint: UnitPoint(x: 0.36, y: 0), endPoint: UnitPoint(x: 0.64, y: 1))))
            .overlay(shape.strokeBorder(Trace.Story.ink.opacity(0.12), lineWidth: 1))
        }
    }

    /// Any other object of the reward: a paper tag with its name.
    struct ObjectTag: View {
        let name: String

        var body: some View {
            VStack(spacing: 14) {
                Circle()
                    .strokeBorder(Trace.Colors.inkSoft, lineWidth: 1.5)
                    .frame(width: 14, height: 14)
                StoryLabel(text: L10n.t("story.paper.ben"), color: Trace.Colors.inkSoft)
                Text(name)
                    .font(Trace.StoryFonts.h3)
                    .foregroundStyle(Trace.Colors.ink)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                    .minimumScaleFactor(0.6)
                Rule()
                Spacer(minLength: 0)
            }
            .padding(18)
            .frame(width: 180, height: 230)
            .paper(Trace.Colors.label, radius: 4)
        }
    }

    /// h18's object, entering like a card (+20 pt, 4° → 0°, 420 ms), with its shadow on the desk.
    struct RewardObject: View {
        let item: RewardItem
        let name: String
        let player: StoryPlayer?
        let rank: String
        let portrait: UIImage?
        @State private var shown = false
        @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
        @AppStorage(Preferences.reduceMotionKey) private var appReduceMotion = false

        /// The BEN card is drawn as a card; any other object as a tag.
        private var isCard: Bool {
            item.id == "office_card" || item.name.lowercased().contains("carte ben") || item.name.lowercased().contains("ben card")
        }

        var body: some View {
            let still = systemReduceMotion || appReduceMotion
            ZStack {
                Ellipse()
                    .fill(Trace.Story.sceneVoid.opacity(0.85))
                    .frame(width: 150, height: 18)
                    .blur(radius: 10)
                    .frame(maxHeight: .infinity, alignment: .bottom)
                    .opacity(shown ? 1 : 0)
                object
                    .rotation3DEffect(.degrees(-10), axis: (x: 0, y: 1, z: 0), perspective: 0.6)
                    .shadow(color: .black.opacity(0.7), radius: 30, y: 30)
                    .rotationEffect(.degrees(shown || still ? 0 : 4))
                    .offset(y: shown || still ? 0 : 20)
                    .opacity(shown ? 1 : 0)
            }
            .frame(width: 220, height: 270)
            .onAppear {
                withAnimation(still ? .easeOut(duration: 0.2) : .easeOut(duration: 0.42)) { shown = true }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text(name))
            .accessibilityAddTraits(.isImage)
        }

        @ViewBuilder
        private var object: some View {
            if isCard {
                BENCard(name: StoryPaper.fullName(player), rank: rank, serviceNumber: player?.serviceNumber ?? "",
                        portrait: portrait, initials: StoryPaper.initials(player))
            } else {
                ObjectTag(name: name)
            }
        }
    }

    /// The promotion note of a rank already reached (h08, tap on a passed step).
    struct PromotionNote: View {
        let title: String
        let date: String?
        let first: Bool
        let onClose: () -> Void

        var body: some View {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    Letterhead()
                    StoryLabel(text: L10n.t("story.career.note.title"), color: Trace.Colors.inkSoft)
                        .accessibilityAddTraits(.isHeader)
                    Text(title)
                        .font(Trace.StoryFonts.h2)
                        .foregroundStyle(Trace.Colors.ink)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(first ? L10n.t("story.career.note.first") : L10n.t("story.career.note.body"))
                        .font(Trace.StoryFonts.body)
                        .foregroundStyle(Trace.Colors.inkMid)
                        .lineSpacing(4)
                        .fixedSize(horizontal: false, vertical: true)
                    if let date {
                        Text(L10n.f("story.career.note.date", date))
                            .font(Trace.StoryFonts.technical)
                            .foregroundStyle(Trace.Colors.inkSoft)
                    }
                    Visa()
                    Button(L10n.t("a11y.close"), action: onClose)
                        .buttonStyle(TextLinkStyle(onPaper: true))
                        .frame(maxWidth: .infinity)
                        .accessibilityIdentifier("story.career.note.close")
                }
                .padding(20)
            }
            .scrollBounceBehavior(.basedOnSize)
            .background(Trace.Colors.paper.overlay(PaperGrain()).ignoresSafeArea())
            .accessibilityIdentifier("story.career.note")
        }
    }

    /// h19 « Rejouer un chapitre »: the chapters already finished.
    struct ReplaySheet: View {
        let chapters: [StoryChapter]
        let onChoose: (String) -> Void
        let onClose: () -> Void

        var body: some View {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    Text(L10n.t("story.settings.replay"))
                        .font(Trace.StoryFonts.h2)
                        .foregroundStyle(Trace.Colors.ink)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityAddTraits(.isHeader)
                    Text(L10n.t("story.settings.replayNote"))
                        .font(Trace.StoryFonts.body)
                        .foregroundStyle(Trace.Colors.inkMid)
                        .fixedSize(horizontal: false, vertical: true)
                    if chapters.isEmpty {
                        Text(L10n.t("story.settings.replayEmpty"))
                            .font(Trace.StoryFonts.body)
                            .foregroundStyle(Trace.Colors.inkSoft)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.vertical, 8)
                    } else {
                        VStack(spacing: 0) {
                            Rule()
                            ForEach(chapters) { chapter in
                                Button { onChoose(chapter.id) } label: {
                                    HStack(alignment: .firstTextBaseline, spacing: 12) {
                                        StoryLabel(text: L10n.f("story.chapter.tab", StoryPaper.twoDigits(chapter.number)),
                                                   color: Trace.Colors.inkSoft)
                                        Text(StoryPaper.title(chapter.title))
                                            .font(Trace.StoryFonts.body)
                                            .foregroundStyle(Trace.Colors.ink)
                                            .multilineTextAlignment(.leading)
                                            .fixedSize(horizontal: false, vertical: true)
                                        Spacer(minLength: 8)
                                        Image(systemName: "chevron.right")
                                            .font(Trace.StoryFonts.caption)
                                            .foregroundStyle(Trace.Colors.inkSoft)
                                            .accessibilityHidden(true)
                                    }
                                    .padding(.vertical, 8)
                                    .frame(minHeight: 48)
                                    .overlay(alignment: .bottom) { Rule(color: Trace.Colors.ruled.opacity(2)) }
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(PressableStyle())
                                .accessibilityIdentifier("story.settings.replay.\(chapter.id)")
                            }
                        }
                    }
                    Button(L10n.t("a11y.close"), action: onClose)
                        .buttonStyle(TextLinkStyle(onPaper: true))
                        .frame(maxWidth: .infinity)
                        .accessibilityIdentifier("story.settings.replay.close")
                }
                .padding(20)
            }
            .scrollBounceBehavior(.basedOnSize)
            .background(Trace.Colors.paper.overlay(PaperGrain()).ignoresSafeArea())
        }
    }

    /// h19 « Réinitialiser l'histoire »: the one hold of the settings (1.6 s, red).
    struct ResetSheet: View {
        let onConfirm: () -> Void
        let onCancel: () -> Void

        var body: some View {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    Text(L10n.t("story.settings.resetTitle"))
                        .font(Trace.StoryFonts.h2)
                        .foregroundStyle(Trace.Colors.ink)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityAddTraits(.isHeader)
                    Text(L10n.t("story.settings.resetMessage"))
                        .font(Trace.StoryFonts.body)
                        .foregroundStyle(Trace.Colors.inkMid)
                        .lineSpacing(4)
                        .fixedSize(horizontal: false, vertical: true)
                    StoryHoldButton(title: L10n.t("story.settings.resetHold"), seconds: 1.6, destructive: true, onPaper: true) {
                        onConfirm()
                    }
                    .accessibilityIdentifier("story.settings.reset.hold")
                    .padding(.top, 8)
                    Button(L10n.t("story.settings.cancel"), action: onCancel)
                        .buttonStyle(TextLinkStyle(onPaper: true))
                        .frame(maxWidth: .infinity)
                        .accessibilityIdentifier("story.settings.reset.cancel")
                }
                .padding(20)
            }
            .scrollBounceBehavior(.basedOnSize)
            .background(Trace.Colors.paper.overlay(PaperGrain()).ignoresSafeArea())
        }
    }
}

// MARK: - h07 · Profil enquêteur

/// The investigator's file: letterhead, print 112 × 142, name, rank and service number, the
/// three numbers (cases handled · solved · seniority), the last three lines of the history,
/// Lacaze's visa and « Voir en 3D ». Never a relationship score.
struct StoryProfileView: View {
    let story: StoryCoordinator
    let onBack: () -> Void
    let onView3D: () -> Void

    @Environment(\.dynamicTypeSize) private var typeSize

    private static let printWidth: CGFloat = 112
    private static let printHeight: CGFloat = 142
    private static let historyLength = 3

    var body: some View {
        StoryPaper.Page(backID: "story.profile.back", onBack: onBack) {
            sheet
        } bottom: {
            EmptyView()
        }
        .background(ModeBackdrop(colors: Trace.Story.deskStory))
    }

    private var sheet: some View {
        VStack(alignment: .leading, spacing: 20) {
            StoryPaper.Letterhead()
                .accessibilityAddTraits(.isHeader)
            identity
            StoryPaper.Rule()
            numbers
            StoryPaper.Rule()
            history
            visa
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .paper(Trace.Colors.paper, radius: 0, lifted: true)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("story.profile.sheet")
    }

    /// Print beside the name; stacked at accessibility sizes.
    private var stacked: Bool { typeSize.isAccessibilitySize }

    private var identity: some View {
        let player = story.player
        let rank = story.save?.rank ?? .enqueteur
        let name = StoryPaper.fullName(player)
        let title = story.rankTitle().uppercased()
        let layout = stacked
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 14))
            : AnyLayout(HStackLayout(alignment: .top, spacing: 16))
        return layout {
            PortraitOrInitials(image: story.portrait, initials: StoryPaper.initials(player),
                               width: Self.printWidth, height: Self.printHeight)
                .padding(5)
                .background(Trace.Colors.printWhite)
                .shadow(color: .black.opacity(0.25), radius: 5, y: 4)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(Text(L10n.f("story.profile.a11y.print", name)))
                .accessibilityAddTraits(.isImage)
            VStack(alignment: .leading, spacing: 6) {
                Text(name)
                    .font(Trace.StoryFonts.h2)
                    .foregroundStyle(Trace.Colors.ink)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityAddTraits(.isHeader)
                Text(title)
                    .font(Trace.StoryFonts.technical)
                    .tracking(0.3)
                    .foregroundStyle(Trace.Colors.inkMid)
                    .fixedSize(horizontal: false, vertical: true)
                if let number = player?.serviceNumber {
                    Text(L10n.f("story.profile.serviceNumber", number))
                        .font(Trace.StoryFonts.technical)
                        .tracking(0.3)
                        .foregroundStyle(Trace.Colors.inkSoft)
                }
                StampImage(asset: StoryPaper.stampAsset(rank), label: title, width: 104, onPaper: true, angle: -8)
                    .padding(.top, 6)
            }
        }
    }

    /// AFFAIRES TRAITÉES · RÉSOLUES · ANCIENNETÉ (« 0 · 0 · — » at first).
    private var numbers: some View {
        let layout = stacked
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 12))
            : AnyLayout(HStackLayout(alignment: .top, spacing: 10))
        return layout {
            number(L10n.t("story.profile.handled"), "\(handled)")
            number(L10n.t("story.profile.solved"), "\(story.solvedCount)")
            number(L10n.t("story.profile.seniority"), story.seniority)
        }
    }

    private func number(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            StoryLabel(text: label, color: Trace.Colors.inkSoft)
                .fixedSize(horizontal: false, vertical: true)
            Text(value)
                .font(Trace.StoryFonts.number)
                .monospacedDigit()
                .foregroundStyle(Trace.Colors.ink)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    /// Cases handled, all modes: the story's (solved or not, ALIBI checks included) plus those
    /// solved elsewhere — never fewer than the cases solved.
    private var handled: Int {
        guard let save = story.save else { return story.solvedCount }
        let solvedHere = Set(save.cases.values.filter { $0.solved && $0.alibi != true }.map(\.caseID))
        return save.cases.count + max(0, story.solvedCount - solvedHere.count)
    }

    /// The last three lines, newest first; « Première affectation » when there is none.
    private var history: some View {
        let entries = Array((story.save?.history ?? []).suffix(Self.historyLength).reversed())
        let created: String? = story.save?.createdAt
        let createdShown = created.map { StoryCoordinator.shownDay($0) }
        return VStack(alignment: .leading, spacing: 0) {
            StoryLabel(text: L10n.t("story.profile.history"), color: Trace.Colors.inkSoft)
                .padding(.bottom, 4)
                .accessibilityAddTraits(.isHeader)
            if entries.isEmpty {
                historyLine(date: createdShown, text: L10n.t("story.profile.firstAssignment"))
            } else {
                ForEach(Array(entries.enumerated()), id: \.offset) { _, entry in
                    historyLine(date: StoryCoordinator.shownDay(entry.date), text: entry.text)
                }
            }
        }
    }

    private func historyLine(date: String?, text: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Text(date ?? "—")
                .font(Trace.StoryFonts.technical)
                .foregroundStyle(Trace.Colors.inkSoft)
                .frame(minWidth: 92, alignment: .leading)
            Text(text)
                .font(Trace.StoryFonts.body)
                .foregroundStyle(Trace.Colors.ink)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .padding(.vertical, 9)
        .overlay(alignment: .bottom) { StoryPaper.Rule(color: Trace.Colors.ruled.opacity(2)) }
        .accessibilityElement(children: .combine)
    }

    /// Lacaze's visa, and the link to the 3D viewer (h06, read-only).
    private var visa: some View {
        let layout = stacked
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 10))
            : AnyLayout(HStackLayout(alignment: .bottom, spacing: 12))
        return layout {
            StoryPaper.Visa()
            if !stacked { Spacer(minLength: 8) }
            Button(L10n.t("story.profile.view3d"), action: onView3D)
                .buttonStyle(TextLinkStyle(onPaper: true))
                .accessibilityIdentifier("story.profile.view3d")
        }
        .padding(.top, 4)
    }
}

// MARK: - h08 · Carrière

/// The career as a vertical timeline on paper: one step per rank — passed (filled ink dot, solid
/// line, the date), current (red ring and halo, dotted line on, « ACTUEL » and a counter), future
/// (empty ring, dotted, 45 %, its condition). No gauge, no percentage. A passed step opens its
/// promotion note.
struct StoryCareerView: View {
    let story: StoryCoordinator
    let onBack: () -> Void

    @State private var note: CareerNote?

    private enum StepState { case passed, current, future }

    private struct CareerNote: Identifiable {
        let id: StoryRank
        let title: String
        let date: String?
    }

    private static let dotSize: CGFloat = 14
    private static let markerWidth: CGFloat = 26

    var body: some View {
        StoryPaper.Page(backID: "story.career.back", onBack: onBack) {
            VStack(alignment: .leading, spacing: 14) {
                Text(L10n.t("story.career.title"))
                    .font(Trace.StoryFonts.h1)
                    .foregroundStyle(Trace.Colors.bone)
                    .accessibilityAddTraits(.isHeader)
                Text(L10n.t("story.career.intro"))
                    .font(Trace.StoryFonts.caption)
                    .foregroundStyle(Trace.Colors.bone2)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.bottom, 6)
                timeline
            }
        } bottom: {
            EmptyView()
        }
        .background(ModeBackdrop(colors: Trace.Story.deskStory))
        .sheet(item: $note) { item in
            StoryPaper.PromotionNote(title: item.title, date: item.date, first: item.id == tiers.first?.rank,
                                     onClose: { note = nil })
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(16)
                .presentationBackground(Trace.Colors.paper)
        }
    }

    private var tiers: [CareerTier] {
        (story.content?.campaign.career ?? []).sorted { $0.rank < $1.rank }
    }

    private var timeline: some View {
        let tiers = self.tiers
        let rank = story.save?.rank ?? .enqueteur
        return VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(tiers.enumerated()), id: \.offset) { index, tier in
                row(tier, state: state(of: tier.rank, current: rank), last: index == tiers.count - 1)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .paper(Trace.Colors.paper, radius: 0, lifted: true)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("story.career.sheet")
    }

    private func state(of rank: StoryRank, current: StoryRank) -> StepState {
        if rank < current { return .passed }
        return rank == current ? .current : .future
    }

    @ViewBuilder
    private func row(_ tier: CareerTier, state: StepState, last: Bool) -> some View {
        if state == .passed {
            Button {
                note = CareerNote(id: tier.rank, title: story.rankTitle(tier.rank), date: date(of: tier.rank))
            } label: {
                rowContent(tier, state: state, last: last)
            }
            .buttonStyle(PressableStyle())
            .accessibilityHint(Text(L10n.t("story.career.a11y.openNote")))
            .accessibilityIdentifier("story.career.rank.\(tier.rank.rawValue)")
        } else {
            rowContent(tier, state: state, last: last)
                .accessibilityIdentifier("story.career.rank.\(tier.rank.rawValue)")
        }
    }

    private func rowContent(_ tier: CareerTier, state: StepState, last: Bool) -> some View {
        let title = story.rankTitle(tier.rank)
        let step = stepLine(tier.rank)
        let meta = self.meta(tier, state: state)
        return VStack(alignment: .leading, spacing: 4) {
            Text(title.uppercased())
                .font(Trace.StoryFonts.careerRank)
                .tracking(1.9)
                .foregroundStyle(Trace.Colors.ink)
                .fixedSize(horizontal: false, vertical: true)
            Text(step)
                .font(Trace.Fonts.prose)
                .foregroundStyle(Trace.Colors.ink)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
            Text(meta)
                .font(Trace.StoryFonts.technical)
                .tracking(0.3)
                .textCase(.uppercase)
                .foregroundStyle(state == .current ? Trace.Colors.stamp : Trace.Colors.inkSoft)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.leading, Self.markerWidth + 12)
        .padding(.bottom, last ? 0 : 26)
        .overlay(alignment: .topLeading) { marker(state: state, last: last) }
        .opacity(state == .future ? 0.45 : 1)
        .contentShape(Rectangle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text([title, stateName(state), step, meta].joined(separator: ", ")))
    }

    /// The dot (14 pt) and the line to the next step: solid once passed, dotted after.
    private func marker(state: StepState, last: Bool) -> some View {
        VStack(spacing: 0) {
            ZStack {
                switch state {
                case .passed:
                    Circle().fill(Trace.Colors.ink).frame(width: Self.dotSize, height: Self.dotSize)
                case .current:
                    Circle().fill(Trace.Colors.stamp.opacity(0.18)).frame(width: Self.markerWidth, height: Self.markerWidth)
                    Circle().strokeBorder(Trace.Colors.stamp, lineWidth: 2).frame(width: Self.dotSize, height: Self.dotSize)
                case .future:
                    Circle().strokeBorder(Trace.Colors.ink, lineWidth: 1.5).frame(width: Self.dotSize, height: Self.dotSize)
                }
            }
            .frame(width: Self.markerWidth, height: Self.markerWidth)
            if !last {
                Line()
                    .stroke(Trace.Colors.ink,
                            style: StrokeStyle(lineWidth: 1.5, lineCap: .round, dash: state == .passed ? [] : [0.5, 4.5]))
                    .frame(width: 2)
                    .frame(maxHeight: .infinity)
            }
        }
        .frame(width: Self.markerWidth)
        // The dot sits on the rank's line.
        .padding(.top, -5)
        .accessibilityHidden(true)
    }

    private func stateName(_ state: StepState) -> String {
        switch state {
        case .passed: L10n.t("story.career.a11y.passed")
        case .current: L10n.t("story.career.a11y.current")
        case .future: L10n.t("story.career.a11y.future")
        }
    }

    /// What the rank brings (CHARACTER_CUSTOMIZATION §6), in one line.
    private func stepLine(_ rank: StoryRank) -> String {
        switch rank {
        case .enqueteur: L10n.t("story.career.step.enqueteur")
        case .inspecteur: L10n.t("story.career.step.inspecteur")
        case .senior: L10n.t("story.career.step.senior")
        case .experimente: L10n.t("story.career.step.experimente")
        }
    }

    private func meta(_ tier: CareerTier, state: StepState) -> String {
        switch state {
        case .passed:
            return date(of: tier.rank) ?? L10n.t("story.career.reached")
        case .current:
            guard let next = story.content?.campaign.tier(after: tier.rank) else { return L10n.t("story.career.current") }
            let counter = L10n.f("story.career.counter", min(story.solvedCount, next.cases), next.cases)
            return L10n.t("story.career.current") + " · " + counter
        case .future:
            return L10n.f("story.career.condition", condition(tier))
        }
    }

    /// « 20 affaires résolues · chapitre 04 » (both are needed).
    private func condition(_ tier: CareerTier) -> String {
        let cases = L10n.f("story.career.cases", tier.cases)
        guard let chapter = tier.chapter else { return cases }
        return cases + " · " + L10n.f("story.career.chapter", StoryPaper.twoDigits(chapter))
    }

    /// The day a rank was reached: the creation for the first one, the history's promotion line
    /// for the others (in any grammatical form: the agreement may have changed since).
    private func date(of rank: StoryRank) -> String? {
        guard let save = story.save else { return nil }
        if rank == (tiers.first?.rank ?? .enqueteur) {
            return save.createdAt.map { StoryCoordinator.shownDay($0) }
        }
        let forms: [StoryText.GrammaticalForm] = [.feminine, .masculine, .neutral]
        let lines = Set(forms.map { L10n.f("story.history.promotion", StoryText.rankTitle(rank, form: $0)) })
        return save.history.last(where: { lines.contains($0.text) }).map { StoryCoordinator.shownDay($0.date) }
    }
}

// MARK: - h10 · Chapitre

/// A chapter's folder (story.folder, a sheet inside, margin 14): tab « CHAPITRE 0N », title, the
/// synopsis, the steps (✓ done · ● current · ○ to come, 45 %, « ··· » for a surprise), and one
/// button: « CONTINUER · SCÈNE n » (current), « CHAPITRE SUIVANT » (finished, RÉSOLU on the
/// folder), none for a chapter not written yet (« Bientôt disponible »).
struct StoryChapterView: View {
    let story: StoryCoordinator
    let chapterID: String
    let onBack: () -> Void
    let onContinue: () -> Void

    @State private var continuing = false

    private enum Phase { case finished, current, available, locked, planned }
    private enum StepState { case done, current, future }

    private var chapter: StoryChapter? { story.content?.campaign.chapter(chapterID) }

    var body: some View {
        let chapter = self.chapter
        StoryPaper.Page(backID: "story.chapter.back", onBack: onBack) {
            if let chapter {
                folder(chapter, phase: phase(of: chapter))
                    .padding(.top, 12)
            } else {
                Text(L10n.t("story.chapter.soon"))
                    .font(Trace.StoryFonts.body)
                    .foregroundStyle(Trace.Colors.bone2)
                    .padding(.top, 24)
            }
        } bottom: {
            if let chapter {
                footer(chapter, phase: phase(of: chapter))
            }
        }
        .background(ModeBackdrop(colors: Trace.Story.deskStory))
    }

    // MARK: State

    private func phase(of chapter: StoryChapter) -> Phase {
        if chapter.status == .planned { return .planned }
        guard let save = story.save else { return .locked }
        let here = save.replay == nil && save.position.chapterID == chapter.id
        let inProgress = here && save.position.stepIndex < chapter.steps.count
        if inProgress { return .current }
        if save.completedChapters.contains(chapter.id) { return .finished }
        if story.currentChapter?.id == chapter.id && save.unlocks.contains(chapter.id) { return .available }
        return .locked
    }

    private func stepState(_ index: Int, phase: Phase) -> StepState {
        switch phase {
        case .finished:
            return .done
        case .current:
            let current = story.save?.position.stepIndex ?? 0
            if index < current { return .done }
            return index == current ? .current : .future
        case .available:
            return index == 0 ? .current : .future
        case .locked, .planned:
            return .future
        }
    }

    /// Every case of the chapter solved (else the folder is stamped CLASSÉ).
    private func solved(_ chapter: StoryChapter) -> Bool {
        guard let save = story.save else { return false }
        let ids = chapter.steps.compactMap { $0.kind == .investigation ? $0.caseID : nil }
        return ids.compactMap { save.cases[$0] }.allSatisfy(\.solved)
    }

    // MARK: Folder

    private func folder(_ chapter: StoryChapter, phase: Phase) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(L10n.f("story.chapter.tab", StoryPaper.twoDigits(chapter.number)))
                .font(Trace.StoryFonts.label)
                .tracking(1.6)
                .textCase(.uppercase)
                .foregroundStyle(Trace.Story.ink)
                .padding(.horizontal, 14)
                .frame(minHeight: 30)
                .background(UnevenRoundedRectangle(topLeadingRadius: 8, topTrailingRadius: 8).fill(Trace.Story.folder))
                .accessibilityAddTraits(.isHeader)
            folderSheet(chapter, phase: phase)
                .padding(14)
                .frame(maxWidth: .infinity)
                .background(
                    UnevenRoundedRectangle(topLeadingRadius: 0, bottomLeadingRadius: 8, bottomTrailingRadius: 8, topTrailingRadius: 8)
                        .fill(Trace.Story.folder)
                )
        }
        .shadow(color: .black.opacity(0.6), radius: 24, y: 22)
        .opacity(phase == .planned || phase == .locked ? 0.5 : 1)
    }

    private func folderSheet(_ chapter: StoryChapter, phase: Phase) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(StoryPaper.title(chapter.title))
                .font(Trace.StoryFonts.h2)
                .foregroundStyle(Trace.Colors.ink)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.trailing, phase == .finished ? 88 : 0)
                .accessibilityAddTraits(.isHeader)
            Text(story.resolve(chapter.synopsis))
                .font(Trace.StoryFonts.body)
                .foregroundStyle(Trace.Colors.inkMid)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
            switch phase {
            case .planned:
                StoryLabel(text: L10n.t("story.chapter.soon"), color: Trace.Colors.inkSoft)
                    .padding(.top, 4)
            case .locked:
                StoryLabel(text: lockedLine(chapter), color: Trace.Colors.inkSoft)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 4)
            case .finished, .current, .available:
                steps(chapter, phase: phase)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .paper(Trace.Colors.paper, radius: 0)
        .overlay(alignment: .topTrailing) {
            if phase == .finished {
                stamp(chapter)
                    .padding(.top, 10)
                    .padding(.trailing, 8)
            }
        }
    }

    @ViewBuilder
    private func stamp(_ chapter: StoryChapter) -> some View {
        if solved(chapter) {
            StampImage(asset: "stamp_resolu_rouge_marque", label: L10n.t("stamp.solved"), width: 92, onPaper: true, angle: -10)
        } else {
            StateStamp(text: L10n.t("story.paper.stampFiled"), color: Trace.Story.greyStamp)
                .padding(.top, 10)
        }
    }

    /// « Disponible après le chapitre 01 ».
    private func lockedLine(_ chapter: StoryChapter) -> String {
        L10n.f("story.chapter.locked", StoryPaper.twoDigits(max(1, chapter.number - 1)))
    }

    private func steps(_ chapter: StoryChapter, phase: Phase) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            StoryPaper.Rule()
            ForEach(Array(chapter.steps.enumerated()), id: \.offset) { index, step in
                stepRow(step, state: stepState(index, phase: phase))
            }
        }
        .padding(.top, 4)
    }

    private func stepRow(_ step: ChapterStep, state: StepState) -> some View {
        let hidden = state == .future && step.surprise == true
        let type = typeName(step)
        let title = hidden ? "···" : story.resolve(step.title ?? type)
        let glyph: String
        switch state {
        case .done: glyph = "✓"
        case .current: glyph = "●"
        case .future: glyph = "○"
        }
        let spoken = hidden ? L10n.t("story.chapter.a11y.hidden") : title
        return HStack(alignment: .center, spacing: 12) {
            Text(verbatim: glyph)
                .font(Trace.Fonts.monoStrong)
                .foregroundStyle(state == .current ? Trace.Colors.stamp : Trace.Colors.ink)
                .frame(width: 16)
            Text(title)
                .font(Trace.StoryFonts.body)
                .foregroundStyle(Trace.Colors.ink)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 8)
            StoryLabel(text: type, color: Trace.Colors.inkSoft)
        }
        .padding(.vertical, 6)
        .frame(minHeight: 44)
        .overlay(alignment: .bottom) { StoryPaper.Rule(color: Trace.Colors.ruled.opacity(2)) }
        .opacity(state == .future ? 0.45 : 1)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text([stepStateName(state), spoken, type].joined(separator: ", ")))
        .accessibilityIdentifier("story.chapter.step.\(step.id)")
    }

    private func stepStateName(_ state: StepState) -> String {
        switch state {
        case .done: L10n.t("story.chapter.a11y.done")
        case .current: L10n.t("story.chapter.a11y.current")
        case .future: L10n.t("story.chapter.a11y.future")
        }
    }

    /// SCÈNE · TÉLÉPHONE · ALIBI · RÉSULTAT · BUREAU.
    private func typeName(_ step: ChapterStep) -> String {
        switch step.kind {
        case .scene:
            return L10n.t("story.chapter.type.scene")
        case .investigation:
            let alibi = (step.caseID ?? "").hasPrefix("alibi")
            return alibi ? L10n.t("story.chapter.type.alibi") : L10n.t("story.chapter.type.phone")
        case .result:
            return L10n.t("story.chapter.type.result")
        case .office:
            return L10n.t("story.chapter.type.office")
        }
    }

    // MARK: Footer

    @ViewBuilder
    private func footer(_ chapter: StoryChapter, phase: Phase) -> some View {
        switch phase {
        case .current, .available:
            StoryPaper.Footer {
                Button(continueTitle(chapter, phase: phase)) { proceed() }
                    .buttonStyle(CTAButtonStyle())
                    .accessibilityIdentifier("story.chapter.continue")
            }
        case .finished:
            if opensNext(after: chapter) {
                StoryPaper.Footer {
                    Button(L10n.t("story.chapter.next")) { proceed() }
                        .buttonStyle(CTAButtonStyle())
                        .accessibilityIdentifier("story.chapter.next")
                }
            } else if nextIsPlanned(after: chapter) {
                StoryPaper.Footer {
                    Text(L10n.t("story.chapter.nextSoon"))
                        .font(Trace.StoryFonts.caption)
                        .foregroundStyle(Trace.Colors.bone2)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(minHeight: 44)
                }
            }
        case .locked, .planned:
            EmptyView()
        }
    }

    /// « CONTINUER · SCÈNE n » when the next step is a scene, else « CONTINUER ».
    private func continueTitle(_ chapter: StoryChapter, phase: Phase) -> String {
        let index = phase == .current ? (story.save?.position.stepIndex ?? 0) : 0
        guard index < chapter.steps.count, chapter.steps[index].kind == .scene else { return L10n.t("story.chapter.continue") }
        let number = chapter.steps.prefix(index + 1).filter { $0.kind == .scene }.count
        return L10n.f("story.chapter.continueScene", number)
    }

    /// The chapter after this one is the story's next (CONTINUER would open it).
    private func opensNext(after chapter: StoryChapter) -> Bool {
        guard !story.endOfContent, let next = story.content?.campaign.chapter(after: chapter.id),
              next.status == .playable else { return false }
        return story.currentChapter?.id == next.id
    }

    private func nextIsPlanned(after chapter: StoryChapter) -> Bool {
        guard let next = story.content?.campaign.chapter(after: chapter.id) else { return true }
        return next.status == .planned
    }

    /// Once: the screen changes right after.
    private func proceed() {
        guard !continuing else { return }
        continuing = true
        onContinue()
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(1))
            continuing = false
        }
    }
}

// MARK: - h15 · Nouveau dossier

/// The last image of the scene in 2D: the kraft folder on Lacaze's desk. Tab « N° C02-A »,
/// « CHAPITRE 0N · AFFAIRE A », the title, NOUVEAU, « AFFECTÉ À É. MOREL ». [OUVRIR LE DOSSIER]
/// rises in with a 500 ms fade.
struct StoryCaseFolderView: View {
    let story: StoryCoordinator
    let caseID: String
    let caseTitle: String
    let label: String
    let chapterNumber: Int
    let onOpen: () -> Void

    @State private var buttonShown = false
    @State private var opened = false
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    @AppStorage(Preferences.reduceMotionKey) private var appReduceMotion = false

    private var still: Bool { systemReduceMotion || appReduceMotion }

    var body: some View {
        StoryPaper.Page(backID: "story.caseFolder.back", onBack: { story.pauseToHub() }) {
            folder
                .padding(.top, 40)
        } bottom: {
            StoryPaper.Footer {
                Button(L10n.t("story.caseFolder.open")) { open() }
                    .buttonStyle(CTAButtonStyle())
                    .accessibilityIdentifier("story.caseFolder.open")
            }
            .opacity(buttonShown ? 1 : 0)
            .offset(y: buttonShown || still ? 0 : 16)
        }
        .background(ModeBackdrop(colors: Trace.Story.deskInvestigations))
        .task {
            try? await Task.sleep(for: .seconds(still ? 0.1 : 0.5))
            withAnimation(.easeOut(duration: still ? 0.2 : 0.5)) { buttonShown = true }
        }
    }

    private var folder: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(label.isEmpty ? "—" : label)
                .font(Trace.StoryFonts.label)
                .tracking(1.6)
                .textCase(.uppercase)
                .foregroundStyle(Trace.Story.kraftInk)
                .padding(.horizontal, 14)
                .frame(minHeight: 30)
                .background(UnevenRoundedRectangle(topLeadingRadius: 8, topTrailingRadius: 8).fill(Trace.Colors.kraft))
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .top, spacing: 12) {
                    StoryLabel(text: L10n.f("story.caseFolder.kicker", StoryPaper.twoDigits(chapterNumber), letter),
                               color: Trace.Colors.kraftLabel)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 8)
                    StoryPaper.StampDrop(delay: 0.35) {
                        StateStamp(text: L10n.t("story.paper.stampNew"))
                    }
                }
                Text(StoryPaper.title(caseTitle))
                    .font(Trace.StoryFonts.h2)
                    .foregroundStyle(Trace.Story.kraftInk)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityAddTraits(.isHeader)
                Spacer(minLength: 48)
                if let assigned {
                    Text(assigned)
                        .font(Trace.StoryFonts.technical)
                        .tracking(0.6)
                        .foregroundStyle(Trace.Colors.ink)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Trace.Colors.label)
                        .shadow(color: .black.opacity(0.2), radius: 1.5, y: 1)
                        .rotationEffect(.degrees(-1.5))
                }
            }
            .padding(22)
            .frame(maxWidth: .infinity, minHeight: 280, alignment: .topLeading)
            .kraft(radius: 8)
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("story.caseFolder")
    }

    /// « A », « B »…: the case's rank among the chapter's investigations.
    private var letter: String {
        let chapters = story.content?.campaign.chapters ?? []
        let chapter = chapters.first { $0.steps.contains { $0.caseID == caseID } }
            ?? chapters.first { $0.number == chapterNumber }
        let cases = (chapter?.steps ?? []).compactMap { $0.kind == .investigation ? $0.caseID : nil }
        return StoryPaper.letter(cases.firstIndex(of: caseID) ?? 0)
    }

    /// « AFFECTÉE À É. MOREL » (the player's agreement).
    private var assigned: String? {
        guard let player = story.player else { return nil }
        let name = StoryPaper.shortName(player)
        switch player.agreement {
        case .feminine: return L10n.f("story.caseFolder.assignedF", name)
        case .masculine: return L10n.f("story.caseFolder.assignedM", name)
        case .neutral: return L10n.f("story.caseFolder.assignedN", name)
        }
    }

    private func open() {
        guard !opened else { return }
        opened = true
        AudioDirector.shared.play(.folder, volume: 0.6)
        Haptics.light()
        onOpen()
    }
}

// MARK: - h16 → h17 → Avancement de service → h18

/// The end of a chapter, one sheet after the other (T-UI-5: a paper push of 40 pt, 380 ms):
/// the result (h16), the service record (h17 — when a rank was reached, « Avancement de
/// service » happens on it: the new rank stamp falls, one sentence), and the objects added to the
/// office (h18). A chapter is never blocking: CLASSÉ goes on too.
struct StoryResultFlow: View {
    let story: StoryCoordinator
    let result: StoryChapterResult
    let onDone: () -> Void
    let onOffice: (String?) -> Void

    private enum Page: Hashable { case summary, progress, reward(Int) }

    @State private var page: Page = .summary
    @State private var done = false
    @Environment(\.dynamicTypeSize) private var typeSize
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    @AppStorage(Preferences.reduceMotionKey) private var appReduceMotion = false

    /// ProgressBoxes: at most 30 boxes (the sentence gives the exact count).
    private static let maxBoxes = 30

    private var still: Bool { systemReduceMotion || appReduceMotion }
    private var chapter: StoryChapter? { story.content?.campaign.chapter(result.chapterID) }
    private var items: [RewardItem] { result.reward?.items ?? [] }
    private var chapterNumber: String { StoryPaper.twoDigits(chapter?.number ?? 0) }
    /// Labels on the CLASSÉ sheet (paper at 60 %) are in full ink, for contrast.
    private var labelInk: Color { result.solved ? Trace.Colors.inkSoft : Trace.Colors.ink }
    private var bodyInk: Color { result.solved ? Trace.Colors.inkMid : Trace.Colors.ink }

    private var pageTransition: AnyTransition {
        still ? .opacity : .asymmetric(insertion: .offset(x: 40).combined(with: .opacity),
                                       removal: .offset(x: -40).combined(with: .opacity))
    }

    var body: some View {
        ZStack {
            switch page {
            case .summary:
                summaryPage.transition(pageTransition)
            case .progress:
                progressPage.transition(pageTransition)
            case .reward(let index):
                rewardPage(index).id(index).transition(pageTransition)
            }
        }
        .background(ModeBackdrop(colors: Trace.Story.deskStory))
        .onAppear { AudioDirector.shared.play(.paper, volume: 0.4) }
    }

    // MARK: Navigation

    private func go(_ next: Page) {
        AudioDirector.shared.play(.paper, volume: 0.4)
        withAnimation(still ? .easeInOut(duration: 0.2) : .easeInOut(duration: 0.38)) { page = next }
    }

    /// Leaving h17: the promotion shown there is acknowledged, then the objects (or the chapter
    /// goes on).
    private func leaveProgress() {
        if result.promotion != nil {
            story.acknowledgePromotion()
        }
        if items.isEmpty {
            finish { onDone() }
        } else {
            go(.reward(0))
        }
    }

    /// Once only: the chapter goes on right after.
    private func finish(_ action: () -> Void) {
        guard !done else { return }
        done = true
        action()
    }

    // MARK: h16 · Résultat de chapitre

    private var summaryPage: some View {
        StoryPaper.Page(backID: "story.result.back", onBack: { story.pauseToHub() }) {
            summarySheet
        } bottom: {
            StoryPaper.Footer {
                Button(L10n.t("story.result.file")) { go(.progress) }
                    .buttonStyle(CTAButtonStyle())
                    .accessibilityIdentifier("story.result.file")
            }
        }
    }

    private var summarySheet: some View {
        let text = result.solved ? chapter?.summary : (chapter?.summaryUnsolved ?? chapter?.summary)
        let summary = story.resolve(text ?? "")
        return VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top, spacing: 12) {
                StoryLabel(text: L10n.f("story.result.kicker", chapterNumber), color: labelInk)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 8)
                Spacer(minLength: 8)
                if result.solved {
                    FallingStampImage(asset: "stamp_resolu_rouge_marque", label: L10n.t("stamp.solved"), width: 100,
                                      onPaper: true, angle: -8, success: true, delay: 0.35)
                } else {
                    StoryPaper.StampDrop(delay: 0.35) {
                        StateStamp(text: L10n.t("story.paper.stampFiled"), color: Trace.Story.greyStamp)
                    }
                    .padding(.top, 6)
                }
            }
            Text(StoryPaper.title(chapter?.title ?? ""))
                .font(Trace.StoryFonts.h2)
                .foregroundStyle(Trace.Colors.ink)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)
            if !summary.isEmpty {
                Text(summary)
                    .font(Trace.StoryFonts.body)
                    .foregroundStyle(bodyInk)
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
            }
            table
            decisions
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .paper(result.solved ? Trace.Colors.paper : Trace.Colors.paper.opacity(0.6), radius: 0, lifted: true)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("story.result.sheet")
    }

    /// AFFAIRES DU CHAPITRE · ALIBI · TEMPS TOTAL.
    private var table: some View {
        let cases = result.cases == 0 ? "—" : "\(result.casesSolved) / \(result.cases)"
        let alibis = result.alibis == 0 ? "—" : "\(result.alibis)"
        let layout = typeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 10))
            : AnyLayout(HStackLayout(alignment: .top, spacing: 8))
        return layout {
            column(L10n.t("story.result.cases"), cases)
            column(L10n.t("story.result.alibi"), alibis)
            column(L10n.t("story.result.time"), StoryPaper.duration(result.seconds))
        }
        .padding(.vertical, 12)
        .overlay(alignment: .top) { StoryPaper.Rule() }
        .overlay(alignment: .bottom) { StoryPaper.Rule() }
    }

    private func column(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            StoryLabel(text: label, color: labelInk)
                .fixedSize(horizontal: false, vertical: true)
            Text(value)
                .font(Trace.Fonts.fieldValueLarge)
                .monospacedDigit()
                .foregroundStyle(Trace.Colors.ink)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    /// VOS DÉCISIONS: one or two sentences from the remembered answers.
    private var decisions: some View {
        let lines = result.decisions.prefix(2).map { story.resolve($0) }
        return VStack(alignment: .leading, spacing: 8) {
            StoryLabel(text: L10n.t("story.result.decisions"), color: labelInk)
                .accessibilityAddTraits(.isHeader)
            if lines.isEmpty {
                Text(L10n.t("story.result.noDecision"))
                    .font(Trace.StoryFonts.body)
                    .foregroundStyle(bodyInk)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                ForEach(Array(lines.enumerated()), id: \.offset) { _, line in
                    Text(line)
                        .font(Trace.StoryFonts.body)
                        .foregroundStyle(Trace.Colors.ink)
                        .lineSpacing(4)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    // MARK: h17 · État de service

    private var progressPage: some View {
        StoryPaper.Page(backID: "story.progress.back", onBack: { go(.summary) }) {
            progressSheet
        } bottom: {
            StoryPaper.Footer {
                Button(L10n.t("story.progress.continue")) { leaveProgress() }
                    .buttonStyle(CTAButtonStyle())
                    .accessibilityIdentifier("story.progress.continue")
            }
        }
    }

    private var progressSheet: some View {
        let next = result.nextTier
        let note = chapter?.note.map { story.resolve($0) } ?? ""
        return VStack(alignment: .leading, spacing: 18) {
            StoryLabel(text: L10n.t("story.progress.title"), color: Trace.Colors.inkSoft)
                .accessibilityAddTraits(.isHeader)
            if let promotion = result.promotion {
                promotionBlock(promotion.to)
                StoryPaper.Rule()
            }
            ranks(next: next)
            if let next {
                let total = min(next.cases, Self.maxBoxes)
                ProgressBoxes(total: total, done: min(result.solvedCount, total))
                Text(progressLine(next))
                    .font(Trace.StoryFonts.body)
                    .foregroundStyle(Trace.Colors.inkMid)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                Text(L10n.t("story.progress.max"))
                    .font(Trace.StoryFonts.h3)
                    .foregroundStyle(Trace.Colors.ink)
                    .fixedSize(horizontal: false, vertical: true)
            }
            if !note.isEmpty {
                noteBlock(note)
            }
        }
        // ProgressBoxes lays 10 boxes of 26 pt per row (332 pt): a narrower margin keeps them on the sheet.
        .padding(.horizontal, 12)
        .padding(.vertical, 18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .paper(Trace.Colors.paper, radius: 0, lifted: true)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("story.progress.sheet")
    }

    /// RANG ACTUEL → RANG SUIVANT.
    private func ranks(next: CareerTier?) -> some View {
        let layout = typeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 8))
            : AnyLayout(HStackLayout(alignment: .top, spacing: 12))
        return layout {
            rankColumn(L10n.t("story.progress.currentRank"), story.rankTitle(result.rank))
            if let next {
                Text(verbatim: "→")
                    .font(Trace.StoryFonts.h3)
                    .foregroundStyle(Trace.Colors.inkSoft)
                    .padding(.top, 14)
                    .accessibilityHidden(true)
                rankColumn(L10n.t("story.progress.nextRank"), story.rankTitle(next.rank))
            }
        }
    }

    private func rankColumn(_ label: String, _ title: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            StoryLabel(text: label, color: Trace.Colors.inkSoft)
            Text(title)
                .font(Trace.StoryFonts.h3)
                .foregroundStyle(Trace.Colors.ink)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    /// « Affaires résolues : 1 sur 20. Il faut aussi terminer le chapitre 04. »
    private func progressLine(_ next: CareerTier) -> String {
        var line = L10n.f("story.progress.solved", result.solvedCount, next.cases)
        if let number = next.chapter, !finishedChapters.contains(number) {
            line += " " + L10n.f("story.progress.chapterNeeded", StoryPaper.twoDigits(number))
        }
        return line
    }

    private var finishedChapters: Set<Int> {
        guard let save = story.save, let content = story.content else { return [] }
        return save.finishedChapterNumbers(in: content.campaign)
    }

    /// Lacaze's note, typed (the game never writes by hand for anyone but the player).
    private func noteBlock(_ text: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            StoryLabel(text: L10n.t("story.progress.note"), color: Trace.Colors.inkSoft)
            Text(text)
                .font(Trace.Fonts.quote)
                .foregroundStyle(Trace.Colors.pen)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.leading, 12)
        .overlay(alignment: .leading) { Rectangle().fill(Trace.Colors.stamp.opacity(0.6)).frame(width: 2) }
        .padding(.top, 4)
        .accessibilityElement(children: .combine)
    }

    // MARK: Avancement de service (on h17)

    /// A rank reached: « AVANCEMENT DE SERVICE », the sentence, the new rank stamp falling.
    private func promotionBlock(_ rank: StoryRank) -> some View {
        let title = story.rankTitle(rank)
        let layout = typeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 14))
            : AnyLayout(HStackLayout(alignment: .top, spacing: 12))
        return layout {
            VStack(alignment: .leading, spacing: 8) {
                StoryLabel(text: L10n.t("story.promotion.title"), color: Trace.Colors.stamp)
                    .accessibilityAddTraits(.isHeader)
                Text(L10n.f("story.promotion.body", title))
                    .font(Trace.StoryFonts.body)
                    .foregroundStyle(Trace.Colors.ink)
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            FallingStampImage(asset: StoryPaper.stampAsset(rank), label: title.uppercased(), width: 120,
                              onPaper: true, angle: -8, success: true, delay: 0.5)
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("story.promotion")
    }

    // MARK: h18 · Récompense

    @ViewBuilder
    private func rewardPage(_ index: Int) -> some View {
        if items.indices.contains(index) {
            let item = items[index]
            let last = index == items.count - 1
            StoryPaper.Page(backID: "story.reward.back",
                            onBack: { go(index == 0 ? .progress : .reward(index - 1)) }) {
                VStack(spacing: 16) {
                    StoryPaper.RewardObject(item: item, name: story.resolve(item.name), player: story.player,
                                            rank: story.rankTitle(), portrait: story.portrait)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 12)
                    StoryLabel(text: L10n.t("story.reward.added"))
                    Text(story.resolve(item.name))
                        .font(Trace.StoryFonts.h2)
                        .foregroundStyle(Trace.Colors.bone)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityAddTraits(.isHeader)
                    if let provenance = item.provenance, !provenance.isEmpty {
                        Text(story.resolve(provenance))
                            .font(Trace.StoryFonts.caption)
                            .foregroundStyle(Trace.Colors.bone2)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .frame(maxWidth: .infinity)
                .accessibilityElement(children: .contain)
                .accessibilityIdentifier("story.reward.sheet")
            } bottom: {
                StoryPaper.Footer {
                    Button(L10n.t("story.reward.office")) { finish { onOffice(item.id) } }
                        .buttonStyle(CTAButtonStyle())
                        .accessibilityIdentifier("story.reward.office")
                    Button(L10n.t("story.reward.later")) {
                        if last {
                            finish { onDone() }
                        } else {
                            go(.reward(index + 1))
                        }
                    }
                    .buttonStyle(TextLinkStyle())
                    .accessibilityIdentifier("story.reward.later")
                }
            }
        } else {
            Color.clear.onAppear { finish { onDone() } }
        }
    }
}

// MARK: - h19 · Paramètres histoire

/// LECTURE (subtitles, text speed, auto-advance, voices) · AFFICHAGE 3D (quality, depth of field,
/// camera motion) · CARRIÈRE (appearance, replay a chapter, agreement, reset — red, then a 1.6 s
/// hold). Rows of 48 pt on the dark desk; the settings persist in `StoryPreferences`.
struct StorySettingsView: View {
    let story: StoryCoordinator
    let onBack: () -> Void
    let onEditAppearance: () -> Void
    let onReplay: (String) -> Void

    private enum Sheet: String, Identifiable {
        case replay, reset
        var id: String { rawValue }
    }

    @State private var subtitleSize = StoryPreferences.subtitleSize
    @State private var textSpeed = StoryPreferences.textSpeed
    @State private var voice = StoryPreferences.voice
    @State private var quality = StoryPreferences.quality
    @State private var depthOfField = StoryPreferences.depthOfField
    @State private var cameraMotion = StoryPaper.CameraMotion(StoryPreferences.reduceCameraMotion)
    /// The agreement chosen here (the coordinator does not republish it).
    @State private var agreement: Agreement?
    @State private var sheet: Sheet?
    @State private var pendingReplay: String?
    @State private var resetConfirmed = false

    var body: some View {
        StoryPaper.Page(backID: "story.settings.back", onBack: onBack) {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 6) {
                    StoryLabel(text: L10n.t("story.settings.kicker"))
                    Text(L10n.t("story.settings.title"))
                        .font(Trace.StoryFonts.h1)
                        .foregroundStyle(Trace.Colors.bone)
                        .accessibilityAddTraits(.isHeader)
                }
                reading
                display
                career
            }
        } bottom: {
            EmptyView()
        }
        .background(ModeBackdrop(colors: Trace.Story.deskStory))
        .onChange(of: subtitleSize) { _, value in StoryPreferences.subtitleSize = value }
        .onChange(of: textSpeed) { _, value in StoryPreferences.textSpeed = value }
        .onChange(of: voice) { _, value in StoryPreferences.voice = value }
        .onChange(of: quality) { _, value in StoryPreferences.quality = value }
        .onChange(of: depthOfField) { _, value in StoryPreferences.depthOfField = value }
        .onChange(of: cameraMotion) { _, value in StoryPreferences.reduceCameraMotion = value.value }
        .sheet(item: $sheet, onDismiss: { afterSheet() }) { which in
            switch which {
            case .replay:
                StoryPaper.ReplaySheet(chapters: completedChapters,
                                       onChoose: { id in
                                           pendingReplay = id
                                           sheet = nil
                                       },
                                       onClose: { sheet = nil })
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
                    .presentationCornerRadius(16)
                    .presentationBackground(Trace.Colors.paper)
            case .reset:
                StoryPaper.ResetSheet(onConfirm: {
                                          resetConfirmed = true
                                          sheet = nil
                                      },
                                      onCancel: { sheet = nil })
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
                    .presentationCornerRadius(16)
                    .presentationBackground(Trace.Colors.paper)
            }
        }
    }

    // MARK: Groups

    private var reading: some View {
        SettingsGroup(title: L10n.t("story.settings.reading")) {
            choiceRow(L10n.t("story.settings.subtitles"), id: "story.settings.subtitles", selection: $subtitleSize, options: [
                StoryPaper.Choice(value: StoryPreferences.SubtitleSize.small, label: L10n.t("story.settings.subtitles.small")),
                StoryPaper.Choice(value: StoryPreferences.SubtitleSize.medium, label: L10n.t("story.settings.subtitles.medium")),
                StoryPaper.Choice(value: StoryPreferences.SubtitleSize.large, label: L10n.t("story.settings.subtitles.large")),
            ])
            choiceRow(L10n.t("story.settings.speed"), id: "story.settings.speed", selection: $textSpeed, options: [
                StoryPaper.Choice(value: StoryPreferences.TextSpeed.slow, label: L10n.t("story.settings.speed.slow")),
                StoryPaper.Choice(value: StoryPreferences.TextSpeed.normal, label: L10n.t("story.settings.speed.normal")),
                StoryPaper.Choice(value: StoryPreferences.TextSpeed.instant, label: L10n.t("story.settings.speed.instant")),
            ])
            toggleRow(L10n.t("story.settings.auto"), id: "story.settings.auto",
                      isOn: Binding(get: { story.auto }, set: { story.auto = $0 }))
            toggleRow(L10n.t("story.settings.voice"), id: "story.settings.voice", isOn: $voice, divider: false)
        }
    }

    private var display: some View {
        SettingsGroup(title: L10n.t("story.settings.display")) {
            choiceRow(L10n.t("story.settings.quality"), id: "story.settings.quality", selection: $quality, options: [
                StoryPaper.Choice(value: StoryPreferences.Quality.auto, label: L10n.t("story.settings.quality.auto")),
                StoryPaper.Choice(value: StoryPreferences.Quality.economy, label: L10n.t("story.settings.quality.economy")),
                StoryPaper.Choice(value: StoryPreferences.Quality.high, label: L10n.t("story.settings.quality.high")),
            ])
            toggleRow(L10n.t("story.settings.depth"), id: "story.settings.depth", isOn: $depthOfField)
            choiceRow(L10n.t("story.settings.camera"), id: "story.settings.camera", selection: $cameraMotion, options: [
                StoryPaper.Choice(value: StoryPaper.CameraMotion.system, label: L10n.t("story.settings.camera.system")),
                StoryPaper.Choice(value: StoryPaper.CameraMotion.reduced, label: L10n.t("story.settings.camera.on")),
                StoryPaper.Choice(value: StoryPaper.CameraMotion.full, label: L10n.t("story.settings.camera.off")),
            ], divider: false)
        }
    }

    private var career: some View {
        SettingsGroup(title: L10n.t("story.settings.career")) {
            linkRow(L10n.t("story.settings.appearance"), id: "story.settings.appearance", action: onEditAppearance)
            linkRow(L10n.t("story.settings.replay"), id: "story.settings.replay") { sheet = .replay }
            choiceRow(L10n.t("story.settings.agreement"), id: "story.settings.agreement", selection: agreementBinding, options: [
                StoryPaper.Choice(value: Agreement.feminine, label: L10n.t("story.settings.agreement.f")),
                StoryPaper.Choice(value: Agreement.masculine, label: L10n.t("story.settings.agreement.m")),
                StoryPaper.Choice(value: Agreement.neutral, label: L10n.t("story.settings.agreement.n")),
            ])
            linkRow(L10n.t("story.settings.reset"), id: "story.settings.reset", color: Trace.Colors.stampOnDark,
                    divider: false) { sheet = .reset }
        }
    }

    private var agreementBinding: Binding<Agreement> {
        Binding(get: { agreement ?? story.player?.agreement ?? .feminine },
                set: { value in
                    agreement = value
                    story.updateAgreement(value)
                })
    }

    private var completedChapters: [StoryChapter] {
        guard let save = story.save, let content = story.content else { return [] }
        return content.campaign.chapters.filter { save.completedChapters.contains($0.id) && $0.status == .playable }
    }

    /// The sheet is gone: replay the chosen chapter, or reset the story (ENQUÊTES and ALIBI kept).
    private func afterSheet() {
        if let id = pendingReplay {
            pendingReplay = nil
            onReplay(id)
        } else if resetConfirmed {
            resetConfirmed = false
            story.resetStory()
            onBack()
        }
    }

    // MARK: Rows

    private var rowDivider: some View {
        Rectangle()
            .fill(Trace.Colors.bone.opacity(0.08))
            .frame(height: 1)
            .padding(.leading, 16)
            .accessibilityHidden(true)
    }

    private func choiceRow<Value: Hashable>(_ title: String, id: String, selection: Binding<Value>,
                                            options: [StoryPaper.Choice<Value>], divider: Bool = true) -> some View {
        let current = options.first(where: { $0.value == selection.wrappedValue })?.label ?? ""
        return Menu {
            Picker(title, selection: selection) {
                ForEach(options) { option in
                    Text(option.label).tag(option.value)
                }
            }
        } label: {
            HStack(spacing: 8) {
                Text(title)
                    .font(Trace.StoryFonts.uiBody)
                    .foregroundStyle(Trace.Colors.bone)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 8)
                Text(current)
                    .font(Trace.StoryFonts.uiBody)
                    .foregroundStyle(Trace.Colors.bone2)
                    .multilineTextAlignment(.trailing)
                Image(systemName: "chevron.up.chevron.down")
                    .font(Trace.StoryFonts.caption)
                    .foregroundStyle(Trace.Colors.bone3)
                    .accessibilityHidden(true)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 6)
            .frame(minHeight: 48)
            .contentShape(Rectangle())
        }
        .tint(Trace.Colors.bone)
        .overlay(alignment: .bottom) { if divider { rowDivider } }
        .accessibilityLabel(Text(title))
        .accessibilityValue(Text(current))
        .accessibilityIdentifier(id)
    }

    private func toggleRow(_ title: String, id: String, isOn: Binding<Bool>, divider: Bool = true) -> some View {
        Toggle(isOn: isOn) {
            Text(title)
                .font(Trace.StoryFonts.uiBody)
                .foregroundStyle(Trace.Colors.bone)
                .fixedSize(horizontal: false, vertical: true)
        }
        .tint(Trace.Colors.stampOnDark)
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
        .frame(minHeight: 48)
        .overlay(alignment: .bottom) { if divider { rowDivider } }
        .accessibilityIdentifier(id)
    }

    private func linkRow(_ title: String, id: String, color: Color = Trace.Colors.bone, divider: Bool = true,
                         action: @escaping @MainActor () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Text(title)
                    .font(Trace.StoryFonts.uiBody)
                    .foregroundStyle(color)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 8)
                Image(systemName: "chevron.right")
                    .font(Trace.StoryFonts.caption)
                    .foregroundStyle(Trace.Colors.bone3)
                    .accessibilityHidden(true)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 6)
            .frame(minHeight: 48)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .overlay(alignment: .bottom) { if divider { rowDivider } }
        .accessibilityIdentifier(id)
    }
}
#endif
