import SwiftUI

/// badge: sanguine with a 2.5 paper outline — dot (14), counter (22, "99+" cap) or label (22).
public struct Badge: View {
    public enum Kind: Sendable {
        case dot
        case count(Int)
        case label(String)
    }

    private let kind: Kind

    public init(_ kind: Kind) {
        self.kind = kind
    }

    public var body: some View {
        switch kind {
        case .dot:
            Circle()
                .fill(Theme.Colors.accentSanguine)
                .overlay(Circle().strokeBorder(Theme.Colors.surfaceCard, lineWidth: Theme.Border.ui))
                .frame(width: Theme.Size.badgeDot, height: Theme.Size.badgeDot)
        case .count(let count):
            pill(count > 99 ? "99+" : "\(count)")
        case .label(let text):
            pill(text)
        }
    }

    private func pill(_ text: String) -> some View {
        Text(text)
            .typography(Theme.Typography.labelTab)
            .foregroundStyle(Theme.Colors.inkInverse)
            .padding(.horizontal, Theme.Spacing.s2)
            .frame(minWidth: Theme.Size.badgeCounter, minHeight: Theme.Size.badgeCounter)
            .background(Capsule().fill(Theme.Colors.accentSanguine))
            .overlay(Capsule().strokeBorder(Theme.Colors.surfaceCard, lineWidth: Theme.Border.ui))
    }
}

#Preview {
    HStack(spacing: Theme.Spacing.s4) {
        Badge(.dot)
        Badge(.count(3))
        Badge(.count(150))
        Badge(.label("Nouveau"))
    }
    .padding()
    .background(Theme.Colors.bgPaper)
}
