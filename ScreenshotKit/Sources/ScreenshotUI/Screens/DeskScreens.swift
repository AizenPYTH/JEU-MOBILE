#if os(iOS)
import SwiftUI
import CaseEngine

// MARK: - Wordmark

/// TRACE / BUREAU DES ENQUÊTES — mono, wide tracking.
struct TraceWordmark: View {
    var subtitle: String = L10n.t("desk.subtitle")

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("TRACE").font(Trace.Fonts.wordmark).tracking(9).foregroundStyle(Trace.Colors.bone)
            Text(subtitle).font(Trace.Fonts.monoSmall).tracking(2.6).foregroundStyle(Trace.Colors.bone2)
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
    }
}

/// "DOSSIER OUVERT", "AUTRES DOSSIERS"…
struct DeskOverline: View {
    let text: String
    var body: some View {
        Text(text).font(Trace.Fonts.fieldLabel).tracking(2.4).foregroundStyle(Trace.Colors.bone2)
    }
}

// MARK: - 02 · Bureau

/// The desk: the case in progress (or the next one) lies flat, open; the others are in a drawer.
struct BureauView: View {
    let cases: [CaseFile]
    let progress: [String: CaseProgress]
    let resumable: (saved: SavedInvestigation, file: CaseFile)?
    let featured: CaseFile?
    let rank: String
    let onOpen: (CaseFile) -> Void
    let onResume: () -> Void
    let onTab: (DeskTab) -> Void

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    HStack(alignment: .top) {
                        TraceWordmark()
                        Spacer()
                        Button { onTab(.investigator) } label: {
                            HStack(spacing: 8) {
                                Text("ENQ").font(Trace.Fonts.monoSmall.weight(.bold)).foregroundStyle(Trace.Colors.ink)
                                    .frame(width: 30, height: 30).background(Circle().fill(Trace.Colors.paper))
                                Text(rank).font(Trace.Fonts.ui).foregroundStyle(Trace.Colors.bone).lineLimit(1)
                            }
                            .padding(.leading, 5).padding(.trailing, 12).frame(height: 40)
                            .background(Capsule().fill(Trace.Colors.graphite))
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(Text(L10n.t("tab.investigator")))
                    }
                    .padding(.top, 8)

                    if let featured {
                        DeskOverline(text: resumable != nil ? L10n.t("desk.openFile") : L10n.t("desk.nextFile"))
                        FolderCard(file: featured, progress: progress[featured.id], saved: resumable?.file.id == featured.id ? resumable?.saved : nil,
                                   onOpen: { onOpen(featured) }, onResume: onResume)
                    }

                    let others = cases.filter { $0.id != featured?.id }
                    if !others.isEmpty {
                        DeskOverline(text: L10n.t("desk.otherFiles")).padding(.top, 8)
                        VStack(spacing: -8) {
                            ForEach(Array(others.enumerated()), id: \.element.id) { offset, file in
                                FolderTabRow(file: file, status: DossierStatus.of(file, progress: progress[file.id], savedCaseID: resumable?.file.id),
                                             score: progress[file.id]?.bestScore, shade: offset) { onOpen(file) }
                                    .zIndex(Double(offset))
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            }
            DeskTabBar(selected: .bureau, onSelect: onTab)
        }
        .background(TraceDesk())
    }
}

/// The open case file lying on the desk: tab N°, kraft folder with a sheet peeking out, the taped
/// print, CONFIDENTIEL, the typed fields, and the ink button.
struct FolderCard: View {
    let file: CaseFile
    let progress: CaseProgress?
    let saved: SavedInvestigation?
    let onOpen: () -> Void
    let onResume: () -> Void

    var body: some View {
        let facts = DossierFacts(file: file)
        let status = saved != nil ? DossierStatus.open : DossierStatus.of(file, progress: progress, savedCaseID: nil)
        VStack(alignment: .leading, spacing: 0) {
            // The tab and the sheet peeking out of the folder.
            HStack(alignment: .bottom, spacing: 0) {
                Text(L10n.f("dossier.tabNumber", dossierNumber(file.number)))
                    .font(Trace.Fonts.pieceNumber).tracking(1.4).foregroundStyle(Trace.Colors.kraftInk)
                    .padding(.horizontal, 14).frame(height: 28)
                    .background(UnevenRoundedRectangle(topLeadingRadius: 8, topTrailingRadius: 8).fill(Trace.Colors.kraftDark))
                Rectangle().fill(Trace.Colors.paper).frame(height: 10).padding(.trailing, 70).rotationEffect(.degrees(-1.2))
            }
            Button(action: onOpen) {
                VStack(alignment: .leading, spacing: 10) {
                    Text(L10n.f("dossier.number", dossierNumber(file.number))).fieldLabel(Trace.Colors.kraftLabel)
                    Text(file.title.uppercased())
                        .font(Trace.Fonts.caseTitle).foregroundStyle(Trace.Colors.kraftInk)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.trailing, 110)
                    Text("\(facts.category) · \(facts.city)".uppercased())
                        .font(Trace.Fonts.fieldValue).tracking(1).foregroundStyle(Trace.Colors.kraftInk)
                    StampMark(text: L10n.t("stamp.confidential"), size: 12, angle: -4).padding(.vertical, 4)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("case.\(file.id)")
            .padding(.horizontal, 18).padding(.top, 18)

            Rectangle().stroke(Trace.Colors.kraftLabel, style: StrokeStyle(lineWidth: 1, dash: [4, 3])).frame(height: 1)
                .padding(.horizontal, 18).padding(.vertical, 12)

            Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 10) {
                GridRow {
                    field(L10n.t("dossier.state"), status.title, color: status == .open ? Trace.Colors.stamp : Trace.Colors.kraftInk)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(L10n.t("dossier.difficulty")).fieldLabel(Trace.Colors.kraftLabel)
                        DifficultyMeter(level: facts.rating, color: Trace.Colors.kraftInk)
                    }
                }
                GridRow {
                    field(L10n.t("dossier.pieces"), saved.map { L10n.f("dossier.piecesCount", $0.snapshot.notebook.count) } ?? "—")
                        .accessibilityIdentifier("home.resumeMeta")
                    field(L10n.t("dossier.place"), facts.place)
                }
            }
            .padding(.horizontal, 18)

            Group {
                if let saved {
                    Button(action: onResume) {
                        HStack {
                            Text(L10n.t("home.resume"))
                            Spacer()
                            Text(PhoneFormat.countdown(saved.remainingSeconds)).foregroundStyle(Trace.Colors.stampOnDark)
                        }
                        .padding(.horizontal, 18)
                    }
                    .buttonStyle(InkButtonStyle())
                    .accessibilityIdentifier("home.resume")
                } else {
                    Button(action: onOpen) {
                        HStack {
                            Text(L10n.t("home.start"))
                            Spacer()
                            Text(PhoneFormat.countdown(Double(file.durationSeconds))).foregroundStyle(Trace.Colors.bone2)
                        }
                        .padding(.horizontal, 18)
                    }
                    .buttonStyle(InkButtonStyle())
                    .accessibilityIdentifier("home.start")
                }
            }
            .padding(18)
        }
        .kraft()
        .overlay(alignment: .topTrailing) {
            // The print taped to the folder, overflowing its edge.
            PhotoPrint(caption: facts.subject, border: 6) {
                if let contact = facts.subjectContact() {
                    Portrait(contact: contact, width: 92, height: 92).saturation(0.3)
                } else {
                    GeneratedPhoto(scene: file.introScene?.shots.first { $0.scene != nil }?.scene ?? "vitrine", seed: file.id)
                        .frame(width: 92, height: 92)
                }
            }
            .frame(width: 110)
            .overlay(alignment: .top) { Tape().offset(y: -8) }
            .rotationEffect(.degrees(5))
            .offset(x: 6, y: 12)
            .allowsHitTesting(false)
        }
    }

    private func field(_ label: String, _ value: String, color: Color = Trace.Colors.kraftInk) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(label).fieldLabel(Trace.Colors.kraftLabel)
            Text(value).font(Trace.Fonts.fieldValue).foregroundStyle(color).textCase(.uppercase).lineLimit(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }
}

/// A folder in the drawer: its tab (number, title, city) and its status badge.
struct FolderTabRow: View {
    let file: CaseFile
    let status: DossierStatus
    let score: Int?
    let shade: Int
    let onOpen: () -> Void

    private let shades = [Trace.Colors.kraftLight, Trace.Colors.kraft, Trace.Colors.kraftMid, Trace.Colors.kraftDark]

    var body: some View {
        Button(action: onOpen) {
            HStack(spacing: 12) {
                Text(dossierNumber(file.number)).font(Trace.Fonts.fieldValue).foregroundStyle(Trace.Colors.kraftInk)
                Text(file.title.capitalizedFirst).font(Trace.Fonts.name).foregroundStyle(Trace.Colors.kraftInk).lineLimit(1)
                Spacer(minLength: 6)
                Text(DossierFacts(file: file).city.uppercased()).font(Trace.Fonts.monoSmall).foregroundStyle(Trace.Colors.kraftLabel).lineLimit(1)
                badge
            }
            .padding(.horizontal, 16)
            .frame(height: 56)
            .frame(maxWidth: .infinity)
            .background(
                UnevenRoundedRectangle(topLeadingRadius: 8, bottomLeadingRadius: 2, bottomTrailingRadius: 2, topTrailingRadius: 8)
                    .fill(shades[shade % shades.count])
                    .shadow(color: .black.opacity(0.35), radius: 7, y: -4)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(PressableStyle())
        .accessibilityIdentifier("case.\(file.id)")
        .accessibilityLabel(Text("\(L10n.f("dossier.number", dossierNumber(file.number))), \(file.title), \(status.title)"))
    }

    @ViewBuilder
    private var badge: some View {
        switch status {
        case .solved: StampMark(text: L10n.t("stamp.solved"), size: 8, angle: -4)
        case .unsolved: StampMark(text: L10n.t("stamp.unsolved"), size: 8, dashed: true, angle: -3)
        case .open: StampMark(text: L10n.t("stamp.resume"), size: 8, dashed: true, angle: -3)
        case .new: StampMark(text: L10n.t("stamp.new"), color: Trace.Colors.ink, size: 8, angle: 0, filled: true)
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

// MARK: - 03 · Archives

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
                    Text(L10n.t("archives.title")).font(Trace.Fonts.screenTitle).foregroundStyle(Trace.Colors.bone)
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
        .background(TraceDesk())
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
        return Button { withAnimation(Trace.Motion.standard) { filter = value } } label: {
            Text(title).font(.custom(Theme.FontName.medium, size: 13))
                .foregroundStyle(on ? Trace.Colors.ink : Trace.Colors.bone)
                .padding(.horizontal, 14).frame(height: 32)
                .background(Capsule().fill(on ? Trace.Colors.bone : .clear))
                .overlay(Capsule().strokeBorder(on ? .clear : Trace.Colors.graphite, lineWidth: 1))
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
                Text(dossierNumber(file.number)).font(.custom(Trace.FontName.monoBold, size: 20)).foregroundStyle(Trace.Colors.ink)
                    .frame(width: 58, alignment: .leading)
                VStack(alignment: .leading, spacing: 5) {
                    Text(file.title.capitalizedFirst).font(Trace.Fonts.name).foregroundStyle(Trace.Colors.ink).lineLimit(1)
                    Text("\(facts.category) · \(facts.city)".uppercased()).font(Trace.Fonts.monoSmall).foregroundStyle(Trace.Colors.inkSoft).lineLimit(1)
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

// MARK: - 20 · Enquêteur

/// The investigator's card (laminated), service record and distinctions.
struct InvestigatorView: View {
    let attempts: [Attempt]
    let caseCount: Int
    let onSettings: () -> Void
    let onTab: (DeskTab) -> Void

    static func rankIndex(_ attempts: [Attempt]) -> Int {
        min(ProgressStore.summary(of: attempts).values.filter(\.solved).count, 4)
    }

    var body: some View {
        let summary = ProgressStore.summary(of: attempts)
        let solved = summary.values.filter(\.solved).count
        let ranked = attempts.filter(\.ranked)
        let best = ranked.map(\.score).max()
        let found = attempts.reduce(0) { $0 + $1.found }
        let total = attempts.reduce(0) { $0 + $1.total }
        let rank = Self.rankIndex(attempts)
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    Text(L10n.t("investigator.title")).font(Trace.Fonts.screenTitle).foregroundStyle(Trace.Colors.bone)
                        .padding(.top, 12)
                    card(rank: rank, solved: solved)
                    VStack(alignment: .leading, spacing: 0) {
                        Text(L10n.t("investigator.record")).fieldLabel().padding(.bottom, 6)
                        LedgerRow(label: L10n.t("profile.solved"), value: "\(solved) / \(caseCount)")
                        LedgerRow(label: L10n.t("profile.attempts"), value: "\(attempts.count)")
                        LedgerRow(label: L10n.t("profile.best"), value: best.map { "\($0) / 100" } ?? "—")
                        LedgerRow(label: L10n.t("profile.found"), value: total == 0 ? "—" : "\(found * 100 / total) %")
                    }
                    .padding(18)
                    .paper(Trace.Colors.paper)
                    VStack(alignment: .leading, spacing: 12) {
                        Text(L10n.t("profile.badges")).font(Trace.Fonts.fieldLabel).tracking(2).foregroundStyle(Trace.Colors.bone2)
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                            mention(L10n.t("profile.badgeFirst"), earned: solved > 0)
                            mention(L10n.t("profile.badgeNoHelp"), earned: attempts.contains { $0.solved && $0.ranked && $0.hintsUsed == 0 })
                            mention(L10n.t("profile.badgePerfect"), earned: attempts.contains { $0.ranked && $0.score >= 100 })
                            mention(L10n.t("profile.badgeThorough"), earned: attempts.contains { $0.total > 0 && $0.found == $0.total })
                        }
                    }
                    Button(action: onSettings) {
                        HStack {
                            Text(L10n.t("menu.settings"))
                            Spacer()
                            Image(systemName: "chevron.right")
                        }
                        .font(Trace.Fonts.ui).foregroundStyle(Trace.Colors.bone)
                        .padding(.horizontal, 16).frame(height: 52)
                        .background(RoundedRectangle(cornerRadius: 8).fill(Trace.Colors.graphite))
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("menu.settings")
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            }
            DeskTabBar(selected: .investigator, onSelect: onTab)
        }
        .background(TraceDesk())
    }

    /// A laminated ID card: ink band, photo, grade, service number, progress to the next grade.
    private func card(rank: Int, solved: Int) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(L10n.t("investigator.card")).font(Trace.Fonts.monoSmall.weight(.bold)).tracking(2).foregroundStyle(Trace.Colors.bone)
                Spacer()
                Text("TRACE").font(Trace.Fonts.monoSmall.weight(.bold)).tracking(3).foregroundStyle(Trace.Colors.bone2)
            }
            .padding(.horizontal, 16).frame(height: 34)
            .background(Trace.Colors.ink)
            HStack(alignment: .top, spacing: 16) {
                PhotoPrint(border: 3) {
                    ZStack {
                        Rectangle().fill(Trace.Colors.graphite)
                        Image(systemName: "person.fill").font(.system(size: 34)).foregroundStyle(Trace.Colors.bone3)
                    }
                    .frame(width: 70, height: 84)
                }
                VStack(alignment: .leading, spacing: 8) {
                    FieldRow(label: L10n.t("profile.rank"), value: L10n.t("profile.rank\(rank)"))
                    FieldRow(label: L10n.t("investigator.number"), value: "TR-\(String(format: "%04d", 1000 + solved * 137 % 9000))")
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 3) {
                            ForEach(0..<4, id: \.self) { i in Rectangle().fill(i < rank ? Trace.Colors.ink : Trace.Colors.ruled.opacity(3)).frame(height: 4) }
                        }
                        Text(rank < 4 ? L10n.t("profile.rankNext") : L10n.t("profile.rankMax")).font(Trace.Fonts.monoSmall).foregroundStyle(Trace.Colors.inkSoft)
                    }
                }
            }
            .padding(16)
        }
        .background(RoundedRectangle(cornerRadius: 12).fill(Trace.Colors.print))
        .overlay(RoundedRectangle(cornerRadius: 12).fill(LinearGradient(colors: [.white.opacity(0.35), .clear], startPoint: .topLeading, endPoint: .center)))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.5), radius: 16, y: 12)
    }

    private func mention(_ title: String, earned: Bool) -> some View {
        VStack(spacing: 8) {
            StampMark(text: earned ? L10n.t("stamp.mention") : "· · ·", color: earned ? Trace.Colors.stamp : Trace.Colors.inkFaint, size: 9,
                      dashed: !earned, angle: earned ? -5 : 0)
            Text(title).font(Trace.Fonts.proseSmall).foregroundStyle(earned ? Trace.Colors.ink : Trace.Colors.inkFaint)
                .multilineTextAlignment(.center).lineLimit(3)
        }
        .frame(maxWidth: .infinity, minHeight: 96)
        .padding(10)
        .paper(Trace.Colors.paperAged)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(earned ? .isSelected : [])
    }
}
#endif
