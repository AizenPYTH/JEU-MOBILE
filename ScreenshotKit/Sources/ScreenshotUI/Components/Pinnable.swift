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

/// Toast above the notebook capsule: "◆ Ajouté au carnet · 3" and, below, what was pinned.
/// Amber for a pin, violet for a link to a suspect.
struct ToastView: View {
    let toast: GameSession.Toast

    private var color: Color {
        switch toast.kind {
        case .pinned: Theme.Colors.signal
        case .linked: Theme.Colors.special
        case .neutral: Theme.Colors.textSecondary
        }
    }

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: Theme.Radius.lg, style: .continuous)
        HStack(spacing: Theme.Spacing.s3) {
            Image(systemName: toast.kind == .linked ? "link" : toast.kind == .pinned ? "pin.fill" : "pin.slash")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(color)
                .frame(width: 28, height: 28)
                .background(Circle().fill(color.opacity(0.16)))
            VStack(alignment: .leading, spacing: 1) {
                Text(toast.text)
                    .font(Theme.Fonts.calloutStrong)
                    .foregroundStyle(Theme.Colors.textPrimary)
                if let detail = toast.detail {
                    Text(detail)
                        .font(Theme.Fonts.caption)
                        .foregroundStyle(Theme.Colors.textSecondary)
                        .lineLimit(1)
                }
            }
        }
        .padding(.leading, Theme.Spacing.s3)
        .padding(.trailing, Theme.Spacing.s5)
        .padding(.vertical, Theme.Spacing.s2)
        .frame(minHeight: 44)
        .background(shape.fill(Theme.Colors.bgBubbleIn))
        .overlay(shape.strokeBorder(color.opacity(0.35), lineWidth: 1))
        .shadow(color: .black.opacity(0.5), radius: 16, y: 12)
        .padding(.horizontal, Theme.Spacing.s6)
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("phone.toast")
    }
}
#endif
