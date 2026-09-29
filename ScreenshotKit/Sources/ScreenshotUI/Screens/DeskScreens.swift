#if os(iOS)
import SwiftUI
import CaseEngine

// The BEN outside an investigation (UX V3 §4–§6): the Bureau (01) with its modes (01b), the
// Archives and the investigator's profile. Flat surfaces, Newsreader titles, Plex Sans interface,
// Plex Mono for data only; the tab bar BUREAU · ARCHIVES · ENQUÊTEUR at the bottom.

// MARK: - Shared chrome

/// The top of a BEN screen (§4 « où suis-je »): « ‹ {previous screen} » in benText (44 pt), then
/// the screen's title in Newsreader.
struct BenScreenHeader: View {
    var back: String? = nil
    var backID = "nav.back"
    var onBack: () -> Void = {}
    let title: String
    var titleID = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if let back {
                BackLink(title: back, identifier: backID, action: onBack)
            }
            Text(title)
                .font(Trace.Fonts.title)
                .foregroundStyle(Trace.Colors.text)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)
                .accessibilityIdentifier(titleID)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// The « placeholder rayé » of a photo area (§5 CaseCard): thin diagonal rules on `surface2`.
struct BenStripes: View {
    var body: some View {
        Canvas { context, size in
            var path = Path()
            var x: CGFloat = -size.height
            while x < size.width {
                path.move(to: CGPoint(x: x, y: size.height))
                path.addLine(to: CGPoint(x: x + size.height, y: 0))
                x += 12
            }
            context.stroke(path, with: .color(Trace.Colors.line), lineWidth: 1.5)
        }
        .background(Trace.Colors.surface2)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

/// A case's cover photo (`cover_<NNN>` in Art.xcassets, if one is ever delivered), else the
/// striped placeholder. Never a person of the case.
struct CasePhoto: View {
    let caseNumber: Int

    var body: some View {
        if let image = ArtLibrary.image("cover_\(dossierNumber(caseNumber))") {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .accessibilityHidden(true)
        } else {
            BenStripes()
        }
    }
}

extension String {
    /// "PREMIER MÉTRO" → "Premier métro"
    var capitalizedFirst: String {
        let lower = lowercased()
        return lower.prefix(1).uppercased() + lower.dropFirst()
    }
}

// MARK: - Modes

/// The Bureau's segmented control (§6-01): Enquêtes · Alibi · Histoire, remembered.
enum DeskMode: String, CaseIterable, Hashable {
    case investigations, alibi, story

    var title: String {
        switch self {
        case .investigations: L10n.t("mode.investigations.title")
        case .alibi: L10n.t("desk.mode.alibi")
        case .story: L10n.t("desk.mode.story")
        }
    }

    /// Kept from the three-folder desk: the UI tests reach each mode by it.
    var identifier: String { "mode.\(rawValue)" }

    /// The ModeCard's glyph (outlined SF Symbol).
    var symbol: String {
        switch self {
        case .investigations: "magnifyingglass"
        case .alibi: "clock"
        case .story: "book.closed"
        }
    }
}

/// What the Bureau shows of the story (computed by RootView from the story coordinator).
struct StoryDeskSummary {
    var hasInvestigator: Bool
    /// « Chapitre 1 · Première affectation »
    var chapterLine: String?
    /// 0…1 of the current chapter.
    var progress: Double
}

/// The state of a case on a card or a row (§5 CaseCard).
enum CaseCardState: Equatable {
    case new
    case open(remaining: Double, pieces: Int)
    case solved
    case unsolved

    /// Pill text, colour and symbol (never the colour alone).
    var badge: (text: String, color: Color, symbol: String) {
        switch self {
        case .new: (L10n.t("case.state.new"), Trace.Colors.benText, "●")
        case .open: (L10n.t("case.state.open"), Trace.Colors.benText, "◐")
        case .solved: (L10n.t("case.state.solved"), Trace.Colors.successText, "✓")
        case .unsolved: (L10n.t("case.state.unsolved"), Trace.Colors.criticalOnDark, "✕")
        }
    }

    /// The short label of a list row.
    var rowText: String {
        switch self {
        case .new: L10n.t("case.state.newShort")
        case .open: L10n.t("case.state.open")
        case .solved: "✓ " + L10n.t("case.state.solved")
        case .unsolved: "✕ " + L10n.t("case.state.unsolved")
        }
    }

    var rowColor: Color {
        switch self {
        case .new: Trace.Colors.text2
        case .open: Trace.Colors.benText
        case .solved: Trace.Colors.successText
        case .unsolved: Trace.Colors.text2
        }
    }

    static func of(_ file: CaseFile, progress: CaseProgress?, saved: SavedInvestigation?) -> CaseCardState {
        if let saved { return .open(remaining: saved.remainingSeconds, pieces: saved.snapshot.notebook.count) }
        guard let progress, progress.plays > 0 else { return .new }
        return progress.solved ? .solved : .unsolved
    }
}

// MARK: - 01 · Bureau

/// The Bureau (§6-01): the logo mention and the investigator's avatar (→ profile), « Bonjour,
/// {Prénom} », the modes' segmented control, then the mode's content — ENQUÊTES: one large
/// CaseCard (the case in progress, or the next one) and « Autres affaires »; ALIBI: the checks;
/// HISTOIRE: the story's card. Alibi and Histoire stay locked (01b) until the player is assigned
/// to the BEN, as before the redesign. One primary button per mode.
struct BureauView: View {
    let identity: PlayerIdentity
    @Binding var mode: DeskMode
    /// Alibi and Histoire are open (the player was assigned after the first #001 report).
    let modesUnlocked: Bool
    /// Shown in the locked modes' condition (« Disponible après #001 »).
    let firstNumber: Int
    let cases: [CaseFile]
    let progress: [String: CaseProgress]
    /// Finished attempts (the data of a played case's card).
    let attempts: [Attempt]
    /// The investigation in progress when it is a main-mode case.
    let resumable: (saved: SavedInvestigation, file: CaseFile)?
    /// Seconds of each case at its intended level (« Temps détendu » included), by case id.
    let durations: [String: Int]
    /// The case whose report was just classified as solved: its card shows, and the RÉSOLU stamp
    /// falls on it (§6-12, the only stamp of the interface).
    let justFiled: String?
    let alibiCases: [CaseFile]
    let alibiInProgressID: String?
    let story: StoryDeskSummary
    let onOpen: (CaseFile) -> Void
    let onResume: () -> Void
    let onReport: (CaseFile) -> Void
    let onAlibi: (CaseFile) -> Void
    let onStory: () -> Void
    /// The Histoire segment is on screen: the story's save is loaded for its card.
    let onStoryVisible: () -> Void
    let onProfile: () -> Void
    let onTab: (DeskTab) -> Void

    @State private var stampLanded = false
    @State private var appeared = false
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    @AppStorage(Preferences.reduceMotionKey) private var appReduceMotion = false

    private var still: Bool { systemReduceMotion || appReduceMotion }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    header
                    ModeSegments(selection: $mode, locked: modesUnlocked ? [] : [.alibi, .story])
                    modeContent
                        .id(mode)
                        .transition(.opacity)
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 24)
                .opacity(appeared ? 1 : 0)
            }
            .scrollBounceBehavior(.basedOnSize)
            DeskTabBar(selected: .bureau, onSelect: onTab)
        }
        .background(DeskBackdrop())
        .animation(still ? .easeOut(duration: 0.2) : Trace.Motion.tab, value: mode)
        .task(id: mode) {
            if mode == .story, modesUnlocked { onStoryVisible() }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.2)) { appeared = true }
        }
    }

    // MARK: Header

    /// « CONCLUDE : ENQUÊTES » + the 36 pt avatar (→ profile), then « Bonjour, {Prénom} ».
    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center, spacing: 12) {
                LogoText()
                Spacer(minLength: 8)
                Button(action: onProfile) {
                    PortraitOrInitials(image: ArtLibrary.image(identity.portraitName), initials: identity.id.initials,
                                       width: Self.avatar, height: Self.avatar)
                        .clipShape(Circle())
                        .overlay(Circle().strokeBorder(Trace.Colors.line, lineWidth: 1))
                        .frame(width: Trace.Height.hit, height: Trace.Height.hit)
                        .contentShape(Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text(verbatim: "\(L10n.t("tab.investigator")), \(identity.id.fullName)"))
                .accessibilityIdentifier("home.profile")
            }
            Text(L10n.f("desk.hello", identity.id.firstName))
                .font(Trace.Fonts.title)
                .foregroundStyle(Trace.Colors.text)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)
                .accessibilityIdentifier("home.title")
        }
    }

    private static let avatar: CGFloat = 36

    // MARK: Mode content

    @ViewBuilder
    private var modeContent: some View {
        switch mode {
        case .investigations:
            investigations
        case .alibi:
            if modesUnlocked {
                AlibiDeskView(cases: alibiCases, progress: progress, inProgressID: alibiInProgressID,
                              onOpen: onAlibi, onResume: onResume)
            } else {
                lockedModes(.alibi)
            }
        case .story:
            if modesUnlocked {
                StoryDeskCard(summary: story, onOpen: onStory)
            } else {
                lockedModes(.story)
            }
        }
    }

    // MARK: Enquêtes

    /// Every case is solved and nothing is in progress.
    private var allClosed: Bool {
        resumable == nil && !cases.isEmpty && cases.allSatisfy { progress[$0.id]?.solved == true }
    }

    /// The large card: the case just classified (its stamp), the case in progress, or the next
    /// case not played (else the first one not solved).
    private var featured: CaseFile? {
        if let justFiled, let file = cases.first(where: { $0.id == justFiled }) { return file }
        if let resumable { return resumable.file }
        if allClosed { return nil }
        return cases.first { progress[$0.id] == nil } ?? cases.first { progress[$0.id]?.solved != true }
    }

    @ViewBuilder
    private var investigations: some View {
        let featured = self.featured
        VStack(alignment: .leading, spacing: 16) {
            if cases.isEmpty {
                SkeletonCard()
            } else if let file = featured {
                CaseCard(file: file,
                         state: state(of: file),
                         durationSeconds: durations[file.id] ?? file.durationSeconds,
                         report: ProgressStore.reportAttempt(of: file.id, in: attempts),
                         stamp: stamp(for: file),
                         onOpen: { onOpen(file) },
                         onResume: onResume,
                         onReport: { onReport(file) },
                         onStampLanded: { stampLanded = true })
                if justFiled == file.id, let next = nextCase(after: file) {
                    Button(L10n.f("desk.nextCase", shownNumber(next.number))) { onOpen(next) }
                        .buttonStyle(CTAButtonStyle())
                        .accessibilityIdentifier("desk.next")
                }
            } else {
                allClosedCard
            }
            otherCases(excluding: featured)
        }
    }

    private func state(of file: CaseFile) -> CaseCardState {
        CaseCardState.of(file, progress: progress[file.id], saved: resumable?.file.id == file.id ? resumable?.saved : nil)
    }

    private func stamp(for file: CaseFile) -> CaseCard.Stamp {
        guard justFiled == file.id, state(of: file) == .solved else { return .none }
        return stampLanded ? .landed : .falling
    }

    private func nextCase(after file: CaseFile) -> CaseFile? {
        cases.first { $0.id != file.id && progress[$0.id] == nil }
            ?? cases.first { $0.id != file.id && progress[$0.id]?.solved != true }
    }

    /// « Toutes les affaires sont classées » + a link to the Archives.
    private var allClosedCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(L10n.t("desk.allClosedTitle"))
                .font(Trace.Fonts.serifTitle(24))
                .foregroundStyle(Trace.Colors.text)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)
            Text(L10n.t("desk.allClosed"))
                .font(Trace.Fonts.callout)
                .foregroundStyle(Trace.Colors.text2)
                .fixedSize(horizontal: false, vertical: true)
            Button(L10n.t("desk.openArchives")) { onTab(.archives) }
                .buttonStyle(TextLinkStyle())
                .accessibilityIdentifier("desk.archives")
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .benCard(radius: Trace.Radius.largeCard)
    }

    /// « Autres affaires »: 50 pt rows.
    @ViewBuilder
    private func otherCases(excluding featured: CaseFile?) -> some View {
        let others = cases.filter { $0.id != featured?.id }
        if !others.isEmpty {
            VStack(alignment: .leading, spacing: 0) {
                SectionHeader(title: L10n.t("desk.otherCases"))
                VStack(spacing: 0) {
                    ForEach(Array(others.enumerated()), id: \.element.id) { index, file in
                        CaseListRow(file: file, state: state(of: file), divider: index < others.count - 1) {
                            onOpen(file)
                        }
                    }
                }
                .benCard()
            }
            .padding(.top, 8)
        }
    }

    // MARK: 01b · locked modes

    /// A locked mode (§6-13 « Mode verrouillé »): its name, its condition, then the three
    /// ModeCards (§6-01b) — Enquêtes active, the other two with their condition.
    private func lockedModes(_ locked: DeskMode) -> some View {
        let solved = cases.filter { progress[$0.id]?.solved == true }.count
        return VStack(alignment: .leading, spacing: 12) {
            EmptyPage(title: locked.title, tip: L10n.f("mode.lockedMessage", shownNumber(firstNumber)))
            ModeCard(mode: .investigations,
                     subtitle: L10n.t("modecard.investigations.subtitle"),
                     line: L10n.t("modecard.investigations.line"),
                     meta: L10n.f("modecard.investigations.meta", solved, cases.count),
                     active: true, locked: false) { mode = .investigations }
            ModeCard(mode: .alibi,
                     subtitle: L10n.t("modecard.alibi.subtitle"),
                     line: L10n.t("alibi.pitch"),
                     meta: L10n.t("mode.locked"),
                     active: false, locked: true) {}
            ModeCard(mode: .story,
                     subtitle: L10n.t("modecard.story.subtitle"),
                     line: L10n.t("mode.story.promise"),
                     meta: L10n.t("mode.locked"),
                     active: false, locked: true) {}
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("desk.modes")
    }
}

// MARK: - Segmented control of the modes

/// Enquêtes · Alibi · Histoire in a `surface` track (radius 12), the active segment on `surface3`
/// (radius 9); 40 pt segments in 44 pt targets. Same look as `DividerTabs`, with one identifier per
/// mode (`mode.investigations`, `mode.alibi`, `mode.story`). A locked mode shows a lock; it can
/// still be selected, to read its condition (01b).
private struct ModeSegments: View {
    @Binding var selection: DeskMode
    let locked: Set<DeskMode>
    @Namespace private var slider

    var body: some View {
        HStack(spacing: 0) {
            ForEach(DeskMode.allCases, id: \.self) { mode in
                let active = mode == selection
                Button {
                    selection = mode
                    Haptics.selection()
                } label: {
                    HStack(spacing: 5) {
                        if locked.contains(mode) {
                            Image(systemName: "lock")
                                .font(.system(size: 11, weight: .semibold))
                                .accessibilityHidden(true)
                        }
                        Text(mode.title)
                            .font(active ? .custom(Trace.FontName.sansSemibold, size: 14, relativeTo: .subheadline)
                                         : .custom(Trace.FontName.sans, size: 14, relativeTo: .subheadline))
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
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
                .accessibilityHint(locked.contains(mode) ? Text(L10n.t("mode.locked")) : Text(verbatim: ""))
                .accessibilityIdentifier(mode.identifier)
            }
        }
        .padding(2)
        .background(RoundedRectangle(cornerRadius: Trace.Radius.segmented, style: .continuous).fill(Trace.Colors.surface))
    }
}

// MARK: - ModeCard (§5)

/// A mode: a 48 pt outlined glyph in benText, the headline, a subtitle in benText, one line, the
/// meta (its condition when locked). Active: 1.5 pt ben rule. Locked: 60 %.
struct ModeCard: View {
    let mode: DeskMode
    let subtitle: String
    let line: String
    let meta: String?
    let active: Bool
    let locked: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(alignment: .top, spacing: 14) {
                Image(systemName: mode.symbol)
                    .font(.system(size: 30, weight: .regular))
                    .foregroundStyle(Trace.Colors.benText)
                    .frame(width: 48, height: 48)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 4) {
                    Text(mode.title)
                        .font(Trace.Fonts.headline)
                        .foregroundStyle(Trace.Colors.text)
                    Text(subtitle)
                        .font(Trace.Fonts.callout)
                        .foregroundStyle(Trace.Colors.benText)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(line)
                        .font(Trace.Fonts.body)
                        .foregroundStyle(Trace.Colors.text2)
                        .fixedSize(horizontal: false, vertical: true)
                    if let meta {
                        HStack(spacing: 5) {
                            if locked {
                                Image(systemName: "lock").font(.system(size: 11, weight: .semibold)).accessibilityHidden(true)
                            }
                            Text(meta)
                        }
                        .font(Trace.Fonts.caption)
                        .foregroundStyle(Trace.Colors.text2)
                        .padding(.top, 2)
                    }
                }
                Spacer(minLength: 0)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .benCard()
            .overlay(
                RoundedRectangle(cornerRadius: Trace.Radius.card, style: .continuous)
                    .strokeBorder(Trace.Colors.ben, lineWidth: active ? 1.5 : 0)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(PressableStyle())
        .disabled(locked)
        .opacity(locked ? 0.6 : 1)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(active ? .isSelected : [])
        .accessibilityIdentifier("modecard.\(mode.rawValue)")
    }
}

// MARK: - CaseCard (§5)

/// A case: the photo area (176 pt, cover or striped placeholder) with its state pill, « #001 »,
/// the title, « Lieu · Type », three data (difficulty, duration or time left, pieces) and one
/// button — Nouvelle: [Ouvrir le dossier] · En cours: [Reprendre] · Résolue: « Voir le rapport »
/// (secondary). The RÉSOLU stamp falls on the photo when the case was just classified.
struct CaseCard: View {
    enum Stamp { case none, falling, landed }

    let file: CaseFile
    let state: CaseCardState
    let durationSeconds: Int
    /// The attempt a played case's data comes from (its last solved one, else its last one).
    var report: Attempt? = nil
    var stamp: Stamp = .none
    let onOpen: () -> Void
    let onResume: () -> Void
    let onReport: () -> Void
    var onStampLanded: () -> Void = {}
    @Environment(\.dynamicTypeSize) private var typeSize

    private static let photoHeight: CGFloat = 176
    private static let stampAsset = "stamp_resolu_rouge_marque"

    var body: some View {
        let facts = DossierFacts(file: file)
        VStack(alignment: .leading, spacing: 0) {
            Color.clear
                .frame(height: Self.photoHeight)
                .frame(maxWidth: .infinity)
                .overlay { CasePhoto(caseNumber: file.number) }
                .clipped()
                .overlay(alignment: .topLeading) { pill.padding(12) }
                .overlay {
                    if stamp != .none {
                        CardStamp(falling: stamp == .falling, asset: Self.stampAsset, onLanded: onStampLanded)
                    }
                }
            VStack(alignment: .leading, spacing: 6) {
                Text(verbatim: "#\(shownNumber(file.number))")
                    .font(Trace.Fonts.data)
                    .foregroundStyle(Trace.Colors.benText)
                    .accessibilityLabel(Text(fileLabel(file.number)))
                Text(file.title.capitalizedFirst)
                    .font(Trace.Fonts.title)
                    .foregroundStyle(Trace.Colors.text)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityAddTraits(.isHeader)
                let place = Self.placeLine(facts)
                if !place.isEmpty {
                    Text(place)
                        .font(Trace.Fonts.callout)
                        .foregroundStyle(Trace.Colors.text2)
                        .fixedSize(horizontal: false, vertical: true)
                }
                metaGrid(facts)
                    .padding(.top, 12)
                actions
                    .padding(.top, 16)
            }
            .padding(16)
        }
        .clipShape(RoundedRectangle(cornerRadius: Trace.Radius.largeCard, style: .continuous))
        .benCard(radius: Trace.Radius.largeCard)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("home.card")
    }

    /// « Marseille · Disparition »
    static func placeLine(_ facts: DossierFacts) -> String {
        [facts.city, facts.category.capitalizedFirst].filter { !$0.isEmpty }.joined(separator: " · ")
    }

    private var pill: some View {
        let badge = state.badge
        return StatusBadge(text: badge.text, color: badge.color, symbol: badge.symbol)
            .background(Capsule().fill(Trace.Colors.bg.opacity(0.85)))
            .accessibilityIdentifier("home.state")
    }

    // MARK: Data

    /// Difficulté · Durée (or Temps restant) · Pièces; one column at accessibility sizes.
    private func metaGrid(_ facts: DossierFacts) -> some View {
        let layout = typeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 12))
            : AnyLayout(HStackLayout(alignment: .top, spacing: 12))
        return layout {
            cell(L10n.t("dossier.difficulty")) {
                DifficultyMeter(level: facts.rating)
            }
            cell(timeLabel) {
                Text(PhoneFormat.countdown(timeValue))
                    .font(Trace.Fonts.fieldValueLarge)
                    .foregroundStyle(Trace.Colors.text)
            }
            cell(L10n.t("case.meta.pieces")) {
                Text(verbatim: piecesValue)
                    .font(Trace.Fonts.fieldValueLarge)
                    .foregroundStyle(Trace.Colors.text)
                    .accessibilityIdentifier("home.resumeMeta")
            }
        }
    }

    private func cell<Content: View>(_ label: String, @ViewBuilder _ content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(Trace.Fonts.caption)
                .foregroundStyle(Trace.Colors.text2)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    private var timeLabel: String {
        if case .open = state { return L10n.t("result.timeLeft") }
        return L10n.t("desk.duration")
    }

    private var timeValue: Double {
        if case .open(let remaining, _) = state { return remaining }
        return Double(durationSeconds)
    }

    /// Pieces filed (in progress) or found (played) over the case's counted pieces.
    private var piecesValue: String {
        let total = Self.countedPieces(file)
        switch state {
        case .open(_, let pieces):
            return pieces > total ? "\(pieces)" : "\(pieces)/\(total)"
        case .solved, .unsolved:
            if let report { return "\(report.found)/\(report.total)" }
            return "—/\(total)"
        case .new:
            return "0/\(total)"
        }
    }

    /// The pieces the verdict counts (every piece but the false leads).
    static func countedPieces(_ file: CaseFile) -> Int {
        file.evidence.filter { $0.importance != .falseLead }.count
    }

    // MARK: Actions

    @ViewBuilder
    private var actions: some View {
        switch state {
        case .new, .unsolved:
            Button(L10n.t("home.start"), action: onOpen)
                .buttonStyle(CTAButtonStyle())
                .accessibilityIdentifier("home.start")
        case .open(let remaining, let pieces):
            Button(L10n.t("desk.resume"), action: onResume)
                .buttonStyle(CTAButtonStyle())
                .accessibilityLabel(Text(verbatim: "\(L10n.t("desk.resume")), \(PhoneFormat.countdown(remaining)), \(L10n.f("dossier.piecesCount", pieces))"))
                .accessibilityIdentifier("home.resume")
        case .solved:
            Button(L10n.t("desk.report"), action: onReport)
                .buttonStyle(CTAButtonStyle(kind: .outline))
                .accessibilityIdentifier("home.report")
        }
    }
}

/// The RÉSOLU PNG on a case card (§6-12): scale 1.3 → 1 in 180 ms (easeIn) then a 60 ms settle,
/// rigid haptic and the stamp's sound; reduced motion: a 200 ms fade.
private struct CardStamp: View {
    let falling: Bool
    let asset: String
    let onLanded: () -> Void
    @State private var phase = 0
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    @AppStorage(Preferences.reduceMotionKey) private var appReduceMotion = false

    var body: some View {
        let still = systemReduceMotion || appReduceMotion
        StampImage(asset: asset, label: L10n.t("stamp.solved"), width: 150, onPaper: false, angle: -8,
                   color: Trace.Colors.successText)
            .scaleEffect(still ? 1 : (phase == 0 ? 1.3 : phase == 1 ? 0.98 : 1))
            .opacity(phase > 0 ? 1 : 0)
            .allowsHitTesting(false)
            .task {
                guard falling else {
                    phase = 2
                    return
                }
                try? await Task.sleep(for: .milliseconds(450))
                if still {
                    withAnimation(.easeOut(duration: 0.2)) { phase = 2 }
                } else {
                    withAnimation(Trace.Motion.stamp) { phase = 1 }
                    try? await Task.sleep(for: .milliseconds(180))
                    withAnimation(.easeOut(duration: 0.06)) { phase = 2 }
                }
                AudioDirector.shared.play(.stamp, volume: 0.9)
                Haptics.rigid()
                onLanded()
            }
    }
}

/// Loading (§6-01 « chargement »): surface blocks, no text.
private struct SkeletonCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Trace.Colors.surface2.frame(height: 176)
            VStack(alignment: .leading, spacing: 10) {
                RoundedRectangle(cornerRadius: 4).fill(Trace.Colors.surface2).frame(width: 48, height: 12)
                RoundedRectangle(cornerRadius: 6).fill(Trace.Colors.surface2).frame(width: 220, height: 26)
                RoundedRectangle(cornerRadius: 4).fill(Trace.Colors.surface2).frame(width: 160, height: 14)
                RoundedRectangle(cornerRadius: Trace.Radius.button).fill(Trace.Colors.surface2).frame(height: Trace.Height.button)
                    .padding(.top, 12)
            }
            .padding([.horizontal, .bottom], 16)
        }
        .clipShape(RoundedRectangle(cornerRadius: Trace.Radius.largeCard, style: .continuous))
        .benCard(radius: Trace.Radius.largeCard)
        .accessibilityHidden(true)
    }
}

/// A case under « Autres affaires » (50 pt): « #00N · Titre », its state; a locked case shows
/// its condition (« Après #00N ») and, once touched, « Disponible après la conclusion du
/// dossier #00N. » (§6-13). No case is locked today: the Bureau passes no condition.
struct CaseListRow: View {
    let file: CaseFile
    let state: CaseCardState
    var lockedAfter: Int? = nil
    var divider = true
    let action: () -> Void
    @State private var showsCondition = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                if lockedAfter != nil {
                    withAnimation(.easeOut(duration: 0.2)) { showsCondition.toggle() }
                } else {
                    action()
                }
            } label: {
                HStack(alignment: .center, spacing: 10) {
                    Text(verbatim: "#\(shownNumber(file.number))")
                        .font(Trace.Fonts.data)
                        .foregroundStyle(lockedAfter == nil ? Trace.Colors.benText : Trace.Colors.text2)
                    Text(file.title.capitalizedFirst)
                        .font(Trace.Fonts.callout)
                        .foregroundStyle(lockedAfter == nil ? Trace.Colors.text : Trace.Colors.text2)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 8)
                    trailing
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 6)
                .frame(maxWidth: .infinity, minHeight: Trace.Height.row, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(PressableStyle())
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text(verbatim: "\(fileLabel(file.number)), \(file.title.capitalizedFirst), \(stateText)"))
            .accessibilityAddTraits(.isButton)
            .accessibilityIdentifier("case.\(file.id)")
            if showsCondition, let lockedAfter {
                VStack(alignment: .leading, spacing: 2) {
                    Text(file.title.capitalizedFirst)
                        .font(Trace.Fonts.headline)
                        .foregroundStyle(Trace.Colors.text)
                    Text(L10n.f("case.lockedMessage", shownNumber(lockedAfter)))
                        .font(Trace.Fonts.callout)
                        .foregroundStyle(Trace.Colors.text2)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .transition(.opacity)
                .accessibilityElement(children: .combine)
            }
        }
        .overlay(alignment: .bottom) {
            if divider { Rectangle().fill(Trace.Colors.line).frame(height: 1).padding(.leading, 16) }
        }
    }

    private var stateText: String {
        if let lockedAfter { return L10n.f("desk.lockedAfter", shownNumber(lockedAfter)) }
        return state.rowText
    }

    @ViewBuilder
    private var trailing: some View {
        HStack(spacing: 6) {
            if lockedAfter != nil {
                Image(systemName: "lock").font(.system(size: 12, weight: .semibold))
                Text(stateText).font(Trace.Fonts.caption)
            } else {
                Text(stateText).font(Trace.Fonts.caption)
                Image(systemName: "chevron.right").font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Trace.Colors.text3)
            }
        }
        .foregroundStyle(lockedAfter == nil ? state.rowColor : Trace.Colors.text2)
        .accessibilityHidden(true)
    }
}

// MARK: - Histoire

/// The story's card on the Bureau: the chapter in progress (or « Créer votre enquêteur »), its
/// progress, and the button that opens the story's hub.
private struct StoryDeskCard: View {
    let summary: StoryDeskSummary
    let onOpen: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Color.clear
                .frame(height: 120)
                .frame(maxWidth: .infinity)
                .overlay { BenStripes() }
                .overlay {
                    Image(systemName: DeskMode.story.symbol)
                        .font(.system(size: 40, weight: .regular))
                        .foregroundStyle(Trace.Colors.benText)
                        .accessibilityHidden(true)
                }
                .clipped()
            VStack(alignment: .leading, spacing: 8) {
                Text(L10n.t("desk.mode.story")).fieldLabel()
                Text(title)
                    .font(Trace.Fonts.serifTitle(24))
                    .foregroundStyle(Trace.Colors.text)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityAddTraits(.isHeader)
                Text(L10n.t("mode.story.promise"))
                    .font(Trace.Fonts.callout)
                    .foregroundStyle(Trace.Colors.text2)
                    .fixedSize(horizontal: false, vertical: true)
                if summary.hasInvestigator {
                    progressBar
                        .padding(.top, 4)
                }
                Button(summary.hasInvestigator ? L10n.t("desk.story.continue") : L10n.t("desk.story.start"), action: onOpen)
                    .buttonStyle(CTAButtonStyle())
                    .accessibilityIdentifier("story.open")
                    .padding(.top, 8)
            }
            .padding(16)
        }
        .clipShape(RoundedRectangle(cornerRadius: Trace.Radius.largeCard, style: .continuous))
        .benCard(radius: Trace.Radius.largeCard)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("desk.story")
    }

    private var title: String {
        guard summary.hasInvestigator else { return L10n.t("mode.story.create") }
        return summary.chapterLine ?? L10n.t("mode.story.promise")
    }

    /// A 2 pt bar, no percentage text.
    private var progressBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Trace.Colors.surface3)
                Capsule().fill(Trace.Colors.ben).frame(width: geo.size.width * min(1, max(0, summary.progress)))
            }
        }
        .frame(height: 2)
        .accessibilityElement()
        .accessibilityValue(Text(verbatim: "\(Int((summary.progress * 100).rounded())) %"))
    }
}

// MARK: - Archives

/// Every case as a flat card: « #00N », title, « Lieu · Type », its state as a StatusBadge (symbol +
/// word), and one line (difficulty, date and mark, attempts). Filters in a segmented control.
struct ArchivesView: View {
    let cases: [CaseFile]
    let progress: [String: CaseProgress]
    let attempts: [Attempt]
    let savedCaseID: String?
    let onOpen: (CaseFile) -> Void
    let onTab: (DeskTab) -> Void

    enum Filter: Hashable { case all, open, solved, unsolved }
    @State private var filter: Filter = .all

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    BenScreenHeader(back: L10n.t("tab.bureau"), backID: "archives.back", onBack: { onTab(.bureau) },
                                    title: L10n.t("archives.title"), titleID: "archives.title")
                    Text(L10n.f("archives.count", cases.count))
                        .font(Trace.Fonts.caption)
                        .foregroundStyle(Trace.Colors.text2)
                    DividerTabs(tabs: [(value: Filter.all, label: L10n.t("archives.all")),
                                       (value: Filter.open, label: L10n.t("archives.open")),
                                       (value: Filter.solved, label: L10n.t("archives.solved")),
                                       (value: Filter.unsolved, label: L10n.t("archives.unsolved"))],
                                selection: $filter,
                                identifier: "archives.filter")
                    LazyVStack(spacing: 12) {
                        ForEach(visible) { file in
                            ArchiveCard(file: file, status: status(file), progress: progress[file.id],
                                        lastAttempt: attempts.last { $0.caseID == file.id }) { onOpen(file) }
                        }
                        if visible.isEmpty {
                            EmptyPage(title: L10n.t("archives.empty"), tip: L10n.t("archives.emptyTip"))
                                .padding(.horizontal, 16)
                                .benCard()
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 24)
            }
            DeskTabBar(selected: .archives, onSelect: onTab)
        }
        .background(DeskBackdrop())
    }

    private func status(_ file: CaseFile) -> DossierStatus {
        DossierStatus.of(file, progress: progress[file.id], savedCaseID: savedCaseID)
    }

    private var visible: [CaseFile] {
        cases.filter { file in
            switch filter {
            case .all: true
            case .open: status(file) == .open || status(file) == .new
            case .solved: status(file) == .solved
            case .unsolved: status(file) == .unsolved
            }
        }
    }
}

/// An archive card: flat `surface`, the state as a StatusBadge.
struct ArchiveCard: View {
    let file: CaseFile
    let status: DossierStatus
    let progress: CaseProgress?
    let lastAttempt: Attempt?
    let onOpen: () -> Void

    var body: some View {
        let facts = DossierFacts(file: file)
        Button(action: onOpen) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .center) {
                    Text(verbatim: "#\(shownNumber(file.number))")
                        .font(Trace.Fonts.data)
                        .foregroundStyle(Trace.Colors.benText)
                    Spacer(minLength: 8)
                    badge
                }
                Text(file.title.capitalizedFirst)
                    .font(Trace.Fonts.headline)
                    .foregroundStyle(Trace.Colors.text)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                let place = CaseCard.placeLine(facts)
                if !place.isEmpty {
                    Text(place)
                        .font(Trace.Fonts.caption)
                        .foregroundStyle(Trace.Colors.text2)
                        .fixedSize(horizontal: false, vertical: true)
                }
                footer(facts)
                    .padding(.top, 4)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .benCard()
            .contentShape(Rectangle())
        }
        .buttonStyle(PressableStyle())
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("case.\(file.id)")
    }

    private var badge: some View {
        let state: CaseCardState = switch status {
        case .new: .new
        case .open: .open(remaining: 0, pieces: 0)
        case .solved: .solved
        case .unsolved: .unsolved
        }
        let b = state.badge
        return StatusBadge(text: b.text, color: b.color, symbol: b.symbol)
    }

    @ViewBuilder
    private func footer(_ facts: DossierFacts) -> some View {
        switch status {
        case .new, .open:
            DifficultyMeter(level: facts.rating)
        case .solved:
            Text(L10n.f("archives.closedOn", lastAttempt.map { $0.date.formatted(.dateTime.day(.twoDigits).month(.twoDigits)) } ?? "—",
                        progress?.bestScore ?? 0))
                .font(Trace.Fonts.data)
                .foregroundStyle(Trace.Colors.text2)
        case .unsolved:
            Text(L10n.f("archives.attempts", progress?.plays ?? 0))
                .font(Trace.Fonts.caption)
                .foregroundStyle(Trace.Colors.text2)
        }
    }
}

// MARK: - Enquêteur (profile)

/// The investigator's profile (tab 3). Before the assignment (screen 12): identity only. After it:
/// service number and rank, the career (ReportCards), the cases, the distinctions and the history.
/// Changing investigator reuses « Qui enquête ? »; the settings are at the bottom.
struct InvestigatorView: View {
    let attempts: [Attempt]
    let cases: [CaseFile]
    let identity: PlayerIdentity
    let assigned: Bool
    let onChangeIdentity: (PlayerIdentity) -> Void
    let onSettings: () -> Void
    let onTab: (DeskTab) -> Void

    @State private var changing = false
    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        let summary = ProgressStore.summary(of: attempts)
        let rank = Rank.forSolved(summary.values.filter(\.solved).count)
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    BenScreenHeader(back: L10n.t("tab.bureau"), backID: "profile.back", onBack: { onTab(.bureau) },
                                    title: L10n.t("investigator.title"), titleID: "profile.view")
                    identityCard(rank: rank)
                    if assigned {
                        career(rank: rank, summary: summary)
                        casesList(summary: summary)
                        distinctions
                        history
                    }
                    Button(assigned ? L10n.t("profile.changeIdentity") : L10n.t("profile.changeInvestigator")) {
                        changing = true
                    }
                    .buttonStyle(CTAButtonStyle(kind: .outline))
                    .accessibilityIdentifier("profile.changeIdentity")
                    settingsRow
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 24)
            }
            DeskTabBar(selected: .investigator, onSelect: onTab)
        }
        .background(DeskBackdrop())
        .fullScreenCover(isPresented: $changing) {
            WhoInvestigatesScreen(initial: identity, allowsAppearance: assigned,
                                  onContinue: { chosen in
                                      onChangeIdentity(chosen)
                                      changing = false
                                  },
                                  onBack: { changing = false })
        }
    }

    private var columns: [GridItem] {
        typeSize.isAccessibilitySize ? [GridItem(.flexible())] : [GridItem(.flexible(), spacing: 12), GridItem(.flexible())]
    }

    // MARK: Identity

    /// The photo (or initials), name and title; after the assignment, the service number, the rank
    /// (a badge — the only stamp of the interface is RÉSOLU), the short bio and the date.
    private func identityCard(rank: Rank) -> some View {
        let layout = typeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 14))
            : AnyLayout(HStackLayout(alignment: .top, spacing: 16))
        return VStack(alignment: .leading, spacing: 14) {
            layout {
                PlayerPrint(identity: identity, width: 72)
                VStack(alignment: .leading, spacing: 6) {
                    Text(identity.id.fullName)
                        .font(Trace.Fonts.headline)
                        .foregroundStyle(Trace.Colors.text)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(identity.id.title.capitalizedFirst)
                        .font(Trace.Fonts.caption)
                        .foregroundStyle(Trace.Colors.text2)
                    if assigned {
                        Text(verbatim: identity.id.serviceNumber)
                            .font(Trace.Fonts.data)
                            .foregroundStyle(Trace.Colors.benText)
                            .accessibilityLabel(Text(verbatim: "\(L10n.t("investigator.number")) \(identity.id.serviceNumber)"))
                        StatusBadge(text: rank.title.capitalizedFirst, color: Trace.Colors.benText, symbol: "#")
                    }
                }
                Spacer(minLength: 0)
            }
            if assigned {
                Text(identity.id.bio)
                    .font(Trace.Fonts.callout)
                    .foregroundStyle(Trace.Colors.text2)
                    .fixedSize(horizontal: false, vertical: true)
                if let date = PlayerStore.assignedDate {
                    Text(assignedLine(Self.dotted(date)))
                        .font(Trace.Fonts.caption)
                        .foregroundStyle(Trace.Colors.text2)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .benCard()
        .accessibilityElement(children: .combine)
    }

    /// « Affectée au BEN le 13.09.2026 »
    private func assignedLine(_ date: String) -> String {
        identity.id.isFeminine ? L10n.f("profile.assignedOnF", date) : L10n.f("profile.assignedOnM", date)
    }

    // MARK: Career

    /// « Parcours »: rank, what the next one takes, cases solved, plays, best score, pieces found.
    private func career(rank: Rank, summary: [String: CaseProgress]) -> some View {
        let solved = cases.filter { summary[$0.id]?.solved == true }.count
        let ranked = attempts.filter(\.ranked)
        let best = ranked.map(\.score).max()
        let found = attempts.reduce(0) { $0 + $1.found }
        let total = attempts.reduce(0) { $0 + $1.total }
        return VStack(alignment: .leading, spacing: 0) {
            SectionHeader(title: L10n.t("profile.career"))
            LazyVGrid(columns: columns, alignment: .leading, spacing: 12) {
                ReportCard(label: L10n.t("profile.rank"), value: rank.title.capitalizedFirst, color: Trace.Colors.benText)
                ReportCard(label: L10n.t("profile.solved"), value: "\(solved)/\(cases.count)")
                ReportCard(label: L10n.t("profile.attempts"), value: "\(attempts.count)")
                ReportCard(label: L10n.t("profile.best"), value: best.map { "\($0)/100" } ?? "—")
                ReportCard(label: L10n.t("profile.found"), value: total == 0 ? "—" : "\(found * 100 / total) %")
            }
            Text(nextRankLine(rank: rank, solved: summary.values.filter(\.solved).count))
                .font(Trace.Fonts.caption)
                .foregroundStyle(Trace.Colors.text2)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 10)
        }
    }

    /// « Encore 1 dossier résolu pour INSPECTEUR », or « Rang maximal atteint. »
    private func nextRankLine(rank: Rank, solved: Int) -> String {
        guard let threshold = rank.nextThreshold, let next = Rank(rawValue: rank.rawValue + 1) else {
            return L10n.t("profile.rankMax")
        }
        let left = max(1, threshold - solved)
        return L10n.f("profile.nextRank", L10n.f("profile.casesToGo", left), next.title.capitalizedFirst)
    }

    // MARK: Cases

    /// One 50 pt row per case: #, title, state in words, best mark.
    private func casesList(summary: [String: CaseProgress]) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            SectionHeader(title: L10n.t("menu.cases"))
            VStack(spacing: 0) {
                ForEach(Array(cases.enumerated()), id: \.element.id) { index, file in
                    caseLine(file, progress: summary[file.id], divider: index < cases.count - 1)
                }
            }
            .benCard()
        }
    }

    private func caseLine(_ file: CaseFile, progress: CaseProgress?, divider: Bool) -> some View {
        let state = CaseCardState.of(file, progress: progress, saved: nil)
        return HStack(alignment: .center, spacing: 10) {
            Text(verbatim: "#\(shownNumber(file.number))")
                .font(Trace.Fonts.data)
                .foregroundStyle(Trace.Colors.benText)
            Text(file.title.capitalizedFirst)
                .font(Trace.Fonts.callout)
                .foregroundStyle(state == .new ? Trace.Colors.text2 : Trace.Colors.text)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 8)
            VStack(alignment: .trailing, spacing: 2) {
                Text(state.rowText)
                    .font(Trace.Fonts.caption)
                    .foregroundStyle(state.rowColor)
                if let progress, progress.bestScore > 0 {
                    Text(verbatim: "\(progress.bestScore)/100")
                        .font(Trace.Fonts.data)
                        .foregroundStyle(Trace.Colors.text)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
        .frame(minHeight: Trace.Height.row)
        .overlay(alignment: .bottom) {
            if divider { Rectangle().fill(Trace.Colors.line).frame(height: 1).padding(.leading, 16) }
        }
        .accessibilityElement(children: .combine)
    }

    // MARK: Distinctions

    private var distinctions: some View {
        VStack(alignment: .leading, spacing: 0) {
            SectionHeader(title: L10n.t("profile.badges"))
            LazyVGrid(columns: columns, alignment: .leading, spacing: 12) {
                mention(L10n.t("profile.badgeFirst"), earned: attempts.contains { $0.solved })
                mention(L10n.t("profile.badgeNoHelp"), earned: attempts.contains { $0.solved && $0.ranked && $0.hintsUsed == 0 })
                mention(L10n.t("profile.badgePerfect"), earned: attempts.contains { $0.ranked && $0.score >= 100 })
                mention(L10n.t("profile.badgeThorough"), earned: attempts.contains { $0.total > 0 && $0.found == $0.total })
            }
        }
    }

    private func mention(_ title: String, earned: Bool) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(Trace.Fonts.callout)
                .foregroundStyle(earned ? Trace.Colors.text : Trace.Colors.text2)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
            if earned {
                StatusBadge(text: L10n.t("profile.badgeEarned"), color: Trace.Colors.successText, symbol: "✓")
            } else {
                StatusBadge(text: L10n.t("profile.badgeNotYet"), color: Trace.Colors.text2, symbol: "·")
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: 96, alignment: .topLeading)
        .benCard()
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(earned ? .isSelected : [])
    }

    // MARK: History

    /// The last finished attempts, newest first: date, case, result, mark.
    private var history: some View {
        let known = attempts.filter { attempt in cases.contains { $0.id == attempt.caseID } }
        let recent = Array(known.sorted { $0.date > $1.date }.prefix(Self.historyLength))
        return VStack(alignment: .leading, spacing: 0) {
            SectionHeader(title: L10n.t("profile.history"))
            VStack(spacing: 0) {
                if recent.isEmpty {
                    Text(L10n.t("archive.emptyMessage"))
                        .font(Trace.Fonts.callout)
                        .foregroundStyle(Trace.Colors.text2)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    ForEach(Array(recent.enumerated()), id: \.element.id) { index, attempt in
                        historyLine(attempt, divider: index < recent.count - 1)
                    }
                }
            }
            .benCard()
        }
    }

    private static let historyLength = 12

    private func historyLine(_ attempt: Attempt, divider: Bool) -> some View {
        let file = cases.first { $0.id == attempt.caseID }
        let result = attempt.solved ? "✓ " + L10n.t("case.state.solved") : "✕ " + L10n.t("case.state.unsolved")
        let score = attempt.ranked ? "\(attempt.score)/100" : L10n.t("archive.unranked")
        return HStack(alignment: .firstTextBaseline, spacing: 12) {
            Text(Self.dotted(attempt.date))
                .font(Trace.Fonts.data)
                .foregroundStyle(Trace.Colors.text2)
            VStack(alignment: .leading, spacing: 2) {
                Text(verbatim: "#\(shownNumber(file?.number ?? 0)) · \(file?.title.capitalizedFirst ?? "")")
                    .font(Trace.Fonts.callout)
                    .foregroundStyle(Trace.Colors.text)
                    .fixedSize(horizontal: false, vertical: true)
                Text(verbatim: "\(result) · \(score)")
                    .font(Trace.Fonts.caption)
                    .foregroundStyle(attempt.solved ? Trace.Colors.successText : Trace.Colors.text2)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .overlay(alignment: .bottom) {
            if divider { Rectangle().fill(Trace.Colors.line).frame(height: 1).padding(.leading, 16) }
        }
        .accessibilityElement(children: .combine)
    }

    /// JJ.MM.AAAA
    private static func dotted(_ date: Date) -> String {
        let parts = Calendar.current.dateComponents([.day, .month, .year], from: date)
        return String(format: "%02ld.%02ld.%04ld", parts.day ?? 0, parts.month ?? 0, parts.year ?? 0)
    }

    // MARK: Settings

    private var settingsRow: some View {
        Button(action: onSettings) {
            HStack(spacing: 12) {
                Image(systemName: "gearshape")
                    .accessibilityHidden(true)
                Text(L10n.t("menu.settings"))
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(Trace.Colors.text3)
                    .accessibilityHidden(true)
            }
            .font(Trace.Fonts.body)
            .foregroundStyle(Trace.Colors.text)
            .padding(.horizontal, 16)
            .frame(minHeight: Trace.Height.row)
            .benCard(Trace.Colors.surface2, radius: Trace.Radius.button)
            .contentShape(Rectangle())
        }
        .buttonStyle(PressableStyle())
        .accessibilityIdentifier("menu.settings")
    }
}
#endif
