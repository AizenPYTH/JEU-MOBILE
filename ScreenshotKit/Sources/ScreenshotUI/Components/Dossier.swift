#if os(iOS)
import SwiftUI
import CaseEngine

// The pieces of the case file as the Carnet shows them (V4 « Dossier lisible » §3 on the UX of V3
// §5): NotebookDividers, SuspectSheet, EvidencePrint (+ the ÉLÉMENT CLÉ stamp), RedThread, the ruled
// chronology, EvidenceCard. Paper, prints and red thread, ink on paper. They only show what the
// player put in the file and decided — never a reading of it, never whether a link is right.

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

// MARK: - Notebook tokens (V4 §2 « Typographie », §3)

extension Trace.Fonts {
    /// A Carnet divider's label: Plex Sans 13/600.
    static let notebookDivider = Font.custom(Trace.FontName.sansSemibold, size: 13, relativeTo: .footnote)
    /// A divider's counter: Plex Mono 10.
    static let notebookCount = Font.custom(Trace.FontName.monoSemibold, size: 10, relativeTo: .caption2)
    /// A suspect's name on a SuspectSheet: Newsreader 19/600.
    static let notebookName = Font.custom(Trace.FontName.serifSemibold, size: 19, relativeTo: .title3)
    /// Reading text on a notebook page (the chronology): Plex Sans 15.
    static let notebookText = Font.custom(Trace.FontName.sans, size: 15, relativeTo: .subheadline)
    /// A time in the chronology's margin: Plex Mono 14.
    static let notebookTime = Font.custom(Trace.FontName.monoMedium, size: 14, relativeTo: .subheadline)
    /// The words written along the red thread: Caveat 20.
    static let threadNote = Font.custom(Trace.FontName.hand, size: 20, relativeTo: .title3)
}

extension Trace.Colors {
    /// The V3 « warning » (timer under 01:00, a hint's cost) on paper: a dark ochre, 5.2:1 on paperCard.
    static let notebookWarning = Color(hex: 0x8A5A12)
    /// The hairline round a capture, a card or a field on paper.
    static let notebookHairline = Color(hex: 0x1C1A17, opacity: 0.16)
}

/// A board of the Carnet (§3): `kraftBoard` under the pieces, `kraftDark` under the red thread;
/// kraft fibres in multiply between the cards (none with « Augmenter le contraste »), a dark edge.
struct BoardSurface: View {
    var color: Color = Trace.Colors.kraftBoard
    @Environment(\.colorSchemeContrast) private var contrast

    var body: some View {
        Rectangle()
            .fill(color)
            .overlay { if contrast != .increased { PaperGrain(intensity: 0.04, texture: "tex_kraft_fibers") } }
            .overlay(Rectangle().strokeBorder(Color.black.opacity(0.28), lineWidth: 1))
            .clipped()
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }
}

/// A card laid on a board or a page: `paperCard`, square corners, the slip shadow. No texture (it
/// holds text and buttons).
struct PaperCardBackground: View {
    var color: Color = Trace.Colors.paperCard
    var shadow = Trace.Shadow.slip

    var body: some View {
        Rectangle()
            .fill(color)
            .shadow(color: shadow.color, radius: shadow.radius, y: shadow.y)
            .accessibilityHidden(true)
    }
}

// MARK: - Exhibit (a piece of the file)

/// One exhibit on paper: what the piece shows (`ExhibitSupport`) on a `paperCard` slip, then
/// « PIÈCE nn · Type · HH:MM ».
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
                    Text(PieceFormat.title(number)).font(Trace.Fonts.data).foregroundStyle(Trace.Colors.ink)
                }
                Spacer(minLength: 4)
                Text(PieceFormat.type(ref, in: game) + (item.at.map { " · " + PhoneFormat.time($0) } ?? ""))
                    .font(Trace.Fonts.caption).foregroundStyle(Trace.Colors.ink2).lineLimit(1)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(PaperCardBackground())
        .accessibilityElement(children: .combine)
    }
}

/// What an exhibit shows, on paper (ink): the photo as a print, the message capture (the phone's
/// light screen, like the screen it came from), the call record, the map extract, the diary entry,
/// the note… Shared by the exhibits, the Carnet's piece detail and the filing slip.
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
                    .accessibilityHidden(true)
                    if ref.kind == .photoInfo || !compact {
                        Text(photo.caption).font(Trace.Fonts.callout).foregroundStyle(Trace.Colors.ink).lineLimit(compact ? 2 : nil)
                            .fixedSize(horizontal: false, vertical: !compact)
                    }
                    if ref.kind == .photoInfo, let place = photo.place {
                        Text(place).font(Trace.Fonts.caption).foregroundStyle(Trace.Colors.ink2).lineLimit(compact ? 1 : nil)
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
                        .foregroundStyle(Trace.Colors.ink2)
                    Text(PhoneFormat.time(event.start) + (event.end.map { "–" + PhoneFormat.time($0) } ?? ""))
                        .font(Trace.Fonts.data).foregroundStyle(Trace.Colors.ink)
                    Text(event.title).font(Trace.Fonts.callout.weight(.semibold)).foregroundStyle(Trace.Colors.ink).lineLimit(compact ? 2 : nil)
                    if let location = event.location {
                        Text(location).font(Trace.Fonts.caption).foregroundStyle(Trace.Colors.ink2).lineLimit(compact ? 1 : nil)
                    }
                }
            }
        case .note:
            if let note = index.note(ref.id) {
                Text("« \(note.body) »").font(Trace.Fonts.quote).foregroundStyle(Trace.Colors.ink).lineLimit(compact ? 4 : nil)
                    .fixedSize(horizontal: false, vertical: !compact)
            }
        case .mail:
            if let mail = index.mail(ref.id) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(mail.fromName).font(Trace.Fonts.caption.weight(.semibold)).foregroundStyle(Trace.Colors.ink).lineLimit(1)
                    Text(mail.subject).font(Trace.Fonts.callout.weight(.semibold)).foregroundStyle(Trace.Colors.ink).lineLimit(compact ? 2 : nil)
                    Text(mail.body).font(Trace.Fonts.callout).foregroundStyle(Trace.Colors.ink2).lineLimit(compact ? 3 : nil)
                        .fixedSize(horizontal: false, vertical: !compact)
                    if let files = mail.attachments, !files.isEmpty {
                        Text("⎘ " + files.joined(separator: " · ")).font(Trace.Fonts.caption).foregroundStyle(Trace.Colors.ink2).lineLimit(1)
                    }
                }
            }
        case .browser:
            if let entry = index.browserEntry(ref.id) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(entry.url ?? L10n.t("piece.search")).font(Trace.Fonts.data).foregroundStyle(Trace.Colors.ink2).lineLimit(1)
                    Text(entry.kind == .search ? "« \(entry.text) »" : entry.text)
                        .font(Trace.Fonts.callout.weight(.semibold)).foregroundStyle(Trace.Colors.ink).lineLimit(compact ? 3 : nil)
                    if let summary = entry.summary, !compact {
                        Text(summary).font(Trace.Fonts.callout).foregroundStyle(Trace.Colors.ink2)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        case .contact:
            if let contact = game.contact(ref.id) {
                HStack(spacing: 8) {
                    Avatar(contact: contact, size: 30)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(contact.name).font(Trace.Fonts.callout.weight(.semibold)).foregroundStyle(Trace.Colors.ink)
                        Text(contact.phone).font(Trace.Fonts.data).foregroundStyle(Trace.Colors.ink2)
                    }
                }
            }
        case .app:
            Text(PieceFormat.preview(ref, in: game)).font(Trace.Fonts.callout).foregroundStyle(Trace.Colors.ink)
        }
    }

    /// A message capture: the bubble on the phone's white screen, like the screen it came from.
    private func capture(from: String, text: String, mine: Bool) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(from).font(Trace.Fonts.caption).foregroundStyle(Trace.Colors.ink2).lineLimit(1)
            Text(text)
                .font(Theme.Fonts.callout)
                .foregroundStyle(mine ? Theme.Colors.bubbleOutText : Theme.Colors.textPrimary)
                .lineLimit(compact ? 4 : nil)
                .fixedSize(horizontal: false, vertical: !compact)
                .padding(.horizontal, 10).padding(.vertical, 7)
                .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(mine ? Theme.Colors.bubbleOut : Theme.Colors.bgBubbleIn))
                .frame(maxWidth: .infinity, alignment: mine ? .trailing : .leading)
                .padding(8)
                .background(Rectangle().fill(Theme.Colors.bgBase))
                .overlay(Rectangle().strokeBorder(Trace.Colors.notebookHairline, lineWidth: 1))
        }
    }

    /// A call record: the call among its neighbours, the call itself underlined in ink.
    private func callRecord(_ call: Call) -> some View {
        let calls = game.calls.sorted { $0.at < $1.at }
        let i = calls.firstIndex { $0.id == call.id } ?? 0
        let rows = calls.isEmpty ? [call] : Array(calls[max(0, i - 1)...min(calls.count - 1, i + 1)])
        return VStack(alignment: .leading, spacing: 3) {
            Text(L10n.t("piece.callRecord")).font(Trace.Fonts.data).foregroundStyle(Trace.Colors.ink2)
            ForEach(rows) { row in
                let this = row.id == call.id
                HStack {
                    Text(PhoneFormat.time(row.at)).font(Trace.Fonts.data)
                    Text(game.name(of: row.contact).split(separator: " ").first.map(String.init) ?? "")
                        .font(this ? Trace.Fonts.callout.weight(.semibold) : Trace.Fonts.callout).lineLimit(1)
                    Text(CallsFormat.arrow(row)).font(Trace.Fonts.caption)
                    Spacer(minLength: 2)
                    Text(row.durationSeconds > 0 ? PhoneFormat.duration(row.durationSeconds) : "—").font(Trace.Fonts.data)
                }
                .foregroundStyle(this ? Trace.Colors.ink : Trace.Colors.ink2)
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(Rectangle().fill(this ? Trace.Colors.tint(Trace.Colors.red) : .clear))
            }
        }
    }

    /// A map extract: streets, the last position circled in red.
    private func mapExtract(_ track: LocationTrack) -> some View {
        let last = track.points.max { $0.at < $1.at }
        return VStack(alignment: .leading, spacing: 4) {
            MapGlyph(seed: track.id)
                .frame(height: compact ? 64 : 120)
            Text(L10n.f("item.track", game.name(of: track.contact))).font(Trace.Fonts.callout.weight(.semibold)).foregroundStyle(Trace.Colors.ink).lineLimit(1)
            if let last, let place = game.index.place(last.place) {
                Text(place.name).font(Trace.Fonts.caption).foregroundStyle(Trace.Colors.ink2).lineLimit(1)
            }
        }
    }
}

/// A printed map extract: a few streets on white, the last position circled in red. Decorative
/// (the place is always written next to it).
struct MapGlyph: View {
    let seed: String

    var body: some View {
        Canvas { context, size in
            var rng = SeededRandom(seed: seed)
            for _ in 0..<6 {
                var road = Path()
                road.move(to: CGPoint(x: rng.next() * size.width, y: 0))
                road.addLine(to: CGPoint(x: rng.next() * size.width, y: size.height))
                context.stroke(road, with: .color(Trace.Colors.ink2.opacity(0.28)), lineWidth: 2 + rng.next() * 3)
            }
            let c = CGPoint(x: size.width * 0.62, y: size.height * 0.42)
            context.fill(Path(ellipseIn: CGRect(x: c.x - 3, y: c.y - 3, width: 6, height: 6)), with: .color(Trace.Colors.red))
            context.stroke(Path(ellipseIn: CGRect(x: c.x - 10, y: c.y - 10, width: 20, height: 20)), with: .color(Trace.Colors.red), lineWidth: 2)
        }
        .background(Trace.Colors.paperCardLight)
        .overlay(Rectangle().strokeBorder(Trace.Colors.notebookHairline, lineWidth: 1))
        .accessibilityHidden(true)
    }
}

// MARK: - EvidencePrint (§3, screen 07)

/// The 86 pt vignette of a piece on the board: the photo as a print; a message's words on white;
/// a map glyph; otherwise the piece in a few words on white, with its kind's symbol.
struct EvidenceVignette: View {
    let ref: ItemRef
    let game: Investigation
    var height: CGFloat = 86

    var body: some View {
        Group {
            switch ref.kind {
            case .photo, .photoInfo:
                if let photo = game.index.photo(ref.id) {
                    PhotoPrint(border: 4) {
                        GeneratedPhoto(photo: photo)
                            .frame(maxWidth: .infinity)
                            .frame(height: height)
                    }
                } else {
                    slip(text: PieceFormat.preview(ref, in: game), from: nil)
                }
            case .message:
                if let message = game.index.message(ref.id) {
                    slip(text: message.text ?? L10n.t("item.photo"), from: game.name(of: message.from))
                } else {
                    slip(text: PieceFormat.preview(ref, in: game), from: nil)
                }
            case .draft:
                slip(text: PieceFormat.preview(ref, in: game), from: L10n.t("messages.draft"))
            case .track:
                MapGlyph(seed: ref.id)
                    .frame(height: height)
                    .padding(4)
                    .background(Trace.Colors.photoBorder)
                    .shadow(color: Trace.Shadow.print.color, radius: Trace.Shadow.print.radius, y: Trace.Shadow.print.y)
            default:
                slip(text: PieceFormat.preview(ref, in: game), from: nil)
            }
        }
        .accessibilityHidden(true)
    }

    /// A white strip with the piece's words (the phone's type for a message: it keeps its look).
    private func slip(text: String, from: String?) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 5) {
                Image(systemName: Self.symbol(ref.kind))
                if let from { Text(from).lineLimit(1) }
            }
            .font(Theme.Fonts.caption)
            .foregroundStyle(Theme.Colors.textSecondary)
            Text(text)
                .font(Theme.Fonts.callout)
                .foregroundStyle(Theme.Colors.textPrimary)
                .lineLimit(3)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(8)
        .frame(maxWidth: .infinity, minHeight: height, maxHeight: height, alignment: .topLeading)
        .background(Theme.Colors.bgBase)
        .clipped()
        .overlay(Rectangle().strokeBorder(Trace.Colors.notebookHairline, lineWidth: 1))
        .shadow(color: Trace.Shadow.print.color, radius: Trace.Shadow.print.radius, y: Trace.Shadow.print.y)
    }

    static func symbol(_ kind: ItemRef.Kind) -> String {
        switch kind {
        case .message: "message"
        case .draft: "square.and.pencil"
        case .photo: "photo"
        case .photoInfo: "info.circle"
        case .call: "phone"
        case .track: "map"
        case .calendar: "calendar"
        case .note: "note.text"
        case .mail: "envelope"
        case .browser: "magnifyingglass"
        case .contact: "person.crop.rectangle"
        case .app: "app"
        }
    }
}

/// The ÉLÉMENT CLÉ stamp (PNG, multiply) on a piece the PLAYER put in a « contredit » thread —
/// never from the case's own data. `falling`: it falls now (180 ms, rigid haptic; appears with
/// reduced motion).
struct KeyElementStamp: View {
    static let asset = "stamp_element_cle_rouge_marque"
    var falling = false
    var width: CGFloat = 96
    var onLanded: () -> Void = {}

    var body: some View {
        Group {
            if falling {
                FallingStampImage(asset: Self.asset, label: L10n.t("carnet.keyElement"), width: width, onPaper: true,
                                  angle: -8, delay: 0.35, onLanded: onLanded)
            } else {
                StampImage(asset: Self.asset, label: L10n.t("carnet.keyElement"), width: width, onPaper: true, angle: -8)
            }
        }
        .allowsHitTesting(false)
    }
}

/// Whether a print carries the ÉLÉMENT CLÉ stamp, and whether it falls now.
enum KeyStampState: Equatable { case none, still, falling }

/// EvidencePrint (§3): a piece on the evidence board, a `paperCard` slip holding the 86 pt vignette
/// (the print is tilted by the piece's id, ≤ 1.5°), « PIÈCE nn », its type, and the links line
/// (« ↑ Emma », « ≠ contredit 05 » in red). Tap: the piece's detail. The slip itself, its text and
/// its buttons (`footer`) stay straight.
struct EvidencePrint<Footer: View>: View {
    let ref: ItemRef
    let game: Investigation
    let number: Int
    var stamp: KeyStampState = .none
    let onOpen: () -> Void
    var onStampLanded: () -> Void = {}
    @ViewBuilder var footer: () -> Footer

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Button(action: onOpen) {
                VStack(alignment: .leading, spacing: 6) {
                    EvidenceVignette(ref: ref, game: game)
                        .tilt("\(ref)")
                        .overlay(alignment: .topTrailing) {
                            if stamp != .none {
                                KeyElementStamp(falling: stamp == .falling, width: 92, onLanded: onStampLanded)
                                    .offset(x: 8, y: -10)
                            }
                        }
                        .padding(.top, 2)
                        .padding(.bottom, 6)
                    Text(PieceFormat.title(number))
                        .font(Trace.Fonts.data)
                        .tracking(1)
                        .foregroundStyle(Trace.Colors.ink)
                    Text(PieceFormat.caption(ref, in: game))
                        .font(Trace.Fonts.caption)
                        .foregroundStyle(Trace.Colors.ink2)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                    PrintLinks(ref: ref, game: game)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(PressableStyle())
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text(spoken))
            .accessibilityAddTraits(.isButton)
            .accessibilityIdentifier("notebook.row")
            footer()
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(PaperCardBackground())
    }

    private var spoken: String {
        [PieceFormat.spoken(ref, in: game, number: number), PrintLinks.spoken(ref: ref, game: game),
         stamp == .none ? nil : L10n.t("carnet.keyElement")]
            .compactMap { $0 }
            .joined(separator: ". ")
    }
}

/// The links line of a print: « ↑ Emma » / « ↓ Emma » (the player's reading, arrow + colour) and
/// « ≠ contredit 05 » in red for each element the player said it contradicts.
struct PrintLinks: View {
    let ref: ItemRef
    let game: Investigation

    var body: some View {
        let entry = game.notebook.first { $0.ref == ref }
        let suspect = entry?.linkedTo.flatMap { game.index.suspect($0) }
        let against = game.contradicted(by: ref)
        if suspect != nil || !against.isEmpty {
            FlowLayout(spacing: 8) {
                if let suspect {
                    Text(verbatim: LinkTally.glyph(entry?.stance) + " " + Self.firstName(game.name(of: suspect.contact)))
                        .foregroundStyle(LinkTally.color(entry?.stance))
                }
                ForEach(Array(against.enumerated()), id: \.offset) { _, node in
                    Text(L10n.f("chrono.contradicts", Self.shortTag(node, in: game)))
                        .foregroundStyle(Trace.Colors.red)
                }
            }
            .font(Trace.Fonts.caption.weight(.semibold))
            .lineLimit(1)
        }
    }

    /// « 05 » for a piece, the first name for a person.
    static func shortTag(_ node: Connection.Node, in game: Investigation) -> String {
        switch node {
        case .piece(let ref): game.pieceNumber(of: ref).map { PieceFormat.number($0) } ?? PieceFormat.kind(ref, in: game)
        case .person(let id): firstName(game.index.suspect(id).map { game.name(of: $0.contact) } ?? id)
        }
    }

    static func firstName(_ name: String) -> String {
        name.split(separator: " ").first.map(String.init) ?? name
    }

    /// VoiceOver: « L'accuse : Emma. ≠ contredit PIÈCE 05 ».
    static func spoken(ref: ItemRef, game: Investigation) -> String? {
        let entry = game.notebook.first { $0.ref == ref }
        var parts: [String] = []
        if let suspect = entry?.linkedTo.flatMap({ game.index.suspect($0) }) {
            let name = firstName(game.name(of: suspect.contact))
            switch entry?.stance {
            case .incriminates:
                parts.append(game.caseFile.isAlibi ? L10n.t("alibi.linkContradicts") : L10n.f("carnet.linkAccuses", name))
            case .clears:
                parts.append(game.caseFile.isAlibi ? L10n.t("alibi.linkConfirms") : L10n.f("carnet.linkClears", name))
            case nil:
                parts.append(L10n.f("toast.linked", name))
            }
        }
        parts += game.contradicted(by: ref).map { L10n.f("chrono.contradicts", ConnectionFormat.tag($0, in: game)) }
        return parts.isEmpty ? nil : parts.joined(separator: ". ")
    }
}

// MARK: - EvidenceCard (a piece on a paper sheet)

/// EvidenceCard (V3 §5, on paper): a `paperCard` card — « PIÈCE nn » (data, ink), « type · source »
/// (caption, ink2), the content in three lines then « Lire plus », then the card's own footer.
/// States: plain · selected (2 pt ink rule) · contradiction (red rule + « ≠ contredit PIÈCE nn »).
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
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(PaperCardBackground(shadow: Trace.Shadow.print))
        .overlay(Rectangle().strokeBorder(borderColor, lineWidth: mark == .plain ? 1 : 2))
        .accessibilityElement(children: .contain)
    }

    private var borderColor: Color {
        switch mark {
        case .plain: Trace.Colors.notebookHairline
        case .selected: Trace.Colors.ink
        case .contradiction: Trace.Colors.red
        }
    }

    private func summary(_ number: Int, readMore: Bool) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(PieceFormat.title(number)).font(Trace.Fonts.data).tracking(1).foregroundStyle(Trace.Colors.ink)
                Spacer(minLength: 4)
                if let badge {
                    Text(badge)
                        .font(Trace.Fonts.caption.weight(.semibold))
                        .foregroundStyle(Trace.Colors.red)
                        .multilineTextAlignment(.trailing)
                }
            }
            Text(PieceFormat.caption(ref, in: game))
                .font(Trace.Fonts.caption)
                .foregroundStyle(Trace.Colors.ink2)
                .fixedSize(horizontal: false, vertical: true)
            EvidencePreview(ref: ref, game: game)
            if readMore {
                Text(L10n.t("carnet.readMore"))
                    .font(Trace.Fonts.caption.weight(.semibold))
                    .foregroundStyle(Trace.Colors.ink)
                    .underline()
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

/// The content of a piece in a card: a photo thumbnail (a small print), or its words in three lines.
struct EvidencePreview: View {
    let ref: ItemRef
    let game: Investigation

    var body: some View {
        switch ref.kind {
        case .photo, .photoInfo:
            if let photo = game.index.photo(ref.id) {
                HStack(alignment: .top, spacing: 12) {
                    PhotoPrint(border: 3) {
                        GeneratedPhoto(photo: photo).frame(width: 84, height: 63)
                    }
                    .accessibilityHidden(true)
                    Text(PieceFormat.preview(ref, in: game))
                        .font(Trace.Fonts.callout)
                        .foregroundStyle(Trace.Colors.ink)
                        .lineLimit(3)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        default:
            Text(PieceFormat.preview(ref, in: game))
                .font(Trace.Fonts.callout)
                .foregroundStyle(Trace.Colors.ink)
                .lineLimit(3)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

// MARK: - SuspectSheet (§3, screen 06)

/// What the player's readings say about a suspect: accused (↑ n l'accusent), cleared (↓ n le
/// disculpent) or neutral (« Rien de relevé »). Counts only what the player decided, never a verdict.
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

    /// On paper.
    var color: Color {
        switch self {
        case .neutral, .split: Trace.Colors.ink2
        case .accused: Trace.Colors.red
        case .cleared: Trace.Colors.green
        }
    }
}

/// « ↑ 2 contre   ↓ 1 pour » (Plex Mono 13/700): red and green on paper, ink2 at zero — always
/// with the arrow and the word, never the colour alone.
struct StanceTally: View {
    let against: Int
    let favour: Int
    /// ALIBI: « contredisent » / « confirment ».
    var alibi = false

    var body: some View {
        FlowLayout(spacing: 14) {
            Text(alibi ? "↑ \(against) " + L10n.t("alibi.tallyContradicts") : L10n.f("carnet.sheet.against", against))
                .foregroundStyle(against > 0 ? Trace.Colors.red : Trace.Colors.ink2)
            Text(alibi ? "↓ \(favour) " + L10n.t("alibi.tallyConfirms") : L10n.f("carnet.sheet.favour", favour))
                .foregroundStyle(favour > 0 ? Trace.Colors.green : Trace.Colors.ink2)
        }
        .font(Trace.Fonts.data)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(LinkTally.spoken(against: against, favour: favour)))
    }
}

/// SuspectSheet (§3): a `paperCard` sheet on the ruled page — the identity photo 78 × 98 (initials
/// when missing), the name in Newsreader 19/600, the age in Mono, the relation, « ALIBI » and what
/// they declared (their statement — never the case's hidden alibi), « ↑ n contre » / « ↓ n pour »
/// from the player's own readings, and the player's ticked notes in Caveat (also spoken).
struct SuspectSheet: View {
    let suspect: Suspect
    let contact: Contact?
    var against = 0
    var favour = 0
    /// The player's own ticks (never checked by the game).
    var marks: [SuspectMark] = []

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            IDPhoto(contact: contact, width: 78, height: 98, stapled: true)
                .padding(.top, 4)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(name)
                        .font(Trace.Fonts.notebookName)
                        .foregroundStyle(Trace.Colors.ink)
                        .fixedSize(horizontal: false, vertical: true)
                    if let age = suspect.age {
                        Text(L10n.f("suspect.ageShort", age))
                            .font(Trace.Fonts.fieldValue)
                            .foregroundStyle(Trace.Colors.ink2)
                            .lineLimit(1)
                    }
                }
                Text(suspect.role)
                    .font(Trace.Fonts.callout)
                    .foregroundStyle(Trace.Colors.ink2)
                    .fixedSize(horizontal: false, vertical: true)
                Text(L10n.t("suspect.alibiLabel"))
                    .fieldLabel(Trace.Colors.ink2)
                    .padding(.top, 8)
                Text(suspect.statement)
                    .font(Trace.Fonts.callout)
                    .foregroundStyle(Trace.Colors.ink)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
                StanceTally(against: against, favour: favour)
                    .padding(.top, 8)
                if !marks.isEmpty {
                    Handwritten(text: marksText, size: 19)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, 2)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            Image(systemName: "chevron.right")
                .font(Trace.Fonts.caption.weight(.semibold))
                .foregroundStyle(Trace.Colors.ink2)
                .padding(.top, 6)
                .accessibilityHidden(true)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(PaperCardBackground())
        .contentShape(Rectangle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(spoken))
    }

    private var name: String { contact?.name ?? suspect.contact }

    private var marksText: String {
        marks.map { L10n.t("mark.\($0.rawValue)") }.joined(separator: " · ")
    }

    private var spoken: String {
        [name, suspect.age.map { L10n.f("suspect.age", $0) }, suspect.role,
         L10n.f("suspect.alibiLine", suspect.statement), LinkTally.spoken(against: against, favour: favour),
         marks.isEmpty ? nil : L10n.f("carnet.a11y.marks", marksText)]
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
                Text(L10n.t("suspect.noPiece")).foregroundStyle(Trace.Colors.ink2)
            } else {
                HStack(spacing: 10) {
                    Text(verbatim: "↑ \(against)").foregroundStyle(against > 0 ? Trace.Colors.red : Trace.Colors.ink2)
                    Text(verbatim: "↓ \(favour)").foregroundStyle(favour > 0 ? Trace.Colors.green : Trace.Colors.ink2)
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

    /// The colour of a reading on paper (with its glyph and word, never alone).
    static func color(_ stance: NotebookEntry.Stance?) -> Color {
        switch stance {
        case .incriminates: Trace.Colors.red
        case .clears: Trace.Colors.green
        case nil: Trace.Colors.ink2
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

// MARK: - Connections: the red thread (§3 RedThread, screen 08)

/// Words, symbols and colours of the links between two elements. Always the word; the colour only
/// repeats it (on paper: contredit = red, confirme = green, the others = ink2).
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
        case .contradicts: Trace.Colors.red
        case .confirms: Trace.Colors.green
        case .samePlace, .sameTime, .implicates: Trace.Colors.ink2
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

    /// VoiceOver: « Fil 1 : Pièce 03, contredit, Pièce 02 ».
    static func spoken(_ connection: Connection, number: Int, in game: Investigation) -> String {
        var parts: [String] = []
        for (i, node) in connection.nodes.enumerated() {
            if i > 0, i - 1 < connection.verbs.count { parts.append(verb(connection.verbs[i - 1]).lowercased()) }
            parts.append(tag(node, in: game) + (node.isPerson ? "" : " " + text(node, in: game)))
        }
        return L10n.f("connection.threadShort", number) + " : " + parts.joined(separator: ", ")
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

/// RedThread (§3): one chain of the player's connections on the `kraftDark` board. A paper label
/// « FIL n · verbe »; the elements are `paperCard` nodes with a red pin on top, offset sideways
/// 0 / 40 pt in turn; between two of them a red 2 × 44 pt thread with its verb written in Caveat 20
/// ivory (and spoken). It never says whether a link is right.
struct RedThread: View {
    let connection: Connection
    let number: Int
    let game: Investigation
    /// The link (index in `verbs`) to draw now: pin set, thread unrolled, verb written.
    var drawLink: Int? = nil
    var onOpenPiece: ((ItemRef) -> Void)? = nil
    var onAdd: (() -> Void)? = nil
    var onDelete: (() -> Void)? = nil

    /// Where the thread runs, from the chain's leading edge.
    static let threadX: CGFloat = 64
    /// The sideways offset of every other node.
    static let stagger: CGFloat = 40

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
                .padding(.bottom, 16)
            ForEach(Array(connection.nodes.enumerated()), id: \.offset) { i, node in
                if i > 0, i - 1 < connection.verbs.count {
                    ThreadSegment(verb: connection.verbs[i - 1], x: Self.threadX, animated: drawLink == i - 1)
                }
                nodeView(node, index: i, animatedPin: drawLink.map { $0 + 1 == i } ?? false)
            }
            if let onAdd { addButton(onAdd) }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .contextMenu {
            if let onDelete {
                Button(role: .destructive, action: onDelete) {
                    Label(L10n.t("connection.deleteThread"), systemImage: "trash")
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(Text(ConnectionFormat.spoken(connection, number: number, in: game)))
    }

    /// « FIL 1 · CONTREDIT » on a paper label; the options (delete) on the right.
    private var header: some View {
        HStack(alignment: .center, spacing: 8) {
            Text(L10n.f("connection.threadTitle", number, connection.verbs.first.map { ConnectionFormat.verb($0) } ?? ""))
                .fieldLabel(Trace.Colors.ink)
                .lineLimit(2)
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(PaperCardBackground(color: Trace.Colors.label, shadow: Trace.Shadow.print))
                .accessibilityAddTraits(.isHeader)
            Spacer(minLength: 8)
            if let onDelete {
                Menu {
                    Button(role: .destructive, action: onDelete) {
                        Label(L10n.t("connection.deleteThread"), systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(Trace.Fonts.headline)
                        .foregroundStyle(Trace.Colors.ink)
                        .frame(width: 34, height: 34)
                        .background(Circle().fill(Trace.Colors.paperCard))
                        .frame(width: Trace.Height.hit, height: Trace.Height.hit)
                        .contentShape(Rectangle())
                }
                .accessibilityLabel(Text(L10n.t("connection.threadOptions")))
                .accessibilityIdentifier("notebook.connection.menu.\(connection.id)")
            }
        }
    }

    @ViewBuilder
    private func nodeView(_ node: Connection.Node, index: Int, animatedPin: Bool) -> some View {
        let lead: CGFloat = index.isMultiple(of: 2) ? 0 : Self.stagger
        let card = HStack(alignment: .center, spacing: 12) {
            if case .person(let id) = node, let suspect = game.index.suspect(id) {
                IDPhoto(contact: game.contact(suspect.contact), width: 32, height: 40)
                    .accessibilityHidden(true)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(ConnectionFormat.label(node, in: game))
                    .font(Trace.Fonts.data)
                    .foregroundStyle(Trace.Colors.ink2)
                Text(ConnectionFormat.text(node, in: game))
                    .font(Trace.Fonts.callout)
                    .foregroundStyle(Trace.Colors.ink)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            if node.pieceRef != nil, onOpenPiece != nil {
                Image(systemName: "chevron.right")
                    .font(Trace.Fonts.caption.weight(.semibold))
                    .foregroundStyle(Trace.Colors.ink2)
                    .accessibilityHidden(true)
            }
        }
        .padding(.horizontal, 12)
        .padding(.top, 14)
        .padding(.bottom, 12)
        .frame(maxWidth: .infinity, minHeight: Trace.Height.hit, alignment: .leading)
        .background(PaperCardBackground())
        .overlay(alignment: .topLeading) {
            ThreadPin(animated: animatedPin)
                .offset(x: Self.threadX - lead - 7, y: -7)
        }
        .contentShape(Rectangle())
        Group {
            if let ref = node.pieceRef, let onOpenPiece {
                Button { onOpenPiece(ref) } label: { card }
                    .buttonStyle(PressableStyle())
                    .accessibilityElement(children: .combine)
            } else {
                card.accessibilityElement(children: .combine)
            }
        }
        .padding(.leading, lead)
        .padding(.trailing, Self.stagger - lead)
    }

    /// « + Ajouter un élément »: a loose end of thread, then a paper tag.
    private func addButton(_ action: @escaping () -> Void) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Line()
                .stroke(Trace.Colors.red, style: StrokeStyle(lineWidth: 2, dash: [4, 4]))
                .frame(width: 2, height: 20)
                .padding(.leading, Self.threadX - 1)
                .accessibilityHidden(true)
            Button(action: action) {
                Label(L10n.t("connection.addElement"), systemImage: "plus")
                    .font(Trace.Fonts.callout.weight(.semibold))
                    .foregroundStyle(Trace.Colors.ink)
                    .padding(.horizontal, 14)
                    .frame(minHeight: 40)
                    .background(PaperCardBackground(shadow: Trace.Shadow.print))
                    .frame(minHeight: Trace.Height.hit)
                    .contentShape(Rectangle())
            }
            .buttonStyle(PressableStyle())
            .padding(.leading, Self.threadX - 28)
            .accessibilityIdentifier("notebook.connection.add.\(connection.id)")
        }
    }
}

/// A red pin on a node (14 pt). A new one is set: scale 1.2 → 1 in 120 ms (a fade with reduced
/// motion), once the builder sheet has gone down.
struct ThreadPin: View {
    @State private var set: Bool
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    @AppStorage(Preferences.reduceMotionKey) private var appReduceMotion = false

    init(animated: Bool = false) {
        _set = State(initialValue: !animated)
    }

    var body: some View {
        let reduced = systemReduceMotion || appReduceMotion
        Pin(color: Trace.Colors.red, size: 14)
            .scaleEffect(set || reduced ? 1 : 1.2)
            .opacity(set ? 1 : 0)
            .task {
                guard !set else { return }
                try? await Task.sleep(for: .milliseconds(300))
                withAnimation(reduced ? .easeInOut(duration: 0.2) : .easeOut(duration: 0.12)) { set = true }
            }
    }
}

/// The red thread between two nodes (2 × 44 pt) and its verb in Caveat 20 ivory. A new one unrolls
/// top → bottom (300 ms) after its pin, then its word is written left → right (400 ms); with
/// reduced motion both fade in (200 ms), no unrolling.
struct ThreadSegment: View {
    let verb: Connection.Verb
    var x: CGFloat = RedThread.threadX
    @State private var unrolled: CGFloat
    @State private var written: CGFloat
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    @AppStorage(Preferences.reduceMotionKey) private var appReduceMotion = false

    init(verb: Connection.Verb, x: CGFloat = RedThread.threadX, animated: Bool = false) {
        self.verb = verb
        self.x = x
        _unrolled = State(initialValue: animated ? 0 : 1)
        _written = State(initialValue: animated ? 0 : 1)
    }

    private var reduced: Bool { systemReduceMotion || appReduceMotion }

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Rectangle()
                .fill(Trace.Colors.red)
                .frame(width: 2)
                .frame(minHeight: 44, maxHeight: .infinity)
                .scaleEffect(x: 1, y: reduced ? 1 : unrolled, anchor: .top)
                .opacity(reduced ? unrolled : 1)
                .accessibilityHidden(true)
            Text(ConnectionFormat.verb(verb).lowercased())
                .font(Trace.Fonts.threadNote)
                .foregroundStyle(Trace.Colors.ivory)
                .shadow(color: .black.opacity(0.35), radius: 1, y: 1)
                .fixedSize(horizontal: false, vertical: true)
                .mask(alignment: .leading) {
                    Rectangle().scaleEffect(x: reduced ? 1 : written, y: 1, anchor: .leading)
                }
                .opacity(reduced ? written : 1)
                .padding(.vertical, 4)
        }
        .padding(.leading, x - 1)
        .fixedSize(horizontal: false, vertical: true)
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(ConnectionFormat.verb(verb)))
        .task {
            guard unrolled < 1 || written < 1 else { return }
            // After the builder sheet (300 ms) and the pin (120 ms).
            try? await Task.sleep(for: .milliseconds(420))
            if reduced {
                withAnimation(.easeInOut(duration: 0.2)) {
                    unrolled = 1
                    written = 1
                }
                return
            }
            withAnimation(.easeInOut(duration: 0.3)) { unrolled = 1 }
            try? await Task.sleep(for: .milliseconds(300))
            withAnimation(.easeOut(duration: 0.4)) { written = 1 }
        }
    }
}

// MARK: - Chronology (the ruled page)

/// Carnet › Chrono: the dated pieces of the file in time order, written on a ruled page — the time
/// in Plex Mono 14 in the left margin (the page's red rule at `margin`), the text in Plex Sans 15
/// ink, « PIÈCE nn · source » in ink2. A piece the PLAYER put in a « contredit » thread: a red dot on
/// the margin and « ≠ contredit PIÈCE nn » in red. Declarations are events too (« Déclaration »);
/// without a time, they come first. At accessibility sizes the time sits above the text (no margin).
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
    /// The page's red margin rule, from its leading edge; nil: no margin (accessibility sizes).
    var margin: CGFloat? = 56

    private enum Event {
        case piece(NotebookEntry, ItemDescriber.Item, Moment)
        case declaration(Declaration, Moment)

        var at: Moment {
            switch self {
            case .piece(_, _, let at), .declaration(_, let at): at
            }
        }
    }

    /// Where the text column starts.
    private var textX: CGFloat { (margin ?? 4) + 12 }

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
                EmptyPage(title: L10n.t("chrono.emptyTitle"), tip: L10n.t("chrono.emptyBody"), onPaper: true)
                    .padding(.leading, textX)
                    .padding(.trailing, 16)
                    .accessibilityIdentifier("notebook.chrono.empty")
            }
            if !untimed.isEmpty {
                SectionHeader(title: L10n.t("chrono.statements"), color: Trace.Colors.ink2)
                    .padding(.leading, textX)
                    .padding(.top, 8)
                    .padding(.bottom, -4)
                ForEach(untimed) { declaration in
                    row(time: nil, text: declaration.who + " · " + declaration.text, meta: L10n.t("chrono.statement"), contradiction: false)
                }
                Color.clear.frame(height: 8).accessibilityHidden(true)
            }
            ForEach(Array(events.enumerated()), id: \.offset) { offset, event in
                let previous = offset > 0 ? events[offset - 1].at : nil
                if previous.map({ !$0.isSameDay(as: event.at) }) ?? true {
                    Text(PhoneFormat.longDayCapitalized(event.at))
                        .font(Trace.Fonts.caption.weight(.semibold))
                        .foregroundStyle(Trace.Colors.ink2)
                        .padding(.leading, textX)
                        .padding(.trailing, 16)
                        .padding(.top, offset == 0 && untimed.isEmpty ? 8 : 16)
                        .padding(.bottom, 2)
                        .accessibilityAddTraits(.isHeader)
                }
                eventRow(event)
            }
        }
        .padding(.bottom, 16)
    }

    @ViewBuilder
    private func eventRow(_ event: Event) -> some View {
        switch event {
        case .piece(let entry, let item, let at):
            let number = game.pieceNumber(of: entry.ref) ?? 0
            let against = game.contradicted(by: entry.ref)
            let meta = against.isEmpty
                ? PieceFormat.title(number) + " · " + PieceFormat.origin(entry.ref, in: game)
                : against.map { L10n.f("chrono.contradicts", ConnectionFormat.tag($0, in: game)) }.joined(separator: " · ")
            let line = row(time: at, text: item.label, meta: meta, contradiction: !against.isEmpty)
            if let onOpen {
                Button { onOpen(entry.ref) } label: { line }
                    .buttonStyle(PressableStyle())
                    .accessibilityIdentifier("notebook.row")
            } else {
                line.accessibilityIdentifier("notebook.row")
            }
        case .declaration(let declaration, let at):
            row(time: at, text: declaration.who + " · " + declaration.text, meta: L10n.t("chrono.statement"), contradiction: false)
        }
    }

    private func row(time: Moment?, text: String, meta: String, contradiction: Bool) -> some View {
        let clock = time.map { PhoneFormat.time($0) } ?? ""
        return HStack(alignment: .firstTextBaseline, spacing: 0) {
            if let margin {
                Text(clock)
                    .font(Trace.Fonts.notebookTime)
                    .monospacedDigit()
                    .foregroundStyle(Trace.Colors.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                    .frame(width: max(0, margin - 8), alignment: .trailing)
                    .padding(.trailing, 8)
            }
            VStack(alignment: .leading, spacing: 3) {
                if margin == nil, !clock.isEmpty {
                    Text(clock)
                        .font(Trace.Fonts.notebookTime)
                        .monospacedDigit()
                        .foregroundStyle(Trace.Colors.ink)
                }
                Text(text)
                    .font(Trace.Fonts.notebookText)
                    .foregroundStyle(Trace.Colors.ink)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    if contradiction && margin == nil {
                        Circle().fill(Trace.Colors.red).frame(width: 8, height: 8).accessibilityHidden(true)
                    }
                    Text(meta)
                        .font(contradiction ? Trace.Fonts.caption.weight(.semibold) : Trace.Fonts.caption)
                        .foregroundStyle(contradiction ? Trace.Colors.red : Trace.Colors.ink2)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(.leading, margin == nil ? 16 : 12)
            .padding(.trailing, 16)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 8)
        .overlay(alignment: .topLeading) {
            if contradiction, let margin {
                // On the margin rule, level with the first line.
                Circle()
                    .fill(Trace.Colors.red)
                    .frame(width: 9, height: 9)
                    .offset(x: margin - 4, y: 13)
                    .accessibilityHidden(true)
            }
        }
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }
}

// MARK: - NotebookDividers (§3)

/// NotebookDividers (§3): the Carnet's four dividers, in the `tabs` colours; the active one is
/// paper, 44 pt tall and continuous with the page below it; the others 38 pt, 6 pt lower, shaded
/// at the foot (behind the page). Label Plex Sans 13/600 ink + counter Plex Mono 10. Changing: the
/// new one rises (250 ms spring; a fade with reduced motion). Each divider is a 44 pt target.
struct NotebookDividers<Value: Hashable>: View {
    struct Item {
        let value: Value
        let label: String
        var count: Int? = nil
        let identifier: String
    }

    let items: [Item]
    @Binding var selection: Value
    @Environment(\.dynamicTypeSize) private var typeSize
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    @AppStorage(Preferences.reduceMotionKey) private var appReduceMotion = false

    var body: some View {
        HStack(alignment: .bottom, spacing: 4) {
            ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                divider(item, index: index)
            }
        }
    }

    private func divider(_ item: Item, index: Int) -> some View {
        let active = item.value == selection
        let shape = UnevenRoundedRectangle(topLeadingRadius: Trace.Radius.folderTab, bottomLeadingRadius: 0,
                                           bottomTrailingRadius: 0, topTrailingRadius: Trace.Radius.folderTab)
        let colors = Trace.Colors.tabs
        return Button {
            guard !active else { return }
            withAnimation(systemReduceMotion || appReduceMotion ? .easeInOut(duration: 0.2) : Trace.Motion.tab) {
                selection = item.value
            }
            Haptics.selection()
        } label: {
            label(item, active: active)
                .padding(.horizontal, 6)
                .padding(.vertical, 6)
                .frame(maxWidth: .infinity, minHeight: active ? 44 : 38)
                .background {
                    shape
                        .fill(active ? Trace.Colors.paper : colors[index % colors.count])
                        .overlay(alignment: .bottom) {
                            if !active {
                                LinearGradient(colors: [.clear, .black.opacity(0.16)], startPoint: .top, endPoint: .bottom)
                                    .frame(height: 8)
                            }
                        }
                }
                .frame(minHeight: Trace.Height.hit, alignment: .bottom)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(item.label))
        .accessibilityValue(Text(item.count.map { "\($0)" } ?? ""))
        .accessibilityAddTraits(active ? [.isButton, .isSelected] : .isButton)
        .accessibilityIdentifier(item.identifier)
    }

    private func label(_ item: Item, active: Bool) -> some View {
        let layout = typeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(spacing: 2))
            : AnyLayout(HStackLayout(alignment: .firstTextBaseline, spacing: 4))
        return layout {
            Text(item.label)
                .font(Trace.Fonts.notebookDivider)
                .foregroundStyle(Trace.Colors.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            if let count = item.count {
                Text(verbatim: "\(count)")
                    .font(Trace.Fonts.notebookCount)
                    .monospacedDigit()
                    .foregroundStyle(active ? Trace.Colors.ink2 : Trace.Colors.ink)
                    .lineLimit(1)
            }
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
