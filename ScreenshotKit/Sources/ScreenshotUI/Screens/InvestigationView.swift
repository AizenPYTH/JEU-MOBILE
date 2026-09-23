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
                            .presentationDetents([.height(340), .medium])
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
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
            Button(L10n.t("accuseNow.confirm"), action: onAccuse).buttonStyle(PrimaryButtonStyle(height: Theme.Size.buttonM))
                .accessibilityIdentifier("accuseNow.confirm")
            Button(L10n.t("accuseNow.cancel"), action: onCancel).buttonStyle(TertiaryButtonStyle()).frame(maxWidth: .infinity)
        }
        .padding(Theme.Spacing.marginGame)
    }
}

// MARK: - Notebook (screen 28–29)

/// The investigation notebook. Always answers: what am I looking for (objective), how far am I
/// (pinned · linked · apps explored), who are the suspects, what did I find, in what order, and
/// what have I concluded so far. It only shows what the player found and decided — never a verdict.
struct NotebookView: View {
    let session: GameSession
    let onAccuse: () -> Void
    @State private var tab = 0
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        let game = session.game
        NavigationStack {
            VStack(alignment: .leading, spacing: Theme.Spacing.s4) {
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(L10n.f("carnet.caseOverline", session.caseFile.number)).overline(Theme.Colors.special)
                        Text(L10n.t("carnet.title")).font(Theme.Fonts.titleLarge).foregroundStyle(Theme.Colors.textPrimary)
                            .accessibilityIdentifier("notebook.title")
                    }
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
                ObjectiveCard(objective: session.caseFile.objective)
                    .accessibilityIdentifier("notebook.objective")
                NotebookProgress(pinned: game.notebook.count,
                                 linked: game.notebook.filter { $0.linkedTo != nil }.count,
                                 apps: game.openedApps.count, totalApps: AppID.allCases.count)
                Segmented(options: [(0, L10n.t("carnet.suspects")),
                                    (1, L10n.f("carnet.evidence", game.notebook.count)),
                                    (2, L10n.t("carnet.timeline")),
                                    (3, L10n.t("carnet.notes"))], selection: $tab, identifier: "notebook.tab")
                ScrollView {
                    switch tab {
                    case 0: suspects(game)
                    case 1: evidence(game)
                    case 2: timeline(game)
                    default: deductions(game)
                    }
                }
                Button(action: onAccuse) {
                    Label(L10n.t("carnet.accuse"), systemImage: "person.fill.questionmark")
                }
                .buttonStyle(PrimaryButtonStyle(height: Theme.Size.buttonM))
                .accessibilityIdentifier("notebook.accuse")
            }
            .padding(.horizontal, Theme.Spacing.marginList)
            .padding(.top, Theme.Spacing.s5)
            .padding(.bottom, Theme.Spacing.s4)
            .background(Theme.Colors.ink0.ignoresSafeArea())
            .navigationDestination(for: SuspectID.self) { id in
                SuspectFileView(suspectID: id, session: session)
            }
        }
    }

    private func suspects(_ game: Investigation) -> some View {
        VStack(spacing: Theme.Spacing.s3) {
            ForEach(session.caseFile.suspects) { suspect in
                NavigationLink(value: suspect.id) {
                    SuspectCard(suspect: suspect, game: game)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, Theme.Spacing.s2)
    }

    @ViewBuilder
    private func evidence(_ game: Investigation) -> some View {
        let rows = game.notebook.map { NotebookRow(entry: $0, item: ItemDescriber.describe($0.ref, in: game)) }
            .sorted { ($0.item.at ?? Moment(seconds: 0)) > ($1.item.at ?? Moment(seconds: 0)) }
        if rows.isEmpty {
            EmptyStateView(title: L10n.t("carnet.emptyTitle"), message: L10n.t("carnet.emptyMessage"))
        } else {
            let linked = rows.filter { $0.entry.linkedTo != nil }
            let loose = rows.filter { $0.entry.linkedTo == nil }
            VStack(alignment: .leading, spacing: Theme.Spacing.s2) {
                Label(L10n.t("carnet.linkHelp"), systemImage: "hand.tap")
                    .font(Theme.Fonts.caption)
                    .foregroundStyle(Theme.Colors.textSecondary)
                    .padding(.vertical, Theme.Spacing.s2)
                if !linked.isEmpty {
                    Text(L10n.f("carnet.linkedSection", linked.count)).overline(Theme.Colors.special).padding(.top, Theme.Spacing.s3)
                    ForEach(linked) { row in evidenceRow(row, game: game, timeline: false) }
                }
                if !loose.isEmpty {
                    Text(L10n.f("carnet.looseSection", loose.count)).overline().padding(.top, Theme.Spacing.s3)
                    ForEach(loose) { row in evidenceRow(row, game: game, timeline: false) }
                }
            }
        }
    }

    @ViewBuilder
    private func timeline(_ game: Investigation) -> some View {
        let rows = game.notebook.map { NotebookRow(entry: $0, item: ItemDescriber.describe($0.ref, in: game)) }
            .sorted { ($0.item.at ?? Moment(seconds: .max)) < ($1.item.at ?? Moment(seconds: .max)) }
        if rows.isEmpty {
            EmptyStateView(title: L10n.t("carnet.emptyTitle"), message: L10n.t("carnet.emptyMessage"))
        } else {
            VStack(alignment: .leading, spacing: 0) {
                ForEach(Array(rows.enumerated()), id: \.element.id) { offset, row in
                    let previous = offset > 0 ? rows[offset - 1].item.at : nil
                    if let at = row.item.at, previous.map({ !$0.isSameDay(as: at) }) ?? true {
                        Text(PhoneFormat.separatorCaps(at)).overline(Theme.Colors.info)
                            .padding(.top, offset == 0 ? Theme.Spacing.s3 : Theme.Spacing.s5)
                            .padding(.bottom, Theme.Spacing.s2)
                    }
                    evidenceRow(row, game: game, timeline: true)
                }
            }
        }
    }

    /// The player's own conclusions: the ticks of each suspect's file, side by side.
    private func deductions(_ game: Investigation) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.s3) {
            Text(L10n.t("carnet.notesHelp"))
                .font(Theme.Fonts.caption)
                .foregroundStyle(Theme.Colors.textSecondary)
                .padding(.vertical, Theme.Spacing.s2)
            ForEach(session.caseFile.suspects) { suspect in
                NavigationLink(value: suspect.id) {
                    DeductionCard(suspect: suspect, game: game)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func evidenceRow(_ row: NotebookRow, game: Investigation, timeline: Bool) -> some View {
        EvidenceRow(item: row.item, linkedName: row.entry.linkedTo.flatMap { id in
            session.caseFile.suspects.first { $0.id == id }.map { game.name(of: $0.contact) }
        }, timeline: timeline)
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

/// "Votre objectif" — what the player is looking for, always one tap away.
struct ObjectiveCard: View {
    let objective: String

    var body: some View {
        HStack(alignment: .top, spacing: Theme.Spacing.s3) {
            Image(systemName: "scope").font(.system(size: 15, weight: .semibold)).foregroundStyle(Theme.Colors.special)
                .padding(.top, 2)
            VStack(alignment: .leading, spacing: 2) {
                Text(L10n.t("carnet.objective")).overline(Theme.Colors.special)
                Text(objective).font(Theme.Fonts.callout).foregroundStyle(Theme.Colors.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(Theme.Spacing.s4)
        .background(RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous).fill(Theme.Colors.specialTint))
        .overlay(RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous).strokeBorder(Theme.Colors.special.opacity(0.35)))
        .accessibilityElement(children: .combine)
    }
}

/// Where the player stands — only their own actions: pinned, linked, apps explored.
struct NotebookProgress: View {
    let pinned: Int
    let linked: Int
    let apps: Int
    let totalApps: Int

    var body: some View {
        HStack(spacing: Theme.Spacing.s3) {
            stat("◆", "\(pinned)", L10n.t("carnet.statPinned"), Theme.Colors.signal)
            stat("⟷", "\(linked)", L10n.t("carnet.statLinked"), Theme.Colors.special)
            stat("▦", "\(apps)/\(totalApps)", L10n.t("carnet.statApps"), Theme.Colors.info)
        }
    }

    private func stat(_ symbol: String, _ value: String, _ label: String, _ color: Color) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            HStack(spacing: 4) {
                Text(symbol).foregroundStyle(color)
                Text(value).foregroundStyle(Theme.Colors.textPrimary).contentTransition(.numericText())
            }
            .font(Theme.Fonts.dataStrong)
            Text(label).font(Theme.Fonts.caption).foregroundStyle(Theme.Colors.textSecondary).lineLimit(1).minimumScaleFactor(0.8)
        }
        .padding(.horizontal, Theme.Spacing.s3)
        .padding(.vertical, Theme.Spacing.s2)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: Theme.Radius.sm, style: .continuous).fill(Theme.Colors.bgSurface))
        .accessibilityElement(children: .combine)
    }
}

/// A suspect in the notebook: portrait, name, role, linked items, the player's ticks.
struct SuspectCard: View {
    let suspect: Suspect
    let game: Investigation

    var body: some View {
        let linked = game.linkedEntries(for: suspect.id).count
        let marks = SuspectMark.allCases.filter { game.marks[suspect.id]?.contains($0) == true }
        HStack(spacing: Theme.Spacing.s4) {
            Portrait(contact: game.contact(suspect.contact), width: 56, height: 64)
            VStack(alignment: .leading, spacing: 3) {
                Text(game.name(of: suspect.contact)).font(Theme.Fonts.headline).foregroundStyle(Theme.Colors.textPrimary).lineLimit(1)
                Text(suspect.role).font(Theme.Fonts.caption).foregroundStyle(Theme.Colors.textSecondary).lineLimit(1)
                HStack(spacing: Theme.Spacing.s2) {
                    Chip(text: L10n.f("carnet.linked", linked), color: linked > 0 ? Theme.Colors.special : Theme.Colors.textTertiary)
                    if !marks.isEmpty {
                        Chip(text: L10n.f("carnet.marksCount", marks.count), color: Theme.Colors.signal)
                    }
                }
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.right").font(.system(size: 13, weight: .semibold)).foregroundStyle(Theme.Colors.textTertiary)
        }
        .padding(Theme.Spacing.s4)
        .background(RoundedRectangle(cornerRadius: Theme.Radius.lg, style: .continuous).fill(Theme.Colors.bgSurface))
        .elevation0(Theme.Radius.lg)
        .contentShape(Rectangle())
    }
}

/// One suspect's ticks, read-only, in the "Notes" tab.
struct DeductionCard: View {
    let suspect: Suspect
    let game: Investigation

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.s3) {
            HStack(spacing: Theme.Spacing.s3) {
                Avatar(contact: game.contact(suspect.contact), size: 30)
                Text(game.name(of: suspect.contact)).font(Theme.Fonts.headline).foregroundStyle(Theme.Colors.textPrimary)
                Spacer()
                Image(systemName: "chevron.right").font(.system(size: 13, weight: .semibold)).foregroundStyle(Theme.Colors.textTertiary)
            }
            ForEach(SuspectMark.allCases, id: \.self) { mark in
                let on = game.marks[suspect.id]?.contains(mark) == true
                HStack(spacing: Theme.Spacing.s3) {
                    Image(systemName: on ? "checkmark.square.fill" : "square")
                        .foregroundStyle(on ? Theme.Colors.signal : Theme.Colors.textTertiary)
                    Text(L10n.t("mark.\(mark.rawValue)"))
                        .font(Theme.Fonts.callout)
                        .foregroundStyle(on ? Theme.Colors.textPrimary : Theme.Colors.textTertiary)
                }
                .accessibilityElement(children: .combine)
                .accessibilityAddTraits(on ? .isSelected : [])
            }
        }
        .padding(Theme.Spacing.s4)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: Theme.Radius.lg, style: .continuous).fill(Theme.Colors.bgSurface))
        .elevation0(Theme.Radius.lg)
        .contentShape(Rectangle())
    }
}

/// Small rounded label ("2 liés", "◆ Épinglé"…).
struct Chip: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text)
            .font(Theme.Fonts.dataSmall)
            .foregroundStyle(color)
            .padding(.horizontal, 7)
            .frame(height: 20)
            .background(Capsule().fill(color.opacity(0.14)))
            .lineLimit(1)
    }
}

struct NotebookRow: Identifiable {
    let entry: NotebookEntry
    let item: ItemDescriber.Item
    var id: ItemRef { entry.ref }
}

/// EvidenceRow: source app icon + mono time + label; the suspect it is linked to as a violet chip.
/// Timeline mode draws the vertical axis.
struct EvidenceRow: View {
    let item: ItemDescriber.Item
    let linkedName: String?
    var timeline = false

    var body: some View {
        HStack(alignment: .top, spacing: Theme.Spacing.s3) {
            if timeline {
                VStack(spacing: 0) {
                    Circle().fill(linkedName == nil ? Theme.Colors.signal : Theme.Colors.special).frame(width: 9, height: 9).padding(.top, 10)
                    Rectangle().fill(Theme.Colors.line2).frame(width: 1)
                }
                .frame(width: 10)
            }
            AppTileGlyph(app: item.app, size: 28)
                .padding(.top, 2)
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: Theme.Spacing.s3) {
                    Text(item.at.map { PhoneFormat.time($0) } ?? "—")
                        .font(Theme.Fonts.dataStrong)
                        .foregroundStyle(Theme.Colors.textPrimary)
                    if let at = item.at, !timeline {
                        Text(PhoneFormat.shortDay(at)).font(Theme.Fonts.dataSmall).foregroundStyle(Theme.Colors.textTertiary)
                    }
                    Text(item.app.title).font(Theme.Fonts.caption).foregroundStyle(Theme.Colors.textTertiary)
                }
                Text(item.label).font(Theme.Fonts.callout).foregroundStyle(Theme.Colors.textPrimary).lineLimit(3)
                if let linkedName {
                    Chip(text: "→ " + linkedName, color: Theme.Colors.special)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(Theme.Spacing.s3)
        .frame(minHeight: Theme.Size.evidenceRow)
        .background(RoundedRectangle(cornerRadius: Theme.Radius.sm, style: .continuous)
            .fill(linkedName == nil ? Theme.Colors.bgSurface : Theme.Colors.specialTint))
        .overlay(alignment: .leading) {
            if linkedName != nil {
                RoundedRectangle(cornerRadius: 2).fill(Theme.Colors.special).frame(width: 3).padding(.vertical, Theme.Spacing.s3)
            }
        }
        .padding(.bottom, timeline ? 0 : Theme.Spacing.s1)
        .accessibilityElement(children: .combine)
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
                        Label(L10n.t("suspect.claims"), systemImage: "quote.opening").overline(Theme.Colors.info)
                        Text(suspect.statement).font(Theme.Fonts.narrativeSmall).foregroundStyle(Theme.Colors.textPrimary)
                    }
                    .padding(Theme.Spacing.s4)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous).fill(Theme.Colors.bgSurface))
                    .overlay(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 2).fill(Theme.Colors.info).frame(width: 3).padding(.vertical, Theme.Spacing.s4)
                    }
                    VStack(alignment: .leading, spacing: Theme.Spacing.s3) {
                        Text(L10n.t("suspect.marks")).overline(Theme.Colors.signal)
                        Text(L10n.t("suspect.marksHelp")).font(Theme.Fonts.caption).foregroundStyle(Theme.Colors.textSecondary)
                        ForEach(SuspectMark.allCases, id: \.self) { mark in
                            let on = game.marks[suspect.id]?.contains(mark) == true
                            Button {
                                session.perform { $0.toggle(mark, for: suspect.id) }
                                Haptics.selection()
                            } label: {
                                HStack(spacing: Theme.Spacing.s4) {
                                    Image(systemName: on ? "checkmark.square.fill" : "square")
                                        .font(.system(size: 20))
                                        .foregroundStyle(on ? Theme.Colors.signal : Theme.Colors.textSecondary)
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
                        Text(L10n.f("suspect.linked", linked.count)).overline(Theme.Colors.special)
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
