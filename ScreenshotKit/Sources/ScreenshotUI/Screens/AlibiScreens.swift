#if os(iOS)
import SwiftUI
import UIKit
import CaseEngine

// The ALIBI mode (docs/game_modes/ALIBI.md): « Vérifier. Croiser. Conclure. » One person, one
// statement, the same phone and the same Carnet as an investigation, then one question —
// « Son alibi est-il fiable ? » — answered with a held button, the verification and a report.
// UX V3 re-skin: flat cards, V3 buttons, StatusBadges instead of stamps. Flow and logic unchanged.

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

    /// ALIBI CONFIRMÉ (success, ✓) / ALIBI CONTREDIT (critical, ✕): never the colour alone.
    @MainActor
    static func badge(_ holds: Bool) -> StatusBadge {
        StatusBadge(text: answer(holds),
                    color: holds ? Trace.Colors.successText : Trace.Colors.criticalOnDark,
                    symbol: holds ? "✓" : "✕")
    }
}

// MARK: - The Alibi segment of the Bureau (the list of checks)

/// The Bureau's « Alibi » segment (§6-01): the mode's name and promise, the checks as 50 pt rows
/// (state on each), and one main button for the next check ([Commencer], or [Reprendre] when one
/// is in progress). Embedded in the Bureau: no background, no back link.
struct AlibiDeskView: View {
    let cases: [CaseFile]
    let progress: [String: CaseProgress]
    let inProgressID: String?
    let onOpen: (CaseFile) -> Void
    let onResume: () -> Void

    private var next: CaseFile? {
        cases.first { $0.id == inProgressID } ?? cases.first { progress[$0.id]?.solved != true } ?? cases.first
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(L10n.t("desk.mode.alibi"))
                    .font(Trace.Fonts.serifTitle(24))
                    .foregroundStyle(Trace.Colors.text)
                    .accessibilityAddTraits(.isHeader)
                    .accessibilityIdentifier("alibi.title")
                Text(L10n.t("modecard.alibi.subtitle"))
                    .font(Trace.Fonts.callout)
                    .foregroundStyle(Trace.Colors.benText)
                Text(L10n.t("alibi.pitch"))
                    .font(Trace.Fonts.body)
                    .foregroundStyle(Trace.Colors.text2)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 4)
            }
            if cases.isEmpty {
                EmptyPage(title: L10n.t("archives.empty"), tip: L10n.t("alibi.pitch"))
            } else {
                VStack(alignment: .leading, spacing: 0) {
                    SectionHeader(title: L10n.t("alibi.list"))
                    VStack(spacing: 0) {
                        ForEach(Array(cases.enumerated()), id: \.element.id) { index, file in
                            row(file, divider: index < cases.count - 1)
                        }
                    }
                    .benCard()
                }
            }
            if let next {
                Group {
                    if next.id == inProgressID {
                        Button(L10n.t("desk.resume"), action: onResume)
                            .accessibilityIdentifier("alibi.resume")
                    } else {
                        Button(L10n.t("alibi.start")) { onOpen(next) }
                            .accessibilityIdentifier("alibi.start")
                    }
                }
                .buttonStyle(CTAButtonStyle())
            }
        }
        .accessibilityElement(children: .contain)
    }

    private func open(_ file: CaseFile) {
        if file.id == inProgressID { onResume() } else { onOpen(file) }
    }

    /// « ALIBI #001 · Le dîner », the person, the time, the state.
    private func row(_ file: CaseFile, divider: Bool) -> some View {
        let status = self.status(of: file)
        return Button { open(file) } label: {
            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(fileLabel(file.number))
                        .font(Trace.Fonts.data)
                        .foregroundStyle(Trace.Colors.benText)
                    Text(file.title.capitalizedFirst)
                        .font(Trace.Fonts.headline)
                        .foregroundStyle(Trace.Colors.text)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(file.tagline)
                        .font(Trace.Fonts.caption)
                        .foregroundStyle(Trace.Colors.text2)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(L10n.f("alibi.duration", max(1, file.durationSeconds / 60)))
                        .font(Trace.Fonts.data)
                        .foregroundStyle(Trace.Colors.text2)
                }
                Spacer(minLength: 8)
                Text(status.text)
                    .font(Trace.Fonts.caption)
                    .foregroundStyle(status.color)
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Trace.Colors.text3)
                    .accessibilityHidden(true)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity, minHeight: Trace.Height.row, alignment: .leading)
            .overlay(alignment: .bottom) {
                if divider { Rectangle().fill(Trace.Colors.line).frame(height: 1).padding(.leading, 16) }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(PressableStyle())
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("alibi.case.\(file.id)")
    }

    private func status(of file: CaseFile) -> (text: String, color: Color) {
        if file.id == inProgressID { return ("◐ " + L10n.t("alibi.status.inProgress"), Trace.Colors.benText) }
        guard let p = progress[file.id] else { return (L10n.t("alibi.status.new"), Trace.Colors.text2) }
        return p.solved ? ("✓ " + L10n.t("alibi.status.done"), Trace.Colors.successText)
                        : (L10n.t("alibi.status.tried"), Trace.Colors.text2)
    }
}

// MARK: - Briefing

/// The mini-file: « ‹ Bureau », ALIBI #00N, the title, « Lieu · Type »; LA DÉCLARATION (who,
/// what, where, when) in a card with a ben rule; VOTRE MISSION; CONTEXTE; COMMENT; then the fixed
/// footer [Commencer] (or [Reprendre l'enquête]).
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
        VStack(alignment: .leading, spacing: 0) {
            BackLink(title: L10n.t("tab.bureau"), identifier: "alibi.briefingBack", action: onClose)
                .padding(.horizontal, 16)
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    header
                    claimCard
                    mission
                    context
                    howTo
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 24)
            }
            .scrollIndicators(.hidden)
            footer
        }
        .background(DeskBackdrop())
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(fileLabel(caseFile.number))
                .font(Trace.Fonts.data)
                .foregroundStyle(Trace.Colors.benText)
            Text(caseFile.title.capitalizedFirst)
                .font(Trace.Fonts.title)
                .foregroundStyle(Trace.Colors.text)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)
            let place = CaseCard.placeLine(DossierFacts(file: caseFile))
            if !place.isEmpty {
                Text(place)
                    .font(Trace.Fonts.callout)
                    .foregroundStyle(Trace.Colors.text2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    /// Who, the statement (Newsreader), the place and the window.
    @ViewBuilder
    private var claimCard: some View {
        if let claim = caseFile.claim {
            VStack(alignment: .leading, spacing: 0) {
                SectionHeader(title: L10n.t("alibi.claimLabel"))
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 12) {
                        PortraitOrInitials(image: nil, initials: person?.initials ?? "?", width: 40, height: 40)
                            .clipShape(Circle())
                            .accessibilityHidden(true)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(person?.name ?? "")
                                .font(Trace.Fonts.headline)
                                .foregroundStyle(Trace.Colors.text)
                            Text(L10n.t("alibi.personLabel"))
                                .font(Trace.Fonts.caption)
                                .foregroundStyle(Trace.Colors.text2)
                        }
                    }
                    Text(claim.statement)
                        .font(Trace.Fonts.quote)
                        .foregroundStyle(Trace.Colors.text)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityIdentifier("alibi.claim")
                    VStack(spacing: 0) {
                        FieldRow(label: L10n.t("alibi.placeLabel"), value: claim.place)
                        FieldRow(label: L10n.t("alibi.windowLabel"), value: AlibiText.window(claim), divider: false)
                    }
                }
                .padding(.vertical, 16)
                .padding(.leading, 19)
                .padding(.trailing, 16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .missionCard()
            }
        }
    }

    private var mission: some View {
        VStack(alignment: .leading, spacing: 0) {
            SectionHeader(title: L10n.t("briefing.mission"))
            Text(caseFile.objective)
                .font(Trace.Fonts.body)
                .foregroundStyle(Trace.Colors.text)
                .fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityElement(children: .combine)
    }

    private var context: some View {
        VStack(alignment: .leading, spacing: 0) {
            SectionHeader(title: L10n.t("dossier.tab.context"))
            VStack(alignment: .leading, spacing: 10) {
                ForEach(Array(caseFile.synopsis.enumerated()), id: \.offset) { _, line in
                    Text(line)
                        .font(Trace.Fonts.body)
                        .foregroundStyle(Trace.Colors.text2)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    /// How to play, in three short lines (the first ALIBI explains itself).
    private var howTo: some View {
        VStack(alignment: .leading, spacing: 0) {
            SectionHeader(title: L10n.t("dossier.how"))
            VStack(alignment: .leading, spacing: 10) {
                ForEach(1...3, id: \.self) { step in
                    HStack(alignment: .firstTextBaseline, spacing: 10) {
                        Text(verbatim: "0\(step)")
                            .font(Trace.Fonts.data)
                            .foregroundStyle(Trace.Colors.benText)
                        Text(L10n.t("alibi.how\(step)"))
                            .font(Trace.Fonts.callout)
                            .foregroundStyle(Trace.Colors.text)
                            .fixedSize(horizontal: false, vertical: true)
                    }
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
            .buttonStyle(CTAButtonStyle())
            Text(L10n.f("alibi.time", PhoneFormat.countdown(Double(durationSeconds))))
                .font(Trace.Fonts.caption)
                .foregroundStyle(Trace.Colors.text2)
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 10)
        .background(Trace.Colors.bg.ignoresSafeArea(edges: .bottom))
        .overlay(alignment: .top) { Rectangle().fill(Trace.Colors.line).frame(height: 1) }
    }
}

// MARK: - Verdict

/// « Son alibi est-il fiable ? » on `bgDeep`: the statement, the player's own tally from the Carnet,
/// two answers (selected: 2 pt ben rule + ✓, the other at 55 %), then the hold (1.6 s). VoiceOver:
/// a double tap asks for confirmation.
struct AlibiVerdictView: View {
    let session: GameSession
    @State private var choice: Bool?
    @State private var concluded = false
    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        let game = session.game
        let timeUp = session.remainingSeconds <= 0
        let person = session.caseFile.suspects.first
        let linked = person.map { game.linkedEntries(for: $0.id) } ?? []
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HStack(alignment: .firstTextBaseline) {
                    Text(fileLabel(session.caseFile.number) + " · " + L10n.t("alibi.verdict"))
                        .font(Trace.Fonts.data)
                        .foregroundStyle(Trace.Colors.benText)
                    Spacer(minLength: 8)
                    if timeUp {
                        Text(L10n.t("accuse.timeUp"))
                            .font(Trace.Fonts.caption)
                            .foregroundStyle(Trace.Colors.warning)
                            .accessibilityIdentifier("accuse.timeUp")
                    }
                }
                Text(L10n.t("alibi.question"))
                    .font(Trace.Fonts.display)
                    .foregroundStyle(Trace.Colors.text)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityAddTraits(.isHeader)
                    .accessibilityIdentifier("alibi.question")
                if let claim = session.caseFile.claim {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(game.name(of: claim.person))
                            .font(Trace.Fonts.headline)
                            .foregroundStyle(Trace.Colors.text)
                        Text(claim.statement)
                            .font(Trace.Fonts.quote)
                            .foregroundStyle(Trace.Colors.text)
                            .fixedSize(horizontal: false, vertical: true)
                        Text(claim.place + " · " + AlibiText.window(claim))
                            .font(Trace.Fonts.caption)
                            .foregroundStyle(Trace.Colors.text2)
                            .fixedSize(horizontal: false, vertical: true)
                        Text(verbatim: "↑ \(linked.filter { $0.stance == .incriminates }.count) " + L10n.t("alibi.tallyContradicts")
                             + "   ↓ \(linked.filter { $0.stance == .clears }.count) " + L10n.t("alibi.tallyConfirms"))
                            .font(Trace.Fonts.data)
                            .foregroundStyle(Trace.Colors.text2)
                            .padding(.top, 2)
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .benCard()
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
        .background(Trace.Colors.bgDeep.ignoresSafeArea())
    }

    /// [ALIBI CONFIRMÉ] / [ALIBI CONTREDIT]: a selectable card.
    private func answer(_ holds: Bool) -> some View {
        let chosen = choice == holds
        let shape = RoundedRectangle(cornerRadius: Trace.Radius.card, style: .continuous)
        return Button {
            guard choice != holds else { return }
            withAnimation(.easeOut(duration: 0.2)) { choice = holds }
            Haptics.selection()
        } label: {
            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    AlibiText.badge(holds)
                    Text(L10n.t(holds ? "alibi.confirmedHelp" : "alibi.contradictedHelp"))
                        .font(Trace.Fonts.callout)
                        .foregroundStyle(Trace.Colors.text2)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 4)
                ZStack {
                    Circle().fill(chosen ? Trace.Colors.ben : Color.clear)
                    Circle().strokeBorder(chosen ? Trace.Colors.ben : Trace.Colors.text3, lineWidth: 1.5)
                    if chosen {
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(Trace.Colors.onFill)
                    }
                }
                .frame(width: 26, height: 26)
                .accessibilityHidden(true)
            }
            .padding(16)
            .frame(maxWidth: .infinity, minHeight: 64, alignment: .leading)
            .benCard()
            .overlay(shape.strokeBorder(Trace.Colors.ben, lineWidth: chosen ? 2 : 0))
            .contentShape(shape)
        }
        .buttonStyle(PressableStyle())
        .opacity(choice == nil || chosen ? 1 : 0.55)
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
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 10)
        .background(Trace.Colors.bgDeep.ignoresSafeArea(edges: .bottom))
    }

    private func conclude() {
        guard let choice, !concluded else { return }
        concluded = true
        session.concludeAlibi(holds: choice)
    }
}

// MARK: - Result

/// The verification (1.8 s), then a one-page report: the verdict badge (right / wrong), the
/// player's answer and — when right, or on request — the real one (ALIBI CONFIRMÉ / CONTREDIT as
/// StatusBadges), what really happened, the key pieces found ✓ / missed ○, the data. Wrong:
/// [Reprendre la vérification], « Voir la réponse », « Classer quand même ».
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
    @Environment(\.dynamicTypeSize) private var typeSize

    private var solved: Bool { verdict.isCorrect }
    private var open: Bool { solved || revealed }
    private var answer: Bool { verdict.alibiAnswer ?? false }

    var body: some View {
        ZStack {
            Trace.Colors.bg.ignoresSafeArea()
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

    private var columns: [GridItem] {
        typeSize.isAccessibilitySize ? [GridItem(.flexible())] : [GridItem(.flexible(), spacing: 12), GridItem(.flexible())]
    }

    private var report: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                StatusBadge(text: L10n.t(solved ? "alibi.result.right" : "alibi.result.wrong"),
                            color: solved ? Trace.Colors.successText : Trace.Colors.criticalOnDark,
                            symbol: solved ? "✓" : "✕")
                    .accessibilityIdentifier("result.read")
                VStack(alignment: .leading, spacing: 6) {
                    Text(fileLabel(caseFile.number) + " · " + L10n.t("alibi.report"))
                        .font(Trace.Fonts.data)
                        .foregroundStyle(Trace.Colors.benText)
                    Text(caseFile.title.capitalizedFirst)
                        .font(Trace.Fonts.title)
                        .foregroundStyle(Trace.Colors.text)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityAddTraits(.isHeader)
                }
                answers
                if open {
                    VStack(alignment: .leading, spacing: 10) {
                        Text(caseFile.solution.headline)
                            .font(Trace.Fonts.headline)
                            .foregroundStyle(Trace.Colors.text)
                            .fixedSize(horizontal: false, vertical: true)
                        Text(caseFile.solution.summary)
                            .font(Trace.Fonts.body)
                            .foregroundStyle(Trace.Colors.text2)
                            .fixedSize(horizontal: false, vertical: true)
                        RevealTimeline(steps: caseFile.solution.reveal, found: verdict.foundEvidenceIDs,
                                       shown: caseFile.solution.reveal.count)
                            .padding(.top, 6)
                    }
                } else {
                    VStack(alignment: .leading, spacing: 10) {
                        Text(L10n.t("alibi.wrong"))
                            .font(Trace.Fonts.body)
                            .foregroundStyle(Trace.Colors.text2)
                            .fixedSize(horizontal: false, vertical: true)
                        if let trap = caseFile.suspects.first?.trap {
                            SectionHeader(title: L10n.t("result.trap"))
                            Text(trap)
                                .font(Trace.Fonts.callout)
                                .foregroundStyle(Trace.Colors.text)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
                keyPieces
                LazyVGrid(columns: columns, alignment: .leading, spacing: 12) {
                    ReportCard(label: L10n.t("result.colHints"), value: "\(verdict.hintsUsed)")
                    ReportCard(label: L10n.t("result.colMark"), value: "\(verdict.score)/100")
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 20)
            .frame(maxWidth: .infinity, alignment: .leading)
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
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 10)
            .background(Trace.Colors.bg.ignoresSafeArea(edges: .bottom))
            .overlay(alignment: .top) { Rectangle().fill(Trace.Colors.line).frame(height: 1) }
        }
    }

    /// « Votre verdict » and, once open, « La réponse ».
    private var answers: some View {
        VStack(alignment: .leading, spacing: 0) {
            answerRow(L10n.t("alibi.yourAnswer"), holds: answer, divider: open && caseFile.solution.alibiHolds != nil)
            if open, let holds = caseFile.solution.alibiHolds {
                answerRow(L10n.t("alibi.rightAnswer"), holds: holds, divider: false)
            }
        }
        .benCard()
    }

    private func answerRow(_ label: String, holds: Bool, divider: Bool) -> some View {
        HStack(alignment: .center, spacing: 12) {
            Text(label)
                .font(Trace.Fonts.callout)
                .foregroundStyle(Trace.Colors.text2)
            Spacer(minLength: 8)
            AlibiText.badge(holds)
        }
        .padding(.horizontal, 16)
        .frame(minHeight: Trace.Height.row)
        .overlay(alignment: .bottom) {
            if divider { Rectangle().fill(Trace.Colors.line).frame(height: 1).padding(.leading, 16) }
        }
        .accessibilityElement(children: .combine)
    }

    /// Key pieces found ✓ / missed ○ (missed ones stay unnamed until the answer is open).
    private var keyPieces: some View {
        VStack(alignment: .leading, spacing: 0) {
            SectionHeader(title: L10n.f("alibi.piecesFound", verdict.foundCount, verdict.totalCount))
            VStack(alignment: .leading, spacing: 8) {
                ForEach(caseFile.evidence.filter { $0.importance == .key }) { evidence in
                    let found = verdict.foundEvidenceIDs.contains(evidence.id)
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text(verbatim: found ? "✓" : "○")
                            .foregroundStyle(found ? Trace.Colors.successText : Trace.Colors.text2)
                        Text(found || open ? evidence.title : L10n.t("result.keyHiddenGeneric"))
                            .foregroundStyle(Trace.Colors.text)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .font(Trace.Fonts.callout)
                    .accessibilityElement(children: .combine)
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .benCard()
        }
    }
}
#endif
