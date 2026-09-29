#if os(iOS)
import SwiftUI
import CaseEngine

/// A versable element of the phone (handoff UX V3 §6-04). A TAP selects it: a 2 pt ben ring, and
/// the EvidenceBadge « + Verser au dossier » under it (fade + 4 pt, 150 ms), which files it
/// (`GameSession.requestFiling`) and opens the EvidenceSheet. An element already filed keeps its
/// « ✓ Pièce 03 » label, and its badge reads « ✓ Pièce 03 · Voir la pièce » (→ the Carnet). The
/// badge is offered for EVERY element, so the game never tells which ones matter. A tap elsewhere,
/// navigating or scrolling it away hides it.
///
/// The 0.5 s long press stays as a shortcut that files at once. It is simultaneous with the
/// element's own gestures, so a Button or a row keeps its tap and a ScrollView keeps scrolling (the
/// press fails beyond 12 pt of movement). On iOS 18+ it is a UIKit recognizer (`PressRecognizer`):
/// SwiftUI's LongPressGesture there blocks a scroll that starts on the element.
///
/// Elements whose tap already does something (a row that opens a screen, a grid photo) pass
/// `selectOnTap: false`: they keep their tap and are filed by long press, or from the screen they
/// open. A whole screen (a note, a mail, a contact card: taller than 400 pt) shows its badge inside
/// its bottom-leading corner — always, when its tap does not select it.
struct Pinnable: ViewModifier {
    let ref: ItemRef
    let session: GameSession
    var radius: CGFloat = Theme.Radius.lg
    var selectOnTap = true
    @GestureState(resetTransaction: Transaction(animation: .easeOut(duration: 0.15))) private var legacyPressing = false
    @State private var touching = false
    private var pressing: Bool { legacyPressing || touching }
    /// The element's frame in the window: the badge layer of the phone draws the badge under it.
    @State private var frame: CGRect = .zero
    @Environment(EvidenceBadgeAnchor.self) private var anchor: EvidenceBadgeAnchor?
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    @AppStorage(Preferences.reduceMotionKey) private var appReduceMotion = false

    private var reduceMotion: Bool { systemReduceMotion || appReduceMotion }

    func body(content: Content) -> some View {
        let number = session.game.pieceNumber(of: ref)
        let shape = RoundedRectangle(cornerRadius: radius, style: .continuous)
        let isSelected = session.selected == ref
        let screen = frame.height > pinnableScreenHeight
        let inside = frame.height >= pinnableLargeHeight
        let grows = pressing && !screen && !reduceMotion
        content
            .accessibilityAction(named: Text(L10n.t("pin.add"))) { session.requestFiling(ref) }
            .overlay {
                shape
                    .strokeBorder(Trace.Colors.ben, lineWidth: 2)
                    .opacity((pressing || isSelected) && !screen ? 1 : 0)
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
            }
            .scaleEffect(grows ? 1.03 : 1)
            .overlay(alignment: .topTrailing) {
                if let number, !screen {
                    PieceBadge(number: number)
                        .offset(x: inside ? -10 : -6, y: inside ? 8 : -7)
                        .allowsHitTesting(false)
                        .transition(.opacity)
                }
            }
            .overlay(alignment: .bottomLeading) {
                // A whole screen: its badge sits inside its corner, above the home indicator.
                if screen && (isSelected || !selectOnTap) {
                    EvidenceBadge(ref: ref, session: session)
                        .padding(.leading, Theme.Spacing.marginCompact)
                        .padding(.bottom, pinnableScreenBadgeBottom)
                        .transition(reduceMotion ? .opacity : .opacity.combined(with: .offset(y: 4)))
                }
            }
            .overlay(alignment: .topLeading) {
                if screen {
                    // A whole screen is not one VoiceOver element: its « Verser au dossier » is a
                    // button of its own (invisible), besides the visible badge.
                    Color.clear
                        .frame(width: 1, height: 1)
                        .accessibilityElement()
                        .accessibilityLabel(Text(L10n.t("pin.add")))
                        .accessibilityAddTraits(.isButton)
                        .accessibilityAction { session.requestFiling(ref) }
                }
            }
            .zIndex(isSelected ? 1 : 0)
            .animation(.easeOut(duration: 0.15), value: isSelected)
            .onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: { newFrame in
                frame = newFrame
                if session.selected == ref, newFrame.height <= pinnableScreenHeight {
                    anchor?.place(ref, at: newFrame)
                }
            }
            .onChange(of: isSelected) { _, selected in
                if selected, !screen { anchor?.place(ref, at: frame) }
            }
            .onDisappear {
                if session.selected == ref { session.clearSelection() }
            }
            .modifier(TapToSelect(enabled: selectOnTap) { session.select(ref) })
            .modifier(PressAttachment(legacyPressing: $legacyPressing, touching: $touching) { session.requestFiling(ref) })
    }
}

/// The tap that selects an element (simultaneous: the element's own gestures still work).
private struct TapToSelect: ViewModifier {
    let enabled: Bool
    let action: () -> Void

    func body(content: Content) -> some View {
        if enabled {
            content.simultaneousGesture(TapGesture().onEnded { action() })
        } else {
            content
        }
    }
}

/// The 0.5 s press of `Pinnable`: UIKit on iOS 18+, SwiftUI before.
private struct PressAttachment: ViewModifier {
    let legacyPressing: GestureState<Bool>
    @Binding var touching: Bool
    let recognized: () -> Void

    func body(content: Content) -> some View {
        if #available(iOS 18.0, *) {
            content.gesture(PressRecognizer(minimumDuration: pinnablePressDuration, maximumDistance: 12, onPressing: { down in
                // A short delay on the way in: a finger that starts a scroll does not light the element up.
                withAnimation(down ? .easeOut(duration: 0.15).delay(0.1) : .easeOut(duration: 0.15)) { touching = down }
            }, onRecognized: recognized))
        } else {
            content.simultaneousGesture(
                LongPressGesture(minimumDuration: pinnablePressDuration, maximumDistance: 12)
                    .updating(legacyPressing) { value, state, transaction in
                        state = value
                        transaction.animation = .easeOut(duration: 0.15).delay(0.1)
                    }
                    .onEnded { _ in recognized() }
            )
        }
    }
}

/// The long press shortcut (§6-04: 0.5 s).
private let pinnablePressDuration: Double = 0.5
/// From this height the « ✓ Pièce 0N » label sits inside the element's corner (a photo, a card),
/// not astride its top edge (a message, a row).
private let pinnableLargeHeight: CGFloat = 200
/// Taller than this, the element is a whole screen: it does not grow under the finger and its
/// badge sits inside it.
private let pinnableScreenHeight: CGFloat = 400
/// Room kept under a whole screen's badge for the phone's home indicator.
private let pinnableScreenBadgeBottom: CGFloat = 44

extension View {
    /// Makes an element of the phone « versable »: tap → EvidenceBadge « + Verser au dossier »;
    /// long press → filed at once. `enabled: false` for what is on screen but cannot be filed yet
    /// (a message removed by its sender, whose text is hidden until it is recovered).
    /// `selectOnTap: false` for an element whose tap already does something (a row that opens a
    /// screen, a grid photo, a whole screen).
    @ViewBuilder
    func pinnable(_ ref: ItemRef, session: GameSession, radius: CGFloat = Theme.Radius.lg, enabled: Bool = true,
                  selectOnTap: Bool = true) -> some View {
        if enabled {
            modifier(Pinnable(ref: ref, session: session, radius: radius, selectOnTap: selectOnTap))
        } else {
            self
        }
    }
}

// MARK: - EvidenceBadge (§5)

/// Where the selected element is, in the window: the phone's badge layer draws the badge there,
/// above every app screen (so no row, list or clip hides it).
@MainActor
@Observable
final class EvidenceBadgeAnchor {
    private(set) var ref: ItemRef?
    private(set) var frame: CGRect?

    func place(_ ref: ItemRef, at frame: CGRect) {
        if self.ref != ref { self.ref = ref }
        if self.frame != frame { self.frame = frame }
    }
}

extension Trace.Fonts {
    /// The EvidenceBadge label: Plex Sans 13/600.
    static let evidenceBadge = Font.custom(Trace.FontName.sansSemibold, size: 13, relativeTo: .footnote)
}

/// EvidenceBadge (§5): a `bg` pill of 30 pt (44 pt target), « + » in benText and « Verser au
/// dossier » in Plex Sans 13/600. Already filed: « ✓ Pièce 03 · Voir la pièce » on the success
/// tint, which opens the Carnet on that piece.
struct EvidenceBadge: View {
    let ref: ItemRef
    let session: GameSession

    var body: some View {
        let number = session.game.pieceNumber(of: ref)
        Button {
            if number != nil { session.showInCarnet(ref) } else { session.requestFiling(ref) }
        } label: {
            HStack(spacing: 6) {
                if let number {
                    Text(verbatim: "✓").foregroundStyle(Trace.Colors.successText)
                    Text(PieceFormat.shortTitle(number)).foregroundStyle(Trace.Colors.successText)
                    Text(verbatim: "·").foregroundStyle(Trace.Colors.text2)
                    Text(L10n.t("evidence.viewPiece")).foregroundStyle(Trace.Colors.text)
                } else {
                    Text(verbatim: "+").foregroundStyle(Trace.Colors.benText)
                    Text(L10n.t("pin.add")).foregroundStyle(Trace.Colors.text)
                }
            }
            .font(Trace.Fonts.evidenceBadge)
            .lineLimit(1)
            .padding(.horizontal, 12)
            .frame(minHeight: evidenceBadgeHeight)
            .background(Capsule().fill(number == nil ? Color.clear : Trace.Colors.tint(Trace.Colors.success)))
            .background(Capsule().fill(Trace.Colors.bg))
            .frame(minHeight: Trace.Height.hit)
            .contentShape(Rectangle())
        }
        .buttonStyle(PressableStyle())
        .accessibilityLabel(Text(number.map { PieceFormat.shortTitle($0) + ", " + L10n.t("evidence.viewPiece") } ?? L10n.t("pin.add")))
        .accessibilityIdentifier(number == nil ? "evidence.file" : "evidence.viewPiece")
    }
}

/// The pill's own height (its touch target is 44).
private let evidenceBadgeHeight: CGFloat = 30
/// Width kept for a badge on the right of an element before it is aligned on the element's
/// trailing edge instead (a sent message on the right of the screen).
private let evidenceBadgeRoom: CGFloat = 200

/// The layer of the phone that draws the selected element's EvidenceBadge, under the element
/// (above it when there is no room below), aligned on its leading edge — or its trailing edge
/// when it sits on the right.
struct EvidenceBadgeLayer: View {
    let session: GameSession
    let anchor: EvidenceBadgeAnchor
    /// The badge never covers the status bar (top) nor the home indicator (bottom).
    var topInset: CGFloat = 0
    var bottomInset: CGFloat = 0
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    @AppStorage(Preferences.reduceMotionKey) private var appReduceMotion = false

    var body: some View {
        let reduceMotion = systemReduceMotion || appReduceMotion
        GeometryReader { geo in
            let origin = geo.frame(in: .global).origin
            if let ref = session.selected, anchor.ref == ref, let frame = anchor.frame,
               session.receipt == nil {
                let rect = frame.offsetBy(dx: -origin.x, dy: -origin.y)
                let bottom = geo.size.height - bottomInset
                if rect.maxY > topInset && rect.minY < bottom {
                    let below = rect.maxY + Trace.Height.hit <= bottom
                    let top = below ? rect.maxY - 4 : max(topInset, rect.minY - Trace.Height.hit + 4)
                    let trailing = rect.minX + evidenceBadgeRoom > geo.size.width
                    EvidenceBadge(ref: ref, session: session)
                        .fixedSize()
                        .padding(.leading, trailing ? 0 : max(8, rect.minX))
                        .padding(.trailing, trailing ? max(8, geo.size.width - rect.maxX) : 0)
                        .frame(width: geo.size.width, alignment: trailing ? .trailing : .leading)
                        .padding(.top, top)
                        .frame(width: geo.size.width, height: geo.size.height, alignment: .topLeading)
                        .id(ref)
                        .transition(reduceMotion ? .opacity : .opacity.combined(with: .offset(y: below ? -4 : 4)))
                }
            }
        }
        .animation(.easeOut(duration: 0.15), value: session.selected)
    }
}

// MARK: - Toast

/// A short line at the top of the phone for a moment (« Retirée du dossier », « Lié à Emma »…):
/// a flat `surface2` pill, no tape, no rotation.
struct ToastView: View {
    let toast: GameSession.Toast

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(toast.text)
                .font(Trace.Fonts.monoStrong)
                .foregroundStyle(Trace.Colors.text)
                .fixedSize(horizontal: false, vertical: true)
            if let detail = toast.detail {
                Text(detail)
                    .font(Trace.Fonts.caption)
                    .foregroundStyle(Trace.Colors.text2)
                    .lineLimit(1)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .frame(maxWidth: 320, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: Trace.Radius.card, style: .continuous).fill(Trace.Colors.surface2))
        .padding(.horizontal, Theme.Spacing.s6)
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("phone.toast")
    }
}
#endif
