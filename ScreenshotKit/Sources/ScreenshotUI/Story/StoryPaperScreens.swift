#if os(iOS)
import SwiftUI
import UIKit
import StoryEngine

// The paper screens of the story mode (docs/design_story/STORY_UX_FLOW.md §3), laid on the V4 desk
// (docs/design_v4): h07 the investigator's file, h08 the career, h10 a chapter's folder, h15 the
// new case file, h16 → h17 → « Avancement de service » → h18 the end of a chapter, h19 the
// story's settings. Kraft folders and ivory sheets written in ink, Newsreader titles, Plex Mono
// short labels, PNG stamps (RÉSOLU, CONFIDENTIEL, the ranks), Caveat only for Lacaze's note; one
// main button per screen at the bottom (ivory on the desk). They read `StoryCoordinator` and call
// its actions: no story rule here. « Réduire les animations » turns every move into a 200 ms fade
// and stamps appear without falling.

extension Trace.StoryFonts {
    /// The rank on the career timeline (h08): Newsreader 20/600.
    static let careerRank = Font.custom(Trace.FontName.serifSemibold, size: 20, relativeTo: .title3)
}

// MARK: - Shared pieces

/// Pieces shared by the story's paper screens (a namespace: nothing here leaks out of the file).
private enum StoryPaper {
    private static let letters = Array("ABCDEFGHIJKLMNOPQRSTUVWXYZ")

    /// « 01 », « 12 ».
    static func twoDigits(_ n: Int) -> String { n < 10 ? "0\(n)" : "\(n)" }

    /// « A », « B »… (the n-th case of a chapter).
    static func letter(_ index: Int) -> String { String(letters[max(0, min(index, letters.count - 1))]) }

    /// « PREMIÈRE AFFECTATION » → « Première affectation ».
    static func title(_ text: String) -> String { StoryTitles.sentence(text) }

    static func fullName(_ player: StoryPlayer?) -> String {
        guard let player else { return "—" }
        return player.firstName + " " + player.lastName
    }

    /// « É. Morel »
    static func shortName(_ player: StoryPlayer) -> String {
        "\(player.firstName.prefix(1)). \(player.lastName)"
    }

    static func initials(_ player: StoryPlayer?) -> String {
        guard let player else { return "" }
        return StoryCoordinator.initials(player.firstName, player.lastName)
    }

    /// mm:ss (an hour counts as 60 minutes); « — » for nothing.
    static func duration(_ seconds: Int) -> String {
        guard seconds > 0 else { return "—" }
        return String(format: "%02ld:%02ld", seconds / 60, seconds % 60)
    }

    // MARK: Views

    /// A 1 pt rule in ink on paper.
    struct Rule: View {
        var color: Color = Trace.Story.rule

        var body: some View {
            Rectangle().fill(color).frame(height: 1).accessibilityHidden(true)
        }
    }

    /// The sheet's header: « BEN » and the bureau's name, the BEN's seal, then a 1.5 pt ink rule.
    struct Letterhead: View {
        var body: some View {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .center, spacing: 12) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(L10n.t("story.paper.ben"))
                            .font(Trace.Fonts.data)
                            .tracking(1.2)
                            .foregroundStyle(Trace.Colors.ink)
                        Text(L10n.t("assignment.bureau"))
                            .font(Trace.Fonts.caption)
                            .foregroundStyle(Trace.Colors.ink2)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer(minLength: 8)
                    if let seal = ArtLibrary.image("seal_ben_bleu") {
                        Image(uiImage: seal)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 44, height: 44)
                            .blendMode(.multiply)
                            .opacity(0.85)
                            .accessibilityHidden(true)
                    }
                }
                Rectangle().fill(Trace.Colors.ink).frame(height: 1.5).accessibilityHidden(true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityElement(children: .combine)
        }
    }

    /// Lacaze's visa: his blue signature (when delivered) over his printed name.
    struct Visa: View {
        var body: some View {
            VStack(alignment: .leading, spacing: 2) {
                StoryLabel(text: L10n.t("story.profile.visa"))
                if let signature = ArtLibrary.image("signature_lacaze_bleu") {
                    Image(uiImage: signature)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 120, height: 40, alignment: .leading)
                        .blendMode(.multiply)
                        .accessibilityHidden(true)
                }
                Text(L10n.t("assignment.signatory"))
                    .font(Trace.Fonts.caption)
                    .foregroundStyle(Trace.Colors.ink)
            }
            .accessibilityElement(children: .combine)
        }
    }

    /// « ‹ Histoire » (V3 §4 « où suis-je »): the previous screen's name, ivory on the desk, 44 pt.
    struct TopBar: View {
        let backID: String
        var backLabel: String? = nil
        let onBack: () -> Void

        var body: some View {
            HStack(spacing: 0) {
                BackChevron(label: backLabel ?? L10n.t("story.nav.hub"), action: onBack)
                    .accessibilityIdentifier(backID)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 12)
            .frame(minHeight: 44)
        }
    }

    /// A screen of the story on the desk: the top bar, the scrolling content, the footer.
    struct Page<Content: View, Bottom: View>: View {
        let backID: String
        let onBack: () -> Void
        /// « ‹ {previous screen} »; « Histoire » by default.
        var backLabel: String? = nil
        @ViewBuilder let content: Content
        @ViewBuilder let bottom: Bottom

        var body: some View {
            VStack(spacing: 0) {
                TopBar(backID: backID, backLabel: backLabel, onBack: onBack)
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
            .background(ModeBackdrop())
        }
    }

    /// A title on the desk: a Plex Mono kicker, Newsreader 30 in ivory, an optional line.
    struct DeskHeading: View {
        let kicker: String?
        let title: String
        var line: String? = nil

        var body: some View {
            VStack(alignment: .leading, spacing: 6) {
                if let kicker { StoryLabel(text: kicker, color: Trace.Colors.ivory2) }
                Text(title)
                    .font(Trace.Fonts.title)
                    .foregroundStyle(Trace.Colors.ivory)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityAddTraits(.isHeader)
                if let line {
                    Text(line)
                        .font(Trace.Fonts.callout)
                        .foregroundStyle(Trace.Colors.ivoryMid)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, 2)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    /// A stamp that falls on the sheet (V4 §5): scale 1.35 → 1 in 180 ms, a 60 ms settle, a rigid
    /// haptic and the thud; with reduced motion it just appears (200 ms).
    struct StampFall<Content: View>: View {
        var delay: Double = 0.35
        @ViewBuilder let content: Content
        @State private var phase = 0
        @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
        @AppStorage(Preferences.reduceMotionKey) private var appReduceMotion = false

        var body: some View {
            let still = systemReduceMotion || appReduceMotion
            content
                .scaleEffect(still ? 1 : (phase == 0 ? 1.35 : phase == 1 ? 0.98 : 1))
                .opacity(phase > 0 ? 1 : 0)
                .task {
                    try? await Task.sleep(for: .seconds(delay))
                    if still {
                        withAnimation(.easeOut(duration: 0.2)) { phase = 2 }
                    } else {
                        withAnimation(Trace.Motion.stamp) { phase = 1 }
                        try? await Task.sleep(for: .milliseconds(180))
                        withAnimation(.easeOut(duration: 0.06)) { phase = 2 }
                    }
                    AudioDirector.shared.play(.stamp, volume: 0.8)
                    Haptics.rigid()
                }
        }
    }

    /// Label ········ value (the report's figures, V4 ClosingReport).
    struct DottedLine: View {
        let label: String
        let value: String

        var body: some View {
            HStack(alignment: .lastTextBaseline, spacing: 6) {
                Text(label)
                    .font(Trace.Fonts.callout)
                    .foregroundStyle(Trace.Colors.ink2)
                    .fixedSize(horizontal: false, vertical: true)
                Dots()
                    .stroke(Trace.Colors.ink2.opacity(0.6), style: StrokeStyle(lineWidth: 1.2, lineCap: .round, dash: [0.5, 4]))
                    .frame(height: 1)
                    .frame(minWidth: 16)
                    .accessibilityHidden(true)
                Text(value)
                    .font(Trace.Fonts.data)
                    .monospacedDigit()
                    .foregroundStyle(Trace.Colors.ink)
            }
            .padding(.vertical, 6)
            .accessibilityElement(children: .combine)
        }
    }

    /// A horizontal dotted leader.
    struct Dots: Shape {
        func path(in rect: CGRect) -> Path {
            var p = Path()
            p.move(to: CGPoint(x: rect.minX, y: rect.maxY))
            p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
            return p
        }
    }

    /// A vertical line (the career's timeline).
    struct VLine: Shape {
        func path(in rect: CGRect) -> Path {
            var p = Path()
            p.move(to: CGPoint(x: rect.midX, y: rect.minY))
            p.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
            return p
        }
    }

    /// A value of a settings menu (h19).
    struct Choice<Value: Hashable>: Identifiable {
        let value: Value
        let label: String
        var id: Value { value }
    }

    /// The BEN card of the reward (h18): a plastic card, the lanyard slot, « BEN », the print with
    /// initials, the name, the rank, the service number.
    struct BENCard: View {
        let name: String
        let rank: String
        let serviceNumber: String
        let initials: String

        var body: some View {
            let shape = RoundedRectangle(cornerRadius: 10, style: .continuous)
            VStack(spacing: 10) {
                Capsule()
                    .strokeBorder(Trace.Colors.ink2.opacity(0.6), lineWidth: 1.5)
                    .frame(width: 34, height: 8)
                    .padding(.top, 12)
                VStack(spacing: 3) {
                    Text(L10n.t("story.paper.ben"))
                        .font(Trace.Fonts.data)
                        .tracking(1.5)
                        .foregroundStyle(Trace.Colors.red)
                    Text(L10n.t("assignment.bureau"))
                        .font(.custom(Trace.FontName.sans, size: 11, relativeTo: .caption2))
                        .foregroundStyle(Trace.Colors.ink2)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .minimumScaleFactor(0.7)
                }
                PortraitOrInitials(image: nil, initials: initials, width: 74, height: 92)
                VStack(spacing: 3) {
                    Text(name)
                        .font(.custom(Trace.FontName.serifSemibold, size: 17, relativeTo: .headline))
                        .foregroundStyle(Trace.Colors.ink)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .minimumScaleFactor(0.6)
                    Text(rank)
                        .font(Trace.Fonts.caption)
                        .foregroundStyle(Trace.Colors.ink2)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    Text(serviceNumber)
                        .font(Trace.StoryFonts.technical)
                        .foregroundStyle(Trace.Colors.ink)
                }
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 12)
            .frame(width: 176, height: 272)
            .background(shape.fill(Trace.Colors.photoBorder))
            .overlay(shape.strokeBorder(Trace.Colors.ink.opacity(0.12), lineWidth: 1))
            .shadow(color: Trace.Shadow.slip.color, radius: Trace.Shadow.slip.radius, y: Trace.Shadow.slip.y)
        }
    }

    /// Any other object of the reward: a paper tag with its label and its name, pinned.
    struct ObjectTag: View {
        let name: String

        var body: some View {
            VStack(alignment: .leading, spacing: 14) {
                Text(L10n.t("story.paper.ben"))
                    .font(Trace.Fonts.data)
                    .tracking(1.5)
                    .foregroundStyle(Trace.Colors.red)
                Text(name)
                    .font(Trace.StoryFonts.h3)
                    .foregroundStyle(Trace.Colors.ink)
                    .multilineTextAlignment(.leading)
                    .lineLimit(4)
                    .minimumScaleFactor(0.6)
                Rule()
                Spacer(minLength: 0)
            }
            .padding(18)
            .padding(.top, 6)
            .frame(width: 184, height: 232, alignment: .topLeading)
            .paper(Trace.Colors.paperCard)
            .overlay(alignment: .top) { Pin(color: Trace.Colors.red).offset(y: -6) }
        }
    }

    /// h18's object, laid on the desk with a fade and a 20 pt rise (420 ms), slightly tilted.
    struct RewardObject: View {
        let item: RewardItem
        let name: String
        let player: StoryPlayer?
        let rank: String
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
                object
                    .tilt("reward." + item.id)
                    .offset(y: shown || still ? 0 : 20)
                    .opacity(shown ? 1 : 0)
            }
            .frame(width: 220, height: 290)
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
                        initials: StoryPaper.initials(player))
            } else {
                ObjectTag(name: name)
            }
        }
    }

    /// The promotion note of a rank already reached (h08, tap on a passed step), on paper.
    struct PromotionNote: View {
        let title: String
        let date: String?
        let first: Bool
        let onClose: () -> Void

        var body: some View {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    Letterhead()
                    StoryLabel(text: L10n.t("story.career.note.title"))
                        .accessibilityAddTraits(.isHeader)
                    Text(title)
                        .font(Trace.StoryFonts.h2)
                        .foregroundStyle(Trace.Colors.ink)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(first ? L10n.t("story.career.note.first") : L10n.t("story.career.note.body"))
                        .font(Trace.StoryFonts.body)
                        .foregroundStyle(Trace.Colors.ink)
                        .lineSpacing(4)
                        .fixedSize(horizontal: false, vertical: true)
                    if let date {
                        Text(L10n.f("story.career.note.date", date))
                            .font(Trace.StoryFonts.technical)
                            .foregroundStyle(Trace.Colors.ink2)
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

    /// h19 « Rejouer un chapitre »: the chapters already finished, on paper.
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
                        .foregroundStyle(Trace.Colors.ink2)
                        .fixedSize(horizontal: false, vertical: true)
                    if chapters.isEmpty {
                        Text(L10n.t("story.settings.replayEmpty"))
                            .font(Trace.StoryFonts.body)
                            .foregroundStyle(Trace.Colors.ink2)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.vertical, 8)
                    } else {
                        VStack(spacing: 0) {
                            Rule()
                            ForEach(chapters) { chapter in
                                Button { onChoose(chapter.id) } label: {
                                    HStack(alignment: .firstTextBaseline, spacing: 12) {
                                        StoryLabel(text: L10n.f("story.chapter.tab", StoryPaper.twoDigits(chapter.number)))
                                        Text(StoryPaper.title(chapter.title))
                                            .font(Trace.StoryFonts.body)
                                            .foregroundStyle(Trace.Colors.ink)
                                            .multilineTextAlignment(.leading)
                                            .fixedSize(horizontal: false, vertical: true)
                                        Spacer(minLength: 8)
                                        Image(systemName: "chevron.right")
                                            .font(Trace.StoryFonts.caption)
                                            .foregroundStyle(Trace.Colors.ink2)
                                            .accessibilityHidden(true)
                                    }
                                    .padding(.vertical, 8)
                                    .frame(minHeight: 48)
                                    .overlay(alignment: .bottom) { Rule() }
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

    /// h19 « Réinitialiser l'histoire »: the one hold of the settings (1.6 s, red), on paper.
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
                        .foregroundStyle(Trace.Colors.ink)
                        .lineSpacing(4)
                        .fixedSize(horizontal: false, vertical: true)
                    StoryHoldButton(title: L10n.t("story.settings.resetHold"), seconds: 1.6, destructive: true, onPaper: true,
                                    identifier: "story.settings.reset.hold") {
                        onConfirm()
                    }
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

/// The investigator's file on paper: letterhead, the stapled print (initials) 104 × 130, name, the
/// rank stamp and the service number, the three numbers (cases handled · solved · seniority), the
/// last three lines of the history, Lacaze's visa. Never a relationship score.
struct StoryProfileView: View {
    let story: StoryCoordinator
    let onBack: () -> Void

    @Environment(\.dynamicTypeSize) private var typeSize

    private static let printWidth: CGFloat = 104
    private static let printHeight: CGFloat = 130
    private static let historyLength = 3

    var body: some View {
        StoryPaper.Page(backID: "story.profile.back", onBack: onBack) {
            sheet
                .padding(.top, 8)
        } bottom: {
            EmptyView()
        }
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
            StoryPaper.Visa()
                .padding(.top, 4)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .paper(Trace.Colors.paper)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("story.profile.sheet")
    }

    /// Print beside the name; stacked at accessibility sizes.
    private var stacked: Bool { typeSize.isAccessibilitySize }

    private var identity: some View {
        let player = story.player
        let name = StoryPaper.fullName(player)
        let title = story.rankTitle()
        let layout = stacked
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 14))
            : AnyLayout(HStackLayout(alignment: .top, spacing: 16))
        return layout {
            StoryPlayerPrint(initials: StoryPaper.initials(player), width: Self.printWidth, height: Self.printHeight,
                             label: L10n.f("story.profile.a11y.print", name))
                .tilt("profile.print")
                .padding(.top, 6)
            VStack(alignment: .leading, spacing: 8) {
                Text(name)
                    .font(Trace.StoryFonts.h2)
                    .foregroundStyle(Trace.Colors.ink)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityAddTraits(.isHeader)
                if let number = player?.serviceNumber {
                    Text(L10n.f("story.profile.serviceNumber", number))
                        .font(Trace.Fonts.data)
                        .foregroundStyle(Trace.Colors.ink)
                }
                StoryRankStamp(rank: (story.save?.rank ?? .enqueteur).rawValue, title: title, width: 130, angle: -6)
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
            StoryLabel(text: label)
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
            StoryLabel(text: L10n.t("story.profile.history"))
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
                .foregroundStyle(Trace.Colors.ink2)
                .frame(minWidth: 92, alignment: .leading)
            Text(text)
                .font(Trace.Fonts.callout)
                .foregroundStyle(Trace.Colors.ink)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .padding(.vertical, 9)
        .overlay(alignment: .bottom) { StoryPaper.Rule() }
        .accessibilityElement(children: .combine)
    }
}

// MARK: - h08 · Carrière

/// The career as a vertical timeline on a sheet: one step per rank — passed (ink dot, solid line,
/// the date), current (red ring on a red halo, « Actuel » and a counter), future (empty ring,
/// dotted, 45 %, its condition). No gauge, no percentage. A passed step opens its promotion note.
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
            VStack(alignment: .leading, spacing: 20) {
                StoryPaper.DeskHeading(kicker: L10n.t("story.hub.kicker"), title: L10n.t("story.career.title"),
                                       line: L10n.t("story.career.intro"))
                timeline
            }
        } bottom: {
            EmptyView()
        }
        .sheet(item: $note) { item in
            StoryPaper.PromotionNote(title: item.title, date: item.date, first: item.id == tiers.first?.rank,
                                     onClose: { note = nil })
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(Trace.Radius.sheet)
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
        .paper(Trace.Colors.paper)
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
            Text(title)
                .font(Trace.StoryFonts.careerRank)
                .foregroundStyle(Trace.Colors.ink)
                .fixedSize(horizontal: false, vertical: true)
            Text(step)
                .font(Trace.Fonts.callout)
                .foregroundStyle(Trace.Colors.ink2)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
            Text(meta)
                .font(Trace.StoryFonts.technical)
                .foregroundStyle(state == .current ? Trace.Colors.red : Trace.Colors.ink2)
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
                    Circle().fill(Trace.Colors.tint(Trace.Colors.red)).frame(width: Self.markerWidth, height: Self.markerWidth)
                    Circle().strokeBorder(Trace.Colors.red, lineWidth: 2).frame(width: Self.dotSize, height: Self.dotSize)
                case .future:
                    Circle().strokeBorder(Trace.Colors.ink2, lineWidth: 1.5).frame(width: Self.dotSize, height: Self.dotSize)
                }
            }
            .frame(width: Self.markerWidth, height: Self.markerWidth)
            if !last {
                StoryPaper.VLine()
                    .stroke(Trace.Colors.ink2.opacity(0.6),
                            style: StrokeStyle(lineWidth: 2, lineCap: .round, dash: state == .passed ? [] : [0.5, 4.5]))
                    .frame(width: 2)
                    .frame(maxHeight: .infinity)
            }
        }
        .frame(width: Self.markerWidth)
        // The dot sits on the rank's line.
        .padding(.top, -2)
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

/// A chapter as a kraft folder « CHAPITRE 0N » holding its sheet: the title, the synopsis, the
/// steps (✓ done · ● current · ○ to come, 45 %, « ··· » for a surprise), the RÉSOLU stamp (or
/// « Classé ») once finished. One button at the bottom: « Continuer · Scène n » (current),
/// « Chapitre suivant » (finished), none for a chapter not written yet (« Bientôt disponible »).
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
                    .padding(.top, 8)
            } else {
                Text(L10n.t("story.chapter.soon"))
                    .font(Trace.StoryFonts.body)
                    .foregroundStyle(Trace.Colors.ivoryMid)
                    .padding(.top, 24)
            }
        } bottom: {
            if let chapter {
                footer(chapter, phase: phase(of: chapter))
            }
        }
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
            StoryFolderTab(text: L10n.f("story.chapter.tab", StoryPaper.twoDigits(chapter.number)))
                .accessibilityHidden(true)
            sheet(chapter, phase: phase)
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .kraft()
        }
        .opacity(phase == .planned || phase == .locked ? 0.7 : 1)
    }

    private func sheet(_ chapter: StoryChapter, phase: Phase) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 8) {
                VStack(alignment: .leading, spacing: 10) {
                    Text(L10n.f("story.chapter.tab", StoryPaper.twoDigits(chapter.number)).uppercased())
                        .font(Trace.Fonts.data)
                        .tracking(1.2)
                        .foregroundStyle(Trace.Colors.ink)
                        .accessibilityAddTraits(.isHeader)
                    Text(StoryPaper.title(chapter.title))
                        .font(Trace.Fonts.title)
                        .foregroundStyle(Trace.Colors.ink)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityAddTraits(.isHeader)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                if phase == .finished {
                    stamp(chapter)
                        .frame(width: 100)
                        .padding(.top, 6)
                }
            }
            Rectangle().fill(Trace.Colors.ink).frame(height: 1.5).accessibilityHidden(true)
            Text(story.resolve(chapter.synopsis))
                .font(Trace.Fonts.body)
                .foregroundStyle(Trace.Colors.ink)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
            switch phase {
            case .planned:
                StoryLabel(text: L10n.t("story.chapter.soon"))
                    .padding(.top, 4)
            case .locked:
                StoryLabel(text: lockedLine(chapter))
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 4)
            case .finished, .current, .available:
                steps(chapter, phase: phase)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .paper(Trace.Colors.paper)
    }

    /// RÉSOLU (the PNG) or « Classé » (a code stamp in ink).
    @ViewBuilder
    private func stamp(_ chapter: StoryChapter) -> some View {
        if solved(chapter) {
            StampImage(asset: "stamp_resolu_rouge_marque", label: L10n.t("story.badge.solved"), width: 100, angle: -9)
        } else {
            StampMark(text: L10n.t("story.paper.stampFiled"), color: Trace.Colors.ink2, size: 13)
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
                .foregroundStyle(state == .current ? Trace.Colors.red : state == .done ? Trace.Colors.green : Trace.Colors.ink2)
                .frame(width: 16)
            Text(title)
                .font(Trace.Fonts.callout)
                .foregroundStyle(Trace.Colors.ink)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 8)
            StoryLabel(text: type)
        }
        .padding(.vertical, 6)
        .frame(minHeight: 44)
        .overlay(alignment: .bottom) { StoryPaper.Rule() }
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
            StoryFooter {
                Button(continueTitle(chapter, phase: phase)) { proceed() }
                    .buttonStyle(CTAButtonStyle())
                    .accessibilityIdentifier("story.chapter.continue")
            }
        case .finished:
            if opensNext(after: chapter) {
                StoryFooter {
                    Button(L10n.t("story.chapter.next")) { proceed() }
                        .buttonStyle(CTAButtonStyle())
                        .accessibilityIdentifier("story.chapter.next")
                }
            } else if nextIsPlanned(after: chapter) {
                StoryFooter {
                    Text(L10n.t("story.chapter.nextSoon"))
                        .font(Trace.StoryFonts.caption)
                        .foregroundStyle(Trace.Colors.ivoryMid)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(minHeight: 44)
                }
            }
        case .locked, .planned:
            EmptyView()
        }
    }

    /// « Continuer · scène n » when the next step is a scene, else « Continuer ».
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

/// The last image of the scene: the new case file, a kraft folder (V4 CaseFolder) on the desk —
/// its tab and number, « CHAPITRE 0N · AFFAIRE A », the title in Newsreader, the CONFIDENTIEL stamp
/// falling on it, « Affectée à É. Morel » on a stapled label. [Ouvrir le dossier] rises in with a
/// 500 ms fade at the bottom.
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
                .padding(.top, 28)
        } bottom: {
            StoryFooter {
                Button(L10n.t("story.caseFolder.open")) { open() }
                    .buttonStyle(CTAButtonStyle())
                    .accessibilityIdentifier("story.caseFolder.open")
            }
            .opacity(buttonShown ? 1 : 0)
            .offset(y: buttonShown || still ? 0 : 16)
        }
        .task {
            try? await Task.sleep(for: .seconds(still ? 0.1 : 0.5))
            withAnimation(.easeOut(duration: still ? 0.2 : 0.5)) { buttonShown = true }
        }
    }

    private var folder: some View {
        VStack(alignment: .leading, spacing: 0) {
            StoryFolderTab(text: label.isEmpty ? L10n.t("story.paper.ben") : label.uppercased())
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 16) {
                Text(label.isEmpty ? "—" : label.uppercased())
                    .font(Trace.Fonts.data)
                    .tracking(1.2)
                    .foregroundStyle(Trace.Colors.ink)
                StoryLabel(text: L10n.f("story.caseFolder.kicker", StoryPaper.twoDigits(chapterNumber), letter),
                           color: Trace.Colors.ink)
                    .fixedSize(horizontal: false, vertical: true)
                Text(StoryPaper.title(caseTitle))
                    .font(Trace.Fonts.caseTitle)
                    .foregroundStyle(Trace.Colors.ink)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityAddTraits(.isHeader)
                Spacer(minLength: 8)
                HStack {
                    Spacer(minLength: 0)
                    FallingStampImage(asset: "stamp_confidentiel_rouge_marque", label: L10n.t("stamp.confidential"),
                                      width: 150, angle: -8, delay: 0.35)
                        .allowsHitTesting(false)
                }
                .frame(minHeight: 72)
                if let assigned {
                    Text(assigned)
                        .font(Trace.Fonts.callout)
                        .foregroundStyle(Trace.Colors.ink)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .paper(Trace.Colors.paperCard)
                        .overlay(alignment: .topLeading) { Staple().offset(x: 20, y: -4) }
                }
            }
            .padding(20)
            .frame(maxWidth: .infinity, minHeight: 340, alignment: .topLeading)
            .kraft()
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

    /// « Affectée à É. Morel » (the player's agreement).
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
/// the report (h16), the service record (h17 — when a rank was reached, « Avancement de
/// service » happens on it: the new rank's stamp falls, one sentence), and the objects added to
/// the office (h18). A chapter is never blocking: CLASSÉ goes on too.
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
        .background(ModeBackdrop())
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

    // MARK: h16 · Résultat de chapitre (the report)

    private var summaryPage: some View {
        StoryPaper.Page(backID: "story.result.back", onBack: { story.pauseToHub() }) {
            summarySheet
                .padding(.top, 8)
        } bottom: {
            StoryFooter {
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
            StoryPaper.Letterhead()
            HStack(alignment: .top, spacing: 8) {
                VStack(alignment: .leading, spacing: 8) {
                    StoryLabel(text: L10n.f("story.result.kicker", chapterNumber))
                        .fixedSize(horizontal: false, vertical: true)
                    Text(StoryPaper.title(chapter?.title ?? ""))
                        .font(Trace.Fonts.title)
                        .foregroundStyle(Trace.Colors.ink)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityAddTraits(.isHeader)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                verdictStamp
                    .frame(width: 112)
                    .padding(.top, 10)
                    .allowsHitTesting(false)
            }
            if !summary.isEmpty {
                Text(summary)
                    .font(Trace.StoryFonts.body)
                    .foregroundStyle(Trace.Colors.ink)
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
            }
            table
            decisions
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .paper(Trace.Colors.paper)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("story.result.sheet")
    }

    /// RÉSOLU (the PNG) falls on the report; « Classé » in ink when a case was not solved.
    @ViewBuilder
    private var verdictStamp: some View {
        if result.solved {
            FallingStampImage(asset: "stamp_resolu_rouge_marque", label: L10n.t("story.badge.solved"),
                              width: 112, angle: -9, delay: 0.35)
        } else {
            StoryPaper.StampFall(delay: 0.35) {
                StampMark(text: L10n.t("story.paper.stampFiled"), color: Trace.Colors.ink, size: 15, angle: -9)
            }
        }
    }

    /// AFFAIRES DU CHAPITRE · ALIBI · TEMPS TOTAL, with dotted leaders.
    private var table: some View {
        let cases = result.cases == 0 ? "—" : "\(result.casesSolved) / \(result.cases)"
        let alibis = result.alibis == 0 ? "—" : "\(result.alibis)"
        return VStack(spacing: 0) {
            StoryPaper.DottedLine(label: L10n.t("story.result.cases"), value: cases)
            StoryPaper.DottedLine(label: L10n.t("story.result.alibi"), value: alibis)
            StoryPaper.DottedLine(label: L10n.t("story.result.time"), value: StoryPaper.duration(result.seconds))
        }
        .padding(.vertical, 6)
        .overlay(alignment: .top) { StoryPaper.Rule() }
        .overlay(alignment: .bottom) { StoryPaper.Rule() }
    }

    /// VOS DÉCISIONS: one or two sentences from the remembered answers.
    private var decisions: some View {
        let lines = result.decisions.prefix(2).map { story.resolve($0) }
        return VStack(alignment: .leading, spacing: 8) {
            StoryLabel(text: L10n.t("story.result.decisions"))
                .accessibilityAddTraits(.isHeader)
            if lines.isEmpty {
                Text(L10n.t("story.result.noDecision"))
                    .font(Trace.StoryFonts.body)
                    .foregroundStyle(Trace.Colors.ink2)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                ForEach(Array(lines.enumerated()), id: \.offset) { _, line in
                    Text(line)
                        .font(Trace.Fonts.quote)
                        .foregroundStyle(Trace.Colors.ink)
                        .lineSpacing(3)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    // MARK: h17 · État de service

    private var progressPage: some View {
        StoryPaper.Page(backID: "story.progress.back", onBack: { go(.summary) }, backLabel: L10n.t("common.back")) {
            progressSheet
                .padding(.top, 8)
        } bottom: {
            StoryFooter {
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
            StoryPaper.Letterhead()
            StoryLabel(text: L10n.t("story.progress.title"))
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
                    .foregroundStyle(Trace.Colors.ink)
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
        // ProgressBoxes lays up to 10 boxes of 26 pt per row: a narrower margin keeps them on the sheet.
        .padding(.horizontal, 16)
        .padding(.vertical, 20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .paper(Trace.Colors.paper)
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
                    .foregroundStyle(Trace.Colors.ink2)
                    .padding(.top, 14)
                    .accessibilityHidden(true)
                rankColumn(L10n.t("story.progress.nextRank"), story.rankTitle(next.rank))
            }
        }
    }

    private func rankColumn(_ label: String, _ title: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            StoryLabel(text: label)
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

    /// Lacaze's note, in his hand (Caveat, pen blue; also read by VoiceOver), and his signature.
    private func noteBlock(_ text: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            StoryLabel(text: L10n.t("story.progress.note"))
            Handwritten(text: text, size: 21)
                .fixedSize(horizontal: false, vertical: true)
            if let signature = ArtLibrary.image("signature_lacaze_bleu") {
                Image(uiImage: signature)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 110, height: 36, alignment: .leading)
                    .blendMode(.multiply)
                    .accessibilityHidden(true)
            }
        }
        .padding(.leading, 12)
        .overlay(alignment: .leading) { Rectangle().fill(Trace.Colors.marginRed).frame(width: 1.5) }
        .padding(.top, 4)
        .accessibilityElement(children: .combine)
    }

    // MARK: Avancement de service (on h17)

    /// A rank reached: « AVANCEMENT DE SERVICE », the sentence, the new rank's stamp falling.
    private func promotionBlock(_ rank: StoryRank) -> some View {
        let title = story.rankTitle(rank)
        let layout = typeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 14))
            : AnyLayout(HStackLayout(alignment: .top, spacing: 12))
        return layout {
            VStack(alignment: .leading, spacing: 8) {
                StoryLabel(text: L10n.t("story.promotion.title"), color: Trace.Colors.red)
                    .accessibilityAddTraits(.isHeader)
                Text(L10n.f("story.promotion.body", title))
                    .font(Trace.StoryFonts.body)
                    .foregroundStyle(Trace.Colors.ink)
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            StoryPaper.StampFall(delay: 0.5) {
                StoryRankStamp(rank: rank.rawValue, title: title, width: 120, angle: -8)
            }
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
                            onBack: { go(index == 0 ? .progress : .reward(index - 1)) },
                            backLabel: L10n.t("common.back")) {
                VStack(spacing: 14) {
                    StoryPaper.RewardObject(item: item, name: story.resolve(item.name), player: story.player,
                                            rank: story.rankTitle())
                        .frame(maxWidth: .infinity)
                        .padding(.top, 16)
                        .padding(.bottom, 6)
                    StoryLabel(text: L10n.t("story.reward.added"), color: Trace.Colors.ivory2)
                    Text(story.resolve(item.name))
                        .font(Trace.StoryFonts.h2)
                        .foregroundStyle(Trace.Colors.ivory)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityAddTraits(.isHeader)
                    if let provenance = item.provenance, !provenance.isEmpty {
                        Text(story.resolve(provenance))
                            .font(Trace.Fonts.callout)
                            .foregroundStyle(Trace.Colors.ivoryMid)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .frame(maxWidth: .infinity)
                .accessibilityElement(children: .contain)
                .accessibilityIdentifier("story.reward.sheet")
            } bottom: {
                StoryFooter {
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

/// LECTURE (subtitles, text speed, auto-advance, voices) · CARRIÈRE (replay a chapter, agreement,
/// reset — red, then a 1.6 s hold). Paper sheets of 48 pt rows in ink on the desk; the settings
/// persist in `StoryPreferences`. (The 3D display settings left with the 3D.)
struct StorySettingsView: View {
    let story: StoryCoordinator
    let onBack: () -> Void
    let onReplay: (String) -> Void

    private enum Sheet: String, Identifiable {
        case replay, reset
        var id: String { rawValue }
    }

    @State private var subtitleSize = StoryPreferences.subtitleSize
    @State private var textSpeed = StoryPreferences.textSpeed
    @State private var voice = StoryPreferences.voice
    /// The agreement chosen here (the coordinator does not republish it).
    @State private var agreement: Agreement?
    @State private var sheet: Sheet?
    @State private var pendingReplay: String?
    @State private var resetConfirmed = false

    var body: some View {
        StoryPaper.Page(backID: "story.settings.back", onBack: onBack) {
            VStack(alignment: .leading, spacing: 24) {
                StoryPaper.DeskHeading(kicker: L10n.t("story.settings.kicker"), title: L10n.t("story.settings.title"))
                reading
                career
            }
        } bottom: {
            EmptyView()
        }
        .onChange(of: subtitleSize) { _, value in StoryPreferences.subtitleSize = value }
        .onChange(of: textSpeed) { _, value in StoryPreferences.textSpeed = value }
        .onChange(of: voice) { _, value in StoryPreferences.voice = value }
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
                    .presentationCornerRadius(Trace.Radius.sheet)
                    .presentationBackground(Trace.Colors.paper)
            case .reset:
                StoryPaper.ResetSheet(onConfirm: {
                                          resetConfirmed = true
                                          sheet = nil
                                      },
                                      onCancel: { sheet = nil })
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
                    .presentationCornerRadius(Trace.Radius.sheet)
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

    private var career: some View {
        SettingsGroup(title: L10n.t("story.settings.career")) {
            linkRow(L10n.t("story.settings.replay"), id: "story.settings.replay") { sheet = .replay }
            choiceRow(L10n.t("story.settings.agreement"), id: "story.settings.agreement", selection: agreementBinding, options: [
                StoryPaper.Choice(value: Agreement.feminine, label: L10n.t("story.settings.agreement.f")),
                StoryPaper.Choice(value: Agreement.masculine, label: L10n.t("story.settings.agreement.m")),
                StoryPaper.Choice(value: Agreement.neutral, label: L10n.t("story.settings.agreement.n")),
            ])
            linkRow(L10n.t("story.settings.reset"), id: "story.settings.reset", color: Trace.Colors.red,
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
            .fill(Trace.Story.rule)
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
                    .foregroundStyle(Trace.Colors.ink)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 8)
                Text(current)
                    .font(Trace.StoryFonts.uiBody)
                    .foregroundStyle(Trace.Colors.ink2)
                    .multilineTextAlignment(.trailing)
                Image(systemName: "chevron.up.chevron.down")
                    .font(Trace.StoryFonts.caption)
                    .foregroundStyle(Trace.Colors.ink2)
                    .accessibilityHidden(true)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 6)
            .frame(minHeight: 48)
            .contentShape(Rectangle())
        }
        .tint(Trace.Colors.ink)
        .overlay(alignment: .bottom) { if divider { rowDivider } }
        .accessibilityLabel(Text(title))
        .accessibilityValue(Text(current))
        .accessibilityIdentifier(id)
    }

    private func toggleRow(_ title: String, id: String, isOn: Binding<Bool>, divider: Bool = true) -> some View {
        Toggle(isOn: isOn) {
            Text(title)
                .font(Trace.StoryFonts.uiBody)
                .foregroundStyle(Trace.Colors.ink)
                .fixedSize(horizontal: false, vertical: true)
        }
        .tint(Trace.Colors.ink)
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
        .frame(minHeight: 48)
        .overlay(alignment: .bottom) { if divider { rowDivider } }
        .accessibilityIdentifier(id)
    }

    private func linkRow(_ title: String, id: String, color: Color = Trace.Colors.ink, divider: Bool = true,
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
                    .foregroundStyle(Trace.Colors.ink2)
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
