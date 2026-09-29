#if os(iOS)
import SwiftUI
import UIKit
import CaseEngine

/// EvidenceSlip (handoff V4 §3, screen 05, on the UX V3 §6-05): « C'est enregistré, je continue. »
/// A paperCard slip laid over the phone (the shell draws the 55 % desk veil), rotated −1.2°, held
/// by a piece of tape: « PIÈCE 03 » (Plex Mono 15/700) with « TYPE · date · heure », the element on
/// white behind a thin rule, the code stamp VERSÉE, the one-time help line, then [Relier] (→ the
/// Carnet, to connect this piece) and [Continuer]. It falls in (scale 1.06 → 1, rotation −3 →
/// −1.2°, 300 ms), then the stamp falls (1.35 → 1, 180 ms). It closes by itself after 2.5 s (not
/// under VoiceOver, not in the UI tests). An element already in the file says so and leads to its
/// piece instead. Reduced motion: fades, the stamp just appears.
///
/// The shell places it, draws the veil, and makes « Continuer » glide the slip to « Carnet »: it
/// draws a second, `departing` copy (at rest, not interactive, hidden from VoiceOver) that flies.
struct EvidenceSlip: View {
    let session: GameSession
    let receipt: GameSession.FilingReceipt
    /// [Relier]: the Carnet, in « relier » mode for this piece.
    var onConnect: () -> Void = {}
    /// « Voir la pièce » (an element already filed): the Carnet on this piece.
    var onViewInCarnet: () -> Void = {}
    /// [Continuer], the veil, or the 2.5 s auto-close.
    var onContinue: () -> Void = {}
    /// The copy that glides to « Carnet »: drawn at rest, without its fall nor its stamp's.
    var departing = false
    /// 0: in the air · 1: laid on the phone.
    @State private var landed: Bool
    /// The stamp: 0 above the slip · 1 hitting it (0.98) · 2 settled.
    @State private var stampPhase: Int
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    @AppStorage(Preferences.reduceMotionKey) private var appReduceMotion = false

    init(session: GameSession, receipt: GameSession.FilingReceipt, onConnect: @escaping () -> Void = {},
         onViewInCarnet: @escaping () -> Void = {}, onContinue: @escaping () -> Void = {}, departing: Bool = false) {
        self.session = session
        self.receipt = receipt
        self.onConnect = onConnect
        self.onViewInCarnet = onViewInCarnet
        self.onContinue = onContinue
        self.departing = departing
        // An element already in the file, or the gliding copy: the slip and its stamp are at rest.
        _landed = State(initialValue: departing)
        _stampPhase = State(initialValue: departing || !receipt.isNew ? 2 : 0)
    }

    private var reduceMotion: Bool { systemReduceMotion || appReduceMotion }

    var body: some View {
        let game = session.game
        VStack(alignment: .leading, spacing: 0) {
            ViewThatFits(in: .vertical) {
                details(game)
                ScrollView { details(game) }
                    .scrollBounceBehavior(.basedOnSize)
            }
            actions
                .padding(.top, 18)
        }
        .padding(.horizontal, 20)
        .padding(.top, 24)
        .padding(.bottom, 20)
        .frame(maxWidth: evidenceSlipWidth, alignment: .leading)
        .background(
            Rectangle()
                .fill(Trace.Colors.paperCard)
                .shadow(color: Trace.Shadow.slip.color, radius: 12, y: 6)
        )
        .overlay(alignment: .top) { Tape(width: 56).offset(y: -8) }
        .scaleEffect(landed || reduceMotion ? 1 : evidenceSlipFallScale)
        .modifier(TiltModifier(degrees: landed || reduceMotion ? evidenceSlipAngle : evidenceSlipFallAngle))
        .opacity(landed ? 1 : 0)
        .accessibilityElement(children: .contain)
        .accessibilityAddTraits(.isModal)
        .accessibilityIdentifier("filing.sheet")
        .onAppear { fall() }
        .task(id: receipt.id) {
            // « Se referme seule après 2,5 s » — not while VoiceOver reads it, not in the UI tests
            // (they tap « Continuer » themselves), never the gliding copy.
            guard !departing, receipt.isNew, !UIAccessibility.isVoiceOverRunning, !EvidenceSlip.uiTesting else { return }
            try? await Task.sleep(for: .seconds(2.5))
            guard !Task.isCancelled, session.receipt?.id == receipt.id else { return }
            onContinue()
        }
    }

    // MARK: Content

    private func details(_ game: Investigation) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    if let number = receipt.number {
                        Text(PieceFormat.title(number))
                            .font(Trace.Fonts.pieceTitle)
                            .tracking(1.2)
                            .foregroundStyle(Trace.Colors.ink)
                    }
                    Text(FilingText.kicker(receipt.ref, in: game))
                        .font(Trace.Fonts.caption)
                        .foregroundStyle(Trace.Colors.ink2)
                        .fixedSize(horizontal: false, vertical: true)
                    if !receipt.isNew {
                        Text(L10n.t("evidence.alreadyFiled"))
                            .font(Trace.Fonts.caption)
                            .foregroundStyle(Trace.Colors.ink2)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                stamp
            }
            FilingPreview(ref: receipt.ref, game: game)
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Rectangle().fill(Trace.Colors.photoBorder))
                .overlay(Rectangle().strokeBorder(Trace.Colors.ink2.opacity(0.3), lineWidth: 1))
            ForEach(receipt.help, id: \.self) { line in
                Text(line)
                    .font(Trace.Fonts.callout)
                    .foregroundStyle(Trace.Colors.ink)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    /// The code stamp VERSÉE (red frame, Plex Mono 700, −8°).
    private var stamp: some View {
        StampMark(text: L10n.t("slip.stamp"), color: Trace.Colors.red, size: 13)
            .scaleEffect(reduceMotion ? 1 : (stampPhase == 0 ? 1.35 : stampPhase == 1 ? 0.98 : 1))
            .opacity(stampPhase > 0 ? 1 : 0)
            .padding(.top, 2)
            .fixedSize()
    }

    private var actions: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 10) { secondary; primary }
            VStack(spacing: 10) { primary; secondary }
        }
    }

    @ViewBuilder
    private var secondary: some View {
        if receipt.isNew {
            Button(L10n.t("evidence.connect"), action: onConnect)
                .buttonStyle(CTAButtonStyle(kind: .outline, onPaper: true))
                .accessibilityIdentifier("filing.connect")
        } else {
            Button(L10n.t("evidence.viewPiece"), action: onViewInCarnet)
                .buttonStyle(CTAButtonStyle(kind: .outline, onPaper: true))
                .accessibilityIdentifier("filing.viewInCarnet")
        }
    }

    private var primary: some View {
        Button(L10n.t("evidence.continue"), action: onContinue)
            .buttonStyle(CTAButtonStyle(kind: .primary, onPaper: true))
            .accessibilityIdentifier("filing.confirm")
    }

    // MARK: Motion (V4 §5 « Pièce versée »)

    /// The slip falls on the phone (300 ms), then its stamp (180 ms + a 60 ms settle). Reduced
    /// motion: a 200 ms fade, the stamp appears with it.
    private func fall() {
        guard !landed else { return }
        if reduceMotion {
            withAnimation(.easeOut(duration: 0.2)) {
                landed = true
                if receipt.isNew { stampPhase = 2 }
            }
            return
        }
        withAnimation(.timingCurve(0.2, 0.8, 0.2, 1, duration: 0.3)) { landed = true }
        guard receipt.isNew, stampPhase == 0 else { return }
        Task {
            try? await Task.sleep(for: .milliseconds(300))
            withAnimation(Trace.Motion.stamp) { stampPhase = 1 }
            AudioDirector.shared.play(.stamp, volume: 0.6)
            try? await Task.sleep(for: .milliseconds(180))
            withAnimation(.easeOut(duration: 0.06)) { stampPhase = 2 }
        }
    }

    /// The UI tests launch with `-UITestReset`: the slip waits for their tap.
    static let uiTesting = ProcessInfo.processInfo.arguments.contains("-UITestReset")
}

/// The slip's width (it is narrower on a small phone: the shell keeps 24 pt around it).
private let evidenceSlipWidth: CGFloat = 340
/// At rest: −1.2°. Falling: from −3° and 1.06.
private let evidenceSlipAngle: Double = -1.2
private let evidenceSlipFallAngle: Double = -3
private let evidenceSlipFallScale: CGFloat = 1.06

/// The words of the EvidenceSlip.
enum FilingText {
    /// « TYPE · date · heure »: « MESSAGE · 12 sept. · 22:30 » (the source is in the preview).
    static func kicker(_ ref: ItemRef, in game: Investigation) -> String {
        let item = ItemDescriber.describe(ref, in: game)
        var parts = [PieceFormat.kind(ref, in: game)]
        if let at = item.at { parts += [PhoneFormat.shortDay(at), PhoneFormat.time(at)] }
        return parts.joined(separator: " · ")
    }
}

/// A few lines of the element: the message, the photo and its caption, the call…
struct FilingPreview: View {
    let ref: ItemRef
    let game: Investigation

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Who (or which app) the element comes from.
            Text(PieceFormat.origin(ref, in: game))
                .font(Trace.Fonts.caption)
                .foregroundStyle(Trace.Colors.ink2)
                .lineLimit(1)
            content
        }
    }

    @ViewBuilder
    private var content: some View {
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
                    prose(mail.subject, lines: 2)
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
            .foregroundStyle(Trace.Colors.ink)
            .lineLimit(lines)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func quote(_ text: String, lines: Int = 4) -> some View {
        Text("« \(text) »")
            .font(Trace.Fonts.quote)
            .foregroundStyle(Trace.Colors.ink)
            .lineLimit(lines)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func detail(_ text: String, lines: Int = 1) -> some View {
        Text(text)
            .font(Trace.Fonts.caption)
            .foregroundStyle(Trace.Colors.ink2)
            .lineLimit(lines)
    }

    private func thumbnail(_ photo: Photo) -> some View {
        GeneratedPhoto(photo: photo)
            .frame(width: 64, height: 64)
            .clipped()
            .accessibilityLabel(Text(photo.caption))
    }
}

#endif
