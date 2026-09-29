#if os(iOS)
import SwiftUI
import CaseEngine

// MARK: - Carnet (UX V3 §4, §6-06 → 09)

/// Where the Carnet opens: on a piece's detail, or on a new connection starting from a piece.
enum NotebookFocus: Equatable {
    case piece(ItemRef)
    case connect(ItemRef)
}

/// The Carnet (UX V3 §4, §6-06 → 09): a full-screen pushed screen (the shell presents it).
/// « ‹ Téléphone », the title and the running timer; four tabs with their counters — Pièces,
/// Suspects (Déclaration in ALIBI), Chronologie, Connexions; at the bottom « Conclure l'enquête ».
/// Concluding is always possible (owner decision): an outlined button while fewer than three pieces
/// are linked to someone with a reading, the primary button from three; an empty file asks first.
/// It only holds what the player filed and decided — never a verdict, never whether a link is right.
struct NotebookView: View {
    let session: GameSession
    var focus: NotebookFocus? = nil
    let onBack: () -> Void
    let onConclude: () -> Void

    @State private var page: Page = .pieces
    /// The last tab change went to a tab further right (the new page slides in from the right).
    @State private var forward = true
    @State private var sheet: NotebookSheet?
    @State private var showingHints = false
    /// « Conclure quand même » was confirmed: conclude once its sheet is gone.
    @State private var concludeAfterSheet = false
    @State private var typeFilter: PieceFamily?
    /// The link just drawn (it draws itself once, §8 « Connexion créée »).
    @State private var fresh: FreshLink?
    @State private var focusApplied: NotebookFocus?
    @Environment(\.dynamicTypeSize) private var typeSize
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @AppStorage(Preferences.reduceMotionKey) private var appReduceMotion = false

    /// From this many pieces linked with a reading, CONCLURE becomes the primary button.
    private static let solidFile = 3

    /// The tabs, in display order (their identifiers are « notebook.tab.<index> »).
    enum Page: Int, CaseIterable {
        case pieces, suspects, chronology, connections
    }

    enum NotebookSheet: Identifiable {
        case piece(ItemRef)
        case suspect(SuspectID)
        case builder(BuilderStart)
        case dossier
        case concludeEmpty

        var id: String {
            switch self {
            case .piece(let ref): "piece.\(ref)"
            case .suspect(let id): "suspect.\(id)"
            case .builder(let start): "builder.\(start.extending ?? 0).\(start.first.map { "\($0)" } ?? "-")"
            case .dossier: "dossier"
            case .concludeEmpty: "concludeEmpty"
            }
        }
    }

    struct FreshLink: Equatable {
        let connectionID: Int
        let link: Int
    }

    /// A filed piece and its number (filing order).
    private struct PieceRow: Identifiable {
        let entry: NotebookEntry
        let number: Int
        var id: ItemRef { entry.ref }
    }

    private var reduceMotion: Bool { systemReduceMotion || appReduceMotion }
    /// Changes that reflow the page (a piece removed, a filter): a fade with reduced motion.
    private var layoutMotion: Animation { reduceMotion ? .easeInOut(duration: 0.2) : Trace.Motion.paper }
    private var isAlibi: Bool { session.caseFile.isAlibi }

    var body: some View {
        let game = session.game
        VStack(spacing: 0) {
            topBar
            tabs(game)
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
            ZStack(alignment: .top) {
                pageView(page, game: game)
                    .id(page)
                    .transition(pageTransition)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .clipped()
            .simultaneousGesture(swipe)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) { footer(game) }
        .background(Trace.Colors.bg.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .accessibilityHidden(showingHints)
        .overlay { hintsLayer }
        .sheet(item: $sheet, onDismiss: {
            if concludeAfterSheet {
                concludeAfterSheet = false
                onConclude()
            }
        }, content: { which in
            sheetContent(which)
                .environment(\.caseNumber, session.caseFile.number)
        })
        .environment(\.caseNumber, session.caseFile.number)
        .onAppear { apply(focus) }
        .onChange(of: focus) { _, newFocus in apply(newFocus) }
    }

    // MARK: Top bar

    /// « ‹ Téléphone » and the timer; then the title, « Dossier » and « Indice ».
    private var topBar: some View {
        let large = typeSize.isAccessibilitySize
        let titleLayout = large
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 4))
            : AnyLayout(HStackLayout(alignment: .center, spacing: 12))
        return VStack(alignment: .leading, spacing: 2) {
            HStack(alignment: .center) {
                BackLink(title: L10n.t("carnet.back"), identifier: "notebook.close", action: onBack)
                Spacer(minLength: 8)
                NotebookTimer(session: session)
            }
            titleLayout {
                Text(L10n.t("carnet.title"))
                    .font(Trace.Fonts.title)
                    .foregroundStyle(Trace.Colors.text)
                    .accessibilityAddTraits(.isHeader)
                    .accessibilityIdentifier("notebook.title")
                if !large { Spacer(minLength: 8) }
                HStack(spacing: 18) {
                    dossierLink
                    hintLink
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 4)
        .padding(.bottom, 12)
    }

    /// « Dossier »: the objective and the context stay one tap away (the briefing's text).
    private var dossierLink: some View {
        Button {
            sheet = .dossier
            Haptics.selection()
        } label: {
            Label(L10n.t("carnet.dossierLink"), systemImage: "folder")
        }
        .buttonStyle(TextLinkStyle())
        .lineLimit(1)
        .accessibilityIdentifier("notebook.dossier")
    }

    /// « Indice »: screen 14.
    private var hintLink: some View {
        Button {
            showingHints = true
            Haptics.selection()
        } label: {
            Label(L10n.t("carnet.hint"), systemImage: "lightbulb")
        }
        .buttonStyle(TextLinkStyle())
        .lineLimit(1)
        .accessibilityIdentifier("notebook.hint")
    }

    // MARK: Tabs (NotebookTab, §5)

    private func tabs(_ game: Investigation) -> some View {
        let dated = game.notebook.filter { ItemDescriber.describe($0.ref, in: game).at != nil }.count
        return DividerTabs(tabs: [(Page.pieces, L10n.t("carnet.piecesTab")),
                                  (Page.suspects, L10n.t(isAlibi ? "alibi.tab.claim" : "carnet.suspects")),
                                  (Page.chronology, L10n.t("carnet.timeline")),
                                  (Page.connections, L10n.t("carnet.connectionsTab"))],
                           selection: pageBinding,
                           identifier: "notebook.tab",
                           counts: [game.notebook.count, isAlibi ? nil : session.caseFile.suspects.count,
                                    dated, game.connections.count])
    }

    /// The selection, remembering the direction of the change (the content follows it, §8).
    private var pageBinding: Binding<Page> {
        Binding(get: { page }, set: { newPage in
            forward = newPage.rawValue >= page.rawValue
            page = newPage
        })
    }

    /// 250 ms spring: the new page slides in from the side of its tab (a fade with reduced motion).
    private var pageTransition: AnyTransition {
        if reduceMotion { return .opacity }
        return .asymmetric(insertion: .move(edge: forward ? .trailing : .leading).combined(with: .opacity),
                           removal: .opacity)
    }

    /// A horizontal swipe changes tab (the tabs above are the tap equivalent, §9).
    private var swipe: some Gesture {
        DragGesture(minimumDistance: 24)
            .onEnded { value in
                let dx = value.translation.width
                // A drag from the left edge is the shell's « ‹ Téléphone » gesture.
                guard value.startLocation.x > 30, abs(dx) > 60, abs(dx) > abs(value.translation.height) * 1.5,
                      let target = Page(rawValue: page.rawValue + (dx < 0 ? 1 : -1)) else { return }
                withAnimation(reduceMotion ? .easeInOut(duration: 0.2) : Trace.Motion.tab) { pageBinding.wrappedValue = target }
                Haptics.selection()
            }
    }

    @ViewBuilder
    private func pageView(_ page: Page, game: Investigation) -> some View {
        switch page {
        case .pieces: piecesPage(game)
        case .suspects: suspectsPage(game)
        case .chronology: chronologyPage(game)
        case .connections: connectionsPage(game)
        }
    }

    // MARK: Conclusion access (§4, owner decision)

    /// « Conclure l'enquête », fixed at the bottom: always enabled; outlined under three pieces
    /// linked with a reading, the primary button from three.
    private func footer(_ game: Investigation) -> some View {
        let linked = game.notebook.filter { $0.linkedTo != nil && $0.stance != nil }.count
        return Button(L10n.t("carnet.conclude")) { conclude(game) }
            .buttonStyle(CTAButtonStyle(kind: linked >= Self.solidFile ? .primary : .outline))
            .accessibilityIdentifier("notebook.accuse")
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 8)
            .frame(maxWidth: .infinity)
            .background(Trace.Colors.bg.ignoresSafeArea(edges: .bottom))
            .overlay(alignment: .top) { Rectangle().fill(Trace.Colors.line).frame(height: 1) }
    }

    private func conclude(_ game: Investigation) {
        if game.notebook.isEmpty {
            sheet = .concludeEmpty
        } else {
            onConclude()
        }
    }

    // MARK: 07 · Pièces

    private func piecesPage(_ game: Investigation) -> some View {
        let all = game.notebook.enumerated().map { PieceRow(entry: $0.element, number: $0.offset + 1) }.reversed()
        let families = PieceFamily.allCases.filter { family in game.notebook.contains { PieceFamily.of($0.ref.kind) == family } }
        let active = typeFilter.flatMap { families.contains($0) ? $0 : nil }
        let rows = all.filter { active == nil || PieceFamily.of($0.entry.ref.kind) == active }
        return ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                if isAlibi { goalStrip(game) }
                if game.notebook.isEmpty {
                    emptyPieces
                } else {
                    if game.notebook.count > 6 && families.count > 1 {
                        filterBar(families, active: active)
                    }
                    ForEach(rows) { row in
                        pieceCard(row, game: game)
                            .transition(.opacity)
                    }
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    /// Filter pills by type (more than six pieces): Tous, Messages, Photos, Appels…
    private func filterBar(_ families: [PieceFamily], active: PieceFamily?) -> some View {
        FlowLayout(spacing: 8) {
            pill(L10n.t("carnet.filter.all"), on: active == nil, identifier: "notebook.filter.all") { typeFilter = nil }
            ForEach(families, id: \.self) { family in
                pill(family.title, on: active == family, identifier: "notebook.filter.\(family.rawValue)") { typeFilter = family }
            }
        }
    }

    private func pill(_ title: String, on: Bool, identifier: String, action: @escaping () -> Void) -> some View {
        Button {
            withAnimation(layoutMotion) { action() }
            Haptics.selection()
        } label: {
            Text(title)
                .font(Trace.Fonts.caption.weight(.semibold))
                .foregroundStyle(on ? Trace.Colors.benText : Trace.Colors.text2)
                .lineLimit(1)
                .padding(.horizontal, 14)
                .frame(minHeight: 32)
                .background(Capsule().fill(on ? Trace.Colors.tint(Trace.Colors.ben) : Trace.Colors.surface2))
                .overlay(Capsule().strokeBorder(on ? Trace.Colors.ben : Color.clear, lineWidth: 1.5))
                .frame(minHeight: Trace.Height.hit)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(on ? .isSelected : [])
        .accessibilityIdentifier(identifier)
    }

    /// ALIBI: the statement to check stays in sight above the pieces.
    private func goalStrip(_ game: Investigation) -> some View {
        let file = session.caseFile
        return VStack(alignment: .leading, spacing: 6) {
            SectionHeader(title: L10n.t("alibi.claimLabel"))
            Text(file.claim.map { AlibiText.claimLine($0, game: game) } ?? file.objective)
                .font(Trace.Fonts.body.weight(.semibold))
                .foregroundStyle(Trace.Colors.text)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .benCard()
        .overlay(alignment: .leading) { Rectangle().fill(Trace.Colors.ben).frame(width: 3) }
        .clipShape(RoundedRectangle(cornerRadius: Trace.Radius.card, style: .continuous))
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("notebook.goal")
    }

    /// §6-13: no piece yet.
    private var emptyPieces: some View {
        VStack(alignment: .leading, spacing: 8) {
            EmptyPage(title: L10n.t("carnet.noPieces.title"), tip: L10n.t("carnet.noPieces.body"))
            Button(L10n.t("carnet.openPhone"), action: onBack)
                .buttonStyle(CTAButtonStyle(kind: .primary))
                .accessibilityIdentifier("notebook.backToPhone")
        }
    }

    /// EvidenceCard + its links line + « L'accuse / Le disculpe ». Tap: the piece's detail.
    private func pieceCard(_ row: PieceRow, game: Investigation) -> some View {
        let entry = row.entry
        let against = game.contradicted(by: entry.ref)
        let badge = against.first.map { L10n.f("chrono.contradicts", ConnectionFormat.tag($0, in: game)) }
        return EvidenceCard(ref: entry.ref, game: game, mark: against.isEmpty ? .plain : .contradiction, badge: badge,
                            onOpen: {
                                sheet = .piece(entry.ref)
                                Haptics.selection()
                            }) {
            VStack(alignment: .leading, spacing: 10) {
                NotebookLinks(entry: entry, game: game, alibi: isAlibi)
                StancePicker(session: session, entry: entry,
                             accusesID: "notebook.accuses.\(row.number)",
                             clearsID: "notebook.clears.\(row.number)",
                             chipPrefix: "notebook.suspectChip")
            }
        }
        .contextMenu {
            Button { startConnection(from: entry.ref) } label: {
                Label(L10n.t("carnet.link"), systemImage: "link")
            }
            Button(role: .destructive) { remove(entry.ref) } label: {
                Label(L10n.t("pin.remove"), systemImage: "trash")
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("notebook.piece.\(row.number)")
    }

    private func remove(_ ref: ItemRef) {
        withAnimation(layoutMotion) { session.togglePin(ref) }
    }

    // MARK: 06 · Suspects

    private func suspectsPage(_ game: Investigation) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                if isAlibi {
                    claimPage(game)
                } else {
                    ForEach(session.caseFile.suspects) { suspect in
                        let linked = game.linkedEntries(for: suspect.id)
                        Button {
                            sheet = .suspect(suspect.id)
                            Haptics.selection()
                        } label: {
                            SuspectCard(suspect: suspect, contact: game.contact(suspect.contact),
                                        against: linked.filter { $0.stance == .incriminates }.count,
                                        favour: linked.filter { $0.stance == .clears }.count,
                                        pieces: linked.count)
                        }
                        .buttonStyle(PressableStyle())
                        .accessibilityIdentifier("notebook.suspect.\(suspect.id)")
                    }
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    /// ALIBI: the statement to check, and how many filed pieces the player said confirm or contradict it.
    private func claimPage(_ game: Investigation) -> some View {
        let person = session.caseFile.suspects.first
        let linked = person.map { game.linkedEntries(for: $0.id) } ?? []
        return VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: L10n.t("alibi.claimLabel"))
            if let claim = session.caseFile.claim {
                Text(game.name(of: claim.person))
                    .font(Trace.Fonts.headline)
                    .foregroundStyle(Trace.Colors.text)
                    .accessibilityAddTraits(.isHeader)
                Text(claim.statement)
                    .font(Trace.Fonts.quote)
                    .foregroundStyle(Trace.Colors.text)
                    .fixedSize(horizontal: false, vertical: true)
                VStack(alignment: .leading, spacing: 0) {
                    FieldRow(label: L10n.t("alibi.placeLabel"), value: claim.place)
                    FieldRow(label: L10n.t("alibi.windowLabel"), value: AlibiText.window(claim), divider: false)
                }
            }
            FlowLayout(spacing: 16) {
                Text(verbatim: "↑ \(linked.filter { $0.stance == .incriminates }.count) " + L10n.t("alibi.tallyContradicts"))
                    .foregroundStyle(Trace.Colors.criticalOnDark)
                Text(verbatim: "↓ \(linked.filter { $0.stance == .clears }.count) " + L10n.t("alibi.tallyConfirms"))
                    .foregroundStyle(Trace.Colors.successText)
            }
            .font(Trace.Fonts.data)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .benCard()
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("notebook.claim")
    }

    // MARK: 08 · Chronologie

    private func chronologyPage(_ game: Investigation) -> some View {
        ScrollView {
            ChronologySheet(game: game, declarations: declarations(game), onOpen: { ref in
                sheet = .piece(ref)
                Haptics.selection()
            })
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    /// What each person declared (their alibi): the ALIBI claim has its time window; a suspect's
    /// statement has none (it is listed first).
    private func declarations(_ game: Investigation) -> [ChronologySheet.Declaration] {
        if let claim = session.caseFile.claim {
            return [ChronologySheet.Declaration(id: "claim", who: NotebookText.firstName(game.name(of: claim.person)),
                                                text: claim.statement, at: claim.from)]
        }
        return session.caseFile.suspects.map { suspect in
            ChronologySheet.Declaration(id: suspect.id, who: game.name(of: suspect.contact), text: suspect.statement)
        }
    }

    // MARK: 09 · Connexions

    private func connectionsPage(_ game: Investigation) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                if game.connections.isEmpty {
                    EmptyPage(title: L10n.t("connection.emptyTitle"), tip: L10n.t("connection.emptyBody"))
                        .accessibilityIdentifier("notebook.connection.empty")
                    if game.notebook.count >= 2 { newConnectionButton }
                } else {
                    newConnectionButton
                    ForEach(Array(game.connections.enumerated()), id: \.element.id) { offset, connection in
                        ConnectionChain(connection: connection, number: offset + 1, game: game,
                                        drawLink: fresh?.connectionID == connection.id ? fresh?.link : nil,
                                        onOpenPiece: { ref in sheet = .piece(ref) },
                                        onAdd: addAction(for: connection, game: game),
                                        onDelete: { deleteConnection(connection.id) })
                            .transition(.opacity)
                            .accessibilityElement(children: .contain)
                            .accessibilityIdentifier("notebook.connection.\(connection.id)")
                    }
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var newConnectionButton: some View {
        Button {
            sheet = .builder(BuilderStart(extending: nil, first: nil))
            Haptics.selection()
        } label: {
            Label(L10n.t("connection.new"), systemImage: "plus")
        }
        .buttonStyle(CTAButtonStyle(kind: .outline))
        .accessibilityIdentifier("notebook.connection.new")
    }

    /// « + Ajouter un élément », when something is left to add: a person or a filed piece not in the chain yet.
    private func addAction(for connection: Connection, game: Investigation) -> (() -> Void)? {
        guard session.caseFile.suspects.count + game.notebook.count > connection.nodes.count else { return nil }
        return { sheet = .builder(BuilderStart(extending: connection.id, first: nil)) }
    }

    private func startConnection(from ref: ItemRef) {
        page = .connections
        sheet = .builder(BuilderStart(extending: nil, first: .piece(ref)))
    }

    private func deleteConnection(_ id: Int) {
        withAnimation(layoutMotion) { session.perform { $0.removeConnection(id) } }
        if fresh?.connectionID == id { fresh = nil }
        Haptics.selection()
    }

    /// The builder's last step: the chain is drawn (or extended), then shown drawing itself.
    private func finish(_ result: ConnectionBuilderSheet.Result) {
        switch result {
        case .connect(let first, let second, let verb):
            var made: Connection?
            session.perform { made = $0.connect(first, second, verb: verb) }
            if let made { fresh = FreshLink(connectionID: made.id, link: 0) }
        case .extend(let id, let node, let verb):
            var extended = false
            session.perform { extended = $0.extend(id, with: node, verb: verb) }
            if extended, let chain = session.game.connections.first(where: { $0.id == id }) {
                fresh = FreshLink(connectionID: id, link: chain.verbs.count - 1)
            }
        }
        Haptics.light()
        page = .connections
        sheet = nil
    }

    // MARK: Focus

    /// `.piece`: Pièces with that piece's detail; `.connect`: Connexions, a new chain from that piece.
    private func apply(_ focus: NotebookFocus?) {
        guard let focus else {
            focusApplied = nil
            return
        }
        guard focus != focusApplied else { return }
        focusApplied = focus
        switch focus {
        case .piece(let ref):
            page = .pieces
            guard session.isPinned(ref) else { return }
            present(.piece(ref))
        case .connect(let ref):
            page = .connections
            guard session.isPinned(ref) else { return }
            present(.builder(BuilderStart(extending: nil, first: .piece(ref))))
        }
    }

    /// A sheet asked for as the Carnet arrives: after its push.
    private func present(_ which: NotebookSheet) {
        Task {
            try? await Task.sleep(for: .milliseconds(400))
            sheet = which
        }
    }

    // MARK: Sheets

    @ViewBuilder
    private func sheetContent(_ which: NotebookSheet) -> some View {
        switch which {
        case .piece(let ref):
            PieceDetailSheet(session: session, ref: ref,
                             onLink: { startConnection(from: ref) },
                             onRemove: {
                                 sheet = nil
                                 remove(ref)
                             },
                             onClose: { sheet = nil })
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(Trace.Radius.sheet)
                .presentationBackground(Trace.Colors.surface)
        case .suspect(let id):
            SuspectFileView(suspectID: id, session: session,
                            onOpenInPhone: { app, route in
                                sheet = nil
                                onBack()
                                session.launch(app, then: route)
                            },
                            onClose: { sheet = nil })
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(Trace.Radius.sheet)
                .presentationBackground(Trace.Colors.bg)
        case .builder(let start):
            ConnectionBuilderSheet(session: session, start: start, onDone: { finish($0) }, onCancel: { sheet = nil })
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(Trace.Radius.sheet)
                .presentationBackground(Trace.Colors.bg)
        case .dossier:
            CaseBriefSheet(caseFile: session.caseFile) { sheet = nil }
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
                .presentationCornerRadius(Trace.Radius.sheet)
                .presentationBackground(Trace.Colors.surface)
        case .concludeEmpty:
            PaperConfirmSheet(title: L10n.t("carnet.emptyTitle"),
                              message: L10n.t("carnet.concludeAnyway"),
                              confirm: L10n.t("carnet.concludeConfirm"),
                              confirmID: "notebook.concludeAnyway",
                              cancel: L10n.t("common.back"),
                              cancelID: "notebook.concludeBack",
                              onConfirm: {
                                  concludeAfterSheet = true
                                  sheet = nil
                              },
                              onCancel: { sheet = nil })
                .presentationDetents(confirmDetents)
                .presentationCornerRadius(Trace.Radius.sheet)
                .presentationBackground(Trace.Colors.surface)
        }
    }

    private var confirmDetents: Set<PresentationDetent> {
        if typeSize.isAccessibilitySize { return [.large] }
        return typeSize > .large ? [.medium] : [.height(300)]
    }

    // MARK: 14 · Indice

    /// Screen 14 over a veil (opaque with Reduce Transparency): the veil fades, the sheet rises
    /// (y 24 → 0 + opacity; opacity only with reduced motion).
    private var hintsLayer: some View {
        ZStack(alignment: .bottom) {
            if showingHints {
                (reduceTransparency ? Trace.Colors.bgDeep : Trace.Colors.bgDeep.opacity(0.6))
                    .ignoresSafeArea()
                    .contentShape(Rectangle())
                    .onTapGesture { showingHints = false }
                    .accessibilityHidden(true)
                    .transition(.opacity)
            }
            if showingHints {
                HintsView(session: session, onClose: { showingHints = false })
                    .transition(reduceMotion ? AnyTransition.opacity : AnyTransition.opacity.combined(with: .offset(y: 24)))
            }
        }
        .animation(reduceMotion ? .easeInOut(duration: 0.2) : Trace.Motion.sheet, value: showingHints)
    }
}

/// Where a new link of a connection starts: a chain to extend, or a first element already chosen.
struct BuilderStart: Equatable {
    var extending: Int?
    var first: Connection.Node?
}

/// The Carnet's timer, top right: Plex Mono, warning under 01:00, critical under 00:10 (same rules
/// as the investigation bar). Its own view, so only it redraws on every tick.
private struct NotebookTimer: View {
    let session: GameSession

    var body: some View {
        let remaining = session.remainingSeconds
        let level = session.timerLevel
        Text(PhoneFormat.countdown(remaining))
            .font(Trace.Fonts.dataLarge)
            .monospacedDigit()
            .foregroundStyle(color(level))
            .animation(.easeInOut(duration: 0.3), value: level)
            .accessibilityLabel(Text(L10n.f("a11y.timer", SpokenDuration.text(remaining))))
            .accessibilityValue(Text(PhoneFormat.countdown(remaining)))
            .accessibilityIdentifier("notebook.timer")
    }

    private func color(_ level: GameSession.TimerLevel) -> Color {
        switch level {
        case .normal: Trace.Colors.text
        case .low: Trace.Colors.warning
        case .critical: Trace.Colors.criticalOnDark
        }
    }
}

/// The Carnet's words for a link: « L'accuse », « L'accuse : Lucas », first names.
private enum NotebookText {
    /// « L'accuse » / « Le disculpe » — in ALIBI mode « Contredit » / « Confirme » (the statement).
    static func stance(_ stance: NotebookEntry.Stance, alibi: Bool = false) -> String {
        if alibi { return L10n.t(stance == .incriminates ? "alibi.stanceContradicts" : "alibi.stanceConfirms") }
        return L10n.t(stance == .incriminates ? "suspect.stanceAgainst" : "suspect.stanceFavour")
    }

    static func link(_ stance: NotebookEntry.Stance, name: String, alibi: Bool = false) -> String {
        if alibi { return L10n.t(stance == .incriminates ? "alibi.linkContradicts" : "alibi.linkConfirms") }
        return L10n.f(stance == .incriminates ? "carnet.linkAccuses" : "carnet.linkClears", name)
    }

    /// « Lucas » from « Lucas Ferrand ».
    static func firstName(_ name: String) -> String {
        name.split(separator: " ").first.map(String.init) ?? name
    }
}

/// The links line of a piece (§5 EvidenceCard): « ↑ L'accuse : Emma », « Reliée : Connexion 1, 3 ».
private struct NotebookLinks: View {
    let entry: NotebookEntry
    let game: Investigation
    let alibi: Bool

    var body: some View {
        let numbers = game.connectionNumbers(containing: .piece(entry.ref))
        let suspect = entry.linkedTo.flatMap { game.index.suspect($0) }
        if suspect != nil || !numbers.isEmpty {
            VStack(alignment: .leading, spacing: 4) {
                if let suspect {
                    let name = NotebookText.firstName(game.name(of: suspect.contact))
                    if let stance = entry.stance {
                        HStack(alignment: .firstTextBaseline, spacing: 6) {
                            Text(verbatim: LinkTally.glyph(stance)).foregroundStyle(LinkTally.color(stance))
                            Text(NotebookText.link(stance, name: name, alibi: alibi)).foregroundStyle(Trace.Colors.text)
                        }
                        .font(Trace.Fonts.caption.weight(.semibold))
                    } else {
                        Text(L10n.f("toast.linked", name)).font(Trace.Fonts.caption).foregroundStyle(Trace.Colors.text2)
                    }
                }
                if !numbers.isEmpty {
                    Text(L10n.f("carnet.inConnections", numbers.map { L10n.f("connection.short", $0) }.joined(separator: ", ")))
                        .font(Trace.Fonts.caption)
                        .foregroundStyle(Trace.Colors.benText)
                }
            }
            .fixedSize(horizontal: false, vertical: true)
            .accessibilityElement(children: .combine)
        }
    }
}

/// [↑ L'accuse] [↓ Le disculpe] on a piece, then « Quel suspect ? » and one chip per suspect (the
/// engine links a piece to one person; the same again undoes it). ALIBI: one person, one tap.
private struct StancePicker: View {
    let session: GameSession
    let entry: NotebookEntry
    let accusesID: String
    let clearsID: String
    let chipPrefix: String

    @State private var open: NotebookEntry.Stance?
    @Environment(\.dynamicTypeSize) private var typeSize
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    @AppStorage(Preferences.reduceMotionKey) private var appReduceMotion = false

    private var motion: Animation { systemReduceMotion || appReduceMotion ? .easeInOut(duration: 0.2) : Trace.Motion.paper }

    var body: some View {
        let alibi = session.caseFile.isAlibi
        let layout = typeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 8))
            : AnyLayout(HStackLayout(spacing: 8))
        VStack(alignment: .leading, spacing: 10) {
            layout {
                button(.incriminates, alibi: alibi)
                    .accessibilityIdentifier(accusesID)
                button(.clears, alibi: alibi)
                    .accessibilityIdentifier(clearsID)
            }
            if let open, !alibi {
                chips(open)
                    .transition(.opacity)
            }
        }
    }

    private func button(_ stance: NotebookEntry.Stance, alibi: Bool) -> some View {
        let set = entry.linkedTo != nil && entry.stance == stance
        let isOpen = open == stance
        return Button {
            if alibi, let person = session.caseFile.suspects.first {
                // One person: the reading is the link (same again = undo).
                withAnimation(motion) { session.annotate(entry.ref, suspect: person.id, stance: stance) }
            } else {
                withAnimation(motion) { open = isOpen ? nil : stance }
            }
            Haptics.selection()
        } label: {
            Text(LinkTally.glyph(stance) + " " + NotebookText.stance(stance, alibi: alibi))
        }
        .buttonStyle(StanceButtonStyle(stance: stance, filled: set, open: isOpen))
        .accessibilityAddTraits(set ? .isSelected : [])
        .accessibilityValue(Text(isOpen ? L10n.t("carnet.pickSuspect") : ""))
    }

    private func chips(_ stance: NotebookEntry.Stance) -> some View {
        let game = session.game
        return VStack(alignment: .leading, spacing: 8) {
            Text(L10n.t("carnet.pickSuspect"))
                .font(Trace.Fonts.caption)
                .foregroundStyle(Trace.Colors.text2)
            FlowLayout(spacing: 8) {
                ForEach(session.caseFile.suspects) { candidate in
                    let chosen = entry.linkedTo == candidate.id && entry.stance == stance
                    Button {
                        withAnimation(motion) {
                            session.annotate(entry.ref, suspect: candidate.id, stance: stance)
                            open = nil
                        }
                    } label: {
                        Text((chosen ? "✓ " : "") + NotebookText.firstName(game.name(of: candidate.contact)))
                    }
                    .buttonStyle(SuspectChipStyle(stance: stance, chosen: chosen))
                    .accessibilityAddTraits(chosen ? .isSelected : [])
                    .accessibilityIdentifier("\(chipPrefix).\(candidate.id)")
                }
            }
        }
    }
}

/// [↑ L'accuse] / [↓ Le disculpe]: `surface2`; once set, the reading's colour at 16 % with its
/// word and glyph; a 2 pt ben rule while its suspect chips are open (selected).
private struct StanceButtonStyle: ButtonStyle {
    let stance: NotebookEntry.Stance
    let filled: Bool
    let open: Bool

    func makeBody(configuration: Configuration) -> some View {
        let shape = RoundedRectangle(cornerRadius: Trace.Radius.segmented, style: .continuous)
        let color = stance == .incriminates ? Trace.Colors.critical : Trace.Colors.success
        let fill = filled ? Trace.Colors.tint(color) : (configuration.isPressed ? Trace.Colors.surface3 : Trace.Colors.surface2)
        let border = open ? Trace.Colors.ben : (filled ? color.opacity(0.6) : Color.clear)
        return configuration.label
            .font(Trace.Fonts.monoStrong)
            .lineLimit(1)
            .minimumScaleFactor(0.8)
            .foregroundStyle(filled ? LinkTally.color(stance) : Trace.Colors.text)
            .padding(.horizontal, 14)
            .frame(maxWidth: .infinity, minHeight: Trace.Height.hit)
            .background(shape.fill(fill))
            .overlay(shape.strokeBorder(border, lineWidth: open ? 2 : 1))
            .contentShape(shape)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.09), value: configuration.isPressed)
    }
}

/// A suspect's first name on a pill; tinted with the reading when this piece is linked to them that way.
private struct SuspectChipStyle: ButtonStyle {
    let stance: NotebookEntry.Stance
    let chosen: Bool

    func makeBody(configuration: Configuration) -> some View {
        let color = stance == .incriminates ? Trace.Colors.critical : Trace.Colors.success
        return configuration.label
            .font(Trace.Fonts.monoStrong)
            .lineLimit(1)
            .foregroundStyle(chosen ? LinkTally.color(stance) : Trace.Colors.text)
            .padding(.horizontal, 16)
            .frame(minHeight: Trace.Height.hit)
            .background(Capsule().fill(chosen ? Trace.Colors.tint(color) : (configuration.isPressed ? Trace.Colors.surface3 : Trace.Colors.surface2)))
            .overlay(Capsule().strokeBorder(chosen ? color.opacity(0.6) : Trace.Colors.line, lineWidth: 1))
            .contentShape(Capsule())
    }
}

/// The close cross of a sheet (44 pt).
private struct SheetCloseButton: View {
    let identifier: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "xmark")
                .font(Trace.Fonts.callout.weight(.semibold))
                .foregroundStyle(Trace.Colors.text2)
                .frame(width: Trace.Height.hit, height: Trace.Height.hit)
                .background(Circle().fill(Trace.Colors.surface2).padding(6))
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(L10n.t("a11y.close")))
        .accessibilityIdentifier(identifier)
    }
}

// MARK: - Piece detail (§6-07 « Tap → détail »)

/// A filed piece in full: « PIÈCE nn », « type · source », what it shows, its links, « L'accuse /
/// Le disculpe », [Relier] (a new connection from it) and « Retirer du dossier ».
private struct PieceDetailSheet: View {
    let session: GameSession
    let ref: ItemRef
    let onLink: () -> Void
    let onRemove: () -> Void
    let onClose: () -> Void

    var body: some View {
        let game = session.game
        ScrollView {
            if let entry = game.notebook.first(where: { $0.ref == ref }), let number = game.pieceNumber(of: ref) {
                let against = game.contradicted(by: ref)
                VStack(alignment: .leading, spacing: 16) {
                    HStack(alignment: .center) {
                        Text(PieceFormat.title(number))
                            .font(Trace.Fonts.data)
                            .foregroundStyle(Trace.Colors.benText)
                            .accessibilityAddTraits(.isHeader)
                            .accessibilityIdentifier("piece.detail.title")
                        Spacer(minLength: 8)
                        SheetCloseButton(identifier: "piece.detail.close", action: onClose)
                    }
                    Text(PieceFormat.caption(ref, in: game))
                        .font(Trace.Fonts.caption)
                        .foregroundStyle(Trace.Colors.text2)
                        .fixedSize(horizontal: false, vertical: true)
                    ExhibitSupport(ref: ref, game: game, compact: false)
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(RoundedRectangle(cornerRadius: Trace.Radius.node, style: .continuous).fill(Trace.Colors.surface2))
                        .accessibilityElement(children: .combine)
                    if !against.isEmpty {
                        Text(against.map { L10n.f("chrono.contradicts", ConnectionFormat.tag($0, in: game)) }.joined(separator: " · "))
                            .font(Trace.Fonts.caption.weight(.semibold))
                            .foregroundStyle(Trace.Colors.warning)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    NotebookLinks(entry: entry, game: game, alibi: session.caseFile.isAlibi)
                    VStack(alignment: .leading, spacing: 0) {
                        SectionHeader(title: L10n.t("carnet.thisPiece"))
                        StancePicker(session: session, entry: entry,
                                     accusesID: "piece.detail.accuses",
                                     clearsID: "piece.detail.clears",
                                     chipPrefix: "piece.detail.suspectChip")
                    }
                    Button(action: onLink) {
                        Label(L10n.t("carnet.link"), systemImage: "link")
                    }
                    .buttonStyle(CTAButtonStyle(kind: .outline))
                    .accessibilityIdentifier("piece.detail.link")
                    Button(action: onRemove) {
                        Text(L10n.t("pin.remove"))
                            .font(Trace.Fonts.link)
                            .foregroundStyle(Trace.Colors.criticalOnDark)
                            .frame(maxWidth: .infinity, minHeight: Trace.Height.hit)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("piece.detail.remove")
                }
                .padding(20)
            }
        }
        .background(Trace.Colors.surface.ignoresSafeArea())
    }
}

// MARK: - New connection (§6-09)

/// « Choisissez le premier élément » → « Choisissez le second » → « Quel est le lien ? » (five
/// verbs). Extending a chain: the element to add, then the verb. Elements: the people of the case
/// and the filed pieces. It never suggests which link is right.
private struct ConnectionBuilderSheet: View {
    enum Result {
        case connect(Connection.Node, Connection.Node, Connection.Verb)
        case extend(Int, Connection.Node, Connection.Verb)
    }

    private enum Step { case first, second, verb }

    let session: GameSession
    let start: BuilderStart
    let onDone: (Result) -> Void
    let onCancel: () -> Void

    @State private var first: Connection.Node?
    @State private var second: Connection.Node?
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    @AppStorage(Preferences.reduceMotionKey) private var appReduceMotion = false

    init(session: GameSession, start: BuilderStart, onDone: @escaping (Result) -> Void, onCancel: @escaping () -> Void) {
        self.session = session
        self.start = start
        self.onDone = onDone
        self.onCancel = onCancel
        _first = State(initialValue: start.first)
    }

    private var motion: Animation { systemReduceMotion || appReduceMotion ? .easeInOut(duration: 0.2) : Trace.Motion.paper }

    private var chain: Connection? {
        start.extending.flatMap { id in session.game.connections.first { $0.id == id } }
    }

    /// Where the new link starts: the chain's last element, or the first element chosen.
    private var anchor: Connection.Node? { chain?.nodes.last ?? first }

    private var step: Step {
        if chain == nil && first == nil { return .first }
        return second == nil ? .second : .verb
    }

    private var canGoBack: Bool {
        switch step {
        case .first: false
        case .second: chain == nil && start.first == nil
        case .verb: true
        }
    }

    private var title: String {
        switch step {
        case .first: L10n.t("connection.pickFirst")
        case .second: L10n.t(chain == nil ? "connection.pickSecond" : "connection.pickNext")
        case .verb: L10n.t("connection.pickVerb")
        }
    }

    var body: some View {
        let game = session.game
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    if canGoBack {
                        BackLink(title: L10n.t("common.back"), identifier: "connection.back") { goBack() }
                    }
                    Spacer(minLength: 8)
                    Button(L10n.t("common.cancel"), action: onCancel)
                        .buttonStyle(TextLinkStyle())
                        .accessibilityIdentifier("connection.cancel")
                }
                Text(title)
                    .font(Trace.Fonts.title)
                    .foregroundStyle(Trace.Colors.text)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityAddTraits(.isHeader)
                    .accessibilityIdentifier("connection.step")
                if let anchor {
                    VStack(alignment: .leading, spacing: 8) {
                        nodeRow(anchor, game: game, chosen: true)
                        if let second {
                            Image(systemName: "arrow.down")
                                .font(Trace.Fonts.caption.weight(.semibold))
                                .foregroundStyle(Trace.Colors.text3)
                                .padding(.leading, 22)
                                .accessibilityHidden(true)
                            nodeRow(second, game: game, chosen: true)
                        }
                    }
                }
                if step == .verb {
                    verbs
                } else {
                    elements(game)
                }
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .animation(motion, value: step)
        }
        .background(Trace.Colors.bg.ignoresSafeArea())
    }

    private func goBack() {
        withAnimation(motion) {
            if second != nil { second = nil } else if chain == nil && start.first == nil { first = nil }
        }
    }

    /// What can still be chosen: not already in the chain (or the first element).
    private var excluded: [Connection.Node] {
        if let chain { return chain.nodes }
        return [first].compactMap { $0 }
    }

    @ViewBuilder
    private func elements(_ game: Investigation) -> some View {
        let people = session.caseFile.suspects.map { Connection.Node.person($0.id) }.filter { !excluded.contains($0) }
        let pieces = game.notebook.reversed().map { Connection.Node.piece($0.ref) }.filter { !excluded.contains($0) }
        if !people.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                SectionHeader(title: L10n.t("connection.people"))
                ForEach(people, id: \.self) { node in
                    elementButton(node, game: game)
                }
            }
        }
        if !pieces.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                SectionHeader(title: L10n.t("connection.pieces"))
                ForEach(pieces, id: \.self) { node in
                    elementButton(node, game: game)
                }
            }
        }
    }

    private func elementButton(_ node: Connection.Node, game: Investigation) -> some View {
        Button {
            withAnimation(motion) {
                if step == .first { first = node } else { second = node }
            }
            Haptics.selection()
        } label: {
            nodeRow(node, game: game, chosen: false)
        }
        .buttonStyle(PressableStyle())
        .accessibilityIdentifier(identifier(node, game: game))
    }

    private func identifier(_ node: Connection.Node, game: Investigation) -> String {
        switch node {
        case .piece(let ref): "connection.pick.piece.\(game.pieceNumber(of: ref) ?? 0)"
        case .person(let id): "connection.pick.person.\(id)"
        }
    }

    private func nodeRow(_ node: Connection.Node, game: Investigation, chosen: Bool) -> some View {
        HStack(alignment: .center, spacing: 12) {
            if case .person(let id) = node, let suspect = game.index.suspect(id) {
                IDPhoto(contact: game.contact(suspect.contact), width: 36, height: 45)
                    .accessibilityHidden(true)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(ConnectionFormat.label(node, in: game)).font(Trace.Fonts.data).foregroundStyle(Trace.Colors.benText)
                Text(ConnectionFormat.text(node, in: game))
                    .font(Trace.Fonts.callout)
                    .foregroundStyle(Trace.Colors.text)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                if case .piece(let ref) = node {
                    Text(PieceFormat.caption(ref, in: game)).font(Trace.Fonts.caption).foregroundStyle(Trace.Colors.text2).lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(12)
        .frame(maxWidth: .infinity, minHeight: Trace.Height.row, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: Trace.Radius.node, style: .continuous).fill(Trace.Colors.surface2))
        .overlay(RoundedRectangle(cornerRadius: Trace.Radius.node, style: .continuous)
            .strokeBorder(chosen ? Trace.Colors.ben : Color.clear, lineWidth: 2))
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }

    /// The five verbs: word + symbol, the colour only repeats the word.
    private var verbs: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(Connection.Verb.allCases, id: \.self) { verb in
                Button { choose(verb) } label: {
                    HStack(spacing: 12) {
                        Image(systemName: ConnectionFormat.symbol(verb))
                            .font(Trace.Fonts.headline)
                            .foregroundStyle(ConnectionFormat.color(verb))
                            .frame(width: 28)
                            .accessibilityHidden(true)
                        Text(ConnectionFormat.verb(verb))
                            .font(Trace.Fonts.headline)
                            .foregroundStyle(Trace.Colors.text)
                        Spacer(minLength: 0)
                    }
                    .padding(.horizontal, 16)
                    .frame(maxWidth: .infinity, minHeight: Trace.Height.button)
                    .background(RoundedRectangle(cornerRadius: Trace.Radius.button, style: .continuous).fill(Trace.Colors.surface2))
                    .contentShape(Rectangle())
                }
                .buttonStyle(PressableStyle())
                .accessibilityIdentifier("connection.verb.\(verb.rawValue)")
            }
        }
    }

    private func choose(_ verb: Connection.Verb) {
        guard let second else { return }
        if let chain {
            onDone(.extend(chain.id, second, verb))
        } else if let first {
            onDone(.connect(first, second, verb))
        }
    }
}

// MARK: - Dossier (objective + context)

/// « Dossier » from the Carnet: the case's objective and its context, as in the briefing.
private struct CaseBriefSheet: View {
    let caseFile: CaseFile
    let onClose: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .center) {
                    Text(fileLabel(caseFile.number))
                        .font(Trace.Fonts.data)
                        .foregroundStyle(Trace.Colors.benText)
                    Spacer(minLength: 8)
                    SheetCloseButton(identifier: "notebook.dossierClose", action: onClose)
                }
                Text(caseFile.title)
                    .font(Trace.Fonts.title)
                    .foregroundStyle(Trace.Colors.text)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityAddTraits(.isHeader)
                VStack(alignment: .leading, spacing: 6) {
                    SectionHeader(title: L10n.t("carnet.objective"))
                    Text(caseFile.objective)
                        .font(Trace.Fonts.body.weight(.semibold))
                        .foregroundStyle(Trace.Colors.text)
                        .fixedSize(horizontal: false, vertical: true)
                    if let claim = caseFile.claim {
                        Text(claim.statement)
                            .font(Trace.Fonts.quote)
                            .foregroundStyle(Trace.Colors.text)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.top, 6)
                        Text(claim.place + " · " + AlibiText.window(claim))
                            .font(Trace.Fonts.caption)
                            .foregroundStyle(Trace.Colors.text2)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Trace.Colors.surface2)
                .overlay(alignment: .leading) { Rectangle().fill(Trace.Colors.ben).frame(width: 3) }
                .clipShape(RoundedRectangle(cornerRadius: Trace.Radius.card, style: .continuous))
                .accessibilityElement(children: .combine)
                ForEach(Array(caseFile.synopsis.enumerated()), id: \.offset) { _, line in
                    Text(line)
                        .font(Trace.Fonts.body)
                        .foregroundStyle(Trace.Colors.text2)
                        .lineSpacing(4)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 16)
        }
        .background(Trace.Colors.surface.ignoresSafeArea())
    }
}

// MARK: - Checkbox, flow layout

/// A square box; a check on `ben` when ticked.
struct CheckBox: View {
    let on: Bool
    var size: CGFloat = 20

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: 5, style: .continuous)
        ZStack {
            shape.fill(on ? Trace.Colors.ben : Color.clear)
            shape.strokeBorder(on ? Trace.Colors.ben : Trace.Colors.text2, lineWidth: 1.5)
            if on {
                Image(systemName: "checkmark")
                    .font(Trace.Fonts.caption.weight(.bold))
                    .foregroundStyle(Trace.Colors.onFill)
                    .transition(.opacity)
            }
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}

/// Wraps its children onto several lines (chips, pills, badges).
struct FlowLayout: Layout {
    var spacing: CGFloat = 6

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? .infinity
        var x: CGFloat = 0, y: CGFloat = 0, line: CGFloat = 0, widest: CGFloat = 0
        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if x > 0 && x + size.width > width { y += line + spacing; x = 0; line = 0 }
            x += size.width + spacing
            line = max(line, size.height)
            widest = max(widest, x - spacing)
        }
        return CGSize(width: min(widest, width), height: y + line)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX, y = bounds.minY, line: CGFloat = 0
        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if x > bounds.minX && x + size.width > bounds.maxX { y += line + spacing; x = bounds.minX; line = 0 }
            view.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            line = max(line, size.height)
        }
    }
}

// MARK: - Suspect file

/// A suspect's file (Carnet › Suspects › tap, a sheet): photo, relation, what they declared, what
/// the seized phone holds about them (shortcuts), the pieces the player linked to them as
/// EvidenceCards with « L'accuse » / « Le disculpe », the other pieces of the file to qualify for
/// them, and the player's own notes. Nothing concludes for the player: no highlight, no ranking.
struct SuspectFileView: View {
    let suspectID: SuspectID
    let session: GameSession
    /// Opens something in the phone (closes the Carnet). nil where the phone is not reachable.
    var onOpenInPhone: ((AppID, PhoneRoute?) -> Void)? = nil
    /// Closes the sheet. nil: `dismiss()`.
    var onClose: (() -> Void)? = nil
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        let game = session.game
        if let suspect = game.index.suspect(suspectID) {
            let index = session.caseFile.suspects.firstIndex { $0.id == suspectID } ?? 0
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    header(suspect, letter: Suspect.letter(index), game: game)
                    statement(suspect)
                    identity(suspect, game: game)
                    phoneFacts(suspect, game: game)
                    linkedPieces(suspect, game: game)
                    otherPieces(suspect, game: game)
                    marks(suspect, game: game)
                }
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(Trace.Colors.bg.ignoresSafeArea())
            .environment(\.caseNumber, session.caseFile.number)
        }
    }

    private func close() {
        if let onClose { onClose() } else { dismiss() }
    }

    private func header(_ suspect: Suspect, letter: String, game: Investigation) -> some View {
        let linked = game.linkedEntries(for: suspect.id)
        let standing = SuspectStanding(against: linked.filter { $0.stance == .incriminates }.count,
                                       favour: linked.filter { $0.stance == .clears }.count)
        return VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center) {
                Text(L10n.f("suspect.fileHeader", letter)).font(Trace.Fonts.data).foregroundStyle(Trace.Colors.benText)
                Spacer(minLength: 8)
                SheetCloseButton(identifier: "suspect.close", action: close)
            }
            HStack(alignment: .top, spacing: 16) {
                IDPhoto(contact: game.contact(suspect.contact), width: 84, height: 105)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 6) {
                    Text(game.name(of: suspect.contact))
                        .font(Trace.Fonts.nameLarge)
                        .foregroundStyle(Trace.Colors.text)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityAddTraits(.isHeader)
                        .accessibilityIdentifier("suspect.name")
                    Text(([suspect.age.map { L10n.f("suspect.age", $0) }].compactMap { $0 } + [suspect.role]).joined(separator: " · "))
                        .font(Trace.Fonts.callout)
                        .foregroundStyle(Trace.Colors.text2)
                        .fixedSize(horizontal: false, vertical: true)
                    StatusBadge(text: standing.text, color: standing.color, symbol: standing.symbol)
                        .padding(.top, 4)
                }
                Spacer(minLength: 0)
            }
        }
    }

    /// « Alibi déclaré »: what they told the police, as a quote with a ben rule.
    private func statement(_ suspect: Suspect) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            SectionHeader(title: L10n.t("suspect.statementLabel"))
            Text(suspect.statement)
                .font(Trace.Fonts.quote)
                .foregroundStyle(Trace.Colors.text)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.leading, 14)
                .overlay(alignment: .leading) { Rectangle().fill(Trace.Colors.ben).frame(width: 3) }
        }
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private func identity(_ suspect: Suspect, game: Investigation) -> some View {
        let optionalRows: [(String, String)?] = [
            (L10n.t("suspect.link"), suspect.role),
            suspect.address.map { (L10n.t("suspect.address"), $0) },
            game.contact(suspect.contact).map { (L10n.t("suspect.phoneLabel"), $0.phone) },
        ]
        let rows = optionalRows.compactMap { $0 }
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(rows.enumerated()), id: \.offset) { offset, row in
                FieldRow(label: row.0, value: row.1, divider: offset < rows.count - 1)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 4)
        .benCard()
    }

    /// What the seized phone holds about this person: facts and shortcuts, never a reading.
    @ViewBuilder
    private func phoneFacts(_ suspect: Suspect, game: Investigation) -> some View {
        let conversation = game.device.conversations.first { !$0.isGroup && $0.participants == [suspect.contact] }
        let messages = conversation.map { game.visibleMessages(in: $0.id).count } ?? 0
        let calls = game.calls.filter { $0.contact == suspect.contact }.count
        VStack(alignment: .leading, spacing: 0) {
            SectionHeader(title: L10n.t("suspect.inPhone"))
            VStack(spacing: 0) {
                fact(symbol: "message", value: L10n.f("suspect.messagesCount", messages)) {
                    if let conversation { onOpenInPhone?(.messages, .conversation(conversation.id)) }
                }
                .disabled(conversation == nil || onOpenInPhone == nil)
                Rectangle().fill(Trace.Colors.line).frame(height: 1)
                fact(symbol: "phone", value: L10n.f("n.calls", calls)) {
                    onOpenInPhone?(.phone, nil)
                }
                .disabled(calls == 0 || onOpenInPhone == nil)
            }
            .padding(.horizontal, 16)
            .benCard()
            if onOpenInPhone != nil {
                Text(L10n.t("suspect.shortcutHelp"))
                    .font(Trace.Fonts.caption)
                    .foregroundStyle(Trace.Colors.text2)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 8)
            }
        }
    }

    private func fact(symbol: String, value: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: symbol)
                    .font(Trace.Fonts.callout)
                    .foregroundStyle(Trace.Colors.text2)
                    .frame(width: 22)
                    .accessibilityHidden(true)
                Text(value).font(Trace.Fonts.callout).foregroundStyle(Trace.Colors.text)
                Spacer(minLength: 0)
                if onOpenInPhone != nil {
                    Image(systemName: "chevron.right")
                        .font(Trace.Fonts.caption.weight(.semibold))
                        .foregroundStyle(Trace.Colors.text3)
                        .accessibilityHidden(true)
                }
            }
            .frame(maxWidth: .infinity, minHeight: Trace.Height.row)
            .contentShape(Rectangle())
        }
        .buttonStyle(PressableStyle())
    }

    /// PIÈCES LIÉES: the pieces the player linked to this suspect, in filing order, with their
    /// reading. [L'accuse] / [Le disculpe] switch it; the same one again unlinks the piece.
    private func linkedPieces(_ suspect: Suspect, game: Investigation) -> some View {
        let entries = game.linkedEntries(for: suspect.id)
        return VStack(alignment: .leading, spacing: 0) {
            SectionHeader(title: L10n.f("suspect.linked", entries.count))
            if entries.isEmpty {
                Text(L10n.t("suspect.noPiece")).font(Trace.Fonts.callout).foregroundStyle(Trace.Colors.text2)
            } else {
                VStack(spacing: 12) {
                    ForEach(Array(entries.enumerated()), id: \.element.ref) { offset, entry in
                        EvidenceCard(ref: entry.ref, game: game) {
                            stanceRow(entry, suspect: suspect,
                                      accusesID: "suspect.stance.incriminates.\(offset)",
                                      clearsID: "suspect.stance.clears.\(offset)")
                        }
                    }
                }
            }
        }
    }

    /// The rest of the file, to say what each piece shows about this person (the link moves here).
    @ViewBuilder
    private func otherPieces(_ suspect: Suspect, game: Investigation) -> some View {
        let others = game.notebook.filter { $0.linkedTo != suspect.id }
        if !others.isEmpty {
            VStack(alignment: .leading, spacing: 0) {
                SectionHeader(title: L10n.t("suspect.otherPieces"))
                VStack(spacing: 12) {
                    ForEach(others) { entry in
                        let number = game.pieceNumber(of: entry.ref) ?? 0
                        VStack(alignment: .leading, spacing: 8) {
                            Text(PieceFormat.title(number)).font(Trace.Fonts.data).foregroundStyle(Trace.Colors.benText)
                            Text(PieceFormat.preview(entry.ref, in: game))
                                .font(Trace.Fonts.callout)
                                .foregroundStyle(Trace.Colors.text)
                                .lineLimit(2)
                            if let other = entry.linkedTo.flatMap({ game.index.suspect($0) }), let stance = entry.stance {
                                Text(LinkTally.glyph(stance) + " " + NotebookText.link(stance, name: NotebookText.firstName(game.name(of: other.contact))))
                                    .font(Trace.Fonts.caption)
                                    .foregroundStyle(Trace.Colors.text2)
                            }
                            stanceRow(entry, suspect: suspect,
                                      accusesID: "suspect.other.incriminates.\(number)",
                                      clearsID: "suspect.other.clears.\(number)")
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .benCard()
                        .accessibilityElement(children: .contain)
                    }
                }
            }
        }
    }

    private func stanceRow(_ entry: NotebookEntry, suspect: Suspect, accusesID: String, clearsID: String) -> some View {
        HStack(spacing: 8) {
            stanceButton(.incriminates, entry: entry, suspect: suspect)
                .accessibilityIdentifier(accusesID)
            stanceButton(.clears, entry: entry, suspect: suspect)
                .accessibilityIdentifier(clearsID)
        }
    }

    private func stanceButton(_ stance: NotebookEntry.Stance, entry: NotebookEntry, suspect: Suspect) -> some View {
        let on = entry.linkedTo == suspect.id && entry.stance == stance
        return Button {
            session.annotate(entry.ref, suspect: suspect.id, stance: stance)
        } label: {
            Text(LinkTally.glyph(stance) + " " + NotebookText.stance(stance))
        }
        .buttonStyle(StanceButtonStyle(stance: stance, filled: on, open: false))
        .accessibilityAddTraits(on ? .isSelected : [])
    }

    /// NOTES DE L'ENQUÊTEUR: the player's own ticks, never checked by the game.
    private func marks(_ suspect: Suspect, game: Investigation) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            SectionHeader(title: L10n.t("suspect.marks"))
            Text(L10n.t("suspect.marksHelp"))
                .font(Trace.Fonts.caption)
                .foregroundStyle(Trace.Colors.text2)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.bottom, 4)
            ForEach(SuspectMark.allCases, id: \.self) { mark in
                let on = game.marks[suspect.id]?.contains(mark) == true
                Button {
                    withAnimation(.easeOut(duration: 0.15)) { session.perform { $0.toggle(mark, for: suspect.id) } }
                    Haptics.selection()
                } label: {
                    HStack(spacing: 12) {
                        CheckBox(on: on)
                        Text(L10n.t("mark.\(mark.rawValue)"))
                            .font(Trace.Fonts.callout)
                            .foregroundStyle(Trace.Colors.text)
                            .fixedSize(horizontal: false, vertical: true)
                        Spacer(minLength: 0)
                    }
                    .frame(minHeight: Trace.Height.hit)
                    .contentShape(Rectangle())
                }
                .buttonStyle(PressableStyle())
                .accessibilityAddTraits(on ? .isSelected : [])
            }
        }
    }
}

// MARK: - 14 · Indice

/// « Besoin d'aide ? » (screen 14): a flat sheet. The hints come in the case's order (direction →
/// place → exact piece). Each hint costs score points — never time — and the sheet says what the
/// best possible mark has become. Revealed hints are cards; the next one is closed, with its cost
/// and, if it is not available yet, when it will be.
struct HintsView: View {
    let session: GameSession
    /// Closes the sheet (the Carnet's veil). nil: `dismiss()` (presented by the system).
    var onClose: (() -> Void)? = nil
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    @AppStorage(Preferences.reduceMotionKey) private var appReduceMotion = false

    private var sheetShape: UnevenRoundedRectangle {
        UnevenRoundedRectangle(topLeadingRadius: Trace.Radius.sheet, topTrailingRadius: Trace.Radius.sheet)
    }

    var body: some View {
        let game = session.game
        ViewThatFits(in: .vertical) {
            content(game)
            ScrollView { content(game) }
        }
        .background(
            sheetShape
                .fill(Trace.Colors.surface)
                .overlay(sheetShape.strokeBorder(Trace.Colors.line, lineWidth: 1))
                .ignoresSafeArea(edges: .bottom)
        )
        .accessibilityElement(children: .contain)
        .accessibilityAddTraits(.isModal)
        .accessibilityAction(.escape) { close() }
    }

    private func close() {
        if let onClose { onClose() } else { dismiss() }
    }

    private func content(_ game: Investigation) -> some View {
        let hints = game.caseFile.hints
        let revealed = Array(hints.enumerated()).filter { game.state(of: $0.element) == .revealed }
        let next = hints.firstIndex { game.state(of: $0) != .revealed }
        let maxMark = max(0, 100 - game.hintScoreCost)
        return VStack(alignment: .leading, spacing: 16) {
            Capsule().fill(Trace.Colors.surface3).frame(width: 36, height: 5)
                .frame(maxWidth: .infinity)
                .accessibilityHidden(true)
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(fileLabel(game.caseFile.number))
                        .font(Trace.Fonts.data)
                        .foregroundStyle(Trace.Colors.benText)
                    Text(L10n.t("hints.need"))
                        .font(Trace.Fonts.title)
                        .foregroundStyle(Trace.Colors.text)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityAddTraits(.isHeader)
                }
                Spacer(minLength: 8)
                SheetCloseButton(identifier: "hints.close", action: close)
            }
            Text(L10n.t("hints.explainShort"))
                .font(Trace.Fonts.callout)
                .foregroundStyle(Trace.Colors.text2)
                .fixedSize(horizontal: false, vertical: true)
            Text(L10n.f("hints.maxNow", maxMark))
                .font(Trace.Fonts.data)
                .foregroundStyle(maxMark < 100 ? Trace.Colors.warning : Trace.Colors.text)
                .contentTransition(.numericText())
                .fixedSize(horizontal: false, vertical: true)
            ForEach(revealed, id: \.element.id) { offset, hint in
                revealedHint(hint, number: offset + 1)
                    .transition(.opacity)
            }
            if let next {
                closedHint(hints[next], number: next + 1, state: game.state(of: hints[next]))
                Button(L10n.f("hints.revealN", next + 1)) { reveal() }
                    .buttonStyle(CTAButtonStyle(kind: .primary))
                    .disabled(game.state(of: hints[next]) != .available)
                    .accessibilityIdentifier("hints.reveal")
            } else if !hints.isEmpty {
                Text(L10n.t("hints.allRevealed"))
                    .font(Trace.Fonts.body)
                    .foregroundStyle(Trace.Colors.text)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Button(L10n.t("hints.continue"), action: close)
                .buttonStyle(TextLinkStyle())
                .frame(maxWidth: .infinity)
                .accessibilityIdentifier("hints.continue")
        }
        .padding(.horizontal, 20)
        .padding(.top, 10)
        .padding(.bottom, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func reveal() {
        let reduced = systemReduceMotion || appReduceMotion
        var revealed: Hint?
        withAnimation(reduced ? .easeInOut(duration: 0.2) : Trace.Motion.paper) {
            revealed = session.useHint()
        }
        if revealed != nil {
            Haptics.light()
        }
    }

    private func tierName(_ number: Int) -> String { L10n.t("hints.tierName\(min(max(number, 1), 3))") }

    /// A revealed hint: the supervisor's words.
    private func revealedHint(_ hint: Hint, number: Int) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Text(L10n.f("hints.number", number) + " · " + tierName(number))
                    .fieldLabel()
                Spacer(minLength: 8)
                Text(hint.scoreCost == 0 ? L10n.t("hints.free") : L10n.f("hints.cost", hint.scoreCost))
                    .font(Trace.Fonts.data)
                    .foregroundStyle(Trace.Colors.text2)
            }
            Text(hint.text)
                .font(Trace.Fonts.quote)
                .foregroundStyle(Trace.Colors.text)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: Trace.Radius.card, style: .continuous).fill(Trace.Colors.surface2))
        .accessibilityElement(children: .combine)
    }

    /// The next hint, still closed: what it gives, what it costs, when it opens.
    private func closedHint(_ hint: Hint, number: Int, state: Investigation.HintState) -> some View {
        let until = lockedUntil(state)
        return VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                Text(L10n.f("hints.number", number) + " · " + tierName(number))
                    .fieldLabel()
                Spacer(minLength: 8)
                if until != nil {
                    Image(systemName: "lock")
                        .font(Trace.Fonts.caption.weight(.semibold))
                        .foregroundStyle(Trace.Colors.text2)
                        .accessibilityHidden(true)
                }
            }
            Text(L10n.t("hints.what\(min(max(number, 1), 3))"))
                .font(Trace.Fonts.callout)
                .foregroundStyle(Trace.Colors.text)
                .fixedSize(horizontal: false, vertical: true)
            Text(hint.scoreCost == 0 ? L10n.t("hints.freeNote") : L10n.f("hints.costNote", hint.scoreCost))
                .font(Trace.Fonts.caption.weight(.semibold))
                .foregroundStyle(hint.scoreCost == 0 ? Trace.Colors.text2 : Trace.Colors.warning)
                .fixedSize(horizontal: false, vertical: true)
            if let until {
                Text(L10n.f("hints.lockedUntil", PhoneFormat.countdown(Double(until))))
                    .font(Trace.Fonts.data)
                    .foregroundStyle(Trace.Colors.text2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: Trace.Radius.card, style: .continuous).fill(Trace.Colors.bg))
        .overlay(RoundedRectangle(cornerRadius: Trace.Radius.card, style: .continuous).strokeBorder(Trace.Colors.line, lineWidth: 1))
        .accessibilityElement(children: .combine)
    }

    private func lockedUntil(_ state: Investigation.HintState) -> Int? {
        if case .locked(let until) = state { return until }
        return nil
    }
}
#endif
