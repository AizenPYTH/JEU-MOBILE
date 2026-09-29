#if os(iOS)
import SwiftUI
import UIKit
import CaseEngine

/// EvidenceSheet (handoff UX V3 §5, §6-05): « C'est enregistré, je continue. » A `surface` sheet
/// (radius 20) over the phone, above the investigation bar: « PIÈCE 03 » + « ✓ Versée au dossier »,
/// a preview of the element on `surface2`, the one-time help line, then [Relier] (→ the Carnet, to
/// connect this piece) and [Continuer]. It closes by itself after 2.5 s (not under VoiceOver). An
/// element already in the file says so and leads to its piece instead.
///
/// The veil (35 % black on the phone) and the placement are the shell's (`InvestigationView`).
struct FilingSheet: View {
    let session: GameSession
    let receipt: GameSession.FilingReceipt
    /// [Relier]: the Carnet, in « relier » mode for this piece.
    let onConnect: () -> Void
    /// « Voir la pièce » (an element already filed): the Carnet on this piece.
    let onViewInCarnet: () -> Void

    var body: some View {
        let game = session.game
        VStack(alignment: .leading, spacing: 0) {
            ViewThatFits(in: .vertical) {
                details(game)
                ScrollView { details(game) }
                    .scrollBounceBehavior(.basedOnSize)
            }
            HStack(spacing: 10) {
                if receipt.isNew {
                    Button(L10n.t("evidence.connect"), action: onConnect)
                        .buttonStyle(CTAButtonStyle(kind: .outline, height: Trace.Height.button - 6))
                        .accessibilityIdentifier("filing.connect")
                } else {
                    Button(L10n.t("evidence.viewPiece"), action: onViewInCarnet)
                        .buttonStyle(CTAButtonStyle(kind: .outline, height: Trace.Height.button - 6))
                        .accessibilityIdentifier("filing.viewInCarnet")
                }
                Button(L10n.t("evidence.continue")) { session.fileCandidate() }
                    .buttonStyle(CTAButtonStyle(kind: .primary, height: Trace.Height.button - 6))
                    .accessibilityIdentifier("filing.confirm")
            }
            .padding(.top, 16)
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            UnevenRoundedRectangle(topLeadingRadius: Trace.Radius.sheet, topTrailingRadius: Trace.Radius.sheet,
                                   style: .continuous)
                .fill(Trace.Colors.surface)
                .overlay(UnevenRoundedRectangle(topLeadingRadius: Trace.Radius.sheet, topTrailingRadius: Trace.Radius.sheet,
                                                style: .continuous)
                    .stroke(Trace.Colors.line, lineWidth: 1))
        )
        .environment(\.colorScheme, .dark)
        .accessibilityElement(children: .contain)
        .accessibilityAddTraits(.isModal)
        .accessibilityIdentifier("filing.sheet")
        .task(id: receipt.id) {
            // « Se referme seule après 2,5 s » — not while VoiceOver reads it, not in the UI tests
            // (they tap « Continuer » themselves).
            guard receipt.isNew, !UIAccessibility.isVoiceOverRunning, !FilingSheet.uiTesting else { return }
            try? await Task.sleep(for: .seconds(2.5))
            guard !Task.isCancelled, session.receipt?.id == receipt.id else { return }
            session.fileCandidate()
        }
    }

    private func details(_ game: Investigation) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center, spacing: 10) {
                if let number = receipt.number {
                    Text(PieceFormat.title(number))
                        .font(Trace.Fonts.data)
                        .foregroundStyle(Trace.Colors.benText)
                }
                Spacer(minLength: 8)
                StatusBadge(text: L10n.t(receipt.isNew ? "evidence.filed" : "evidence.alreadyFiled"),
                            color: Trace.Colors.successText, symbol: "✓")
            }
            Text(FilingText.kicker(receipt.ref, in: game))
                .font(Trace.Fonts.caption)
                .foregroundStyle(Trace.Colors.text2)
                .fixedSize(horizontal: false, vertical: true)
            FilingPreview(ref: receipt.ref, game: game)
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(RoundedRectangle(cornerRadius: Trace.Radius.node, style: .continuous).fill(Trace.Colors.surface2))
            ForEach(receipt.help, id: \.self) { line in
                Text(line)
                    .font(Trace.Fonts.callout)
                    .foregroundStyle(Trace.Colors.text)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    /// The UI tests launch with `-UITestReset`: the sheet waits for their tap.
    static let uiTesting = ProcessInfo.processInfo.arguments.contains("-UITestReset")
}

/// The words of the EvidenceSheet and of the flying copy.
enum FilingText {
    /// `{Type} · {source} · {date heure}`: « Message · Emma Roussel · 12 sept. 22:30 ». The source
    /// is the person the element comes from, or its app.
    static func kicker(_ ref: ItemRef, in game: Investigation) -> String {
        let item = ItemDescriber.describe(ref, in: game)
        var parts = [sentenceCase(PieceFormat.kind(ref, in: game)), item.person.map { game.name(of: $0) } ?? item.app.title]
        if let at = item.at { parts.append(PhoneFormat.shortDay(at) + " " + PhoneFormat.time(at)) }
        return parts.joined(separator: " · ")
    }

    /// « ANALYSE PHOTO » → « Analyse photo » (capitals are for section headers only).
    static func sentenceCase(_ text: String) -> String {
        let lower = text.lowercased()
        return lower.prefix(1).uppercased() + lower.dropFirst()
    }
}

/// A few lines of the element: the message, the photo and its caption, the call…
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
            .font(Trace.Fonts.callout)
            .foregroundStyle(Trace.Colors.text)
            .lineLimit(lines)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func quote(_ text: String, lines: Int = 4) -> some View {
        Text("« \(text) »")
            .font(Trace.Fonts.quote)
            .foregroundStyle(Trace.Colors.text)
            .lineLimit(lines)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func detail(_ text: String, lines: Int = 1) -> some View {
        Text(text)
            .font(Trace.Fonts.caption)
            .foregroundStyle(Trace.Colors.text2)
            .lineLimit(lines)
    }

    private func thumbnail(_ photo: Photo) -> some View {
        GeneratedPhoto(photo: photo)
            .frame(width: 64, height: 64)
            .clipShape(RoundedRectangle(cornerRadius: Trace.Radius.segment, style: .continuous))
            .accessibilityLabel(Text(photo.caption))
    }
}

/// The copy of a piece just filed (§6-05): it flies from the sheet to the Carnet button (scale
/// 1 → 0.2, opacity → 0, 450 ms spring).
struct FiledPaperCopy: View {
    let piece: GameSession.FiledPiece
    let game: Investigation

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(PieceFormat.title(piece.number))
                .font(Trace.Fonts.data)
                .foregroundStyle(Trace.Colors.benText)
                .lineLimit(1)
            Text(ItemDescriber.describe(piece.ref, in: game).label)
                .font(Trace.Fonts.caption)
                .foregroundStyle(Trace.Colors.text)
                .lineLimit(2)
        }
        .padding(12)
        .frame(width: 210, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: Trace.Radius.node, style: .continuous).fill(Trace.Colors.surface2))
        .accessibilityHidden(true)
    }
}
#endif
