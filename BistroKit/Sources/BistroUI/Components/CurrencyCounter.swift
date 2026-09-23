import SwiftUI
import GameCore

/// hud.currency: h 38 · pill · icon 26 · type.number.hud · max 6 characters (compact units).
/// Optional "+" shortcut (gems → shop).
public struct CurrencyCounter: View {
    private let currency: AssetName.Currency
    private let amount: Int
    private let onPlus: (() -> Void)?

    public init(_ currency: AssetName.Currency, amount: Int, onPlus: (() -> Void)? = nil) {
        self.currency = currency
        self.amount = amount
        self.onPlus = onPlus
    }

    public var body: some View {
        let shape = Capsule()
        HStack(spacing: Theme.Spacing.s1) {
            GameImage(AssetName.currency(currency))
                .frame(width: Theme.Size.hudIcon, height: Theme.Size.hudIcon)
            Text(CompactNumber.format(amount, style: L10n.numberStyle))
                .typography(Theme.Typography.numberHud)
                .foregroundStyle(Theme.Colors.inkPrimary)
                .contentTransition(.numericText())
                .animation(Theme.Motion.easeInOut(Theme.Motion.coinCollect), value: amount)
            if let onPlus {
                Button(action: onPlus) {
                    Image(systemName: "plus")
                        .fontWeight(.heavy)
                        .foregroundStyle(Theme.Colors.inkPrimary)
                        .frame(width: Theme.Layout.hit, height: Theme.Layout.hit)
                }
                .buttonStyle(.plain)
                .padding(.vertical, -(Theme.Layout.hit - Theme.Size.hudCurrencyHeight) / 2)
            }
        }
        .padding(.leading, Theme.Spacing.s1)
        .padding(.trailing, onPlus == nil ? Theme.Spacing.s3 : 0)
        .frame(height: Theme.Size.hudCurrencyHeight)
        .background(shape.fill(Theme.Colors.surfaceCard))
        .overlay(shape.strokeBorder(Theme.Colors.inkPrimary, lineWidth: Theme.Border.ui))
        .inkShadow(Theme.Shadow.s, in: shape)
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    VStack(alignment: .leading, spacing: Theme.Spacing.s4) {
        CurrencyCounter(.coins, amount: 9_850)
        CurrencyCounter(.coins, amount: 12_400)
        CurrencyCounter(.coins, amount: 45_700_000_000)
        CurrencyCounter(.gems, amount: 86) {}
    }
    .padding()
    .background(Theme.Colors.bgPaper)
}
