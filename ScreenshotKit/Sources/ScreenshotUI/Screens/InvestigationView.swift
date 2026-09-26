#if os(iOS)
import SwiftUI
import CaseEngine

// MARK: - 08 · Carnet

/// The Carnet (final handoff §F-08): a full-screen sheet on the desk, a kraft folder with three
/// divider tabs — PIÈCES (the filed pieces, newest first; the player says what each one proves:
/// « L'ACCUSE » / « LE DISCULPE » + a suspect), SUSPECTS (index cards, ▲n ▼n) and CHRONOLOGIE.
/// It only holds what the player filed and decided — never a verdict. CONCLURE is always possible.
struct NotebookView: View {
    let session: GameSession
    let onConclude: () -> Void

    @State private var tab = 0
    /// The piece card whose suspect chips are open, and for which reading.
    @State private var picking: Picking?
    @State private var sheet: PaperSheet?
    @State private var showingHints = false
    /// « Conclure quand même » was confirmed: conclude once its sheet is gone.
    @State private var concludeAfterSheet = false
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var typeSize
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @AppStorage(Preferences.reduceMotionKey) private var appReduceMotion = false

    /// From this many linked pieces, CONCLURE becomes the full button (§F-08).
    private static let solidFile = 3

    struct Picking: Equatable {
        let ref: ItemRef
        let stance: NotebookEntry.Stance
    }

    enum PaperSheet: String, Identifiable {
        case dossier, concludeEmpty
        var id: String { rawValue }
    }

    /// A filed piece and its number (filing order).
    private struct PieceRow: Identifiable {
        let entry: NotebookEntry
        let number: Int
        var id: ItemRef { entry.ref }
    }

    private var reduceMotion: Bool { systemReduceMotion || appReduceMotion }
    /// Changes that reflow the page (chips, a piece removed): none with reduced motion (§J).
    private var layoutMotion: Animation? { reduceMotion ? nil : Trace.Motion.paper }
    /// Sheets and veils: a 200 ms fade with reduced motion.
    private var fadeMotion: Animation { reduceMotion ? .easeInOut(duration: 0.2) : Trace.Motion.paper }

    var body: some View {
        let game = session.game
        NavigationStack {
            VStack(spacing: 0) {
                header
                DividerTabs(tabs: [(0, L10n.f("carnet.tab.pieces", game.notebook.count)),
                                   (1, L10n.t("carnet.suspects")),
                                   (2, L10n.t("carnet.timeline"))],
                            selection: $tab, identifier: "notebook.tab", sheetColor: Trace.Colors.kraft)
                folder(game)
            }
            .background(DeskBackdrop())
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: SuspectID.self) { id in
                SuspectFileView(suspectID: id, session: session) { app, route in
                    dismiss()
                    session.launch(app, then: route)
                }
            }
        }
        .accessibilityHidden(showingHints)
        .overlay { hintsLayer }
        .sheet(item: $sheet, onDismiss: {
            if concludeAfterSheet {
                concludeAfterSheet = false
                onConclude()
            }
        }, content: { which in
            switch which {
            case .dossier:
                CaseBriefSheet(caseFile: session.caseFile) { sheet = nil }
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
                    .presentationCornerRadius(16)
                    .presentationBackground(Trace.Colors.paper)
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
                    .presentationCornerRadius(16)
                    .presentationBackground(Trace.Colors.paper)
            }
        })
        .environment(\.caseNumber, session.caseFile.number)
        .onAppear { session.coach.carnetOpened() }
        .onDisappear { session.coach.carnetClosed() }
    }

    private var confirmDetents: Set<PresentationDetent> {
        if typeSize.isAccessibilitySize { return [.large] }
        return typeSize > .large ? [.medium] : [.height(300)]
    }

    // MARK: Header

    @ViewBuilder
    private var header: some View {
        if typeSize.isAccessibilitySize {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    closeButton
                    Spacer(minLength: 8)
                    dossierLink
                    hintButton
                }
                headerTitle.padding(.leading, 8)
            }
            .padding(.horizontal, 8)
            .padding(.top, 8)
            .padding(.bottom, 6)
        } else {
            HStack(spacing: 4) {
                closeButton
                headerTitle
                Spacer(minLength: 8)
                dossierLink
                hintButton
            }
            .padding(.horizontal, 8)
            .padding(.top, 8)
            .padding(.bottom, 6)
        }
    }

    private var headerTitle: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(L10n.f("dossier.number", dossierNumber(session.caseFile.number)))
                .font(Trace.Fonts.kicker)
                .tracking(1.6)
                .foregroundStyle(Trace.Colors.bone2)
            Text(L10n.t("carnet.title"))
                .font(Trace.Fonts.monoTitle)
                .tracking(2.4)
                .textCase(.uppercase)
                .foregroundStyle(Trace.Colors.bone)
                .accessibilityAddTraits(.isHeader)
                .accessibilityIdentifier("notebook.title")
        }
    }

    /// Back to the phone (the sheet goes down).
    private var closeButton: some View {
        Button { dismiss() } label: {
            Image(systemName: "xmark")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Trace.Colors.bone)
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(L10n.t("carnet.backToPhone")))
        .accessibilityIdentifier("notebook.close")
    }

    /// « Dossier »: the objective and the context stay one tap away (the briefing's text).
    private var dossierLink: some View {
        Button(L10n.t("carnet.dossierLink")) {
            sheet = .dossier
            Haptics.selection()
        }
        .buttonStyle(TextLinkStyle())
        .lineLimit(1)
        .minimumScaleFactor(0.7)
        .padding(.horizontal, 6)
        .accessibilityIdentifier("notebook.dossier")
    }

    /// The lightbulb: screen 14 · Indice.
    private var hintButton: some View {
        Button {
            showingHints = true
            Haptics.selection()
        } label: {
            Image(systemName: "lightbulb")
                .font(.system(size: 18, weight: .regular))
                .foregroundStyle(Trace.Colors.bone)
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(L10n.t("carnet.hint")))
        .accessibilityIdentifier("notebook.hint")
    }

    // MARK: Folder

    private var folderShape: UnevenRoundedRectangle {
        UnevenRoundedRectangle(topLeadingRadius: 2, bottomLeadingRadius: 10, bottomTrailingRadius: 10, topTrailingRadius: 10)
    }

    /// The kraft folder under the divider tabs: the active page, then CONCLURE at the bottom.
    private func folder(_ game: Investigation) -> some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    switch tab {
                    case 0: pieces(game)
                    case 1: suspects(game)
                    default: chronology(game)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 18)
                .frame(maxWidth: .infinity, alignment: .leading)
                .id(tab)
                .transition(.opacity)
            }
            .animation(.easeInOut(duration: 0.2), value: tab)
            footer(game)
        }
        .background(
            folderShape
                .fill(Trace.Colors.kraft)
                .overlay(PaperGrain(intensity: 0.05, texture: "tex_kraft_fibers").clipShape(folderShape))
                .shadow(color: .black.opacity(0.55), radius: 22, y: 12)
                .ignoresSafeArea(edges: .bottom)
        )
        .padding(.horizontal, 8)
    }

    /// CONCLURE L'ENQUÊTE — always enabled; outline while the file is thin, full from 3 linked
    /// pieces. Bubble 3 of the tutorial sits just above it, in the flow (it never covers a piece).
    private func footer(_ game: Investigation) -> some View {
        let linked = game.notebook.filter { $0.linkedTo != nil && $0.stance != nil }.count
        return VStack(spacing: 12) {
            if session.coach.active == .link {
                CoachBubble(bubble: .link, arrow: .bottom, dark: true) { session.coach.dismiss() }
                    .transition(.opacity)
            }
            Button(L10n.t("carnet.conclude")) { conclude(game) }
                .buttonStyle(CTAButtonStyle(kind: linked >= Self.solidFile ? .primary : .outline, onPaper: true))
                .accessibilityIdentifier("notebook.accuse")
        }
        .padding(.horizontal, 16)
        .padding(.top, 10)
        .padding(.bottom, 10)
        .animation(reduceMotion ? nil : Animation.easeOut(duration: 0.2), value: session.coach.active)
    }

    private func conclude(_ game: Investigation) {
        if game.notebook.isEmpty {
            sheet = .concludeEmpty
        } else {
            onConclude()
        }
    }

    // MARK: Pièces

    @ViewBuilder
    private func pieces(_ game: Investigation) -> some View {
        if game.notebook.isEmpty {
            emptyFile
        } else {
            let rows = game.notebook.enumerated().map { PieceRow(entry: $0.element, number: $0.offset + 1) }.reversed()
            ForEach(Array(rows)) { row in
                pieceCard(row.entry, number: row.number, game: game)
                    .transition(.opacity)
            }
        }
    }

    /// §N: an empty file says what to do next.
    private var emptyFile: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L10n.t("carnet.empty.title"))
                .font(Trace.Fonts.serifTitle(22))
                .foregroundStyle(Trace.Colors.ink)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)
            Text(L10n.t("carnet.empty.body"))
                .font(Trace.Fonts.prose)
                .foregroundStyle(Trace.Colors.inkMid)
                .fixedSize(horizontal: false, vertical: true)
            Button(L10n.t("carnet.backToPhone")) { dismiss() }
                .buttonStyle(CTAButtonStyle(kind: .primary, onPaper: true))
                .accessibilityIdentifier("notebook.backToPhone")
                .padding(.top, 8)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .paper(Trace.Colors.paper, radius: 0)
    }

    /// One filed piece: its kicker and preview, « CETTE PIÈCE… » [L'ACCUSE] [LE DISCULPE], the
    /// suspect chips once a reading is chosen, the typed summary of the link, « Retirer du dossier ».
    private func pieceCard(_ entry: NotebookEntry, number: Int, game: Investigation) -> some View {
        let suspect = entry.linkedTo.flatMap { game.index.suspect($0) }
        let open = picking?.ref == entry.ref ? picking : nil
        return VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 10) {
                (Text(PieceFormat.title(number)).foregroundColor(Trace.Colors.stamp)
                    + Text(" · " + PieceFormat.header(entry.ref, in: game)).foregroundColor(Trace.Colors.inkSoft))
                    .font(Trace.Fonts.kicker)
                    .tracking(1.2)
                    .fixedSize(horizontal: false, vertical: true)
                ExhibitSupport(ref: entry.ref, game: game)
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text(spokenPiece(entry, number: number, game: game)))
            .accessibilityIdentifier("notebook.row")
            .accessibilityActions {
                ForEach(session.caseFile.suspects) { candidate in
                    let name = NotebookText.firstName(game.name(of: candidate.contact))
                    Button(L10n.f("carnet.linkAccuses", name)) {
                        session.annotate(entry.ref, suspect: candidate.id, stance: .incriminates)
                    }
                    Button(L10n.f("carnet.linkClears", name)) {
                        session.annotate(entry.ref, suspect: candidate.id, stance: .clears)
                    }
                }
                Button(L10n.t("pin.remove")) { remove(entry) }
            }

            Rectangle().fill(Trace.Colors.inkFaint.opacity(0.3)).frame(height: 1)
                .accessibilityHidden(true)
            Text(L10n.t("carnet.thisPiece"))
                .font(Trace.Fonts.kicker)
                .tracking(1.6)
                .textCase(.uppercase)
                .foregroundStyle(Trace.Colors.inkSoft)
            stanceButtons(entry, number: number)
            if let open {
                chips(entry, stance: open.stance, game: game)
                    .transition(.opacity)
            }
            if let suspect, let stance = entry.stance {
                Text(LinkTally.glyph(stance) + " " + NotebookText.link(stance, name: NotebookText.firstName(game.name(of: suspect.contact))))
                    .font(Trace.Fonts.monoStrong)
                    .foregroundStyle(stance == .incriminates ? Trace.Colors.stamp : Trace.Colors.ink)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityHidden(true)
            }
            HStack {
                Spacer(minLength: 0)
                Button(L10n.t("pin.remove")) { remove(entry) }
                    .buttonStyle(TextLinkStyle(onPaper: true))
                    .accessibilityHidden(true) // a custom action of the piece for VoiceOver
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .paper(Trace.Colors.paper, radius: 0)
        .accessibilityElement(children: .contain)
    }

    private func spokenPiece(_ entry: NotebookEntry, number: Int, game: Investigation) -> String {
        var text = PieceFormat.spoken(entry.ref, in: game, number: number)
        if let id = entry.linkedTo, let suspect = game.index.suspect(id), let stance = entry.stance {
            text += ". " + NotebookText.link(stance, name: NotebookText.firstName(game.name(of: suspect.contact)))
        }
        return text
    }

    private func stanceButtons(_ entry: NotebookEntry, number: Int) -> some View {
        let layout = typeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: 8))
            : AnyLayout(HStackLayout(spacing: 10))
        return layout {
            stanceButton(.incriminates, entry: entry)
                .accessibilityIdentifier("notebook.accuses.\(number)")
            stanceButton(.clears, entry: entry)
                .accessibilityIdentifier("notebook.clears.\(number)")
        }
    }

    /// Opens (or closes) the suspect chips for this reading.
    private func stanceButton(_ stance: NotebookEntry.Stance, entry: NotebookEntry) -> some View {
        let set = entry.linkedTo != nil && entry.stance == stance
        let choice = Picking(ref: entry.ref, stance: stance)
        let open = picking == choice
        return Button {
            withAnimation(layoutMotion) { picking = open ? nil : choice }
            Haptics.selection()
        } label: {
            Text(LinkTally.glyph(stance) + " " + NotebookText.stance(stance))
        }
        .buttonStyle(StanceButtonStyle(stance: stance, filled: set, open: open))
        .accessibilityAddTraits(set ? .isSelected : [])
        .accessibilityValue(Text(open ? L10n.t("carnet.pickSuspect") : ""))
    }

    /// One chip per suspect: the engine links a piece to one suspect. Same again = undo.
    private func chips(_ entry: NotebookEntry, stance: NotebookEntry.Stance, game: Investigation) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(L10n.t("carnet.pickSuspect"))
                .font(Trace.Fonts.kicker)
                .tracking(1.6)
                .textCase(.uppercase)
                .foregroundStyle(Trace.Colors.inkSoft)
            FlowLayout(spacing: 8) {
                ForEach(session.caseFile.suspects) { candidate in
                    let chosen = entry.linkedTo == candidate.id && entry.stance == stance
                    Button {
                        withAnimation(layoutMotion) {
                            session.annotate(entry.ref, suspect: candidate.id, stance: stance)
                            picking = nil
                        }
                    } label: {
                        Text((chosen ? "✓ " : "") + NotebookText.firstName(game.name(of: candidate.contact)))
                    }
                    .buttonStyle(SuspectChipStyle(stance: stance, chosen: chosen))
                    .accessibilityAddTraits(chosen ? .isSelected : [])
                    .accessibilityIdentifier("notebook.suspectChip.\(candidate.id)")
                }
            }
        }
    }

    private func remove(_ entry: NotebookEntry) {
        withAnimation(layoutMotion) {
            if picking?.ref == entry.ref { picking = nil }
            session.togglePin(entry.ref)
        }
    }

    // MARK: Suspects

    private func suspects(_ game: Investigation) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            ForEach(Array(session.caseFile.suspects.enumerated()), id: \.element.id) { index, suspect in
                let linked = game.linkedEntries(for: suspect.id)
                NavigationLink(value: suspect.id) {
                    SuspectIndexCard(suspect: suspect, letter: Suspect.letter(index), contact: game.contact(suspect.contact),
                                     against: linked.filter { $0.stance == .incriminates }.count,
                                     favour: linked.filter { $0.stance == .clears }.count,
                                     pieces: linked.compactMap { pieceLine($0, game: game) })
                }
                .buttonStyle(PressableStyle())
                .accessibilityIdentifier("notebook.suspect.\(suspect.id)")
            }
        }
    }

    /// « PIÈCE 03 · MESSAGE · 22:47 » under a suspect's card.
    private func pieceLine(_ entry: NotebookEntry, game: Investigation) -> LinkedPieceLine? {
        guard let number = game.pieceNumber(of: entry.ref) else { return nil }
        let time = ItemDescriber.describe(entry.ref, in: game).at.map { " · " + PhoneFormat.time($0) } ?? ""
        return LinkedPieceLine(stance: entry.stance, text: PieceFormat.title(number) + " · " + PieceFormat.kind(entry.ref, in: game) + time)
    }

    // MARK: Chronologie

    private func chronology(_ game: Investigation) -> some View {
        ChronologySheet(game: game)
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .paper(Trace.Colors.paper, radius: 0)
    }

    // MARK: 14 · Indice

    /// Screen 14 over a 50 % veil (opaque with Reduce Transparency). Two siblings so each keeps
    /// its own transition: the veil fades, the sheet arrives (§J: y 24 → 0 + opacity; opacity only
    /// with reduced motion).
    private var hintsLayer: some View {
        ZStack(alignment: .bottom) {
            if showingHints {
                (reduceTransparency ? Trace.Colors.launch : Trace.Colors.launch.opacity(0.5))
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
        .animation(fadeMotion, value: showingHints)
    }
}

/// The Carnet's words for a link: « L'accuse », « L'accuse : Lucas », first names.
private enum NotebookText {
    static func stance(_ stance: NotebookEntry.Stance) -> String {
        L10n.t(stance == .incriminates ? "suspect.stanceAgainst" : "suspect.stanceFavour")
    }

    static func link(_ stance: NotebookEntry.Stance, name: String) -> String {
        L10n.f(stance == .incriminates ? "carnet.linkAccuses" : "carnet.linkClears", name)
    }

    /// « Lucas » from « Lucas Ferrand ».
    static func firstName(_ name: String) -> String {
        name.split(separator: " ").first.map(String.init) ?? name
    }
}

/// [▲ L'ACCUSE] / [▼ LE DISCULPE] on a piece: outline; once set, filled red (accuses) or ink (clears).
private struct StanceButtonStyle: ButtonStyle {
    let stance: NotebookEntry.Stance
    let filled: Bool
    let open: Bool

    func makeBody(configuration: Configuration) -> some View {
        let shape = RoundedRectangle(cornerRadius: 6, style: .continuous)
        let fill = stance == .incriminates ? Trace.Colors.stamp : Trace.Colors.ink
        let text = stance == .incriminates ? Trace.Colors.criticalText : Trace.Colors.bone
        return configuration.label
            .font(Trace.Fonts.monoStrong)
            .tracking(1.4)
            .textCase(.uppercase)
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .foregroundStyle(filled ? text : Trace.Colors.ink)
            .padding(.horizontal, 12)
            .frame(maxWidth: .infinity, minHeight: 44)
            .background(shape.fill(filled ? fill : Color.clear))
            .overlay(shape.strokeBorder(filled ? fill : Trace.Colors.ink, lineWidth: open && !filled ? 2.5 : 1.5))
            .contentShape(shape)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

/// A suspect's first name on a paper chip; filled when this piece is linked to them that way.
private struct SuspectChipStyle: ButtonStyle {
    let stance: NotebookEntry.Stance
    let chosen: Bool

    func makeBody(configuration: Configuration) -> some View {
        let shape = RoundedRectangle(cornerRadius: 4, style: .continuous)
        let fill = stance == .incriminates ? Trace.Colors.stamp : Trace.Colors.ink
        let text = stance == .incriminates ? Trace.Colors.criticalText : Trace.Colors.bone
        return configuration.label
            .font(Trace.Fonts.monoStrong)
            .tracking(1.2)
            .textCase(.uppercase)
            .lineLimit(1)
            .foregroundStyle(chosen ? text : Trace.Colors.ink)
            .padding(.horizontal, 14)
            .frame(minHeight: 44)
            .background(shape.fill(chosen ? fill : Trace.Colors.paperSelected))
            .overlay(shape.strokeBorder(chosen ? fill : Trace.Colors.inkSoft, lineWidth: 1))
            .contentShape(shape)
            .opacity(configuration.isPressed ? 0.75 : 1)
    }
}

// MARK: - Dossier (objective + context)

/// « Dossier » from the Carnet: the case's objective and its context, as in the briefing.
private struct CaseBriefSheet: View {
    let caseFile: CaseFile
    let onClose: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Text(L10n.f("dossier.number", dossierNumber(caseFile.number)))
                    .font(Trace.Fonts.kicker)
                    .tracking(1.6)
                    .foregroundStyle(Trace.Colors.inkSoft)
                Text(caseFile.title)
                    .font(Trace.Fonts.serifTitle(26))
                    .foregroundStyle(Trace.Colors.ink)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityAddTraits(.isHeader)
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
                .accessibilityElement(children: .combine)
                ForEach(Array(caseFile.synopsis.enumerated()), id: \.offset) { _, line in
                    Text(line)
                        .font(Trace.Fonts.prose)
                        .foregroundStyle(Trace.Colors.ink)
                        .lineSpacing(4)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Button(L10n.t("a11y.close"), action: onClose)
                    .buttonStyle(TextLinkStyle(onPaper: true))
                    .frame(maxWidth: .infinity)
                    .accessibilityIdentifier("notebook.dossierClose")
            }
            .padding(.horizontal, 20)
            .padding(.top, 24)
            .padding(.bottom, 16)
        }
        .background(Trace.Colors.paper.overlay(PaperGrain()).ignoresSafeArea())
    }
}

// MARK: - Checkbox, flow layout

/// A square box drawn in ink; a pen cross when ticked.
struct CheckBox: View {
    let on: Bool
    var size: CGFloat = 16

    var body: some View {
        ZStack {
            Rectangle().strokeBorder(Trace.Colors.ink, lineWidth: 1.3)
            if on {
                Image(systemName: "xmark").font(.system(size: size * 0.7, weight: .heavy)).foregroundStyle(Trace.Colors.pen)
                    .transition(.opacity)
            }
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}

/// Wraps its children onto several lines (chips, labels glued on a page).
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

/// A suspect's file, typed on paper: identity photo clipped on, identity lines, what the seized
/// phone holds about them (shortcuts), their statement, the pieces the player linked to them (with
/// the player's reading, which can be changed here) and the player's own notes (boxes).
/// Nothing concludes for the player: no highlight, no ranking, nothing written in their place.
struct SuspectFileView: View {
    let suspectID: SuspectID
    let session: GameSession
    /// Opens something in the phone (closes the notebook). nil where the phone is not reachable.
    var onOpenInPhone: ((AppID, PhoneRoute?) -> Void)? = nil

    var body: some View {
        let game = session.game
        if let suspect = game.index.suspect(suspectID) {
            let index = session.caseFile.suspects.firstIndex { $0.id == suspectID } ?? 0
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    header(suspect, letter: Suspect.letter(index), game: game)
                    identity(suspect, game: game)
                    phoneFacts(suspect, game: game)
                    statement(suspect)
                    linkedPieces(suspect, game: game)
                    marks(suspect, game: game)
                }
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .leading)
                .paper(Trace.Colors.paper, radius: 0)
                .overlay(alignment: .top) { Staple().offset(y: 6) }
                .padding(.horizontal, 12)
                .padding(.vertical, 14)
            }
            .background(DeskBackdrop())
            .toolbar(.visible, for: .navigationBar)
            .toolbarBackground(Trace.Colors.desk, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .navigationBarTitleDisplayMode(.inline)
            .tint(Trace.Colors.bone)
        }
    }

    private func header(_ suspect: Suspect, letter: String, game: Investigation) -> some View {
        HStack(alignment: .top, spacing: 16) {
            IDPhoto(contact: game.contact(suspect.contact), width: 84, height: 104)
                .overlay(alignment: .topLeading) { Paperclip().offset(x: -4, y: -14) }
                .rotationEffect(.degrees(-1.5))
            VStack(alignment: .leading, spacing: 6) {
                Text(L10n.f("suspect.fileHeader", letter)).fieldLabel(Trace.Colors.stamp)
                Text(game.name(of: suspect.contact)).font(Trace.Fonts.nameLarge).foregroundStyle(Trace.Colors.ink)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityAddTraits(.isHeader)
                    .accessibilityIdentifier("suspect.name")
                Text(suspect.role.uppercased()).font(Trace.Fonts.monoSmall).foregroundStyle(Trace.Colors.inkSoft)
                    .fixedSize(horizontal: false, vertical: true)
                StampMark(text: L10n.t("stamp.confidential"), size: 8, angle: -4).padding(.top, 4)
            }
            Spacer(minLength: 0)
        }
    }

    @ViewBuilder
    private func identity(_ suspect: Suspect, game: Investigation) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            if let age = suspect.age { LedgerRow(label: L10n.t("suspect.ageLabel"), value: L10n.f("suspect.age", age)) }
            LedgerRow(label: L10n.t("suspect.link"), value: suspect.role)
            if let address = suspect.address { LedgerRow(label: L10n.t("suspect.address"), value: address) }
            if let phone = game.contact(suspect.contact)?.phone { LedgerRow(label: L10n.t("suspect.phoneLabel"), value: phone) }
        }
    }

    /// What the seized phone holds about this person: facts and shortcuts, never a reading.
    @ViewBuilder
    private func phoneFacts(_ suspect: Suspect, game: Investigation) -> some View {
        let conversation = game.device.conversations.first { !$0.isGroup && $0.participants == [suspect.contact] }
        let messages = conversation.map { game.visibleMessages(in: $0.id).count } ?? 0
        let calls = game.calls.filter { $0.contact == suspect.contact }.count
        VStack(alignment: .leading, spacing: 6) {
            Text(L10n.t("suspect.inPhone")).fieldLabel()
            fact(symbol: "bubble.left.and.bubble.right", value: L10n.f("suspect.messagesCount", messages)) {
                if let conversation { onOpenInPhone?(.messages, .conversation(conversation.id)) }
            }
            .disabled(conversation == nil || onOpenInPhone == nil)
            fact(symbol: "phone", value: L10n.f("n.calls", calls)) {
                onOpenInPhone?(.phone, nil)
            }
            .disabled(calls == 0 || onOpenInPhone == nil)
            if onOpenInPhone != nil {
                Text(L10n.t("suspect.shortcutHelp")).font(Trace.Fonts.monoSmall).foregroundStyle(Trace.Colors.inkSoft)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func fact(symbol: String, value: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: symbol).font(.system(size: 13)).foregroundStyle(Trace.Colors.inkSoft).frame(width: 20)
                    .accessibilityHidden(true)
                Text(value).font(Trace.Fonts.fieldValue).foregroundStyle(Trace.Colors.ink)
                Spacer(minLength: 0)
                if onOpenInPhone != nil {
                    Image(systemName: "arrow.up.forward").font(.system(size: 11, weight: .bold)).foregroundStyle(Trace.Colors.inkSoft)
                        .accessibilityHidden(true)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 44)
            .overlay(alignment: .bottom) { Rectangle().fill(Trace.Colors.inkFaint.opacity(0.3)).frame(height: 1) }
            .contentShape(Rectangle())
        }
        .buttonStyle(PressableStyle())
    }

    private func statement(_ suspect: Suspect) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(L10n.t("suspect.statementLabel")).fieldLabel()
            Text(suspect.statement).font(Trace.Fonts.quote).foregroundStyle(Trace.Colors.ink)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.leading, 12)
                .overlay(alignment: .leading) { Rectangle().fill(Trace.Colors.ink).frame(width: 1.5) }
        }
        .accessibilityElement(children: .combine)
    }

    /// PIÈCES LIÉES: the pieces the player linked to this suspect, in filing order, with their
    /// reading. [L'ACCUSE] / [LE DISCULPE] switch it; the same one again unlinks the piece.
    private func linkedPieces(_ suspect: Suspect, game: Investigation) -> some View {
        let entries = game.linkedEntries(for: suspect.id)
        let against = entries.filter { $0.stance == .incriminates }.count
        let favour = entries.filter { $0.stance == .clears }.count
        return VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Text(L10n.f("suspect.linked", entries.count)).fieldLabel()
                Spacer()
                if !entries.isEmpty { LinkTally(against: against, favour: favour) }
            }
            if entries.isEmpty {
                Text(L10n.t("suspect.noPiece")).font(Trace.Fonts.proseSmall).foregroundStyle(Trace.Colors.inkSoft)
            } else {
                ForEach(Array(entries.enumerated()), id: \.element.ref) { offset, entry in
                    linkedRow(entry, suspect: suspect, index: offset, game: game)
                }
            }
        }
    }

    private func linkedRow(_ entry: NotebookEntry, suspect: Suspect, index: Int, game: Investigation) -> some View {
        let number = game.pieceNumber(of: entry.ref) ?? 0
        return VStack(alignment: .leading, spacing: 8) {
            VStack(alignment: .leading, spacing: 4) {
                Text(PieceFormat.title(number) + " · " + PieceFormat.header(entry.ref, in: game))
                    .font(Trace.Fonts.kicker)
                    .tracking(1.2)
                    .foregroundStyle(Trace.Colors.inkSoft)
                    .fixedSize(horizontal: false, vertical: true)
                Text(PieceFormat.preview(entry.ref, in: game))
                    .font(Trace.Fonts.proseSmall)
                    .foregroundStyle(Trace.Colors.ink)
                    .lineLimit(3)
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text(PieceFormat.spoken(entry.ref, in: game, number: number)))
            HStack(spacing: 10) {
                stanceButton(.incriminates, entry: entry, suspect: suspect)
                    .accessibilityIdentifier("suspect.stance.incriminates.\(index)")
                stanceButton(.clears, entry: entry, suspect: suspect)
                    .accessibilityIdentifier("suspect.stance.clears.\(index)")
            }
        }
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .overlay(alignment: .bottom) { Rectangle().fill(Trace.Colors.inkFaint.opacity(0.3)).frame(height: 1) }
    }

    private func stanceButton(_ stance: NotebookEntry.Stance, entry: NotebookEntry, suspect: Suspect) -> some View {
        let on = entry.stance == stance
        return Button {
            session.annotate(entry.ref, suspect: suspect.id, stance: stance)
        } label: {
            Text(LinkTally.glyph(stance) + " " + NotebookText.stance(stance))
        }
        .buttonStyle(StanceButtonStyle(stance: stance, filled: on, open: false))
        .accessibilityAddTraits(on ? .isSelected : [])
    }

    private func marks(_ suspect: Suspect, game: Investigation) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(L10n.t("suspect.marks")).fieldLabel()
            Text(L10n.t("suspect.marksHelp")).font(Trace.Fonts.monoSmall).foregroundStyle(Trace.Colors.inkSoft)
                .fixedSize(horizontal: false, vertical: true)
            ForEach(SuspectMark.allCases, id: \.self) { mark in
                let on = game.marks[suspect.id]?.contains(mark) == true
                Button {
                    withAnimation(.easeOut(duration: 0.15)) { session.perform { $0.toggle(mark, for: suspect.id) } }
                    AudioDirector.shared.play(.paper, volume: 0.3)
                    Haptics.selection()
                } label: {
                    HStack(spacing: 12) {
                        CheckBox(on: on, size: 18)
                        Text(L10n.t("mark.\(mark.rawValue)")).font(Trace.Fonts.prose).foregroundStyle(Trace.Colors.ink)
                            .fixedSize(horizontal: false, vertical: true)
                        Spacer(minLength: 0)
                    }
                    .frame(minHeight: 44)
                    .contentShape(Rectangle())
                }
                .buttonStyle(PressableStyle())
                .accessibilityAddTraits(on ? .isSelected : [])
            }
        }
    }
}

// MARK: - 14 · Indice

/// « BESOIN D'AIDE ? » (final handoff §F-14): a paper sheet. The hints come in the case's order
/// (direction → place → exact piece). No tickets in this game: each hint costs score points —
/// never time — and the sheet says what the best possible mark has become. Revealed hints are
/// yellow post-its (typed, never handwritten: the handwriting is the player's); the next one is
/// closed, with its cost and, if it is not available yet, when it will be.
struct HintsView: View {
    let session: GameSession
    /// Closes the sheet (the Carnet's veil). nil: `dismiss()` (presented by the system).
    var onClose: (() -> Void)? = nil
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    @AppStorage(Preferences.reduceMotionKey) private var appReduceMotion = false

    private var sheetShape: UnevenRoundedRectangle {
        UnevenRoundedRectangle(topLeadingRadius: 16, topTrailingRadius: 16)
    }

    var body: some View {
        let game = session.game
        ViewThatFits(in: .vertical) {
            content(game)
            ScrollView { content(game) }
        }
        .background(
            sheetShape
                .fill(Trace.Colors.paper)
                .overlay(PaperGrain().clipShape(sheetShape))
                .shadow(color: .black.opacity(0.55), radius: 20, y: -2)
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
        return VStack(alignment: .leading, spacing: 14) {
            Capsule().fill(Trace.Colors.inkFaint.opacity(0.5)).frame(width: 36, height: 4)
                .frame(maxWidth: .infinity)
                .accessibilityHidden(true)
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(L10n.f("dossier.number", dossierNumber(game.caseFile.number)) + " · " + L10n.t("carnet.hint"))
                        .font(Trace.Fonts.kicker)
                        .tracking(1.6)
                        .textCase(.uppercase)
                        .foregroundStyle(Trace.Colors.stamp)
                    Text(L10n.t("hints.need"))
                        .font(Trace.Fonts.monoTitle)
                        .tracking(1.2)
                        .textCase(.uppercase)
                        .foregroundStyle(Trace.Colors.ink)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityAddTraits(.isHeader)
                }
                Spacer(minLength: 8)
                Button(action: close) {
                    Image(systemName: "xmark")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Trace.Colors.ink)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .padding(.trailing, -10)
                .accessibilityLabel(Text(L10n.t("a11y.close")))
                .accessibilityIdentifier("hints.close")
            }
            Text(L10n.t("hints.explainShort"))
                .font(Trace.Fonts.proseSmall)
                .foregroundStyle(Trace.Colors.inkMid)
                .fixedSize(horizontal: false, vertical: true)
            Text(L10n.f("hints.maxNow", maxMark))
                .font(Trace.Fonts.monoStrong)
                .tracking(0.8)
                .foregroundStyle(maxMark < 100 ? Trace.Colors.stamp : Trace.Colors.ink)
                .contentTransition(.numericText())
                .fixedSize(horizontal: false, vertical: true)
            ForEach(revealed, id: \.element.id) { offset, hint in
                postIt(hint, number: offset + 1)
                    .transition(.opacity)
            }
            if let next {
                closedHint(hints[next], number: next + 1, state: game.state(of: hints[next]))
                Button(L10n.f("hints.revealN", next + 1)) { reveal() }
                    .buttonStyle(CTAButtonStyle(kind: .primary, onPaper: true))
                    .disabled(game.state(of: hints[next]) != .available)
                    .accessibilityIdentifier("hints.reveal")
            } else if !hints.isEmpty {
                Text(L10n.t("hints.allRevealed"))
                    .font(Trace.Fonts.prose)
                    .foregroundStyle(Trace.Colors.ink)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Button(L10n.t("hints.continue"), action: close)
                .buttonStyle(TextLinkStyle(onPaper: true))
                .frame(maxWidth: .infinity)
                .accessibilityIdentifier("hints.continue")
        }
        .padding(.horizontal, 16)
        .padding(.top, 10)
        .padding(.bottom, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func reveal() {
        let reduced = systemReduceMotion || appReduceMotion
        var revealed: Hint?
        withAnimation(reduced ? nil : Trace.Motion.paper) {
            revealed = session.useHint()
        }
        if revealed != nil {
            AudioDirector.shared.play(.paper, volume: 0.6)
            Haptics.light()
        }
    }

    private func tierName(_ number: Int) -> String { L10n.t("hints.tierName\(min(max(number, 1), 3))") }

    /// A revealed hint: a yellow post-it, the supervisor's words, typed.
    private func postIt(_ hint: Hint, number: Int) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Text(L10n.f("hints.number", number) + " · " + tierName(number))
                    .font(Trace.Fonts.kicker)
                    .tracking(1.4)
                    .textCase(.uppercase)
                    .foregroundStyle(Trace.Colors.stamp)
                Spacer(minLength: 8)
                Text(hint.scoreCost == 0 ? L10n.t("hints.free") : L10n.f("hints.cost", hint.scoreCost))
                    .font(Trace.Fonts.monoSmall)
                    .foregroundStyle(Trace.Colors.inkSoft)
            }
            Text(hint.text)
                .font(Trace.Fonts.quote)
                .foregroundStyle(Trace.Colors.ink)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .paper(Trace.Colors.noteYellow, radius: 1)
        .rotationEffect(.degrees(Trace.tilt(hint.id, range: 0.8)))
        .accessibilityElement(children: .combine)
    }

    /// The next hint, still closed: what it gives, what it costs, when it opens.
    private func closedHint(_ hint: Hint, number: Int, state: Investigation.HintState) -> some View {
        let until = lockedUntil(state)
        return VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                Text(L10n.f("hints.number", number) + " · " + tierName(number))
                    .font(Trace.Fonts.kicker)
                    .tracking(1.4)
                    .textCase(.uppercase)
                    .foregroundStyle(Trace.Colors.ink)
                Spacer(minLength: 8)
                if until != nil {
                    Image(systemName: "lock").font(.system(size: 12, weight: .semibold)).foregroundStyle(Trace.Colors.inkSoft)
                        .accessibilityHidden(true)
                }
            }
            Text(L10n.t("hints.what\(min(max(number, 1), 3))"))
                .font(Trace.Fonts.proseSmall)
                .foregroundStyle(Trace.Colors.inkMid)
                .fixedSize(horizontal: false, vertical: true)
            Text(hint.scoreCost == 0 ? L10n.t("hints.freeNote") : L10n.f("hints.costNote", hint.scoreCost))
                .font(Trace.Fonts.monoStrong)
                .foregroundStyle(hint.scoreCost == 0 ? Trace.Colors.ink : Trace.Colors.stamp)
                .fixedSize(horizontal: false, vertical: true)
            if let until {
                Text(L10n.f("hints.lockedUntil", PhoneFormat.countdown(Double(until))))
                    .font(Trace.Fonts.mono)
                    .foregroundStyle(Trace.Colors.inkSoft)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .overlay(Rectangle().strokeBorder(Trace.Colors.inkSoft, style: StrokeStyle(lineWidth: 1, dash: [4, 3])))
        .accessibilityElement(children: .combine)
    }

    private func lockedUntil(_ state: Investigation.HintState) -> Int? {
        if case .locked(let until) = state { return until }
        return nil
    }
}
#endif
