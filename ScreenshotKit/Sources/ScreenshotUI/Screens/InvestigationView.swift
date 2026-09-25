#if os(iOS)
import SwiftUI
import CaseEngine

/// The timed session: the phone, plus the notebook / hints / "accuse now" sheets on top.
/// The timer keeps running under the sheets; it pauses when the app goes to the background.
struct InvestigationView: View {
    let session: GameSession
    let onQuit: () -> Void
    @State private var sheet: Sheet?
    @State private var askingToQuit = false
    @Environment(\.scenePhase) private var scenePhase

    enum Sheet: String, Identifiable {
        case notebook, hints, accuseNow
        var id: String { rawValue }
    }

    var body: some View {
        PhoneView(session: session,
                  onNotebook: { sheet = .notebook },
                  onHints: { sheet = .hints },
                  onTimer: { sheet = .accuseNow },
                  onQuit: {
                      // The clock stops while the player decides.
                      session.pause()
                      askingToQuit = true
                  })
            .alert(L10n.t("quit.title"), isPresented: $askingToQuit) {
                Button(L10n.t("quit.continue"), role: .cancel) { session.resume() }
                Button(L10n.t("quit.confirm"), action: onQuit)
            } message: {
                Text(L10n.t("quit.message"))
            }
            .sheet(item: $sheet) { which in
                Group {
                    switch which {
                    case .notebook:
                        NotebookView(session: session) { sheet = nil; session.requestAccusation() }
                            .presentationDetents([.large])
                    case .hints:
                        HintsView(session: session)
                            .presentationDetents([.medium, .large])
                    case .accuseNow:
                        AccuseNowSheet(session: session, onAccuse: { sheet = nil; session.requestAccusation() }, onCancel: { sheet = nil })
                            .presentationDetents([.height(380), .medium])
                    }
                }
                .presentationCornerRadius(Theme.Radius.sheet)
                .presentationBackground(Trace.Colors.desk)
                .presentationDragIndicator(.visible)
            }
            .overlay {
                if scenePhase != .active {
                    PauseOverlay()
                }
            }
            .onChange(of: scenePhase) { _, phase in
                switch phase {
                case .active: session.resume()
                case .inactive, .background: session.pause()
                @unknown default: break
                }
            }
            .onChange(of: session.phase) { _, phase in
                if phase != .investigating { sheet = nil }
            }
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

/// Tap on the timer: a service note — "Clore le dossier maintenant ?" with the time bonus.
struct AccuseNowSheet: View {
    let session: GameSession
    let onAccuse: () -> Void
    let onCancel: () -> Void

    var body: some View {
        let bonus = Int(session.remainingSeconds / session.game.durationSeconds * Double(session.rules.scoring.timeLeft))
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .top) {
                    Text(L10n.f("accuseNow.overline", PhoneFormat.countdown(session.remainingSeconds))).fieldLabel(Trace.Colors.stamp)
                    Spacer()
                    StampMark(text: L10n.t("stamp.confidential"), size: 8, angle: 4)
                }
                Text(L10n.t("accuseNow.title")).font(Trace.Fonts.nameLarge).foregroundStyle(Trace.Colors.ink)
                    .fixedSize(horizontal: false, vertical: true)
                Text(L10n.f("accuseNow.bonus", bonus)).font(Trace.Fonts.proseSmall).foregroundStyle(Trace.Colors.inkSoft)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .paper(Trace.Colors.paper)
            Spacer(minLength: 0)
            Button(L10n.t("accuseNow.confirm"), action: onAccuse)
                .buttonStyle(InkButtonStyle(height: 52, fill: Trace.Colors.stamp, text: Trace.Colors.stampText))
                .accessibilityIdentifier("accuseNow.confirm")
            Button(action: onCancel) {
                Text(L10n.t("accuseNow.cancel")).font(Trace.Fonts.button).tracking(1.4).textCase(.uppercase)
                    .foregroundStyle(Trace.Colors.bone2).frame(maxWidth: .infinity, minHeight: 44)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 18)
        .padding(.top, 26)
        .padding(.bottom, 12)
        .background(TraceDesk())
    }
}

// MARK: - Carnet (field notebook)

/// The investigator's field notebook: a spiral notebook with blue lines and a red margin. Divider
/// tabs: the suspects' index cards, the pieces put in the file, the chronology built from them, and
/// the connections the player drew ("l'accuse →", "le disculpe →"). It only holds what the player
/// found and decided — never a verdict.
struct NotebookView: View {
    let session: GameSession
    let onAccuse: () -> Void
    @State private var tab = 0
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        let game = session.game
        NavigationStack {
            VStack(spacing: 0) {
                header
                DividerTabs(tabs: [(0, L10n.t("carnet.suspects")),
                                   (1, L10n.f("carnet.evidence", game.notebook.count)),
                                   (2, L10n.t("carnet.timeline")),
                                   (3, L10n.t("carnet.notes"))],
                            selection: $tab, identifier: "notebook.tab", sheetColor: Trace.Colors.notebook)
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        ObjectiveCard(objective: session.caseFile.objective)
                            .accessibilityIdentifier("notebook.objective")
                        switch tab {
                        case 0: suspects(game)
                        case 1: pieces(game)
                        case 2: ChronologySheet(game: game)
                        default: connections(game)
                        }
                    }
                    .padding(.leading, 58)
                    .padding(.trailing, 16)
                    .padding(.vertical, 18)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(alignment: .top) { RuledLines(spacing: 30, color: Trace.Colors.notebookRule) }
                    .animation(Trace.Motion.standard, value: tab)
                }
                .background(NotebookPaper())
                .clipShape(UnevenRoundedRectangle(topLeadingRadius: 0, bottomLeadingRadius: 6, bottomTrailingRadius: 6, topTrailingRadius: 6))
                .padding(.horizontal, 8)
                Button(action: onAccuse) {
                    Text(L10n.t("carnet.accuse"))
                }
                .buttonStyle(InkButtonStyle(height: 52, fill: Trace.Colors.stamp, text: Trace.Colors.stampText))
                .accessibilityIdentifier("notebook.accuse")
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 8)
            }
            .background(TraceDesk())
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: SuspectID.self) { id in
                SuspectFileView(suspectID: id, session: session) { app, route in
                    dismiss()
                    session.launch(app, then: route)
                }
            }
        }
    }

    private var header: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                Text(L10n.f("carnet.header", dossierNumber(session.caseFile.number))).fieldLabel(Trace.Colors.bone3)
                Text(L10n.t("carnet.title")).font(Trace.Fonts.screenTitle).foregroundStyle(Trace.Colors.bone)
                    .accessibilityIdentifier("notebook.title")
            }
            Spacer()
            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Trace.Colors.bone2)
                    .frame(width: 44, height: 44)
                    .background(Circle().strokeBorder(Trace.Colors.graphite, lineWidth: 1))
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text(L10n.t("a11y.close")))
            .accessibilityIdentifier("notebook.close")
        }
        .padding(.horizontal, 18)
        .padding(.top, 18)
        .padding(.bottom, 10)
    }

    // Suspects: the index cards, with what the player filed for / against each one.
    private func suspects(_ game: Investigation) -> some View {
        let counts = session.caseFile.suspects.map { s in
            let linked = game.linkedEntries(for: s.id)
            return (against: linked.filter { $0.stance == .incriminates }.count, favour: linked.filter { $0.stance == .clears }.count)
        }
        let top = counts.map(\.against).max() ?? 0
        let principal = top > 0 && counts.filter { $0.against == top }.count == 1 ? counts.firstIndex { $0.against == top } : nil
        return VStack(alignment: .leading, spacing: 14) {
            ForEach(Array(session.caseFile.suspects.enumerated()), id: \.element.id) { index, suspect in
                NavigationLink(value: suspect.id) {
                    SuspectIndexCard(suspect: suspect, letter: Suspect.letter(index), contact: game.contact(suspect.contact),
                                     against: counts[index].against, favour: counts[index].favour, principal: principal == index)
                        .tilt(suspect.id, range: 0.8)
                }
                .buttonStyle(PressableStyle())
                .accessibilityIdentifier("notebook.suspect.\(suspect.id)")
            }
            Handwritten(text: L10n.t("carnet.linkHelp"), color: Trace.Colors.pen, size: 19, angle: -1.5)
                .padding(.top, 4)
        }
    }

    // Pièces: every piece in the file, on its own support, in filing order.
    @ViewBuilder
    private func pieces(_ game: Investigation) -> some View {
        if game.notebook.isEmpty {
            EmptyPage(title: L10n.t("carnet.emptyTitle"), tip: L10n.t("carnet.emptyMessage"))
        } else {
            LazyVGrid(columns: [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)], alignment: .leading, spacing: 18) {
                ForEach(game.notebook, id: \.ref) { entry in
                    piece(entry, game: game)
                }
            }
        }
    }

    private func piece(_ entry: NotebookEntry, game: Investigation) -> some View {
        let suspect = entry.linkedTo.flatMap { id in session.caseFile.suspects.first { $0.id == id } }
        return VStack(alignment: .leading, spacing: 4) {
            ExhibitView(ref: entry.ref, game: game)
                .accessibilityElement(children: .combine)
                .accessibilityIdentifier("notebook.row")
            if let suspect {
                Handwritten(text: StanceWords.arrow(entry.stance) + " " + game.name(of: suspect.contact),
                            color: entry.stance == .incriminates ? Trace.Colors.stamp : Trace.Colors.pen, size: 17, angle: -2)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
        }
        .contextMenu {
            ForEach(session.caseFile.suspects) { suspect in
                Menu(game.name(of: suspect.contact)) {
                    Button(L10n.t("suspect.stanceAgainst")) { session.annotate(entry.ref, suspect: suspect.id, stance: .incriminates) }
                    Button(L10n.t("suspect.stanceFavour")) { session.annotate(entry.ref, suspect: suspect.id, stance: .clears) }
                }
            }
            if entry.linkedTo != nil {
                Button(L10n.t("pin.unlink")) { session.setStance(nil, for: entry.ref); session.link(entry.ref, to: nil) }
            }
            Button(L10n.t("pin.remove"), role: .destructive) { session.togglePin(entry.ref) }
        }
    }

    // Connexions: per suspect, the pieces the player hung on them, in their own hand.
    private func connections(_ game: Investigation) -> some View {
        VStack(alignment: .leading, spacing: 22) {
            Text(L10n.t("carnet.notesHelp")).font(Trace.Fonts.proseSmall).foregroundStyle(Trace.Colors.inkSoft)
            ForEach(Array(session.caseFile.suspects.enumerated()), id: \.element.id) { index, suspect in
                NavigationLink(value: suspect.id) {
                    ConnectionBlock(suspect: suspect, letter: Suspect.letter(index), game: game)
                }
                .buttonStyle(PressableStyle())
            }
        }
    }
}

/// The notebook's page: cream paper, red margin, the spiral on the left.
struct NotebookPaper: View {
    var body: some View {
        ZStack(alignment: .topLeading) {
            Trace.Colors.notebook
            PaperGrain(intensity: 0.03)
            Canvas { context, size in
                context.fill(Path(CGRect(x: 44, y: 0, width: 1.2, height: size.height)), with: .color(Trace.Colors.marginRed))
                var y: CGFloat = 16
                while y < size.height {
                    context.fill(Path(ellipseIn: CGRect(x: 14, y: y, width: 9, height: 9)), with: .color(Trace.Colors.desk.opacity(0.85)))
                    context.fill(Path(roundedRect: CGRect(x: 2, y: y + 3, width: 17, height: 3), cornerRadius: 1.5), with: .color(Trace.Colors.metal))
                    y += 23
                }
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

/// "l'accuse →" / "le disculpe →" / "→": the player's words for a link.
enum StanceWords {
    static func arrow(_ stance: NotebookEntry.Stance?) -> String {
        switch stance {
        case .incriminates: L10n.t("carnet.accusesArrow")
        case .clears: L10n.t("carnet.clearsArrow")
        case nil: "→"
        }
    }
}

/// One suspect in the "Connexions" page: name, then the piece labels the player drew to them.
struct ConnectionBlock: View {
    let suspect: Suspect
    let letter: String
    let game: Investigation

    var body: some View {
        let linked = game.linkedEntries(for: suspect.id)
        let marks = SuspectMark.allCases.filter { game.marks[suspect.id]?.contains($0) == true }
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(L10n.f("suspect.letter", letter)).fieldLabel()
                Text(game.name(of: suspect.contact)).font(Trace.Fonts.name).foregroundStyle(Trace.Colors.ink)
                Spacer()
                Image(systemName: "chevron.right").font(.system(size: 12, weight: .semibold)).foregroundStyle(Trace.Colors.inkFaint)
            }
            if linked.isEmpty && marks.isEmpty {
                Handwritten(text: L10n.t("carnet.nothingYet"), color: Trace.Colors.inkFaint, size: 18, angle: -1)
            }
            row(.incriminates, linked.filter { $0.stance == .incriminates }, color: Trace.Colors.stamp)
            row(.clears, linked.filter { $0.stance == .clears }, color: Trace.Colors.pen)
            row(nil, linked.filter { $0.stance == nil }, color: Trace.Colors.inkSoft)
            ForEach(marks, id: \.self) { mark in
                HStack(spacing: 8) {
                    CheckBox(on: true)
                    Handwritten(text: L10n.t("mark.\(mark.rawValue)"), size: 18, angle: -1)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private func row(_ stance: NotebookEntry.Stance?, _ entries: [NotebookEntry], color: Color) -> some View {
        if !entries.isEmpty {
            HStack(alignment: .top, spacing: 8) {
                Handwritten(text: StanceWords.arrow(stance), color: color, size: 19, angle: -2)
                    .fixedSize()
                FlowLayout(spacing: 6) {
                    ForEach(entries, id: \.ref) { entry in
                        EvidenceLabel(text: label(entry), seed: entry.ref.id)
                    }
                }
            }
        }
    }

    private func label(_ entry: NotebookEntry) -> String {
        let number = game.pieceNumber(of: entry.ref).map(PieceFormat.short) ?? ""
        let time = ItemDescriber.describe(entry.ref, in: game).at.map { PhoneFormat.time($0) } ?? ""
        return [number, time].filter { !$0.isEmpty }.joined(separator: " ")
    }
}

/// A square box drawn in ink; a pen cross when ticked.
struct CheckBox: View {
    let on: Bool
    var size: CGFloat = 16

    var body: some View {
        ZStack {
            Rectangle().strokeBorder(Trace.Colors.ink, lineWidth: 1.3)
            if on {
                Image(systemName: "xmark").font(.system(size: size * 0.7, weight: .heavy)).foregroundStyle(Trace.Colors.pen)
                    .transition(.scale(scale: 1.4).combined(with: .opacity))
            }
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}

/// Wraps its children onto several lines (labels glued on a page).
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

/// "Objectif" — clipped at the top of the notebook page, always one glance away.
struct ObjectiveCard: View {
    let objective: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(L10n.t("carnet.objective")).fieldLabel(Trace.Colors.stamp)
            Text(objective).font(Trace.Fonts.proseSmall).foregroundStyle(Trace.Colors.ink)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .paper(Trace.Colors.noteYellow, radius: 1)
        .overlay(alignment: .topTrailing) { Paperclip().rotationEffect(.degrees(8)).offset(x: -14, y: -16) }
        .rotationEffect(.degrees(-0.6))
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Suspect file

/// A suspect's file, typed on paper: identity photo clipped on, identity lines, what the seized
/// phone holds about them (shortcuts), their statement, the player's own notes (boxes), and the
/// pieces the player hung on them — each annotated by hand "l'accuse" / "le disculpe".
/// Nothing concludes for the player.
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
                    marks(suspect, game: game)
                    LinkedChain(suspect: suspect, session: session)
                }
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(alignment: .top) { RuledLines(spacing: 28) }
                .paper(Trace.Colors.paper)
                .overlay(alignment: .top) { Staple().offset(y: 6) }
                .padding(.horizontal, 12)
                .padding(.vertical, 14)
            }
            .background(TraceDesk())
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
                    .accessibilityIdentifier("suspect.name")
                Text(suspect.role.uppercased()).font(Trace.Fonts.monoSmall).foregroundStyle(Trace.Colors.inkSoft)
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
                Text(L10n.t("suspect.shortcutHelp")).font(Trace.Fonts.monoSmall).foregroundStyle(Trace.Colors.inkFaint)
            }
        }
    }

    private func fact(symbol: String, value: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: symbol).font(.system(size: 13)).foregroundStyle(Trace.Colors.inkSoft).frame(width: 20)
                Text(value).font(Trace.Fonts.fieldValue).foregroundStyle(Trace.Colors.ink)
                Spacer(minLength: 0)
                if onOpenInPhone != nil {
                    Image(systemName: "arrow.up.forward").font(.system(size: 11, weight: .bold)).foregroundStyle(Trace.Colors.inkSoft)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 40)
            .overlay(alignment: .bottom) { Rectangle().fill(Trace.Colors.ruled.opacity(2)).frame(height: 1) }
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
    }

    private func marks(_ suspect: Suspect, game: Investigation) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(L10n.t("suspect.marks")).fieldLabel()
            Text(L10n.t("suspect.marksHelp")).font(Trace.Fonts.monoSmall).foregroundStyle(Trace.Colors.inkFaint)
                .fixedSize(horizontal: false, vertical: true)
            ForEach(SuspectMark.allCases, id: \.self) { mark in
                let on = game.marks[suspect.id]?.contains(mark) == true
                Button {
                    withAnimation(Trace.Motion.stamp) { session.perform { $0.toggle(mark, for: suspect.id) } }
                    AudioDirector.shared.play(.paper, volume: 0.3)
                    Haptics.selection()
                } label: {
                    HStack(spacing: 12) {
                        CheckBox(on: on, size: 18)
                        Text(L10n.t("mark.\(mark.rawValue)")).font(Trace.Fonts.prose).foregroundStyle(Trace.Colors.ink)
                        Spacer()
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

/// CONTRE / EN FAVEUR: the pieces the player hung on a suspect, in time order. Each carries its
/// label and the two hand annotations "l'accuse" / "le disculpe" — the chosen one gets circled.
struct LinkedChain: View {
    let suspect: Suspect
    let session: GameSession

    var body: some View {
        let game = session.game
        let entries = game.linkedEntries(for: suspect.id)
            .map { (entry: $0, item: ItemDescriber.describe($0.ref, in: game)) }
            .sorted { ($0.item.at ?? Moment(seconds: 0)) < ($1.item.at ?? Moment(seconds: 0)) }
        let against = entries.filter { $0.entry.stance == .incriminates }.count
        let favour = entries.filter { $0.entry.stance == .clears }.count
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Text(L10n.f("suspect.linked", entries.count)).fieldLabel()
                Spacer()
                if !entries.isEmpty {
                    Text(L10n.f("suspect.counts", against, favour)).font(Trace.Fonts.monoSmall.weight(.semibold))
                        .foregroundStyle(Trace.Colors.ink)
                }
            }
            if entries.isEmpty {
                Handwritten(text: L10n.t("suspect.noLinked"), color: Trace.Colors.inkSoft, size: 18, angle: -1)
            } else {
                Text(L10n.t("suspect.stanceHelp")).font(Trace.Fonts.monoSmall).foregroundStyle(Trace.Colors.inkFaint)
                    .fixedSize(horizontal: false, vertical: true)
                ForEach(Array(entries.enumerated()), id: \.offset) { offset, row in
                    chainRow(row.entry, item: row.item, index: offset, game: game)
                }
            }
        }
    }

    private func chainRow(_ entry: NotebookEntry, item: ItemDescriber.Item, index: Int, game: Investigation) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                EvidenceLabel(text: game.pieceNumber(of: entry.ref).map(PieceFormat.short) ?? "P.—", seed: entry.ref.id)
                Text([PieceFormat.kind(entry.ref, in: game), item.at.map { PhoneFormat.shortDay($0) + " · " + PhoneFormat.time($0) }]
                        .compactMap { $0 }.joined(separator: " · "))
                    .font(Trace.Fonts.monoSmall).foregroundStyle(Trace.Colors.inkSoft).lineLimit(1)
            }
            Text(Self.withoutName(item.label, name: game.name(of: suspect.contact)))
                .font(Trace.Fonts.proseSmall).foregroundStyle(Trace.Colors.ink).lineLimit(3)
            if let place = item.place {
                Text(place.uppercased()).font(Trace.Fonts.monoSmall).foregroundStyle(Trace.Colors.inkSoft)
            }
            HStack(spacing: 18) {
                stanceButton(.incriminates, entry: entry)
                    .accessibilityIdentifier("suspect.stance.incriminates.\(index)")
                stanceButton(.clears, entry: entry)
                    .accessibilityIdentifier("suspect.stance.clears.\(index)")
            }
        }
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .overlay(alignment: .leading) {
            Rectangle().fill(color(entry.stance)).frame(width: 2).offset(x: -10)
        }
        .overlay(alignment: .bottom) { Rectangle().fill(Trace.Colors.ruled.opacity(2)).frame(height: 1) }
    }

    /// In the suspect's own file, "Emma Roussel · « … »" is just "« … »".
    static func withoutName(_ label: String, name: String) -> String {
        label.hasPrefix(name + " · ") ? String(label.dropFirst(name.count + 3)) : label
    }

    private func stanceButton(_ stance: NotebookEntry.Stance, entry: NotebookEntry) -> some View {
        let on = entry.stance == stance
        let color = stance == .incriminates ? Trace.Colors.stamp : Trace.Colors.pen
        return Button {
            withAnimation(Trace.Motion.emphasized) { session.setStance(on ? nil : stance, for: entry.ref) }
            if !on { AudioDirector.shared.play(.paper, volume: 0.3) }
        } label: {
            Handwritten(text: L10n.t(stance == .incriminates ? "suspect.stanceAgainst" : "suspect.stanceFavour"),
                        color: on ? color : Trace.Colors.inkFaint, size: 21, angle: -2)
                .padding(.horizontal, 10)
                .frame(minHeight: 40)
                .overlay {
                    if on {
                        Ellipse().stroke(color, lineWidth: 1.6).rotationEffect(.degrees(-4))
                            .transition(.scale(scale: 0.6).combined(with: .opacity))
                    }
                }
                .contentShape(Rectangle())
        }
        .buttonStyle(PressableStyle())
        .accessibilityLabel(Text(L10n.t(stance == .incriminates ? "suspect.stanceAgainst" : "suspect.stanceFavour")))
        .accessibilityAddTraits(on ? .isSelected : [])
    }

    private func color(_ stance: NotebookEntry.Stance?) -> Color {
        switch stance {
        case .incriminates: Trace.Colors.stamp
        case .clears: Trace.Colors.pen
        case nil: Trace.Colors.inkFaint
        }
    }
}

// MARK: - Hints (sealed envelopes)

/// "Aide à l'enquête": sealed envelopes from the supervisor. Each one says what it gives and what
/// it costs — score points, never time — and what the best possible score becomes.
struct HintsView: View {
    let session: GameSession
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        let game = session.game
        let maxScore = max(0, 100 - game.hintScoreCost)
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(L10n.t("hints.overline")).fieldLabel(Trace.Colors.stampOnDark)
                        Text(L10n.t("hints.title")).font(Trace.Fonts.screenTitle).foregroundStyle(Trace.Colors.bone)
                    }
                    Spacer()
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(Trace.Colors.bone2)
                            .frame(width: 44, height: 44)
                            .background(Circle().strokeBorder(Trace.Colors.graphite, lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(Text(L10n.t("a11y.close")))
                    .accessibilityIdentifier("hints.close")
                }
                Text(L10n.t("hints.explain")).font(Trace.Fonts.proseSmall).foregroundStyle(Trace.Colors.bone2)
                    .fixedSize(horizontal: false, vertical: true)
                HStack {
                    Text(L10n.t("hints.maxScore")).font(Trace.Fonts.mono).textCase(.uppercase).tracking(0.8).foregroundStyle(Trace.Colors.bone2)
                    Spacer()
                    Text("\(maxScore) / 100")
                        .font(Trace.Fonts.fieldValueLarge)
                        .foregroundStyle(maxScore < 100 ? Trace.Colors.stampOnDark : Trace.Colors.bone)
                        .contentTransition(.numericText())
                        .animation(Trace.Motion.emphasized, value: maxScore)
                }
                .padding(.vertical, 10)
                .overlay(alignment: .bottom) { Rectangle().fill(Trace.Colors.graphite).frame(height: 1) }
                ForEach(Array(game.caseFile.hints.enumerated()), id: \.element.id) { offset, hint in
                    HintCard(number: offset + 1, hint: hint, state: game.state(of: hint), scoreAfter: maxScore - hint.scoreCost) {
                        if session.useHint() != nil {
                            AudioDirector.shared.play(.paper, volume: 0.6)
                            Haptics.success()
                        }
                    }
                }
            }
            .padding(20)
        }
        .background(TraceDesk())
    }
}

/// One hint: a kraft envelope with a wax seal (available), tied with a string (not yet), or the
/// supervisor's note taken out of it (revealed).
struct HintCard: View {
    let number: Int
    let hint: Hint
    let state: Investigation.HintState
    /// Best possible score once this hint is used.
    let scoreAfter: Int
    let onReveal: () -> Void

    private var tierName: String { L10n.t("hints.tierName\(min(number, 3))") }
    private var cost: String { hint.scoreCost == 0 ? L10n.t("hints.free") : L10n.f("hints.cost", hint.scoreCost) }

    var body: some View {
        Group {
            switch state {
            case .revealed: note
            case .available: envelope(sealed: false, lockText: nil)
            case .locked(let until):
                envelope(sealed: true, lockText: until > 0 ? L10n.f("hints.lockedUntil", PhoneFormat.countdown(Double(until))) : L10n.t("hints.lockedPrevious"))
            }
        }
        .tilt("hint\(number)", range: 1)
        .animation(Trace.Motion.emphasized, value: state == .revealed)
    }

    private var note: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Text(L10n.f("hints.tier", number) + " · " + tierName).fieldLabel(Trace.Colors.stamp)
                Spacer()
                Text(cost).font(Trace.Fonts.monoSmall.weight(.semibold)).foregroundStyle(Trace.Colors.inkSoft)
            }
            Text(hint.text).font(Trace.Fonts.quote).foregroundStyle(Trace.Colors.ink)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .paper(Trace.Colors.noteYellow, radius: 1)
        .overlay(alignment: .top) { Tape().offset(y: -8) }
        .transition(.move(edge: .top).combined(with: .opacity))
    }

    private func envelope(sealed: Bool, lockText: String?) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Text(L10n.f("hints.tier", number)).fieldLabel(Trace.Colors.kraftLabel)
                Spacer()
                Text(cost).font(Trace.Fonts.monoSmall.weight(.bold)).foregroundStyle(Trace.Colors.kraftInk)
            }
            Text(tierName).font(Trace.Fonts.name).foregroundStyle(Trace.Colors.kraftInk)
            Text(L10n.t("hints.what\(min(number, 3))")).font(Trace.Fonts.proseSmall).foregroundStyle(Trace.Colors.kraftLabel)
                .fixedSize(horizontal: false, vertical: true)
            if let lockText {
                Label(lockText, systemImage: "lock").font(Trace.Fonts.monoSmall).foregroundStyle(Trace.Colors.kraftInk.opacity(0.7))
                    .padding(.top, 4)
            } else {
                Button(action: onReveal) {
                    HStack {
                        Text(L10n.t("hints.reveal"))
                        Spacer()
                        if hint.scoreCost > 0 { Text(L10n.f("hints.scoreAfter", max(0, scoreAfter))) }
                    }
                    .padding(.horizontal, 14)
                }
                .buttonStyle(InkButtonStyle(height: 44))
                .accessibilityIdentifier("hints.reveal.\(number)")
                .padding(.top, 4)
            }
        }
        .padding(16)
        .padding(.top, 18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            ZStack(alignment: .top) {
                RoundedRectangle(cornerRadius: 3).fill(sealed ? Trace.Colors.kraftSealed : Trace.Colors.kraft)
                EnvelopeFlap().fill(Trace.Colors.ink.opacity(0.07)).frame(height: 44)
                EnvelopeFlap().stroke(Trace.Colors.kraftInk.opacity(0.25), lineWidth: 1).frame(height: 44)
                PaperGrain(intensity: 0.05).clipShape(RoundedRectangle(cornerRadius: 3))
            }
            .shadow(color: .black.opacity(0.45), radius: 10, y: 8)
        )
        .overlay(alignment: .top) {
            if sealed {
                Rectangle().fill(Trace.Colors.kraftInk.opacity(0.55)).frame(width: 2).frame(maxHeight: .infinity)
            } else {
                Circle().fill(Trace.Colors.stamp)
                    .overlay(Circle().strokeBorder(Trace.Colors.stampDeep.opacity(0.5), lineWidth: 2).padding(3))
                    .overlay(Text("\(number)").font(Trace.Fonts.stamp(12)).foregroundStyle(Trace.Colors.stampText))
                    .frame(width: 30, height: 30)
                    .shadow(color: .black.opacity(0.3), radius: 2, y: 1)
                    .offset(y: 28)
                    .accessibilityHidden(true)
            }
        }
        .opacity(sealed ? 0.8 : 1)
        .transition(.opacity)
    }
}

/// The V of an envelope's flap.
struct EnvelopeFlap: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.minX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        return p
    }
}
#endif
