#if os(iOS)
import SwiftUI
import UIKit
import CaseEngine

// The ALIBI mode (docs/game_modes/ALIBI.md): « Vérifier. Croiser. Conclure. » One person, one
// statement, the same phone and the same Carnet as an investigation, then one question —
// « Son alibi est-il fiable ? » — answered with a held button, the verification and a report.
// V4 « Dossier lisible » (docs/design_v4 §8 step 6): the ALIBI files are blue-grey paper folders
// (`stubAlibi`) with ink text (the Bureau's ALIBI tab is `AlibiFolder`, in DeskScreens.swift); the statement is framed in red on a paper sheet, the person's photo
// stapled; the verdict is chosen between two paper cards on the deep desk; the report is a paper
// sheet stamped ALIBI CONFIRMÉ (green) or ALIBI CONTREDIT (red). Flow and logic unchanged.

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

    /// ✓ ALIBI CONFIRMÉ / ✕ ALIBI CONTREDIT: never the colour alone.
    static func symbol(_ holds: Bool) -> String { holds ? "✓" : "✕" }

    /// Green for « confirmé », red for « contredit » — on paper, or on the desk.
    static func color(_ holds: Bool, onPaper: Bool = true) -> Color {
        holds ? (onPaper ? Trace.Colors.green : Trace.Colors.successText)
              : (onPaper ? Trace.Colors.red : Trace.Colors.redOnDesk)
    }

    /// The person who makes the statement (a contact of the phone).
    static func person(of file: CaseFile) -> Contact? {
        file.claim.flatMap { claim in file.devices.flatMap(\.contacts).first { $0.id == claim.person } }
    }
}

/// Sizes of the ALIBI screens (V4 §2–§3).
private enum AlibiLayout {
    /// The briefing: the folder fills the screen, the sheet inserted with a 10 pt margin; « Lieu ·
    /// Type » in Plex Sans 15/500 (§3 CaseFolder).
    static let folderInset: CGFloat = Trace.Spacing.edge
    static let placeFont = Font.custom(Trace.FontName.sansMedium, size: 15, relativeTo: .subheadline)
    /// The statement's red frame (1.5 pt, §3 CaseSheet « Mission »).
    static let frame: CGFloat = 1.5
    /// The person's photo, stapled: 64 × 80 on the briefing, 56 × 70 on the verdict.
    static let photo = CGSize(width: 64, height: 80)
    static let smallPhoto = CGSize(width: 56, height: 70)
    /// A verdict card: min 72 pt, red rule 2 pt, red pin 14 pt, lifted 4 pt; the other at 55 %.
    static let answerMinHeight: CGFloat = 72
    static let rule: CGFloat = 2
    static let pin: CGFloat = 14
    static let lift: CGFloat = 4
    static let dimmed: Double = 0.55
    /// The report's code stamp (Plex Mono 16/700, −8°) and the signature.
    static let stampSize: CGFloat = 16
    static let unsolvedStampWidth: CGFloat = 150
    static let signatureWidth: CGFloat = 116
}

// MARK: - Briefing

/// The mini-file (V4 02, in the ALIBI folder): the blue-grey folder fills the screen — « ‹ Bureau » in
/// ink and the OUVERT stamp on it — and, inserted with a 10 pt margin, a paper sheet (§3 CaseSheet):
/// ALIBI #00N, the title, « Lieu · Type » over a 1.5 pt ink rule; DÉCLARATION À VÉRIFIER framed in red (the
/// person's photo stapled, the statement in Newsreader, the place and the window); VOTRE MISSION;
/// CONTEXTE; after a dotted rule, COMMENT ENQUÊTER. Fixed footer on the bar: [Commencer] (or
/// [Reprendre l'enquête]) and the time.
struct AlibiBriefingView: View {
    let caseFile: CaseFile
    let durationSeconds: Int
    let inProgress: Bool
    let onStart: () -> Void
    let onResume: () -> Void
    let onClose: () -> Void

    private var person: Contact? { AlibiText.person(of: caseFile) }

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 0) {
                topBar
                ScrollView {
                    sheet
                        .padding(.horizontal, AlibiLayout.folderInset)
                        .padding(.top, Trace.Spacing.xs)
                        .padding(.bottom, Trace.Spacing.l)
                }
                .scrollIndicators(.hidden)
                .scrollBounceBehavior(.basedOnSize)
            }
            .background { Color.clear.kraft(color: Trace.Colors.stubAlibi).ignoresSafeArea(edges: .top) }
            footer
        }
        .background(Trace.Colors.bar.ignoresSafeArea())
    }

    /// « ‹ Bureau » in ink on the folder, and the OUVERT code stamp (as on the case file, 02).
    private var topBar: some View {
        HStack(alignment: .center, spacing: Trace.Spacing.m) {
            BackLink(title: L10n.t("tab.bureau"), identifier: "alibi.briefingBack", onPaper: true, action: onClose)
            Spacer(minLength: Trace.Spacing.s)
            StampMark(text: L10n.t("briefing.status.opened"), size: 12)
                .padding(.trailing, 6)
        }
        .padding(.horizontal, Paperwork.deskMargin)
        .padding(.bottom, Trace.Spacing.xs)
    }

    private var sheet: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            PaperworkRule(strong: true)
                .padding(.top, Trace.Spacing.m + 2)
            claimFrame
                .padding(.top, Trace.Spacing.xl)
            mission
                .padding(.top, Trace.Spacing.xxl)
            context
                .padding(.top, Trace.Spacing.xxl)
            PaperworkDots()
                .padding(.top, Trace.Spacing.xxl)
            howTo
                .padding(.top, Trace.Spacing.xl)
        }
        .padding(Paperwork.sheetPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .paper()
    }

    /// ALIBI #00N, the title, « Lieu · Type ».
    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(fileLabel(caseFile.number))
                .font(Trace.Fonts.data)
                .tracking(1.2)
                .foregroundStyle(Trace.Colors.ink2)
            Text(caseFile.title.capitalizedFirst)
                .font(Trace.Fonts.caseTitle)
                .foregroundStyle(Trace.Colors.ink)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)
            let place = Self.placeLine(DossierFacts(file: caseFile))
            if !place.isEmpty {
                Text(place)
                    .font(AlibiLayout.placeFont)
                    .foregroundStyle(Trace.Colors.ink2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    /// « Marseille · Disparition »
    private static func placeLine(_ facts: DossierFacts) -> String {
        [facts.city, facts.category.capitalizedFirst].filter { !$0.isEmpty }.joined(separator: " · ")
    }

    /// DÉCLARATION À VÉRIFIER, framed in red: who (photo stapled), what (Newsreader), where, when.
    @ViewBuilder
    private var claimFrame: some View {
        if let claim = caseFile.claim {
            VStack(alignment: .leading, spacing: Trace.Spacing.l) {
                Text(L10n.t("alibi.claimLabel"))
                    .fieldLabel(Trace.Colors.red)
                    .accessibilityAddTraits(.isHeader)
                HStack(alignment: .center, spacing: Trace.Spacing.l) {
                    IDPhoto(contact: person, width: AlibiLayout.photo.width, height: AlibiLayout.photo.height, stapled: true)
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(person?.name ?? "")
                            .font(Trace.Fonts.personName)
                            .foregroundStyle(Trace.Colors.ink)
                            .fixedSize(horizontal: false, vertical: true)
                        Text(L10n.t("alibi.personLabel"))
                            .fieldLabel(Trace.Colors.ink2)
                    }
                    .accessibilityElement(children: .combine)
                }
                Text(claim.statement)
                    .font(Trace.Fonts.quote)
                    .foregroundStyle(Trace.Colors.ink)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier("alibi.claim")
                VStack(alignment: .leading, spacing: 0) {
                    field(L10n.t("alibi.placeLabel"), claim.place)
                    field(L10n.t("alibi.windowLabel"), AlibiText.window(claim))
                }
            }
            .padding(Trace.Spacing.l)
            .frame(maxWidth: .infinity, alignment: .leading)
            .overlay(Rectangle().strokeBorder(Trace.Colors.red, lineWidth: AlibiLayout.frame))
        }
    }

    /// LABEL / value under a thin ink rule.
    private func field(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(label)
                .fieldLabel(Trace.Colors.ink2)
            Text(value)
                .font(Trace.Fonts.callout)
                .foregroundStyle(Trace.Colors.ink)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, Trace.Spacing.s)
        .frame(maxWidth: .infinity, alignment: .leading)
        .overlay(alignment: .top) { PaperworkRule() }
        .accessibilityElement(children: .combine)
    }

    private var mission: some View {
        VStack(alignment: .leading, spacing: Trace.Spacing.s) {
            Text(L10n.t("briefing.mission"))
                .fieldLabel(Trace.Colors.red)
                .accessibilityAddTraits(.isHeader)
            Text(caseFile.objective)
                .font(Trace.Fonts.body)
                .foregroundStyle(Trace.Colors.ink)
                .fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityElement(children: .combine)
    }

    private var context: some View {
        VStack(alignment: .leading, spacing: Trace.Spacing.s) {
            Text(L10n.t("dossier.tab.context"))
                .fieldLabel(Trace.Colors.ink2)
                .accessibilityAddTraits(.isHeader)
            VStack(alignment: .leading, spacing: Trace.Spacing.s + 2) {
                ForEach(Array(caseFile.synopsis.enumerated()), id: \.offset) { _, line in
                    Text(line)
                        .font(Trace.Fonts.body)
                        .foregroundStyle(Trace.Colors.ink)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    /// How to play, in three short lines (the first ALIBI explains itself).
    private var howTo: some View {
        VStack(alignment: .leading, spacing: Trace.Spacing.s + 2) {
            Text(L10n.t("dossier.how"))
                .fieldLabel(Trace.Colors.ink2)
                .accessibilityAddTraits(.isHeader)
            ForEach(1...3, id: \.self) { step in
                HStack(alignment: .firstTextBaseline, spacing: Trace.Spacing.m) {
                    Text(verbatim: "0\(step)")
                        .font(Trace.Fonts.data)
                        .foregroundStyle(Trace.Colors.ink2)
                    Text(L10n.t("alibi.how\(step)"))
                        .font(Trace.Fonts.callout)
                        .foregroundStyle(Trace.Colors.ink)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .accessibilityElement(children: .combine)
    }

    private var footer: some View {
        VStack(spacing: 6) {
            Group {
                if inProgress {
                    Button(L10n.t("home.resume"), action: onResume)
                        .accessibilityIdentifier("alibi.briefingResume")
                } else {
                    Button(L10n.t("alibi.start"), action: onStart)
                        .accessibilityIdentifier("alibi.briefingStart")
                }
            }
            .buttonStyle(CTAButtonStyle(kind: .primary))
            Text(L10n.f("alibi.time", PhoneFormat.countdown(Double(durationSeconds))))
                .font(Trace.Fonts.data)
                .foregroundStyle(Trace.Colors.ivory2)
        }
        .padding(.horizontal, Paperwork.deskMargin)
        .padding(.top, Trace.Spacing.m)
        .padding(.bottom, Trace.Spacing.s + 2)
        .background(Trace.Colors.bar.ignoresSafeArea(edges: .bottom))
    }
}

// MARK: - Verdict

/// « Son alibi est-il fiable ? » on the deep desk (V4 09): the number in red, the question in
/// Newsreader 36, the statement on a paper card (photo stapled, the player's own tally from the
/// Carnet ↑ contre / ↓ pour), two paper cards « Alibi confirmé » / « Alibi contredit » (selected:
/// straight, lifted, 2 pt red rule and a red pin; the other at 55 %), then the hold (1.6 s).
/// VoiceOver: a double tap asks for confirmation.
struct AlibiVerdictView: View {
    let session: GameSession
    @State private var choice: Bool?
    @State private var concluded = false
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    @AppStorage(Preferences.reduceMotionKey) private var appReduceMotion = false

    private var still: Bool { systemReduceMotion || appReduceMotion }

    var body: some View {
        let timeUp = session.remainingSeconds <= 0
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .firstTextBaseline, spacing: Trace.Spacing.s) {
                    Text(fileLabel(session.caseFile.number) + " · " + L10n.t("alibi.verdict"))
                        .font(Trace.Fonts.data)
                        .foregroundStyle(Trace.Colors.redOnDesk)
                    Spacer(minLength: Trace.Spacing.s)
                    if timeUp {
                        Text(L10n.t("accuse.timeUp"))
                            .font(Trace.Fonts.data)
                            .foregroundStyle(Trace.Colors.redOnDesk)
                            .accessibilityIdentifier("accuse.timeUp")
                    }
                }
                Text(L10n.t("alibi.question"))
                    .font(Trace.Fonts.display)
                    .foregroundStyle(Trace.Colors.ivory)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, Trace.Spacing.s + 2)
                    .accessibilityAddTraits(.isHeader)
                    .accessibilityIdentifier("alibi.question")
                claimCard
                    .padding(.top, Trace.Spacing.xl)
                VStack(spacing: Trace.Spacing.xl) {
                    answer(true)
                    answer(false)
                }
                .padding(.top, Trace.Spacing.xxl + Trace.Spacing.s)
            }
            .padding(.horizontal, Trace.Spacing.xl)
            .padding(.top, Trace.Spacing.xl)
            .padding(.bottom, Trace.Spacing.xxl)
        }
        .scrollBounceBehavior(.basedOnSize)
        .safeAreaInset(edge: .bottom, spacing: 0) { footer(timeUp: timeUp) }
        .background(DeepDeskBackdrop())
    }

    /// The statement being judged, as filed: photo stapled, name, words, place and window, tally.
    @ViewBuilder
    private var claimCard: some View {
        if let claim = session.caseFile.claim {
            let game = session.game
            let linked = session.caseFile.suspects.first.map { game.linkedEntries(for: $0.id) } ?? []
            let against = linked.filter { $0.stance == .incriminates }.count
            let infavour = linked.filter { $0.stance == .clears }.count
            VStack(alignment: .leading, spacing: Trace.Spacing.m) {
                HStack(alignment: .center, spacing: Trace.Spacing.l) {
                    IDPhoto(contact: AlibiText.person(of: session.caseFile),
                            width: AlibiLayout.smallPhoto.width, height: AlibiLayout.smallPhoto.height, stapled: true)
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(game.name(of: claim.person))
                            .font(Trace.Fonts.personName)
                            .foregroundStyle(Trace.Colors.ink)
                            .fixedSize(horizontal: false, vertical: true)
                        Text(claim.place + " · " + AlibiText.window(claim))
                            .font(Trace.Fonts.caption)
                            .foregroundStyle(Trace.Colors.ink2)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                Text(claim.statement)
                    .font(Trace.Fonts.quote)
                    .foregroundStyle(Trace.Colors.ink)
                    .fixedSize(horizontal: false, vertical: true)
                HStack(spacing: Trace.Spacing.l) {
                    Text(verbatim: "↑ \(against) " + L10n.t("alibi.tallyContradicts"))
                        .foregroundStyle(Trace.Colors.red)
                    Text(verbatim: "↓ \(infavour) " + L10n.t("alibi.tallyConfirms"))
                        .foregroundStyle(Trace.Colors.green)
                }
                .font(Trace.Fonts.data)
            }
            .padding(Trace.Spacing.l)
            .frame(maxWidth: .infinity, alignment: .leading)
            .paper(Trace.Colors.paperCard)
            .accessibilityElement(children: .combine)
        }
    }

    /// « Alibi confirmé » / « Alibi contredit »: a paper card.
    private func answer(_ holds: Bool) -> some View {
        let chosen = choice == holds
        return Button {
            guard choice != holds else { return }
            Haptics.selection()
            choice = holds
        } label: {
            VStack(alignment: .leading, spacing: Trace.Spacing.s) {
                HStack(alignment: .firstTextBaseline, spacing: Trace.Spacing.s) {
                    Text(verbatim: AlibiText.symbol(holds))
                        .font(Trace.Fonts.pieceTitle)
                        .foregroundStyle(AlibiText.color(holds))
                    Text(AlibiText.answer(holds).capitalizedFirst)
                        .font(Trace.Fonts.personName)
                        .foregroundStyle(Trace.Colors.ink)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Text(L10n.t(holds ? "alibi.confirmedHelp" : "alibi.contradictedHelp"))
                    .font(Trace.Fonts.callout)
                    .foregroundStyle(Trace.Colors.ink2)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, Trace.Spacing.l + 2)
            .padding(.vertical, Trace.Spacing.l)
            .frame(maxWidth: .infinity, minHeight: AlibiLayout.answerMinHeight, alignment: .leading)
            .paper(chosen ? Trace.Colors.paperCardLight : Trace.Colors.paperCard)
            .overlay(Rectangle().strokeBorder(Trace.Colors.red, lineWidth: AlibiLayout.rule).opacity(chosen ? 1 : 0))
            .overlay(alignment: .top) {
                Pin(color: Trace.Colors.red, size: AlibiLayout.pin)
                    .offset(y: -AlibiLayout.pin / 2)
                    .scaleEffect(chosen || still ? 1 : 1.2)
                    .opacity(chosen ? 1 : 0)
            }
            .offset(y: chosen && !still ? -AlibiLayout.lift : 0)
            .animation(still ? nil : .easeOut(duration: 0.26), value: chosen)
            .contentShape(Rectangle())
        }
        .buttonStyle(PressableStyle())
        .opacity(choice == nil || chosen ? 1 : AlibiLayout.dimmed)
        .animation(.easeInOut(duration: 0.2), value: choice)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(chosen ? .isSelected : [])
        .accessibilityIdentifier(holds ? "alibi.answer.confirmed" : "alibi.answer.contradicted")
    }

    private func footer(timeUp: Bool) -> some View {
        let title = choice.map { L10n.f("alibi.hold", AlibiText.answer($0)) } ?? L10n.t("alibi.choose")
        return VStack(spacing: 2) {
            BenHoldButton(title: title,
                          seconds: Trace.Motion.holdToClose,
                          enabled: choice != nil,
                          identifier: "accuse.hold",
                          accessibilityConfirm: choice.map { AlibiText.answer($0) + " ?" },
                          action: conclude)
            if !timeUp {
                Button(L10n.t("accuse.backToCarnet")) { session.resumeInvestigation() }
                    .buttonStyle(TextLinkStyle())
                    .accessibilityIdentifier("accuse.back")
            }
        }
        .padding(.horizontal, Trace.Spacing.xl)
        .padding(.top, Trace.Spacing.m)
        .padding(.bottom, Trace.Spacing.s + 2)
        .background(Trace.Colors.deskDeepGradient[2].ignoresSafeArea(edges: .bottom))
    }

    private func conclude() {
        guard let choice, !concluded else { return }
        concluded = true
        session.concludeAlibi(holds: choice)
    }
}

// MARK: - Result

/// The verification (1.8 s, shared: it stamps RÉSOLU when the verdict is right, NON RÉSOLU when it
/// is wrong), then the report on one paper sheet (§3 ClosingReport): RAPPORT · ALIBI #00N, the
/// title; the stamp — once the answer is open (right verdict, or « Voir la réponse »), the code
/// stamp of the right answer, ALIBI CONFIRMÉ (green frame) or ALIBI CONTREDIT (red frame); a wrong
/// verdict not yet revealed keeps the NON RÉSOLU stamp and never shows the answer (solution on
/// request only). Then « Verdict juste / erroné », your verdict and the answer with dotted leaders,
/// what really happened (or the trap), the key pieces ✓ / ○, the figures, the visa. Footer on the
/// bar: [Classer le dossier]; wrong: [Reprendre la vérification], « Voir la réponse », « Classer
/// quand même ».
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
    /// The right answer, when the report may show it.
    private var rightAnswer: Bool? { open ? caseFile.solution.alibiHolds : nil }

    var body: some View {
        ZStack {
            DeskBackdrop()
            if reading || revealed {
                report.transition(.opacity)
            } else {
                VerificationView(caseNumber: caseFile.number, caseTitle: caseFile.title,
                                 designation: L10n.f("alibi.yourVerdict", AlibiText.answer(answer)), solved: solved,
                                 decisiveFound: verdict.foundCount, decisiveTotal: verdict.totalCount) {
                    withAnimation(systemReduceMotion || appReduceMotion ? .easeInOut(duration: 0.2) : Trace.Motion.paper) { reading = true }
                }
                .transition(.opacity)
            }
        }
    }

    private var report: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                PaperworkHeader(kicker: L10n.t("alibi.report"), trailing: fileLabel(caseFile.number),
                                title: caseFile.title.capitalizedFirst)
                stamp
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .padding(.top, Trace.Spacing.l)
                Text(verbatim: (solved ? "✓ " : "✕ ") + L10n.t(solved ? "alibi.result.right" : "alibi.result.wrong"))
                    .font(Trace.Fonts.headline)
                    .foregroundStyle(solved ? Trace.Colors.green : Trace.Colors.red)
                    .fixedSize(horizontal: false, vertical: true)
                    // Clear of the tilted stamp's lower corner.
                    .padding(.top, Trace.Spacing.l)
                answers
                    .padding(.top, Trace.Spacing.xs)
                story
                    .padding(.top, Trace.Spacing.xxl)
                keyPieces
                    .padding(.top, Trace.Spacing.xxl)
                figures
                    .padding(.top, Trace.Spacing.xl)
                visa
                    .padding(.top, Trace.Spacing.s)
            }
            .padding(Paperwork.sheetPadding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .paper()
            .padding(.horizontal, Paperwork.deskMargin)
            .padding(.vertical, Trace.Spacing.xl)
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("result.report")
        }
        .scrollBounceBehavior(.basedOnSize)
        .safeAreaInset(edge: .bottom, spacing: 0) { footer }
    }

    /// The code stamp of the right answer once open; NON RÉSOLU while a wrong verdict is not
    /// revealed. Carries "result.read" (the UI tests wait for it).
    @ViewBuilder
    private var stamp: some View {
        if let holds = rightAnswer {
            FallingStamp(text: AlibiText.answer(holds), color: AlibiText.color(holds), size: AlibiLayout.stampSize)
                .accessibilityIdentifier("result.read")
        } else {
            FallingStampImage(asset: "stamp_non_resolu_noir_marque", label: L10n.t("case.state.unsolved"),
                              width: AlibiLayout.unsolvedStampWidth, color: Trace.Colors.ink, success: false)
                .accessibilityIdentifier("result.read")
        }
    }

    /// Votre verdict ........ ✕ ALIBI CONTREDIT / La réponse ........ ✓ ALIBI CONFIRMÉ (once open).
    private var answers: some View {
        VStack(spacing: 0) {
            PaperworkLedgerLine(label: L10n.t("alibi.yourAnswer"),
                                value: AlibiText.symbol(answer) + " " + AlibiText.answer(answer),
                                valueColor: AlibiText.color(answer))
            if let holds = rightAnswer {
                PaperworkLedgerLine(label: L10n.t("alibi.rightAnswer"),
                                    value: AlibiText.symbol(holds) + " " + AlibiText.answer(holds),
                                    valueColor: AlibiText.color(holds))
            }
        }
    }

    /// What really happened (once open), else the wrong-verdict note and the trap.
    @ViewBuilder
    private var story: some View {
        if open {
            VStack(alignment: .leading, spacing: Trace.Spacing.m) {
                Text(L10n.t("result.whatHappened"))
                    .fieldLabel(Trace.Colors.ink2)
                    .accessibilityAddTraits(.isHeader)
                Text(caseFile.solution.headline)
                    .font(Trace.Fonts.headline)
                    .foregroundStyle(Trace.Colors.ink)
                    .fixedSize(horizontal: false, vertical: true)
                Text(caseFile.solution.summary)
                    .font(Trace.Fonts.body)
                    .foregroundStyle(Trace.Colors.ink2)
                    .fixedSize(horizontal: false, vertical: true)
                RevealTimeline(steps: caseFile.solution.reveal, found: verdict.foundEvidenceIDs,
                               shown: caseFile.solution.reveal.count, onPaper: true)
                    .padding(.top, Trace.Spacing.xs)
            }
        } else {
            VStack(alignment: .leading, spacing: Trace.Spacing.m) {
                Text(L10n.t("alibi.wrong"))
                    .font(Trace.Fonts.body)
                    .foregroundStyle(Trace.Colors.ink2)
                    .fixedSize(horizontal: false, vertical: true)
                if let trap = caseFile.suspects.first?.trap {
                    Text(L10n.t("result.trap"))
                        .fieldLabel(Trace.Colors.red)
                        .padding(.top, Trace.Spacing.s)
                        .accessibilityAddTraits(.isHeader)
                    Text(trap)
                        .font(Trace.Fonts.callout)
                        .foregroundStyle(Trace.Colors.ink)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    /// Key pieces found ✓ / missed ○ (missed ones stay unnamed until the answer is open).
    private var keyPieces: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(L10n.f("alibi.piecesFound", verdict.foundCount, verdict.totalCount))
                .fieldLabel(Trace.Colors.ink2)
                .padding(.bottom, Trace.Spacing.s)
                .accessibilityAddTraits(.isHeader)
            ForEach(caseFile.evidence.filter { $0.importance == .key }) { evidence in
                let found = verdict.foundEvidenceIDs.contains(evidence.id)
                HStack(alignment: .firstTextBaseline, spacing: Trace.Spacing.s) {
                    Text(verbatim: found ? "✓" : "○")
                        .foregroundStyle(found ? Trace.Colors.green : Trace.Colors.ink2)
                    Text(found || open ? evidence.title : L10n.t("result.keyHiddenGeneric"))
                        .foregroundStyle(found ? Trace.Colors.ink : Trace.Colors.ink2)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 0)
                }
                .font(Trace.Fonts.callout)
                .padding(.vertical, Trace.Spacing.s)
                .overlay(alignment: .top) { PaperworkRule() }
                .accessibilityElement(children: .combine)
            }
        }
    }

    /// Temps restant, Indices, then the mark in Newsreader 40.
    private var figures: some View {
        VStack(spacing: 0) {
            PaperworkLedgerLine(label: L10n.t("result.timeLeft"), value: PhoneFormat.countdown(Double(verdict.remainingSeconds)))
            PaperworkLedgerLine(label: L10n.t("result.colHints"), value: "\(verdict.hintsUsed)")
            HStack(alignment: .lastTextBaseline, spacing: 6) {
                Text(L10n.t("result.finalMark"))
                    .fieldLabel(Trace.Colors.ink2)
                PaperworkDots()
                    .frame(minWidth: 12)
                Text(verbatim: "\(verdict.score)")
                    .font(Trace.Fonts.score)
                    .foregroundStyle(Trace.Colors.ink)
                Text(verbatim: "/100")
                    .font(Trace.Fonts.data)
                    .foregroundStyle(Trace.Colors.ink2)
            }
            .padding(.top, Trace.Spacing.s)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text(verbatim: L10n.t("result.finalMark") + ", \(verdict.score)/100"))
        }
    }

    /// Lacaze's visa (signature), bottom right; decorative.
    @ViewBuilder
    private var visa: some View {
        if let signature = ArtLibrary.image("signature_lacaze_bleu") {
            Image(uiImage: signature)
                .resizable()
                .scaledToFit()
                .frame(width: AlibiLayout.signatureWidth)
                .blendMode(.multiply)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .accessibilityHidden(true)
        }
    }

    private var footer: some View {
        VStack(spacing: 2) {
            if solved {
                Button(L10n.t("result.fileCase"), action: onFile)
                    .buttonStyle(CTAButtonStyle(kind: .primary))
                    .accessibilityIdentifier("result.file")
            } else {
                Button(L10n.t("alibi.retry"), action: onRetry)
                    .buttonStyle(CTAButtonStyle(kind: .primary))
                    .accessibilityIdentifier("result.retry")
                // Side by side; one under the other when the text is large.
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: Trace.Spacing.xl) { secondaryLinks }
                    VStack(spacing: 0) { secondaryLinks }
                }
            }
        }
        .padding(.horizontal, Paperwork.deskMargin)
        .padding(.top, Trace.Spacing.m)
        .padding(.bottom, Trace.Spacing.s + 2)
        .background(Trace.Colors.bar.ignoresSafeArea(edges: .bottom))
    }

    /// « Voir la réponse » (until revealed) and « Classer quand même ».
    @ViewBuilder
    private var secondaryLinks: some View {
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
#endif
