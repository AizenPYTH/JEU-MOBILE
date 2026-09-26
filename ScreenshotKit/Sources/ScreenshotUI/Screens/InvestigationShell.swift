#if os(iOS)
import SwiftUI
import CaseEngine

/// The timed session: the phone, and on top of it the Carnet, the « VERSER AU DOSSIER » sheet and
/// the pause sheet. The timer keeps running under the Carnet and the filing sheet; it stops when
/// the app goes to the background (it then waits, « EN PAUSE », for the first tap) and while the
/// pause sheet is asked. At 00:00 (or on concluding) every sheet closes at once: the conclusion
/// screen must be up in less than 500 ms.
struct InvestigationView: View {
    let session: GameSession
    let onQuit: () -> Void
    @State private var sheet: Sheet?
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    enum Sheet: Identifiable, Equatable {
        case notebook
        /// The element long-pressed, and its piece number when the sheet opened (nil = not filed).
        case filing(ItemRef, filed: Int?)
        case pause

        var id: String {
            switch self {
            case .notebook: "notebook"
            case .filing(let ref, _): "filing." + ref.description
            case .pause: "pause"
            }
        }
    }

    /// §G: sheets have 16 pt top corners.
    private let sheetRadius: CGFloat = 16

    var body: some View {
        PhoneView(session: session, onNotebook: { openNotebook() }, onQuit: { askToPause() })
            .sheet(item: sheetBinding) { which in
                sheetContent(which)
                    .environment(\.caseNumber, session.caseFile.number)
            }
            .overlay {
                if scenePhase != .active {
                    PauseOverlay()
                }
            }
            .onChange(of: scenePhase) { _, phase in
                if phase != .active {
                    session.pause()
                } else if let sheet, sheet != .pause {
                    // Back in the Carnet or the filing sheet: the clock goes on (no « EN PAUSE »
                    // label to see there, and the Carnet is part of the timed investigation).
                    session.resume()
                }
                // Back on the phone itself: « EN PAUSE » on the timer tag until the first tap (§N).
            }
            .onChange(of: session.filingCandidate) { _, ref in
                if let ref {
                    sheet = .filing(ref, filed: session.game.pieceNumber(of: ref))
                } else if case .filing? = sheet {
                    if session.phase == .investigating { sheet = nil } else { closeSheetsAtOnce() }
                }
            }
            .onChange(of: session.phase) { _, phase in
                if phase != .investigating { closeSheetsAtOnce() }
            }
            .onAppear {
                // A filing left open by a previous screen of this session (never shown here).
                if session.filingCandidate != nil { session.cancelFiling() }
            }
    }

    @ViewBuilder
    private func sheetContent(_ which: Sheet) -> some View {
        switch which {
        case .notebook:
            NotebookView(session: session, onConclude: {
                session.coach.carnetClosed()
                sheet = nil
                session.requestAccusation()
            })
            .presentationDetents([.large])
            .presentationBackground(Trace.Colors.desk)
            .presentationCornerRadius(sheetRadius)
            .presentationDragIndicator(.visible)
        case .filing(let ref, let filed):
            FilingSheet(session: session, ref: ref, filedNumber: filed, onViewInCarnet: { showInCarnet() })
                .presentationDetents(filingDetents)
                .presentationBackground(Trace.Colors.paper)
                .presentationCornerRadius(sheetRadius)
                .presentationDragIndicator(.hidden)
        case .pause:
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
                .presentationCornerRadius(sheetRadius)
                .presentationDragIndicator(.hidden)
        }
    }

    private var filingDetents: Set<PresentationDetent> {
        dynamicTypeSize.isAccessibilitySize ? [.medium, .large] : [.height(320), .medium]
    }

    private var pauseDetents: Set<PresentationDetent> {
        dynamicTypeSize.isAccessibilitySize ? [.large] : [.height(300)]
    }

    /// A sheet closed by the player (swipe down, tap outside, `dismiss()` in the Carnet).
    private var sheetBinding: Binding<Sheet?> {
        Binding(get: { sheet }, set: { newValue in
            if newValue == nil, let old = sheet { closedByPlayer(old) }
            sheet = newValue
        })
    }

    private func closedByPlayer(_ old: Sheet) {
        switch old {
        case .notebook: session.coach.carnetClosed()
        case .filing: session.cancelFiling()
        case .pause: session.resume() // same as « Continuer »
        }
    }

    // MARK: Actions

    private func openNotebook() {
        // Bubble 1 is answered by any tap outside it.
        if session.coach.active == .explore { session.coach.dismiss() }
        sheet = .notebook
        session.coach.carnetOpened()
    }

    /// « VOIR DANS LE CARNET » on an element already filed.
    private func showInCarnet() {
        session.cancelFiling()
        sheet = .notebook
        session.coach.carnetOpened()
    }

    /// The pause button: the clock stops while the player decides.
    private func askToPause() {
        session.pause()
        sheet = .pause
    }

    /// [METTRE EN PAUSE]: back to the desk, the investigation saved.
    private func leave() {
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) { sheet = nil }
        onQuit()
    }

    /// « Continuer »: the clock starts again.
    private func keepInvestigating() {
        sheet = nil
        session.resume()
    }

    /// 00:00 or concluding: every sheet goes at once, without its slide.
    private func closeSheetsAtOnce() {
        guard let old = sheet else { return }
        if old == .notebook { session.coach.carnetClosed() }
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) { sheet = nil }
    }
}

/// "Enquête en pause" — the desk goes dark, a note is left on it.
struct PauseOverlay: View {
    var body: some View {
        ZStack {
            Rectangle().fill(.ultraThinMaterial).ignoresSafeArea()
            Trace.Colors.desk.opacity(0.55).ignoresSafeArea()
            VStack(alignment: .leading, spacing: 8) {
                Text(L10n.t("pause.overline")).fieldLabel(Trace.Colors.stamp)
                Text(L10n.t("pause.title")).font(Trace.Fonts.nameLarge).foregroundStyle(Trace.Colors.ink)
            }
            .padding(.horizontal, 28)
            .padding(.vertical, 22)
            .paper(Trace.Colors.noteYellow, lifted: true)
            .overlay(alignment: .top) { Tape().offset(y: -8) }
            .rotationEffect(.degrees(-2))
        }
    }
}
#endif
