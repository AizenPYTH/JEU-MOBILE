#if os(iOS)
import SwiftUI
import UIKit
import CaseEngine

// The end of a case (final handoff §F-09 → §F-11): « QUI EST RESPONSABLE ? » and the hold to
// conclude (09), the typed verification and the stamp on the closed folder (10), the closing
// report (11). The official assignment (12) is in AssignmentView.swift.

// MARK: - 09 · Conclusion

/// « QUI EST RESPONSABLE ? »: one print per suspect with the pieces the player linked (▲ against,
/// ▼ in favour), then « MAINTENIR : {PRÉNOM} EST RESPONSABLE » (1.2 s). Shown when the player
/// concludes from the Carnet, or forced when the timer hits 00:00 (« TEMPS ÉCOULÉ », no way back,
/// no time limit to choose). With VoiceOver or Switch Control: a plain button and a confirmation.
struct AccusationView: View {
    let session: GameSession
    @State private var selected: SuspectID?
    @State private var confirming = false
    @State private var confirmed = false
    @State private var concluded = false
    @Environment(\.dynamicTypeSize) private var typeSize
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    @Environment(\.accessibilityVoiceOverEnabled) private var voiceOverEnabled
    @Environment(\.accessibilitySwitchControlEnabled) private var switchControlEnabled
    @AppStorage(Preferences.reduceMotionKey) private var appReduceMotion = false

    private var reduced: Bool { systemReduceMotion || appReduceMotion }

    /// The hold is replaced by a button and a confirmation sheet (§F-09, §M).
    private var assistive: Bool {
        voiceOverEnabled || switchControlEnabled || UIAccessibility.isVoiceOverRunning || UIAccessibility.isSwitchControlRunning
    }

    var body: some View {
        let game = session.game
        let timeUp = session.remainingSeconds <= 0
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                header(timeUp: timeUp)
                LazyVGrid(columns: columns, alignment: .leading, spacing: 16) {
                    ForEach(session.caseFile.suspects) { suspect in
                        suspectCard(suspect, game: game)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 20)
            .padding(.bottom, 24)
        }
        .scrollBounceBehavior(.basedOnSize)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            footer(timeUp: timeUp)
        }
        .background(DeskBackdrop())
        .sheet(isPresented: $confirming, onDismiss: {
            if confirmed { conclude() }
        }) {
            PaperConfirmSheet(title: L10n.t("accuse.confirmTitle"),
                              message: L10n.f("accuse.confirmMessage", selectedFullName),
                              confirm: L10n.t("accuse.conclude"),
                              confirmID: "accuse.confirm",
                              cancel: L10n.t("common.back"),
                              cancelID: "accuse.confirmCancel",
                              onConfirm: {
                                  confirmed = true
                                  confirming = false
                              },
                              onCancel: { confirming = false })
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.hidden)
                .presentationBackground(Trace.Colors.paper)
        }
    }

    /// Two columns; one at accessibility text sizes.
    private var columns: [GridItem] {
        typeSize.isAccessibilitySize
            ? [GridItem(.flexible(), spacing: 12)]
            : [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]
    }

    private func header(timeUp: Bool) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            if typeSize.isAccessibilitySize {
                kicker
                if timeUp { timeUpLabel }
            } else {
                HStack(alignment: .center, spacing: 8) {
                    kicker
                    Spacer(minLength: 8)
                    if timeUp { timeUpLabel }
                }
            }
            Text(L10n.t("accuse.title"))
                .font(Trace.Fonts.monoTitle)
                .tracking(1.2)
                .textCase(.uppercase)
                .foregroundStyle(Trace.Colors.bone)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)
                .accessibilityIdentifier("accuse.title")
        }
    }

    private var kicker: some View {
        Text(L10n.f("accuse.kicker", shownNumber(session.caseFile.number)))
            .font(Trace.Fonts.kicker)
            .tracking(1.6)
            .foregroundStyle(Trace.Colors.bone2)
            .fixedSize(horizontal: false, vertical: true)
    }

    /// The timer ran out: the conclusion was forced, there is no way back.
    private var timeUpLabel: some View {
        Text(L10n.t("accuse.timeUp"))
            .font(Trace.Fonts.kicker)
            .tracking(1.6)
            .foregroundStyle(Trace.Colors.stampOnDark)
            .fixedSize()
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .overlay(RoundedRectangle(cornerRadius: 3).strokeBorder(Trace.Colors.stampOnDark, lineWidth: 1.5))
            .accessibilityIdentifier("accuse.timeUp")
    }

    /// A suspect's card: square print, name, ▲ pieces against / ▼ pieces in favour (text, not only colour).
    private func suspectCard(_ suspect: Suspect, game: Investigation) -> some View {
        let isSelected = selected == suspect.id
        let contact = game.contact(suspect.contact)
        let name = game.name(of: suspect.contact)
        let entries = game.linkedEntries(for: suspect.id)
        let against = entries.filter { $0.stance == .incriminates }.count
        let favour = entries.filter { $0.stance == .clears }.count
        return Button {
            choose(suspect.id)
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                ConclusionPrint(image: ArtLibrary.portrait(case: session.caseFile.number, contact: contact),
                                initials: contact?.initials ?? String(name.prefix(2)).uppercased())
                Text(name)
                    .font(Trace.Fonts.serifTitle(17))
                    .foregroundStyle(Trace.Colors.ink)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                HStack(spacing: 12) {
                    Text(verbatim: "▲\(against)").foregroundStyle(Trace.Colors.stamp)
                    Text(verbatim: "▼\(favour)").foregroundStyle(Trace.Colors.inkMid)
                    Spacer(minLength: 0)
                    if isSelected {
                        Text(verbatim: "✓").foregroundStyle(Trace.Colors.stamp)
                    }
                }
                .font(Trace.Fonts.monoStrong)
            }
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .paper(isSelected ? Trace.Colors.paperSelected : Trace.Colors.paper, radius: 2, lifted: isSelected)
            .overlay(RoundedRectangle(cornerRadius: 2).strokeBorder(Trace.Colors.stamp, lineWidth: 2).opacity(isSelected ? 1 : 0))
            .contentShape(Rectangle())
        }
        .buttonStyle(PressableStyle())
        .offset(y: isSelected && !reduced ? -6 : 0)
        .opacity(selected == nil || isSelected ? 1 : 0.6)
        .zIndex(isSelected ? 1 : 0)
        .accessibilityLabel(Text(name))
        .accessibilityValue(Text(L10n.f("accuse.a11y.against", against) + ", " + L10n.f("accuse.a11y.favour", favour)))
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .accessibilityIdentifier("accuse.suspect.\(suspect.id)")
    }

    /// The named hold (or, with VoiceOver / Switch Control, a button and a sheet), and the way back
    /// to the Carnet while time remains.
    private func footer(timeUp: Bool) -> some View {
        VStack(spacing: 2) {
            if assistive {
                Button {
                    requestConfirmation()
                } label: {
                    Text(selected == nil ? L10n.t("accuse.choose") : L10n.f("accuse.concludeFor", selectedFirstName))
                        .fixedSize(horizontal: false, vertical: true)
                }
                .buttonStyle(CTAButtonStyle())
                .disabled(selected == nil)
                .accessibilityIdentifier("accuse.hold")
            } else {
                ConclusionHoldButton(title: selected == nil ? L10n.t("accuse.choose") : L10n.f("accuse.holdFor", selectedFirstName),
                                     enabled: selected != nil,
                                     actionName: L10n.t("accuse.conclude"),
                                     onActivate: { requestConfirmation() },
                                     onComplete: { conclude() })
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

    private var selectedContactName: String? {
        guard let selected, let suspect = session.game.index.suspect(selected) else { return nil }
        return session.game.name(of: suspect.contact)
    }

    private var selectedFullName: String { selectedContactName ?? "" }

    /// « Emma » for « Emma Roussel ».
    private var selectedFirstName: String {
        let full = selectedContactName ?? ""
        return full.split(separator: " ").first.map(String.init) ?? full
    }

    private func choose(_ id: SuspectID) {
        guard selected != id else { return }
        let animation: Animation = reduced ? .easeInOut(duration: 0.2) : .easeOut(duration: 0.26)
        withAnimation(animation) { selected = id }
        Haptics.selection()
        AudioDirector.shared.play(.paper, volume: 0.3)
    }

    private func requestConfirmation() {
        guard selected != nil, !concluded else { return }
        confirmed = false
        confirming = true
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

/// « MAINTENIR : … »: a dark track that fills linearly with the stamp's red while held (1.2 s);
/// released early, it drains in 250 ms and nothing is sent. Light haptic at the start, rigid at
/// the end. Assistive technologies get a custom action « Conclure ».
struct ConclusionHoldButton: View {
    let title: String
    let enabled: Bool
    let actionName: String
    let onActivate: () -> Void
    let onComplete: () -> Void

    @State private var progress: CGFloat = 0
    @State private var done = false

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: 6, style: .continuous)
        Text(title)
            .font(Trace.Fonts.cta)
            .tracking(2)
            .textCase(.uppercase)
            .multilineTextAlignment(.center)
            .foregroundStyle(Trace.Colors.bone.opacity(enabled ? 1 : 0.42))
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity, minHeight: 56)
            .background(alignment: .leading) {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        (enabled ? Trace.Colors.holdTrack : Color.clear)
                        Trace.Colors.stamp.frame(width: geo.size.width * progress)
                    }
                }
            }
            .clipShape(shape)
            .overlay(shape.strokeBorder(Trace.Colors.bone.opacity(enabled ? 0 : 0.18), lineWidth: 1.5))
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
                    withAnimation(.linear(duration: 0.25)) { progress = 0 }
                }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text(title))
            .accessibilityAddTraits(.isButton)
            .accessibilityAction { if enabled { onActivate() } }
            .accessibilityAction(named: Text(actionName)) {
                guard enabled, !done else { return }
                done = true
                onComplete()
            }
    }
}

/// A square photo print (white border): the case portrait, or initials on BEN blue (§N).
private struct ConclusionPrint: View {
    let image: UIImage?
    let initials: String

    var body: some View {
        Color.clear
            .aspectRatio(1, contentMode: .fit)
            .overlay {
                GeometryReader { geo in
                    PortraitOrInitials(image: image, initials: initials, width: geo.size.width, height: geo.size.height)
                        .saturation(image == nil ? 1 : 0.85)
                }
            }
            .clipped()
            .padding(4)
            .background(Trace.Colors.printWhite)
            .shadow(color: .black.opacity(0.25), radius: 5, y: 4)
            .accessibilityHidden(true)
    }
}

// MARK: - 10 · Verification

/// « VÉRIFICATION DU DOSSIER… » typed in 1.4 s, 300 ms of silence, the folder closes, the stamp
/// falls (RÉSOLU / NON RÉSOLU), then « RESPONSABLE DÉSIGNÉ : … » and [LIRE LE RAPPORT].
/// Reduced motion: the text is there at once, the cover fades in, the stamp appears without falling.
struct VerificationView: View {
    let caseNumber: Int
    let caseTitle: String
    /// « RESPONSABLE DÉSIGNÉ : … » / « VOTRE VERDICT : … », under the stamp.
    let designation: String
    let solved: Bool
    let onRead: () -> Void

    @State private var typed = 0
    @State private var closed = false
    @State private var stampDown = false
    @State private var landed = false
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    @AppStorage(Preferences.reduceMotionKey) private var appReduceMotion = false

    private static let typingSeconds = 1.4
    /// Above this many characters, one key sound every other character.
    private static let soundPerCharacterLimit = 28
    /// About −18 dB (§K).
    private static let keyVolume: Float = 0.13
    private static let folderWidth: CGFloat = 300
    private static let folderHeight: CGFloat = 340

    private var still: Bool { systemReduceMotion || appReduceMotion }
    private var line: String { L10n.t("verdict.checking") }

    var body: some View {
        VStack(spacing: 28) {
            Spacer(minLength: 12)
            folder
            Text(designation)
                .font(Trace.Fonts.monoStrong)
                .tracking(1.4)
                .foregroundStyle(Trace.Colors.bone)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 28)
                .opacity(landed ? 1 : 0)
                .accessibilityHidden(!landed)
            Spacer(minLength: 12)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            ZStack {
                if landed {
                    Button(L10n.t("result.read"), action: onRead)
                        .buttonStyle(CTAButtonStyle())
                        .accessibilityIdentifier("result.read")
                        .transition(.opacity)
                } else {
                    Color.clear.frame(height: 56)
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 12)
            .padding(.bottom, 10)
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("verify.view")
        .task { await run() }
    }

    /// The folder: the open sheet being typed, then the kraft cover closing over it with the stamp.
    private var folder: some View {
        ZStack {
            Color.clear.kraft(color: Trace.Colors.kraftDark)
            openSheet
                .opacity(closed ? 0 : 1)
            cover
                .rotation3DEffect(.degrees(closed || still ? 0 : -75), axis: (x: 0, y: 1, z: 0),
                                  anchor: .leading, perspective: 0.5)
                .opacity(closed ? 1 : 0)
        }
        .frame(width: Self.folderWidth, height: Self.folderHeight)
        .overlay(alignment: .topLeading) {
            UnevenRoundedRectangle(topLeadingRadius: 8, topTrailingRadius: 8)
                .fill(Trace.Colors.kraftDark)
                .frame(width: 110, height: 20)
                .offset(y: -18)
                .accessibilityHidden(true)
        }
    }

    private var openSheet: some View {
        let cursor = typed < line.count ? "▌" : ""
        return VStack(alignment: .leading, spacing: 12) {
            Text(fileLabel(caseNumber))
                .font(Trace.Fonts.kicker)
                .tracking(1.6)
                .foregroundStyle(Trace.Colors.stamp)
            Text(caseTitle)
                .font(Trace.Fonts.serifTitle(20))
                .foregroundStyle(Trace.Colors.ink)
                .lineLimit(3)
                .minimumScaleFactor(0.7)
            Rectangle().fill(Trace.Colors.ink.opacity(0.18)).frame(height: 1)
            Text(String(line.prefix(typed)) + cursor)
                .font(Trace.Fonts.fieldValueLarge)
                .foregroundStyle(Trace.Colors.ink)
                .lineLimit(3)
                .minimumScaleFactor(0.7)
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityLabel(Text(line))
            Spacer(minLength: 0)
        }
        .padding(18)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .paper(Trace.Colors.paper, radius: 0)
        .padding(12)
    }

    private var cover: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(fileLabel(caseNumber))
                .font(Trace.Fonts.kicker)
                .tracking(2)
                .foregroundStyle(Trace.Colors.kraftInk)
            Text(caseTitle)
                .font(Trace.Fonts.serifTitle(20))
                .foregroundStyle(Trace.Colors.kraftInk)
                .lineLimit(3)
                .minimumScaleFactor(0.7)
            Spacer(minLength: 8)
            ZStack {
                if stampDown {
                    FallingStampImage(asset: solved ? "stamp_resolu_rouge_marque" : "stamp_non_resolu_noir_marque",
                                      label: solved ? L10n.t("stamp.solved") : L10n.t("stamp.unsolved"),
                                      width: 220,
                                      onPaper: true,
                                      angle: -8,
                                      color: solved ? Trace.Colors.stamp : Trace.Colors.ink,
                                      success: solved,
                                      delay: 0.05)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 80)
            Spacer(minLength: 8)
            Text(L10n.t("verdict.closed"))
                .font(Trace.Fonts.monoSmall)
                .foregroundStyle(Trace.Colors.kraftLabel)
        }
        .padding(22)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .kraft()
    }

    private func run() async {
        let count = line.count
        if still {
            typed = count
            try? await Task.sleep(for: .milliseconds(300))
            guard !Task.isCancelled else { return }
            withAnimation(.easeInOut(duration: 0.2)) { closed = true }
            try? await Task.sleep(for: .milliseconds(220))
            guard !Task.isCancelled else { return }
            stampDown = true
            try? await Task.sleep(for: .milliseconds(400))
        } else {
            let step = Self.typingSeconds / Double(max(1, count))
            let sparse = count > Self.soundPerCharacterLimit
            for index in 1...max(1, count) {
                typed = index
                if !sparse || index % 2 == 0 { AudioDirector.shared.play(.typewriter, volume: Self.keyVolume) }
                try? await Task.sleep(for: .seconds(step))
                if Task.isCancelled { return }
            }
            // Silence before the stamp (§K).
            try? await Task.sleep(for: .milliseconds(300))
            guard !Task.isCancelled else { return }
            withAnimation(Trace.Motion.paper) { closed = true }
            try? await Task.sleep(for: .milliseconds(420))
            guard !Task.isCancelled else { return }
            stampDown = true
            try? await Task.sleep(for: .milliseconds(520))
        }
        guard !Task.isCancelled else { return }
        let animation: Animation = still ? .easeInOut(duration: 0.2) : .easeOut(duration: 0.3)
        withAnimation(animation) { landed = true }
    }
}

// MARK: - 11 · Closing report

/// The verification (10), then the closing report (11): header + mini-stamp, what happened (or,
/// not solved, what the player did not see — never the culprit), the key pieces ✓ / ○, then
/// TEMPS RESTANT · INDICES · NOTE. Solved: [CLASSER LE DOSSIER]. Not solved: [REPRENDRE L'ENQUÊTE],
/// « Classer quand même », « Consulter la solution ». Re-created with `revealed` after the
/// solution is requested: straight to the report, the solution shown in full.
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

    /// The verification is over: the report is on screen.
    @State private var reading = false
    /// « Consulter la solution ? » is on screen; `revealAsked` once confirmed (acted on when it closes).
    @State private var askingReveal = false
    @State private var revealAsked = false
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
    /// The report sheet arrives like a sheet of paper (§J); with reduced motion, it only fades.
    private var reportTransition: AnyTransition { reduced ? .opacity : .opacity.combined(with: .offset(y: 24)) }

    var body: some View {
        ZStack {
            DeskBackdrop()
            if reading || revealed {
                report
                    .transition(reportTransition)
            } else {
                VerificationView(caseNumber: caseFile.number, caseTitle: caseFile.title,
                                 designation: L10n.f("verify.designated", accusedName.uppercased()), solved: solved) {
                    AudioDirector.shared.play(.paper, volume: 0.4)
                    withAnimation(reduced ? .easeInOut(duration: 0.2) : Trace.Motion.paper) { reading = true }
                }
                .transition(.opacity)
            }
        }
    }

    private var report: some View {
        ScrollView {
            sheet
                .padding(.horizontal, 16)
                .padding(.top, 20)
                .padding(.bottom, 24)
        }
        .scrollBounceBehavior(.basedOnSize)
        .safeAreaInset(edge: .bottom, spacing: 0) { actions }
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
                .presentationCornerRadius(16)
                .presentationBackground(Trace.Colors.paper)
        }
    }

    private var sheet: some View {
        VStack(alignment: .leading, spacing: 20) {
            reportHeader
            rule
            VStack(alignment: .leading, spacing: 12) {
                sectionTitle(open ? L10n.t("result.whatHappened") : L10n.t("result.notSeen"))
                if open {
                    solutionSection
                } else {
                    notSeenSection
                }
            }
            if !keyEvidence.isEmpty {
                rule
                keyPiecesSection
            }
            footer
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .paper(Trace.Colors.paper, radius: 0, lifted: true)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("result.report")
    }

    // MARK: Header

    private var reportHeader: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text(L10n.f("result.header", shownNumber(caseFile.number)))
                    .font(Trace.Fonts.kicker)
                    .tracking(1.6)
                    .foregroundStyle(Trace.Colors.inkSoft)
                Text(caseFile.title)
                    .font(Trace.Fonts.serifTitle(22))
                    .foregroundStyle(Trace.Colors.ink)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityAddTraits(.isHeader)
                if revealed && !solved {
                    Text(L10n.t("stamp.revealed"))
                        .font(Trace.Fonts.kicker)
                        .tracking(1.6)
                        .foregroundStyle(Trace.Colors.stamp)
                }
            }
            Spacer(minLength: 8)
            StampImage(asset: solved ? "stamp_resolu_rouge_marque" : "stamp_non_resolu_noir_marque",
                       label: solved ? L10n.t("stamp.solved") : L10n.t("stamp.unsolved"),
                       width: solved ? 84 : 100,
                       onPaper: true,
                       angle: -8,
                       color: solved ? Trace.Colors.stamp : Trace.Colors.ink)
                .padding(.top, 6)
        }
    }

    // MARK: What happened

    /// Solved or revealed: the headline and the summary; after a request, also who it was and the
    /// reconstruction step by step.
    @ViewBuilder
    private var solutionSection: some View {
        if revealed && !solved {
            HStack(alignment: .center, spacing: 14) {
                ConclusionPrint(image: ArtLibrary.portrait(case: caseFile.number, contact: culprit),
                                initials: culprit?.initials ?? "?")
                    .frame(width: 64)
                Text(L10n.f("result.culpritWas", culpritName))
                    .font(Trace.Fonts.serifTitle(18))
                    .foregroundStyle(Trace.Colors.ink)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .accessibilityElement(children: .combine)
        }
        Text(caseFile.solution.headline)
            .font(Trace.Fonts.serifTitle(19))
            .foregroundStyle(Trace.Colors.ink)
            .fixedSize(horizontal: false, vertical: true)
        Text(caseFile.solution.summary)
            .font(Trace.Fonts.prose)
            .foregroundStyle(Trace.Colors.inkMid)
            .fixedSize(horizontal: false, vertical: true)
        if revealed && !caseFile.solution.reveal.isEmpty {
            sectionTitle(L10n.t("result.timeline"))
                .padding(.top, 8)
            RevealTimeline(steps: caseFile.solution.reveal, found: verdict.foundEvidenceIDs,
                           shown: caseFile.solution.reveal.count)
        }
    }

    /// Not solved, solution not requested: why it was not the accused (alibi, trap), what the
    /// player got right about them, and how much was missed per app — never the culprit. A
    /// meaning is only shown when the piece does not concern the culprit.
    @ViewBuilder
    private var notSeenSection: some View {
        Text(L10n.f("result.wrongTitle", accusedName))
            .font(Trace.Fonts.serifTitle(19))
            .foregroundStyle(Trace.Colors.ink)
            .fixedSize(horizontal: false, vertical: true)
        if let alibi = verdict.alibi {
            memo(L10n.t("result.alibi"), alibi)
        }
        if let trap = verdict.trap {
            memo(L10n.t("result.trap"), trap)
        }
        if !verdict.foundAboutAccused.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                sectionTitle(L10n.t("result.rightFinds"))
                ForEach(verdict.foundAboutAccused) { evidence in
                    HStack(alignment: .firstTextBaseline, spacing: 10) {
                        Text(verbatim: "✓")
                            .font(Trace.Fonts.monoStrong)
                            .foregroundStyle(Trace.Colors.pen)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(evidence.title)
                                .font(Trace.Fonts.fieldValue)
                                .foregroundStyle(Trace.Colors.ink)
                                .fixedSize(horizontal: false, vertical: true)
                            if !evidence.suspects.contains(verdict.culprit) {
                                Text(evidence.meaning)
                                    .font(Trace.Fonts.proseSmall)
                                    .foregroundStyle(Trace.Colors.inkMid)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                    .accessibilityElement(children: .combine)
                }
            }
            .padding(.top, 4)
        }
        if !verdict.missedByApp.isEmpty {
            VStack(alignment: .leading, spacing: 0) {
                sectionTitle(L10n.f("result.missed", verdict.missed.count))
                ForEach(missedApps, id: \.app) { item in
                    LedgerRow(label: item.app.title, value: L10n.f("result.missedCount", item.count))
                }
            }
            .padding(.top, 4)
        }
    }

    /// Missed items per app, most first.
    private var missedApps: [(app: AppID, count: Int)] {
        verdict.missedByApp
            .map { (app: $0.key, count: $0.value) }
            .sorted { $0.count != $1.count ? $0.count > $1.count : $0.app.title < $1.app.title }
    }

    // MARK: Key pieces

    /// ✓ found, ○ missed at 45 %. Not solved and not revealed: a missed piece only says which app
    /// it is in.
    private var keyPiecesSection: some View {
        let key = keyEvidence
        let foundCount = key.filter { verdict.foundEvidenceIDs.contains($0.id) }.count
        let index: CaseIndex? = open ? nil : CaseIndex(caseFile)
        return VStack(alignment: .leading, spacing: 4) {
            sectionTitle(L10n.f("result.keyPieces", foundCount, key.count))
                .padding(.bottom, 4)
            ForEach(key) { evidence in
                let found = verdict.foundEvidenceIDs.contains(evidence.id)
                keyRow(found || open ? evidence.title : hiddenLabel(for: evidence, index: index), found: found)
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("result.keyEvidence")
    }

    private func keyRow(_ label: String, found: Bool) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Text(verbatim: found ? "✓" : "○")
                .font(Trace.Fonts.monoStrong)
                .foregroundStyle(found ? Trace.Colors.pen : Trace.Colors.ink)
                .frame(width: 16, alignment: .leading)
            Text(label)
                .font(Trace.Fonts.prose)
                .foregroundStyle(Trace.Colors.ink)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .frame(minHeight: 30)
        .opacity(found ? 1 : 0.45)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text((found ? L10n.t("a11y.found") : L10n.t("a11y.missed")) + ", " + label))
    }

    /// « Une pièce dans l'app Messages » — a deleted message counts as the Trash.
    private func hiddenLabel(for evidence: Evidence, index: CaseIndex?) -> String {
        guard let ref = evidence.refs.first else { return L10n.t("result.keyHiddenGeneric") }
        let deleted = ref.kind == .message && index?.message(ref.id)?.deletedAt != nil
        return L10n.f("result.keyHidden", (deleted ? AppID.trash : ref.kind.app).title)
    }

    // MARK: Footer

    /// TEMPS RESTANT · INDICES · NOTE (never big; « — » when not solved), and the relaxed-time mention.
    private var footer: some View {
        let time = PhoneFormat.countdown(Double(verdict.remainingSeconds))
        let hints = "\(verdict.hintsUsed)"
        let mark = solved ? "\(verdict.score)/100" : "—"
        return VStack(alignment: .leading, spacing: 8) {
            if typeSize.isAccessibilitySize {
                VStack(spacing: 0) {
                    LedgerRow(label: L10n.t("result.timeLeft"), value: time)
                    LedgerRow(label: L10n.t("result.colHints"), value: hints)
                    LedgerRow(label: L10n.t("result.colMark"), value: mark)
                }
            } else {
                HStack(alignment: .top, spacing: 8) {
                    footerColumn(L10n.t("result.timeLeft"), time)
                    footerColumn(L10n.t("result.colHints"), hints)
                    footerColumn(L10n.t("result.colMark"), mark)
                }
                .padding(.top, 12)
                .overlay(alignment: .top) { rule }
            }
            if relaxed {
                Text(L10n.t("result.relaxed"))
                    .font(Trace.Fonts.monoSmall)
                    .foregroundStyle(Trace.Colors.inkSoft)
            }
        }
    }

    private func footerColumn(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(Trace.Fonts.kicker)
                .tracking(1.2)
                .textCase(.uppercase)
                .foregroundStyle(Trace.Colors.inkSoft)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(value)
                .font(Trace.Fonts.fieldValueLarge)
                .monospacedDigit()
                .foregroundStyle(Trace.Colors.ink)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    // MARK: Actions

    /// One full button; the rest are text links.
    private var actions: some View {
        VStack(spacing: 2) {
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
                    .accessibilityIdentifier("result.retry")
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 24) { secondaryLinks }
                    VStack(spacing: 0) { secondaryLinks }
                }
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

    @ViewBuilder
    private var secondaryLinks: some View {
        Button(L10n.t("result.fileAnyway"), action: onFileAnyway)
            .buttonStyle(TextLinkStyle())
            .accessibilityIdentifier("result.fileAnyway")
        if !revealed {
            Button(L10n.t("result.reveal")) { askingReveal = true }
                .buttonStyle(TextLinkStyle())
                .accessibilityIdentifier("result.reveal")
        }
    }

    // MARK: Pieces of the sheet

    private var rule: some View {
        Rectangle().fill(Trace.Colors.ink.opacity(0.18)).frame(height: 1)
    }

    private func sectionTitle(_ text: String) -> some View {
        Text(text)
            .font(Trace.Fonts.kicker)
            .tracking(1.6)
            .textCase(.uppercase)
            .foregroundStyle(Trace.Colors.inkSoft)
            .fixedSize(horizontal: false, vertical: true)
            .accessibilityAddTraits(.isHeader)
    }

    /// A labelled line of the debrief (the alibi, the trap).
    private func memo(_ label: String, _ text: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(Trace.Fonts.kicker)
                .tracking(1.6)
                .textCase(.uppercase)
                .foregroundStyle(Trace.Colors.stamp)
            Text(text)
                .font(Trace.Fonts.proseSmall)
                .foregroundStyle(Trace.Colors.ink)
                .fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityElement(children: .combine)
    }
}

/// The reconstruction, typed: found (filled square) · missed (empty square), a thin ink line.
struct RevealTimeline: View {
    let steps: [RevealStep]
    let found: Set<String>
    let shown: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(steps.enumerated()), id: \.offset) { offset, step in
                let isFound = step.evidence.map { found.contains($0) } ?? true
                HStack(alignment: .top, spacing: 12) {
                    Text(PhoneFormat.time(step.at)).font(Trace.Fonts.fieldValue).foregroundStyle(Trace.Colors.ink)
                        .frame(width: 42, alignment: .trailing)
                    VStack(spacing: 0) {
                        Rectangle()
                            .fill(isFound ? Trace.Colors.ink : .clear)
                            .overlay(Rectangle().strokeBorder(Trace.Colors.ink, lineWidth: 1.3))
                            .frame(width: 9, height: 9)
                            .padding(.top, 4)
                        if offset < steps.count - 1 {
                            Rectangle().fill(Trace.Colors.ink.opacity(0.5)).frame(width: 1).frame(minHeight: 28)
                        }
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(step.text).font(Trace.Fonts.proseSmall).foregroundStyle(isFound ? Trace.Colors.ink : Trace.Colors.inkSoft)
                            .fixedSize(horizontal: false, vertical: true)
                        if !isFound { Text(L10n.t("result.notFound")).font(Trace.Fonts.monoSmall).foregroundStyle(Trace.Colors.stamp) }
                    }
                    .padding(.bottom, 14)
                }
                .opacity(offset < shown ? 1 : 0)
                .offset(y: offset < shown ? 0 : 6)
                .accessibilityElement(children: .combine)
                .accessibilityLabel(Text((isFound ? L10n.t("a11y.found") : L10n.t("a11y.missed")) + ", \(PhoneFormat.time(step.at)), \(step.text)"))
            }
        }
    }
}
#endif
