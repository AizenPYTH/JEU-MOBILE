#if os(iOS)
import SwiftUI
import CaseEngine

// The pieces of the case file as the Carnet shows them (UX V3 §5): EvidenceCard, SuspectCard,
// ConnectionChain, the chronology. Flat surfaces, no paper. They only show what the player put in
// the file and decided — never a reading of it, never whether a link is right.

// MARK: - Piece numbers

extension Investigation {
    /// "Pièce N° nn": the order in which the player put the item in the file (1 = the first).
    func pieceNumber(of ref: ItemRef) -> Int? {
        notebook.firstIndex { $0.ref == ref }.map { $0 + 1 }
    }

    /// The elements the player said this piece contradicts (their connections), in drawing order.
    func contradicted(by ref: ItemRef) -> [Connection.Node] {
        var found: [Connection.Node] = []
        let me = Connection.Node.piece(ref)
        for connection in connections {
            for (i, verb) in connection.verbs.enumerated() where verb == .contradicts && i + 1 < connection.nodes.count {
                let a = connection.nodes[i], b = connection.nodes[i + 1]
                let other: Connection.Node? = a == me ? b : (b == me ? a : nil)
                if let other, !found.contains(other) { found.append(other) }
            }
        }
        return found
    }

    /// « Connexion 1, 3 »: the display numbers (1 = first drawn) of the chains holding this element.
    func connectionNumbers(containing node: Connection.Node) -> [Int] {
        connections.enumerated().filter { $0.element.nodes.contains(node) }.map { $0.offset + 1 }
    }
}

enum PieceFormat {
    static func number(_ n: Int) -> String { n < 10 ? "0\(n)" : "\(n)" }

    /// "PIÈCE 04"
    static func title(_ n: Int) -> String { L10n.f("piece.number", number(n)) }
    /// « Pièce 03 » (sentence case, in badges).
    static func shortTitle(_ n: Int) -> String { L10n.f("piece.short", number(n)) }

    /// "P.04"
    static func short(_ n: Int) -> String { "P." + number(n) }

    /// PHOTO, MESSAGE, APPEL… (capitals: data labels).
    static func kind(_ ref: ItemRef, in game: Investigation) -> String {
        if ref.kind == .message, game.index.message(ref.id)?.deletedAt != nil { return L10n.t("piece.kind.deleted") }
        return L10n.t("piece.kind.\(ref.kind.rawValue)")
    }

    /// Photo, Message, Appel… (sentence case: the « type · source » caption of an EvidenceCard).
    static func type(_ ref: ItemRef, in game: Investigation) -> String {
        if ref.kind == .message, game.index.message(ref.id)?.deletedAt != nil { return L10n.t("piece.type.deleted") }
        return L10n.t("piece.type.\(ref.kind.rawValue)")
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

    /// The source, or else the app the piece comes from (« Notes », « Agenda »).
    static func origin(_ ref: ItemRef, in game: Investigation) -> String {
        source(ref, in: game) ?? ItemDescriber.describe(ref, in: game).app.title
    }

    /// "MESSAGE · LUCAS FERRAND · 12.09 22:47": {TYPE} · {SOURCE} · {DATE HEURE} (final handoff §F-06).
    static func header(_ ref: ItemRef, in game: Investigation) -> String {
        let at = ItemDescriber.describe(ref, in: game).at
        return [kind(ref, in: game), source(ref, in: game)?.uppercased(), at.map { dayTime($0) }]
            .compactMap { $0 }
            .joined(separator: " · ")
    }

    /// « Message · Lucas Ferrand · 22:47 » (UX V3 §5 EvidenceCard « type · source »).
    static func caption(_ ref: ItemRef, in game: Investigation) -> String {
        let at = ItemDescriber.describe(ref, in: game).at
        return [type(ref, in: game), origin(ref, in: game), at.map { PhoneFormat.time($0) }]
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

/// The filter pills of Carnet › Pièces (§6-07): pieces grouped by what they are.
enum PieceFamily: String, CaseIterable, Hashable {
    case messages, photos, calls, places, calendar, notes, mails, web, contacts, apps

    static func of(_ kind: ItemRef.Kind) -> PieceFamily {
        switch kind {
        case .message, .draft: .messages
        case .photo, .photoInfo: .photos
        case .call: .calls
        case .track: .places
        case .calendar: .calendar
        case .note: .notes
        case .mail: .mails
        case .browser: .web
        case .contact: .contacts
        case .app: .apps
        }
    }

    var title: String { L10n.t("carnet.filter.\(rawValue)") }
}

// MARK: - Exhibit (a piece of the file)

/// One exhibit, flat: what the piece shows (`ExhibitSupport`) on `surface2`, then
/// « PIÈCE nn · Type · HH:MM ». No paper, no rotation (V3).
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
                    Text(PieceFormat.title(number)).font(Trace.Fonts.data).foregroundStyle(Trace.Colors.benText)
                }
                Spacer(minLength: 4)
                Text(PieceFormat.type(ref, in: game) + (item.at.map { " · " + PhoneFormat.time($0) } ?? ""))
                    .font(Trace.Fonts.caption).foregroundStyle(Trace.Colors.text2).lineLimit(1)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: Trace.Radius.node, style: .continuous).fill(Trace.Colors.surface2))
        .accessibilityElement(children: .combine)
    }
}

/// What an exhibit shows: the photo, the message capture (a light strip, like the screen it came
/// from — content keeps its look), the call record, the map extract, the diary entry, the note…
/// Shared by the exhibits, the Carnet's piece detail and the filing sheet.
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
                        Text(photo.caption).font(Trace.Fonts.callout).foregroundStyle(Trace.Colors.text).lineLimit(compact ? 2 : nil)
                    }
                    if ref.kind == .photoInfo, let place = photo.place {
                        Text(place).font(Trace.Fonts.caption).foregroundStyle(Trace.Colors.text2).lineLimit(compact ? 1 : nil)
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
                    Text(PhoneFormat.longDayCapitalized(event.start)).font(Trace.Fonts.caption)
                        .foregroundStyle(Trace.Colors.text2)
                    Text(PhoneFormat.time(event.start) + (event.end.map { "–" + PhoneFormat.time($0) } ?? ""))
                        .font(Trace.Fonts.data).foregroundStyle(Trace.Colors.benText)
                    Text(event.title).font(Trace.Fonts.callout.weight(.semibold)).foregroundStyle(Trace.Colors.text).lineLimit(compact ? 2 : nil)
                    if let location = event.location {
                        Text(location).font(Trace.Fonts.caption).foregroundStyle(Trace.Colors.text2).lineLimit(compact ? 1 : nil)
                    }
                }
            }
        case .note:
            if let note = index.note(ref.id) {
                Text("« \(note.body) »").font(Trace.Fonts.quote).foregroundStyle(Trace.Colors.text).lineLimit(compact ? 4 : nil)
            }
        case .mail:
            if let mail = index.mail(ref.id) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(mail.fromName).font(Trace.Fonts.caption.weight(.semibold)).foregroundStyle(Trace.Colors.text).lineLimit(1)
                    Text(mail.subject).font(Trace.Fonts.callout.weight(.semibold)).foregroundStyle(Trace.Colors.text).lineLimit(compact ? 2 : nil)
                    Text(mail.body).font(Trace.Fonts.callout).foregroundStyle(Trace.Colors.text2).lineLimit(compact ? 3 : nil)
                    if let files = mail.attachments, !files.isEmpty {
                        Text("⎘ " + files.joined(separator: " · ")).font(Trace.Fonts.caption).foregroundStyle(Trace.Colors.text2).lineLimit(1)
                    }
                }
            }
        case .browser:
            if let entry = index.browserEntry(ref.id) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(entry.url ?? L10n.t("piece.search")).font(Trace.Fonts.data).foregroundStyle(Trace.Colors.text2).lineLimit(1)
                    Text(entry.kind == .search ? "« \(entry.text) »" : entry.text)
                        .font(Trace.Fonts.callout.weight(.semibold)).foregroundStyle(Trace.Colors.text).lineLimit(compact ? 3 : nil)
                    if let summary = entry.summary, !compact {
                        Text(summary).font(Trace.Fonts.callout).foregroundStyle(Trace.Colors.text2)
                    }
                }
            }
        case .contact:
            if let contact = game.contact(ref.id) {
                HStack(spacing: 8) {
                    Avatar(contact: contact, size: 30)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(contact.name).font(Trace.Fonts.callout.weight(.semibold)).foregroundStyle(Trace.Colors.text)
                        Text(contact.phone).font(Trace.Fonts.data).foregroundStyle(Trace.Colors.text2)
                    }
                }
            }
        case .app:
            Text(PieceFormat.preview(ref, in: game)).font(Trace.Fonts.callout).foregroundStyle(Trace.Colors.text)
        }
    }

    /// A message capture: the bubble on the phone's light background, like the screen it came from.
    private func capture(from: String, text: String, mine: Bool) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(from).font(Trace.Fonts.caption).foregroundStyle(Trace.Colors.text2).lineLimit(1)
            Text(text)
                .font(Theme.Fonts.callout)
                .foregroundStyle(mine ? Theme.Colors.bubbleOutText : Theme.Colors.textPrimary)
                .lineLimit(compact ? 4 : nil)
                .padding(.horizontal, 10).padding(.vertical, 7)
                .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(mine ? Theme.Colors.bubbleOut : Theme.Colors.bgBubbleIn))
                .frame(maxWidth: .infinity, alignment: mine ? .trailing : .leading)
                .padding(8)
                .background(RoundedRectangle(cornerRadius: Trace.Radius.node, style: .continuous).fill(Theme.Colors.bgBase))
        }
    }

    /// A call record: the call among its neighbours, highlighted.
    private func callRecord(_ call: Call) -> some View {
        let calls = game.calls.sorted { $0.at < $1.at }
        let i = calls.firstIndex { $0.id == call.id } ?? 0
        let rows = calls.isEmpty ? [call] : Array(calls[max(0, i - 1)...min(calls.count - 1, i + 1)])
        return VStack(alignment: .leading, spacing: 3) {
            Text(L10n.t("piece.callRecord")).font(Trace.Fonts.data).foregroundStyle(Trace.Colors.text2)
            ForEach(rows) { row in
                HStack {
                    Text(PhoneFormat.time(row.at)).font(Trace.Fonts.data)
                    Text(game.name(of: row.contact).split(separator: " ").first.map(String.init) ?? "")
                        .font(Trace.Fonts.callout).lineLimit(1)
                    Text(CallsFormat.arrow(row)).font(Trace.Fonts.caption)
                    Spacer(minLength: 2)
                    Text(row.durationSeconds > 0 ? PhoneFormat.duration(row.durationSeconds) : "—").font(Trace.Fonts.data)
                }
                .foregroundStyle(row.id == call.id ? Trace.Colors.text : Trace.Colors.text2)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(RoundedRectangle(cornerRadius: 6).fill(row.id == call.id ? Trace.Colors.tint(Trace.Colors.ben) : .clear))
            }
        }
    }

    /// A map extract: streets, the last position circled.
    private func mapExtract(_ track: LocationTrack) -> some View {
        let last = track.points.max { $0.at < $1.at }
        return VStack(alignment: .leading, spacing: 4) {
            ZStack {
                Rectangle().fill(Trace.Colors.surface3)
                Canvas { context, size in
                    var rng = SeededRandom(seed: track.id)
                    for _ in 0..<6 {
                        var road = Path()
                        road.move(to: CGPoint(x: rng.next() * size.width, y: 0))
                        road.addLine(to: CGPoint(x: rng.next() * size.width, y: size.height))
                        context.stroke(road, with: .color(Trace.Colors.text2.opacity(0.35)), lineWidth: 2 + rng.next() * 3)
                    }
                    let c = CGPoint(x: size.width * 0.62, y: size.height * 0.4)
                    context.stroke(Path(ellipseIn: CGRect(x: c.x - 8, y: c.y - 8, width: 16, height: 16)), with: .color(Trace.Colors.benText), lineWidth: 2)
                }
            }
            .frame(height: compact ? 64 : 120)
            .clipShape(RoundedRectangle(cornerRadius: Trace.Radius.node, style: .continuous))
            .accessibilityHidden(true)
            Text(L10n.f("item.track", game.name(of: track.contact))).font(Trace.Fonts.callout.weight(.semibold)).foregroundStyle(Trace.Colors.text).lineLimit(1)
            if let last, let place = game.index.place(last.place) {
                Text(place.name).font(Trace.Fonts.caption).foregroundStyle(Trace.Colors.text2).lineLimit(1)
            }
        }
    }
}

// MARK: - EvidenceCard (§5)

/// EvidenceCard (§5): « PIÈCE nn » (data, benText), « type · source » (caption), the content in
/// three lines then « Lire plus », then the card's own footer (links line, readings).
/// States: plain · selected (2 pt ben rule) · contradiction (warning rule + « ≠ contredit PIÈCE nn »).
struct EvidenceCard<Footer: View>: View {
    enum Mark: Equatable { case plain, selected, contradiction }

    let ref: ItemRef
    let game: Investigation
    var mark: Mark = .plain
    /// « ≠ contredit PIÈCE 02 » at the top right (contradiction).
    var badge: String? = nil
    /// Tap on the piece (its detail). nil: not tappable.
    var onOpen: (() -> Void)? = nil
    var openIdentifier = "notebook.row"
    @ViewBuilder var footer: () -> Footer

    var body: some View {
        let number = game.pieceNumber(of: ref) ?? 0
        let shape = RoundedRectangle(cornerRadius: Trace.Radius.card, style: .continuous)
        VStack(alignment: .leading, spacing: 12) {
            if let onOpen {
                Button(action: onOpen) { summary(number, readMore: true) }
                    .buttonStyle(PressableStyle())
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(Text(PieceFormat.spoken(ref, in: game, number: number) + (badge.map { ". " + $0 } ?? "")))
                    .accessibilityAddTraits(.isButton)
                    .accessibilityIdentifier(openIdentifier)
            } else {
                summary(number, readMore: false)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(Text(PieceFormat.spoken(ref, in: game, number: number)))
            }
            footer()
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(shape.fill(Trace.Colors.surface))
        .overlay(shape.strokeBorder(borderColor, lineWidth: mark == .selected ? 2 : 1))
        .accessibilityElement(children: .contain)
    }

    private var borderColor: Color {
        switch mark {
        case .plain: Trace.Colors.line
        case .selected: Trace.Colors.ben
        case .contradiction: Trace.Colors.warning
        }
    }

    private func summary(_ number: Int, readMore: Bool) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .center, spacing: 8) {
                Text(PieceFormat.title(number)).font(Trace.Fonts.data).foregroundStyle(Trace.Colors.benText)
                Spacer(minLength: 4)
                if let badge {
                    StatusBadge(text: badge, color: Trace.Colors.warning)
                }
            }
            Text(PieceFormat.caption(ref, in: game))
                .font(Trace.Fonts.caption)
                .foregroundStyle(Trace.Colors.text2)
                .fixedSize(horizontal: false, vertical: true)
            EvidencePreview(ref: ref, game: game)
            if readMore {
                Text(L10n.t("carnet.readMore")).font(Trace.Fonts.caption.weight(.semibold)).foregroundStyle(Trace.Colors.benText)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
    }
}

extension EvidenceCard where Footer == EmptyView {
    init(ref: ItemRef, game: Investigation, mark: Mark = .plain, badge: String? = nil,
         onOpen: (() -> Void)? = nil, openIdentifier: String = "notebook.row") {
        self.init(ref: ref, game: game, mark: mark, badge: badge, onOpen: onOpen, openIdentifier: openIdentifier) { EmptyView() }
    }
}

/// The content of a piece in a card: a photo thumbnail, or its words in three lines.
struct EvidencePreview: View {
    let ref: ItemRef
    let game: Investigation

    var body: some View {
        switch ref.kind {
        case .photo, .photoInfo:
            if let photo = game.index.photo(ref.id) {
                HStack(alignment: .top, spacing: 12) {
                    GeneratedPhoto(photo: photo)
                        .frame(width: 88, height: 66)
                        .clipShape(RoundedRectangle(cornerRadius: Trace.Radius.node, style: .continuous))
                        .accessibilityHidden(true)
                    Text(PieceFormat.preview(ref, in: game))
                        .font(Trace.Fonts.callout)
                        .foregroundStyle(Trace.Colors.text)
                        .lineLimit(3)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        default:
            Text(PieceFormat.preview(ref, in: game))
                .font(Trace.Fonts.callout)
                .foregroundStyle(Trace.Colors.text)
                .lineLimit(3)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

// MARK: - SuspectCard (§5)

/// What the player's readings say about a suspect (§5 SuspectCard): accused (↑ n l'accusent),
/// cleared (↓ n le disculpent) or neutral (« Rien de relevé »). Counts only what the player
/// decided, never a verdict.
enum SuspectStanding: Equatable {
    case neutral
    case accused(Int)
    case cleared(Int)
    case split(against: Int, favour: Int)

    init(against: Int, favour: Int) {
        if against == 0 && favour == 0 { self = .neutral }
        else if against > favour { self = .accused(against) }
        else if favour > against { self = .cleared(favour) }
        else { self = .split(against: against, favour: favour) }
    }

    var text: String {
        switch self {
        case .neutral: L10n.t("carnet.status.neutral")
        case .accused(let n): L10n.f(n == 1 ? "carnet.status.accusedOne" : "carnet.status.accusedMany", n)
        case .cleared(let n): L10n.f(n == 1 ? "carnet.status.clearedOne" : "carnet.status.clearedMany", n)
        case .split(let a, let f): "↑ \(a) · ↓ \(f)"
        }
    }

    var symbol: String? {
        switch self {
        case .neutral, .split: nil
        case .accused: "↑"
        case .cleared: "↓"
        }
    }

    var color: Color {
        switch self {
        case .neutral, .split: Trace.Colors.text2
        case .accused: Trace.Colors.criticalOnDark
        case .cleared: Trace.Colors.successText
        }
    }
}

/// SuspectCard (§5): photo 56 × 70 (initials when missing), name + age, relation, « Alibi · … »
/// (what they declared), StatusBadge + « n pièces ».
struct SuspectCard: View {
    let suspect: Suspect
    let contact: Contact?
    var against = 0
    var favour = 0
    /// Pieces linked to this suspect (whatever the reading).
    var pieces = 0

    var body: some View {
        let standing = SuspectStanding(against: against, favour: favour)
        HStack(alignment: .top, spacing: 14) {
            IDPhoto(contact: contact, width: 56, height: 70)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(contact?.name ?? suspect.contact)
                        .font(Trace.Fonts.headline)
                        .foregroundStyle(Trace.Colors.text)
                        .fixedSize(horizontal: false, vertical: true)
                    if let age = suspect.age {
                        Text(L10n.f("suspect.age", age)).font(Trace.Fonts.caption).foregroundStyle(Trace.Colors.text2)
                    }
                }
                Text(suspect.role)
                    .font(Trace.Fonts.callout)
                    .foregroundStyle(Trace.Colors.text2)
                    .fixedSize(horizontal: false, vertical: true)
                Text(L10n.f("suspect.alibiLine", suspect.statement))
                    .font(Trace.Fonts.caption)
                    .foregroundStyle(Trace.Colors.text2)
                    .lineLimit(2)
                FlowLayout(spacing: 8) {
                    StatusBadge(text: standing.text, color: standing.color, symbol: standing.symbol)
                    Text(L10n.f(pieces == 1 ? "carnet.pieceCountOne" : "carnet.pieceCountMany", pieces))
                        .font(Trace.Fonts.caption)
                        .foregroundStyle(Trace.Colors.text2)
                        .frame(minHeight: Trace.Height.badge)
                }
                .padding(.top, 4)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            Image(systemName: "chevron.right")
                .font(Trace.Fonts.caption.weight(.semibold))
                .foregroundStyle(Trace.Colors.text3)
                .padding(.top, 4)
                .accessibilityHidden(true)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .benCard()
        .contentShape(Rectangle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(spoken(standing)))
    }

    private func spoken(_ standing: SuspectStanding) -> String {
        [contact?.name ?? suspect.contact, suspect.age.map { L10n.f("suspect.age", $0) }, suspect.role,
         L10n.f("suspect.alibiLine", suspect.statement), LinkTally.spoken(against: against, favour: favour)]
            .compactMap { $0 }
            .joined(separator: ", ")
    }
}

/// « ↑2 ↓1 »: how many filed pieces accuse / clear a suspect — numbers, never colour alone.
struct LinkTally: View {
    let against: Int
    let favour: Int

    var body: some View {
        Group {
            if against + favour == 0 {
                Text(L10n.t("suspect.noPiece")).foregroundStyle(Trace.Colors.text2)
            } else {
                HStack(spacing: 10) {
                    Text(verbatim: "↑ \(against)").foregroundStyle(against > 0 ? Trace.Colors.criticalOnDark : Trace.Colors.text3)
                    Text(verbatim: "↓ \(favour)").foregroundStyle(favour > 0 ? Trace.Colors.successText : Trace.Colors.text3)
                }
            }
        }
        .font(Trace.Fonts.data)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(Self.spoken(against: against, favour: favour)))
    }

    /// « 2 pièces l'accusent, 1 le disculpe ».
    static func spoken(against: Int, favour: Int) -> String {
        if against + favour == 0 { return L10n.t("suspect.noPiece") }
        return L10n.f("carnet.a11y.accusedBy", against) + ", " + L10n.f("carnet.a11y.clearedBy", favour)
    }

    /// ↑ accuses, ↓ clears, · linked without a reading.
    static func glyph(_ stance: NotebookEntry.Stance?) -> String {
        switch stance {
        case .incriminates: "↑"
        case .clears: "↓"
        case nil: "·"
        }
    }

    /// The colour of a reading (with its glyph and word, never alone).
    static func color(_ stance: NotebookEntry.Stance?) -> Color {
        switch stance {
        case .incriminates: Trace.Colors.criticalOnDark
        case .clears: Trace.Colors.successText
        case nil: Trace.Colors.text2
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

// MARK: - Connections (§5 ConnectionChain)

/// Words, symbols and colours of the links between two elements. Always the word; the colour only
/// repeats it (contredit = warning, confirme = success, the others = benText).
enum ConnectionFormat {
    static func verb(_ verb: Connection.Verb) -> String { L10n.t("connection.verb.\(verb.rawValue)") }

    static func symbol(_ verb: Connection.Verb) -> String {
        switch verb {
        case .contradicts: "notequal"
        case .confirms: "checkmark"
        case .samePlace: "mappin.and.ellipse"
        case .sameTime: "clock"
        case .implicates: "arrow.down.right"
        }
    }

    static func color(_ verb: Connection.Verb) -> Color {
        switch verb {
        case .contradicts: Trace.Colors.warning
        case .confirms: Trace.Colors.successText
        case .samePlace, .sameTime, .implicates: Trace.Colors.benText
        }
    }

    /// The node's data label: « PIÈCE 03 », or « PERSONNE ».
    static func label(_ node: Connection.Node, in game: Investigation) -> String {
        switch node {
        case .piece(let ref): game.pieceNumber(of: ref).map { PieceFormat.title($0) } ?? PieceFormat.kind(ref, in: game)
        case .person: L10n.t("connection.person")
        }
    }

    /// The node's text: the piece in one line, or the person's name.
    static func text(_ node: Connection.Node, in game: Investigation) -> String {
        switch node {
        case .piece(let ref): PieceFormat.preview(ref, in: game)
        case .person(let id): game.index.suspect(id).map { game.name(of: $0.contact) } ?? id
        }
    }

    /// Short form in a line of meta: « PIÈCE 03 » or a person's name.
    static func tag(_ node: Connection.Node, in game: Investigation) -> String {
        switch node {
        case .piece: label(node, in: game)
        case .person: text(node, in: game)
        }
    }

    /// VoiceOver: « Connexion 1 : Pièce 03, contredit, Pièce 02 ».
    static func spoken(_ connection: Connection, number: Int, in game: Investigation) -> String {
        var parts: [String] = []
        for (i, node) in connection.nodes.enumerated() {
            if i > 0, i - 1 < connection.verbs.count { parts.append(verb(connection.verbs[i - 1]).lowercased()) }
            parts.append(tag(node, in: game) + (node.isPerson ? "" : " " + text(node, in: game)))
        }
        return L10n.f("connection.short", number) + " : " + parts.joined(separator: ", ")
    }
}

extension Connection.Node {
    var isPerson: Bool {
        switch self {
        case .person: true
        case .piece: false
        }
    }

    var pieceRef: ItemRef? {
        switch self {
        case .piece(let ref): ref
        case .person: nil
        }
    }
}

/// ConnectionChain (§5): a `surface` card, « CONNEXION n · verbe », the elements on `surface2`
/// (data label + text), and between two of them a 2 × 28 pt connector with its verb. It never
/// says whether a link is right.
struct ConnectionChain: View {
    let connection: Connection
    let number: Int
    let game: Investigation
    /// The link (index in `verbs`) to draw now, top → bottom (a new connection or element).
    var drawLink: Int? = nil
    var onOpenPiece: ((ItemRef) -> Void)? = nil
    var onAdd: (() -> Void)? = nil
    var onDelete: (() -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .center) {
                Text(L10n.f("connection.title", number, connection.verbs.first.map { ConnectionFormat.verb($0) } ?? ""))
                    .fieldLabel()
                    .accessibilityAddTraits(.isHeader)
                Spacer(minLength: 8)
                if let onDelete {
                    Menu {
                        Button(role: .destructive, action: onDelete) {
                            Label(L10n.t("connection.delete"), systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(Trace.Fonts.headline)
                            .foregroundStyle(Trace.Colors.text2)
                            .frame(width: Trace.Height.hit, height: Trace.Height.hit)
                            .contentShape(Rectangle())
                    }
                    .accessibilityLabel(Text(L10n.t("connection.options")))
                    .accessibilityIdentifier("notebook.connection.menu.\(connection.id)")
                }
            }
            .padding(.bottom, 6)
            ForEach(Array(connection.nodes.enumerated()), id: \.offset) { i, node in
                if i > 0, i - 1 < connection.verbs.count {
                    ConnectorView(verb: connection.verbs[i - 1], animated: drawLink == i - 1)
                }
                nodeView(node)
            }
            if let onAdd {
                Button(action: onAdd) {
                    Label(L10n.t("connection.addElement"), systemImage: "plus")
                }
                .buttonStyle(TextLinkStyle())
                .padding(.top, 6)
                .accessibilityIdentifier("notebook.connection.add.\(connection.id)")
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 10)
        .padding(.bottom, onAdd == nil ? 16 : 6)
        .frame(maxWidth: .infinity, alignment: .leading)
        .benCard()
        .contextMenu {
            if let onDelete {
                Button(role: .destructive, action: onDelete) {
                    Label(L10n.t("connection.delete"), systemImage: "trash")
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(Text(ConnectionFormat.spoken(connection, number: number, in: game)))
    }

    @ViewBuilder
    private func nodeView(_ node: Connection.Node) -> some View {
        let content = HStack(alignment: .center, spacing: 12) {
            if case .person(let id) = node, let suspect = game.index.suspect(id) {
                IDPhoto(contact: game.contact(suspect.contact), width: 32, height: 40)
                    .accessibilityHidden(true)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(ConnectionFormat.label(node, in: game)).font(Trace.Fonts.data).foregroundStyle(Trace.Colors.benText)
                Text(ConnectionFormat.text(node, in: game))
                    .font(Trace.Fonts.callout)
                    .foregroundStyle(Trace.Colors.text)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            if node.pieceRef != nil, onOpenPiece != nil {
                Image(systemName: "chevron.right").font(Trace.Fonts.caption.weight(.semibold)).foregroundStyle(Trace.Colors.text3)
                    .accessibilityHidden(true)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, minHeight: Trace.Height.hit, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: Trace.Radius.node, style: .continuous).fill(Trace.Colors.surface2))
        if let ref = node.pieceRef, let onOpenPiece {
            Button { onOpenPiece(ref) } label: { content.contentShape(Rectangle()) }
                .buttonStyle(PressableStyle())
                .accessibilityElement(children: .combine)
        } else {
            content.accessibilityElement(children: .combine)
        }
    }
}

/// The vertical 2 × 28 pt connector and its verb. A new one draws itself top → bottom (300 ms,
/// easeInOut) and its verb fades in; with reduced motion, a 200 ms fade only (§8).
struct ConnectorView: View {
    let verb: Connection.Verb
    /// False until a new connector has drawn itself.
    @State private var drawn: Bool
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    @AppStorage(Preferences.reduceMotionKey) private var appReduceMotion = false

    init(verb: Connection.Verb, animated: Bool = false) {
        self.verb = verb
        _drawn = State(initialValue: !animated)
    }

    var body: some View {
        let color = ConnectionFormat.color(verb)
        let reduced = systemReduceMotion || appReduceMotion
        HStack(alignment: .center, spacing: 12) {
            ZStack(alignment: .top) {
                Color.clear.frame(width: 2, height: 28)
                Rectangle().fill(color).frame(width: 2, height: drawn || reduced ? 28 : 0)
                    .opacity(reduced && !drawn ? 0 : 1)
            }
            .frame(width: 2, height: 28)
            HStack(spacing: 5) {
                Image(systemName: ConnectionFormat.symbol(verb))
                Text(ConnectionFormat.verb(verb))
            }
            .font(Trace.Fonts.caption.weight(.semibold))
            .foregroundStyle(color)
            .opacity(drawn ? 1 : 0)
        }
        .padding(.leading, 22)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(ConnectionFormat.verb(verb)))
        .onAppear {
            guard !drawn else { return }
            // After the sheet that created it has gone down.
            withAnimation((reduced ? Animation.easeInOut(duration: 0.2) : .easeInOut(duration: 0.3)).delay(0.3)) { drawn = true }
        }
    }
}

// MARK: - Chronology (§6-08)

/// Carnet › Chronologie: the dated pieces of the file in time order, under a day header. Time in
/// Plex Mono 14 (52 pt column), a 10 pt dot and a 2 pt line, the text, « PIÈCE nn · source ».
/// A piece the player put in a « contredit » link: warning dot with a halo, « ≠ contredit PIÈCE nn ».
/// Declarations (alibis) are events too: « Déclaration »; without a time, they come first.
struct ChronologySheet: View {
    struct Declaration: Identifiable {
        let id: String
        let who: String
        let text: String
        var at: Moment? = nil
    }

    let game: Investigation
    var declarations: [Declaration] = []
    var onOpen: ((ItemRef) -> Void)? = nil

    private enum Event {
        case piece(NotebookEntry, ItemDescriber.Item, Moment)
        case declaration(Declaration, Moment)

        var at: Moment {
            switch self {
            case .piece(_, _, let at), .declaration(_, let at): at
            }
        }
    }

    var body: some View {
        let pieces: [Event] = game.notebook.compactMap { entry in
            let item = ItemDescriber.describe(entry.ref, in: game)
            return item.at.map { Event.piece(entry, item, $0) }
        }
        let timed = declarations.compactMap { d in d.at.map { Event.declaration(d, $0) } }
        let events = (pieces + timed).sorted { $0.at < $1.at }
        let untimed = declarations.filter { $0.at == nil }
        VStack(alignment: .leading, spacing: 0) {
            if pieces.isEmpty {
                EmptyPage(title: L10n.t("chrono.emptyTitle"), tip: L10n.t("chrono.emptyBody"))
                    .accessibilityIdentifier("notebook.chrono.empty")
            }
            if !untimed.isEmpty {
                SectionHeader(title: L10n.t("chrono.statements"))
                    .padding(.top, pieces.isEmpty ? 0 : 4)
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(untimed) { declaration in
                        row(time: nil, text: declaration.who + " · " + declaration.text, meta: L10n.t("chrono.statement"),
                            dot: .declaration, last: false)
                    }
                }
                .padding(.bottom, 12)
            }
            ForEach(Array(events.enumerated()), id: \.offset) { offset, event in
                let previous = offset > 0 ? events[offset - 1].at : nil
                if previous.map({ !$0.isSameDay(as: event.at) }) ?? true {
                    Text(PhoneFormat.longDayCapitalized(event.at))
                        .font(Trace.Fonts.caption)
                        .foregroundStyle(Trace.Colors.text2)
                        .padding(.leading, 64)
                        .padding(.top, offset == 0 ? 0 : 12)
                        .padding(.bottom, 8)
                        .accessibilityAddTraits(.isHeader)
                }
                eventRow(event, last: offset == events.count - 1)
            }
        }
    }

    private enum Dot { case plain, contradiction, declaration }

    @ViewBuilder
    private func eventRow(_ event: Event, last: Bool) -> some View {
        switch event {
        case .piece(let entry, let item, let at):
            let number = game.pieceNumber(of: entry.ref) ?? 0
            let against = game.contradicted(by: entry.ref)
            let meta = against.isEmpty
                ? PieceFormat.title(number) + " · " + PieceFormat.origin(entry.ref, in: game)
                : against.map { L10n.f("chrono.contradicts", ConnectionFormat.tag($0, in: game)) }.joined(separator: " · ")
            let line = row(time: at, text: item.label, meta: meta, dot: against.isEmpty ? .plain : .contradiction, last: last)
            if let onOpen {
                Button { onOpen(entry.ref) } label: { line }
                    .buttonStyle(PressableStyle())
                    .accessibilityIdentifier("notebook.row")
            } else {
                line.accessibilityIdentifier("notebook.row")
            }
        case .declaration(let declaration, let at):
            row(time: at, text: declaration.who + " · " + declaration.text, meta: L10n.t("chrono.statement"), dot: .declaration, last: last)
        }
    }

    private func row(time: Moment?, text: String, meta: String, dot: Dot, last: Bool) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(time.map { PhoneFormat.time($0) } ?? "")
                .font(.custom(Trace.FontName.monoMedium, size: 14, relativeTo: .subheadline))
                .foregroundStyle(Trace.Colors.text)
                .frame(width: 52, alignment: .leading)
            VStack(spacing: 0) {
                dotView(dot).padding(.top, 5)
                Rectangle().fill(last ? Color.clear : Trace.Colors.surface3).frame(width: 2).frame(maxHeight: .infinity)
            }
            .frame(width: 14)
            .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 3) {
                Text(text)
                    .font(Trace.Fonts.callout)
                    .foregroundStyle(Trace.Colors.text)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
                Text(meta)
                    .font(dot == .contradiction ? Trace.Fonts.caption.weight(.semibold) : Trace.Fonts.caption)
                    .foregroundStyle(dot == .contradiction ? Trace.Colors.warning : Trace.Colors.text2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.bottom, 16)
        }
        // The line runs the full height of the row.
        .fixedSize(horizontal: false, vertical: true)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private func dotView(_ dot: Dot) -> some View {
        switch dot {
        case .plain:
            Circle().fill(Trace.Colors.benText).frame(width: 10, height: 10)
        case .contradiction:
            Circle().fill(Trace.Colors.warning).frame(width: 10, height: 10)
                .background(Circle().fill(Trace.Colors.tint(Trace.Colors.warning)).frame(width: 18, height: 18))
        case .declaration:
            Circle().strokeBorder(Trace.Colors.text2, lineWidth: 2).frame(width: 10, height: 10)
        }
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
