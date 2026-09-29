#if os(iOS)
import SwiftUI
import UIKit
import CaseEngine

// The end of a case, laid on the desk (handoff V4 §3–§5, docs/design_v4): « Qui est responsable ? »
// with the suspects' prints pinned on the deep desk (09), the verification typed on a blank sheet
// then stamped RÉSOLU / NON RÉSOLU (11), the closing report on paper, filed into its folder (10).
// The behaviour is the V3 one (docs/design_ux_v3 §6-10 → §6-12). The assignment after #001 is in
// AssignmentView.swift.

// MARK: - 09 · Accusation

/// « Qui est responsable ? » on the deep desk: one PinnedSuspect per suspect (2 columns, 1 at
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
                VStack(alignment: .leading, spacing: Trace.Spacing.m) {
                    topLine(timeUp: timeUp)
                    header
                }
                // Rows 28 pt apart: room for the pins above each print and for the lift.
                LazyVGrid(columns: columns, alignment: .leading, spacing: Trace.Spacing.xxl + Trace.Spacing.xs) {
                    ForEach(session.caseFile.suspects) { suspect in
                        pinned(suspect)
                    }
                }
                .padding(.top, Trace.Spacing.s)
            }
            .padding(.horizontal, Trace.Spacing.l)
            .padding(.top, Trace.Spacing.s)
            .padding(.bottom, Trace.Spacing.xxl)
        }
        .scrollBounceBehavior(.basedOnSize)
        .safeAreaInset(edge: .bottom, spacing: 0) { footer }
        .background(DeepDeskBackdrop())
    }

    /// Two columns; one at accessibility text sizes (§3 Dynamic Type).
    private var columns: [GridItem] {
        typeSize.isAccessibilitySize
            ? [GridItem(.flexible(), spacing: Trace.Spacing.l)]
            : [GridItem(.flexible(), spacing: Trace.Spacing.l), GridItem(.flexible(), spacing: Trace.Spacing.l)]
    }

    // MARK: Top

    /// « ‹ Carnet » while time remains; « Temps écoulé » once the timer is out (no way back).
    @ViewBuilder
    private func topLine(timeUp: Bool) -> some View {
        if timeUp {
            HStack(spacing: Trace.Spacing.s) {
                Text(verbatim: "◐").accessibilityHidden(true)
                Text(L10n.t("accuse.timeUp"))
            }
            .font(Trace.Fonts.data)
            .tracking(1.2)
            .textCase(.uppercase)
            .foregroundStyle(Trace.Colors.redOnDesk)
            .frame(minHeight: Trace.Height.hit, alignment: .leading)
            .accessibilityElement(children: .combine)
            .accessibilityIdentifier("accuse.timeUp")
        } else {
            BackLink(title: L10n.t("carnet.title"), identifier: "accuse.back") {
                session.resumeInvestigation()
            }
        }
    }

    /// « DOSSIER #001 · VÉRIFICATION FINALE » (Plex Mono, red on the desk), « Qui est responsable ? »
    /// (Newsreader 36, ivory).
    private var header: some View {
        VStack(alignment: .leading, spacing: Trace.Spacing.s) {
            Text(L10n.f("accuse.kicker", shownNumber(session.caseFile.number)))
                .font(Trace.Fonts.data)
                .tracking(1.3)
                .foregroundStyle(Trace.Colors.redOnDesk)
                .fixedSize(horizontal: false, vertical: true)
            Text(L10n.t("accuse.title"))
                .font(Trace.Fonts.display)
                .foregroundStyle(Trace.Colors.ivory)
                .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)
                .accessibilityIdentifier("accuse.title")
        }
    }

    // MARK: PinnedSuspect (§3)

    private func pinned(_ suspect: Suspect) -> some View {
        let game = session.game
        let isSelected = selected == suspect.id
        let contact = game.contact(suspect.contact)
        let name = game.name(of: suspect.contact)
        return Button {
            choose(suspect.id)
        } label: {
            PinnedSuspect(name: name,
                          relation: suspect.role,
                          image: ArtLibrary.portrait(case: session.caseFile.number, contact: contact),
                          initials: contact?.initials ?? IDPhoto.initials(of: name),
                          seed: suspect.id,
                          selected: isSelected)
        }
        .buttonStyle(PressableStyle())
        .opacity(selected == nil || isSelected ? 1 : 0.5)
        .zIndex(isSelected ? 1 : 0)
        .accessibilityLabel(Text(name))
        .accessibilityValue(Text(suspect.role))
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityIdentifier("accuse.suspect.\(suspect.id)")
    }

    // MARK: Hold

    /// The hold (1.6 s), disabled with « Choisissez un suspect » until a print is chosen.
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
            .background(Trace.Colors.bar.ignoresSafeArea(edges: .bottom))
            .overlay(alignment: .top) { Rectangle().fill(Trace.Colors.line).frame(height: 1) }
    }

    /// « Emma » for « Emma Roussel ».
    private var selectedFirstName: String {
        guard let selected, let suspect = session.game.index.suspect(selected) else { return "" }
        let full = session.game.name(of: suspect.contact)
        return full.split(separator: " ").first.map(String.init) ?? full
    }

    /// Straightened, lifted, red pin: the V4 spring of 260 ms; a 200 ms fade with reduced motion.
    private func choose(_ id: SuspectID) {
        guard selected != id, !concluded else { return }
        withAnimation(reduced ? .easeInOut(duration: 0.2) : Trace.Motion.sheet) { selected = id }
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

/// PinnedSuspect (V4 §3): a print (photoBorder edge, 176 pt photo, the name in Plex Sans 17/600 ink
/// and the relation in ink2 on its bottom margin) with a pin on top. Normal: a small deterministic
/// rotation (±2°, the handoff's value for this component; none with « Augmenter le contraste »),
/// `staple` pin. Selected: straight, lifted 6 pt, a 2 pt red rule, a red pin.
private struct PinnedSuspect: View {
    let name: String
    let relation: String
    let image: UIImage?
    let initials: String
    let seed: String
    let selected: Bool

    static let photoHeight: CGFloat = 176
    private static let border: CGFloat = 6
    private static let pinSize: CGFloat = 14

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Color.clear
                .frame(maxWidth: .infinity)
                .frame(height: Self.photoHeight)
                .overlay {
                    GeometryReader { geo in
                        PortraitOrInitials(image: image, initials: initials, width: geo.size.width, height: geo.size.height)
                    }
                }
                .clipped()
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(Trace.Fonts.headline)
                    .foregroundStyle(Trace.Colors.ink)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                Text(relation)
                    .font(Trace.Fonts.caption)
                    .foregroundStyle(Trace.Colors.ink2)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, Trace.Spacing.s + 2)
            .padding(.horizontal, 2)
        }
        .padding(Self.border)
        .padding(.bottom, Self.border + 2)
        .background(Trace.Colors.photoBorder)
        .overlay(Rectangle().strokeBorder(Trace.Colors.red, lineWidth: 2).opacity(selected ? 1 : 0))
        .shadow(color: selected ? Trace.Shadow.slip.color : Trace.Shadow.print.color,
                radius: selected ? Trace.Shadow.slip.radius * 2 : Trace.Shadow.print.radius,
                y: selected ? Trace.Shadow.slip.y * 2 : Trace.Shadow.print.y)
        .overlay(alignment: .top) {
            Pin(color: selected ? Trace.Colors.red : Trace.Colors.staple, size: Self.pinSize)
                .offset(y: -Self.pinSize / 2)
        }
        .modifier(TiltModifier(degrees: selected ? 0 : Self.angle(seed)))
        .offset(y: selected ? -6 : 0)
        .contentShape(Rectangle())
    }

    /// ±2°, the same for a suspect every time (FNV-1a of its id).
    static func angle(_ seed: String) -> Double {
        var hash: UInt64 = 1469598103934665603
        for byte in seed.utf8 { hash = (hash ^ UInt64(byte)) &* 1099511628211 }
        return (Double(hash % 1000) / 1000 * 2 - 1) * 2
    }
}

/// Hold to confirm with separate VoiceOver activation (the ALIBI verdict's former hold), on the V4
/// hold: track #2A2522, filled in red from left to right while held (linear, 1.6 s); released
/// early, it empties in 250 ms and nothing is sent. Light haptic at the start, rigid at the end.
/// Assistive technologies: the default action calls `onActivate` (the caller confirms), the named
/// action `actionName` concludes directly.
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
            .foregroundStyle(enabled ? Trace.Colors.ivory : Trace.Colors.ivory2)
            .padding(.horizontal, Trace.Spacing.l)
            .padding(.vertical, Trace.Spacing.s + 2)
            .frame(maxWidth: .infinity, minHeight: Trace.Height.hold)
            .background(alignment: .leading) {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Trace.Colors.holdTrack
                        Trace.Colors.redOnDesk.frame(width: geo.size.width * progress)
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

// MARK: - 11 · Verification

/// The verification (V4 §4 « Vérification »), 1.8 s, not interruptible: a blank sheet centred on
/// the desk; « VÉRIFICATION DU DOSSIER… » then the three lines (the designation, the decisive
/// pieces n/N, the connections) typed like a typewriter — 22 ms per character, compressed so the
/// typing ends by ~1.45 s —, then the RÉSOLU or NON RÉSOLU stamp falls on the sheet (180 ms + 60 ms
/// settle, rigid haptic); then `onRead` (the caller slides the report in). Reduced motion: the
/// lines appear, the stamp appears.
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

    /// Characters typed so far, across the heading and the lines.
    @State private var typed = 0
    @State private var stamped = false
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    @AppStorage(Preferences.reduceMotionKey) private var appReduceMotion = false

    /// The typing starts a beat after the sheet is on screen…
    private static let typingStart = 0.1
    /// … and ends by 1.45 s, when the stamp falls (it lands at ~1.69 s, before the 1.8 s).
    private static let stampAt = 1.45
    /// The stamp's reserved band at the bottom of the sheet.
    private static let stampBand: CGFloat = 76

    private var still: Bool { systemReduceMotion || appReduceMotion }

    private var heading: String { L10n.t("verdict.checking") }

    private var lines: [String] {
        var result = [designation]
        if decisiveTotal > 0 { result.append(L10n.f("verify.decisive", decisiveFound, decisiveTotal)) }
        result.append(L10n.f("verify.connections", connections))
        return result
    }

    /// Heading then lines, and where each one starts in the typed stream.
    private var texts: [String] { [heading] + lines }
    private var offsets: [Int] {
        var result: [Int] = []
        var total = 0
        for text in texts { result.append(total); total += text.count }
        return result
    }
    private var totalCharacters: Int { texts.reduce(0) { $0 + $1.count } }

    var body: some View {
        ZStack {
            DeepDeskBackdrop()
            // Centred; scrollable only when very large text makes the sheet taller than the screen.
            ViewThatFits(in: .vertical) {
                placedSheet
                ScrollView {
                    placedSheet.padding(.vertical, Trace.Spacing.xxl)
                }
                .scrollBounceBehavior(.basedOnSize)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("verify.view")
        .task { await run() }
    }

    private var placedSheet: some View {
        sheet
            .frame(maxWidth: 360)
            .padding(.horizontal, Trace.Spacing.xxl)
    }

    private var sheet: some View {
        let starts = offsets
        return VStack(alignment: .leading, spacing: 0) {
            Text(fileLabel(caseNumber))
                .font(Trace.Fonts.data)
                .tracking(1.2)
                .foregroundStyle(Trace.Colors.ink2)
                .accessibilityLabel(Text(fileLabel(caseNumber) + ", " + caseTitle))
            Rectangle()
                .fill(Trace.Colors.ink)
                .frame(height: 1.5)
                .padding(.top, Trace.Spacing.s)
                .accessibilityHidden(true)
            typedLine(heading, from: starts[0],
                      font: .custom(Trace.FontName.monoSemibold, size: 14, relativeTo: .callout), tracking: 0.6)
                .padding(.top, Trace.Spacing.xl)
                .accessibilityAddTraits(.isHeader)
            VStack(alignment: .leading, spacing: Trace.Spacing.m) {
                ForEach(Array(lines.enumerated()), id: \.offset) { index, line in
                    typedLine(line, from: starts[index + 1],
                              font: .custom(Trace.FontName.mono, size: 13, relativeTo: .footnote), tracking: 0)
                }
            }
            .padding(.top, Trace.Spacing.l)
            // The stamp falls here, below the text, never over it.
            Color.clear
                .frame(height: Self.stampBand)
                .frame(maxWidth: .infinity)
                .overlay(alignment: .trailing) {
                    if stamped {
                        FallingStampImage(asset: solved ? "stamp_resolu_rouge_marque" : "stamp_non_resolu_noir_marque",
                                          label: L10n.t(solved ? "stamp.solved" : "stamp.unsolved"),
                                          width: solved ? 128 : 172,
                                          onPaper: true,
                                          angle: -9,
                                          color: solved ? Trace.Colors.red : Trace.Colors.ink,
                                          success: solved,
                                          delay: 0)
                    }
                }
                .padding(.top, Trace.Spacing.l)
        }
        .padding(.horizontal, Trace.Spacing.xl)
        .padding(.top, Trace.Spacing.xl)
        .padding(.bottom, Trace.Spacing.l)
        .frame(maxWidth: .infinity, alignment: .leading)
        .paper(Trace.Colors.paper)
    }

    /// One typed line: the typed part in ink, the rest laid out but clear (the text never reflows
    /// while it is typed). VoiceOver reads the whole line once its typing has started.
    private func typedLine(_ text: String, from start: Int, font: Font, tracking: CGFloat) -> some View {
        let count = max(0, min(text.count, typed - start))
        let shown = String(text.prefix(count))
        let rest = String(text.dropFirst(count))
        return (Text(shown).foregroundStyle(Trace.Colors.ink) + Text(rest).foregroundStyle(Color.clear))
            .font(font)
            .tracking(tracking)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityLabel(Text(text))
            .accessibilityHidden(count == 0)
    }

    private func run() async {
        let clock = ContinuousClock()
        let start = clock.now
        let total = totalCharacters
        if still {
            try? await Task.sleep(for: .milliseconds(150))
            guard !Task.isCancelled else { return }
            withAnimation(.easeInOut(duration: 0.2)) { typed = total }
        } else {
            // 22 ms per character, or faster so that everything is typed by `stampAt`.
            let budget = Self.stampAt - Self.typingStart
            let perCharacter = min(Trace.Motion.typewriterCharacter, budget / Double(max(1, total)))
            while typed < total {
                try? await Task.sleep(for: .milliseconds(16))
                guard !Task.isCancelled else { return }
                let elapsed = Self.seconds(clock.now - start) - Self.typingStart
                let count = min(total, max(0, Int(elapsed / perCharacter)))
                if count != typed { typed = count }
            }
        }
        try? await Task.sleep(until: start.advanced(by: .milliseconds(Int(Self.stampAt * 1000))), clock: .continuous)
        guard !Task.isCancelled else { return }
        stamped = true
        try? await Task.sleep(until: start.advanced(by: .milliseconds(Int(Trace.Motion.verification * 1000))), clock: .continuous)
        guard !Task.isCancelled else { return }
        onRead()
    }

    private static func seconds(_ duration: Duration) -> Double {
        let parts = duration.components
        return Double(parts.seconds) + Double(parts.attoseconds) / 1e18
    }
}

// MARK: - 10 · Closing report

/// The verification (11), then the closing report (V4 ClosingReport) on a paper sheet: « RAPPORT
/// DE CLÔTURE » + #001, the title, the RÉSOLU / NON RÉSOLU stamp (−9°), the RESPONSABLE block, a
/// short explanation from the case, the figures on dotted ledger lines, the missed pieces on demand
/// (with their app) and the reconstruction on demand, then the final mark (Newsreader 40) and
/// Lacaze's visa. Not solved: the culprit stays hidden until « Consulter la solution » (confirmed;
/// the attempt then stops counting and can only be filed). Footer: solved → [Classer le dossier];
/// not solved → [Reprendre l'enquête] (timer full, pieces kept) + « Classer ». Filing slides the
/// report down into its folder (600 ms) before the callback. Re-created with `revealed` once the
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

    private enum Filing: Equatable { case file, fileAnyway }

    /// The verification is over: the report is on screen.
    @State private var reading = false
    /// « Consulter la solution ? » is on screen; `revealAsked` once confirmed (acted on when it closes).
    @State private var askingReveal = false
    @State private var revealAsked = false
    @State private var showMissed = false
    @State private var showTimeline = false
    /// « Classer »: the report slides into its folder, then the callback.
    @State private var filing: Filing?
    @State private var folderUp = false
    @State private var sheetDown = false
    @State private var fadedOut = false
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
    private var stampAsset: String { solved ? "stamp_resolu_rouge_marque" : "stamp_non_resolu_noir_marque" }
    private var stampLabel: String { L10n.t(solved ? "stamp.solved" : "stamp.unsolved") }
    /// The report slides in from below the stamped sheet (a fade with reduced motion).
    private var reportTransition: AnyTransition {
        reduced ? .opacity : .asymmetric(insertion: .move(edge: .bottom).combined(with: .opacity), removal: .opacity)
    }

    var body: some View {
        ZStack {
            DeepDeskBackdrop()
            if reading || revealed {
                report
                    .transition(reportTransition)
            } else {
                VerificationView(caseNumber: caseFile.number, caseTitle: caseFile.title,
                                 designation: L10n.f("verify.designated", accusedName), solved: solved,
                                 decisiveFound: keyEvidence.filter { verdict.foundEvidenceIDs.contains($0.id) }.count,
                                 decisiveTotal: keyEvidence.count,
                                 connections: connections) {
                    withAnimation(reduced ? .easeInOut(duration: 0.2) : Trace.Motion.paper) { reading = true }
                }
                .transition(.opacity)
            }
        }
    }

    private var report: some View {
        ScrollView {
            sheet
                .scaleEffect(sheetDown ? 0.94 : 1, anchor: .top)
                .offset(y: sheetDown ? 1100 : 0)
                .padding(.horizontal, Trace.Spacing.l)
                .padding(.top, Trace.Spacing.xl)
                .padding(.bottom, Trace.Spacing.xxl + Trace.Spacing.xs)
        }
        .scrollBounceBehavior(.basedOnSize)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            actions.opacity(filing == nil ? 1 : 0)
        }
        .overlay(alignment: .bottom) {
            if folderUp {
                FilingFolder(number: caseFile.number, stampAsset: stampAsset, stampLabel: stampLabel, solved: solved)
                    .transition(.move(edge: .bottom))
            }
        }
        .opacity(fadedOut ? 0 : 1)
        .onAppear { if revealed && !solved { showTimeline = true } }
        .task(id: filing) {
            guard let filing else { return }
            try? await Task.sleep(for: .milliseconds(reduced ? 200 : 600))
            guard !Task.isCancelled else { return }
            switch filing {
            case .file: onFile()
            case .fileAnyway: onFileAnyway()
            }
        }
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
                .presentationBackground(Trace.Colors.paper)
        }
    }

    /// The report itself: one paper sheet, never tilted, no texture behind the text but the grain.
    private var sheet: some View {
        VStack(alignment: .leading, spacing: Trace.Spacing.xxl) {
            reportHeader
            responsibleBlock
            explanation
            figures
            missedSection
            timelineSection
            closing
        }
        .padding(.horizontal, Trace.Spacing.sheet)
        .padding(.top, Trace.Spacing.xxl)
        .padding(.bottom, Trace.Spacing.xl)
        .frame(maxWidth: .infinity, alignment: .leading)
        .paper(Trace.Colors.paper)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("result.report")
    }

    // MARK: Header

    /// « RAPPORT DE CLÔTURE ······ #001 », a 1.5 pt ink rule, the title (Newsreader, sentence case),
    /// then the stamp at −9° on its own line (it never covers text).
    private var reportHeader: some View {
        VStack(alignment: .leading, spacing: Trace.Spacing.m) {
            HStack(alignment: .firstTextBaseline, spacing: Trace.Spacing.s) {
                Text(L10n.t("result.closingReport"))
                    .font(Trace.Fonts.data)
                    .tracking(1.3)
                    .foregroundStyle(Trace.Colors.ink)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: Trace.Spacing.s)
                Text(verbatim: "#" + shownNumber(caseFile.number))
                    .font(Trace.Fonts.data)
                    .foregroundStyle(Trace.Colors.ink)
            }
            .accessibilityElement(children: .combine)
            Rectangle()
                .fill(Trace.Colors.ink)
                .frame(height: 1.5)
                .accessibilityHidden(true)
            Text(caseFile.title.capitalizedFirst)
                .font(Trace.Fonts.title)
                .foregroundStyle(Trace.Colors.ink)
                .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)
            HStack(alignment: .center, spacing: Trace.Spacing.m) {
                if revealed && !solved {
                    Text(L10n.t("result.revealedBadge"))
                        .fieldLabel(Trace.Colors.ink2)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
                StampImage(asset: stampAsset, label: stampLabel, width: solved ? 150 : 190, onPaper: true,
                           angle: -9, color: solved ? Trace.Colors.red : Trace.Colors.ink)
                    .padding(.vertical, Trace.Spacing.s)
                    .padding(.trailing, Trace.Spacing.xs)
                    // The former « Lire le rapport » identifier, kept for the UI tests: the verdict.
                    .accessibilityIdentifier("result.read")
            }
        }
    }

    // MARK: Responsible

    /// RESPONSABLE: the real culprit's print and name when the solution is open; not solved, a blank
    /// print, « Non révélé », « Vous avez accusé : X » and the way to the solution (owner's rule: the
    /// failed report never names the culprit unless the player asks).
    private var responsibleBlock: some View {
        VStack(alignment: .leading, spacing: Trace.Spacing.m) {
            Text(L10n.t("result.responsible"))
                .fieldLabel(Trace.Colors.ink2)
                .accessibilityAddTraits(.isHeader)
            HStack(alignment: .center, spacing: Trace.Spacing.l) {
                responsiblePrint
                VStack(alignment: .leading, spacing: Trace.Spacing.xs) {
                    if open {
                        Text(culpritName)
                            .font(Trace.Fonts.personName)
                            .foregroundStyle(Trace.Colors.ink)
                            .fixedSize(horizontal: false, vertical: true)
                        if let role = caseFile.suspects.first(where: { $0.id == verdict.culprit })?.role {
                            Text(role)
                                .font(Trace.Fonts.caption)
                                .foregroundStyle(Trace.Colors.ink2)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    } else {
                        Text(L10n.t("result.responsibleHidden"))
                            .font(Trace.Fonts.personName)
                            .foregroundStyle(Trace.Colors.ink2)
                            .fixedSize(horizontal: false, vertical: true)
                        Text(L10n.t("result.responsibleHiddenTip"))
                            .font(Trace.Fonts.caption)
                            .foregroundStyle(Trace.Colors.ink2)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                Spacer(minLength: 0)
            }
            .accessibilityElement(children: .combine)
            if !solved {
                Rectangle().fill(Trace.Colors.ink2.opacity(0.25)).frame(height: 1)
                    .accessibilityHidden(true)
                Text(L10n.f("result.youAccused", accusedName))
                    .font(Trace.Fonts.callout)
                    .foregroundStyle(Trace.Colors.ink)
                    .fixedSize(horizontal: false, vertical: true)
            }
            if !open {
                Button(L10n.t("result.reveal")) { askingReveal = true }
                    .buttonStyle(TextLinkStyle(onPaper: true))
                    .accessibilityIdentifier("result.reveal")
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("result.responsible")
    }

    /// The culprit's print, stapled (a « ? » on the blank print while the solution is closed).
    private var responsiblePrint: some View {
        PhotoPrint(border: 4) {
            PortraitOrInitials(image: open ? ArtLibrary.portrait(case: caseFile.number, contact: culprit) : nil,
                               initials: open ? (culprit?.initials ?? IDPhoto.initials(of: culpritName)) : "?",
                               width: 78, height: 98)
        }
        .overlay(alignment: .top) { Staple().offset(y: -4) }
        .tilt(caseFile.id)
        .accessibilityHidden(true)
    }

    // MARK: Explanation

    /// Open: the case's headline and summary. Not solved: why it was not the accused (their alibi,
    /// or the trap), and what the player got right about them — never the culprit.
    @ViewBuilder
    private var explanation: some View {
        VStack(alignment: .leading, spacing: Trace.Spacing.s) {
            Text(open ? L10n.t("result.whatHappened") : L10n.t("result.notSeen"))
                .fieldLabel(Trace.Colors.ink2)
                .accessibilityAddTraits(.isHeader)
            if open {
                Text(caseFile.solution.headline)
                    .font(Trace.Fonts.headline)
                    .foregroundStyle(Trace.Colors.ink)
                    .fixedSize(horizontal: false, vertical: true)
                Text(caseFile.solution.summary)
                    .font(Trace.Fonts.body)
                    .foregroundStyle(Trace.Colors.ink)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                Text(L10n.f("result.wrongTitle", accusedName))
                    .font(Trace.Fonts.headline)
                    .foregroundStyle(Trace.Colors.ink)
                    .fixedSize(horizontal: false, vertical: true)
                if let reason = verdict.alibi ?? verdict.trap {
                    Text(reason)
                        .font(Trace.Fonts.body)
                        .foregroundStyle(Trace.Colors.ink)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .accessibilityElement(children: .contain)
        if !open && !verdict.foundAboutAccused.isEmpty {
            VStack(alignment: .leading, spacing: Trace.Spacing.m) {
                Text(L10n.t("result.rightFinds"))
                    .fieldLabel(Trace.Colors.ink2)
                    .accessibilityAddTraits(.isHeader)
                ForEach(verdict.foundAboutAccused) { evidence in
                    HStack(alignment: .firstTextBaseline, spacing: Trace.Spacing.m) {
                        Text(verbatim: "✓")
                            .font(Trace.Fonts.callout)
                            .foregroundStyle(Trace.Colors.green)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(evidence.title)
                                .font(Trace.Fonts.callout)
                                .foregroundStyle(Trace.Colors.ink)
                                .fixedSize(horizontal: false, vertical: true)
                            if !evidence.suspects.contains(verdict.culprit) {
                                Text(evidence.meaning)
                                    .font(Trace.Fonts.caption)
                                    .foregroundStyle(Trace.Colors.ink2)
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

    /// The figures as ledger lines with dotted leaders: Temps restant, Pièces utilisées, Indices
    /// trouvés, Indices manqués, Connexions (never judged).
    private var figures: some View {
        let missed = verdict.missed.count
        return VStack(alignment: .leading, spacing: 0) {
            Text(L10n.t("result.figures"))
                .fieldLabel(Trace.Colors.ink2)
                .padding(.bottom, Trace.Spacing.xs)
                .accessibilityAddTraits(.isHeader)
            DottedLedgerRow(label: L10n.t("result.timeLeft"), value: PhoneFormat.countdown(Double(verdict.remainingSeconds)))
            DottedLedgerRow(label: L10n.t("result.piecesUsed"), value: "\(verdict.pinnedCount)")
            DottedLedgerRow(label: L10n.t("result.cluesFound"), value: "\(verdict.foundCount)/\(verdict.totalCount)")
            DottedLedgerRow(label: L10n.t("result.cluesMissed"), value: "\(missed)",
                            valueColor: missed > 0 ? Trace.Colors.red : Trace.Colors.ink)
            DottedLedgerRow(label: L10n.t("result.connections"), value: "\(connections)")
            if relaxed {
                Text(L10n.t("result.relaxed"))
                    .font(Trace.Fonts.caption)
                    .foregroundStyle(Trace.Colors.ink2)
                    .padding(.top, Trace.Spacing.s)
            }
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
            VStack(alignment: .leading, spacing: Trace.Spacing.xs) {
                Button {
                    withAnimation(fade) { showMissed.toggle() }
                } label: {
                    HStack(spacing: Trace.Spacing.xs) {
                        Text(showMissed ? L10n.t("result.hideMissed") : L10n.f("result.showMissed", verdict.missed.count))
                        Image(systemName: showMissed ? "chevron.up" : "chevron.down")
                            .font(Trace.Fonts.caption)
                            .accessibilityHidden(true)
                    }
                }
                .buttonStyle(TextLinkStyle(onPaper: true))
                .accessibilityIdentifier("result.missedLink")
                if showMissed {
                    VStack(spacing: 0) {
                        ForEach(Array(verdict.missed.enumerated()), id: \.element.id) { offset, evidence in
                            missedRow(evidence, index: index, last: offset == verdict.missed.count - 1)
                        }
                    }
                    .overlay(alignment: .top) { Rectangle().fill(Trace.Colors.ink2.opacity(0.25)).frame(height: 1) }
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
                .foregroundStyle(Trace.Colors.ink2)
                .frame(minWidth: Trace.Spacing.xxl)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(open ? evidence.title : L10n.t("result.keyHiddenGeneric"))
                    .font(Trace.Fonts.callout)
                    .foregroundStyle(Trace.Colors.ink)
                    .fixedSize(horizontal: false, vertical: true)
                if let place {
                    Text(L10n.f("result.missedIn", place.title))
                        .font(Trace.Fonts.caption)
                        .foregroundStyle(Trace.Colors.ink2)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, Trace.Spacing.m)
        .frame(minHeight: Trace.Height.row)
        .overlay(alignment: .bottom) {
            if !last { Rectangle().fill(Trace.Colors.ink2.opacity(0.18)).frame(height: 1) }
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
                            .font(Trace.Fonts.caption)
                            .accessibilityHidden(true)
                    }
                }
                .buttonStyle(TextLinkStyle(onPaper: true))
                .accessibilityIdentifier("result.timelineLink")
                if showTimeline {
                    RevealTimeline(steps: caseFile.solution.reveal, found: verdict.foundEvidenceIDs,
                                   shown: caseFile.solution.reveal.count, onPaper: true)
                        .padding(.top, Trace.Spacing.s)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .transition(.opacity)
                        .accessibilityElement(children: .contain)
                        .accessibilityIdentifier("result.timeline")
                }
            }
        }
    }

    // MARK: Mark and visa

    /// A dashed rule, then the final mark (Newsreader 40/600, « — » when not ranked) and Lacaze's
    /// visa; stacked when they do not fit side by side.
    private var closing: some View {
        VStack(alignment: .leading, spacing: Trace.Spacing.l) {
            DashedRule()
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .bottom, spacing: Trace.Spacing.l) {
                    finalMark
                    Spacer(minLength: Trace.Spacing.l)
                    ClosingVisa()
                }
                VStack(alignment: .leading, spacing: Trace.Spacing.l) {
                    finalMark
                    ClosingVisa(alignment: .leading)
                }
            }
        }
    }

    private var finalMark: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(L10n.t("result.finalMark"))
                .fieldLabel(Trace.Colors.ink2)
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(verbatim: solved ? "\(verdict.score)" : "—")
                    .font(Trace.Fonts.score)
                    .foregroundStyle(Trace.Colors.ink)
                if solved {
                    Text(verbatim: "/100")
                        .font(Trace.Fonts.data)
                        .foregroundStyle(Trace.Colors.ink2)
                }
            }
        }
        .fixedSize()
        .accessibilityElement(children: .combine)
    }

    // MARK: Footer

    /// Fixed footer on the bar, one full button (ivory on the desk). Solved (or solution read):
    /// [Classer le dossier]. Not solved: [Reprendre l'enquête] + « Classer » (text link).
    private var actions: some View {
        VStack(spacing: Trace.Spacing.xs) {
            if solved {
                Button(L10n.t("result.fileCase")) { file(.file) }
                    .buttonStyle(CTAButtonStyle())
                    .accessibilityIdentifier("result.file")
            } else if revealed {
                // The solution was read: the case can only be filed (unsolved), not replayed at once.
                Button(L10n.t("result.fileCase")) { file(.fileAnyway) }
                    .buttonStyle(CTAButtonStyle())
                    .accessibilityIdentifier("result.file")
            } else {
                Button(L10n.t("result.retry"), action: onRetry)
                    .buttonStyle(CTAButtonStyle())
                    .accessibilityHint(Text(L10n.t("result.replayHint")))
                    .accessibilityIdentifier("result.retry")
                Button(L10n.t("result.fileShort")) { file(.fileAnyway) }
                    .buttonStyle(TextLinkStyle())
                    .frame(maxWidth: .infinity)
                    .accessibilityIdentifier("result.fileAnyway")
            }
        }
        .disabled(filing != nil)
        .padding(.horizontal, Trace.Spacing.l)
        .padding(.top, Trace.Spacing.m)
        .padding(.bottom, Trace.Spacing.s)
        .background(Trace.Colors.bar.ignoresSafeArea(edges: .bottom))
        .overlay(alignment: .top) { Rectangle().fill(Trace.Colors.line).frame(height: 1) }
    }

    /// « Classer » (V4 §5): the folder rises, the report slides down into it (600 ms), then the
    /// callback (`.task(id: filing)`). Reduced motion: a 200 ms fade.
    private func file(_ action: Filing) {
        guard filing == nil else { return }
        AudioDirector.shared.play(.folder, volume: 0.8)
        Haptics.light()
        if reduced {
            withAnimation(.easeInOut(duration: 0.2)) { fadedOut = true }
        } else {
            withAnimation(.easeOut(duration: 0.24)) { folderUp = true }
            withAnimation(.easeIn(duration: 0.6)) { sheetDown = true }
        }
        withAnimation(.easeOut(duration: 0.15)) { filing = action }
    }
}

/// The folder the report slides into when it is filed: a kraft front rising from the bottom, the
/// case number and its stamp. Decorative.
private struct FilingFolder: View {
    let number: Int
    let stampAsset: String
    let stampLabel: String
    let solved: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: Trace.Spacing.m) {
            Text(fileLabel(number))
                .font(Trace.Fonts.data)
                .tracking(1.2)
                .foregroundStyle(Trace.Colors.ink)
            StampImage(asset: stampAsset, label: stampLabel, width: solved ? 110 : 140, onPaper: true,
                       angle: -9, color: solved ? Trace.Colors.red : Trace.Colors.ink)
            Spacer(minLength: 0)
        }
        .padding(Trace.Spacing.xxl)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .frame(height: 260)
        .kraft()
        .padding(.horizontal, Trace.Spacing.s)
        .offset(y: 40)
        .ignoresSafeArea(edges: .bottom)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

/// Label ········ value: a figure of the closing report on paper (Plex Sans 14 ink, Plex Mono 13/700
/// value, a dotted ink2 leader on the baseline).
private struct DottedLedgerRow: View {
    let label: String
    let value: String
    var valueColor: Color = Trace.Colors.ink

    var body: some View {
        HStack(alignment: .lastTextBaseline, spacing: Trace.Spacing.s) {
            Text(label)
                .font(Trace.Fonts.callout)
                .foregroundStyle(Trace.Colors.ink)
                .fixedSize(horizontal: false, vertical: true)
                .layoutPriority(1)
            HorizontalRule()
                .stroke(Trace.Colors.ink2.opacity(0.7), style: StrokeStyle(lineWidth: 1.5, lineCap: .round, dash: [0.1, 5]))
                .frame(minWidth: Trace.Spacing.l)
                .frame(height: 2)
                .accessibilityHidden(true)
            Text(value)
                .font(Trace.Fonts.data)
                .foregroundStyle(valueColor)
                .fixedSize()
        }
        .padding(.vertical, Trace.Spacing.s)
        .frame(minHeight: 36)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(label + ", " + value))
    }
}

/// A dashed ink rule across the sheet.
private struct DashedRule: View {
    var body: some View {
        HorizontalRule()
            .stroke(Trace.Colors.ink2.opacity(0.45), style: StrokeStyle(lineWidth: 1, dash: [4, 3]))
            .frame(height: 1)
            .accessibilityHidden(true)
    }
}

/// A horizontal line through the middle of its frame.
private struct HorizontalRule: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        return path
    }
}

/// Commandant Lacaze's visa: « VISA », the blue signature PNG (multiply), his name. Also signs the
/// assignment letter.
struct ClosingVisa: View {
    var alignment: HorizontalAlignment = .trailing
    private static let width: CGFloat = 132

    var body: some View {
        VStack(alignment: alignment, spacing: 2) {
            Text(L10n.t("story.profile.visa"))
                .fieldLabel(Trace.Colors.ink2)
            Group {
                if let image = ArtLibrary.image("signature_lacaze_bleu") {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(width: Self.width)
                        .blendMode(.multiply)
                } else {
                    Handwritten(text: L10n.t("assignment.signatory"))
                        .frame(minHeight: 40)
                }
            }
            Text(L10n.t("assignment.signatory"))
                .font(Trace.Fonts.caption)
                .foregroundStyle(Trace.Colors.ink2)
        }
        .fixedSize()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(L10n.t("story.profile.visa") + ", " + L10n.t("assignment.signatory")))
    }
}

// MARK: - Reconstruction

/// The reconstruction: Plex Mono times (52 pt column), a 10 pt dot and a 2 pt line; found = filled
/// dot, missed = hollow dot + « ○ non trouvé » (never colour alone). On paper (`onPaper`, the
/// closing report): ink and ink2, the missed mark in red; otherwise on the desk (ivory).
struct RevealTimeline: View {
    let steps: [RevealStep]
    let found: Set<String>
    let shown: Int
    /// Ink on a paper sheet; ivory on the desk (the default, for the other callers).
    var onPaper: Bool = false

    private static let timeColumn: CGFloat = 52
    private static let dot: CGFloat = 10

    private var strong: Color { onPaper ? Trace.Colors.ink : Trace.Colors.text }
    private var soft: Color { onPaper ? Trace.Colors.ink2 : Trace.Colors.text2 }
    private var dotColor: Color { onPaper ? Trace.Colors.ink : Trace.Colors.ben }
    private var hollow: Color { onPaper ? Trace.Colors.ink2 : Trace.Colors.text3 }
    private var rail: Color { onPaper ? Trace.Colors.ink2.opacity(0.3) : Trace.Colors.surface3 }
    private var missedColor: Color { onPaper ? Trace.Colors.red : Trace.Colors.warning }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(steps.enumerated()), id: \.offset) { offset, step in
                let isFound = step.evidence.map { found.contains($0) } ?? true
                let visible = offset < shown
                HStack(alignment: .top, spacing: Trace.Spacing.m) {
                    Text(PhoneFormat.time(step.at))
                        .font(Trace.Fonts.fieldValueLarge)
                        .foregroundStyle(isFound ? strong : soft)
                        .fixedSize()
                        .frame(minWidth: Self.timeColumn, alignment: .leading)
                    VStack(spacing: 0) {
                        Circle()
                            .fill(isFound ? dotColor : Color.clear)
                            .overlay(Circle().strokeBorder(isFound ? dotColor : hollow, lineWidth: 2))
                            .frame(width: Self.dot, height: Self.dot)
                            .padding(.top, Trace.Spacing.xs)
                        if offset < steps.count - 1 {
                            Rectangle()
                                .fill(rail)
                                .frame(width: 2)
                                .frame(maxHeight: .infinity)
                        }
                    }
                    VStack(alignment: .leading, spacing: Trace.Spacing.xs) {
                        Text(step.text)
                            .font(Trace.Fonts.callout)
                            .foregroundStyle(isFound ? strong : soft)
                            .fixedSize(horizontal: false, vertical: true)
                        if !isFound {
                            Text(verbatim: "○ " + L10n.t("result.notFound"))
                                .font(Trace.Fonts.caption)
                                .foregroundStyle(missedColor)
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
