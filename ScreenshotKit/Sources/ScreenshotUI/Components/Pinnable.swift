#if os(iOS)
import SwiftUI
import CaseEngine

/// Long press on anything in the phone (≈0.4 s, native lift + blur) → the deposit slip: « Verser au
/// dossier » (pin), « L'accuse… » / « Le disculpe… » (link to a suspect with the player's reading),
/// or « Retirer du dossier ». A filed element shows the amber ring + dot.
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
                // The deposit slip: « Verser au dossier », then the player's reading.
                Button {
                    session.togglePin(ref)
                } label: {
                    Label(pinned ? L10n.t("pin.remove") : L10n.t("pin.add"), systemImage: pinned ? "tray.and.arrow.up" : "tray.and.arrow.down")
                }
                Menu {
                    ForEach(session.caseFile.suspects) { suspect in
                        Button {
                            session.annotate(ref, suspect: suspect.id, stance: .incriminates)
                        } label: {
                            Label(session.game.name(of: suspect.contact),
                                  systemImage: entry?.linkedTo == suspect.id && entry?.stance == .incriminates ? "checkmark" : "person")
                        }
                    }
                } label: {
                    Label(L10n.t("pin.accuses"), systemImage: "arrow.up.right")
                }
                Menu {
                    ForEach(session.caseFile.suspects) { suspect in
                        Button {
                            session.annotate(ref, suspect: suspect.id, stance: .clears)
                        } label: {
                            Label(session.game.name(of: suspect.contact),
                                  systemImage: entry?.linkedTo == suspect.id && entry?.stance == .clears ? "checkmark" : "person")
                        }
                    }
                } label: {
                    Label(L10n.t("pin.clears"), systemImage: "checkmark.shield")
                }
            }
    }
}

extension View {
    func pinnable(_ ref: ItemRef, session: GameSession, radius: CGFloat = Theme.Radius.lg) -> some View {
        modifier(Pinnable(ref: ref, session: session, radius: radius))
    }
}

/// The confirmation label taped over the phone for a moment: « PIÈCE 7 VERSÉE AU DOSSIER »,
/// or « L'ACCUSE : EMMA ROUSSEL » — paper, one of the few paper things that enter the phone.
struct ToastView: View {
    let toast: GameSession.Toast

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(toast.text)
                .font(Trace.Fonts.button)
                .tracking(1.2)
                .textCase(.uppercase)
                .foregroundStyle(toast.kind == .neutral ? Trace.Colors.inkSoft : Trace.Colors.stamp)
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
