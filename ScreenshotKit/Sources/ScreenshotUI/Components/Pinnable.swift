#if os(iOS)
import SwiftUI
import CaseEngine

/// A versable element of the phone (handoff V4 §3 EvidenceTag, on the UX V3 §6-04). A TAP selects
/// it: a 2 pt kraft ring, and the EvidenceTag « Verser au dossier » under it (fade + 4 pt, 150 ms),
/// which files it (`GameSession.requestFiling`) and opens the EvidenceSlip. An element already
/// filed keeps its « PIÈCE 03 » paper label, and its tag reads « PIÈCE 03 · Voir la pièce » (→ the
/// Carnet). The tag is offered for EVERY element, so the game never tells which ones matter. A tap
/// elsewhere, navigating or scrolling it away hides it.
///
/// The 0.5 s long press stays as a shortcut that files at once. It is simultaneous with the
/// element's own gestures, so a Button or a row keeps its tap and a ScrollView keeps scrolling (the
/// press fails beyond 12 pt of movement). On iOS 18+ it is a UIKit recognizer (`PressRecognizer`):
/// SwiftUI's LongPressGesture there blocks a scroll that starts on the element.
///
/// Elements whose tap already does something (a row that opens a screen, a grid photo) pass
/// `selectOnTap: false`: they keep their tap and are filed by long press, or from the screen they
/// open. A whole screen (a note, a mail, a contact card: taller than 400 pt) shows its tag inside
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
                    .strokeBorder(Trace.Colors.kraft, lineWidth: 2)
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
                    EvidenceTag(ref: ref, session: session)
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
    /// Makes an element of the phone « versable »: tap → EvidenceTag « Verser au dossier »;
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

// MARK: - EvidenceTag (V4 §3)

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
    /// The EvidenceTag label: Plex Sans 13/600.
    static let evidenceBadge = Font.custom(Trace.FontName.sansSemibold, size: 13, relativeTo: .footnote)
    /// The piece number on a filed element's tag: Plex Mono 10/700.
    static let evidenceTagNumber = Font.custom(Trace.FontName.monoBold, size: 10, relativeTo: .caption2)
}

/// EvidenceTag (V4 §3): a kraft label of 32 pt (44 pt target), corners 4 16 16 4, a white 8 pt
/// eyelet on its left and « Verser au dossier » in Plex Sans 13/600 ink. Already filed: the eyelet,
/// the « PIÈCE 03 » paper label and « Voir la pièce », which opens the Carnet on that piece. Flat
/// kraft, no texture (it is a button); it lies on the light phone like a real luggage label.
struct EvidenceTag: View {
    let ref: ItemRef
    let session: GameSession

    var body: some View {
        let number = session.game.pieceNumber(of: ref)
        let shape = UnevenRoundedRectangle(topLeadingRadius: evidenceTagInnerRadius, bottomLeadingRadius: evidenceTagInnerRadius,
                                           bottomTrailingRadius: evidenceTagOuterRadius, topTrailingRadius: evidenceTagOuterRadius,
                                           style: .continuous)
        Button {
            if number != nil { session.showInCarnet(ref) } else { session.requestFiling(ref) }
        } label: {
            HStack(spacing: 8) {
                // The eyelet: a white ring punched in the label.
                Circle()
                    .fill(Trace.Colors.photoBorder)
                    .overlay(Circle().strokeBorder(Trace.Colors.kraftDark, lineWidth: 1))
                    .frame(width: evidenceTagEyelet, height: evidenceTagEyelet)
                    .accessibilityHidden(true)
                if let number {
                    Text(PieceFormat.title(number))
                        .font(Trace.Fonts.evidenceTagNumber)
                        .tracking(0.8)
                        .foregroundStyle(Trace.Colors.ink)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(Rectangle().fill(Trace.Colors.label))
                    Text(L10n.t("evidence.viewPiece")).foregroundStyle(Trace.Colors.ink)
                } else {
                    Text(L10n.t("pin.add")).foregroundStyle(Trace.Colors.ink)
                }
            }
            .font(Trace.Fonts.evidenceBadge)
            .lineLimit(1)
            .padding(.leading, 10)
            .padding(.trailing, 16)
            .frame(minHeight: Trace.Height.evidenceTag)
            .background(
                shape
                    .fill(Trace.Colors.kraft)
                    .shadow(color: Trace.Shadow.print.color, radius: 3, y: 2)
            )
            .frame(minHeight: Trace.Height.hit)
            .contentShape(Rectangle())
        }
        .buttonStyle(PressableStyle())
        .accessibilityLabel(Text(number.map { PieceFormat.shortTitle($0) + ", " + L10n.t("evidence.viewPiece") } ?? L10n.t("pin.add")))
        .accessibilityIdentifier(number == nil ? "evidence.file" : "evidence.viewPiece")
    }
}

/// The tag's corners: 4 on the eyelet side, 16 on the free end.
private let evidenceTagInnerRadius: CGFloat = 4
private let evidenceTagOuterRadius: CGFloat = 16
/// The eyelet's diameter.
private let evidenceTagEyelet: CGFloat = 8
/// Width kept for a tag on the right of an element before it is aligned on the element's
/// trailing edge instead (a sent message on the right of the screen).
private let evidenceBadgeRoom: CGFloat = 200

/// The layer of the phone that draws the selected element's EvidenceTag, under the element
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
                    EvidenceTag(ref: ref, session: session)
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

/// A short line at the top of the phone for a moment (« Retirée du dossier », « Lié à Emma »…): a
/// small paperCard label held by a piece of tape — ink text, no rotation.
struct ToastView: View {
    let toast: GameSession.Toast

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(toast.text)
                .font(Trace.Fonts.monoStrong)
                .foregroundStyle(Trace.Colors.ink)
                .fixedSize(horizontal: false, vertical: true)
            if let detail = toast.detail {
                Text(detail)
                    .font(Trace.Fonts.caption)
                    .foregroundStyle(Trace.Colors.ink2)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 14)
        .padding(.bottom, 10)
        .frame(maxWidth: 320, alignment: .leading)
        .background(
            Rectangle()
                .fill(Trace.Colors.paperCard)
                .shadow(color: Trace.Shadow.slip.color, radius: Trace.Shadow.slip.radius, y: Trace.Shadow.slip.y)
        )
        .overlay(alignment: .top) { Tape().offset(y: -8) }
        .padding(.horizontal, Theme.Spacing.s6)
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("phone.toast")
    }
}
#endif
