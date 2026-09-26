#if os(iOS)
import SwiftUI
import CaseEngine

// The paper pieces of the case file: exhibits (one support per type), suspect index cards, the
// chronology sheet. They only show what the player put in the file — never a reading of it.

// MARK: - Piece numbers

extension Investigation {
    /// "Pièce N° nn": the order in which the player put the item in the file (1 = the first).
    func pieceNumber(of ref: ItemRef) -> Int? {
        notebook.firstIndex { $0.ref == ref }.map { $0 + 1 }
    }
}

enum PieceFormat {
    static func number(_ n: Int) -> String { n < 10 ? "0\(n)" : "\(n)" }

    /// "PIÈCE 04"
    static func title(_ n: Int) -> String { L10n.f("piece.number", number(n)) }

    /// "P.04"
    static func short(_ n: Int) -> String { "P." + number(n) }

    /// PHOTO, MESSAGE, APPEL…
    static func kind(_ ref: ItemRef, in game: Investigation) -> String {
        if ref.kind == .message, game.index.message(ref.id)?.deletedAt != nil { return L10n.t("piece.kind.deleted") }
        return L10n.t("piece.kind.\(ref.kind.rawValue)")
    }

    /// "12.09 22:47"
    static func dayTime(_ m: Moment) -> String {
        number(m.day) + "." + number(m.month) + " " + PhoneFormat.time(m)
    }

    /// Who the piece comes from, when the phone says it: sender, caller, photographer, contact.
    static func source(_ ref: ItemRef, in game: Investigation) -> String? {
        if ref.kind == .mail { return game.index.mail(ref.id)?.fromName }
        return ItemDescriber.describe(ref, in: game).person.map { game.name(of: $0) }
    }

    /// "MESSAGE · LUCAS FERRAND · 12.09 22:47": {TYPE} · {SOURCE} · {DATE HEURE} (final handoff §F-06).
    static func header(_ ref: ItemRef, in game: Investigation) -> String {
        let at = ItemDescriber.describe(ref, in: game).at
        return [kind(ref, in: game), source(ref, in: game)?.uppercased(), at.map { dayTime($0) }]
            .compactMap { $0 }
            .joined(separator: " · ")
    }

    /// The piece in one line: the words of a message, a call, a caption, a title.
    static func preview(_ ref: ItemRef, in game: Investigation) -> String {
        switch ref.kind {
        case .message:
            if let message = game.index.message(ref.id) { return "« \(message.text ?? L10n.t("item.photo")) »" }
        case .draft:
            if let draft = game.device.conversations.compactMap(\.draft).first(where: { $0.id == ref.id }) { return "« \(draft.text) »" }
        case .call:
            if let call = game.index.call(ref.id) { return CallsFormat.label(call) }
        case .app:
            return AppID(rawValue: ref.id).map { L10n.t("app.\($0.rawValue)") } ?? ""
        default:
            break
        }
        let item = ItemDescriber.describe(ref, in: game)
        return [item.label, item.place].compactMap { $0 }.joined(separator: " · ")
    }

    /// VoiceOver (final handoff §M): « Pièce 1, message, Lucas Ferrand, samedi 12 septembre 22:47 : « … » ».
    static func spoken(_ ref: ItemRef, in game: Investigation, number: Int) -> String {
        let at = ItemDescriber.describe(ref, in: game).at
        let what = [kind(ref, in: game).lowercased(), source(ref, in: game), at.map { PhoneFormat.longDay($0) + " " + PhoneFormat.time($0) }]
            .compactMap { $0 }
            .joined(separator: ", ")
        return L10n.f("carnet.a11y.piece", number, what, preview(ref, in: game))
    }
}

// MARK: - Exhibit (a piece of the file)

/// One exhibit, on the support of its type: a print for a photo, a printed capture for a message,
/// a call record, a map extract, a diary page, a yellow note, a letter, a printed web page, a card.
/// Footer « PIÈCE nn · TYPE · HH:MM ». A stable small rotation from its id.
struct ExhibitView: View {
    let ref: ItemRef
    let game: Investigation
    var compact = true

    var body: some View {
        let number = game.pieceNumber(of: ref)
        let item = ItemDescriber.describe(ref, in: game)
        VStack(alignment: .leading, spacing: 8) {
            ExhibitSupport(ref: ref, game: game, compact: compact)
            HStack(alignment: .firstTextBaseline) {
                if let number {
                    Text(PieceFormat.title(number)).font(Trace.Fonts.pieceNumber).tracking(1).foregroundStyle(Trace.Colors.ink)
                }
                Spacer(minLength: 4)
                Text(PieceFormat.kind(ref, in: game) + (item.at.map { " · " + PhoneFormat.time($0) } ?? ""))
                    .font(Trace.Fonts.monoSmall).foregroundStyle(Trace.Colors.inkSoft).lineLimit(1)
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .paper(background, radius: 1)
        .tilt(ref.id, range: compact ? 1.6 : 0.6)
        .accessibilityElement(children: .combine)
    }

    private var background: Color {
        switch ref.kind {
        case .note: Trace.Colors.noteYellow
        case .call, .mail, .browser: Trace.Colors.print
        default: Trace.Colors.paper
        }
    }
}

/// What an exhibit shows, without its paper: the print, the capture, the record, the extract…
/// Shared by the exhibits and the Carnet's piece cards (photos keep their print frame there, §G).
struct ExhibitSupport: View {
    let ref: ItemRef
    let game: Investigation
    var compact = true

    var body: some View {
        let index = game.index
        switch ref.kind {
        case .photo, .photoInfo:
            if let photo = index.photo(ref.id) {
                VStack(alignment: .leading, spacing: 8) {
                    PhotoPrint(border: 4) {
                        GeneratedPhoto(photo: photo).frame(height: compact ? 96 : 200)
                    }
                    if ref.kind == .photoInfo || !compact {
                        Text(photo.caption).font(Trace.Fonts.proseSmall).foregroundStyle(Trace.Colors.ink).lineLimit(compact ? 2 : nil)
                    }
                }
            }
        case .message:
            if let message = index.message(ref.id) {
                capture(from: game.name(of: message.from), text: message.text ?? L10n.t("item.photo"), mine: message.isFromOwner)
            }
        case .draft:
            if let draft = game.device.conversations.compactMap(\.draft).first(where: { $0.id == ref.id }) {
                capture(from: L10n.t("messages.draft"), text: draft.text, mine: true)
            }
        case .call:
            if let call = index.call(ref.id) { callRecord(call) }
        case .track:
            if let track = index.track(ref.id) { mapExtract(track) }
        case .calendar:
            if let event = index.calendarEvent(ref.id) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(PhoneFormat.longDayCapitalized(event.start).uppercased()).font(Trace.Fonts.monoSmall.weight(.bold))
                        .foregroundStyle(Trace.Colors.stamp)
                    Rectangle().fill(Trace.Colors.stamp.opacity(0.4)).frame(height: 1)
                    Text(PhoneFormat.time(event.start) + (event.end.map { "–" + PhoneFormat.time($0) } ?? ""))
                        .font(Trace.Fonts.fieldValue).foregroundStyle(Trace.Colors.ink)
                    Text(event.title).font(Trace.Fonts.proseSmall.weight(.semibold)).foregroundStyle(Trace.Colors.ink).lineLimit(2)
                    if let location = event.location {
                        Text(location).font(Trace.Fonts.monoSmall).foregroundStyle(Trace.Colors.inkSoft).lineLimit(1)
                    }
                }
            }
        case .note:
            if let note = index.note(ref.id) {
                Text("« \(note.body) »").font(Trace.Fonts.quote).foregroundStyle(Trace.Colors.ink).lineLimit(compact ? 4 : nil)
            }
        case .mail:
            if let mail = index.mail(ref.id) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(mail.fromName.uppercased()).font(Trace.Fonts.monoSmall.weight(.bold)).foregroundStyle(Trace.Colors.ink).lineLimit(1)
                    Text(mail.subject).font(Trace.Fonts.proseSmall.weight(.semibold)).foregroundStyle(Trace.Colors.ink).lineLimit(2)
                    Text(mail.body).font(Trace.Fonts.monoSmall).foregroundStyle(Trace.Colors.inkSoft).lineLimit(compact ? 3 : nil)
                    if let files = mail.attachments, !files.isEmpty {
                        Text("⎘ " + files.joined(separator: " · ")).font(Trace.Fonts.monoSmall).foregroundStyle(Trace.Colors.inkSoft).lineLimit(1)
                    }
                }
            }
        case .browser:
            if let entry = index.browserEntry(ref.id) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(entry.url ?? L10n.t("piece.search")).font(Trace.Fonts.monoSmall).foregroundStyle(Trace.Colors.inkSoft).lineLimit(1)
                    Rectangle().fill(Trace.Colors.inkFaint.opacity(0.3)).frame(height: 1)
                    Text(entry.kind == .search ? "« \(entry.text) »" : entry.text)
                        .font(Trace.Fonts.proseSmall.weight(.semibold)).foregroundStyle(Trace.Colors.ink).lineLimit(3)
                    if let summary = entry.summary, !compact {
                        Text(summary).font(Trace.Fonts.proseSmall).foregroundStyle(Trace.Colors.inkSoft)
                    }
                }
            }
        case .contact:
            if let contact = game.contact(ref.id) {
                HStack(spacing: 8) {
                    Avatar(contact: contact, size: 30)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(contact.name).font(Trace.Fonts.proseSmall.weight(.semibold)).foregroundStyle(Trace.Colors.ink)
                        Text(contact.phone).font(Trace.Fonts.monoSmall).foregroundStyle(Trace.Colors.inkSoft)
                    }
                }
            }
        case .app:
            Text(PieceFormat.preview(ref, in: game)).font(Trace.Fonts.mono).foregroundStyle(Trace.Colors.ink)
        }
    }

    /// A message capture, printed: the bubble on a dark strip, like the screen it came from.
    private func capture(from: String, text: String, mine: Bool) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(from.uppercased()).font(Trace.Fonts.monoSmall).foregroundStyle(Trace.Colors.inkSoft).lineLimit(1)
            Text(text)
                .font(.custom(Theme.FontName.regular, size: 12.5, relativeTo: .footnote))
                .foregroundStyle(mine ? Theme.Colors.bubbleOutText : Theme.Colors.textPrimary)
                .lineLimit(compact ? 4 : nil)
                .padding(.horizontal, 10).padding(.vertical, 7)
                .background(RoundedRectangle(cornerRadius: 12).fill(mine ? Theme.Colors.bubbleOut : Theme.Colors.bgBubbleIn))
                .frame(maxWidth: .infinity, alignment: mine ? .trailing : .leading)
                .padding(6)
                .background(RoundedRectangle(cornerRadius: 6).fill(Theme.Colors.bgBase))
        }
    }

    /// A call record: the call among its neighbours, highlighted.
    private func callRecord(_ call: Call) -> some View {
        let calls = game.calls.sorted { $0.at < $1.at }
        let i = calls.firstIndex { $0.id == call.id } ?? 0
        let rows = Array(calls[max(0, i - 1)...min(calls.count - 1, i + 1)])
        return VStack(alignment: .leading, spacing: 3) {
            Text(L10n.t("piece.callRecord")).font(Trace.Fonts.fieldLabel).tracking(1.2).foregroundStyle(Trace.Colors.inkSoft)
            ForEach(rows) { row in
                HStack {
                    Text(PhoneFormat.time(row.at)).font(Trace.Fonts.monoSmall.weight(.semibold))
                    Text(game.name(of: row.contact).split(separator: " ").first.map(String.init)?.uppercased() ?? "")
                        .font(Trace.Fonts.monoSmall.weight(.semibold)).lineLimit(1)
                    Text(CallsFormat.arrow(row)).font(Trace.Fonts.monoSmall)
                    Spacer(minLength: 2)
                    Text(row.durationSeconds > 0 ? PhoneFormat.duration(row.durationSeconds) : "—").font(Trace.Fonts.monoSmall)
                }
                .foregroundStyle(row.id == call.id ? Trace.Colors.ink : Trace.Colors.inkSoft)
                .padding(.horizontal, 3)
                .background(row.id == call.id ? Trace.Colors.highlight : .clear)
            }
        }
    }

    /// A map extract: streets, the last position circled in red.
    private func mapExtract(_ track: LocationTrack) -> some View {
        let last = track.points.max { $0.at < $1.at }
        return VStack(alignment: .leading, spacing: 4) {
            ZStack {
                Rectangle().fill(Color(hex: 0xD9D4C6))
                Canvas { context, size in
                    var rng = SeededRandom(seed: track.id)
                    for _ in 0..<6 {
                        var road = Path()
                        road.move(to: CGPoint(x: rng.next() * size.width, y: 0))
                        road.addLine(to: CGPoint(x: rng.next() * size.width, y: size.height))
                        context.stroke(road, with: .color(.white.opacity(0.8)), lineWidth: 2 + rng.next() * 3)
                    }
                    context.fill(Path(CGRect(x: 0, y: size.height * 0.62, width: size.width, height: size.height * 0.14)),
                                 with: .color(Color(hex: 0x9FB3BF).opacity(0.7)))
                    let c = CGPoint(x: size.width * 0.62, y: size.height * 0.4)
                    context.stroke(Path(ellipseIn: CGRect(x: c.x - 8, y: c.y - 8, width: 16, height: 16)), with: .color(Trace.Colors.stamp), lineWidth: 2)
                }
            }
            .frame(height: compact ? 64 : 120)
            .accessibilityHidden(true)
            Text(L10n.f("item.track", game.name(of: track.contact))).font(Trace.Fonts.proseSmall.weight(.semibold)).foregroundStyle(Trace.Colors.ink).lineLimit(1)
            if let last, let place = game.index.place(last.place) {
                Text(place.name).font(Trace.Fonts.monoSmall).foregroundStyle(Trace.Colors.inkSoft).lineLimit(1)
            }
        }
    }
}

// MARK: - Suspect index card

/// One piece linked to a suspect, as listed on their index card: « ▲ PIÈCE 03 · MESSAGE · 22:47 ».
struct LinkedPieceLine: Hashable {
    let stance: NotebookEntry.Stance?
    let text: String
}

/// A bristol card: identity photo, SUSPECT A, name, age · link, then what the player filed:
/// « ▲n ▼n » (n pieces accuse / clear them) and, in the Carnet, the list of those pieces.
/// Crossed out when the player cleared them in their notes; red outline when chosen (conclusion).
struct SuspectIndexCard: View {
    let suspect: Suspect
    let letter: String
    let contact: Contact?
    var against = 0
    var favour = 0
    var cleared = false
    var principal = false
    var showCounts = true
    /// The pieces the player linked to this suspect (Carnet › Suspects).
    var pieces: [LinkedPieceLine] = []

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 14) {
                IDPhoto(contact: contact, width: 62, height: 74)
                VStack(alignment: .leading, spacing: 3) {
                    Text(L10n.f("suspect.letter", letter)).fieldLabel()
                    Text(contact?.name ?? suspect.contact)
                        .font(Trace.Fonts.name)
                        .foregroundStyle(Trace.Colors.ink)
                        .strikethrough(cleared, color: Trace.Colors.ink)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    Text(([suspect.age.map { L10n.f("suspect.ageShort", $0) }].compactMap { $0 } + [suspect.role]).joined(separator: " · ").uppercased())
                        .font(Trace.Fonts.monoSmall).foregroundStyle(Trace.Colors.inkSoft).lineLimit(2)
                    if showCounts {
                        LinkTally(against: against, favour: favour)
                            .padding(.top, 2)
                    }
                }
                Spacer(minLength: 0)
                if cleared {
                    StampMark(text: L10n.t("stamp.cleared"), color: Trace.Colors.ink, size: 9, angle: -8)
                }
            }
            if !pieces.isEmpty {
                Rectangle().fill(Trace.Colors.inkFaint.opacity(0.3)).frame(height: 1)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(pieces, id: \.self) { line in
                        HStack(alignment: .firstTextBaseline, spacing: 6) {
                            Text(verbatim: LinkTally.glyph(line.stance))
                                .foregroundStyle(line.stance == .incriminates ? Trace.Colors.stamp : Trace.Colors.ink)
                            Text(line.text)
                                .foregroundStyle(Trace.Colors.inkMid)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .font(Trace.Fonts.monoSmall)
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel(Text(LinkTally.spokenStance(line.stance) + line.text))
                    }
                }
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .paper(Trace.Colors.print, radius: 2)
        .overlay(RoundedRectangle(cornerRadius: 2).strokeBorder(principal ? Trace.Colors.stamp : .clear, lineWidth: 1.5))
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }
}

/// « ▲2 ▼1 »: how many filed pieces accuse / clear a suspect — numbers, never colour alone (§M).
struct LinkTally: View {
    let against: Int
    let favour: Int

    var body: some View {
        Group {
            if against + favour == 0 {
                Text(L10n.t("suspect.noPiece")).foregroundStyle(Trace.Colors.inkSoft)
            } else {
                HStack(spacing: 10) {
                    Text(verbatim: "▲\(against)").foregroundStyle(against > 0 ? Trace.Colors.stamp : Trace.Colors.inkSoft)
                    Text(verbatim: "▼\(favour)").foregroundStyle(favour > 0 ? Trace.Colors.ink : Trace.Colors.inkSoft)
                }
            }
        }
        .font(Trace.Fonts.monoStrong)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(Self.spoken(against: against, favour: favour)))
    }

    /// « 2 pièces l'accusent, 1 le disculpe ».
    static func spoken(against: Int, favour: Int) -> String {
        if against + favour == 0 { return L10n.t("suspect.noPiece") }
        return L10n.f("carnet.a11y.accusedBy", against) + ", " + L10n.f("carnet.a11y.clearedBy", favour)
    }

    /// ▲ accuses, ▼ clears, · linked without a reading.
    static func glyph(_ stance: NotebookEntry.Stance?) -> String {
        switch stance {
        case .incriminates: "▲"
        case .clears: "▼"
        case nil: "·"
        }
    }

    /// « L'accuse, » / « Le disculpe, » before a spoken piece line.
    static func spokenStance(_ stance: NotebookEntry.Stance?) -> String {
        switch stance {
        case .incriminates: L10n.t("suspect.stanceAgainst") + ", "
        case .clears: L10n.t("suspect.stanceFavour") + ", "
        case nil: ""
        }
    }
}

extension Suspect {
    /// A, B, C… in the order of the file.
    static func letter(_ index: Int) -> String { String(UnicodeScalar(65 + min(index, 25)).map(Character.init) ?? "?") }
}

// MARK: - Chronology sheet

/// The chronology, generated from the pieces in the file: time on the left, a filled square per
/// filed piece, gaps of more than 15 minutes as a dotted line. No commentary.
struct ChronologySheet: View {
    let game: Investigation

    var body: some View {
        let rows = game.notebook
            .map { (entry: $0, item: ItemDescriber.describe($0.ref, in: game)) }
            .filter { $0.item.at != nil }
            .sorted { $0.item.at! < $1.item.at! }
        if rows.isEmpty {
            VStack(alignment: .leading, spacing: Trace.Spacing.s) {
                Text(L10n.t("chrono.empty")).font(Trace.Fonts.prose).foregroundStyle(Trace.Colors.ink)
                    .fixedSize(horizontal: false, vertical: true)
                Text(L10n.t("chrono.emptyTip")).font(Trace.Fonts.mono).foregroundStyle(Trace.Colors.inkSoft)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 12)
            .accessibilityElement(children: .combine)
        } else {
            VStack(alignment: .leading, spacing: 0) {
                ForEach(Array(rows.enumerated()), id: \.offset) { offset, row in
                    let at = row.item.at!
                    let previous = offset > 0 ? rows[offset - 1].item.at : nil
                    if let previous, !previous.isSameDay(as: at) || offset == 0 {
                        dayHeader(at)
                    } else if offset == 0 {
                        dayHeader(at)
                    }
                    if let previous, previous.isSameDay(as: at), at.seconds - previous.seconds > 15 * 60 {
                        gap(from: previous, to: at)
                    }
                    line(row.entry, item: row.item, at: at)
                }
            }
        }
    }

    private func dayHeader(_ at: Moment) -> some View {
        Text(PhoneFormat.separatorCaps(at)).font(Trace.Fonts.fieldLabel).tracking(1.4).foregroundStyle(Trace.Colors.stamp)
            .padding(.top, 10).padding(.bottom, 6).padding(.leading, 60)
    }

    private func gap(from: Moment, to: Moment) -> some View {
        HStack(spacing: 0) {
            Color.clear.frame(width: 54)
            Rectangle().fill(.clear).frame(width: 1.5, height: 22)
                .overlay(Line().stroke(Trace.Colors.inkSoft, style: StrokeStyle(lineWidth: 1.5, dash: [3, 3])))
            Spacer()
        }
        .accessibilityHidden(true)
    }

    private func line(_ entry: NotebookEntry, item: ItemDescriber.Item, at: Moment) -> some View {
        let number = game.pieceNumber(of: entry.ref)
        return HStack(alignment: .top, spacing: 10) {
            Text(PhoneFormat.time(at)).font(Trace.Fonts.fieldValue).foregroundStyle(Trace.Colors.ink).frame(width: 44, alignment: .trailing)
            VStack(spacing: 0) {
                Rectangle().fill(Trace.Colors.ink).frame(width: 8, height: 8).padding(.top, 4)
                Rectangle().fill(Trace.Colors.ink).frame(width: 1.5).frame(minHeight: 26)
            }
            .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(item.label).font(Trace.Fonts.proseSmall).foregroundStyle(Trace.Colors.ink).lineLimit(2)
                Text([number.map(PieceFormat.title), PieceFormat.kind(entry.ref, in: game)].compactMap { $0 }.joined(separator: " · "))
                    .font(Trace.Fonts.monoSmall).foregroundStyle(Trace.Colors.inkSoft)
            }
            .padding(.bottom, 10)
            Spacer(minLength: 0)
        }
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("notebook.row")
    }
}

/// A vertical line (dotted gaps).
struct Line: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.midX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        return p
    }
}

// MARK: - Folder cover facts

/// What a case file's cover says, from the case data (and the player's progress).
struct DossierFacts {
    let file: CaseFile
    var info: DossierInfo? { file.dossier }
    var category: String { info?.category ?? L10n.t("dossier.defaultCategory") }
    var city: String { info?.city ?? "" }
    var place: String { info?.place ?? "" }
    var subject: String { info?.subject ?? file.devices.first?.label ?? "" }
    var subjectLabel: String { info?.subjectLabel ?? L10n.t("dossier.victim") }
    var lastContactLabel: String { info?.lastContactLabel ?? L10n.t("dossier.lastContact") }
    var rating: Int { info?.rating ?? min(5, max(1, file.difficulty + 1)) }

    func subjectContact() -> Contact? {
        guard let id = info?.subjectContact else { return nil }
        return file.devices.lazy.compactMap { $0.contacts.first { $0.id == id } }.first
    }

    /// "SAM. 12.09 · 22:08"
    var lastContact: String? {
        info?.lastContact.map { PhoneFormat.shortWeekdayDot($0) + " · " + PhoneFormat.time($0) }
    }
}

/// The status of a case file on the desk.
enum DossierStatus {
    case new, open, solved, unsolved

    static func of(_ file: CaseFile, progress: CaseProgress?, savedCaseID: String?) -> DossierStatus {
        if savedCaseID == file.id { return .open }
        guard let progress, progress.plays > 0 else { return .new }
        return progress.solved ? .solved : .unsolved
    }

    var title: String {
        switch self {
        case .new: L10n.t("status.new")
        case .open: L10n.t("status.open")
        case .solved: L10n.t("status.solved")
        case .unsolved: L10n.t("status.unsolved")
        }
    }
}
#endif
