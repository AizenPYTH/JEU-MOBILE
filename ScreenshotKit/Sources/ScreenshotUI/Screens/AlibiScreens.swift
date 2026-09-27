#if os(iOS)
import SwiftUI
import UIKit
import CaseEngine

// The ALIBI mode (docs/game_modes/ALIBI.md): « VÉRIFIER. CROISER. CONCLURE. » One person, one
// statement, the same phone and the same Carnet as an investigation, then one question —
// « SON ALIBI EST-IL FIABLE ? » — answered with a held button, a typed verification and a stamp.
// Same paper, same desk, same gestures: a second, shorter way to play the same game.

/// Words shared by the ALIBI screens.
enum AlibiText {
    /// « ven. 06.11 · 20:00 → 00:00 »
    static func window(_ claim: AlibiClaim) -> String {
        "\(PhoneFormat.shortWeekdayDot(claim.from).lowercased()) · \(PhoneFormat.time(claim.from)) → \(PhoneFormat.time(claim.to))"
    }

    /// « Mathis : « Je n'ai pas quitté la table. » (20:00 → 00:00) »
    @MainActor
    static func claimLine(_ claim: AlibiClaim, game: Investigation) -> String {
        "\(firstName(game.name(of: claim.person))) : \(claim.statement) (\(PhoneFormat.time(claim.from)) → \(PhoneFormat.time(claim.to)))"
    }

    static func firstName(_ name: String) -> String {
        name.split(separator: " ").first.map(String.init) ?? name
    }

    /// « ALIBI CONFIRMÉ » / « ALIBI CONTREDIT ».
    static func answer(_ holds: Bool) -> String { L10n.t(holds ? "alibi.confirmed" : "alibi.contradicted") }
}

// MARK: - Bureau card

/// The ALIBI entry on the Bureau: visible, secondary (paper, no filled button — the Bureau's main
/// button stays the investigation's).
struct AlibiDeskCard: View {
    let total: Int
    let done: Int
    let inProgress: Bool
    let onOpen: () -> Void

    var body: some View {
        Button(action: onOpen) {
            HStack(alignment: .center, spacing: 14) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(L10n.t("alibi.mode"))
                        .font(Trace.Fonts.monoTitle)
                        .tracking(2.4)
                        .foregroundStyle(Trace.Colors.ink)
                    Text(L10n.t("alibi.tagline"))
                        .font(Trace.Fonts.kicker)
                        .tracking(1.4)
                        .foregroundStyle(Trace.Colors.stamp)
                    Text(L10n.t("alibi.pitch"))
                        .font(Trace.Fonts.proseSmall)
                        .foregroundStyle(Trace.Colors.inkMid)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(inProgress ? L10n.t("alibi.inProgress") : L10n.f("alibi.progress", done, total))
                        .font(Trace.Fonts.monoSmall)
                        .foregroundStyle(Trace.Colors.inkSoft)
                }
                Spacer(minLength: 4)
                Image(systemName: "chevron.right")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Trace.Colors.inkSoft)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .paper(Trace.Colors.paper, radius: 2, lifted: true)
            .contentShape(Rectangle())
        }
        .buttonStyle(PressableStyle())
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
        .accessibilityIdentifier("home.alibi")
    }
}

// MARK: - ALIBI desk (the list of checks)

/// « ALIBI »: the pitch, the checks as paper slips (status on each), one button [COMMENCER] for
/// the next one (or [REPRENDRE] when one is in progress).
struct AlibiDeskView: View {
    let cases: [CaseFile]
    let progress: [String: CaseProgress]
    let inProgressID: String?
    let onOpen: (CaseFile) -> Void
    let onResume: () -> Void
    let onBack: () -> Void

    private var next: CaseFile? {
        cases.first { $0.id == inProgressID } ?? cases.first { progress[$0.id]?.solved != true } ?? cases.first
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    Button(action: onBack) {
                        Label(L10n.t("tab.bureau"), systemImage: "chevron.left")
                    }
                    .buttonStyle(TextLinkStyle())
                    .accessibilityIdentifier("alibi.back")
                    Text(L10n.t("alibi.mode"))
                        .font(Trace.Fonts.serifTitle(30))
                        .foregroundStyle(Trace.Colors.bone)
                        .accessibilityAddTraits(.isHeader)
                        .accessibilityIdentifier("alibi.title")
                    Text(L10n.t("alibi.tagline"))
                        .font(Trace.Fonts.kicker)
                        .tracking(1.8)
                        .foregroundStyle(Trace.Colors.stampOnDark)
                    Text(L10n.t("alibi.pitch"))
                        .font(Trace.Fonts.prose)
                        .foregroundStyle(Trace.Colors.bone2)
                        .fixedSize(horizontal: false, vertical: true)
                    DeskOverline(text: L10n.t("alibi.list"))
                        .padding(.top, 8)
                    ForEach(cases, id: \.id) { file in
                        Button { open(file) } label: { slip(file) }
                            .buttonStyle(PressableStyle())
                            .accessibilityIdentifier("alibi.case.\(file.id)")
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
            }
            if let next {
                Group {
                    if next.id == inProgressID {
                        Button(L10n.t("home.resume"), action: onResume)
                            .accessibilityIdentifier("alibi.resume")
                    } else {
                        Button(L10n.t("alibi.start")) { onOpen(next) }
                            .accessibilityIdentifier("alibi.start")
                    }
                }
                .buttonStyle(CTAButtonStyle())
                .padding(.horizontal, 24)
                .padding(.vertical, 10)
            }
        }
        .background(DeskBackdrop())
    }

    private func open(_ file: CaseFile) {
        if file.id == inProgressID { onResume() } else { onOpen(file) }
    }

    private func slip(_ file: CaseFile) -> some View {
        let status = self.status(of: file)
        return VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(fileLabel(file.number))
                    .font(Trace.Fonts.kicker)
                    .tracking(1.6)
                    .foregroundStyle(Trace.Colors.stamp)
                Spacer(minLength: 8)
                Text(status.text)
                    .font(Trace.Fonts.kicker)
                    .tracking(1.4)
                    .foregroundStyle(status.done ? Trace.Colors.stamp : Trace.Colors.inkSoft)
            }
            Text(file.title)
                .font(Trace.Fonts.serifTitle(20))
                .foregroundStyle(Trace.Colors.ink)
                .fixedSize(horizontal: false, vertical: true)
            Text(file.tagline)
                .font(Trace.Fonts.proseSmall)
                .foregroundStyle(Trace.Colors.inkMid)
                .fixedSize(horizontal: false, vertical: true)
            Text(L10n.f("alibi.duration", max(1, file.durationSeconds / 60)) + " · " + String(repeating: "●", count: file.difficulty)
                 + String(repeating: "○", count: max(0, 3 - file.difficulty)))
                .font(Trace.Fonts.monoSmall)
                .foregroundStyle(Trace.Colors.inkSoft)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .paper(Trace.Colors.paper, radius: 2)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }

    private func status(of file: CaseFile) -> (text: String, done: Bool) {
        if file.id == inProgressID { return (L10n.t("alibi.status.inProgress"), false) }
        guard let p = progress[file.id] else { return (L10n.t("alibi.status.new"), false) }
        return p.solved ? (L10n.t("alibi.status.done"), true) : (L10n.t("alibi.status.tried"), false)
    }
}

// MARK: - Briefing

/// The mini-file: who, what they claim, where, when, what to do — then [COMMENCER].
struct AlibiBriefingView: View {
    let caseFile: CaseFile
    let durationSeconds: Int
    let inProgress: Bool
    let onStart: () -> Void
    let onResume: () -> Void
    let onClose: () -> Void

    private var person: Contact? {
        caseFile.claim.flatMap { claim in caseFile.devices.flatMap(\.contacts).first { $0.id == claim.person } }
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        Button(action: onClose) { Label(L10n.t("common.back"), systemImage: "chevron.left") }
                            .buttonStyle(TextLinkStyle())
                            .accessibilityIdentifier("alibi.briefingBack")
                        Spacer()
                    }
                    sheet
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
            }
            Group {
                if inProgress {
                    Button(L10n.t("home.resume"), action: onResume)
                        .accessibilityIdentifier("alibi.briefingResume")
                } else {
                    Button(L10n.t("alibi.start"), action: onStart)
                        .accessibilityIdentifier("alibi.briefingStart")
                }
            }
            .buttonStyle(CTAButtonStyle())
            .padding(.horizontal, 24)
            .padding(.vertical, 10)
        }
        .background(DeskBackdrop())
    }

    private var sheet: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(fileLabel(caseFile.number) + (caseFile.dossier.map { " · " + $0.category } ?? ""))
                .font(Trace.Fonts.kicker)
                .tracking(1.6)
                .foregroundStyle(Trace.Colors.stamp)
                .fixedSize(horizontal: false, vertical: true)
            Text(caseFile.title)
                .font(Trace.Fonts.serifTitle(28))
                .foregroundStyle(Trace.Colors.ink)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)
            if let city = caseFile.dossier?.city {
                Text(city + (caseFile.dossier.map { " — " + $0.place } ?? ""))
                    .font(Trace.Fonts.monoSmall)
                    .foregroundStyle(Trace.Colors.inkSoft)
            }
            Rectangle().fill(Trace.Colors.ink.opacity(0.18)).frame(height: 1)
            if let claim = caseFile.claim {
                LedgerRow(label: L10n.t("alibi.personLabel"), value: person?.name ?? "")
                Text(claim.statement)
                    .font(Trace.Fonts.quoteLarge)
                    .foregroundStyle(Trace.Colors.ink)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier("alibi.claim")
                LedgerRow(label: L10n.t("alibi.placeLabel"), value: claim.place)
                LedgerRow(label: L10n.t("alibi.windowLabel"), value: AlibiText.window(claim))
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(L10n.t("carnet.objective"))
                    .font(Trace.Fonts.kicker)
                    .tracking(1.6)
                    .foregroundStyle(Trace.Colors.stamp)
                Text(caseFile.objective)
                    .font(Trace.Fonts.prose.weight(.semibold))
                    .foregroundStyle(Trace.Colors.ink)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .overlay(Rectangle().strokeBorder(Trace.Colors.stamp.opacity(0.6), lineWidth: 1))
            ForEach(Array(caseFile.synopsis.enumerated()), id: \.offset) { _, line in
                Text(line)
                    .font(Trace.Fonts.prose)
                    .foregroundStyle(Trace.Colors.inkMid)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Rectangle().fill(Trace.Colors.ink.opacity(0.18)).frame(height: 1)
            // How to play, in three short lines (the first ALIBI explains itself).
            VStack(alignment: .leading, spacing: 6) {
                ForEach(1...3, id: \.self) { step in
                    Text("\(step). " + L10n.t("alibi.how\(step)"))
                        .font(Trace.Fonts.monoSmall)
                        .foregroundStyle(Trace.Colors.ink)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Text(L10n.f("alibi.time", PhoneFormat.countdown(Double(durationSeconds))))
                    .font(Trace.Fonts.monoSmall)
                    .foregroundStyle(Trace.Colors.inkSoft)
            }
            .accessibilityElement(children: .combine)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .paper(Trace.Colors.paper, radius: 0, lifted: true)
    }
}

// MARK: - Verdict

/// « SON ALIBI EST-IL FIABLE ? »: the statement, the player's own tally from the Carnet, two answers,
/// then a held button (1.2 s) — a deliberate action. VoiceOver / Switch Control: a button and a sheet.
struct AlibiVerdictView: View {
    let session: GameSession
    @State private var choice: Bool?
    @State private var confirming = false
    @State private var confirmed = false
    @State private var concluded = false
    @Environment(\.accessibilityVoiceOverEnabled) private var voiceOverEnabled
    @Environment(\.accessibilitySwitchControlEnabled) private var switchControlEnabled

    private var assistive: Bool {
        voiceOverEnabled || switchControlEnabled || UIAccessibility.isVoiceOverRunning || UIAccessibility.isSwitchControlRunning
    }

    var body: some View {
        let game = session.game
        let timeUp = session.remainingSeconds <= 0
        let person = session.caseFile.suspects.first
        let linked = person.map { game.linkedEntries(for: $0.id) } ?? []
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                HStack {
                    Text(fileLabel(session.caseFile.number) + " · " + L10n.t("alibi.verdict"))
                        .font(Trace.Fonts.kicker)
                        .tracking(1.6)
                        .foregroundStyle(Trace.Colors.bone2)
                    Spacer(minLength: 8)
                    if timeUp {
                        Text(L10n.t("accuse.timeUp"))
                            .font(Trace.Fonts.kicker)
                            .tracking(1.6)
                            .foregroundStyle(Trace.Colors.stampOnDark)
                            .accessibilityIdentifier("accuse.timeUp")
                    }
                }
                Text(L10n.t("alibi.question"))
                    .font(Trace.Fonts.monoTitle)
                    .tracking(1.2)
                    .foregroundStyle(Trace.Colors.bone)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityAddTraits(.isHeader)
                    .accessibilityIdentifier("alibi.question")
                if let claim = session.caseFile.claim {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(game.name(of: claim.person))
                            .font(Trace.Fonts.serifTitle(18))
                            .foregroundStyle(Trace.Colors.ink)
                        Text(claim.statement)
                            .font(Trace.Fonts.quote)
                            .foregroundStyle(Trace.Colors.ink)
                            .fixedSize(horizontal: false, vertical: true)
                        Text(claim.place + " · " + AlibiText.window(claim))
                            .font(Trace.Fonts.monoSmall)
                            .foregroundStyle(Trace.Colors.inkSoft)
                            .fixedSize(horizontal: false, vertical: true)
                        Text(verbatim: "▲ \(linked.filter { $0.stance == .incriminates }.count) " + L10n.t("alibi.tallyContradicts")
                             + "   ▼ \(linked.filter { $0.stance == .clears }.count) " + L10n.t("alibi.tallyConfirms"))
                            .font(Trace.Fonts.monoStrong)
                            .foregroundStyle(Trace.Colors.inkMid)
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .paper(Trace.Colors.paper, radius: 2)
                    .accessibilityElement(children: .combine)
                }
                answer(true)
                answer(false)
            }
            .padding(.horizontal, 16)
            .padding(.top, 20)
            .padding(.bottom, 24)
        }
        .scrollBounceBehavior(.basedOnSize)
        .safeAreaInset(edge: .bottom, spacing: 0) { footer(timeUp: timeUp) }
        .background(DeskBackdrop())
        .sheet(isPresented: $confirming, onDismiss: { if confirmed { conclude() } }) {
            PaperConfirmSheet(title: L10n.t("accuse.confirmTitle"),
                              message: choice.map { AlibiText.answer($0) } ?? "",
                              confirm: L10n.t("accuse.conclude"),
                              confirmID: "accuse.confirm",
                              cancel: L10n.t("common.back"),
                              cancelID: "accuse.confirmCancel",
                              onConfirm: { confirmed = true; confirming = false },
                              onCancel: { confirming = false })
                .presentationDetents([.medium])
                .presentationBackground(Trace.Colors.paper)
        }
    }

    /// [ALIBI CONFIRMÉ] / [ALIBI CONTREDIT]: a paper slip, stamped when chosen.
    private func answer(_ holds: Bool) -> some View {
        let chosen = choice == holds
        return Button {
            guard choice != holds else { return }
            withAnimation(.easeOut(duration: 0.2)) { choice = holds }
            Haptics.selection()
            AudioDirector.shared.play(.paper, volume: 0.3)
        } label: {
            HStack(spacing: 12) {
                Text(verbatim: holds ? "▼" : "▲")
                    .font(Trace.Fonts.monoTitle)
                    .foregroundStyle(holds ? Trace.Colors.ink : Trace.Colors.stamp)
                VStack(alignment: .leading, spacing: 4) {
                    Text(AlibiText.answer(holds))
                        .font(Trace.Fonts.cta)
                        .tracking(1.6)
                        .foregroundStyle(Trace.Colors.ink)
                    Text(L10n.t(holds ? "alibi.confirmedHelp" : "alibi.contradictedHelp"))
                        .font(Trace.Fonts.proseSmall)
                        .foregroundStyle(Trace.Colors.inkMid)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 4)
                if chosen { Text(verbatim: "✓").font(Trace.Fonts.monoTitle).foregroundStyle(Trace.Colors.stamp) }
            }
            .padding(16)
            .frame(maxWidth: .infinity, minHeight: 64, alignment: .leading)
            .paper(chosen ? Trace.Colors.paperSelected : Trace.Colors.paper, radius: 2, lifted: chosen)
            .overlay(RoundedRectangle(cornerRadius: 2).strokeBorder(Trace.Colors.stamp, lineWidth: 2).opacity(chosen ? 1 : 0))
            .contentShape(Rectangle())
        }
        .buttonStyle(PressableStyle())
        .opacity(choice == nil || chosen ? 1 : 0.6)
        .accessibilityAddTraits(chosen ? .isSelected : [])
        .accessibilityIdentifier(holds ? "alibi.answer.confirmed" : "alibi.answer.contradicted")
    }

    private func footer(timeUp: Bool) -> some View {
        let title = choice.map { L10n.f("alibi.hold", AlibiText.answer($0)) } ?? L10n.t("alibi.choose")
        return VStack(spacing: 2) {
            if assistive {
                Button(choice.map { AlibiText.answer($0) } ?? L10n.t("alibi.choose")) { requestConfirmation() }
                    .buttonStyle(CTAButtonStyle())
                    .disabled(choice == nil)
                    .accessibilityIdentifier("accuse.hold")
            } else {
                ConclusionHoldButton(title: title, enabled: choice != nil, actionName: L10n.t("accuse.conclude"),
                                     onActivate: { requestConfirmation() }, onComplete: { conclude() })
                    .accessibilityIdentifier("accuse.hold")
            }
            if !timeUp {
                Button(L10n.t("accuse.backToCarnet")) { session.resumeInvestigation() }
                    .buttonStyle(TextLinkStyle())
                    .accessibilityIdentifier("accuse.back")
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 14)
        .padding(.bottom, 10)
        .background(
            LinearGradient(colors: [Trace.Colors.launch.opacity(0), Trace.Colors.launch],
                           startPoint: .top, endPoint: UnitPoint(x: 0.5, y: 0.3))
                .ignoresSafeArea(edges: .bottom)
        )
    }

    private func requestConfirmation() {
        guard choice != nil, !concluded else { return }
        confirmed = false
        confirming = true
    }

    private func conclude() {
        guard let choice, !concluded else { return }
        concluded = true
        session.concludeAlibi(holds: choice)
    }
}

// MARK: - Result

/// « VÉRIFICATION DU DOSSIER… », the stamp (RÉSOLU when the verdict is right), then a one-page
/// report: the verdict, what really happened (right answer or on request), the key pieces found
/// ✓ / missed ○, the mark. Wrong: [REPRENDRE LA VÉRIFICATION], « Voir la réponse », « Classer quand même ».
struct AlibiResultView: View {
    let verdict: Verdict
    let caseFile: CaseFile
    let revealed: Bool
    let onFile: () -> Void
    let onRetry: () -> Void
    let onReveal: () -> Void

    @State private var reading = false
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    @AppStorage(Preferences.reduceMotionKey) private var appReduceMotion = false

    private var solved: Bool { verdict.isCorrect }
    private var open: Bool { solved || revealed }
    private var answer: Bool { verdict.alibiAnswer ?? false }

    var body: some View {
        ZStack {
            DeskBackdrop()
            if reading || revealed {
                report.transition(.opacity)
            } else {
                VerificationView(caseNumber: caseFile.number, caseTitle: caseFile.title,
                                 designation: L10n.f("alibi.yourVerdict", AlibiText.answer(answer)), solved: solved) {
                    AudioDirector.shared.play(.paper, volume: 0.4)
                    withAnimation(systemReduceMotion || appReduceMotion ? .easeInOut(duration: 0.2) : Trace.Motion.paper) { reading = true }
                }
                .transition(.opacity)
            }
        }
    }

    private var report: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(L10n.t("alibi.report") + " · " + fileLabel(caseFile.number))
                            .font(Trace.Fonts.kicker)
                            .tracking(1.6)
                            .foregroundStyle(Trace.Colors.inkSoft)
                        Text(caseFile.title)
                            .font(Trace.Fonts.serifTitle(22))
                            .foregroundStyle(Trace.Colors.ink)
                            .accessibilityAddTraits(.isHeader)
                    }
                    Spacer(minLength: 8)
                    StampImage(asset: solved ? "stamp_resolu_rouge_marque" : "stamp_non_resolu_noir_marque",
                               label: solved ? L10n.t("stamp.solved") : L10n.t("stamp.unsolved"),
                               width: solved ? 84 : 100, onPaper: true, angle: -8,
                               color: solved ? Trace.Colors.stamp : Trace.Colors.ink)
                }
                LedgerRow(label: L10n.t("alibi.yourAnswer"), value: AlibiText.answer(answer),
                          valueColor: solved ? Trace.Colors.stamp : Trace.Colors.ink)
                if open, let holds = caseFile.solution.alibiHolds {
                    LedgerRow(label: L10n.t("alibi.rightAnswer"), value: AlibiText.answer(holds), valueColor: Trace.Colors.stamp)
                    Text(caseFile.solution.headline)
                        .font(Trace.Fonts.serifTitle(19))
                        .foregroundStyle(Trace.Colors.ink)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(caseFile.solution.summary)
                        .font(Trace.Fonts.prose)
                        .foregroundStyle(Trace.Colors.inkMid)
                        .fixedSize(horizontal: false, vertical: true)
                    RevealTimeline(steps: caseFile.solution.reveal, found: verdict.foundEvidenceIDs,
                                   shown: caseFile.solution.reveal.count)
                } else {
                    Text(L10n.t("alibi.wrong"))
                        .font(Trace.Fonts.prose)
                        .foregroundStyle(Trace.Colors.inkMid)
                        .fixedSize(horizontal: false, vertical: true)
                    if let trap = caseFile.suspects.first?.trap {
                        LedgerRow(label: L10n.t("result.trap"), value: "")
                        Text(trap)
                            .font(Trace.Fonts.proseSmall)
                            .foregroundStyle(Trace.Colors.ink)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                Rectangle().fill(Trace.Colors.ink.opacity(0.18)).frame(height: 1)
                Text(L10n.f("alibi.piecesFound", verdict.foundCount, verdict.totalCount))
                    .font(Trace.Fonts.monoStrong)
                    .foregroundStyle(Trace.Colors.ink)
                ForEach(caseFile.evidence.filter { $0.importance == .key }) { evidence in
                    let found = verdict.foundEvidenceIDs.contains(evidence.id)
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text(verbatim: found ? "✓" : "○").foregroundStyle(found ? Trace.Colors.stamp : Trace.Colors.inkSoft)
                        Text(found || open ? evidence.title : L10n.t("result.keyHiddenGeneric"))
                            .foregroundStyle(Trace.Colors.ink)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .font(Trace.Fonts.proseSmall)
                    .accessibilityElement(children: .combine)
                }
                LedgerRow(label: L10n.t("result.colHints"), value: "\(verdict.hintsUsed)")
                LedgerRow(label: L10n.t("result.colMark"), value: "\(verdict.score)/100")
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .paper(Trace.Colors.paper, radius: 0, lifted: true)
            .padding(.horizontal, 16)
            .padding(.vertical, 20)
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("result.report")
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            VStack(spacing: 2) {
                if solved {
                    Button(L10n.t("result.fileCase"), action: onFile)
                        .buttonStyle(CTAButtonStyle())
                        .accessibilityIdentifier("result.file")
                } else {
                    Button(L10n.t("alibi.retry"), action: onRetry)
                        .buttonStyle(CTAButtonStyle())
                        .accessibilityIdentifier("result.retry")
                    if !revealed {
                        Button(L10n.t("alibi.showAnswer"), action: onReveal)
                            .buttonStyle(TextLinkStyle())
                            .accessibilityIdentifier("result.reveal")
                    }
                    Button(L10n.t("result.fileAnyway"), action: onFile)
                        .buttonStyle(TextLinkStyle())
                        .accessibilityIdentifier("result.fileAnyway")
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 10)
            .background(Trace.Colors.launch.opacity(0.9).ignoresSafeArea(edges: .bottom))
        }
    }
}
#endif
