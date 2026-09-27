#if os(iOS)
import SwiftUI
import CaseEngine

// MARK: - 04 · Dossier, briefing

/// The case file on the desk (final handoff §F-04): a kraft folder « N° 00N » holding one typed
/// sheet — the case, the person concerned, the mission and, for #001, the three steps — then one
/// full button, [OUVRIR LE TÉLÉPHONE]. Everything else stays secondary: an investigation in
/// progress ([REPRENDRE L'ENQUÊTE] + « Recommencer »), the challenge level (hidden on the very
/// first case), the closing report of a case already played ([REJOUER] once it is archived).
struct DossierView: View {
    let caseFile: CaseFile
    let rules: GameRules?
    /// Duration of each level, « Temps détendu » included.
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

    private enum Sheet: String, Identifiable {
        case rules, report, restart
        var id: String { rawValue }
    }

    @State private var selected: Challenge = .detective
    @State private var contextOpen = false
    @State private var levelsOpen = false
    @State private var sheet: Sheet?
    @State private var appeared = false
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    @AppStorage(Preferences.reduceMotionKey) private var appReduceMotion = false
    @Environment(\.dynamicTypeSize) private var typeSize

    private var noMotion: Bool { systemReduceMotion || appReduceMotion }
    private var motion: Animation { noMotion ? Animation.easeOut(duration: 0.2) : Trace.Motion.paper }
    /// Opening « Contexte » or the levels: the paper spring; with reduced motion, no animation.
    private var expandMotion: Animation? { noMotion ? nil : Trace.Motion.paper }
    private var facts: DossierFacts { DossierFacts(file: caseFile) }
    private var seconds: Int { durations[selected] ?? caseFile.durationSeconds }
    /// The level choice is not offered on the first play of #001, before the assignment.
    private var showsLevels: Bool { !(caseFile.number == 1 && !PlayerStore.isAssigned) }

    var body: some View {
        VStack(spacing: 0) {
            topBar
            ScrollView {
                folder
                    .padding(.horizontal, Metrics.folderMargin)
                    .padding(.top, 6)
                    .padding(.bottom, 20)
                    .offset(y: appeared || noMotion ? 0 : 24)
                    .opacity(appeared ? 1 : 0)
            }
            .scrollIndicators(.hidden)
            actions
        }
        .background(DeskBackdrop())
        .sheet(item: $sheet) { which in
            switch which {
            case .rules:
                rulesSheet
                    .presentationDetents([.medium, .large])
                    .presentationCornerRadius(Metrics.sheetRadius)
            case .report:
                reportSheet
                    .presentationDetents([.large])
                    .presentationCornerRadius(Metrics.sheetRadius)
                    .presentationDragIndicator(.visible)
            case .restart:
                PaperConfirmSheet(title: L10n.t("intro.restartTitle"),
                                  message: L10n.t("intro.restartMessage"),
                                  confirm: L10n.t("intro.restartConfirm"),
                                  confirmID: "intro.restartConfirm",
                                  destructive: true,
                                  cancel: L10n.t("common.back"),
                                  cancelID: "intro.restartCancel",
                                  onConfirm: {
                                      sheet = nil
                                      onStart(selected)
                                  },
                                  onCancel: { sheet = nil })
                    .presentationDetents([.medium, .large])
                    .presentationCornerRadius(Metrics.sheetRadius)
            }
        }
        .task {
            guard !appeared else { return }
            if !unlocked.contains(selected), let first = Challenge.allCases.first(where: { unlocked.contains($0) }) {
                selected = first
            }
            AudioDirector.shared.play(.folder, volume: 0.45)
            Haptics.paper()
            withAnimation(motion) { appeared = true }
        }
    }

    // MARK: Top

    private var topBar: some View {
        let assigned = PlayerStore.isAssigned
        return HStack {
            Button(action: onClose) {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.backward").font(Metrics.chevron)
                    if assigned {
                        Text(L10n.t("tab.bureau")).font(Trace.Fonts.link)
                    }
                }
                .foregroundStyle(Trace.Colors.boneMid)
                .frame(minWidth: 44, minHeight: 44, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text(assigned ? L10n.t("tab.bureau") : L10n.t("common.back")))
            .accessibilityIdentifier("intro.close")
            Spacer()
        }
        .padding(.horizontal, 16)
    }

    // MARK: Folder

    /// The kraft folder: its tab « N° 00N », and the sheet it holds.
    private var folder: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(L10n.f("briefing.tab", shownNumber(caseFile.number)))
                .font(Trace.Fonts.kicker)
                .tracking(1.6)
                .foregroundStyle(Trace.Colors.kraftInk)
                .padding(.horizontal, 16)
                .frame(minHeight: 30)
                .background(
                    UnevenRoundedRectangle(topLeadingRadius: 8, topTrailingRadius: 8)
                        .fill(Trace.Colors.kraft)
                        .overlay(PaperGrain(intensity: 0.05, texture: "tex_kraft_fibers")
                            .clipShape(UnevenRoundedRectangle(topLeadingRadius: 8, topTrailingRadius: 8)))
                )
                .accessibilityHidden(true)
            sheetContent
                .padding(Metrics.kraftInset)
                .kraft()
        }
    }

    /// The typed sheet (#ECE5D3 + grain).
    private var sheetContent: some View {
        VStack(alignment: .leading, spacing: 18) {
            header
            summary
            mission
            if caseFile.number == 1 {
                steps
            } else {
                Button(L10n.t("briefing.rulesLink")) { sheet = .rules }
                    .buttonStyle(TextLinkStyle(onPaper: true))
                    .accessibilityIdentifier("briefing.rules")
            }
            footer
            if showsLevels {
                levelPicker
            }
            if let last = attempts.last {
                reportLink(last)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 22)
        .padding(.bottom, 16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .paper()
    }

    // MARK: Header

    @ViewBuilder
    private var header: some View {
        if typeSize.isAccessibilitySize {
            VStack(alignment: .leading, spacing: 16) {
                subjectPrint
                headerText
            }
        } else {
            HStack(alignment: .top, spacing: 14) {
                headerText
                Spacer(minLength: 0)
                subjectPrint
            }
        }
    }

    /// `DOSSIER #00N · CATÉGORIE` / city, then the title.
    private var headerText: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(headerLine)
                .font(Trace.Fonts.kicker)
                .tracking(1.6)
                .foregroundStyle(Trace.Colors.inkSoft)
                .fixedSize(horizontal: false, vertical: true)
            if let city = caseFile.dossier?.city, !city.isEmpty {
                Text(city)
                    .font(Trace.Fonts.fieldValue)
                    .foregroundStyle(Trace.Colors.inkMid)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Text(Self.sentenceCase(caseFile.title))
                .font(Trace.Fonts.serifTitle(26))
                .foregroundStyle(Trace.Colors.ink)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)
                .padding(.top, 10)
        }
    }

    private var headerLine: String {
        let number = fileLabel(caseFile.number)
        guard let category = caseFile.dossier?.category, !category.isEmpty else { return number }
        return number + " · " + category
    }

    /// The person concerned, printed 84 × 104 (initials on BEN blue when the portrait is missing).
    @ViewBuilder
    private var subjectPrint: some View {
        if let contact = facts.subjectContact() {
            PortraitOrInitials(image: ArtLibrary.portrait(case: caseFile.number, contact: contact),
                               initials: contact.initials,
                               width: Metrics.printSize.width - 2 * Metrics.printBorder,
                               height: Metrics.printSize.height - 2 * Metrics.printBorder)
                .padding(Metrics.printBorder)
                .background(Trace.Colors.printWhite)
                .shadow(color: .black.opacity(0.25), radius: 5, y: 4)
                .overlay(alignment: .top) { Tape(width: 40).offset(y: -8) }
                .rotationEffect(.degrees(2))
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(Text(contact.name))
                .accessibilityAddTraits(.isImage)
        }
    }

    // MARK: Summary

    /// The first paragraph of the synopsis; the others behind « Contexte ».
    private var summary: some View {
        let more = Array(caseFile.synopsis.dropFirst())
        return VStack(alignment: .leading, spacing: 6) {
            if let first = caseFile.synopsis.first {
                paragraph(first)
            }
            if !more.isEmpty {
                Button {
                    withAnimation(expandMotion) { contextOpen.toggle() }
                    Haptics.selection()
                } label: {
                    HStack(spacing: 6) {
                        Text(L10n.t("dossier.tab.context"))
                        Image(systemName: contextOpen ? "chevron.up" : "chevron.down").font(Trace.Fonts.kicker)
                    }
                }
                .buttonStyle(TextLinkStyle(onPaper: true))
                .accessibilityAddTraits(contextOpen ? .isSelected : [])
                .accessibilityIdentifier("briefing.context")
                if contextOpen {
                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(Array(more.enumerated()), id: \.offset) { _, line in
                            paragraph(line)
                        }
                    }
                    .transition(.opacity)
                }
            }
        }
    }

    private func paragraph(_ text: String) -> some View {
        Text(text)
            .font(Metrics.summaryFont)
            .foregroundStyle(Trace.Colors.ink)
            .lineSpacing(3)
            .fixedSize(horizontal: false, vertical: true)
    }

    // MARK: Mission

    /// VOTRE MISSION: a red rule, the red kicker, the objective of the case.
    private var mission: some View {
        VStack(alignment: .leading, spacing: 8) {
            Rectangle().fill(Trace.Colors.stamp).frame(height: 1.5)
            Text(L10n.t("briefing.mission"))
                .font(Trace.Fonts.kicker)
                .tracking(1.6)
                .foregroundStyle(Trace.Colors.stamp)
            Text(caseFile.objective)
                .font(Metrics.missionFont)
                .foregroundStyle(Trace.Colors.ink)
                .fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityElement(children: .combine)
    }

    /// #001 only: EXPLORER · VERSER AU DOSSIER · CONCLURE, numbered.
    private var steps: some View {
        VStack(alignment: .leading, spacing: 10) {
            step(1, verb: L10n.t("briefing.verb.explore"), rest: exploreLine)
            step(2, verb: L10n.t("briefing.verb.file"), rest: L10n.t("briefing.step.file"))
            step(3, verb: L10n.t("briefing.verb.conclude"), rest: L10n.t("briefing.step.conclude"))
        }
    }

    /// « 1 EXPLORER le téléphone… »: the verb in Plex Mono caps, the rest in Newsreader, one flow.
    private func step(_ number: Int, verb: String, rest: String) -> some View {
        let verbText: Text = Text(verb).font(Trace.Fonts.monoStrong).tracking(1.2).foregroundColor(Trace.Colors.ink)
        let restText: Text = Text(verbatim: " " + rest).font(Trace.Fonts.prose).foregroundColor(Trace.Colors.inkMid)
        return HStack(alignment: .firstTextBaseline, spacing: 10) {
            Text(verbatim: "\(number)")
                .font(Trace.Fonts.monoStrong)
                .foregroundStyle(Trace.Colors.stamp)
            (verbText + restText)
                .fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityElement(children: .combine)
    }

    /// « le téléphone d'Alex / de Clémence : … » (« Alex's phone: … » in English).
    private var exploreLine: String {
        guard let name = ownerFirstName else { return L10n.t("briefing.step.exploreNoName") }
        if Self.elides(name) {
            return L10n.f("briefing.step.exploreElided", name)
        }
        return L10n.f("briefing.step.explore", name)
    }

    /// First name of the phone's owner (the contact `me`).
    private var ownerFirstName: String? {
        let contacts = caseFile.devices.first?.contacts ?? []
        let owner = contacts.first(where: { $0.id == ownerContactID }) ?? contacts.first(where: { $0.isOwner == true })
        guard let first = owner?.name.split(separator: " ").first, !first.isEmpty else { return nil }
        return String(first)
    }

    /// French elision before a vowel or a mute h: « d'Alex », « d'Hugo », « de Clémence ».
    private static func elides(_ name: String) -> Bool {
        guard let first = name.first else { return false }
        let plain = String(first).folding(options: [.diacriticInsensitive, .caseInsensitive], locale: nil)
        return ["a", "e", "i", "o", "u", "h"].contains(plain)
    }

    /// « PREMIER MÉTRO » → « Premier métro ».
    private static func sentenceCase(_ text: String) -> String {
        let lower = text.lowercased()
        return lower.prefix(1).uppercased() + lower.dropFirst()
    }

    // MARK: Footer, level, report

    /// `4 SUSPECTS · TEMPS : 08:00`
    private var footer: some View {
        Text(L10n.f("cases.suspects", caseFile.suspects.count).uppercased() + " · " + timeLine)
            .font(Trace.Fonts.fieldValue)
            .tracking(1.2)
            .foregroundStyle(Trace.Colors.inkMid)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 12)
            .overlay(alignment: .top) { Rectangle().fill(Trace.Colors.ruled.opacity(2)).frame(height: 1) }
    }

    private var timeLine: String { L10n.f("briefing.time", PhoneFormat.countdown(Double(seconds))) }

    /// « NIVEAU : DÉTECTIVE », which opens the three level boxes.
    private var levelPicker: some View {
        VStack(alignment: .leading, spacing: 4) {
            Button {
                withAnimation(expandMotion) { levelsOpen.toggle() }
                Haptics.selection()
            } label: {
                HStack(spacing: 8) {
                    Text(L10n.f("briefing.level", L10n.t("challenge.\(selected.rawValue)").uppercased()))
                        .font(Trace.Fonts.monoStrong)
                        .tracking(1.2)
                        .foregroundStyle(Trace.Colors.ink)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 8)
                    Image(systemName: levelsOpen ? "chevron.up" : "chevron.down")
                        .font(Trace.Fonts.kicker)
                        .foregroundStyle(Trace.Colors.inkSoft)
                }
                .frame(minHeight: 44)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityHint(Text(L10n.t("briefing.levelHint")))
            .accessibilityIdentifier("briefing.level")
            if levelsOpen {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(Challenge.allCases, id: \.self) { level in
                        ChallengeCard(level: level, seconds: durations[level] ?? caseFile.durationSeconds,
                                      progress: levels[level], locked: !unlocked.contains(level),
                                      selected: selected == level) {
                            selected = level
                            Haptics.selection()
                        }
                    }
                    Text(L10n.t("challenge.sameStory"))
                        .font(Trace.Fonts.proseSmall)
                        .foregroundStyle(Trace.Colors.inkSoft)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, 10)
                }
                .transition(.opacity)
            }
        }
    }

    /// The closing report of the last attempt (read-only), with its stamp.
    private func reportLink(_ last: Attempt) -> some View {
        HStack(alignment: .center, spacing: 12) {
            Button(L10n.t("report.title")) { sheet = .report }
                .buttonStyle(TextLinkStyle(onPaper: true))
                .accessibilityIdentifier("dossier.report")
            Spacer(minLength: 8)
            StampMark(text: last.solved ? L10n.t("stamp.solved") : L10n.t("stamp.unsolved"),
                      size: 9, dashed: !last.solved, angle: -3)
        }
    }

    // MARK: Actions

    /// One full button on the desk: OUVRIR LE TÉLÉPHONE (REJOUER once archived), or REPRENDRE
    /// L'ENQUÊTE with « Recommencer » as a link.
    private var actions: some View {
        VStack(spacing: 4) {
            if let saved {
                Text(inProgressLine(saved))
                    .font(Trace.Fonts.monoSmall)
                    .tracking(1)
                    .foregroundStyle(Trace.Colors.bone2)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.bottom, 6)
                Button(L10n.t("home.resume"), action: onResume)
                    .buttonStyle(CTAButtonStyle())
                    .accessibilityIdentifier("intro.resume")
                Button(L10n.t("intro.restartConfirm")) { sheet = .restart }
                    .buttonStyle(TextLinkStyle())
                    .accessibilityIdentifier("intro.restart")
            } else {
                Button(startTitle) { onStart(selected) }
                    .buttonStyle(CTAButtonStyle())
                    .accessibilityLabel(Text(startTitle + ", " + timeLine))
                    .accessibilityIdentifier("intro.start")
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 10)
        .padding(.bottom, 10)
    }

    /// OUVRIR LE TÉLÉPHONE, or REJOUER for a case whose report is open in the Archives.
    private var startTitle: String {
        archiveOpen ? L10n.t("briefing.replay") : L10n.t("briefing.start")
    }

    /// « EN COURS · 05:12 RESTANTES · 2 PIÈCES VERSÉES »
    private func inProgressLine(_ saved: SavedInvestigation) -> String {
        let time = L10n.f("dossier.inProgress", PhoneFormat.countdown(saved.remainingSeconds))
        let pieces = L10n.f("dossier.piecesCount", saved.snapshot.notebook.count).uppercased()
        return time + " · " + pieces
    }

    // MARK: Sheets

    /// « Rappel des règles » (#002–#005): the three verbs, one line each.
    private var rulesSheet: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text(L10n.t("briefing.rulesLink"))
                    .font(Trace.Fonts.serifTitle(22))
                    .foregroundStyle(Trace.Colors.ink)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityAddTraits(.isHeader)
                rule(1, verb: L10n.t("briefing.verb.explore"), line: L10n.t("briefing.rule.cost"))
                rule(2, verb: L10n.t("briefing.verb.file"), line: L10n.t("briefing.rule.file"))
                rule(3, verb: L10n.t("briefing.verb.conclude"), line: L10n.t("briefing.rule.conclude"))
                Button(L10n.t("briefing.rulesDone")) { sheet = nil }
                    .buttonStyle(CTAButtonStyle(onPaper: true))
                    .accessibilityIdentifier("briefing.rulesDone")
                    .padding(.top, 6)
            }
            .padding(.horizontal, 16)
            .padding(.top, 28)
            .padding(.bottom, 16)
        }
        .background(Trace.Colors.paper.overlay(PaperGrain()).ignoresSafeArea())
    }

    private func rule(_ number: Int, verb: String, line: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Text(verbatim: "0\(number)")
                .font(Trace.Fonts.kicker)
                .foregroundStyle(Trace.Colors.stamp)
            VStack(alignment: .leading, spacing: 4) {
                Text(verb)
                    .font(Trace.Fonts.monoStrong)
                    .tracking(1.2)
                    .foregroundStyle(Trace.Colors.ink)
                Text(line)
                    .font(Trace.Fonts.prose)
                    .foregroundStyle(Trace.Colors.inkMid)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.top, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .overlay(alignment: .top) { Rectangle().fill(Trace.Colors.stamp.opacity(0.3)).frame(height: 1.5) }
        .accessibilityElement(children: .combine)
    }

    /// The closing report of the last attempt; the reconstruction once the archive is open.
    private var reportSheet: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                Button { sheet = nil } label: {
                    Image(systemName: "xmark")
                        .font(Metrics.chevron)
                        .foregroundStyle(Trace.Colors.inkSoft)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text(L10n.t("a11y.close")))
                .accessibilityIdentifier("dossier.reportClose")
            }
            .padding(.horizontal, 8)
            .padding(.top, 8)
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    reportContent
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 28)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .background(Trace.Colors.paper.overlay(PaperGrain()).ignoresSafeArea())
    }

    @ViewBuilder
    private var reportContent: some View {
        if let last = attempts.last {
            Text(L10n.t("report.title")).fieldLabel()
            Text(L10n.f("report.caseTitle", shownNumber(caseFile.number), Self.sentenceCase(caseFile.title)))
                .font(Trace.Fonts.name)
                .foregroundStyle(Trace.Colors.ink)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)
            VStack(spacing: 0) {
                LedgerRow(label: L10n.t("report.date"), value: last.date.formatted(date: .abbreviated, time: .shortened))
                LedgerRow(label: L10n.t("report.culpritFound"), value: last.solved ? L10n.t("report.yes") : L10n.t("report.no"))
                LedgerRow(label: L10n.t("report.keyFound"), value: "\(last.found) / \(last.total)")
                LedgerRow(label: L10n.t("report.hints"), value: "\(last.hintsUsed)")
            }
            HStack(alignment: .firstTextBaseline) {
                Text(verbatim: last.ranked ? "\(last.score)" : "—")
                    .font(Trace.Fonts.score)
                    .foregroundStyle(Trace.Colors.ink)
                    .minimumScaleFactor(0.5)
                Text(verbatim: "/100")
                    .font(Trace.Fonts.pieceTitle)
                    .foregroundStyle(Trace.Colors.inkSoft)
                Spacer()
                StampMark(text: last.solved ? L10n.t("stamp.solved") : L10n.t("stamp.unsolved"), size: 14, dashed: !last.solved)
            }
            if archiveOpen {
                VStack(alignment: .leading, spacing: 12) {
                    Text(L10n.t("report.reconstruction")).fieldLabel(Trace.Colors.stamp).padding(.top, 8)
                    Text(caseFile.solution.headline)
                        .font(Trace.Fonts.name)
                        .foregroundStyle(Trace.Colors.ink)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(caseFile.solution.summary)
                        .font(Trace.Fonts.quote)
                        .foregroundStyle(Trace.Colors.inkSoft)
                        .fixedSize(horizontal: false, vertical: true)
                    RevealTimeline(steps: caseFile.solution.reveal,
                                   found: Set(caseFile.solution.reveal.compactMap(\.evidence)),
                                   shown: caseFile.solution.reveal.count)
                    ForEach(Array(caseFile.solution.story.enumerated()), id: \.offset) { _, paragraph in
                        Text(paragraph)
                            .font(Trace.Fonts.prose)
                            .foregroundStyle(Trace.Colors.ink)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .accessibilityIdentifier("dossier.reconstruction")
            } else {
                Text(L10n.t("report.locked"))
                    .font(Trace.Fonts.quote)
                    .foregroundStyle(Trace.Colors.stamp)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    // MARK: Metrics

    private enum Metrics {
        static let folderMargin: CGFloat = 12
        static let kraftInset: CGFloat = 10
        static let sheetRadius: CGFloat = 16
        static let printSize = CGSize(width: 84, height: 104)
        static let printBorder: CGFloat = 4
        static let chevron = Font.system(size: 15, weight: .semibold)
        /// Summary: Newsreader 14.5.
        static let summaryFont = Font.custom(Trace.FontName.serif, size: 14.5, relativeTo: .callout)
        /// Objective: Newsreader 17/500.
        static let missionFont = Font.custom(Trace.FontName.serifMedium, size: 17, relativeTo: .body)
    }
}
#endif
