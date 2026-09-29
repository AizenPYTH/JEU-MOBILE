#if os(iOS)
import SwiftUI
import UIKit
import CaseEngine

// The end of a case (UX V3 §6-10 → §6-12): « Qui est responsable ? » and the hold to conclude (10),
// the verification (11), the closing report (12). Flat BEN surfaces: no paper, no stamp, no
// rotation. The assignment after #001 is in AssignmentView.swift.

// MARK: - 10 · Conclusion

/// « Qui est responsable ? » on `bgDeep`: one ConclusionCard per suspect (2 columns, 1 at
/// accessibility sizes), then « Maintenir : {Prénom} est responsable » (1.6 s). Shown when the
/// player concludes from the Carnet, or forced when the timer hits 00:00 (« Temps écoulé », no way
/// back). VoiceOver / Switch Control: a double tap asks « {Prénom} est responsable ? ».
struct AccusationView: View {
    let session: GameSession
    @State private var selected: SuspectID?
    @State private var concluded = false
    @Environment(\.dynamicTypeSize) private var typeSize
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    @AppStorage(Preferences.reduceMotionKey) private var appReduceMotion = false

    private var reduced: Bool { systemReduceMotion || appReduceMotion }

    var body: some View {
        let timeUp = session.remainingSeconds <= 0
        ScrollView {
            VStack(alignment: .leading, spacing: Trace.Spacing.xxl) {
                header
                LazyVGrid(columns: columns, alignment: .leading, spacing: Trace.Spacing.m) {
                    ForEach(session.caseFile.suspects) { suspect in
                        card(suspect)
                    }
                }
            }
            .padding(.horizontal, Trace.Spacing.l)
            .padding(.top, Trace.Spacing.s)
            .padding(.bottom, Trace.Spacing.xxl)
        }
        .scrollBounceBehavior(.basedOnSize)
        .safeAreaInset(edge: .top, spacing: 0) { topBar(timeUp: timeUp) }
        .safeAreaInset(edge: .bottom, spacing: 0) { footer }
        .background(Trace.Colors.bgDeep.ignoresSafeArea())
    }

    /// Two columns; one at accessibility text sizes (§3 Dynamic Type).
    private var columns: [GridItem] {
        typeSize.isAccessibilitySize
            ? [GridItem(.flexible(), spacing: Trace.Spacing.m)]
            : [GridItem(.flexible(), spacing: Trace.Spacing.m), GridItem(.flexible(), spacing: Trace.Spacing.m)]
    }

    // MARK: Top

    /// « ‹ Carnet » while time remains; « Temps écoulé » (warning) once the timer is out.
    private func topBar(timeUp: Bool) -> some View {
        HStack(spacing: Trace.Spacing.s) {
            if timeUp {
                StatusBadge(text: L10n.t("accuse.timeUp"), color: Trace.Colors.warning, symbol: "◐")
                    .accessibilityIdentifier("accuse.timeUp")
            } else {
                BackLink(title: L10n.t("carnet.title"), identifier: "accuse.back") {
                    session.resumeInvestigation()
                }
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, Trace.Spacing.l)
        .frame(minHeight: Trace.Height.hit)
        .background(Trace.Colors.bgDeep.ignoresSafeArea(edges: .top))
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: Trace.Spacing.s) {
            Text(L10n.f("accuse.kicker", shownNumber(session.caseFile.number)))
                .font(Trace.Fonts.data)
                .foregroundStyle(Trace.Colors.benText)
                .fixedSize(horizontal: false, vertical: true)
            Text(L10n.t("accuse.title"))
                .font(Trace.Fonts.display)
                .foregroundStyle(Trace.Colors.text)
                .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)
                .accessibilityIdentifier("accuse.title")
        }
    }

    // MARK: ConclusionCard (§5)

    /// A large photo, the name (headline) and the relation (caption). Selected: 2 pt ben border and
    /// a 26 pt check; the others fade to 55 %.
    private func card(_ suspect: Suspect) -> some View {
        let game = session.game
        let isSelected = selected == suspect.id
        let contact = game.contact(suspect.contact)
        let name = game.name(of: suspect.contact)
        let photo = ConclusionPrint(image: ArtLibrary.portrait(case: session.caseFile.number, contact: contact),
                                    initials: contact?.initials ?? IDPhoto.initials(of: name))
        let shape = RoundedRectangle(cornerRadius: Trace.Radius.card, style: .continuous)
        return Button {
            choose(suspect.id)
        } label: {
            Group {
                if typeSize.isAccessibilitySize {
                    HStack(alignment: .center, spacing: Trace.Spacing.m) {
                        photo.frame(width: ConclusionPrint.rowWidth)
                        identity(name: name, relation: suspect.role)
                        Spacer(minLength: 0)
                    }
                } else {
                    VStack(alignment: .leading, spacing: Trace.Spacing.m) {
                        photo
                        identity(name: name, relation: suspect.role)
                    }
                }
            }
            .padding(Trace.Spacing.m)
            .frame(maxWidth: .infinity, alignment: .leading)
            .benCard()
            .overlay(shape.strokeBorder(Trace.Colors.ben, lineWidth: 2).opacity(isSelected ? 1 : 0))
            .overlay(alignment: .topTrailing) {
                if isSelected {
                    SelectionCheck()
                        .padding(Trace.Spacing.s)
                        .transition(.opacity)
                }
            }
            .contentShape(shape)
        }
        .buttonStyle(PressableStyle())
        .opacity(selected == nil || isSelected ? 1 : 0.55)
        .accessibilityLabel(Text(name))
        .accessibilityValue(Text(suspect.role))
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityIdentifier("accuse.suspect.\(suspect.id)")
    }

    private func identity(name: String, relation: String) -> some View {
        VStack(alignment: .leading, spacing: Trace.Spacing.xs) {
            Text(name)
                .font(Trace.Fonts.headline)
                .foregroundStyle(Trace.Colors.text)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
            Text(relation)
                .font(Trace.Fonts.caption)
                .foregroundStyle(Trace.Colors.text2)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: Hold

    /// The hold (1.6 s), disabled with « Choisissez un suspect » until a card is chosen.
    private var footer: some View {
        BenHoldButton(title: selected == nil ? L10n.t("accuse.choose") : L10n.f("accuse.holdFor", selectedFirstName),
                      seconds: Trace.Motion.holdToClose,
                      enabled: selected != nil,
                      identifier: "accuse.hold",
                      accessibilityConfirm: selected == nil ? nil : L10n.f("accuse.confirmFor", selectedFirstName),
                      action: conclude)
            .padding(.horizontal, Trace.Spacing.l)
            .padding(.top, Trace.Spacing.m)
            .padding(.bottom, Trace.Spacing.s)
            .background(Trace.Colors.bgDeep.ignoresSafeArea(edges: .bottom))
            .overlay(alignment: .top) { Rectangle().fill(Trace.Colors.line).frame(height: 1) }
    }

    /// « Emma » for « Emma Roussel ».
    private var selectedFirstName: String {
        guard let selected, let suspect = session.game.index.suspect(selected) else { return "" }
        let full = session.game.name(of: suspect.contact)
        return full.split(separator: " ").first.map(String.init) ?? full
    }

    private func choose(_ id: SuspectID) {
        guard selected != id, !concluded else { return }
        withAnimation(reduced ? .easeInOut(duration: 0.2) : .easeOut(duration: 0.2)) { selected = id }
        Haptics.selection()
    }

    private func conclude() {
        guard let selected, !concluded else { return }
        concluded = true
        session.accuse(selected)
    }
}

/// A suspect sheet opened from a list (the case file's suspects).
struct SuspectSheetID: Identifiable {
    let id: SuspectID
}

/// The 26 pt check of a selected card: a ben disc with a white tick.
private struct SelectionCheck: View {
    private static let size: CGFloat = 26

    var body: some View {
        Image(systemName: "checkmark")
            .font(Trace.Fonts.section)
            .fontWeight(.bold)
            .foregroundStyle(Trace.Colors.onFill)
            .frame(width: Self.size, height: Self.size)
            .background(Circle().fill(Trace.Colors.ben))
            .accessibilityHidden(true)
    }
}

/// Hold to confirm with separate VoiceOver activation (used by the ALIBI verdict): the V3 hold
/// (§5 ActionButton « maintien »): `surface2`, filled in `ben` from left to right while held
/// (linear, 1.6 s); released early, it empties in 250 ms and nothing is sent. Light haptic at the
/// start, rigid at the end. Assistive technologies: the default action calls `onActivate` (the
/// caller confirms), the named action `actionName` concludes directly.
struct ConclusionHoldButton: View {
    let title: String
    let enabled: Bool
    let actionName: String
    let onActivate: () -> Void
    let onComplete: () -> Void

    @State private var progress: CGFloat = 0
    @State private var done = false

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: Trace.Radius.button, style: .continuous)
        Text(title)
            .font(Trace.Fonts.cta)
            .multilineTextAlignment(.center)
            .lineLimit(2)
            .minimumScaleFactor(0.8)
            .foregroundStyle(enabled ? Trace.Colors.text : Trace.Colors.text3)
            .padding(.horizontal, Trace.Spacing.l)
            .frame(maxWidth: .infinity, minHeight: Trace.Height.hold)
            .background(alignment: .leading) {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Trace.Colors.surface2
                        Trace.Colors.ben.frame(width: geo.size.width * progress)
                    }
                }
            }
            .clipShape(shape)
            .contentShape(shape)
            .onLongPressGesture(minimumDuration: Trace.Motion.holdToClose, maximumDistance: 40) {
                guard enabled, !done else { return }
                done = true
                Haptics.rigid()
                onComplete()
            } onPressingChanged: { pressing in
                guard enabled, !done else { return }
                if pressing {
                    Haptics.light()
                    withAnimation(.linear(duration: Trace.Motion.holdToClose)) { progress = 1 }
                } else {
                    withAnimation(.easeOut(duration: 0.25)) { progress = 0 }
                }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text(title))
            .accessibilityHint(Text(L10n.t("a11y.holdHint")))
            .accessibilityAddTraits(.isButton)
            .accessibilityAction { if enabled { onActivate() } }
            .accessibilityAction(named: Text(actionName)) {
                guard enabled, !done else { return }
                done = true
                onComplete()
            }
    }
}

/// A suspect's photo (square by default, rounded 12 pt): the case portrait, or the initials on
/// `surface3`. Never a drawn face.
private struct ConclusionPrint: View {
    let image: UIImage?
    let initials: String
    var ratio: CGFloat = 1

    /// Width of the photo when the card is a row (accessibility sizes, the report).
    static let rowWidth: CGFloat = 72

    var body: some View {
        Color.clear
            .aspectRatio(ratio, contentMode: .fit)
            .overlay {
                GeometryReader { geo in
                    PortraitOrInitials(image: image, initials: initials, width: geo.size.width, height: geo.size.height)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: Trace.Radius.node, style: .continuous))
            .accessibilityHidden(true)
    }
}

// MARK: - 11 · Verification

/// « VÉRIFICATION DU DOSSIER… » (Mono 14) on `bgDeep`, 1.8 s, not interruptible: three lines appear
/// every 0.5 s (fade + 6 pt rise) — the designation, the decisive pieces n/N, the connections —
/// over a 2 pt progress bar; then `onRead` (the caller cross-fades to the report). No typing, no
/// stamp, no sound. Reduced motion: the lines only fade.
struct VerificationView: View {
    let caseNumber: Int
    let caseTitle: String
    /// First line: « Suspect désigné · … » / « Votre verdict : … ».
    let designation: String
    let solved: Bool
    /// Key evidence found / total (the line is hidden when the total is 0).
    var decisiveFound: Int = 0
    var decisiveTotal: Int = 0
    /// Connections the player made in the Carnet.
    var connections: Int = 0
    /// Called once the verification is over (1.8 s).
    let onRead: () -> Void

    @State private var shown = 0
    @State private var progress: CGFloat = 0
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    @AppStorage(Preferences.reduceMotionKey) private var appReduceMotion = false

    /// One line every 0.5 s.
    private static let lineInterval = 0.5

    private var still: Bool { systemReduceMotion || appReduceMotion }

    private var lines: [String] {
        var result = [designation]
        if decisiveTotal > 0 { result.append(L10n.f("verify.decisive", decisiveFound, decisiveTotal)) }
        result.append(L10n.f("verify.connections", connections))
        return result
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer(minLength: Trace.Spacing.xxl)
            Text(fileLabel(caseNumber))
                .font(Trace.Fonts.data)
                .foregroundStyle(Trace.Colors.benText)
                .accessibilityLabel(Text(fileLabel(caseNumber) + ", " + caseTitle))
            Text(L10n.t("verdict.checking"))
                .font(Trace.Fonts.fieldValueLarge)
                .foregroundStyle(Trace.Colors.text)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, Trace.Spacing.s)
                .accessibilityAddTraits(.isHeader)
            VStack(alignment: .leading, spacing: Trace.Spacing.m) {
                ForEach(Array(lines.enumerated()), id: \.offset) { index, line in
                    let visible = index < shown
                    Text(line)
                        .font(Trace.Fonts.callout)
                        .foregroundStyle(Trace.Colors.text2)
                        .fixedSize(horizontal: false, vertical: true)
                        .opacity(visible ? 1 : 0)
                        .offset(y: visible || still ? 0 : 6)
                        .accessibilityHidden(!visible)
                }
            }
            .padding(.top, Trace.Spacing.xxl)
            Rectangle()
                .fill(Trace.Colors.surface2)
                .frame(height: 2)
                .overlay(alignment: .leading) {
                    Rectangle()
                        .fill(Trace.Colors.ben)
                        .scaleEffect(x: progress, y: 1, anchor: .leading)
                }
                .clipShape(Capsule())
                .padding(.top, Trace.Spacing.xxl + Trace.Spacing.xs)
                .accessibilityHidden(true)
            Spacer(minLength: Trace.Spacing.xxl)
        }
        .padding(.horizontal, Trace.Spacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background(Trace.Colors.bgDeep.ignoresSafeArea())
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("verify.view")
        .task { await run() }
    }

    private func run() async {
        let total = Trace.Motion.verification
        withAnimation(.linear(duration: total)) { progress = 1 }
        let appear: Animation = still ? .easeInOut(duration: 0.2) : .easeOut(duration: 0.3)
        let count = lines.count
        for index in 1...count {
            try? await Task.sleep(for: .seconds(Self.lineInterval))
            guard !Task.isCancelled else { return }
            withAnimation(appear) { shown = index }
        }
        let rest = max(0.1, total - Self.lineInterval * Double(count))
        try? await Task.sleep(for: .seconds(rest))
        guard !Task.isCancelled else { return }
        onRead()
    }
}

// MARK: - 12 · Closing report

/// The verification (11), then the closing report (12): the verdict badge, #001 + title, the
/// RESPONSABLE card, a short explanation from the case, six ReportCards, the missed pieces on
/// demand (with their app) and the reconstruction on demand. Not solved: the culprit stays hidden
/// until « Consulter la solution » (confirmed; the attempt then stops counting and can only be
/// filed). Footer: solved → [Classer le dossier]; not solved → [Reprendre l'enquête] (the handoff's
/// « Rejouer »: timer full, pieces kept) + « Classer ». Re-created with `revealed` once the
/// solution is requested.
struct ResultView: View {
    let verdict: Verdict
    let caseFile: CaseFile
    let names: [SuspectID: String]
    let revealed: Bool
    let relaxed: Bool
    let culprit: Contact?
    let accused: Contact?
    let onFile: () -> Void
    let onRetry: () -> Void
    let onFileAnyway: () -> Void
    let onRevealRequested: () -> Void
    /// Connections made in the Carnet (`session.game.connections.count`).
    var connections: Int = 0

    /// The verification is over: the report is on screen.
    @State private var reading = false
    /// « Consulter la solution ? » is on screen; `revealAsked` once confirmed (acted on when it closes).
    @State private var askingReveal = false
    @State private var revealAsked = false
    @State private var showMissed = false
    @State private var showTimeline = false
    @Environment(\.dynamicTypeSize) private var typeSize
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    @AppStorage(Preferences.reduceMotionKey) private var appReduceMotion = false

    private var reduced: Bool { systemReduceMotion || appReduceMotion }
    private var solved: Bool { verdict.isCorrect }
    /// The solution may be shown: solved, or explicitly requested.
    private var open: Bool { verdict.isCorrect || revealed }
    private var accusedName: String { accused?.name ?? names[verdict.accused] ?? "" }
    private var culpritName: String { culprit?.name ?? names[verdict.culprit] ?? "" }
    private var keyEvidence: [Evidence] { caseFile.evidence.filter { $0.importance == .key } }
    private var fade: Animation { reduced ? .easeInOut(duration: 0.2) : .easeInOut(duration: 0.3) }

    var body: some View {
        ZStack {
            Trace.Colors.bgDeep.ignoresSafeArea()
            if reading || revealed {
                report
                    .transition(.opacity)
            } else {
                VerificationView(caseNumber: caseFile.number, caseTitle: caseFile.title,
                                 designation: L10n.f("verify.designated", accusedName), solved: solved,
                                 decisiveFound: keyEvidence.filter { verdict.foundEvidenceIDs.contains($0.id) }.count,
                                 decisiveTotal: keyEvidence.count,
                                 connections: connections) {
                    withAnimation(reduced ? .easeInOut(duration: 0.2) : .easeInOut(duration: 0.35)) { reading = true }
                }
                .transition(.opacity)
            }
        }
    }

    private var report: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Trace.Spacing.xxl) {
                reportHeader
                responsibleCard
                explanation
                statsGrid
                missedSection
                timelineSection
                if relaxed {
                    Text(L10n.t("result.relaxed"))
                        .font(Trace.Fonts.caption)
                        .foregroundStyle(Trace.Colors.text2)
                }
            }
            .padding(.horizontal, Trace.Spacing.l)
            .padding(.top, Trace.Spacing.xl)
            .padding(.bottom, Trace.Spacing.xxl)
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("result.report")
        }
        .scrollBounceBehavior(.basedOnSize)
        .safeAreaInset(edge: .bottom, spacing: 0) { actions }
        .background(Trace.Colors.bg.ignoresSafeArea())
        .onAppear { if revealed && !solved { showTimeline = true } }
        .sheet(isPresented: $askingReveal, onDismiss: {
            if revealAsked { revealAsked = false; onRevealRequested() }
        }) {
            PaperConfirmSheet(title: L10n.t("result.revealAskTitle"),
                              message: L10n.t("result.revealAskMessage"),
                              confirm: L10n.t("result.revealAskConfirm"),
                              confirmID: "result.revealConfirm",
                              cancel: L10n.t("result.revealAskCancel"),
                              cancelID: "result.revealCancel",
                              onConfirm: { revealAsked = true; askingReveal = false },
                              onCancel: { askingReveal = false })
                .presentationDetents([.medium])
                .presentationCornerRadius(Trace.Radius.sheet)
                .presentationBackground(Trace.Colors.surface)
        }
    }

    // MARK: Header

    /// « ✓ Affaire résolue » / « ✕ Affaire non résolue », then « #001 » and the title.
    private var reportHeader: some View {
        VStack(alignment: .leading, spacing: Trace.Spacing.m) {
            ViewThatFits(in: .horizontal) {
                HStack(spacing: Trace.Spacing.s) { badges }
                VStack(alignment: .leading, spacing: Trace.Spacing.s) { badges }
            }
            VStack(alignment: .leading, spacing: Trace.Spacing.xs) {
                Text(verbatim: "#" + shownNumber(caseFile.number))
                    .font(Trace.Fonts.data)
                    .foregroundStyle(Trace.Colors.benText)
                Text(caseFile.title.capitalizedFirst)
                    .font(Trace.Fonts.title)
                    .foregroundStyle(Trace.Colors.text)
                    .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityAddTraits(.isHeader)
            }
        }
    }

    @ViewBuilder
    private var badges: some View {
        StatusBadge(text: solved ? L10n.t("result.solvedBadge") : L10n.t("result.unsolvedBadge"),
                    color: solved ? Trace.Colors.successText : Trace.Colors.criticalOnDark,
                    symbol: solved ? "✓" : "✕")
            // The former « Lire le rapport » identifier, kept for the UI tests (the report now
            // follows the verification by itself).
            .accessibilityIdentifier("result.read")
        if revealed && !solved {
            StatusBadge(text: L10n.t("result.revealedBadge"), color: Trace.Colors.text2, symbol: "●")
        }
    }

    // MARK: Responsible

    /// RESPONSABLE: the real culprit when the solution is open; not solved, « Vous avez accusé : X »
    /// and the way to the solution.
    private var responsibleCard: some View {
        VStack(alignment: .leading, spacing: Trace.Spacing.m) {
            SectionHeader(title: L10n.t("result.responsible"))
                .padding(.bottom, -Trace.Spacing.xs)
            if open {
                HStack(alignment: .center, spacing: Trace.Spacing.l) {
                    ConclusionPrint(image: ArtLibrary.portrait(case: caseFile.number, contact: culprit),
                                    initials: culprit?.initials ?? IDPhoto.initials(of: culpritName),
                                    ratio: 0.8)
                        .frame(width: ConclusionPrint.rowWidth)
                    VStack(alignment: .leading, spacing: Trace.Spacing.xs) {
                        Text(culpritName)
                            .font(Trace.Fonts.headline)
                            .foregroundStyle(Trace.Colors.text)
                            .fixedSize(horizontal: false, vertical: true)
                        if let role = caseFile.suspects.first(where: { $0.id == verdict.culprit })?.role {
                            Text(role)
                                .font(Trace.Fonts.caption)
                                .foregroundStyle(Trace.Colors.text2)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    Spacer(minLength: 0)
                }
                .accessibilityElement(children: .combine)
            } else {
                VStack(alignment: .leading, spacing: Trace.Spacing.xs) {
                    Text(L10n.t("result.responsibleHidden"))
                        .font(Trace.Fonts.headline)
                        .foregroundStyle(Trace.Colors.text2)
                    Text(L10n.t("result.responsibleHiddenTip"))
                        .font(Trace.Fonts.caption)
                        .foregroundStyle(Trace.Colors.text2)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .accessibilityElement(children: .combine)
            }
            if !solved {
                Rectangle().fill(Trace.Colors.line).frame(height: 1)
                Text(L10n.f("result.youAccused", accusedName))
                    .font(Trace.Fonts.callout)
                    .foregroundStyle(Trace.Colors.text)
                    .fixedSize(horizontal: false, vertical: true)
            }
            if !open {
                Button(L10n.t("result.reveal")) { askingReveal = true }
                    .buttonStyle(TextLinkStyle())
                    .accessibilityIdentifier("result.reveal")
            }
        }
        .padding(Trace.Spacing.l)
        .frame(maxWidth: .infinity, alignment: .leading)
        .benCard()
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("result.responsible")
    }

    // MARK: Explanation

    /// Open: the case's headline and summary. Not solved: why it was not the accused (their alibi,
    /// or the trap), and what the player got right about them — never the culprit.
    @ViewBuilder
    private var explanation: some View {
        VStack(alignment: .leading, spacing: Trace.Spacing.s) {
            SectionHeader(title: open ? L10n.t("result.whatHappened") : L10n.t("result.notSeen"))
                .padding(.bottom, -Trace.Spacing.xs)
            if open {
                Text(caseFile.solution.headline)
                    .font(Trace.Fonts.headline)
                    .foregroundStyle(Trace.Colors.text)
                    .fixedSize(horizontal: false, vertical: true)
                Text(caseFile.solution.summary)
                    .font(Trace.Fonts.body)
                    .foregroundStyle(Trace.Colors.text2)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                Text(L10n.f("result.wrongTitle", accusedName))
                    .font(Trace.Fonts.headline)
                    .foregroundStyle(Trace.Colors.text)
                    .fixedSize(horizontal: false, vertical: true)
                if let reason = verdict.alibi ?? verdict.trap {
                    Text(reason)
                        .font(Trace.Fonts.body)
                        .foregroundStyle(Trace.Colors.text2)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .accessibilityElement(children: .contain)
        if !open && !verdict.foundAboutAccused.isEmpty {
            VStack(alignment: .leading, spacing: Trace.Spacing.s) {
                SectionHeader(title: L10n.t("result.rightFinds"))
                    .padding(.bottom, -Trace.Spacing.xs)
                ForEach(verdict.foundAboutAccused) { evidence in
                    HStack(alignment: .firstTextBaseline, spacing: Trace.Spacing.m) {
                        Text(verbatim: "✓")
                            .font(Trace.Fonts.callout)
                            .foregroundStyle(Trace.Colors.benText)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(evidence.title)
                                .font(Trace.Fonts.callout)
                                .foregroundStyle(Trace.Colors.text)
                                .fixedSize(horizontal: false, vertical: true)
                            if !evidence.suspects.contains(verdict.culprit) {
                                Text(evidence.meaning)
                                    .font(Trace.Fonts.caption)
                                    .foregroundStyle(Trace.Colors.text2)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                    .accessibilityElement(children: .combine)
                }
            }
        }
    }

    // MARK: Figures

    /// Six ReportCards (2 columns; 1 at accessibility sizes).
    private var statsGrid: some View {
        let columns = typeSize.isAccessibilitySize
            ? [GridItem(.flexible(), spacing: Trace.Spacing.m)]
            : [GridItem(.flexible(), spacing: Trace.Spacing.m), GridItem(.flexible(), spacing: Trace.Spacing.m)]
        let missed = verdict.missed.count
        return LazyVGrid(columns: columns, alignment: .leading, spacing: Trace.Spacing.m) {
            ReportCard(label: L10n.t("result.timeLeft"), value: PhoneFormat.countdown(Double(verdict.remainingSeconds)))
            ReportCard(label: L10n.t("result.piecesUsed"), value: "\(verdict.pinnedCount)")
            ReportCard(label: L10n.t("result.cluesFound"), value: "\(verdict.foundCount)/\(verdict.totalCount)")
            ReportCard(label: L10n.t("result.cluesMissed"), value: "\(missed)",
                       color: missed > 0 ? Trace.Colors.warning : Trace.Colors.text)
            ReportCard(label: L10n.t("result.connections"), value: "\(connections)")
            ReportCard(label: L10n.t("result.finalMark"), value: solved ? "\(verdict.score)/100" : "—")
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("result.keyEvidence")
    }

    // MARK: Missed pieces

    /// « Voir les indices manqués (n) » → each missed piece with the app it was in. Not open: the
    /// piece's title stays hidden (it could name the culprit), only its app is given.
    @ViewBuilder
    private var missedSection: some View {
        if !verdict.missed.isEmpty {
            let index = CaseIndex(caseFile)
            VStack(alignment: .leading, spacing: Trace.Spacing.s) {
                Button {
                    withAnimation(fade) { showMissed.toggle() }
                } label: {
                    HStack(spacing: Trace.Spacing.xs) {
                        Text(showMissed ? L10n.t("result.hideMissed") : L10n.f("result.showMissed", verdict.missed.count))
                        Image(systemName: showMissed ? "chevron.up" : "chevron.down")
                            .accessibilityHidden(true)
                    }
                }
                .buttonStyle(TextLinkStyle())
                .accessibilityIdentifier("result.missedLink")
                if showMissed {
                    VStack(spacing: 0) {
                        ForEach(Array(verdict.missed.enumerated()), id: \.element.id) { offset, evidence in
                            missedRow(evidence, index: index, last: offset == verdict.missed.count - 1)
                        }
                    }
                    .padding(.horizontal, Trace.Spacing.l)
                    .benCard()
                    .transition(.opacity)
                    .accessibilityElement(children: .contain)
                    .accessibilityIdentifier("result.missedList")
                }
            }
        }
    }

    private func missedRow(_ evidence: Evidence, index: CaseIndex, last: Bool) -> some View {
        let place = app(of: evidence, index: index)
        return HStack(alignment: .center, spacing: Trace.Spacing.m) {
            Image(systemName: place?.symbol ?? "questionmark.circle")
                .font(Trace.Fonts.callout)
                .foregroundStyle(Trace.Colors.warning)
                .frame(minWidth: Trace.Spacing.xxl)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(open ? evidence.title : L10n.t("result.keyHiddenGeneric"))
                    .font(Trace.Fonts.callout)
                    .foregroundStyle(Trace.Colors.text)
                    .fixedSize(horizontal: false, vertical: true)
                if let place {
                    Text(L10n.f("result.missedIn", place.title))
                        .font(Trace.Fonts.caption)
                        .foregroundStyle(Trace.Colors.text2)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, Trace.Spacing.m)
        .frame(minHeight: Trace.Height.row)
        .overlay(alignment: .bottom) {
            if !last { Rectangle().fill(Trace.Colors.line).frame(height: 1) }
        }
        .accessibilityElement(children: .combine)
    }

    /// The app a piece was in; a deleted message counts as the Trash.
    private func app(of evidence: Evidence, index: CaseIndex) -> AppID? {
        guard let ref = evidence.refs.first else { return nil }
        let deleted = ref.kind == .message && index.message(ref.id)?.deletedAt != nil
        return deleted ? .trash : ref.kind.app
    }

    // MARK: Reconstruction

    /// The reconstruction on demand, once the solution is open (unfolded after a request).
    @ViewBuilder
    private var timelineSection: some View {
        if open && !caseFile.solution.reveal.isEmpty {
            VStack(alignment: .leading, spacing: Trace.Spacing.s) {
                Button {
                    withAnimation(fade) { showTimeline.toggle() }
                } label: {
                    HStack(spacing: Trace.Spacing.xs) {
                        Text(showTimeline ? L10n.t("result.hideTimeline") : L10n.t("result.showTimeline"))
                        Image(systemName: showTimeline ? "chevron.up" : "chevron.down")
                            .accessibilityHidden(true)
                    }
                }
                .buttonStyle(TextLinkStyle())
                .accessibilityIdentifier("result.timelineLink")
                if showTimeline {
                    RevealTimeline(steps: caseFile.solution.reveal, found: verdict.foundEvidenceIDs,
                                   shown: caseFile.solution.reveal.count)
                        .padding(Trace.Spacing.l)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .benCard()
                        .transition(.opacity)
                        .accessibilityElement(children: .contain)
                        .accessibilityIdentifier("result.timeline")
                }
            }
        }
    }

    // MARK: Footer

    /// Fixed footer, one full button. Solved (or solution read): [Classer le dossier]. Not solved:
    /// [Reprendre l'enquête] + « Classer » (tertiary).
    private var actions: some View {
        VStack(spacing: Trace.Spacing.s) {
            if solved {
                Button(L10n.t("result.fileCase"), action: onFile)
                    .buttonStyle(CTAButtonStyle())
                    .accessibilityIdentifier("result.file")
            } else if revealed {
                // The solution was read: the case can only be filed (unsolved), not replayed at once.
                Button(L10n.t("result.fileCase"), action: onFileAnyway)
                    .buttonStyle(CTAButtonStyle())
                    .accessibilityIdentifier("result.file")
            } else {
                Button(L10n.t("result.retry"), action: onRetry)
                    .buttonStyle(CTAButtonStyle())
                    .accessibilityHint(Text(L10n.t("result.replayHint")))
                    .accessibilityIdentifier("result.retry")
                Button(L10n.t("result.fileShort"), action: onFileAnyway)
                    .buttonStyle(CTAButtonStyle(kind: .tertiary))
                    .accessibilityIdentifier("result.fileAnyway")
            }
        }
        .padding(.horizontal, Trace.Spacing.l)
        .padding(.top, Trace.Spacing.m)
        .padding(.bottom, Trace.Spacing.s)
        .background(Trace.Colors.bg.ignoresSafeArea(edges: .bottom))
        .overlay(alignment: .top) { Rectangle().fill(Trace.Colors.line).frame(height: 1) }
    }
}

// MARK: - Reconstruction

/// The reconstruction: Plex Mono times (52 pt column), a 10 pt dot and a 2 pt line; found = filled
/// ben dot, missed = hollow dot + « ○ non trouvé » (warning, never colour alone).
struct RevealTimeline: View {
    let steps: [RevealStep]
    let found: Set<String>
    let shown: Int

    private static let timeColumn: CGFloat = 52
    private static let dot: CGFloat = 10

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(steps.enumerated()), id: \.offset) { offset, step in
                let isFound = step.evidence.map { found.contains($0) } ?? true
                let visible = offset < shown
                HStack(alignment: .top, spacing: Trace.Spacing.m) {
                    Text(PhoneFormat.time(step.at))
                        .font(Trace.Fonts.fieldValueLarge)
                        .foregroundStyle(isFound ? Trace.Colors.text : Trace.Colors.text2)
                        .fixedSize()
                        .frame(minWidth: Self.timeColumn, alignment: .leading)
                    VStack(spacing: 0) {
                        Circle()
                            .fill(isFound ? Trace.Colors.ben : Color.clear)
                            .overlay(Circle().strokeBorder(isFound ? Trace.Colors.ben : Trace.Colors.text3, lineWidth: 2))
                            .frame(width: Self.dot, height: Self.dot)
                            .padding(.top, Trace.Spacing.xs)
                        if offset < steps.count - 1 {
                            Rectangle()
                                .fill(Trace.Colors.surface3)
                                .frame(width: 2)
                                .frame(maxHeight: .infinity)
                        }
                    }
                    VStack(alignment: .leading, spacing: Trace.Spacing.xs) {
                        Text(step.text)
                            .font(Trace.Fonts.callout)
                            .foregroundStyle(isFound ? Trace.Colors.text : Trace.Colors.text2)
                            .fixedSize(horizontal: false, vertical: true)
                        if !isFound {
                            Text(verbatim: "○ " + L10n.t("result.notFound"))
                                .font(Trace.Fonts.caption)
                                .foregroundStyle(Trace.Colors.warning)
                        }
                    }
                    .padding(.bottom, Trace.Spacing.l)
                    Spacer(minLength: 0)
                }
                .fixedSize(horizontal: false, vertical: true)
                .opacity(visible ? 1 : 0)
                .offset(y: visible ? 0 : 6)
                .accessibilityElement(children: .combine)
                .accessibilityLabel(Text((isFound ? L10n.t("a11y.found") : L10n.t("a11y.missed")) + ", \(PhoneFormat.time(step.at)), \(step.text)"))
            }
        }
    }
}
#endif
