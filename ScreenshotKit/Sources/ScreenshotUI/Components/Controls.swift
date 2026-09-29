#if os(iOS)
import SwiftUI

/// ButtonPrimary: off-white fill, black text, r 14, h 56/52/44; pressed = scale .98 + darker.
struct PrimaryButtonStyle: ButtonStyle {
    var height: CGFloat = Theme.Size.buttonL
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Theme.Fonts.headline)
            .foregroundStyle(isEnabled ? Theme.Colors.textOnLight : Theme.Colors.textTertiary)
            .frame(maxWidth: .infinity, minHeight: height)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous)
                    .fill(isEnabled ? (configuration.isPressed ? Theme.Colors.primaryPressed : Theme.Colors.textPrimary) : Theme.Colors.line1)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(Theme.Motion.standard(Theme.Motion.fast), value: configuration.isPressed)
    }
}

/// ButtonSecondary: line.1 fill + line.2 outline.
struct SecondaryButtonStyle: ButtonStyle {
    var height: CGFloat = Theme.Size.buttonM
    var tint: Color = Theme.Colors.textPrimary

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Theme.Fonts.headline)
            .foregroundStyle(tint)
            .frame(maxWidth: .infinity, minHeight: height)
            .background(RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous).fill(Theme.Colors.line1))
            .overlay(RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous).strokeBorder(Theme.Colors.line2))
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
    }
}

/// ButtonTertiary: secondary text only.
struct TertiaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Theme.Fonts.callout)
            .foregroundStyle(Theme.Colors.textSecondary)
            .frame(minHeight: Theme.Size.hit)
            .opacity(configuration.isPressed ? 0.6 : 1)
    }
}

/// SegmentedControl (the phone's, iOS style): h 38, pad 3, the active segment white on the grey track, r 9.
struct Segmented<Value: Hashable>: View {
    let options: [(value: Value, label: String)]
    @Binding var selection: Value
    /// Accessibility identifier prefix: each segment gets "<prefix>.<index>".
    var identifier: String? = nil

    var body: some View {
        HStack(spacing: 0) {
            ForEach(options.indices, id: \.self) { i in
                let option = options[i]
                Button {
                    selection = option.value
                    Haptics.selection()
                } label: {
                    Text(option.label)
                        .font(Theme.Fonts.calloutStrong)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                        .padding(.horizontal, 2)
                        .foregroundStyle(selection == option.value ? Theme.Colors.textPrimary : Theme.Colors.textSecondary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 9, style: .continuous)
                                .fill(selection == option.value ? Theme.Colors.bgBase : .clear)
                        )
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(selection == option.value ? .isSelected : [])
                .accessibilityIdentifier(identifier.map { "\($0).\(i)" } ?? "")
            }
        }
        .padding(3)
        .frame(height: Theme.Size.segmented)
        .background(RoundedRectangle(cornerRadius: Theme.Radius.sm, style: .continuous).fill(Theme.Colors.bgRaised))
    }
}

/// Empty state of a phone app, rendered like the system's (« Aucune note »): a title and one
/// sentence, centred, in the phone's own style (UX V3 §6-13) — never the BEN's tone.
struct EmptyStateView: View {
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: Theme.Spacing.s3) {
            Text(title).font(Theme.Fonts.headline).foregroundStyle(Theme.Colors.textPrimary)
                .multilineTextAlignment(.center)
            Text(message).font(Theme.Fonts.callout).foregroundStyle(Theme.Colors.textSecondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(Theme.Spacing.s8)
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }
}
#endif
