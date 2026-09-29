#if os(iOS)
import SwiftUI
import CaseEngine

/// The timed session (handoff UX V3 §4, §6-03 to §6-05): the light phone, full width, and under
/// it the dark BEN investigation bar, always visible (« ‹ Dossier » · the timer and the pieces ·
/// « Carnet »). Over the phone, the EvidenceSheet of a piece just filed (35 % veil); the Carnet is
/// a pushed screen over everything; the pause confirmation is a sheet.
///
/// The timer keeps running in the Carnet and under the EvidenceSheet; it stops when the app goes to
/// the background (the bar then reads « En pause » until the first tap on the phone) and while
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
    /// The copy of the piece just filed, on its way to the Carnet button.
    @State private var flight: GameSession.FiledPiece?
    @State private var flightLanded = false
    /// Counter in success colour + ben halo on « Carnet », 1.5 s after a filing.
    @State private var celebrating = false
    @State private var celebrationID = 0
    @State private var phoneFrame: CGRect = .zero
    @State private var carnetFrame: CGRect = .zero
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    @AppStorage(Preferences.reduceMotionKey) private var appReduceMotion = false

    private var reduceMotion: Bool { systemReduceMotion || appReduceMotion }

    var body: some View {
        let filed = session.game.notebook.count
        // The counter moves when the flying copy lands on « Carnet ».
        let shown = max(0, filed - (flight == nil ? 0 : 1))
        ZStack {
            VStack(spacing: 0) {
                PhoneView(session: session)
                    .onGeometryChange(for: CGRect.self) { $0.frame(in: .named(investigationSpace)) } action: { phoneFrame = $0 }
                    .overlay { evidenceSheetLayer }
                InvestigationBar(session: session, shown: shown, celebrating: celebrating,
                                 onDossier: { askToPause() }, onCarnet: { openNotebook(nil) },
                                 onCarnetFrame: { carnetFrame = $0 })
            }
            .background(Trace.Colors.bg.ignoresSafeArea())
            .accessibilityHidden(carnetOpen)

            flightLayer

            if carnetOpen {
                ZStack {
                    Trace.Colors.bg.ignoresSafeArea()
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
                .presentationBackground(Trace.Colors.surface)
                .presentationCornerRadius(Trace.Radius.sheet)
                .presentationDragIndicator(.hidden)
        }
        .onChange(of: scenePhase) { _, phase in
            if phase != .active {
                session.pause()
            } else if carnetOpen || session.receipt != nil {
                // Back in the Carnet or the EvidenceSheet: the clock goes on (the Carnet is part of
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
            if let piece { fly(piece) }
        }
        .onAppear {
            // An EvidenceSheet left open by a previous screen of this session (never shown here).
            if session.receipt != nil { session.cancelFiling() }
        }
    }

    // MARK: EvidenceSheet (§6-05)

    /// The 35 % veil on the phone and the sheet, above the investigation bar.
    private var evidenceSheetLayer: some View {
        ZStack(alignment: .bottom) {
            if let receipt = session.receipt {
                Theme.Colors.scrim
                    .ignoresSafeArea(edges: .top)
                    .contentShape(Rectangle())
                    .onTapGesture { session.fileCandidate() }
                    .transition(.opacity)
                    .accessibilityHidden(true)
                FilingSheet(session: session, receipt: receipt,
                            onConnect: { session.showInCarnet(receipt.ref, connect: true) },
                            onViewInCarnet: { session.showInCarnet(receipt.ref) })
                    .transition(reduceMotion ? .opacity : .move(edge: .bottom))
            }
        }
        .animation(reduceMotion ? .easeInOut(duration: 0.2) : Trace.Motion.sheet, value: session.receipt)
    }

    /// The copy of the piece just filed, from the middle of the phone to « Carnet ».
    @ViewBuilder
    private var flightLayer: some View {
        if let flight {
            let start = CGPoint(x: phoneFrame.midX, y: phoneFrame.minY + phoneFrame.height * 0.4)
            let end = CGPoint(x: carnetFrame.midX, y: carnetFrame.midY)
            FiledPaperCopy(piece: flight, game: session.game)
                .scaleEffect(flightLanded ? 0.2 : 1)
                .opacity(flightLanded ? 0 : 1)
                .position(flightLanded ? end : start)
                .allowsHitTesting(false)
                .zIndex(1)
        }
    }

    /// §6-05 / §8: the copy flies to « Carnet » (450 ms spring, scale 1 → 0.2, opacity → 0), then
    /// the counter moves and turns green for 1.5 s with a ben halo on « Carnet ». Reduced motion:
    /// no flight, only the counter.
    private func fly(_ piece: GameSession.FiledPiece) {
        guard !reduceMotion, phoneFrame != .zero, carnetFrame != .zero else {
            celebrate()
            return
        }
        flightLanded = false
        flight = piece
        Task {
            // The sheet comes up first.
            try? await Task.sleep(for: .milliseconds(150))
            guard flight?.id == piece.id else { return }
            withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) { flightLanded = true }
            try? await Task.sleep(for: .milliseconds(450))
            guard flight?.id == piece.id else { return }
            flight = nil
            flightLanded = false
            celebrate()
        }
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
            flight = nil
        }
        if session.receipt != nil { session.cancelFiling() }
    }
}

/// The shell's coordinate space (the flying copy goes from the phone to « Carnet »).
private let investigationSpace = "investigation.space"
/// The Carnet's edge swipe: starts within 24 pt of the left edge, goes 80 pt right.
private let carnetEdgeWidth: CGFloat = 24
private let carnetEdgeSwipe: CGFloat = 80

// MARK: - InvestigationBar (§4, §5)

/// The BEN's investigation bar (§5 InvestigationBar): `bg`, a `line` rule on top, 92 pt with the
/// bottom safe area, a 1fr / auto / 1fr grid — « ‹ Dossier » (pause, then back to the desk), the
/// timer (Plex Mono 20) with « n pièces versées » under it, and « Carnet » on `surface2`.
/// Timer digits: `text`, `warning` under 01:00 (300 ms, no blinking), `criticalOnDark` under 00:10.
struct InvestigationBar: View {
    let session: GameSession
    /// Pieces shown: the counter moves when the flying copy lands.
    let shown: Int
    /// 1.5 s after a filing: counter in success colour, ben halo on « Carnet ».
    let celebrating: Bool
    let onDossier: () -> Void
    let onCarnet: () -> Void
    var onCarnetFrame: (CGRect) -> Void = { _ in }

    var body: some View {
        let filed = session.game.notebook.count
        let file = fileLabel(session.caseFile.number)
        HStack(alignment: .center, spacing: 8) {
            Button(action: onDossier) {
                HStack(spacing: 3) {
                    Image(systemName: "chevron.left").font(.system(size: 17, weight: .semibold))
                    Text(L10n.t("carnet.dossierLink")).font(Trace.Fonts.link)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                .foregroundStyle(Trace.Colors.benText)
                .frame(minHeight: Trace.Height.hit)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityLabel(Text(L10n.t("carnet.dossierLink")))
            .accessibilityHint(Text(L10n.t("pause.a11y")))
            .accessibilityIdentifier("phone.quit")

            VStack(spacing: 2) {
                BarTimer(remaining: session.remainingSeconds, level: session.timerLevel, paused: session.isPaused)
                    .overlay(alignment: .trailing) {
                        // The time an action just cost (« −8 s »), beside the digits.
                        if let cost = session.lastCost {
                            Text(L10n.f("bar.cost", cost.seconds))
                                .font(Trace.Fonts.data)
                                .foregroundStyle(Trace.Colors.warning)
                                .fixedSize()
                                .alignmentGuide(.trailing) { d in d[.leading] - 6 }
                                .id(cost.id)
                                .transition(.opacity)
                                .allowsHitTesting(false)
                                .accessibilityHidden(true)
                        }
                    }
                Text(session.isPaused ? L10n.t("timer.paused") : Self.count(shown))
                    .font(Trace.Fonts.caption)
                    .foregroundStyle(celebrating && !session.isPaused ? Trace.Colors.successText : Trace.Colors.text2)
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
            .fixedSize(horizontal: true, vertical: false)
            .animation(Theme.Motion.standard(Theme.Motion.fast), value: session.lastCost)

            Button(action: onCarnet) {
                Text(L10n.t("carnet.title"))
                    .font(Trace.Fonts.monoStrong)
                    .foregroundStyle(Trace.Colors.text)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .padding(.horizontal, 18)
                    .frame(minHeight: Trace.Height.hit)
                    .background(RoundedRectangle(cornerRadius: Trace.Radius.button, style: .continuous).fill(Trace.Colors.surface2))
                    .overlay {
                        RoundedRectangle(cornerRadius: Trace.Radius.button + 3, style: .continuous)
                            .strokeBorder(Trace.Colors.ben, lineWidth: 2)
                            .padding(-3)
                            .opacity(celebrating ? 1 : 0)
                    }
                    .contentShape(Rectangle())
            }
            .buttonStyle(PressableStyle())
            .onGeometryChange(for: CGRect.self) { $0.frame(in: .named(investigationSpace)) } action: { onCarnetFrame($0) }
            .frame(maxWidth: .infinity, alignment: .trailing)
            .accessibilityLabel(Text(L10n.f("a11y.carnet", filed)))
            .accessibilityIdentifier("phone.carnet")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
        .frame(minHeight: Trace.Height.investigationBar - investigationBarHomeInset)
        .frame(maxWidth: .infinity)
        .background(Trace.Colors.bg.ignoresSafeArea(edges: .bottom))
        .overlay(alignment: .top) { Rectangle().fill(Trace.Colors.line).frame(height: 1) }
        .environment(\.colorScheme, .dark)
        .accessibilityElement(children: .contain)
    }

    /// « Aucune pièce versée » / « 1 pièce versée » / « 3 pièces versées ».
    static func count(_ n: Int) -> String {
        n == 0 ? L10n.t("bar.noPieces") : L10n.f("dossier.piecesCount", n)
    }
}

/// The bar's height includes the home indicator zone of a Face ID iPhone (34 pt).
private let investigationBarHomeInset: CGFloat = 34

/// The countdown of the bar: Plex Mono 20, `text` → `warning` under 01:00 → `criticalOnDark` under
/// 00:10 (colour change in 300 ms, never blinking). VoiceOver: « Temps restant : … » (+ « En pause »),
/// the digits as its value (UI tests).
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
        case .normal: Trace.Colors.text
        case .low: Trace.Colors.warning
        case .critical: Trace.Colors.criticalOnDark
        }
    }

    /// « Temps restant : 4 minutes et 12 secondes » (+ « En pause »).
    private var accessibilityText: String {
        let spoken = L10n.f("a11y.timer", SpokenDuration.text(remaining))
        return paused ? spoken + ". " + L10n.t("timer.paused") : spoken
    }
}

// MARK: - Pause

/// « Enquête en pause »: the app went to the background. A flat BEN card on the dimmed screen.
struct PauseOverlay: View {
    var body: some View {
        ZStack {
            Trace.Colors.bg.opacity(0.94).ignoresSafeArea()
            VStack(alignment: .leading, spacing: 6) {
                Text(L10n.t("pause.overline")).fieldLabel(Trace.Colors.benText)
                Text(L10n.t("pause.title")).font(Trace.Fonts.headline).foregroundStyle(Trace.Colors.text)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 20)
            .benCard()
        }
        .accessibilityElement(children: .combine)
    }
}
#endif
