import SwiftUI

/// btn.primary / btn.secondary from the design system.
///
/// - primary: h 56 · px 24 · radius.l · border.strong · shadow.m (sanguine) · gold fill
/// - secondary: h 48 · px 20 · radius.l · border.ui · shadow.s (ink) · card fill
/// States: normal, pressed (slides by its shadow, shadow → 0), disabled (dashed border +
/// padlock + sunk fill — never opacity alone), loading (3 dots), badge, long text (2 lines).
public struct BistroButton: View {
    public enum Kind: Sendable { case primary, secondary }

    private let title: String
    private let kind: Kind
    private let isLoading: Bool
    private let badge: String?
    private let fullWidth: Bool
    private let action: () -> Void

    public init(_ title: String, kind: Kind = .primary, isLoading: Bool = false, badge: String? = nil,
                fullWidth: Bool = true, action: @escaping () -> Void) {
        self.title = title
        self.kind = kind
        self.isLoading = isLoading
        self.badge = badge
        self.fullWidth = fullWidth
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            Text(title)
        }
        .buttonStyle(BistroButtonStyle(kind: kind, isLoading: isLoading, fullWidth: fullWidth))
        .overlay(alignment: .topTrailing) {
            if let badge {
                Badge(.label(badge)).offset(x: Theme.Spacing.s1, y: -Theme.Spacing.s2)
            }
        }
        .allowsHitTesting(!isLoading)
    }
}

public struct BistroButtonStyle: ButtonStyle {
    let kind: BistroButton.Kind
    let isLoading: Bool
    let fullWidth: Bool
    @Environment(\.isEnabled) private var isEnabled

    public init(kind: BistroButton.Kind, isLoading: Bool = false, fullWidth: Bool = true) {
        self.kind = kind
        self.isLoading = isLoading
        self.fullWidth = fullWidth
    }

    public func makeBody(configuration: Configuration) -> some View {
        let shape = RoundedRectangle(cornerRadius: Theme.Radius.l)
        let pressed = configuration.isPressed && isEnabled
        let shadow = shadowToken
        return HStack(spacing: Theme.Spacing.s2) {
            if !isEnabled {
                Image(systemName: "lock.fill")
            }
            if isLoading {
                LoadingDots()
            } else {
                configuration.label
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
            }
        }
        .typography(Theme.Typography.labelButton)
        .foregroundStyle(isEnabled ? Theme.Colors.inkPrimary : Theme.Colors.inkDisabled)
        .padding(.horizontal, kind == .primary ? Theme.Spacing.s6 : Theme.Spacing.s5)
        .padding(.vertical, Theme.Spacing.s2)
        .frame(maxWidth: fullWidth ? .infinity : nil,
               minHeight: kind == .primary ? Theme.Size.buttonPrimaryHeight : Theme.Size.buttonSecondaryHeight)
        .background(shape.fill(fill))
        .overlay(
            shape.strokeBorder(isEnabled ? Theme.Colors.inkPrimary : Theme.Colors.inkDisabled,
                               style: StrokeStyle(lineWidth: kind == .primary ? Theme.Border.strong : Theme.Border.ui,
                                                  dash: isEnabled ? [] : [6, 4]))
        )
        .inkShadow(shadow, in: shape, pressed: pressed)
        .offset(x: pressed ? shadow.x : 0, y: pressed ? shadow.y : 0)
        .animation(Theme.Motion.easeOut(Theme.Motion.instant), value: pressed)
        .contentShape(shape)
    }

    private var fill: Color {
        guard isEnabled else { return Theme.Colors.surfaceSunk }
        return kind == .primary ? Theme.Colors.accentGold : Theme.Colors.surfaceCard
    }

    private var shadowToken: Theme.InkShadow {
        guard isEnabled else { return Theme.InkShadow(color: .clear, x: 0, y: 0) }
        return kind == .primary ? Theme.Shadow.m : Theme.Shadow.s
    }
}

/// "En attente" state: three dots filling in turn.
struct LoadingDots: View {
    var body: some View {
        TimelineView(.periodic(from: .now, by: 0.3)) { context in
            let step = Int(context.date.timeIntervalSinceReferenceDate / 0.3) % 3
            HStack(spacing: Theme.Spacing.s1) {
                ForEach(0..<3, id: \.self) { i in
                    Circle()
                        .frame(width: 7, height: 7)
                        .opacity(i <= step ? 1 : 0.3)
                }
            }
        }
        .accessibilityLabel(Text(L10n.string("common.loading")))
    }
}

#Preview("Buttons") {
    VStack(spacing: Theme.Spacing.s5) {
        BistroButton("Préparer") {}
        BistroButton("Préparer") {}.disabled(true)
        BistroButton("Préparer", isLoading: true) {}
        BistroButton("Voir le carnet", badge: "Nouveau") {}
        BistroButton("Récupérer les gains de la nuit, avec un texte très long") {}
        BistroButton("Plus tard", kind: .secondary) {}
        BistroButton("Plus tard", kind: .secondary) {}.disabled(true)
    }
    .padding(Theme.Layout.defaultMargin)
    .background(Theme.Colors.bgPaper)
    .onAppear { BistroFonts.register() }
}
