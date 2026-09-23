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

/// Hold to confirm (900 ms, fills left → right; releasing early rolls back in 200 ms).
struct HoldToConfirmButton: View {
    let title: String
    let disabledTitle: String
    let enabled: Bool
    let action: () -> Void

    @State private var progress: CGFloat = 0
    @State private var holding = false

    var body: some View {
        ZStack(alignment: .leading) {
            RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous)
                .fill(enabled ? Theme.Colors.bgSelected : Theme.Colors.line1)
            GeometryReader { geo in
                RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous)
                    .fill(Theme.Colors.textPrimary)
                    .frame(width: geo.size.width * progress)
            }
            Text(enabled ? title : disabledTitle)
                .font(Theme.Fonts.headline)
                .foregroundStyle(enabled ? (progress > 0.5 ? Theme.Colors.textOnLight : Theme.Colors.textPrimary) : Theme.Colors.textTertiary)
                .frame(maxWidth: .infinity)
        }
        .frame(height: Theme.Size.buttonL)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous))
        .contentShape(Rectangle())
        .onLongPressGesture(minimumDuration: Theme.Motion.holdToConfirm, maximumDistance: 40) {
            guard enabled else { return }
            Haptics.success()
            action()
        } onPressingChanged: { pressing in
            guard enabled else { return }
            holding = pressing
            if pressing {
                withAnimation(.linear(duration: Theme.Motion.holdToConfirm)) { progress = 1 }
            } else {
                withAnimation(.linear(duration: 0.2)) { progress = 0 }
            }
        }
        .accessibilityElement()
        .accessibilityLabel(Text(enabled ? title : disabledTitle))
        .accessibilityAddTraits(.isButton)
        .accessibilityAction { if enabled { action() } }
    }
}

/// SegmentedControl: h 38, pad 3, active segment bg.selected r 9.
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
                                .fill(selection == option.value ? Theme.Colors.bgSelected : .clear)
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

/// Empty state: dashed 56 square + title + a useful sentence (never a dead end).
struct EmptyStateView: View {
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: Theme.Spacing.s4) {
            RoundedRectangle(cornerRadius: Theme.Radius.sm)
                .strokeBorder(Theme.Colors.line3, style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
                .frame(width: 56, height: 56)
            Text(title).font(Theme.Fonts.headline).foregroundStyle(Theme.Colors.textPrimary)
            Text(message).font(Theme.Fonts.callout).foregroundStyle(Theme.Colors.textSecondary).multilineTextAlignment(.center)
        }
        .padding(Theme.Spacing.s8)
        .frame(maxWidth: .infinity)
    }
}
#endif
