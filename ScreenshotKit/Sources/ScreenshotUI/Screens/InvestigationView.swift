#if os(iOS)
import SwiftUI
import CaseEngine

/// The timed session: the phone, plus the notebook / hints / "accuse now" sheets on top.
/// The timer keeps running under the sheets; it pauses when the app goes to the background.
struct InvestigationView: View {
    let session: GameSession
    @State private var sheet: Sheet?
    @Environment(\.scenePhase) private var scenePhase

    enum Sheet: String, Identifiable {
        case notebook, hints, accuseNow
        var id: String { rawValue }
    }

    var body: some View {
        PhoneView(session: session,
                  onNotebook: { sheet = .notebook },
                  onHints: { sheet = .hints },
                  onTimer: { sheet = .accuseNow })
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
                            .presentationDetents([.height(300)])
                    }
                }
                .presentationCornerRadius(Theme.Radius.sheet)
                .presentationBackground(Theme.Colors.ink0)
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

/// "Enquête en pause" — blurred screen when the app leaves the foreground.
struct PauseOverlay: View {
    var body: some View {
        ZStack {
            Rectangle().fill(.ultraThinMaterial).ignoresSafeArea()
            VStack(spacing: Theme.Spacing.s4) {
                Text(L10n.t("pause.overline")).overline(Theme.Colors.signal)
                Text(L10n.t("pause.title")).font(Theme.Fonts.title).foregroundStyle(Theme.Colors.textPrimary)
            }
        }
    }
}

/// Tap on the timer: "Accuser maintenant ?" with the time bonus shown.
struct AccuseNowSheet: View {
    let session: GameSession
    let onAccuse: () -> Void
    let onCancel: () -> Void

    var body: some View {
        let bonus = Int(session.remainingSeconds / session.game.durationSeconds * Double(session.rules.scoring.timeLeft))
        VStack(alignment: .leading, spacing: Theme.Spacing.s5) {
            Text(L10n.f("accuseNow.overline", PhoneFormat.countdown(session.remainingSeconds))).overline(Theme.Colors.signal)
            Text(L10n.t("accuseNow.title")).font(Theme.Fonts.title).foregroundStyle(Theme.Colors.textPrimary)
            Text(L10n.f("accuseNow.bonus", bonus)).font(Theme.Fonts.narrativeSmall).foregroundStyle(Theme.Colors.textSecondary)
            Spacer(minLength: 0)
            Button(L10n.t("accuseNow.confirm"), action: onAccuse).buttonStyle(PrimaryButtonStyle(height: Theme.Size.buttonM))
                .accessibilityIdentifier("accuseNow.confirm")
            Button(L10n.t("accuseNow.cancel"), action: onCancel).buttonStyle(TertiaryButtonStyle()).frame(maxWidth: .infinity)
        }
        .padding(Theme.Spacing.marginGame)
    }
}

// MARK: - Notebook (screen 28–29)

struct NotebookView: View {
    let session: GameSession
    let onAccuse: () -> Void
    @State private var tab = 0
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        let game = session.game
        NavigationStack {
            VStack(alignment: .leading, spacing: Theme.Spacing.s5) {
                HStack(alignment: .firstTextBaseline) {
                    Text(L10n.t("carnet.title")).font(Theme.Fonts.titleLarge).foregroundStyle(Theme.Colors.textPrimary)
                        .accessibilityIdentifier("notebook.title")
                    Spacer()
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(Theme.Fonts.headline)
                            .foregroundStyle(Theme.Colors.textSecondary)
                            .frame(width: Theme.Size.hit, height: Theme.Size.hit)
                            .background(Circle().fill(Theme.Colors.bgRaised))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(Text(L10n.t("a11y.close")))
                    .accessibilityIdentifier("notebook.close")
                }
                Segmented(options: [(0, L10n.t("carnet.suspects")),
                                    (1, L10n.f("carnet.evidence", game.notebook.count)),
                                    (2, L10n.t("carnet.timeline"))], selection: $tab)
                ScrollView {
                    switch tab {
                    case 0: suspects(game)
                    case 1: evidence(game, chronological: false)
                    default: evidence(game, chronological: true)
                    }
                }
                Button(L10n.t("carnet.accuse"), action: onAccuse)
                    .buttonStyle(SecondaryButtonStyle(tint: Theme.Colors.textPrimary))
                    .accessibilityIdentifier("notebook.accuse")
            }
            .padding(Theme.Spacing.marginList)
            .background(Theme.Colors.ink0.ignoresSafeArea())
            .navigationDestination(for: SuspectID.self) { id in
                SuspectFileView(suspectID: id, session: session)
            }
        }
    }

    private func suspects(_ game: Investigation) -> some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible())], spacing: 10) {
            ForEach(session.caseFile.suspects) { suspect in
                let linked = game.linkedEntries(for: suspect.id).count
                NavigationLink(value: suspect.id) {
                    VStack(spacing: Theme.Spacing.s3) {
                        Portrait(contact: game.contact(suspect.contact), width: Theme.Size.portrait, height: Theme.Size.portrait)
                        Text(game.name(of: suspect.contact)).font(Theme.Fonts.headline).foregroundStyle(Theme.Colors.textPrimary).lineLimit(1)
                        Text(suspect.role).font(Theme.Fonts.caption).foregroundStyle(Theme.Colors.textSecondary).lineLimit(1)
                        Text(L10n.f("carnet.linked", linked))
                            .font(Theme.Fonts.data)
                            .foregroundStyle(linked > 0 ? Theme.Colors.signal : Theme.Colors.textTertiary)
                    }
                    .padding(Theme.Spacing.s5)
                    .frame(maxWidth: .infinity)
                    .background(RoundedRectangle(cornerRadius: Theme.Radius.lg).fill(Theme.Colors.bgSurface))
                    .elevation0(Theme.Radius.lg)
                }
                .buttonStyle(.plain)
            }
        }
    }

    @ViewBuilder
    private func evidence(_ game: Investigation, chronological: Bool) -> some View {
        let items = game.notebook.map { NotebookRow(entry: $0, item: ItemDescriber.describe($0.ref, in: game)) }
        let sorted = chronological
            ? items.sorted { ($0.item.at ?? Moment(seconds: .max)) < ($1.item.at ?? Moment(seconds: .max)) }
            : items.sorted { ($0.item.at ?? Moment(seconds: 0)) > ($1.item.at ?? Moment(seconds: 0)) }
        if items.isEmpty {
            EmptyStateView(title: L10n.t("carnet.emptyTitle"), message: L10n.t("carnet.emptyMessage"))
        } else {
            VStack(alignment: .leading, spacing: 0) {
                ForEach(sorted) { row in
                    EvidenceRow(item: row.item, linkedName: row.entry.linkedTo.flatMap { id in
                        session.caseFile.suspects.first { $0.id == id }.map { game.name(of: $0.contact) }
                    }, timeline: chronological)
                    .accessibilityIdentifier("notebook.row")
                    .contextMenu {
                        ForEach(session.caseFile.suspects) { suspect in
                            Button(game.name(of: suspect.contact)) { session.link(row.entry.ref, to: suspect.id) }
                        }
                        Button(L10n.t("pin.unlink")) { session.link(row.entry.ref, to: nil) }
                        Button(L10n.t("pin.remove"), role: .destructive) { session.togglePin(row.entry.ref) }
                    }
                }
            }
        }
    }
}

struct NotebookRow: Identifiable {
    let entry: NotebookEntry
    let item: ItemDescriber.Item
    var id: ItemRef { entry.ref }
}

/// EvidenceRow: mono time + label + source app (h 48). Timeline mode draws the vertical axis.
struct EvidenceRow: View {
    let item: ItemDescriber.Item
    let linkedName: String?
    var timeline = false

    var body: some View {
        HStack(alignment: .top, spacing: Theme.Spacing.s4) {
            if timeline {
                VStack(spacing: 0) {
                    Circle().fill(Theme.Colors.signal).frame(width: 7, height: 7).padding(.top, 5)
                    Rectangle().fill(Theme.Colors.line2).frame(width: 1)
                }
            }
            Text(item.at.map { PhoneFormat.time($0) } ?? "—")
                .font(Theme.Fonts.dataStrong)
                .foregroundStyle(Theme.Colors.textPrimary)
                .frame(width: 44, alignment: .leading)
            VStack(alignment: .leading, spacing: 2) {
                Text(item.label).font(Theme.Fonts.callout).foregroundStyle(Theme.Colors.textPrimary).lineLimit(2)
                HStack(spacing: Theme.Spacing.s3) {
                    Text(item.app.title).overline(Theme.Colors.textTertiary)
                    if let at = item.at { Text(PhoneFormat.shortDay(at)).font(Theme.Fonts.dataSmall).foregroundStyle(Theme.Colors.textTertiary) }
                    if let linkedName { Text("→ " + linkedName).font(Theme.Fonts.dataSmall).foregroundStyle(Theme.Colors.signal) }
                }
            }
            Spacer(minLength: 0)
        }
        .frame(minHeight: Theme.Size.evidenceRow)
        .padding(.vertical, Theme.Spacing.s2)
        .overlay(alignment: .bottom) { if !timeline { Rectangle().fill(Theme.Colors.line1).frame(height: 1) } }
    }
}

/// Screen 29 — a suspect's file: what they claim (narrative voice), what the player linked, own ticks.
struct SuspectFileView: View {
    let suspectID: SuspectID
    let session: GameSession

    var body: some View {
        let game = session.game
        if let suspect = game.index.suspect(suspectID) {
            let contact = game.contact(suspect.contact)
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.s6) {
                    HStack(alignment: .top, spacing: Theme.Spacing.s5) {
                        Portrait(contact: contact, width: 84, height: 104)
                        VStack(alignment: .leading, spacing: Theme.Spacing.s2) {
                            Text(game.name(of: suspect.contact)).font(Theme.Fonts.title2).foregroundStyle(Theme.Colors.textPrimary)
                            Text(suspect.role).font(Theme.Fonts.callout).foregroundStyle(Theme.Colors.textSecondary)
                            HStack(spacing: Theme.Spacing.s3) {
                                if let age = suspect.age { Text(L10n.f("suspect.age", age)) }
                                if let address = suspect.address { Text(address) }
                            }
                            .font(Theme.Fonts.data)
                            .foregroundStyle(Theme.Colors.textTertiary)
                        }
                    }
                    VStack(alignment: .leading, spacing: Theme.Spacing.s3) {
                        Text(L10n.t("suspect.claims")).overline()
                        Text(suspect.statement).font(Theme.Fonts.narrativeSmall).foregroundStyle(Theme.Colors.textPrimary)
                    }
                    VStack(alignment: .leading, spacing: Theme.Spacing.s3) {
                        Text(L10n.t("suspect.marks")).overline()
                        ForEach(SuspectMark.allCases, id: \.self) { mark in
                            let on = game.marks[suspect.id]?.contains(mark) == true
                            Button {
                                session.perform { $0.toggle(mark, for: suspect.id) }
                                Haptics.selection()
                            } label: {
                                HStack(spacing: Theme.Spacing.s4) {
                                    Text(on ? "☑" : "☐").font(Theme.Fonts.headline).foregroundStyle(on ? Theme.Colors.signal : Theme.Colors.textSecondary)
                                    Text(L10n.t("mark.\(mark.rawValue)")).font(Theme.Fonts.body).foregroundStyle(Theme.Colors.textPrimary)
                                    Spacer()
                                }
                                .frame(minHeight: Theme.Size.hit)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .accessibilityAddTraits(on ? .isSelected : [])
                        }
                    }
                    VStack(alignment: .leading, spacing: Theme.Spacing.s3) {
                        let linked = game.linkedEntries(for: suspect.id)
                            .map { ItemDescriber.describe($0.ref, in: game) }
                            .sorted { ($0.at ?? Moment(seconds: 0)) < ($1.at ?? Moment(seconds: 0)) }
                        Text(L10n.f("suspect.linked", linked.count)).overline()
                        if linked.isEmpty {
                            Text(L10n.t("suspect.noLinked")).font(Theme.Fonts.callout).foregroundStyle(Theme.Colors.textTertiary)
                        }
                        ForEach(Array(linked.enumerated()), id: \.offset) { _, item in
                            EvidenceRow(item: item, linkedName: nil)
                        }
                    }
                }
                .padding(Theme.Spacing.marginList)
            }
            .background(Theme.Colors.ink0.ignoresSafeArea())
        }
    }
}

// MARK: - Hints (screen 30)

struct HintsView: View {
    let session: GameSession

    var body: some View {
        let game = session.game
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.s5) {
                Text(L10n.t("hints.title")).font(Theme.Fonts.title).foregroundStyle(Theme.Colors.textPrimary)
                Text(L10n.t("hints.explain")).font(Theme.Fonts.callout).foregroundStyle(Theme.Colors.textSecondary)
                ForEach(Array(game.caseFile.hints.enumerated()), id: \.element.id) { offset, hint in
                    HintCard(number: offset + 1, hint: hint, state: game.state(of: hint)) {
                        _ = session.useHint()
                    }
                }
            }
            .padding(Theme.Spacing.marginGame)
        }
    }
}

struct HintCard: View {
    let number: Int
    let hint: Hint
    let state: Investigation.HintState
    let onReveal: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.s3) {
            HStack {
                Text(L10n.f("hints.tier", number)).overline(state == .revealed ? Theme.Colors.signal : Theme.Colors.textSecondary)
                Spacer()
                Text(hint.scoreCost == 0 ? L10n.t("hints.free") : L10n.f("hints.cost", hint.scoreCost))
                    .font(Theme.Fonts.data)
                    .foregroundStyle(Theme.Colors.textTertiary)
            }
            switch state {
            case .revealed:
                Text(hint.text).font(Theme.Fonts.narrativeSmall).foregroundStyle(Theme.Colors.textPrimary)
            case .available:
                Button(L10n.t("hints.reveal"), action: onReveal).buttonStyle(SecondaryButtonStyle(height: Theme.Size.buttonS))
            case .locked(let until):
                Text(until > 0 ? L10n.f("hints.lockedUntil", PhoneFormat.countdown(Double(until))) : L10n.t("hints.lockedPrevious"))
                    .font(Theme.Fonts.callout)
                    .foregroundStyle(Theme.Colors.textTertiary)
            }
        }
        .padding(Theme.Spacing.s5)
        .background(RoundedRectangle(cornerRadius: Theme.Radius.lg).fill(Theme.Colors.bgSurface))
        .overlay(RoundedRectangle(cornerRadius: Theme.Radius.lg).strokeBorder(state == .revealed ? Theme.Colors.signalLine : Theme.Colors.line1))
    }
}
#endif
