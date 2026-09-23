#if os(iOS)
import SwiftUI
import CaseEngine

/// Long press on anything in the phone (≈0.4 s, native lift + blur) → pin to the notebook,
/// link to a suspect, or unpin. A pinned element shows the amber ring + dot.
/// The game never highlights anything the player has not pinned.
struct Pinnable: ViewModifier {
    let ref: ItemRef
    let session: GameSession
    var radius: CGFloat = Theme.Radius.lg

    func body(content: Content) -> some View {
        let pinned = session.isPinned(ref)
        let entry = session.game.notebook.first { $0.ref == ref }
        content
            .pinnedRing(pinned, radius: radius)
            .contextMenu {
                Button {
                    session.togglePin(ref)
                } label: {
                    Label(pinned ? L10n.t("pin.remove") : L10n.t("pin.add"), systemImage: pinned ? "pin.slash" : "pin")
                }
                Menu {
                    ForEach(session.caseFile.suspects) { suspect in
                        Button {
                            session.link(ref, to: entry?.linkedTo == suspect.id ? nil : suspect.id)
                        } label: {
                            Label(session.game.name(of: suspect.contact),
                                  systemImage: entry?.linkedTo == suspect.id ? "checkmark" : "person")
                        }
                    }
                } label: {
                    Label(L10n.t("pin.link"), systemImage: "link")
                }
            }
    }
}

extension View {
    func pinnable(_ ref: ItemRef, session: GameSession, radius: CGFloat = Theme.Radius.lg) -> some View {
        modifier(Pinnable(ref: ref, session: session, radius: radius))
    }
}

/// Toast "◆ Ajouté au carnet · 3" (h 40, r 20, e1).
struct ToastView: View {
    let text: String

    var body: some View {
        Text(text)
            .font(Theme.Fonts.calloutStrong)
            .foregroundStyle(Theme.Colors.textPrimary)
            .padding(.horizontal, Theme.Spacing.s5)
            .frame(height: 40)
            .background(Capsule().fill(Theme.Colors.bgBubbleIn))
            .elevation1(Capsule())
    }
}
#endif
