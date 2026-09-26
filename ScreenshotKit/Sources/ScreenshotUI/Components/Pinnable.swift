#if os(iOS)
import SwiftUI
import CaseEngine

/// The one collecting gesture of the game (final handoff §B-3, §F-06): a 0.4 s long press on any
/// element of the phone. While the finger is down the element grows to 1.03 with a 2 pt paper ring
/// (150 ms); once recognised, the « VERSER AU DOSSIER » sheet opens (`GameSession.requestFiling`,
/// medium haptic). A filed element keeps its « PIÈCE 0N » label. The game never highlights anything
/// the player has not filed.
///
/// The long press is simultaneous with the element's own gestures, so a Button or a row keeps its
/// tap and a ScrollView keeps scrolling (the press fails beyond 12 pt of movement). The tap that
/// follows a recognised press (the finger lifted on the element) is ignored by the session while
/// the filing sheet is open.
struct Pinnable: ViewModifier {
    let ref: ItemRef
    let session: GameSession
    var radius: CGFloat = Theme.Radius.lg
    @GestureState(resetTransaction: Transaction(animation: .easeOut(duration: 0.15))) private var pressing = false
    /// The element's size: a big element (a photo, a whole note or mail screen) keeps its label
    /// inside its corner, and a whole screen does not grow.
    @State private var size: CGSize = .zero
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    @AppStorage(Preferences.reduceMotionKey) private var appReduceMotion = false

    func body(content: Content) -> some View {
        let number = session.game.pieceNumber(of: ref)
        let shape = RoundedRectangle(cornerRadius: radius, style: .continuous)
        let inside = size.height >= pinnableLargeHeight
        let grows = pressing && size.height <= pinnableScreenHeight && !(systemReduceMotion || appReduceMotion)
        content
            .accessibilityAction(named: Text(L10n.t("pin.add"))) { session.requestFiling(ref) }
            .overlay {
                shape
                    .strokeBorder(Trace.Colors.paper, lineWidth: 2)
                    .opacity(pressing ? 1 : 0)
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
            }
            .scaleEffect(grows ? 1.03 : 1)
            .overlay(alignment: .topTrailing) {
                if let number {
                    PieceBadge(number: number)
                        .offset(x: inside ? -10 : -6, y: inside ? 8 : -7)
                        .allowsHitTesting(false)
                        .transition(.opacity)
                }
            }
            .overlay(alignment: .topLeading) {
                if size.height > pinnableScreenHeight {
                    // A whole screen is not one VoiceOver element: its « Verser au dossier » is a
                    // button of its own (invisible).
                    Color.clear
                        .frame(width: 1, height: 1)
                        .accessibilityElement()
                        .accessibilityLabel(Text(L10n.t("pin.add")))
                        .accessibilityAddTraits(.isButton)
                        .accessibilityAction { session.requestFiling(ref) }
                }
            }
            .onGeometryChange(for: CGSize.self) { $0.size } action: { size = $0 }
            .simultaneousGesture(
                LongPressGesture(minimumDuration: 0.4, maximumDistance: 12)
                    .updating($pressing) { value, state, transaction in
                        state = value
                        // A short delay: a finger that starts a scroll does not light the element up.
                        transaction.animation = .easeOut(duration: 0.15).delay(0.1)
                    }
                    .onEnded { _ in session.requestFiling(ref) }
            )
    }
}

/// From this height the « PIÈCE 0N » label sits inside the element's corner (a photo, a card),
/// not astride its top edge (a message, a row).
private let pinnableLargeHeight: CGFloat = 200
/// Taller than this, the element is a whole screen: it does not grow under the finger.
private let pinnableScreenHeight: CGFloat = 400

extension View {
    /// Makes an element of the phone « versable »: long press → « VERSER AU DOSSIER ».
    /// `enabled: false` for what is on screen but cannot be filed yet (a message removed by its
    /// sender, whose text is hidden until it is recovered).
    @ViewBuilder
    func pinnable(_ ref: ItemRef, session: GameSession, radius: CGFloat = Theme.Radius.lg, enabled: Bool = true) -> some View {
        if enabled {
            modifier(Pinnable(ref: ref, session: session, radius: radius))
        } else {
            self
        }
    }
}

/// A short paper label taped at the top of the phone for a moment (the 90 s tip, « Retirée du
/// dossier »…) — one of the few paper things that enter the phone.
struct ToastView: View {
    let toast: GameSession.Toast

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(toast.text)
                .font(Trace.Fonts.button)
                .tracking(1.2)
                .textCase(.uppercase)
                .foregroundStyle(toast.kind == .neutral ? Trace.Colors.inkSoft : Trace.Colors.stamp)
                .fixedSize(horizontal: false, vertical: true)
            if let detail = toast.detail {
                Text(detail)
                    .font(Trace.Fonts.monoSmall)
                    .foregroundStyle(Trace.Colors.ink)
                    .lineLimit(1)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 9)
        .frame(maxWidth: 300, alignment: .leading)
        .paper(Trace.Colors.label, radius: 1, lifted: true)
        .overlay(alignment: .top) { Tape(width: 40).offset(y: -7) }
        .rotationEffect(.degrees(-1.5))
        .padding(.horizontal, Theme.Spacing.s6)
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("phone.toast")
    }
}
#endif
