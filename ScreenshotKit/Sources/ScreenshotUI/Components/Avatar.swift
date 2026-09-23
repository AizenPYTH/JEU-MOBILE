#if os(iOS)
import SwiftUI
import CaseEngine

/// Neutral avatar: initials on a disc tinted by the contact's hue (portraits will be real photos later — never drawings).
struct Avatar: View {
    let contact: Contact?
    var size: CGFloat = Theme.Size.avatarM

    var body: some View {
        let colors = contact.map { Theme.avatarColor(hue: $0.avatarHue) }
        Circle()
            .fill(colors.map { LinearGradient(colors: [$0.top, $0.bottom], startPoint: .top, endPoint: .bottom) }
                  ?? LinearGradient(colors: [Theme.Colors.bgElevated, Theme.Colors.bgElevated], startPoint: .top, endPoint: .bottom))
            .overlay(Circle().strokeBorder(Theme.Colors.line2, lineWidth: 1))
            .overlay(
                Text(contact?.initials ?? "?")
                    .font(.custom(Theme.FontName.semibold, fixedSize: size * 0.36))
                    .foregroundStyle(Theme.Colors.textPrimary)
            )
            .frame(width: size, height: size)
            .accessibilityHidden(true)
    }
}

/// Group conversation: the member count in a disc.
struct GroupAvatar: View {
    let count: Int
    var size: CGFloat = Theme.Size.avatarM

    var body: some View {
        Circle()
            .fill(Theme.Colors.bgElevated)
            .overlay(Circle().strokeBorder(Theme.Colors.line2, lineWidth: 1))
            .overlay(Text("\(count)").font(.custom(Theme.FontName.mono, fixedSize: size * 0.32)).foregroundStyle(Theme.Colors.textSecondary))
            .frame(width: size, height: size)
            .accessibilityHidden(true)
    }
}

/// Portrait placeholder of a suspect (rectangle, initials) until real photos exist.
struct Portrait: View {
    let contact: Contact?
    var width: CGFloat = Theme.Size.portrait
    var height: CGFloat = Theme.Size.portrait

    var body: some View {
        let colors = Theme.avatarColor(hue: contact?.avatarHue ?? 0.6)
        RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous)
            .fill(LinearGradient(colors: [colors.top, colors.bottom], startPoint: .top, endPoint: .bottom))
            .overlay(StripedPattern().clipShape(RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous)))
            .overlay(
                Text(contact?.initials ?? "?")
                    .font(.custom(Theme.FontName.semibold, fixedSize: min(width, height) * 0.3))
                    .foregroundStyle(Theme.Colors.textPrimary)
            )
            .elevation0(Theme.Radius.md)
            .frame(width: width, height: height)
            .accessibilityHidden(true)
    }
}

/// The handoff's "placeholder rayé": diagonal thin stripes.
struct StripedPattern: View {
    var body: some View {
        Canvas { context, size in
            var path = Path()
            var x: CGFloat = -size.height
            while x < size.width {
                path.move(to: CGPoint(x: x, y: size.height))
                path.addLine(to: CGPoint(x: x + size.height, y: 0))
                x += 9
            }
            context.stroke(path, with: .color(Theme.Colors.line1), lineWidth: 1)
        }
        .allowsHitTesting(false)
    }
}
#endif
