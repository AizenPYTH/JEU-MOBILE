#if os(iOS)
import SwiftUI
import CaseEngine

/// Neutral generated avatar: initials on a tinted disc. No drawn faces.
struct Avatar: View {
    let contact: Contact?
    var size: CGFloat = Theme.Size.avatarM

    var body: some View {
        let hue = contact?.avatarHue ?? 0.6
        Circle()
            .fill(LinearGradient(colors: [Color(hue: hue, saturation: 0.35, brightness: 0.62),
                                          Color(hue: hue, saturation: 0.45, brightness: 0.38)],
                                 startPoint: .top, endPoint: .bottom))
            .overlay(
                Text(contact?.initials ?? "?")
                    .font(.system(size: size * 0.38, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
            )
            .frame(width: size, height: size)
            .accessibilityHidden(true)
    }
}

/// Avatar of a group conversation: two overlapping discs.
struct GroupAvatar: View {
    let contacts: [Contact]
    var size: CGFloat = Theme.Size.avatarM

    var body: some View {
        ZStack {
            Avatar(contact: contacts.first, size: size * 0.7).offset(x: -size * 0.15, y: -size * 0.12)
            Avatar(contact: contacts.dropFirst().first, size: size * 0.7).offset(x: size * 0.15, y: size * 0.12)
        }
        .frame(width: size, height: size)
    }
}
#endif
