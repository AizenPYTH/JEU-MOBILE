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
                SuspectFileView(suspectID: id, session: session) { app, route in
                    dismiss()
                    session.launch(app, then: route)
                }
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
                .accessibilityIdentifier("notebook.suspect.\(suspect.id)")
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
        }, timeline: timeline, person: row.item.person.flatMap { game.contact($0) })
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
                        Chip(text: L10n.f("n.notes", marks.count), color: Theme.Colors.signal)
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
    /// WHO (timeline mode): the person the item is about or from.
    var person: Contact? = nil

    /// In the timeline the person has their own line, so "Emma · « … »" loses its prefix.
    private var label: String {
        guard timeline, let person, item.label.hasPrefix(person.name + " · ") else { return item.label }
        return String(item.label.dropFirst(person.name.count + 3))
    }

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
                Text(label).font(Theme.Fonts.callout).foregroundStyle(Theme.Colors.textPrimary).lineLimit(3)
                if timeline, person != nil || item.place != nil {
                    HStack(spacing: Theme.Spacing.s3) {
                        if let person {
                            HStack(spacing: 4) {
                                Avatar(contact: person, size: 18)
                                Text(person.name).lineLimit(1)
                            }
                        }
                        if let place = item.place {
                            Label(place, systemImage: "mappin").lineLimit(1)
                        }
                    }
                    .font(Theme.Fonts.caption)
                    .foregroundStyle(Theme.Colors.textSecondary)
                }
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

/// Screen 29 — a suspect's file. Everything the player needs to build (or drop) a hypothesis,
/// and nothing that concludes for them: who they are, what the phone holds about them (with
/// shortcuts), what they claim, the player's ticks, and the chain of items the player linked —
/// each one marked by the player as against them or in their favour.
struct SuspectFileView: View {
    let suspectID: SuspectID
    let session: GameSession
    /// Opens something in the phone (closes the notebook). nil where the phone is not reachable.
    var onOpenInPhone: ((AppID, PhoneRoute?) -> Void)? = nil

    var body: some View {
        let game = session.game
        if let suspect = game.index.suspect(suspectID) {
            let contact = game.contact(suspect.contact)
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.s6) {
                    header(suspect, contact: contact, game: game)
                    phoneFacts(suspect, game: game)
                    statement(suspect)
                    marks(suspect, game: game)
                    LinkedChain(suspect: suspect, session: session)
                }
                .padding(Theme.Spacing.marginList)
            }
            .background(Theme.Colors.ink0.ignoresSafeArea())
        }
    }

    private func header(_ suspect: Suspect, contact: Contact?, game: Investigation) -> some View {
        HStack(alignment: .top, spacing: Theme.Spacing.s5) {
            Portrait(contact: contact, width: 84, height: 104)
            VStack(alignment: .leading, spacing: Theme.Spacing.s2) {
                Text(L10n.t("suspect.overline")).overline(Theme.Colors.special)
                Text(game.name(of: suspect.contact)).font(Theme.Fonts.title2).foregroundStyle(Theme.Colors.textPrimary)
                    .accessibilityIdentifier("suspect.name")
                Text(suspect.role).font(Theme.Fonts.callout).foregroundStyle(Theme.Colors.textSecondary)
                HStack(spacing: Theme.Spacing.s3) {
                    if let age = suspect.age { Text(L10n.f("suspect.age", age)) }
                    if let address = suspect.address { Text(address) }
                }
                .font(Theme.Fonts.data)
                .foregroundStyle(Theme.Colors.textTertiary)
            }
        }
    }

    /// What the seized phone holds about this person: facts and shortcuts, never a reading.
    @ViewBuilder
    private func phoneFacts(_ suspect: Suspect, game: Investigation) -> some View {
        let conversation = game.device.conversations.first { !$0.isGroup && $0.participants == [suspect.contact] }
        let messages = conversation.map { game.visibleMessages(in: $0.id).count } ?? 0
        let calls = game.calls.filter { $0.contact == suspect.contact }.count
        let phone = game.contact(suspect.contact)?.phone
        VStack(alignment: .leading, spacing: Theme.Spacing.s3) {
            Label(L10n.t("suspect.inPhone"), systemImage: "iphone").overline(Theme.Colors.info)
            HStack(spacing: Theme.Spacing.s3) {
                fact(symbol: "bubble.left.and.bubble.right.fill", color: Theme.appAccent(.messages), value: L10n.f("suspect.messagesCount", messages)) {
                    if let conversation { onOpenInPhone?(.messages, .conversation(conversation.id)) }
                }
                .disabled(conversation == nil || onOpenInPhone == nil)
                fact(symbol: "phone.fill", color: Theme.appAccent(.phone), value: L10n.f("n.calls", calls)) {
                    onOpenInPhone?(.phone, nil)
                }
                .disabled(calls == 0 || onOpenInPhone == nil)
            }
            if let phone {
                Text(phone).font(Theme.Fonts.data).foregroundStyle(Theme.Colors.textTertiary)
            }
            if onOpenInPhone != nil {
                Text(L10n.t("suspect.shortcutHelp")).font(Theme.Fonts.caption).foregroundStyle(Theme.Colors.textTertiary)
            }
        }
    }

    private func fact(symbol: String, color: Color, value: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: Theme.Spacing.s3) {
                SymbolTile(symbol: symbol, color: color.opacity(0.85), size: 26)
                Text(value).font(Theme.Fonts.calloutStrong).foregroundStyle(Theme.Colors.textPrimary)
                Spacer(minLength: 0)
                if onOpenInPhone != nil {
                    Image(systemName: "arrow.up.forward").font(.system(size: 11, weight: .bold)).foregroundStyle(Theme.Colors.textTertiary)
                }
            }
            .padding(Theme.Spacing.s3)
            .frame(maxWidth: .infinity, minHeight: Theme.Size.hit)
            .background(RoundedRectangle(cornerRadius: Theme.Radius.sm, style: .continuous).fill(Theme.Colors.bgSurface))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func statement(_ suspect: Suspect) -> some View {
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
    }

    private func marks(_ suspect: Suspect, game: Investigation) -> some View {
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
    }
}

/// SUSPECT → ITEM → WHEN → WHERE: the items the player linked to a suspect, in time order,
/// hanging from the suspect on a thin line. Each can be marked "l'accuse" / "le disculpe".
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
        VStack(alignment: .leading, spacing: Theme.Spacing.s3) {
            Text(L10n.f("suspect.linked", entries.count)).overline(Theme.Colors.special)
            if entries.isEmpty {
                Text(L10n.t("suspect.noLinked")).font(Theme.Fonts.callout).foregroundStyle(Theme.Colors.textTertiary)
            } else {
                HStack(spacing: Theme.Spacing.s2) {
                    Chip(text: L10n.f("suspect.againstCount", against), color: Theme.Colors.alertText)
                    Chip(text: L10n.f("suspect.favourCount", favour), color: Theme.Colors.clear)
                }
                Text(L10n.t("suspect.stanceHelp")).font(Theme.Fonts.caption).foregroundStyle(Theme.Colors.textSecondary)
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(Array(entries.enumerated()), id: \.offset) { offset, row in
                        chainRow(row.entry, item: row.item, last: offset == entries.count - 1, game: game)
                    }
                }
            }
        }
    }

    private func chainRow(_ entry: NotebookEntry, item: ItemDescriber.Item, last: Bool, game: Investigation) -> some View {
        HStack(alignment: .top, spacing: Theme.Spacing.s3) {
            VStack(spacing: 0) {
                Circle().fill(color(entry.stance)).frame(width: 10, height: 10).padding(.top, 14)
                if !last { Rectangle().fill(Theme.Colors.line3).frame(width: 1) }
            }
            .frame(width: 12)
            VStack(alignment: .leading, spacing: Theme.Spacing.s2) {
                HStack(spacing: Theme.Spacing.s3) {
                    AppTileGlyph(app: item.app, size: 22)
                    Text(item.at.map { PhoneFormat.shortDay($0) + " · " + PhoneFormat.time($0) } ?? "—")
                        .font(Theme.Fonts.dataStrong).foregroundStyle(Theme.Colors.textPrimary)
                }
                Text(item.label).font(Theme.Fonts.callout).foregroundStyle(Theme.Colors.textPrimary).lineLimit(3)
                if let place = item.place {
                    Label(place, systemImage: "mappin").font(Theme.Fonts.caption).foregroundStyle(Theme.Colors.textSecondary)
                }
                HStack(spacing: Theme.Spacing.s2) {
                    stanceButton(.incriminates, entry: entry)
                    stanceButton(.clears, entry: entry)
                }
            }
            .padding(Theme.Spacing.s3)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: Theme.Radius.sm, style: .continuous).fill(Theme.Colors.bgSurface))
            .padding(.bottom, Theme.Spacing.s3)
        }
    }

    private func stanceButton(_ stance: NotebookEntry.Stance, entry: NotebookEntry) -> some View {
        let on = entry.stance == stance
        let color = stance == .incriminates ? Theme.Colors.alertText : Theme.Colors.clear
        return Button {
            session.setStance(on ? nil : stance, for: entry.ref)
        } label: {
            Label(L10n.t(stance == .incriminates ? "suspect.stanceAgainst" : "suspect.stanceFavour"),
                  systemImage: stance == .incriminates ? "arrow.up.right.circle.fill" : "checkmark.shield.fill")
                .font(Theme.Fonts.caption)
                .foregroundStyle(on ? Theme.Colors.textPrimary : color)
                .padding(.horizontal, Theme.Spacing.s3)
                .frame(minHeight: 32)
                .background(Capsule().fill(on ? color.opacity(0.35) : color.opacity(0.1)))
                .overlay(Capsule().strokeBorder(on ? color : .clear, lineWidth: 1))
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(on ? .isSelected : [])
    }

    private func color(_ stance: NotebookEntry.Stance?) -> Color {
        switch stance {
        case .incriminates: Theme.Colors.alertText
        case .clears: Theme.Colors.clear
        case nil: Theme.Colors.special
        }
    }
}

// MARK: - Hints (screen 30)

/// "Aide à l'enquête": three tiers (a lead, where to look, the evidence). Each one says what it
/// gives and what it costs — score points, never time — and what the best possible score becomes.
struct HintsView: View {
    let session: GameSession
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        let game = session.game
        let maxScore = max(0, 100 - game.hintScoreCost)
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.s5) {
                HStack(alignment: .top) {
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
                    .accessibilityIdentifier("hints.close")
                }
                .padding(.bottom, -Theme.Spacing.s8)
                VStack(alignment: .leading, spacing: Theme.Spacing.s2) {
                    Text(L10n.t("hints.overline")).overline(Theme.Colors.signal)
                    Text(L10n.t("hints.title")).font(Theme.Fonts.title).foregroundStyle(Theme.Colors.textPrimary)
                    Text(L10n.t("hints.explain")).font(Theme.Fonts.callout).foregroundStyle(Theme.Colors.textSecondary)
                }
                HStack {
                    Label(L10n.t("hints.maxScore"), systemImage: "rosette")
                        .font(Theme.Fonts.callout)
                        .foregroundStyle(Theme.Colors.textSecondary)
                    Spacer()
                    Text("\(maxScore) %")
                        .font(Theme.Fonts.dataStrong)
                        .foregroundStyle(maxScore < 100 ? Theme.Colors.signal : Theme.Colors.textPrimary)
                        .contentTransition(.numericText())
                        .animation(Theme.Motion.emphasized(0.3), value: maxScore)
                }
                .padding(Theme.Spacing.s4)
                .background(RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous).fill(Theme.Colors.bgSurface))
                ForEach(Array(game.caseFile.hints.enumerated()), id: \.element.id) { offset, hint in
                    HintCard(number: offset + 1, hint: hint, state: game.state(of: hint), scoreAfter: maxScore - hint.scoreCost) {
                        if session.useHint() != nil { Haptics.success() }
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
    /// Best possible score once this hint is used.
    let scoreAfter: Int
    let onReveal: () -> Void

    private var tierName: String { L10n.t("hints.tierName\(min(number, 3))") }

    var body: some View {
        let revealed = state == .revealed
        VStack(alignment: .leading, spacing: Theme.Spacing.s3) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(L10n.f("hints.tier", number)).overline(revealed ? Theme.Colors.signal : Theme.Colors.textSecondary)
                    Text(tierName).font(Theme.Fonts.headline).foregroundStyle(Theme.Colors.textPrimary)
                }
                Spacer()
                Text(hint.scoreCost == 0 ? L10n.t("hints.free") : L10n.f("hints.cost", hint.scoreCost))
                    .font(Theme.Fonts.dataStrong)
                    .foregroundStyle(hint.scoreCost == 0 ? Theme.Colors.clear : Theme.Colors.signal)
                    .padding(.horizontal, Theme.Spacing.s3)
                    .frame(height: 24)
                    .background(Capsule().fill((hint.scoreCost == 0 ? Theme.Colors.clear : Theme.Colors.signal).opacity(0.14)))
            }
            switch state {
            case .revealed:
                Text(hint.text)
                    .font(Theme.Fonts.narrativeSmall)
                    .foregroundStyle(Theme.Colors.textPrimary)
                    .transition(.opacity.combined(with: .scale(scale: 0.98, anchor: .top)))
            case .available:
                Text(L10n.t("hints.what\(min(number, 3))")).font(Theme.Fonts.caption).foregroundStyle(Theme.Colors.textSecondary)
                Button(action: onReveal) {
                    HStack {
                        Image(systemName: "lightbulb.fill")
                        Text(L10n.t("hints.reveal"))
                        Spacer()
                        if hint.scoreCost > 0 {
                            Text(L10n.f("hints.scoreAfter", max(0, scoreAfter))).font(Theme.Fonts.dataSmall)
                        }
                    }
                    .font(Theme.Fonts.calloutStrong)
                    .foregroundStyle(Theme.Colors.textPrimary)
                    .padding(.horizontal, Theme.Spacing.s4)
                    .frame(minHeight: Theme.Size.buttonS)
                    .background(RoundedRectangle(cornerRadius: Theme.Radius.sm, style: .continuous).fill(Theme.Colors.bgSelected))
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("hints.reveal.\(number)")
            case .locked(let until):
                Label(until > 0 ? L10n.f("hints.lockedUntil", PhoneFormat.countdown(Double(until))) : L10n.t("hints.lockedPrevious"),
                      systemImage: "lock.fill")
                    .font(Theme.Fonts.callout)
                    .foregroundStyle(Theme.Colors.textTertiary)
            }
        }
        .padding(Theme.Spacing.s5)
        .background(RoundedRectangle(cornerRadius: Theme.Radius.lg).fill(revealed ? Theme.Colors.signalTint : Theme.Colors.bgSurface))
        .overlay(RoundedRectangle(cornerRadius: Theme.Radius.lg).strokeBorder(revealed ? Theme.Colors.signalLine : Theme.Colors.line1))
        .opacity(state == .available || revealed ? 1 : 0.7)
        .animation(Theme.Motion.emphasized(0.35), value: revealed)
    }
}
#endif
