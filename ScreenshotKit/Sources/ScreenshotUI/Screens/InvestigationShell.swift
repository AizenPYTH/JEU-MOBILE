#if os(iOS)
import SwiftUI
import CaseEngine

/// The timed session (handoff V4 screens 04–05, on the UX V3 §4, §6-03 to §6-05): the light phone,
/// full width, and under it the kraft InvestigationRim, always visible (« ‹ Dossier #001 » · the
/// timer on its paper label with the pieces · « Carnet »). Over the phone, the EvidenceSlip of a
/// piece just filed (55 % desk veil); the Carnet is a pushed screen over everything; the pause
/// confirmation is a paper sheet.
///
/// The timer keeps running in the Carnet and under the EvidenceSlip; it stops when the app goes to
/// the background (the rim then reads « En pause » until the first tap on the phone) and while
/// the pause is asked. At 00:00 (or on concluding) every layer closes at once: the conclusion
/// screen must be up in less than 500 ms.
struct InvestigationView: View {
    let session: GameSession
    let onQuit: () -> Void
    /// The Carnet is pushed over the phone.
    @State private var carnetOpen = false
    @State private var carnetFocus: NotebookFocus?
    /// « Mettre l'enquête en pause ? »
    @State private var asksPause = false
    /// Pieces whose slip is still on the phone or gliding to « Carnet »: the counter waits for them.
    @State private var held: Set<ItemRef> = []
    /// The slip gliding to « Carnet » after « Continuer » (a copy drawn at rest).
    @State private var departing: GameSession.FilingReceipt?
    @State private var departed = false
    /// Counter in red + red halo on « Carnet », 1.5 s after a filing.
    @State private var celebrating = false
    @State private var celebrationID = 0
    @State private var phoneHeight: CGFloat = 0
    @State private var slipFrame: CGRect = .zero
    @State private var carnetFrame: CGRect = .zero
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    @AppStorage(Preferences.reduceMotionKey) private var appReduceMotion = false

    private var reduceMotion: Bool { systemReduceMotion || appReduceMotion }

    var body: some View {
        let filed = session.game.notebook.count
        // The counter moves when the slip reaches « Carnet ».
        let waiting = held.filter { session.isPinned($0) }.count
        let shown = max(0, filed - waiting)
        ZStack {
            VStack(spacing: 0) {
                PhoneView(session: session)
                    .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { phoneHeight = $0 }
                    .overlay { veil }
                InvestigationRim(session: session, shown: shown, celebrating: celebrating,
                                 onDossier: { askToPause() }, onCarnet: { openNotebook(nil) },
                                 onCarnetFrame: { carnetFrame = $0 })
            }
            // The slip lies over the phone only, but glides above the rim to « Carnet ».
            .overlay(alignment: .top) {
                slipLayer
                    .frame(height: phoneHeight)
            }
            .background(Trace.Colors.desk.ignoresSafeArea())
            .accessibilityHidden(carnetOpen)

            if carnetOpen {
                ZStack {
                    Trace.Colors.desk.ignoresSafeArea()
                    NotebookView(session: session, focus: carnetFocus, onBack: { closeNotebook() }, onConclude: { conclude() })
                        .environment(\.caseNumber, session.caseFile.number)
                }
                // « ‹ Téléphone »'s edge swipe: a drag that starts on the left edge goes back.
                .simultaneousGesture(
                    DragGesture(minimumDistance: 20)
                        .onEnded { value in
                            if value.startLocation.x < carnetEdgeWidth && value.translation.width > carnetEdgeSwipe {
                                closeNotebook()
                            }
                        }
                )
                .transition(reduceMotion ? .opacity : .move(edge: .trailing))
                .zIndex(2)
            }

            if scenePhase != .active {
                PauseOverlay()
                    .zIndex(3)
            }
        }
        .coordinateSpace(.named(investigationSpace))
        .statusBarHidden()
        .persistentSystemOverlays(.hidden)
        .defersSystemGestures(on: .bottom)
        .sheet(isPresented: pauseBinding) {
            PaperConfirmSheet(title: L10n.t("pause.ask.title"),
                              message: L10n.t("pause.ask.message"),
                              confirm: L10n.t("pause.ask.confirm"),
                              confirmID: "pause.confirm",
                              cancel: L10n.t("pause.ask.cancel"),
                              cancelID: "pause.cancel",
                              onConfirm: { leave() },
                              onCancel: { keepInvestigating() })
                .presentationDetents(pauseDetents)
                .presentationBackground(Trace.Colors.paper)
                .presentationCornerRadius(Trace.Radius.sheet)
                .presentationDragIndicator(.hidden)
        }
        .onChange(of: scenePhase) { _, phase in
            if phase != .active {
                session.pause()
            } else if carnetOpen || session.receipt != nil {
                // Back in the Carnet or on the EvidenceSlip: the clock goes on (the Carnet is part of
                // the timed investigation). Back on the phone itself: « En pause » until the first tap.
                session.resume()
            }
        }
        .onChange(of: session.carnetRequest) { _, request in
            guard let request else { return }
            openNotebook(request.connect ? .connect(request.ref) : .piece(request.ref))
        }
        .onChange(of: session.phase) { _, phase in
            if phase != .investigating { closeEverythingAtOnce() }
        }
        .onChange(of: session.lastFiled) { _, piece in
            guard let piece else { return }
            if let receipt = session.receipt, receipt.isNew, receipt.ref == piece.ref {
                // Its slip is up: the counter moves when the slip reaches « Carnet ».
                held.insert(piece.ref)
            } else {
                // Filed without a slip (a notification's « Verser », « L'accuse… »).
                celebrate()
            }
        }
        .onChange(of: session.receipt) { old, new in
            // The slip closed without gliding (« Relier », « Voir la pièce », the pause…).
            guard let old, new?.id != old.id, departing?.id != old.id else { return }
            release(old.ref)
        }
        .onAppear {
            // An EvidenceSlip left open by a previous screen of this session (never shown here).
            if session.receipt != nil { session.cancelFiling() }
        }
    }

    // MARK: EvidenceSlip (screen 05)

    /// The 55 % desk veil on the phone while a slip is up (a tap on it = « Continuer »).
    @ViewBuilder
    private var veil: some View {
        ZStack {
            if let receipt = session.receipt {
                Trace.Colors.desk.opacity(evidenceVeilOpacity)
                    .ignoresSafeArea(edges: .top)
                    .contentShape(Rectangle())
                    .onTapGesture { continueFiling(receipt) }
                    .transition(.opacity)
                    .accessibilityHidden(true)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: session.receipt != nil)
    }

    /// The slip on the phone, and the copy gliding to « Carnet ».
    private var slipLayer: some View {
        ZStack {
            if let receipt = session.receipt {
                EvidenceSlip(session: session, receipt: receipt,
                             onConnect: { session.showInCarnet(receipt.ref, connect: true) },
                             onViewInCarnet: { session.showInCarnet(receipt.ref) },
                             onContinue: { continueFiling(receipt) })
                    .onGeometryChange(for: CGRect.self) { $0.frame(in: .named(investigationSpace)) } action: { slipFrame = $0 }
                    .id(receipt.id)
                    .transition(reduceMotion ? .opacity : .identity)
            }
            if let departing {
                let target = CGSize(width: carnetFrame.midX - slipFrame.midX, height: carnetFrame.midY - slipFrame.midY)
                EvidenceSlip(session: session, receipt: departing, departing: true)
                    .scaleEffect(departed ? evidenceGlideScale : 1)
                    .offset(departed ? target : .zero)
                    .opacity(departed ? evidenceGlideEndOpacity : 1)
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
                    .id(-departing.id)
            }
        }
        .padding(evidenceSlipMargin)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .animation(reduceMotion ? .easeInOut(duration: 0.2) : nil, value: session.receipt?.id)
    }

    /// « Continuer », the veil, or the slip's 2.5 s: the slip glides to « Carnet » (scale → 0.2,
    /// 450 ms), then the counter moves and turns red for 1.5 s with a red halo on « Carnet ».
    /// Reduced motion: the slip fades out, the counter moves.
    private func continueFiling(_ receipt: GameSession.FilingReceipt) {
        guard session.receipt?.id == receipt.id else { return }
        guard receipt.isNew, !reduceMotion, slipFrame != .zero, carnetFrame != .zero else {
            session.fileCandidate()
            return
        }
        departed = false
        departing = receipt
        session.fileCandidate()
        Task {
            // One frame at rest where the slip was, then the glide.
            try? await Task.sleep(for: .milliseconds(16))
            guard departing?.id == receipt.id else { return }
            withAnimation(.timingCurve(0.4, 0, 0.2, 1, duration: evidenceGlideDuration)) { departed = true }
            try? await Task.sleep(for: .seconds(evidenceGlideDuration))
            guard departing?.id == receipt.id else { return }
            departing = nil
            departed = false
            release(receipt.ref)
        }
    }

    /// The piece has reached the Carnet: the counter moves.
    private func release(_ ref: ItemRef) {
        guard held.contains(ref) else { return }
        held.remove(ref)
        celebrate()
    }

    private func celebrate() {
        celebrationID += 1
        let id = celebrationID
        withAnimation(.easeOut(duration: 0.2)) { celebrating = true }
        Task {
            try? await Task.sleep(for: .seconds(1.5))
            guard celebrationID == id else { return }
            withAnimation(.easeIn(duration: 0.3)) { celebrating = false }
        }
    }

    // MARK: Carnet (pushed)

    private func openNotebook(_ focus: NotebookFocus?) {
        guard session.phase == .investigating else { return }
        if session.receipt != nil { session.cancelFiling() }
        session.clearSelection()
        if session.isPaused { session.resume() }
        carnetFocus = focus
        if carnetOpen { return }
        withAnimation(reduceMotion ? .easeInOut(duration: 0.2) : Trace.Motion.standard) { carnetOpen = true }
        session.coach.carnetOpened()
    }

    /// « ‹ Téléphone ».
    private func closeNotebook() {
        guard carnetOpen else { return }
        withAnimation(reduceMotion ? .easeInOut(duration: 0.2) : Trace.Motion.standard) { carnetOpen = false }
        carnetFocus = nil
        session.coach.carnetClosed()
    }

    /// « Conclure l'enquête » (the Carnet's own button): straight to the conclusion.
    private func conclude() {
        closeEverythingAtOnce()
        session.requestAccusation()
    }

    // MARK: Pause

    private var pauseDetents: Set<PresentationDetent> {
        dynamicTypeSize.isAccessibilitySize ? [.large] : [.height(300)]
    }

    /// The sheet swiped away: same as « Continuer ».
    private var pauseBinding: Binding<Bool> {
        Binding(get: { asksPause }, set: { shown in
            if !shown && asksPause {
                asksPause = false
                session.resume()
            }
        })
    }

    /// « ‹ Dossier »: the clock stops while the player decides.
    private func askToPause() {
        if session.receipt != nil { session.cancelFiling() }
        session.clearSelection()
        session.pause()
        asksPause = true
    }

    /// [Mettre en pause]: back to the desk, the investigation saved.
    private func leave() {
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) { asksPause = false }
        onQuit()
    }

    /// « Continuer »: the clock starts again.
    private func keepInvestigating() {
        asksPause = false
        session.resume()
    }

    /// 00:00 or concluding: every layer goes at once, without its slide.
    private func closeEverythingAtOnce() {
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            if carnetOpen {
                carnetOpen = false
                session.coach.carnetClosed()
            }
            carnetFocus = nil
            asksPause = false
            departing = nil
            departed = false
            held.removeAll()
        }
        if session.receipt != nil { session.cancelFiling() }
    }
}

/// The shell's coordinate space (the slip glides from the phone to « Carnet »).
private let investigationSpace = "investigation.space"
/// The Carnet's edge swipe: starts within 24 pt of the left edge, goes 80 pt right.
private let carnetEdgeWidth: CGFloat = 24
private let carnetEdgeSwipe: CGFloat = 80
/// Screen 05: the desk veil over the phone, the room kept around the slip, and its glide.
private let evidenceVeilOpacity: Double = 0.55
private let evidenceSlipMargin: CGFloat = 24
private let evidenceGlideDuration: Double = 0.45
private let evidenceGlideScale: CGFloat = 0.2
private let evidenceGlideEndOpacity: Double = 0.4

extension Trace.Colors {
    /// The timer's « moins d'une minute » on the rim's paper label: a dark amber that keeps 5:1 on
    /// paperCard (the desk's `warning` is too light on paper).
    static let warningOnPaper = Color(hex: 0x8A5A00)
}

// MARK: - InvestigationRim (V4 §3)

/// The kraft investigation rim (V4 §3, ex-InvestigationBar): kraft with its fibres (none with
/// « Augmenter le contraste »), 96 pt with the home indicator zone, a fine shadow line on its top
/// edge, and a 1fr / auto / 1fr grid — « ‹ Dossier #001 » (pause, then back to the case file), a
/// paperCard label with the timer (Plex Mono 19/600 ink) and « n pièces » under it, and the ink
/// button « Carnet ». Timer digits: ink, dark amber under 01:00, red under 00:10 (colour change in
/// 300 ms, never blinking). After a filing: the counter in red and a red halo on « Carnet », 1.5 s.
struct InvestigationRim: View {
    let session: GameSession
    /// Pieces shown: the counter moves when the slip reaches « Carnet ».
    let shown: Int
    /// 1.5 s after a filing: counter in red, red halo on « Carnet ».
    let celebrating: Bool
    let onDossier: () -> Void
    let onCarnet: () -> Void
    var onCarnetFrame: (CGRect) -> Void = { _ in }

    var body: some View {
        let filed = session.game.notebook.count
        let file = fileLabel(session.caseFile.number)
        let back = Self.backTitle(session.caseFile.number)
        HStack(alignment: .center, spacing: 8) {
            Button(action: onDossier) {
                HStack(spacing: 3) {
                    Image(systemName: "chevron.left").font(.system(size: 17, weight: .semibold))
                    Text(back).font(Trace.Fonts.link)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                }
                .foregroundStyle(Trace.Colors.ink)
                .frame(minHeight: Trace.Height.hit)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityLabel(Text(back))
            .accessibilityHint(Text(L10n.t("pause.a11y")))
            .accessibilityIdentifier("phone.quit")

            timerLabel(file: file, filed: filed)

            Button(action: onCarnet) {
                Text(L10n.t("carnet.title"))
            }
            .buttonStyle(CTAButtonStyle(kind: .primary, onPaper: true, height: Trace.Height.hit))
            .fixedSize()
            .overlay {
                RoundedRectangle(cornerRadius: Trace.Radius.button + 3, style: .continuous)
                    .strokeBorder(Trace.Colors.red, lineWidth: 2)
                    .padding(-4)
                    .opacity(celebrating ? 1 : 0)
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
            }
            .onGeometryChange(for: CGRect.self) { $0.frame(in: .named(investigationSpace)) } action: { onCarnetFrame($0) }
            .frame(maxWidth: .infinity, alignment: .trailing)
            .accessibilityLabel(Text(L10n.f("a11y.carnet", filed)))
            .accessibilityIdentifier("phone.carnet")
        }
        .padding(.horizontal, 16)
        .padding(.top, 9)
        .padding(.bottom, 5)
        .frame(minHeight: Trace.Height.investigationBar - investigationBarHomeInset)
        .frame(maxWidth: .infinity)
        .background { RimKraft().ignoresSafeArea(edges: .bottom) }
        .overlay(alignment: .top) { RimEdge() }
        .environment(\.colorScheme, .light)
        .accessibilityElement(children: .contain)
    }

    /// The paperCard label: the timer, and the pieces (or « En pause ») under it; the « −8 s » an
    /// action just cost sits on its corner, on a small paper tag.
    private func timerLabel(file: String, filed: Int) -> some View {
        VStack(spacing: 1) {
            BarTimer(remaining: session.remainingSeconds, level: session.timerLevel, paused: session.isPaused)
            Text(session.isPaused ? L10n.t("timer.paused") : Self.shortCount(shown))
                .font(Trace.Fonts.caption)
                .foregroundStyle(celebrating && !session.isPaused ? Trace.Colors.red : Trace.Colors.ink2)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .contentTransition(.numericText())
                .animation(.easeOut(duration: 0.3), value: shown)
                .contentShape(Rectangle())
                .onTapGesture(perform: onCarnet)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(Text(file + ", " + Self.count(filed)))
                .accessibilityAddTraits(.isButton)
                .accessibilityAction { onCarnet() }
                .accessibilityIdentifier("phone.bar")
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 5)
        .frame(minWidth: rimLabelMinWidth)
        .background(
            Rectangle()
                .fill(Trace.Colors.paperCard)
                .shadow(color: Trace.Shadow.print.color, radius: 3, y: 2)
        )
        .overlay(alignment: .topTrailing) {
            // The time an action just cost (« −8 s »), astride the label's corner.
            if let cost = session.lastCost {
                Text(L10n.f("bar.cost", cost.seconds))
                    .font(Trace.Fonts.pieceNumber)
                    .foregroundStyle(Trace.Colors.red)
                    .fixedSize()
                    .padding(.horizontal, 5)
                    .padding(.vertical, 2)
                    .background(Rectangle().fill(Trace.Colors.label).shadow(color: Trace.Shadow.print.color, radius: 2, y: 1))
                    .alignmentGuide(.top) { d in d.height / 2 }
                    .alignmentGuide(.trailing) { d in d.width / 2 }
                    .id(cost.id)
                    .transition(.opacity)
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
            }
        }
        .fixedSize(horizontal: true, vertical: false)
        .animation(Theme.Motion.standard(Theme.Motion.fast), value: session.lastCost)
    }

    /// « ‹ Dossier #001 » / « ‹ Alibi #001 ».
    static func backTitle(_ n: Int) -> String {
        L10n.f(n > 100 && n <= 200 ? "rim.alibi" : "rim.dossier", shownNumber(n))
    }

    /// « 0 pièce » / « 1 pièce » / « 3 pièces » (on the label).
    static func shortCount(_ n: Int) -> String {
        n == 0 ? L10n.t("rim.noPieces") : L10n.f(n == 1 ? "carnet.pieceCountOne" : "carnet.pieceCountMany", n)
    }

    /// « Aucune pièce versée » / « 1 pièce versée » / « 3 pièces versées » (VoiceOver).
    static func count(_ n: Int) -> String {
        n == 0 ? L10n.t("bar.noPieces") : L10n.f("dossier.piecesCount", n)
    }
}

/// The rim's height includes the home indicator zone of a Face ID iPhone (34 pt).
private let investigationBarHomeInset: CGFloat = 34
/// The paper label keeps its width while the digits change.
private let rimLabelMinWidth: CGFloat = 96
/// The rim's top edge: a fine shadow cast on the phone.
private let rimShadowHeight: CGFloat = 6

/// The rim's kraft: flat kraft, its fibres in multiply (none with « Augmenter le contraste »).
private struct RimKraft: View {
    @Environment(\.colorSchemeContrast) private var contrast

    var body: some View {
        Trace.Colors.kraft
            .overlay {
                if contrast != .increased { PaperGrain(texture: "tex_kraft_fibers") }
            }
            .accessibilityHidden(true)
    }
}

/// The rim's top edge: a kraftDark rule and a soft shadow on the phone above it.
private struct RimEdge: View {
    var body: some View {
        VStack(spacing: 0) {
            LinearGradient(colors: [.clear, Trace.Shadow.print.color], startPoint: .top, endPoint: .bottom)
                .frame(height: rimShadowHeight)
            Rectangle().fill(Trace.Colors.kraftDark).frame(height: 1)
        }
        .offset(y: -rimShadowHeight)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

/// The countdown on the rim's label: Plex Mono 19/600, ink → dark amber under 01:00 → red under
/// 00:10 (colour change in 300 ms, never blinking). VoiceOver: « Temps restant : … » (+ « En
/// pause »), the digits as its value (UI tests).
struct BarTimer: View {
    let remaining: Double
    let level: GameSession.TimerLevel
    let paused: Bool

    var body: some View {
        Text(PhoneFormat.countdown(remaining))
            .font(Trace.Fonts.dataLarge)
            .monospacedDigit()
            .foregroundStyle(color)
            .opacity(paused ? 0.6 : 1)
            .animation(.easeInOut(duration: 0.3), value: level)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text(accessibilityText))
            .accessibilityValue(Text(PhoneFormat.countdown(remaining)))
            .accessibilityIdentifier("phone.timer")
    }

    private var color: Color {
        switch level {
        case .normal: Trace.Colors.ink
        case .low: Trace.Colors.warningOnPaper
        case .critical: Trace.Colors.red
        }
    }

    /// « Temps restant : 4 minutes et 12 secondes » (+ « En pause »).
    private var accessibilityText: String {
        let spoken = L10n.f("a11y.timer", SpokenDuration.text(remaining))
        return paused ? spoken + ". " + L10n.t("timer.paused") : spoken
    }
}

// MARK: - Pause

/// « Enquête en pause »: the app went to the background. A yellow post-it « EN PAUSE », taped on
/// the desk (it hides the phone in the app switcher).
struct PauseOverlay: View {
    var body: some View {
        ZStack {
            TraceDesk()
            VStack(alignment: .leading, spacing: 6) {
                Text(L10n.t("timer.paused"))
                    .font(Trace.Fonts.dataLarge)
                    .tracking(2)
                    .textCase(.uppercase)
                    .foregroundStyle(Trace.Colors.ink)
                Text(L10n.t("pause.stopped"))
                    .font(Trace.Fonts.callout)
                    .foregroundStyle(Trace.Colors.ink2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 24)
            .padding(.top, 26)
            .padding(.bottom, 22)
            .frame(minWidth: pausePostItWidth, alignment: .leading)
            .background(Trace.Colors.postIt.shadow(.drop(color: Trace.Shadow.slip.color, radius: 10, y: 8)))
            .overlay(alignment: .top) { Tape().offset(y: -8) }
            .modifier(TiltModifier(degrees: -1))
            .padding(.horizontal, 32)
        }
        .accessibilityElement(children: .combine)
    }
}

/// The pause post-it's width.
private let pausePostItWidth: CGFloat = 220
#endif
