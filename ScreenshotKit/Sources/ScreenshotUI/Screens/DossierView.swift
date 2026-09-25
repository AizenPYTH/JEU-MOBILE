#if os(iOS)
import SwiftUI
import CaseEngine

// MARK: - 04 · Dossier ouvert

/// Opening a case = opening a folder: the kraft cover swings open on a stapled sheet. Divider tabs:
/// Contexte · Suspects · Pièces · Chronologie (· Rapport once the case was closed). At the bottom,
/// the seized phone as exhibit 01: « PIÈCE 01 · OUVRIR LE TÉLÉPHONE ».
struct DossierView: View {
    let caseFile: CaseFile
    let rules: GameRules?
    let durations: [Challenge: Int]
    let unlocked: Set<Challenge>
    let levels: [Challenge: LevelProgress]
    /// The investigation in progress on this case, if any.
    let saved: SavedInvestigation?
    /// Finished attempts on this case (for the report).
    let attempts: [Attempt]
    let archiveOpen: Bool
    let onStart: (Challenge) -> Void
    let onResume: () -> Void
    let onClose: () -> Void

    enum Tab: Hashable { case context, suspects, pieces, chronology, report }

    @State private var tab: Tab = .context
    @State private var selected: Challenge = .detective
    @State private var confirmRestart = false
    @State private var coverOpen = false
    @State private var suspectOpen: SuspectID?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// The saved game, rebuilt read-only to show what was filed.
    private var game: Investigation? {
        guard let saved, let rules else { return nil }
        return Investigation(restoring: saved.snapshot, caseFile: caseFile, rules: rules, clock: ManualClock())
    }

    var body: some View {
        let game = self.game
        VStack(spacing: 0) {
            topBar
            VStack(spacing: 0) {
                DividerTabs(tabs: tabs(game), selection: $tab, identifier: "dossier.tab", sheetColor: Trace.Colors.paper)
                    .padding(.top, 10)
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        switch tab {
                        case .context: context
                        case .suspects: suspects(game)
                        case .pieces: pieces(game)
                        case .chronology: chronology(game)
                        case .report: report
                        }
                    }
                    .padding(.horizontal, Trace.Spacing.sheet)
                    .padding(.vertical, 22)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .id(tab)
                    .transition(.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity), removal: .opacity))
                }
                .background(
                    ZStack(alignment: .top) {
                        Trace.Colors.paper
                        PaperGrain()
                        HStack(spacing: 60) { Staple(); Staple() }.padding(.top, 6)
                    }
                )
                .clipShape(UnevenRoundedRectangle(topLeadingRadius: 2, topTrailingRadius: 2))
                .padding(.horizontal, 8)
                .animation(Trace.Motion.sheet, value: tab)
            }
            .background(
                UnevenRoundedRectangle(topLeadingRadius: 10, topTrailingRadius: 10)
                    .fill(Trace.Colors.kraft)
                    .shadow(color: .black.opacity(0.55), radius: 22, y: 10)
            )
            .padding(.horizontal, 8)
            .overlay { cover }
            actions
        }
        .background(TraceDesk())
        .confirmationDialog(L10n.t("intro.restartTitle"), isPresented: $confirmRestart, titleVisibility: .visible) {
            Button(L10n.t("intro.restartConfirm"), role: .destructive) { onStart(selected) }
        } message: {
            Text(L10n.t("intro.restartMessage"))
        }
        .sheet(item: Binding(get: { suspectOpen.map(SuspectSheetID.init) }, set: { suspectOpen = $0?.id })) { item in
            if let suspect = caseFile.suspects.first(where: { $0.id == item.id }) {
                ScrollView { SuspectDossierPreview(suspect: suspect, caseFile: caseFile, game: game).padding(8) }
                    .background(TraceDesk())
                    .environment(\.caseNumber, caseFile.number)
                    .presentationDragIndicator(.visible)
            }
        }
        .task {
            AudioDirector.shared.play(.folder, volume: 0.45)
            Haptics.paper()
            if reduceMotion { coverOpen = true; return }
            try? await Task.sleep(for: .milliseconds(120))
            withAnimation(.timingCurve(0.2, 0.8, 0.2, 1, duration: 0.52)) { coverOpen = true }
        }
    }

    private func tabs(_ game: Investigation?) -> [(value: Tab, label: String)] {
        var list: [(value: Tab, label: String)] = [
            (.context, L10n.t("dossier.tab.context")),
            (.suspects, L10n.f("dossier.tab.suspects", caseFile.suspects.count)),
            (.pieces, L10n.f("dossier.tab.pieces", game?.notebook.count ?? 0)),
            (.chronology, L10n.t("dossier.tab.chronology")),
        ]
        if !attempts.isEmpty { list.append((.report, L10n.t("dossier.tab.report"))) }
        return list
    }

    /// The kraft cover, swinging open around its spine.
    private var cover: some View {
        UnevenRoundedRectangle(topLeadingRadius: 2, bottomLeadingRadius: 2, bottomTrailingRadius: 10, topTrailingRadius: 10)
            .fill(Trace.Colors.kraftLight)
            .overlay(PaperGrain(intensity: 0.05))
            .overlay(alignment: .topLeading) {
                VStack(alignment: .leading, spacing: 10) {
                    Text(L10n.f("dossier.number", dossierNumber(caseFile.number))).fieldLabel(Trace.Colors.kraftLabel)
                    Text(caseFile.title).font(Trace.Fonts.caseTitle).foregroundStyle(Trace.Colors.kraftInk)
                    StampMark(text: L10n.t("stamp.confidential"), size: 12)
                }
                .padding(28)
            }
            .padding(.horizontal, 8)
            .rotation3DEffect(.degrees(coverOpen ? -160 : 0), axis: (x: 0, y: 1, z: 0), anchor: .leading, perspective: 0.45)
            .opacity(coverOpen ? 0 : 1)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }

    private var topBar: some View {
        HStack {
            Button(action: onClose) {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.backward").font(.system(size: 15, weight: .semibold))
                    Text(L10n.t("tab.bureau")).font(.custom(Theme.FontName.regular, size: 17))
                }
                .foregroundStyle(Trace.Colors.bone)
                .frame(minHeight: 44)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text(L10n.t("a11y.close")))
            .accessibilityIdentifier("intro.close")
            Spacer()
            Text(saved.map { L10n.f("dossier.inProgress", PhoneFormat.countdown($0.remainingSeconds)) }
                 ?? L10n.f("dossier.notStarted", PhoneFormat.countdown(Double(durations[selected] ?? caseFile.durationSeconds))))
                .font(Trace.Fonts.monoSmall).tracking(1).foregroundStyle(Trace.Colors.bone2)
        }
        .padding(.horizontal, 16)
    }

    // MARK: Contexte

    @ViewBuilder
    private var context: some View {
        let facts = DossierFacts(file: caseFile)
        HStack(alignment: .top) {
            Text(L10n.f("dossier.numberLong", dossierNumber(caseFile.number))).fieldLabel()
            Spacer()
            StampMark(text: L10n.t("stamp.confidential"), size: 11, angle: -4)
        }
        Text(caseFile.title.capitalizedFirst).font(Trace.Fonts.caseTitle).foregroundStyle(Trace.Colors.ink)
            .fixedSize(horizontal: false, vertical: true)
            .accessibilityAddTraits(.isHeader)
        HStack(alignment: .top, spacing: 14) {
            VStack(alignment: .leading, spacing: 0) {
                FieldRow(label: facts.subjectLabel, value: [facts.subject, facts.info?.subjectAge.map { L10n.f("suspect.ageShort", $0) }].compactMap { $0 }.joined(separator: ", "))
                FieldRow(label: L10n.t("dossier.type"), value: facts.category)
                FieldRow(label: L10n.t("dossier.place"), value: "\(facts.place) — \(facts.city)")
                if let last = facts.lastContact { FieldRow(label: facts.lastContactLabel, value: last) }
                FieldRow(label: L10n.t("dossier.status"), value: saved != nil ? L10n.t("status.open") : L10n.t("status.openFile"),
                         valueColor: Trace.Colors.stamp, divider: false)
            }
            VStack(spacing: 4) {
                PhotoPrint(border: 5) {
                    if let contact = facts.subjectContact() {
                        Portrait(contact: contact, width: 96, height: 110).saturation(0.3)
                    } else {
                        GeneratedPhoto(scene: "vitrine", seed: caseFile.id).frame(width: 96, height: 110)
                    }
                }
                .overlay(alignment: .top) { Tape(width: 44).offset(y: -8) }
                Text(facts.subject).font(Trace.Fonts.proseSmall).foregroundStyle(Trace.Colors.ink).lineLimit(1)
            }
            .rotationEffect(.degrees(3))
            .frame(width: 112)
        }
        ForEach(Array(caseFile.synopsis.enumerated()), id: \.offset) { _, line in
            Text(line).font(Trace.Fonts.prose).foregroundStyle(Trace.Colors.ink).lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
        }
        VStack(alignment: .leading, spacing: 4) {
            Text(L10n.t("carnet.objective")).fieldLabel(Trace.Colors.stamp)
            Text(caseFile.objective).font(Trace.Fonts.prose.weight(.semibold)).foregroundStyle(Trace.Colors.ink)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .overlay(RoundedRectangle(cornerRadius: 2).strokeBorder(Trace.Colors.stamp.opacity(0.6), lineWidth: 1))
        if let device = caseFile.devices.first {
            FieldRow(label: L10n.t("dossier.exhibitOne"), value: L10n.f("intro.handedOver", device.label, PhoneFormat.dayAndTime(caseFile.phoneStartTime)), divider: false)
        }
        levelForm
    }

    /// NIVEAU D'ENQUÊTE: the three levels as boxes on the form.
    private var levelForm: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(L10n.t("challenge.pick")).fieldLabel().padding(.top, 8)
            ForEach(Challenge.allCases, id: \.self) { level in
                ChallengeCard(level: level, seconds: durations[level] ?? caseFile.durationSeconds,
                              progress: levels[level], locked: !unlocked.contains(level), selected: selected == level) {
                    selected = level
                    Haptics.selection()
                }
            }
            Handwritten(text: L10n.t("challenge.sameStory"), color: Trace.Colors.inkSoft, size: 18, angle: -1)
        }
    }

    // MARK: Suspects

    @ViewBuilder
    private func suspects(_ game: Investigation?) -> some View {
        Text(L10n.t("dossier.suspectsIntro")).font(Trace.Fonts.proseSmall).foregroundStyle(Trace.Colors.inkSoft)
        let contacts = caseFile.devices.first?.contacts ?? []
        ForEach(Array(caseFile.suspects.enumerated()), id: \.element.id) { offset, suspect in
            let entries = game?.linkedEntries(for: suspect.id) ?? []
            Button { suspectOpen = suspect.id } label: {
                SuspectIndexCard(suspect: suspect, letter: Suspect.letter(offset), contact: contacts.first { $0.id == suspect.contact },
                                 against: entries.filter { $0.stance == .incriminates }.count,
                                 favour: entries.filter { $0.stance == .clears }.count,
                                 cleared: game?.marks[suspect.id]?.contains(.hasAlibi) == true,
                                 showCounts: game != nil)
            }
            .buttonStyle(PressableStyle())
            .accessibilityIdentifier("dossier.suspect.\(suspect.id)")
        }
    }

    // MARK: Pièces

    @ViewBuilder
    private func pieces(_ game: Investigation?) -> some View {
        if let game, !game.notebook.isEmpty {
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible())], spacing: 14) {
                ForEach(game.notebook, id: \.ref) { entry in ExhibitView(ref: entry.ref, game: game) }
            }
        } else {
            EmptyPage(title: L10n.t("dossier.noPieces"), tip: L10n.t("dossier.noPiecesTip"))
        }
    }

    // MARK: Chronologie

    @ViewBuilder
    private func chronology(_ game: Investigation?) -> some View {
        if let game {
            ChronologySheet(game: game)
        } else {
            EmptyPage(title: L10n.t("chrono.empty"), tip: L10n.t("chrono.emptyTip"))
        }
    }

    // MARK: Rapport

    @ViewBuilder
    private var report: some View {
        if let last = attempts.last {
            Text(L10n.t("report.title")).fieldLabel()
            Text(L10n.f("report.caseTitle", dossierNumber(caseFile.number), caseFile.title.capitalizedFirst))
                .font(Trace.Fonts.name).foregroundStyle(Trace.Colors.ink)
            LedgerRow(label: L10n.t("report.date"), value: last.date.formatted(date: .abbreviated, time: .shortened))
            LedgerRow(label: L10n.t("report.culpritFound"), value: last.solved ? L10n.t("report.yes") : L10n.t("report.no"))
            LedgerRow(label: L10n.t("report.keyFound"), value: "\(last.found) / \(last.total)")
            LedgerRow(label: L10n.t("report.hints"), value: "\(last.hintsUsed)")
            HStack(alignment: .firstTextBaseline) {
                Text(last.ranked ? "\(last.score)" : "—").font(Trace.Fonts.score).foregroundStyle(Trace.Colors.ink)
                Text("/100").font(Trace.Fonts.pieceTitle).foregroundStyle(Trace.Colors.inkSoft)
                Spacer()
                StampMark(text: last.solved ? L10n.t("stamp.solved") : L10n.t("stamp.unsolved"), size: 14, dashed: !last.solved)
            }
            if archiveOpen {
                VStack(alignment: .leading, spacing: 12) {
                    Text(L10n.t("report.reconstruction")).fieldLabel(Trace.Colors.stamp).padding(.top, 8)
                    Text(caseFile.solution.headline).font(Trace.Fonts.name).foregroundStyle(Trace.Colors.ink)
                    Text(caseFile.solution.summary).font(Trace.Fonts.quote).foregroundStyle(Trace.Colors.inkSoft)
                    RevealTimeline(steps: caseFile.solution.reveal, found: Set(caseFile.solution.reveal.compactMap(\.evidence)), shown: caseFile.solution.reveal.count)
                    ForEach(Array(caseFile.solution.story.enumerated()), id: \.offset) { _, paragraph in
                        Text(paragraph).font(Trace.Fonts.prose).foregroundStyle(Trace.Colors.ink)
                    }
                }
                .accessibilityIdentifier("dossier.reconstruction")
            } else {
                Handwritten(text: L10n.t("report.locked"), color: Trace.Colors.stamp, size: 20)
            }
        }
    }

    // MARK: Actions

    /// PIÈCE 01 · OUVRIR LE TÉLÉPHONE (or resume).
    @ViewBuilder
    private var actions: some View {
        let seconds = durations[selected] ?? caseFile.durationSeconds
        VStack(spacing: 8) {
            if let saved {
                Button(action: onResume) { exhibitLabel(L10n.t("home.resume"), time: PhoneFormat.countdown(saved.remainingSeconds)) }
                    .buttonStyle(InkButtonStyle(height: 62))
                    .accessibilityIdentifier("intro.resume")
                Button { confirmRestart = true } label: {
                    Text(L10n.f("intro.startLevel", L10n.t("challenge.\(selected.rawValue)"), PhoneFormat.countdown(Double(seconds))))
                }
                .buttonStyle(PaperButtonStyle(height: 44))
                .accessibilityIdentifier("intro.start")
            } else {
                Button { onStart(selected) } label: {
                    exhibitLabel(L10n.t("dossier.openPhone"), time: PhoneFormat.countdown(Double(seconds)),
                                 level: L10n.t("challenge.\(selected.rawValue)"))
                }
                .buttonStyle(InkButtonStyle(height: 62))
                .accessibilityIdentifier("intro.start")
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 10)
    }

    private func exhibitLabel(_ title: String, time: String, level: String? = nil) -> some View {
        HStack(spacing: 14) {
            RoundedRectangle(cornerRadius: 5).strokeBorder(Trace.Colors.bone, lineWidth: 1.5).frame(width: 22, height: 36)
            VStack(alignment: .leading, spacing: 2) {
                Text(L10n.t("dossier.pieceOne")).font(Trace.Fonts.monoSmall).foregroundStyle(Trace.Colors.stampOnDark)
                Text(title)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                if let level { Text(level).font(Trace.Fonts.monoSmall).foregroundStyle(Trace.Colors.bone2) }
                Text(time).font(.custom(Trace.FontName.monoBold, size: 18))
            }
        }
        .padding(.horizontal, 16)
    }
}

/// A suspect's file, read before (or between) investigations: identity, statement, what is filed.
struct SuspectDossierPreview: View {
    let suspect: Suspect
    let caseFile: CaseFile
    let game: Investigation?

    var body: some View {
        let contact = caseFile.devices.first?.contacts.first { $0.id == suspect.contact }
        let index = caseFile.suspects.firstIndex { $0.id == suspect.id } ?? 0
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text(L10n.f("dossier.suspectFileHeader", dossierNumber(caseFile.number), Suspect.letter(index))).fieldLabel()
                Spacer()
            }
            HStack(alignment: .top, spacing: 16) {
                IDPhoto(contact: contact, width: 86, height: 100)
                    .overlay(alignment: .topTrailing) { Paperclip().offset(x: -6, y: -14) }
                    .rotationEffect(.degrees(-2))
                VStack(alignment: .leading, spacing: 0) {
                    Text(contact?.name ?? suspect.contact).font(Trace.Fonts.nameLarge).foregroundStyle(Trace.Colors.ink)
                    if let age = suspect.age { LedgerRow(label: L10n.t("suspect.ageLabel"), value: "\(age)") }
                    LedgerRow(label: L10n.t("suspect.link"), value: suspect.role.uppercased())
                    if let address = suspect.address { LedgerRow(label: L10n.t("suspect.address"), value: address.uppercased()) }
                }
            }
            Text(L10n.t("suspect.statementLabel")).fieldLabel()
            Text(suspect.statement).font(Trace.Fonts.quote).foregroundStyle(Trace.Colors.ink)
        }
        .padding(20)
        .background(ZStack { Trace.Colors.paper; RuledLines(); PaperGrain() })
        .shadow(color: .black.opacity(0.4), radius: 10, y: 8)
    }
}
#endif
