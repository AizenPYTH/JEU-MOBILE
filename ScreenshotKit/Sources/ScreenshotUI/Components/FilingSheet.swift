#if os(iOS)
import SwiftUI
import CaseEngine

/// « VERSER AU DOSSIER » (final handoff §F-06): the paper sheet opened by a long press on an
/// element of the phone. What it is, whose, when; a short preview; one full button and « Annuler ».
/// An element already in the file says so and leads to the Carnet instead. Any element can be
/// filed, even a trivial one: the player judges.
struct FilingSheet: View {
    let session: GameSession
    let ref: ItemRef
    /// Its piece number when the sheet opened (nil = not in the file yet). Fixed for the sheet's
    /// life, so that it does not change while it slides away after « VERSER AU DOSSIER ».
    let filedNumber: Int?
    let onViewInCarnet: () -> Void

    var body: some View {
        let game = session.game
        VStack(alignment: .leading, spacing: 0) {
            Capsule()
                .fill(Trace.Colors.inkFaint.opacity(0.5))
                .frame(width: 36, height: 4)
                .frame(maxWidth: .infinity)
                .padding(.top, 10)
                .padding(.bottom, 14)
                .accessibilityHidden(true)

            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    Text(FilingText.kicker(ref, in: game))
                        .font(Trace.Fonts.kicker)
                        .tracking(1.6)
                        .foregroundStyle(Trace.Colors.inkSoft)
                        .fixedSize(horizontal: false, vertical: true)
                    FilingPreview(ref: ref, game: game)
                    if let filedNumber {
                        Text(L10n.f("filing.alreadyFiled", PieceFormat.title(filedNumber)))
                            .font(Trace.Fonts.monoStrong)
                            .tracking(1)
                            .foregroundStyle(Trace.Colors.stamp)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityElement(children: .combine)
            }
            .scrollBounceBehavior(.basedOnSize)

            VStack(spacing: 2) {
                if filedNumber != nil {
                    Button(L10n.t("filing.viewInCarnet"), action: onViewInCarnet)
                        .buttonStyle(CTAButtonStyle(kind: .primary, onPaper: true))
                        .accessibilityIdentifier("filing.viewInCarnet")
                } else {
                    Button(L10n.t("pin.add")) { session.fileCandidate() }
                        .buttonStyle(CTAButtonStyle(kind: .primary, onPaper: true))
                        .accessibilityIdentifier("filing.confirm")
                }
                Button(L10n.t("filing.cancel")) { session.cancelFiling() }
                    .buttonStyle(TextLinkStyle(onPaper: true))
                    .frame(maxWidth: .infinity)
                    .accessibilityIdentifier("filing.cancel")
            }
            .padding(.top, 12)
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 4)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Trace.Colors.paper.overlay(PaperGrain()).ignoresSafeArea())
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("filing.sheet")
    }
}

/// The words of the filing sheet and of the flying copy.
enum FilingText {
    /// `{TYPE} · {SOURCE} · {DATE HEURE}`: « MESSAGE · EMMA ROUSSEL · 12 SEPT. 22:30 ». The source is
    /// the person the element comes from, or its app.
    static func kicker(_ ref: ItemRef, in game: Investigation) -> String {
        let item = ItemDescriber.describe(ref, in: game)
        var parts = [PieceFormat.kind(ref, in: game), item.person.map { game.name(of: $0) } ?? item.app.title]
        if let at = item.at { parts.append(PhoneFormat.shortDay(at) + " " + PhoneFormat.time(at)) }
        return parts.joined(separator: " · ").uppercased()
    }
}

/// A few lines of the element, in Newsreader 16: the message, the photo and its caption, the call…
struct FilingPreview: View {
    let ref: ItemRef
    let game: Investigation

    var body: some View {
        let index = game.index
        switch ref.kind {
        case .message:
            if let message = index.message(ref.id) {
                HStack(alignment: .top, spacing: 12) {
                    if let photoID = message.photo, let photo = index.photo(photoID) {
                        thumbnail(photo)
                    }
                    if let text = message.text {
                        quote(text)
                    }
                }
            }
        case .draft:
            if let draft = game.device.conversations.compactMap(\.draft).first(where: { $0.id == ref.id }) {
                quote(draft.text)
            }
        case .photo, .photoInfo:
            if let photo = index.photo(ref.id) {
                HStack(alignment: .top, spacing: 12) {
                    thumbnail(photo)
                    VStack(alignment: .leading, spacing: 4) {
                        prose(photo.caption, lines: 3)
                        if ref.kind == .photoInfo, let place = photo.place {
                            detail(place)
                        }
                    }
                }
            }
        case .note:
            if let note = index.note(ref.id) {
                VStack(alignment: .leading, spacing: 4) {
                    prose(note.title, lines: 1)
                    quote(note.body, lines: 3)
                }
            }
        case .mail:
            if let mail = index.mail(ref.id) {
                VStack(alignment: .leading, spacing: 4) {
                    prose("\(mail.fromName) — \(mail.subject)", lines: 2)
                    detail(mail.body, lines: 2)
                }
            }
        default:
            let item = ItemDescriber.describe(ref, in: game)
            VStack(alignment: .leading, spacing: 4) {
                prose(item.label, lines: 3)
                if let place = item.place {
                    detail(place)
                }
            }
        }
    }

    private func prose(_ text: String, lines: Int) -> some View {
        Text(text)
            .font(Trace.Fonts.prose)
            .foregroundStyle(Trace.Colors.ink)
            .lineLimit(lines)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func quote(_ text: String, lines: Int = 4) -> some View {
        prose("« \(text) »", lines: lines)
    }

    private func detail(_ text: String, lines: Int = 1) -> some View {
        Text(text)
            .font(Trace.Fonts.monoSmall)
            .foregroundStyle(Trace.Colors.inkSoft)
            .lineLimit(lines)
    }

    private func thumbnail(_ photo: Photo) -> some View {
        PhotoPrint(border: 3) {
            GeneratedPhoto(photo: photo)
                .frame(width: 78, height: 78)
        }
        .accessibilityLabel(Text(photo.caption))
    }
}

/// The paper copy of a piece just filed (§F-07): 210 pt, −4°, it flies into the dossier bar.
struct FiledPaperCopy: View {
    let piece: GameSession.FiledPiece
    let game: Investigation

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(PieceFormat.title(piece.number) + " · " + PieceFormat.kind(piece.ref, in: game))
                .font(Trace.Fonts.kicker)
                .tracking(1.4)
                .foregroundStyle(Trace.Colors.stamp)
                .lineLimit(1)
            Text(ItemDescriber.describe(piece.ref, in: game).label)
                .font(Trace.Fonts.proseSmall)
                .foregroundStyle(Trace.Colors.ink)
                .lineLimit(2)
        }
        .padding(12)
        .frame(width: 210, alignment: .leading)
        .paper(radius: 2, lifted: true)
        .rotationEffect(.degrees(-4))
        .accessibilityHidden(true)
    }
}
#endif
