import SwiftUI
import GameCore

/// Icon + amount, used in the HUD and shop.
public struct CurrencyCounter: View {
    private let currency: AssetName.Currency
    private let amount: Int

    public init(_ currency: AssetName.Currency, amount: Int) {
        self.currency = currency
        self.amount = amount
    }

    public var body: some View {
        HStack(spacing: Theme.Spacing.xs) {
            GameImage(AssetName.currency(currency))
                .frame(width: Theme.Size.iconMd, height: Theme.Size.iconMd)
            Text(amount, format: .number)
                .font(Theme.Typography.number)
                .foregroundStyle(Theme.Colors.textPrimary)
                .contentTransition(.numericText())
        }
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.vertical, Theme.Spacing.xs)
        .background(Theme.Colors.surface, in: Capsule())
    }
}

#Preview {
    CurrencyCounter(.coins, amount: 12_345)
        .padding()
        .background(Theme.Colors.background)
}
