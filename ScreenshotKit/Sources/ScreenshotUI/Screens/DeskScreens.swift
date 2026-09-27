#if os(iOS)
import SwiftUI
import CaseEngine

/// « PROCHAINE ENQUÊTE », « AUTRES DOSSIERS »…: a kicker on the desk.
struct DeskOverline: View {
    let text: String
    var body: some View {
        Text(text)
            .font(Trace.Fonts.kicker)
            .tracking(1.8)
            .textCase(.uppercase)
            .foregroundStyle(Trace.Colors.bone2)
            .accessibilityAddTraits(.isHeader)
    }
}

// MARK: - 13 · Bureau

/// What the Bureau shows of the ALIBI mode.
struct AlibiSummary {
    let total: Int
    let done: Int
    let inProgress: Bool
}

/// The hub (final handoff §F-13): one big kraft folder with the investigation in progress or the
/// next one, one main button, the other files as 48 pt rows. No logo here. Before the assignment
/// (screen 12) the header shows the investigator's name only: no rank, no service number.
struct BureauView: View {
    let cases: [CaseFile]
    let progress: [String: CaseProgress]
    let resumable: (saved: SavedInvestigation, file: CaseFile)?
    let featured: CaseFile?
    let identity: PlayerIdentity
    let rank: Rank
    let assigned: Bool
    /// The ALIBI mode's card (nil when no ALIBI check is shipped).
    var alibi: AlibiSummary? = nil
    let onOpen: (CaseFile) -> Void
    let onResume: () -> Void
    var onAlibi: () -> Void = {}
    let onProfile: () -> Void
    let onTab: (DeskTab) -> Void
    /// h02: « ‹ Bureau » back to the three modes.
    var onBack: (() -> Void)? = nil

    @State private var appeared = false
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    @AppStorage(Preferences.reduceMotionKey) private var appReduceMotion = false

    /// Every case is solved and nothing is in progress: a note replaces the folder.
    private var allClosed: Bool {
        resumable == nil && !cases.isEmpty && cases.allSatisfy { progress[$0.id]?.solved == true }
    }

    /// The case on the big folder: the one in progress, or the next one (nil when all are closed,
    /// or while nothing is loaded).
    private var main: CaseFile? {
        allClosed ? nil : (resumable?.file ?? featured)
    }

    var body: some View {
        let main = self.main
        let still = systemReduceMotion || appReduceMotion
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    header
                    if allClosed {
                        closedNote
                            .padding(.top, 10)
                            .opacity(appeared ? 1 : 0)
                            .offset(y: appeared || still ? 0 : 24)
                    } else {
                        DeskOverline(text: resumable != nil ? L10n.t("desk.openFile") : L10n.t("desk.nextInvestigation"))
                            .padding(.top, 10)
                        Button {
                            if let main { onOpen(main) }
                        } label: {
                            FeaturedFolder(file: main,
                                           status: main.map { status(of: $0) } ?? .new,
                                           saved: main.flatMap { saved(for: $0) })
                        }
                        .buttonStyle(PressableStyle())
                        .disabled(main == nil)
                        .accessibilityIdentifier(main.map { "case.\($0.id)" } ?? "home.folder")
                            .opacity(appeared ? 1 : 0)
                            .offset(y: appeared || still ? 0 : 24)
                    }
                    otherFiles(excluding: main)
                    if let alibi {
                        // The second mode: visible, never above the investigation.
                        DeskOverline(text: L10n.t("desk.otherMode"))
                            .padding(.top, 14)
                        AlibiDeskCard(total: alibi.total, done: alibi.done, inProgress: alibi.inProgress, onOpen: onAlibi)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            }
            if let main {
                mainButton(for: main)
            }
            DeskTabBar(selected: .bureau, onSelect: onTab)
        }
        .background(DeskBackdrop())
        .onAppear {
            withAnimation(still ? .easeOut(duration: 0.2) : Trace.Motion.paper) { appeared = true }
        }
    }

    // MARK: Header

    /// « Bureau », the investigator's short name (and rank once assigned), the portrait pill.
    private var header: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                if let onBack {
                    BackChevron(label: L10n.t("tab.bureau"), color: Trace.Colors.boneMid, action: onBack)
                        .accessibilityIdentifier("investigations.back")
                }
                Text(L10n.t(onBack == nil ? "tab.bureau" : "mode.investigations.title"))
                    .font(Trace.Fonts.serifTitle(28))
                    .foregroundStyle(Trace.Colors.bone)
                    .accessibilityAddTraits(.isHeader)
                    .accessibilityIdentifier("home.title")
                Text(agentLine)
                    .font(Trace.Fonts.kicker)
                    .tracking(1.4)
                    .foregroundStyle(Trace.Colors.bone2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 8)
            Button(action: onProfile) {
                PortraitOrInitials(image: ArtLibrary.image(identity.portraitName), initials: identity.id.initials,
                                   width: Self.pill, height: Self.pill)
                    .clipShape(Circle())
                    .overlay(Circle().strokeBorder(Trace.Colors.bone.opacity(0.35), lineWidth: 1))
                    .contentShape(Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text(verbatim: "\(L10n.t("tab.investigator")), \(identity.id.fullName)"))
            .accessibilityIdentifier("home.profile")
        }
        .padding(.top, 12)
    }

    private static let pill: CGFloat = 44

    /// « É. MOREL · INSPECTEUR », or « É. MOREL » before the assignment.
    private var agentLine: String {
        assigned ? "\(identity.id.shortName) · \(rank.title)" : identity.id.shortName
    }

    // MARK: Main button

    /// [OUVRIR LE DOSSIER], or [REPRENDRE L'ENQUÊTE] when this case is in progress.
    @ViewBuilder
    private func mainButton(for file: CaseFile) -> some View {
        Group {
            if resumable?.file.id == file.id {
                Button(L10n.t("home.resume"), action: onResume)
                    .accessibilityIdentifier("home.resume")
            } else {
                Button(L10n.t("home.start")) { onOpen(file) }
                    .accessibilityIdentifier("home.start")
            }
        }
        .buttonStyle(CTAButtonStyle())
        .padding(.horizontal, 24)
        .padding(.vertical, 10)
    }

    // MARK: All closed

    /// Every case solved: a sheet of paper and a link to the Archives.
    private var closedNote: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(L10n.t("desk.allClosed"))
                .font(Trace.Fonts.quote)
                .foregroundStyle(Trace.Colors.ink)
                .fixedSize(horizontal: false, vertical: true)
            Button(L10n.t("desk.openArchives")) { onTab(.archives) }
                .buttonStyle(TextLinkStyle(onPaper: true))
                .accessibilityIdentifier("desk.archives")
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .paper(Trace.Colors.paper, radius: 0, lifted: true)
    }

    // MARK: Other files

    @ViewBuilder
    private func otherFiles(excluding main: CaseFile?) -> some View {
        let others = cases.filter { $0.id != main?.id }
        if !others.isEmpty {
            DeskOverline(text: L10n.t("desk.otherFiles"))
                .padding(.top, 14)
            VStack(spacing: 0) {
                ForEach(others, id: \.id) { file in
                    CaseRow(file: file, status: status(of: file)) { onOpen(file) }
                }
            }
        }
    }

    private func status(of file: CaseFile) -> DossierStatus {
        DossierStatus.of(file, progress: progress[file.id], savedCaseID: resumable?.file.id)
    }

    private func saved(for file: CaseFile) -> SavedInvestigation? {
        resumable?.file.id == file.id ? resumable?.saved : nil
    }
}

/// The big kraft folder of the Bureau (354 × 300 pt): tab n°, category · city, title, tagline on
/// two lines, difficulty, duration (time left when in progress), status, and a clipped print (the
/// subject's portrait, or a neutral generated photo). Without a case (loading): an empty folder.
private struct FeaturedFolder: View {
    let file: CaseFile?
    var status: DossierStatus = .new
    var saved: SavedInvestigation? = nil
    @Environment(\.dynamicTypeSize) private var typeSize

    private static let maxWidth: CGFloat = 354
    private static let bodyHeight: CGFloat = 272
    private static let printWidth: CGFloat = 72
    /// Scene of the generated print when the case has no subject portrait.
    private static let neutralScene = "street_night"

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            folderTab
            Group {
                if let file {
                    content(file)
                } else {
                    Color.clear
                }
            }
            .frame(maxWidth: .infinity, minHeight: Self.bodyHeight, alignment: .topLeading)
            .kraft()
            .overlay(alignment: .topTrailing) {
                if let file {
                    clippedPrint(file)
                }
            }
        }
        .frame(maxWidth: Self.maxWidth)
        .frame(maxWidth: .infinity)
    }

    private var folderTab: some View {
        Text(file.map { L10n.f("dossier.tabNumber", shownNumber($0.number)) } ?? " ")
            .font(Trace.Fonts.pieceNumber)
            .tracking(1.4)
            .foregroundStyle(Trace.Colors.kraftInk)
            .padding(.horizontal, 14)
            .frame(minWidth: 64, minHeight: 28)
            .background(UnevenRoundedRectangle(topLeadingRadius: 8, topTrailingRadius: 8).fill(Trace.Colors.kraftDark))
            .accessibilityHidden(true)
    }

    private func content(_ file: CaseFile) -> some View {
        let facts = DossierFacts(file: file)
        return VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 8) {
                Text([facts.category, facts.city].filter { !$0.isEmpty }.joined(separator: " · "))
                    .font(Trace.Fonts.kicker)
                    .tracking(1.6)
                    .textCase(.uppercase)
                    .foregroundStyle(Trace.Colors.kraftLabel)
                    .fixedSize(horizontal: false, vertical: true)
                Text(file.title.capitalizedFirst)
                    .font(Trace.Fonts.serifTitle(26))
                    .foregroundStyle(Trace.Colors.kraftInk)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityLabel(Text(verbatim: "\(fileLabel(file.number)), \(file.title.capitalizedFirst)"))
                    .accessibilityAddTraits(.isHeader)
                Text(file.tagline)
                    .font(Trace.Fonts.prose)
                    .foregroundStyle(Trace.Colors.kraftInk.opacity(0.85))
                    .lineLimit(typeSize.isAccessibilitySize ? nil : 2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.trailing, Self.printWidth + 22)
            .frame(minHeight: 150, alignment: .topLeading)

            Rectangle()
                .stroke(Trace.Colors.kraftLabel, style: StrokeStyle(lineWidth: 1, dash: [4, 3]))
                .frame(height: 1)
                .padding(.top, 14)
                .padding(.bottom, 12)
                .accessibilityHidden(true)

            factsRow(file, facts: facts)

            if let saved {
                Text(L10n.f("dossier.piecesCount", saved.snapshot.notebook.count))
                    .font(Trace.Fonts.fieldValue)
                    .foregroundStyle(Trace.Colors.kraftInk)
                    .padding(.top, 10)
                    .accessibilityIdentifier("home.resumeMeta")
            }
        }
        .padding(18)
    }

    /// Difficulty · duration (or time left) · status; stacked at accessibility sizes.
    private func factsRow(_ file: CaseFile, facts: DossierFacts) -> some View {
        let layout = typeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 10))
            : AnyLayout(HStackLayout(alignment: .top, spacing: 12))
        return layout {
            fact(L10n.t("dossier.difficulty")) {
                DifficultyMeter(level: facts.rating, color: Trace.Colors.kraftInk)
            }
            if let saved {
                fact(L10n.t("result.timeLeft")) {
                    value(PhoneFormat.countdown(saved.remainingSeconds))
                }
            } else {
                fact(L10n.t("desk.duration")) {
                    value(L10n.f("desk.minutes", Self.minutes(of: file)))
                }
            }
            fact(L10n.t("dossier.state")) {
                value(status.title, color: status == .open ? Trace.Colors.stamp : Trace.Colors.kraftInk)
            }
        }
    }

    private func fact<Content: View>(_ label: String, @ViewBuilder _ content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label).fieldLabel(Trace.Colors.kraftLabel)
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    private func value(_ text: String, color: Color = Trace.Colors.kraftInk) -> some View {
        Text(text)
            .font(Trace.Fonts.fieldValue)
            .foregroundStyle(color)
            .textCase(.uppercase)
            .fixedSize(horizontal: false, vertical: true)
    }

    /// The print clipped to the folder: the subject's portrait (initials on BEN blue if it is not
    /// delivered), or a neutral generated photo for a case without a person at its centre.
    private func clippedPrint(_ file: CaseFile) -> some View {
        let facts = DossierFacts(file: file)
        let height = Self.printWidth * 1.25
        return PhotoPrint(border: 4) {
            if let contact = facts.subjectContact() {
                PortraitOrInitials(image: ArtLibrary.portrait(case: file.number, contact: contact),
                                   initials: contact.initials, width: Self.printWidth, height: height)
            } else {
                GeneratedPhoto(scene: Self.neutralScene, seed: file.id)
                    .frame(width: Self.printWidth, height: height)
            }
        }
        .overlay(alignment: .topLeading) {
            Paperclip().frame(width: 14, height: 36).offset(x: 14, y: -16)
        }
        .rotationEffect(.degrees(3))
        .padding(.top, 20)
        .padding(.trailing, 16)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    /// Minutes of the intended level (« Temps détendu » included).
    private static func minutes(of file: CaseFile) -> Int {
        let base = file.challengeDurations?[Challenge.detective.rawValue] ?? file.durationSeconds
        let seconds = Preferences.relaxedTime ? Double(base) * Preferences.relaxedTimeFactor : Double(base)
        return max(1, Int((seconds / 60).rounded()))
    }
}

/// A file under « AUTRES DOSSIERS »: n°, title, status in words (RÉSOLU in red, with the word).
private struct CaseRow: View {
    let file: CaseFile
    let status: DossierStatus
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(alignment: .center, spacing: 14) {
                Text(shownNumber(file.number))
                    .font(Trace.Fonts.monoStrong)
                    .foregroundStyle(Trace.Colors.bone2)
                Text(file.title.capitalizedFirst)
                    .font(Trace.Fonts.name)
                    .foregroundStyle(Trace.Colors.bone)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 8)
                Text(status.title)
                    .font(Trace.Fonts.kicker)
                    .tracking(1.2)
                    .textCase(.uppercase)
                    .foregroundStyle(statusColor)
                    .multilineTextAlignment(.trailing)
            }
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity, minHeight: 48, alignment: .leading)
            .overlay(alignment: .bottom) { Rectangle().fill(Trace.Colors.graphite).frame(height: 1) }
            .contentShape(Rectangle())
        }
        .buttonStyle(PressableStyle())
        .accessibilityLabel(Text(verbatim: "\(fileLabel(file.number)), \(file.title.capitalizedFirst), \(status.title)"))
        .accessibilityIdentifier("case.\(file.id)")
    }

    private var statusColor: Color {
        switch status {
        case .solved: Trace.Colors.stampOnDark
        case .open: Trace.Colors.bone
        case .new, .unsolved: Trace.Colors.bone2
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

// MARK: - Archives

/// Every case file as a bristol card; each state reads without colour (border + bar, stamp,
/// dashed stamp, call to action).
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
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .firstTextBaseline) {
                    Text(L10n.t("archives.title")).font(Trace.Fonts.serifTitle(28)).foregroundStyle(Trace.Colors.bone)
                        .accessibilityAddTraits(.isHeader)
                    Spacer()
                    Text(L10n.f("archives.count", cases.count)).font(Trace.Fonts.monoSmall).tracking(1.5).foregroundStyle(Trace.Colors.bone2)
                }
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        chip(.all, L10n.t("archives.all"))
                        chip(.open, L10n.t("archives.open"))
                        chip(.solved, L10n.t("archives.solved"))
                        chip(.unsolved, L10n.t("archives.unsolved"))
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 10)
            ScrollView {
                LazyVStack(spacing: 14) {
                    ForEach(visible) { file in
                        ArchiveCard(file: file, status: status(file), progress: progress[file.id],
                                    lastAttempt: attempts.last { $0.caseID == file.id }) { onOpen(file) }
                    }
                    if visible.isEmpty {
                        EmptyPage(title: L10n.t("archives.empty"), tip: L10n.t("archives.emptyTip"))
                            .padding(18)
                            .paper(Trace.Colors.print)
                    }
                }
                .padding(.horizontal, 16)
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

    private func chip(_ value: Filter, _ title: String) -> some View {
        let on = filter == value
        return Button {
            withAnimation(Trace.Motion.standard) { filter = value }
            Haptics.selection()
        } label: {
            Text(title).font(.custom(Theme.FontName.medium, size: 13))
                .foregroundStyle(on ? Trace.Colors.ink : Trace.Colors.bone)
                .padding(.horizontal, 14).frame(minHeight: 32)
                .background(Capsule().fill(on ? Trace.Colors.bone : .clear))
                .overlay(Capsule().strokeBorder(on ? .clear : Trace.Colors.graphite, lineWidth: 1))
                .frame(minHeight: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(on ? .isSelected : [])
    }
}

/// A bristol archive card.
struct ArchiveCard: View {
    let file: CaseFile
    let status: DossierStatus
    let progress: CaseProgress?
    let lastAttempt: Attempt?
    let onOpen: () -> Void

    var body: some View {
        let facts = DossierFacts(file: file)
        Button(action: onOpen) {
            HStack(alignment: .top, spacing: 0) {
                Text(shownNumber(file.number)).font(.custom(Trace.FontName.monoBold, size: 20)).foregroundStyle(Trace.Colors.ink)
                    .frame(width: 58, alignment: .leading)
                VStack(alignment: .leading, spacing: 5) {
                    Text(file.title.capitalizedFirst).font(Trace.Fonts.name).foregroundStyle(Trace.Colors.ink)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.trailing, 70)
                    Text("\(facts.category) · \(facts.city)".uppercased()).font(Trace.Fonts.monoSmall).foregroundStyle(Trace.Colors.inkSoft)
                        .fixedSize(horizontal: false, vertical: true)
                    footer(facts)
                }
                Spacer(minLength: 0)
            }
            .padding(.vertical, 14).padding(.leading, 16).padding(.trailing, 12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .paper(Trace.Colors.paperAged, radius: 2)
            .overlay(alignment: .leading) {
                if status == .open { Rectangle().fill(Trace.Colors.stamp).frame(width: 4) }
            }
            .overlay(alignment: .topTrailing) { stamp.padding(12) }
            .contentShape(Rectangle())
        }
        .buttonStyle(PressableStyle())
        .accessibilityIdentifier("case.\(file.id)")
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private var stamp: some View {
        switch status {
        case .solved: StampMark(text: (progress?.bestScore ?? 0) >= 100 ? L10n.t("stamp.perfect") : L10n.t("stamp.solved"), size: 10)
        case .unsolved: StampMark(text: L10n.t("stamp.unsolved"), size: 9, dashed: true, angle: -3)
        case .open, .new: EmptyView()
        }
    }

    @ViewBuilder
    private func footer(_ facts: DossierFacts) -> some View {
        switch status {
        case .open:
            HStack(spacing: 8) {
                Capsule().fill(Trace.Colors.ink).frame(width: 60, height: 3)
                Text(L10n.t("status.open")).font(Trace.Fonts.monoSmall.weight(.bold)).foregroundStyle(Trace.Colors.ink)
            }
        case .new:
            HStack {
                DifficultyMeter(level: facts.rating)
                Spacer()
                Text(L10n.t("archives.openCTA")).font(Trace.Fonts.monoSmall.weight(.bold)).tracking(1.2).foregroundStyle(Trace.Colors.bone)
                    .padding(.horizontal, 12).frame(height: 30).background(RoundedRectangle(cornerRadius: 5).fill(Trace.Colors.ink))
            }
        case .solved:
            Text(L10n.f("archives.closedOn", lastAttempt.map { $0.date.formatted(.dateTime.day(.twoDigits).month(.twoDigits)) } ?? "—", progress?.bestScore ?? 0))
                .font(Trace.Fonts.monoSmall.weight(.semibold)).foregroundStyle(Trace.Colors.ink)
        case .unsolved:
            Text(L10n.f("archives.attempts", progress?.plays ?? 0)).font(Trace.Fonts.monoSmall).foregroundStyle(Trace.Colors.inkSoft)
        }
    }
}

// MARK: - Enquêteur (profile)

/// The investigator's profile (tab 3). Before the assignment (screen 12): identity only — print,
/// name, title, short bio — with no service number, rank or hierarchy. After it: the agent card
/// (service number, rank and its stamp, date of assignment), the service record with the next
/// rank, the cases, the distinctions and the history. Changing investigator (or appearance) reuses
/// screen 03; the settings are at the bottom.
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
                VStack(alignment: .leading, spacing: 20) {
                    Text(L10n.t("investigator.title"))
                        .font(Trace.Fonts.serifTitle(28))
                        .foregroundStyle(Trace.Colors.bone)
                        .accessibilityAddTraits(.isHeader)
                        .accessibilityIdentifier("profile.view")
                        .padding(.top, 12)
                    if assigned {
                        agentCard(rank: rank)
                        career(rank: rank, summary: summary)
                        casesSheet(summary: summary)
                        distinctions
                        history
                    } else {
                        identitySheet
                    }
                    Button(assigned ? L10n.t("profile.changeIdentity") : L10n.t("profile.changeInvestigator")) {
                        changing = true
                    }
                    .buttonStyle(CTAButtonStyle(kind: .outline, height: 48))
                    .accessibilityIdentifier("profile.changeIdentity")
                    settingsRow
                }
                .padding(.horizontal, 16)
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

    // MARK: Identity

    /// Print beside the name; stacked at accessibility sizes.
    private var printLayout: AnyLayout {
        typeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 14))
            : AnyLayout(HStackLayout(alignment: .top, spacing: 16))
    }

    /// Before the assignment: who investigates, nothing of the career.
    private var identitySheet: some View {
        let layout = printLayout
        return VStack(alignment: .leading, spacing: 14) {
            Text(L10n.t("profile.identity")).fieldLabel()
            layout {
                PlayerPrint(identity: identity, width: 96, border: 5)
                VStack(alignment: .leading, spacing: 6) {
                    Text(identity.id.fullName)
                        .font(Trace.Fonts.nameLarge)
                        .foregroundStyle(Trace.Colors.ink)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(identity.id.title)
                        .font(Trace.Fonts.monoStrong)
                        .tracking(1.4)
                        .foregroundStyle(Trace.Colors.inkSoft)
                }
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .paper(Trace.Colors.paper, radius: 0, lifted: true)
    }

    /// After the assignment: the agent card — print, name, service number, rank and its stamp.
    private func agentCard(rank: Rank) -> some View {
        let layout = printLayout
        return VStack(alignment: .leading, spacing: 0) {
            Text(L10n.t("profile.agentCard"))
                .font(Trace.Fonts.kicker)
                .tracking(1.8)
                .textCase(.uppercase)
                .foregroundStyle(Trace.Colors.bone)
                .padding(.horizontal, 16)
                .frame(maxWidth: .infinity, minHeight: 34, alignment: .leading)
                .background(Trace.Colors.ink)
            layout {
                PlayerPrint(identity: identity, width: 96, border: 5)
                VStack(alignment: .leading, spacing: 4) {
                    Text(identity.id.fullName)
                        .font(Trace.Fonts.nameLarge)
                        .foregroundStyle(Trace.Colors.ink)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(identity.id.title)
                        .font(Trace.Fonts.monoStrong)
                        .tracking(1.4)
                        .foregroundStyle(Trace.Colors.inkSoft)
                        .padding(.bottom, 4)
                    FieldRow(label: L10n.t("investigator.number"), value: identity.id.serviceNumber)
                    FieldRow(label: L10n.t("profile.rank"), value: rank.title, divider: false)
                }
            }
            .padding(16)
            Text(identity.id.bio)
                .font(Trace.Fonts.proseSmall)
                .foregroundStyle(Trace.Colors.inkMid)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 16)
                .padding(.bottom, 12)
            HStack(alignment: .center, spacing: 12) {
                if let date = PlayerStore.assignedDate {
                    Text(assignedLine(Self.dotted(date)))
                        .font(Trace.Fonts.proseSmall)
                        .foregroundStyle(Trace.Colors.inkMid)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 8)
                StampImage(asset: rank.stampAsset, label: rank.title, width: 104, onPaper: true, angle: -8)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .background(Trace.Colors.print.overlay(PaperGrain()))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .shadow(color: .black.opacity(0.5), radius: 16, y: 12)
    }

    /// « Affectée au BEN le 13.09.2026 »
    private func assignedLine(_ date: String) -> String {
        identity.id.isFeminine ? L10n.f("profile.assignedOnF", date) : L10n.f("profile.assignedOnM", date)
    }

    // MARK: Career

    /// « Parcours »: rank, what the next one takes, cases solved, attempts, best score, pieces found.
    private func career(rank: Rank, summary: [String: CaseProgress]) -> some View {
        let solved = cases.filter { summary[$0.id]?.solved == true }.count
        let ranked = attempts.filter(\.ranked)
        let best = ranked.map(\.score).max()
        let found = attempts.reduce(0) { $0 + $1.found }
        let total = attempts.reduce(0) { $0 + $1.total }
        return VStack(alignment: .leading, spacing: 0) {
            Text(L10n.t("profile.career")).fieldLabel().padding(.bottom, 6)
            LedgerRow(label: L10n.t("profile.rank"), value: rank.title)
            Text(nextRankLine(rank: rank, solved: summary.values.filter(\.solved).count))
                .font(Trace.Fonts.proseSmall)
                .foregroundStyle(Trace.Colors.inkMid)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .overlay(alignment: .bottom) { Rectangle().fill(Trace.Colors.ruled.opacity(2)).frame(height: 1) }
            LedgerRow(label: L10n.t("profile.solved"), value: "\(solved) / \(cases.count)")
            LedgerRow(label: L10n.t("profile.attempts"), value: "\(attempts.count)")
            LedgerRow(label: L10n.t("profile.best"), value: best.map { "\($0) / 100" } ?? "—")
            LedgerRow(label: L10n.t("profile.found"), value: total == 0 ? "—" : "\(found * 100 / total) %")
        }
        .padding(18)
        .paper(Trace.Colors.paper)
    }

    /// « Encore 1 dossier résolu pour INSPECTEUR », or « Rang maximal atteint. »
    private func nextRankLine(rank: Rank, solved: Int) -> String {
        guard let threshold = rank.nextThreshold, let next = Rank(rawValue: rank.rawValue + 1) else {
            return L10n.t("profile.rankMax")
        }
        let left = max(1, threshold - solved)
        return L10n.f("profile.nextRank", L10n.f("profile.casesToGo", left), next.title)
    }

    // MARK: Cases

    /// One line per case: n°, title, result in words, best score.
    private func casesSheet(summary: [String: CaseProgress]) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(L10n.t("menu.cases")).fieldLabel().padding(.bottom, 4)
            ForEach(cases, id: \.id) { file in
                caseLine(file, progress: summary[file.id])
            }
        }
        .padding(18)
        .paper(Trace.Colors.paper)
    }

    private func caseLine(_ file: CaseFile, progress: CaseProgress?) -> some View {
        let status = DossierStatus.of(file, progress: progress, savedCaseID: nil)
        return HStack(alignment: .firstTextBaseline, spacing: 10) {
            Text(shownNumber(file.number))
                .font(Trace.Fonts.fieldValue)
                .foregroundStyle(Trace.Colors.inkSoft)
            Text(file.title.capitalizedFirst)
                .font(Trace.Fonts.prose)
                .foregroundStyle(status == .new ? Trace.Colors.inkSoft : Trace.Colors.ink)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 8)
            VStack(alignment: .trailing, spacing: 2) {
                Text(status.title)
                    .font(Trace.Fonts.kicker)
                    .tracking(1)
                    .textCase(.uppercase)
                    .foregroundStyle(status == .solved ? Trace.Colors.stamp : Trace.Colors.inkSoft)
                if let progress, progress.bestScore > 0 {
                    Text(verbatim: "\(progress.bestScore) / 100")
                        .font(Trace.Fonts.fieldValue)
                        .foregroundStyle(Trace.Colors.ink)
                }
            }
        }
        .padding(.vertical, 10)
        .frame(minHeight: 48)
        .overlay(alignment: .bottom) { Rectangle().fill(Trace.Colors.ruled.opacity(2)).frame(height: 1) }
        .accessibilityElement(children: .combine)
    }

    // MARK: Distinctions

    private var distinctions: some View {
        let columns = typeSize.isAccessibilitySize
            ? [GridItem(.flexible())]
            : [GridItem(.flexible()), GridItem(.flexible())]
        let solvedAny = attempts.contains { $0.solved }
        return VStack(alignment: .leading, spacing: 12) {
            DeskOverline(text: L10n.t("profile.badges"))
            LazyVGrid(columns: columns, spacing: 12) {
                mention(L10n.t("profile.badgeFirst"), earned: solvedAny)
                mention(L10n.t("profile.badgeNoHelp"), earned: attempts.contains { $0.solved && $0.ranked && $0.hintsUsed == 0 })
                mention(L10n.t("profile.badgePerfect"), earned: attempts.contains { $0.ranked && $0.score >= 100 })
                mention(L10n.t("profile.badgeThorough"), earned: attempts.contains { $0.total > 0 && $0.found == $0.total })
            }
        }
    }

    private func mention(_ title: String, earned: Bool) -> some View {
        VStack(spacing: 8) {
            StampMark(text: earned ? L10n.t("stamp.mention") : "· · ·", color: earned ? Trace.Colors.stamp : Trace.Colors.inkFaint, size: 9,
                      dashed: !earned, angle: earned ? -5 : 0)
            Text(title).font(Trace.Fonts.proseSmall).foregroundStyle(earned ? Trace.Colors.ink : Trace.Colors.inkSoft)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, minHeight: 96)
        .padding(10)
        .paper(Trace.Colors.paperAged)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(earned ? .isSelected : [])
    }

    // MARK: History

    /// The last finished attempts, newest first: date, case, result, score.
    private var history: some View {
        let known = attempts.filter { attempt in cases.contains { $0.id == attempt.caseID } }
        let recent = Array(known.sorted { $0.date > $1.date }.prefix(Self.historyLength))
        return VStack(alignment: .leading, spacing: 0) {
            Text(L10n.t("profile.history")).fieldLabel().padding(.bottom, 4)
            if recent.isEmpty {
                Text(L10n.t("archive.emptyMessage"))
                    .font(Trace.Fonts.proseSmall)
                    .foregroundStyle(Trace.Colors.inkSoft)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.vertical, 10)
            } else {
                ForEach(recent) { attempt in
                    historyLine(attempt)
                }
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .paper(Trace.Colors.paper)
    }

    private static let historyLength = 12

    private func historyLine(_ attempt: Attempt) -> some View {
        let file = cases.first { $0.id == attempt.caseID }
        let result = attempt.solved ? DossierStatus.solved.title : DossierStatus.unsolved.title
        let score = attempt.ranked ? "\(attempt.score) / 100" : L10n.t("archive.unranked")
        return HStack(alignment: .firstTextBaseline, spacing: 10) {
            Text(Self.dotted(attempt.date))
                .font(Trace.Fonts.fieldValue)
                .foregroundStyle(Trace.Colors.inkSoft)
            VStack(alignment: .leading, spacing: 2) {
                Text(verbatim: "\(shownNumber(file?.number ?? 0)) · \(file?.title.capitalizedFirst ?? "")")
                    .font(Trace.Fonts.proseSmall)
                    .foregroundStyle(Trace.Colors.ink)
                    .fixedSize(horizontal: false, vertical: true)
                Text(verbatim: "\(result.uppercased()) · \(score)")
                    .font(Trace.Fonts.monoSmall)
                    .foregroundStyle(attempt.solved ? Trace.Colors.stamp : Trace.Colors.inkSoft)
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, 8)
        .overlay(alignment: .bottom) { Rectangle().fill(Trace.Colors.ruled.opacity(2)).frame(height: 1) }
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
                    .foregroundStyle(Trace.Colors.bone2)
                    .accessibilityHidden(true)
            }
            .font(Trace.Fonts.uiBody)
            .foregroundStyle(Trace.Colors.bone)
            .padding(.horizontal, 16)
            .frame(minHeight: 52)
            .background(RoundedRectangle(cornerRadius: 8).fill(Trace.Colors.graphite))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("menu.settings")
    }
}
#endif
