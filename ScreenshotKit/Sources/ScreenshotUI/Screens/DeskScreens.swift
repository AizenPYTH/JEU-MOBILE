#if os(iOS)
import SwiftUI
import UIKit
import CaseEngine

// The BEN outside an investigation, V4 « Dossier lisible » (docs/design_v4 §3, §4-01): the Bureau
// — a kraft folder laid on the dark desk under its classeur tabs (Enquêtes · Alibi · Histoire), the
// other cases as folder stubs below — then the Archives (a kraft drawer of case sheets with their
// stamps) and the investigator's file (the BEN card on paper). Behaviour, states and flows are the
// V3 ones (docs/design_ux_v3); only the rendering changed. The tab bar BUREAU · ARCHIVES ·
// ENQUÊTEUR stays at the bottom.

// MARK: - Type roles of these screens (V4 §2 « Typographie »)

extension Trace.Fonts {
    /// « Bonjour, Inspectrice Morel »: Newsreader 28/600.
    static let deskGreeting = Font.custom(Trace.FontName.serifSemibold, size: 28, relativeTo: .title)
    /// « Lieu · Type » under a case title: Plex Sans 15/500.
    static let deskPlace = Font.custom(Trace.FontName.sansMedium, size: 15, relativeTo: .subheadline)
    /// A folder tab: Plex Sans 15, 600 when active.
    static let deskTab = Font.custom(Trace.FontName.sans, size: 15, relativeTo: .subheadline)
    static let deskTabActive = Font.custom(Trace.FontName.sansSemibold, size: 15, relativeTo: .subheadline)
    /// A smaller folder tab (the Archives' filters): Plex Sans 13, 600 when active.
    static let deskTabSmall = Font.custom(Trace.FontName.sans, size: 13, relativeTo: .footnote)
    static let deskTabSmallActive = Font.custom(Trace.FontName.sansSemibold, size: 13, relativeTo: .footnote)
    /// The label of a metadata line on a slip: Plex Mono 10/700 caps.
    static let deskSlipLabel = Font.custom(Trace.FontName.monoBold, size: 10, relativeTo: .caption2)
    /// A title on a folder stub or an archive sheet: Plex Sans 15/600.
    static let deskStubTitle = Font.custom(Trace.FontName.sansSemibold, size: 15, relativeTo: .subheadline)
    /// A case title on an archive sheet: Newsreader 22/600.
    static let deskSheetTitle = Font.custom(Trace.FontName.serifSemibold, size: 22, relativeTo: .title3)
    /// The investigator's name on the BEN card: Newsreader 24/600.
    static let deskAgentName = Font.custom(Trace.FontName.serifSemibold, size: 24, relativeTo: .title2)
}

// MARK: - Shared chrome

/// The top of a BEN screen on the desk (§4 « où suis-je »): « ‹ {previous screen} » (44 pt), then
/// the screen's title in Newsreader, ivory.
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
                .foregroundStyle(Trace.Colors.ivory)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)
                .accessibilityIdentifier(titleID)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

extension String {
    /// "PREMIER MÉTRO" → "Premier métro"
    var capitalizedFirst: String {
        let lower = lowercased()
        return lower.prefix(1).uppercased() + lower.dropFirst()
    }
}

extension View {
    /// The body of a folder on the desk (V4 §3 CaseFolder): 20 pt inside, full width, the kraft
    /// material (corners 0 0 12 12, fibres, folder shadow) in the given paper colour.
    func folderBody(_ color: Color = Trace.Colors.kraft, padding: CGFloat = 20) -> some View {
        self.padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .kraft(color: color)
    }
}

/// A dotted leader between a label and its value (report and profile lines), at the baseline.
struct DottedLeader: View {
    var color: Color = Trace.Colors.ink2

    var body: some View {
        FlatLine()
            .stroke(color.opacity(0.7), style: StrokeStyle(lineWidth: 1.2, lineCap: .round, dash: [0.1, 4]))
            .frame(minWidth: 12, maxWidth: .infinity)
            .frame(height: 2)
            .alignmentGuide(.firstTextBaseline) { d in d[.bottom] }
            .accessibilityHidden(true)
    }
}

/// « Label ........ VALEUR » on paper: label Plex Sans 14 ink2, value Plex Mono 13/700 ink. One
/// VoiceOver element carrying both (on the value). At accessibility sizes the value goes under
/// the label.
struct LeaderLine: View {
    let label: String
    let value: String
    var valueColor: Color = Trace.Colors.ink
    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        Group {
            if typeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: 2) {
                    labelText
                    valueText
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    labelText
                    DottedLeader()
                    valueText
                }
            }
        }
        .padding(.vertical, 5)
    }

    private var labelText: some View {
        Text(label)
            .font(Trace.Fonts.callout)
            .foregroundStyle(Trace.Colors.ink2)
            .fixedSize(horizontal: false, vertical: true)
            .accessibilityHidden(true)
    }

    private var valueText: some View {
        Text(value)
            .font(Trace.Fonts.data)
            .foregroundStyle(valueColor)
            .multilineTextAlignment(.trailing)
            .fixedSize(horizontal: false, vertical: true)
            .accessibilityLabel(Text(verbatim: "\(label) \(value)"))
    }
}

/// Difficulty on paper: n filled ink dots out of 5, then « n/5 » in Plex Mono.
struct PaperDifficulty: View {
    let level: Int

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<5, id: \.self) { index in
                Circle()
                    .fill(index < level ? Trace.Colors.ink : Color.clear)
                    .overlay(Circle().strokeBorder(Trace.Colors.ink.opacity(index < level ? 0 : 0.45), lineWidth: 1))
                    .frame(width: 7, height: 7)
            }
            Text(verbatim: "\(level)/5")
                .font(Trace.Fonts.data)
                .foregroundStyle(Trace.Colors.ink)
                .padding(.leading, 4)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(L10n.f("a11y.difficulty", level)))
    }
}

/// A print stapled on a folder (V4 §3 IdPhoto on the CaseFolder): photoBorder edge, the portrait
/// or the initials on photoBg, a staple on top, a Caveat caption (also in the VoiceOver label).
/// Slightly tilted (prints only).
struct CaptionedPrint: View {
    let image: UIImage?
    let initials: String
    let caption: String
    var width: CGFloat = 104
    var height: CGFloat = 128
    /// What VoiceOver reads (« Personne disparue, Alex Moreau »).
    let accessibility: String
    var seed: String = ""

    var body: some View {
        VStack(spacing: 2) {
            PortraitOrInitials(image: image, initials: initials, width: width, height: height)
            Text(caption)
                .font(Trace.Fonts.handSmall)
                .foregroundStyle(Trace.Colors.pen)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .frame(width: width)
        }
        .padding(5)
        .background(Trace.Colors.photoBorder)
        .shadow(color: Trace.Shadow.print.color, radius: Trace.Shadow.print.radius, y: Trace.Shadow.print.y)
        .overlay(alignment: .top) { Staple().offset(y: -4) }
        .tilt(seed.isEmpty ? caption : seed)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(accessibility))
        .accessibilityAddTraits(.isImage)
    }
}

// MARK: - Modes

/// The Bureau's folder tabs (§4-01): Enquêtes · Alibi · Histoire, remembered.
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

    /// The paper of the mode's folder (and of its active tab): kraft, or the grey-blue of the
    /// ALIBI checks.
    var folderColor: Color { self == .alibi ? Trace.Colors.stubAlibi : Trace.Colors.kraft }
}

/// What the Bureau shows of the story (computed by RootView from the story coordinator).
struct StoryDeskSummary {
    var hasInvestigator: Bool
    /// « Chapitre 1 · Première affectation »
    var chapterLine: String?
    /// 0…1 of the current chapter.
    var progress: Double
}

/// The state of a case on a folder, a stub or a sheet.
enum CaseCardState: Equatable {
    case new
    case open(remaining: Double, pieces: Int)
    case solved
    case unsolved

    /// The short label of a stub or a line (symbol + word, never the colour alone).
    var rowText: String {
        switch self {
        case .new: L10n.t("case.state.newShort")
        case .open: "◐ " + L10n.t("case.state.open")
        case .solved: "✓ " + L10n.t("case.state.solved")
        case .unsolved: "✕ " + L10n.t("case.state.unsolved")
        }
    }

    /// Colour of that label on paper.
    var inkColor: Color {
        switch self {
        case .new, .open: Trace.Colors.ink
        case .solved: Trace.Colors.green
        case .unsolved: Trace.Colors.red
        }
    }

    static func of(_ file: CaseFile, progress: CaseProgress?, saved: SavedInvestigation?) -> CaseCardState {
        if let saved { return .open(remaining: saved.remainingSeconds, pieces: saved.snapshot.notebook.count) }
        guard let progress, progress.plays > 0 else { return .new }
        return progress.solved ? .solved : .unsolved
    }
}

// MARK: - FolderTabs (§3)

/// Classeur tabs (V4 §3 FolderTabs): 40 pt tabs, corners 8 8 0 0. Active: the folder's paper
/// (kraft by default, with its fibres), ink/600 text, 40 pt tall, continuous with the folder laid
/// right under it. Inactive: `tabInactive`, ivory2 text, 36 pt, so 4 pt lower. Each tab has a
/// 44 pt target; a locked tab shows a lock and can still be chosen (to read its condition). The
/// active tab rises in 250 ms (a 200 ms fade with reduced motion).
struct FolderTabs<Value: Hashable>: View {
    struct Tab {
        let value: Value
        let label: String
        let identifier: String
        var locked = false
        var hint: String? = nil
    }

    let tabs: [Tab]
    @Binding var selection: Value
    var activeColor: Color = Trace.Colors.kraft
    /// Smaller labels (13 pt), for four tabs or more.
    var small = false
    @Environment(\.colorSchemeContrast) private var contrast
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    @AppStorage(Preferences.reduceMotionKey) private var appReduceMotion = false

    var body: some View {
        HStack(alignment: .bottom, spacing: 4) {
            ForEach(Array(tabs.enumerated()), id: \.offset) { _, tab in
                tabButton(tab)
            }
        }
    }

    private func tabButton(_ tab: Tab) -> some View {
        let active = tab.value == selection
        let shape = UnevenRoundedRectangle(topLeadingRadius: Trace.Radius.folderTab, bottomLeadingRadius: 0,
                                           bottomTrailingRadius: 0, topTrailingRadius: Trace.Radius.folderTab)
        return Button {
            guard !active else { return }
            withAnimation(systemReduceMotion || appReduceMotion ? .easeOut(duration: 0.2) : Trace.Motion.tab) {
                selection = tab.value
            }
            Haptics.selection()
        } label: {
            HStack(spacing: 5) {
                if tab.locked {
                    Image(systemName: "lock")
                        .font(.system(size: 11, weight: .semibold))
                        .accessibilityHidden(true)
                }
                Text(tab.label)
                    .font(font(active: active))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .foregroundStyle(active ? Trace.Colors.ink : Trace.Colors.ivory2)
            .padding(.horizontal, 8)
            .frame(maxWidth: .infinity, minHeight: active ? Trace.Height.folderTab : Trace.Height.folderTab - 4)
            .background {
                shape
                    .fill(active ? activeColor : Trace.Colors.tabInactive)
                    .overlay {
                        if active && contrast != .increased {
                            PaperGrain(intensity: 0.04, texture: "tex_kraft_fibers").clipShape(shape)
                        }
                    }
            }
            .frame(minHeight: Trace.Height.hit, alignment: .bottom)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(active ? .isSelected : [])
        .accessibilityHint(tab.hint.map { Text($0) } ?? Text(verbatim: ""))
        .accessibilityIdentifier(tab.identifier)
    }

    private func font(active: Bool) -> Font {
        if small { return active ? Trace.Fonts.deskTabSmallActive : Trace.Fonts.deskTabSmall }
        return active ? Trace.Fonts.deskTabActive : Trace.Fonts.deskTab
    }
}

// MARK: - 01 · Bureau

/// The Bureau (V4 §4-01): the lamp's pool on the dark desk; the logo mention and the
/// investigator's avatar (→ profile); « Bonjour, {rang} {Nom} » and « Un dossier vous attend sur le
/// bureau. »; the folder tabs, and under the active one its folder — ENQUÊTES: the CaseFolder (the
/// case just classified, the case in progress, or the next one) and the other cases as folder
/// stubs; ALIBI: the checks' folder; HISTOIRE: the story's folder. Alibi and Histoire stay locked
/// until the player is assigned to the BEN, as before. One main button per folder.
struct BureauView: View {
    let identity: PlayerIdentity
    @Binding var mode: DeskMode
    /// Alibi and Histoire are open (the player was assigned after the first #001 report).
    let modesUnlocked: Bool
    /// Shown in the locked modes' condition (« Disponible après #001 »).
    let firstNumber: Int
    let cases: [CaseFile]
    let progress: [String: CaseProgress]
    /// Finished attempts (the data of a played case's folder).
    let attempts: [Attempt]
    /// The investigation in progress when it is a main-mode case.
    let resumable: (saved: SavedInvestigation, file: CaseFile)?
    /// Seconds of each case at its intended level (« Temps détendu » included), by case id.
    let durations: [String: Int]
    /// The case whose report was just classified as solved: its folder comes back to the desk and
    /// the RÉSOLU stamp falls on it (§5 « Classer »).
    let justFiled: String?
    let alibiCases: [CaseFile]
    let alibiInProgressID: String?
    let story: StoryDeskSummary
    let onOpen: (CaseFile) -> Void
    let onResume: () -> Void
    let onReport: (CaseFile) -> Void
    let onAlibi: (CaseFile) -> Void
    let onStory: () -> Void
    /// The Histoire tab is on screen: the story's save is loaded for its folder.
    let onStoryVisible: () -> Void
    let onProfile: () -> Void
    let onTab: (DeskTab) -> Void

    @State private var stampLanded = false
    @State private var appeared = false
    /// The classified folder has slid back onto the desk (600 ms).
    @State private var arrived = false
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    @AppStorage(Preferences.reduceMotionKey) private var appReduceMotion = false

    private var still: Bool { systemReduceMotion || appReduceMotion }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    header
                    VStack(alignment: .leading, spacing: 0) {
                        FolderTabs(tabs: modeTabs, selection: $mode, activeColor: mode.folderColor)
                        modeFolder
                            .id(mode)
                            .transition(.opacity)
                    }
                    if mode == .investigations {
                        belowFolder
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 32)
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
            withAnimation(still ? .easeOut(duration: 0.2) : .timingCurve(0.2, 0.8, 0.2, 1, duration: 0.6)) { arrived = true }
        }
    }

    // MARK: Header

    /// The logo mention + the 36 pt avatar (→ profile), then the greeting and its line.
    private var header: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .center, spacing: 12) {
                LogoText()
                Spacer(minLength: 8)
                Button(action: onProfile) {
                    PortraitOrInitials(image: ArtLibrary.image(identity.portraitName), initials: identity.id.initials,
                                       width: Self.avatar, height: Self.avatar)
                        .clipShape(Circle())
                        .overlay(Circle().strokeBorder(Trace.Colors.ivory.opacity(0.25), lineWidth: 1))
                        .frame(width: Trace.Height.hit, height: Trace.Height.hit)
                        .contentShape(Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text(verbatim: "\(L10n.t("tab.investigator")), \(identity.id.fullName)"))
                .accessibilityIdentifier("home.profile")
            }
            VStack(alignment: .leading, spacing: 6) {
                Text(greeting)
                    .font(Trace.Fonts.deskGreeting)
                    .foregroundStyle(Trace.Colors.ivory)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityAddTraits(.isHeader)
                    .accessibilityIdentifier("home.title")
                Text(allClosed ? L10n.t("desk.allClosed") : L10n.t("desk.waiting"))
                    .font(Trace.Fonts.body)
                    .foregroundStyle(Trace.Colors.ivory2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private static let avatar: CGFloat = 36

    /// « Bonjour, Inspectrice Morel » once assigned (the rank and the last name), « Bonjour, Élise
    /// Morel » before.
    private var greeting: String {
        guard modesUnlocked else { return L10n.f("desk.hello", identity.id.fullName) }
        let solved = cases.filter { progress[$0.id]?.solved == true }.count
        let rank = Rank.forSolved(solved).title(feminine: identity.id.isFeminine).capitalizedFirst
        return L10n.f("desk.helloRank", rank, identity.id.lastName)
    }

    private var modeTabs: [FolderTabs<DeskMode>.Tab] {
        DeskMode.allCases.map { item in
            let locked = !modesUnlocked && item != .investigations
            return FolderTabs<DeskMode>.Tab(value: item, label: item.title, identifier: item.identifier,
                                            locked: locked, hint: locked ? L10n.t("mode.locked") : nil)
        }
    }

    // MARK: The folder under the active tab

    @ViewBuilder
    private var modeFolder: some View {
        switch mode {
        case .investigations:
            investigationsFolder
        case .alibi:
            if modesUnlocked {
                AlibiFolder(cases: alibiCases, progress: progress, inProgressID: alibiInProgressID,
                            onOpen: onAlibi, onResume: onResume)
            } else {
                LockedFolder(mode: .alibi, firstNumber: firstNumber) { mode = .investigations }
            }
        case .story:
            if modesUnlocked {
                StoryFolder(summary: story, onOpen: onStory)
            } else {
                LockedFolder(mode: .story, firstNumber: firstNumber) { mode = .investigations }
            }
        }
    }

    // MARK: Enquêtes

    /// Every case is solved and nothing is in progress.
    private var allClosed: Bool {
        resumable == nil && !cases.isEmpty && cases.allSatisfy { progress[$0.id]?.solved == true }
    }

    /// The folder on the desk: the case just classified (its stamp), the case in progress, or the
    /// next case not played (else the first one not solved).
    private var featured: CaseFile? {
        if let justFiled, let file = cases.first(where: { $0.id == justFiled }) { return file }
        if let resumable { return resumable.file }
        if allClosed { return nil }
        return cases.first { progress[$0.id] == nil } ?? cases.first { progress[$0.id]?.solved != true }
    }

    @ViewBuilder
    private var investigationsFolder: some View {
        if cases.isEmpty {
            SkeletonFolder()
        } else if let file = featured {
            let returning = justFiled == file.id && !still
            CaseFolder(file: file,
                       state: state(of: file),
                       durationSeconds: durations[file.id] ?? file.durationSeconds,
                       report: ProgressStore.reportAttempt(of: file.id, in: attempts),
                       stamp: stamp(for: file),
                       onOpen: { onOpen(file) },
                       onResume: onResume,
                       onReport: { onReport(file) },
                       onStampLanded: { stampLanded = true })
                .offset(y: returning && !arrived ? 28 : 0)
        } else {
            allClosedFolder
        }
    }

    /// « Affaire suivante » after a classified case, then the other cases' folder stubs.
    @ViewBuilder
    private var belowFolder: some View {
        let featured = self.featured
        if let file = featured, justFiled == file.id, let next = nextCase(after: file) {
            Button(L10n.f("desk.nextCase", shownNumber(next.number))) { onOpen(next) }
                .buttonStyle(CTAButtonStyle())
                .accessibilityIdentifier("desk.next")
        }
        let others = cases.filter { $0.id != featured?.id }
        if !others.isEmpty {
            VStack(alignment: .leading, spacing: 0) {
                SectionHeader(title: L10n.t("desk.otherCases"))
                FolderStubStack {
                    ForEach(others) { file in
                        let caseState = state(of: file)
                        FolderStub(number: fileLabel(file.number), shortNumber: "#\(shownNumber(file.number))",
                                   title: file.title.capitalizedFirst, stateText: caseState.rowText,
                                   color: caseState == .solved ? Trace.Colors.stubGrey : Trace.Colors.stubKraft,
                                   identifier: "case.\(file.id)") {
                            onOpen(file)
                        }
                    }
                }
            }
        }
    }

    private func state(of file: CaseFile) -> CaseCardState {
        CaseCardState.of(file, progress: progress[file.id], saved: resumable?.file.id == file.id ? resumable?.saved : nil)
    }

    private func stamp(for file: CaseFile) -> CaseFolder.Stamp {
        guard justFiled == file.id, state(of: file) == .solved else { return .none }
        return stampLanded ? .landed : .falling
    }

    private func nextCase(after file: CaseFile) -> CaseFile? {
        cases.first { $0.id != file.id && progress[$0.id] == nil }
            ?? cases.first { $0.id != file.id && progress[$0.id]?.solved != true }
    }

    /// Every case classified: an empty folder, « Toutes les affaires sont classées », the Archives.
    private var allClosedFolder: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(L10n.t("desk.allClosedTitle"))
                .font(Trace.Fonts.serifTitle(28))
                .foregroundStyle(Trace.Colors.ink)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)
            Text(L10n.t("desk.allClosed"))
                .font(Trace.Fonts.body)
                .foregroundStyle(Trace.Colors.inkMid)
                .fixedSize(horizontal: false, vertical: true)
            Button(L10n.t("desk.openArchives")) { onTab(.archives) }
                .buttonStyle(CTAButtonStyle(kind: .outline, onPaper: true))
                .accessibilityIdentifier("desk.archives")
                .padding(.top, 10)
        }
        .folderBody()
    }
}

// MARK: - CaseFolder (§3)

/// The case on the desk (V4 §3 CaseFolder, ≈ 358 × 420 pt, continuous with the active tab):
/// « DOSSIER #001 » (Mono 13/700) and its stamp — CONFIDENTIEL, or RÉSOLU once solved —, the title
/// (Newsreader 32/600), « Lieu · Type » (15/500), the stapled print of the person concerned with its
/// Caveat caption, a paperCard slip with three data (Difficulté, Durée or Temps restant, Pièces),
/// then the ink button — NOUVEAU: [Ouvrir le dossier] · EN COURS: [Reprendre · 06:58] (pieces n/N
/// on the slip) · RÉSOLU: « Voir le rapport » (outline). The RÉSOLU stamp falls on it when the case
/// was just classified.
struct CaseFolder: View {
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

    private static let minHeight: CGFloat = 420
    private static let resolvedAsset = "stamp_resolu_rouge_marque"
    private static let confidentialAsset = "stamp_confidentiel_rouge_marque"

    var body: some View {
        let facts = DossierFacts(file: file)
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: 12) {
                Text(fileLabel(file.number))
                    .font(Trace.Fonts.data)
                    .tracking(1.2)
                    .foregroundStyle(Trace.Colors.ink)
                    .padding(.top, 4)
                Spacer(minLength: 8)
                stampView
                    .frame(width: 136, height: 44, alignment: .topTrailing)
                    .accessibilityIdentifier("home.state")
            }
            Text(file.title.capitalizedFirst)
                .font(Trace.Fonts.caseTitle)
                .foregroundStyle(Trace.Colors.ink)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)
                .padding(.top, 2)
            let place = Self.placeLine(facts)
            if !place.isEmpty {
                Text(place)
                    .font(Trace.Fonts.deskPlace)
                    .foregroundStyle(Trace.Colors.inkMid)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 4)
            }
            evidence(facts)
                .padding(.top, 24)
            Spacer(minLength: 24)
            actions
        }
        .frame(minHeight: Self.minHeight - 40, alignment: .top)
        .folderBody()
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("home.card")
    }

    /// « Marseille · Disparition »
    static func placeLine(_ facts: DossierFacts) -> String {
        [facts.city, facts.category.capitalizedFirst].filter { !$0.isEmpty }.joined(separator: " · ")
    }

    // MARK: Stamp

    @ViewBuilder
    private var stampView: some View {
        switch (state, stamp) {
        case (_, .falling):
            FallingStampImage(asset: Self.resolvedAsset, label: L10n.t("stamp.solved"), width: 104, angle: -8,
                              delay: 0.6, onLanded: onStampLanded)
        case (.solved, _):
            StampImage(asset: Self.resolvedAsset, label: L10n.t("stamp.solved"), width: 104, angle: -8)
        default:
            StampImage(asset: Self.confidentialAsset, label: L10n.t("stamp.confidential"), width: 132, angle: -6)
        }
    }

    // MARK: Print + slip

    /// The stapled print of the person concerned, and the slip; one column at accessibility sizes.
    private func evidence(_ facts: DossierFacts) -> some View {
        let layout = typeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 20))
            : AnyLayout(HStackLayout(alignment: .top, spacing: 16))
        return layout {
            subjectPrint(facts)
            slip
        }
    }

    private func subjectPrint(_ facts: DossierFacts) -> some View {
        let contact = facts.subjectContact()
        let name = contact?.name ?? facts.subject
        return CaptionedPrint(image: ArtLibrary.portrait(case: file.number, contact: contact),
                              initials: IDPhoto.initials(of: name),
                              caption: name,
                              accessibility: "\(facts.subjectLabel.capitalizedFirst), \(name)",
                              seed: file.id)
            .padding(.top, 4)
    }

    /// Difficulté · Durée (or Temps restant) · Pièces, Plex Mono on paperCard.
    private var slip: some View {
        let facts = DossierFacts(file: file)
        return VStack(alignment: .leading, spacing: 12) {
            slipLine(L10n.t("dossier.difficulty")) {
                PaperDifficulty(level: facts.rating)
            }
            slipLine(timeLabel) {
                Text(PhoneFormat.countdown(timeValue))
                    .font(Trace.Fonts.data)
                    .foregroundStyle(Trace.Colors.ink)
            }
            slipLine(L10n.t("case.meta.pieces")) {
                Text(verbatim: piecesValue)
                    .font(Trace.Fonts.data)
                    .foregroundStyle(Trace.Colors.ink)
                    .accessibilityIdentifier("home.resumeMeta")
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .paper(Trace.Colors.paperCard)
    }

    private func slipLine<Content: View>(_ label: String, @ViewBuilder _ content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(label)
                .font(Trace.Fonts.deskSlipLabel)
                .tracking(1)
                .textCase(.uppercase)
                .foregroundStyle(Trace.Colors.ink2)
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
                .buttonStyle(CTAButtonStyle(kind: .primary, onPaper: true))
                .accessibilityIdentifier("home.start")
        case .open(let remaining, let pieces):
            let title = L10n.f("desk.resumeTime", PhoneFormat.countdown(remaining))
            Button(title, action: onResume)
                .buttonStyle(CTAButtonStyle(kind: .primary, onPaper: true))
                .accessibilityLabel(Text(verbatim: "\(title), \(L10n.f("dossier.piecesCount", pieces))"))
                .accessibilityIdentifier("home.resume")
        case .solved:
            Button(L10n.t("desk.report"), action: onReport)
                .buttonStyle(CTAButtonStyle(kind: .outline, onPaper: true))
                .accessibilityIdentifier("home.report")
        }
    }
}

/// The former name, kept for the callers of `placeLine`.
typealias CaseCard = CaseFolder

/// Loading: a bare kraft folder with ink blocks, no text.
private struct SkeletonFolder: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            block(width: 110, height: 12)
            block(width: 230, height: 28)
            block(width: 150, height: 14)
            HStack(alignment: .top, spacing: 16) {
                Trace.Colors.photoBorder.frame(width: 114, height: 150)
                Trace.Colors.paperCard.frame(height: 130)
            }
            .padding(.top, 12)
            Spacer(minLength: 24)
            RoundedRectangle(cornerRadius: Trace.Radius.button).fill(Trace.Colors.ink.opacity(0.18))
                .frame(height: Trace.Height.button)
        }
        .frame(minHeight: 380, alignment: .top)
        .folderBody()
        .accessibilityHidden(true)
    }

    private func block(width: CGFloat, height: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: 3).fill(Trace.Colors.ink.opacity(0.14)).frame(width: width, height: height)
    }
}

// MARK: - FolderStub (§3)

/// Folder stubs piled at the bottom of the Bureau: each folder shows its 54 pt top edge, the next
/// one lying 6 pt over it (48 pt stay visible, above the 44 pt target).
struct FolderStubStack<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        VStack(spacing: -FolderStub.overlap) { content }
    }
}

/// A case waiting on the Bureau (V4 §3 FolderStub): the top of its folder, 54 pt, in its paper
/// colour (grey, light kraft, or the ALIBI grey-blue); the number in Plex Mono, the title, its
/// state (symbol + word). A locked one is at 55 % and shows its condition when touched.
struct FolderStub: View {
    /// « DOSSIER #002 » (VoiceOver).
    let number: String
    /// « #002 » (on the stub).
    let shortNumber: String
    let title: String
    let stateText: String
    var color: Color = Trace.Colors.stubKraft
    /// The condition of a locked case (« Disponible après la conclusion du dossier #001. »).
    var lockedMessage: String? = nil
    let identifier: String
    let action: () -> Void
    @State private var showsCondition = false
    @Environment(\.colorSchemeContrast) private var contrast

    static let height: CGFloat = 54
    static let overlap: CGFloat = 6

    var body: some View {
        let shape = UnevenRoundedRectangle(topLeadingRadius: Trace.Radius.folderTab, bottomLeadingRadius: 2,
                                           bottomTrailingRadius: 2, topTrailingRadius: Trace.Radius.folderTab)
        VStack(alignment: .leading, spacing: 0) {
            Button {
                if lockedMessage != nil {
                    withAnimation(.easeOut(duration: 0.2)) { showsCondition.toggle() }
                    Haptics.selection()
                } else {
                    action()
                }
            } label: {
                HStack(alignment: .center, spacing: 12) {
                    Text(verbatim: shortNumber)
                        .font(Trace.Fonts.data)
                        .foregroundStyle(Trace.Colors.ink)
                    Text(title)
                        .font(Trace.Fonts.deskStubTitle)
                        .foregroundStyle(Trace.Colors.ink)
                        .multilineTextAlignment(.leading)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 8)
                    if lockedMessage != nil {
                        Image(systemName: "lock")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(Trace.Colors.ink)
                    } else {
                        Text(stateText)
                            .font(Trace.Fonts.caption)
                            .foregroundStyle(Trace.Colors.ink)
                            .lineLimit(1)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(Trace.Colors.inkMid)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 6)
                .padding(.bottom, 6 + Self.overlap)
                .frame(maxWidth: .infinity, minHeight: Self.height, alignment: .leading)
                .background {
                    shape
                        .fill(color)
                        .overlay {
                            if contrast != .increased {
                                PaperGrain(intensity: 0.04, texture: "tex_kraft_fibers").clipShape(shape)
                            }
                        }
                        .shadow(color: Trace.Shadow.slip.color, radius: 4, y: -1)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(PressableStyle())
            .opacity(lockedMessage == nil ? 1 : 0.55)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text(verbatim: "\(number), \(title), \(stateText)"))
            .accessibilityAddTraits(.isButton)
            .accessibilityIdentifier(identifier)
            if showsCondition, let lockedMessage {
                Text(lockedMessage)
                    .font(Trace.Fonts.callout)
                    .foregroundStyle(Trace.Colors.ink)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .paper(Trace.Colors.paperCard)
                    .padding(.top, Self.overlap + 4)
                    .padding(.bottom, Self.overlap + 8)
                    .transition(.opacity)
            }
        }
    }
}

// MARK: - Alibi

/// The ALIBI tab (V4 §4-01, same folder layout in the checks' grey-blue paper): the next check —
/// « ALIBI #001 », its title, its line, the stapled print of the person whose statement is checked,
/// the slip (Difficulté, Durée, Statut) and [Commencer] (or [Reprendre]) —, then the other checks
/// as stubs. Same choice of check as before the redesign.
private struct AlibiFolder: View {
    let cases: [CaseFile]
    let progress: [String: CaseProgress]
    let inProgressID: String?
    let onOpen: (CaseFile) -> Void
    let onResume: () -> Void
    @Environment(\.dynamicTypeSize) private var typeSize

    private var next: CaseFile? {
        cases.first { $0.id == inProgressID } ?? cases.first { progress[$0.id]?.solved != true } ?? cases.first
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            folder
            let others = cases.filter { $0.id != next?.id }
            if !others.isEmpty {
                VStack(alignment: .leading, spacing: 0) {
                    SectionHeader(title: L10n.t("alibi.list"))
                    FolderStubStack {
                        ForEach(others) { file in
                            FolderStub(number: fileLabel(file.number), shortNumber: "#\(shownNumber(file.number))",
                                       title: file.title.capitalizedFirst, stateText: status(of: file).text,
                                       color: Trace.Colors.stubAlibi,
                                       identifier: "alibi.case.\(file.id)") {
                                open(file)
                            }
                        }
                    }
                }
            }
        }
        .accessibilityElement(children: .contain)
    }

    @ViewBuilder
    private var folder: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let file = next {
                HStack(alignment: .top, spacing: 12) {
                    Text(fileLabel(file.number))
                        .font(Trace.Fonts.data)
                        .tracking(1.2)
                        .foregroundStyle(Trace.Colors.ink)
                        .padding(.top, 4)
                    Spacer(minLength: 8)
                    Group {
                        if progress[file.id]?.solved == true {
                            StampImage(asset: "stamp_resolu_rouge_marque", label: L10n.t("stamp.solved"), width: 104, angle: -8)
                        } else {
                            StampImage(asset: "stamp_confidentiel_rouge_marque", label: L10n.t("stamp.confidential"), width: 132, angle: -6)
                        }
                    }
                    .frame(width: 136, height: 44, alignment: .topTrailing)
                }
                Text(file.title.capitalizedFirst)
                    .font(Trace.Fonts.caseTitle)
                    .foregroundStyle(Trace.Colors.ink)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityAddTraits(.isHeader)
                    .accessibilityIdentifier("alibi.title")
                    .padding(.top, 2)
                Text(L10n.t("modecard.alibi.subtitle"))
                    .font(Trace.Fonts.deskPlace)
                    .foregroundStyle(Trace.Colors.ink2)
                    .padding(.top, 4)
                if !file.tagline.isEmpty {
                    Text(file.tagline)
                        .font(Trace.Fonts.callout)
                        .foregroundStyle(Trace.Colors.ink)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, 10)
                }
                evidence(file)
                    .padding(.top, 20)
                Spacer(minLength: 24)
                Group {
                    if file.id == inProgressID {
                        Button(L10n.t("desk.resume"), action: onResume)
                            .accessibilityIdentifier("alibi.resume")
                    } else {
                        Button(L10n.t("alibi.start")) { onOpen(file) }
                            .accessibilityIdentifier("alibi.start")
                    }
                }
                .buttonStyle(CTAButtonStyle(kind: .primary, onPaper: true))
            } else {
                Text(L10n.t("desk.mode.alibi"))
                    .font(Trace.Fonts.caseTitle)
                    .foregroundStyle(Trace.Colors.ink)
                    .accessibilityAddTraits(.isHeader)
                    .accessibilityIdentifier("alibi.title")
                EmptyPage(title: L10n.t("archives.empty"), tip: L10n.t("alibi.pitch"), onPaper: true)
            }
        }
        .frame(minHeight: next == nil ? 0 : 380, alignment: .top)
        .folderBody(Trace.Colors.stubAlibi)
    }

    private func evidence(_ file: CaseFile) -> some View {
        let layout = typeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 20))
            : AnyLayout(HStackLayout(alignment: .top, spacing: 16))
        let person = file.claim.flatMap { claim in file.devices.flatMap(\.contacts).first { $0.id == claim.person } }
        return layout {
            if let person {
                CaptionedPrint(image: ArtLibrary.portrait(case: file.number, contact: person),
                               initials: person.initials, caption: person.name,
                               width: 96, height: 118,
                               accessibility: person.name, seed: file.id)
                    .padding(.top, 4)
            }
            VStack(alignment: .leading, spacing: 12) {
                line(L10n.t("dossier.difficulty")) { PaperDifficulty(level: DossierFacts(file: file).rating) }
                line(L10n.t("desk.duration")) {
                    Text(L10n.f("alibi.duration", max(1, file.durationSeconds / 60)))
                        .font(Trace.Fonts.data)
                        .foregroundStyle(Trace.Colors.ink)
                }
                line(L10n.t("dossier.state")) {
                    let checkStatus = status(of: file)
                    Text(checkStatus.text)
                        .font(Trace.Fonts.data)
                        .foregroundStyle(checkStatus.color)
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .paper(Trace.Colors.paperCard)
        }
    }

    private func line<Content: View>(_ label: String, @ViewBuilder _ content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(label)
                .font(Trace.Fonts.deskSlipLabel)
                .tracking(1)
                .textCase(.uppercase)
                .foregroundStyle(Trace.Colors.ink2)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    private func open(_ file: CaseFile) {
        if file.id == inProgressID { onResume() } else { onOpen(file) }
    }

    /// Nouvelle · ◐ En cours · ✓ Vérifiée · À reprendre (symbol + word).
    private func status(of file: CaseFile) -> (text: String, color: Color) {
        if file.id == inProgressID { return ("◐ " + L10n.t("alibi.status.inProgress"), Trace.Colors.ink) }
        guard let p = progress[file.id] else { return (L10n.t("alibi.status.new"), Trace.Colors.ink) }
        return p.solved ? ("✓ " + L10n.t("alibi.status.done"), Trace.Colors.green)
                        : (L10n.t("alibi.status.tried"), Trace.Colors.ink)
    }
}

// MARK: - Histoire

/// The HISTOIRE tab: the story's kraft folder — the chapter in progress (or « Créer votre
/// enquêteur »), the promise, the chapter's progress, and the button that opens the story.
private struct StoryFolder: View {
    let summary: StoryDeskSummary
    let onOpen: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(L10n.t("mode.story.tab"))
                .font(Trace.Fonts.data)
                .tracking(1.2)
                .foregroundStyle(Trace.Colors.ink)
            Text(title)
                .font(Trace.Fonts.serifTitle(28))
                .foregroundStyle(Trace.Colors.ink)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)
                .padding(.top, 10)
            Text(L10n.t("modecard.story.subtitle"))
                .font(Trace.Fonts.deskPlace)
                .foregroundStyle(Trace.Colors.inkMid)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 4)
            Text(L10n.t("mode.story.promise"))
                .font(Trace.Fonts.body)
                .foregroundStyle(Trace.Colors.ink)
                .fixedSize(horizontal: false, vertical: true)
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .paper(Trace.Colors.paperCard)
                .padding(.top, 20)
            if summary.hasInvestigator {
                progressBar
                    .padding(.top, 20)
            }
            Spacer(minLength: 24)
            Button(summary.hasInvestigator ? L10n.t("desk.story.continue") : L10n.t("desk.story.start"), action: onOpen)
                .buttonStyle(CTAButtonStyle(kind: .primary, onPaper: true))
                .accessibilityIdentifier("story.open")
        }
        .frame(minHeight: 320, alignment: .top)
        .folderBody()
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("desk.story")
    }

    private var title: String {
        guard summary.hasInvestigator else { return L10n.t("mode.story.create") }
        return summary.chapterLine ?? L10n.t("mode.story.promise")
    }

    /// A 3 pt ink bar on a faint track; the percentage for VoiceOver.
    private var progressBar: some View {
        Capsule()
            .fill(Trace.Colors.ink.opacity(0.15))
            .frame(height: 3)
            .overlay(alignment: .leading) {
                GeometryReader { geo in
                    Capsule()
                        .fill(Trace.Colors.ink)
                        .frame(width: geo.size.width * min(1, max(0, summary.progress)))
                }
            }
            .accessibilityElement()
            .accessibilityLabel(Text(summary.chapterLine ?? L10n.t("desk.mode.story")))
            .accessibilityValue(Text(verbatim: "\(Int((summary.progress * 100).rounded())) %"))
    }
}

// MARK: - A locked mode

/// A locked tab's folder (UX V3 §6-13 « Mode verrouillé »): the mode, its promise, its condition on
/// a slip with a lock, and a way back to the investigations.
private struct LockedFolder: View {
    let mode: DeskMode
    let firstNumber: Int
    let onBack: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(mode.title)
                .font(Trace.Fonts.caseTitle)
                .foregroundStyle(Trace.Colors.ink)
                .accessibilityAddTraits(.isHeader)
            Text(L10n.t(mode == .alibi ? "modecard.alibi.subtitle" : "modecard.story.subtitle"))
                .font(Trace.Fonts.deskPlace)
                .foregroundStyle(mode == .alibi ? Trace.Colors.ink2 : Trace.Colors.inkMid)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 4)
            Text(L10n.t(mode == .alibi ? "alibi.pitch" : "mode.story.promise"))
                .font(Trace.Fonts.body)
                .foregroundStyle(Trace.Colors.ink)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 14)
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Image(systemName: "lock")
                    .font(.system(size: 13, weight: .semibold))
                    .accessibilityHidden(true)
                Text(L10n.f("mode.lockedMessage", shownNumber(firstNumber)))
                    .font(Trace.Fonts.callout)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .foregroundStyle(Trace.Colors.ink)
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .paper(Trace.Colors.paperCard)
            .padding(.top, 20)
            .accessibilityElement(children: .combine)
            Spacer(minLength: 24)
            Button(L10n.t("desk.backToInvestigations"), action: onBack)
                .buttonStyle(CTAButtonStyle(kind: .outline, onPaper: true))
                .accessibilityIdentifier("desk.backToInvestigations")
        }
        .frame(minHeight: 320, alignment: .top)
        .folderBody(mode.folderColor)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("desk.modes")
    }
}

// MARK: - Archives

/// The Archives (V4 §8-6): the kraft drawer of the case files under four filter tabs (Tous · En
/// cours · Résolus · Non résolus); each case is a sheet with its number, title, « Lieu · Type »,
/// one data line and its stamp — RÉSOLU (red), NON RÉSOLU (black), OUVERT (in progress),
/// CONFIDENTIEL (not opened yet).
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
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 6) {
                        BenScreenHeader(back: L10n.t("tab.bureau"), backID: "archives.back", onBack: { onTab(.bureau) },
                                        title: L10n.t("archives.title"), titleID: "archives.title")
                        Text(L10n.f("archives.count", cases.count))
                            .font(Trace.Fonts.caption)
                            .foregroundStyle(Trace.Colors.ivory2)
                    }
                    VStack(alignment: .leading, spacing: 0) {
                        FolderTabs(tabs: filterTabs, selection: $filter, small: true)
                        LazyVStack(spacing: 14) {
                            ForEach(visible) { file in
                                ArchiveCard(file: file, status: status(file), progress: progress[file.id],
                                            lastAttempt: attempts.last { $0.caseID == file.id }) { onOpen(file) }
                            }
                            if visible.isEmpty {
                                EmptyPage(title: L10n.t("archives.empty"), tip: L10n.t("archives.emptyTip"), onPaper: true)
                            }
                        }
                        .folderBody(padding: 14)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 32)
            }
            DeskTabBar(selected: .archives, onSelect: onTab)
        }
        .background(DeskBackdrop())
    }

    /// Same identifiers as the former segmented control (`archives.filter.0` …).
    private var filterTabs: [FolderTabs<Filter>.Tab] {
        let items: [(Filter, String)] = [(.all, "archives.all"), (.open, "archives.open"),
                                         (.solved, "archives.solved"), (.unsolved, "archives.unsolved")]
        return items.enumerated()
            .map { index, item in
                FolderTabs<Filter>.Tab(value: item.0, label: L10n.t(item.1), identifier: "archives.filter.\(index)")
            }
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

/// A case in the Archives: a paperCard sheet in the kraft drawer — « DOSSIER #001 », the title
/// (Newsreader 22), « Lieu · Type », one data line (difficulty, date and mark, or attempts), and its
/// stamp on the right.
struct ArchiveCard: View {
    let file: CaseFile
    let status: DossierStatus
    let progress: CaseProgress?
    let lastAttempt: Attempt?
    let onOpen: () -> Void

    var body: some View {
        let facts = DossierFacts(file: file)
        Button(action: onOpen) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 5) {
                    Text(fileLabel(file.number))
                        .font(Trace.Fonts.data)
                        .tracking(1.2)
                        .foregroundStyle(Trace.Colors.ink)
                    Text(file.title.capitalizedFirst)
                        .font(Trace.Fonts.deskSheetTitle)
                        .foregroundStyle(Trace.Colors.ink)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                    let place = CaseFolder.placeLine(facts)
                    if !place.isEmpty {
                        Text(place)
                            .font(Trace.Fonts.caption)
                            .foregroundStyle(Trace.Colors.ink2)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    footer(facts)
                        .padding(.top, 6)
                }
                Spacer(minLength: 4)
                stamp
                    .frame(width: 96, alignment: .trailing)
                    .padding(.top, 2)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .paper(Trace.Colors.paperCard)
            .contentShape(Rectangle())
        }
        .buttonStyle(PressableStyle())
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("case.\(file.id)")
    }

    @ViewBuilder
    private var stamp: some View {
        switch status {
        case .solved:
            StampImage(asset: "stamp_resolu_rouge_marque", label: L10n.t("stamp.solved"), width: 84, angle: -8)
        case .unsolved:
            StampImage(asset: "stamp_non_resolu_noir_marque", label: L10n.t("stamp.unsolved"), width: 96, angle: -6,
                       color: Trace.Colors.ink)
        case .open:
            StampMark(text: L10n.t("briefing.status.opened"), size: 11)
        case .new:
            StampImage(asset: "stamp_confidentiel_rouge_marque", label: L10n.t("stamp.confidential"), width: 96, angle: -6)
        }
    }

    @ViewBuilder
    private func footer(_ facts: DossierFacts) -> some View {
        switch status {
        case .new, .open:
            PaperDifficulty(level: facts.rating)
        case .solved:
            Text(L10n.f("archives.closedOn", lastAttempt.map { $0.date.formatted(.dateTime.day(.twoDigits).month(.twoDigits)) } ?? "—",
                        progress?.bestScore ?? 0))
                .font(Trace.Fonts.data)
                .foregroundStyle(Trace.Colors.ink)
        case .unsolved:
            Text(L10n.f("archives.attempts", progress?.plays ?? 0))
                .font(Trace.Fonts.caption)
                .foregroundStyle(Trace.Colors.ink2)
        }
    }
}

// MARK: - Enquêteur (profile)

/// The investigator's file (tab 3), on paper: the BEN card (print, name, title; after the
/// assignment the service number, the rank, the bio, the date and the BEN seal), then one sheet —
/// Parcours, Affaires, Distinctions, Historique — in Plex Mono lines with dotted leaders. Before the
/// assignment (screen 12): the identity only. Changing investigator reuses « Qui enquête ? »; the
/// settings are at the bottom, on the desk.
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
                    agentCard(rank: rank)
                    if assigned {
                        record(rank: rank, summary: summary)
                    }
                    VStack(spacing: 12) {
                        Button(assigned ? L10n.t("profile.changeIdentity") : L10n.t("profile.changeInvestigator")) {
                            changing = true
                        }
                        .buttonStyle(CTAButtonStyle(kind: .outline))
                        .accessibilityIdentifier("profile.changeIdentity")
                        settingsRow
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 32)
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

    // MARK: The BEN card

    /// « CARTE D'AGENT · BEN »; the stapled print; the name (Newsreader 24), the title; after the
    /// assignment the service number and the rank (leader lines), the bio, the date, the BEN seal.
    private func agentCard(rank: Rank) -> some View {
        let layout = typeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 16))
            : AnyLayout(HStackLayout(alignment: .top, spacing: 18))
        return VStack(alignment: .leading, spacing: 16) {
            Text(L10n.t("profile.agentCard")).fieldLabel(Trace.Colors.ink2)
            layout {
                PlayerPrint(identity: identity, width: 88, border: 5)
                    .overlay(alignment: .top) { Staple().offset(y: -4) }
                    .tilt(identity.portraitName)
                    .padding(.top, 4)
                VStack(alignment: .leading, spacing: 4) {
                    Text(identity.id.fullName)
                        .font(Trace.Fonts.deskAgentName)
                        .foregroundStyle(Trace.Colors.ink)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityAddTraits(.isHeader)
                    Text(identity.id.title)
                        .font(Trace.Fonts.section)
                        .tracking(1.1)
                        .foregroundStyle(Trace.Colors.ink2)
                        .padding(.bottom, 6)
                    if assigned {
                        LeaderLine(label: L10n.t("investigator.number"), value: identity.id.serviceNumber)
                        LeaderLine(label: L10n.t("profile.rank"), value: rank.title(feminine: identity.id.isFeminine))
                    }
                }
            }
            if assigned {
                VStack(alignment: .leading, spacing: 8) {
                    Text(identity.id.bio)
                        .font(Trace.Fonts.callout)
                        .foregroundStyle(Trace.Colors.ink)
                        .fixedSize(horizontal: false, vertical: true)
                    if let date = PlayerStore.assignedDate {
                        Text(assignedLine(Self.dotted(date)))
                            .font(Trace.Fonts.caption)
                            .foregroundStyle(Trace.Colors.ink2)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(.trailing, 80)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .overlay(alignment: .bottomTrailing) {
            if assigned {
                StampImage(asset: "seal_ben_bleu", label: "BEN", width: 76, angle: -12, color: Trace.Colors.pen)
                    .opacity(0.85)
                    .padding(14)
                    .allowsHitTesting(false)
            }
        }
        .paper(Trace.Colors.paperCard)
    }

    /// « Affectée au BEN le 13.09.2026 »
    private func assignedLine(_ date: String) -> String {
        identity.id.isFeminine ? L10n.f("profile.assignedOnF", date) : L10n.f("profile.assignedOnM", date)
    }

    // MARK: The record sheet

    private func record(rank: Rank, summary: [String: CaseProgress]) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            career(rank: rank, summary: summary)
            dashedRule
            casesList(summary: summary)
            dashedRule
            distinctions
            dashedRule
            history
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .paper()
    }

    private var dashedRule: some View {
        FlatLine()
            .stroke(Trace.Colors.ink.opacity(0.35), style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
            .frame(height: 1)
            .padding(.vertical, 20)
            .accessibilityHidden(true)
    }

    /// « Parcours »: rank, cases solved, plays, best mark, pieces found; what the next rank takes.
    private func career(rank: Rank, summary: [String: CaseProgress]) -> some View {
        let solved = cases.filter { summary[$0.id]?.solved == true }.count
        let best = attempts.filter(\.ranked).map(\.score).max()
        let found = attempts.reduce(0) { $0 + $1.found }
        let total = attempts.reduce(0) { $0 + $1.total }
        return VStack(alignment: .leading, spacing: 0) {
            SectionHeader(title: L10n.t("profile.career"), color: Trace.Colors.ink2)
            LeaderLine(label: L10n.t("profile.rank"), value: rank.title(feminine: identity.id.isFeminine))
            LeaderLine(label: L10n.t("profile.solved"), value: "\(solved)/\(cases.count)")
            LeaderLine(label: L10n.t("profile.attempts"), value: "\(attempts.count)")
            LeaderLine(label: L10n.t("profile.best"), value: best.map { "\($0)/100" } ?? "—")
            LeaderLine(label: L10n.t("profile.found"), value: total == 0 ? "—" : "\(found * 100 / total) %")
            Text(nextRankLine(rank: rank, solved: summary.values.filter(\.solved).count))
                .font(Trace.Fonts.caption)
                .foregroundStyle(Trace.Colors.ink2)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 10)
        }
    }

    /// « Encore 1 dossier résolu pour Inspecteur », or « Rang maximal atteint. »
    private func nextRankLine(rank: Rank, solved: Int) -> String {
        guard let threshold = rank.nextThreshold, let next = Rank(rawValue: rank.rawValue + 1) else {
            return L10n.t("profile.rankMax")
        }
        let left = max(1, threshold - solved)
        return L10n.f("profile.nextRank", L10n.f("profile.casesToGo", left),
                      next.title(feminine: identity.id.isFeminine).capitalizedFirst)
    }

    /// « Affaires »: « #001 Le dernier message ...... ✓ Résolue · 82/100 ».
    private func casesList(summary: [String: CaseProgress]) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            SectionHeader(title: L10n.t("menu.cases"), color: Trace.Colors.ink2)
            ForEach(cases) { file in
                let state = CaseCardState.of(file, progress: summary[file.id], saved: nil)
                let best = summary[file.id].map(\.bestScore).flatMap { $0 > 0 ? " · \($0)/100" : nil } ?? ""
                LeaderLine(label: "#\(shownNumber(file.number)) \(file.title.capitalizedFirst)",
                           value: state.rowText + best, valueColor: state.inkColor)
            }
        }
    }

    // MARK: Distinctions

    private var distinctions: some View {
        VStack(alignment: .leading, spacing: 0) {
            SectionHeader(title: L10n.t("profile.badges"), color: Trace.Colors.ink2)
            mention(L10n.t("profile.badgeFirst"), earned: attempts.contains { $0.solved })
            mention(L10n.t("profile.badgeNoHelp"), earned: attempts.contains { $0.solved && $0.ranked && $0.hintsUsed == 0 })
            mention(L10n.t("profile.badgePerfect"), earned: attempts.contains { $0.ranked && $0.score >= 100 })
            mention(L10n.t("profile.badgeThorough"), earned: attempts.contains { $0.total > 0 && $0.found == $0.total })
        }
    }

    private func mention(_ title: String, earned: Bool) -> some View {
        LeaderLine(label: title,
                   value: earned ? "✓ " + L10n.t("profile.badgeEarned") : "· " + L10n.t("profile.badgeNotYet"),
                   valueColor: earned ? Trace.Colors.green : Trace.Colors.ink2)
            .accessibilityAddTraits(earned ? .isSelected : [])
    }

    // MARK: History

    /// The last finished attempts, newest first: date, case, result, mark.
    private var history: some View {
        let known = attempts.filter { attempt in cases.contains { $0.id == attempt.caseID } }
        let recent = Array(known.sorted { $0.date > $1.date }.prefix(Self.historyLength))
        return VStack(alignment: .leading, spacing: 0) {
            SectionHeader(title: L10n.t("profile.history"), color: Trace.Colors.ink2)
            if recent.isEmpty {
                Text(L10n.t("archive.emptyMessage"))
                    .font(Trace.Fonts.callout)
                    .foregroundStyle(Trace.Colors.ink2)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                ForEach(recent) { attempt in
                    historyLine(attempt)
                }
            }
        }
    }

    private static let historyLength = 12

    private func historyLine(_ attempt: Attempt) -> some View {
        let file = cases.first { $0.id == attempt.caseID }
        let result = attempt.solved ? "✓ " + L10n.t("case.state.solved") : "✕ " + L10n.t("case.state.unsolved")
        let score = attempt.ranked ? "\(attempt.score)/100" : L10n.t("archive.unranked")
        return HStack(alignment: .firstTextBaseline, spacing: 12) {
            Text(Self.dotted(attempt.date))
                .font(Trace.Fonts.data)
                .foregroundStyle(Trace.Colors.ink2)
            VStack(alignment: .leading, spacing: 2) {
                Text(verbatim: "#\(shownNumber(file?.number ?? 0)) · \(file?.title.capitalizedFirst ?? "")")
                    .font(Trace.Fonts.callout)
                    .foregroundStyle(Trace.Colors.ink)
                    .fixedSize(horizontal: false, vertical: true)
                Text(verbatim: "\(result) · \(score)")
                    .font(Trace.Fonts.data)
                    .foregroundStyle(attempt.solved ? Trace.Colors.green : Trace.Colors.red)
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, 6)
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
                    .foregroundStyle(Trace.Colors.ivory2)
                    .accessibilityHidden(true)
            }
            .font(Trace.Fonts.body)
            .foregroundStyle(Trace.Colors.ivory)
            .padding(.horizontal, 16)
            .frame(minHeight: Trace.Height.row)
            .benCard(Trace.Colors.surface2, radius: Trace.Radius.button)
            .contentShape(Rectangle())
        }
        .buttonStyle(PressableStyle())
        .accessibilityIdentifier("menu.settings")
    }
}

/// A straight horizontal line through the middle of its frame (leaders, dashed rules).
struct FlatLine: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        return path
    }
}
#endif
