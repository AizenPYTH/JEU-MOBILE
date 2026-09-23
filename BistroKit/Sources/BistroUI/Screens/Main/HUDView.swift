import SwiftUI
import GameCore

/// Top HUD: currencies (reading only) on the left, settings — the only rare action — on the right.
/// Gems (M7) and the reputation medal (M5) appear when those systems exist.
struct HUDView: View {
    let state: GameState
    let onSettings: () -> Void

    var body: some View {
        HStack(spacing: Theme.Spacing.s2) {
            CurrencyCounter(.coins, amount: state.coins)
            Spacer(minLength: Theme.Spacing.s2)
            Button(action: onSettings) {
                GameImage(AssetName.uiIcon("settings"))
                    .frame(width: Theme.Size.iconS, height: Theme.Size.iconS)
                    .frame(width: Theme.Size.settingsButton, height: Theme.Size.settingsButton)
                    .background(Circle().fill(Theme.Colors.surfaceCard))
                    .overlay(Circle().strokeBorder(Theme.Colors.inkPrimary, lineWidth: Theme.Border.ui))
                    .inkShadow(Theme.Shadow.s, in: Circle())
                    .frame(width: Theme.Layout.hit, height: Theme.Layout.hit)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text(L10n.string("settings.title")))
        }
        .padding(.horizontal, Theme.Layout.defaultMargin)
        .padding(.vertical, Theme.Spacing.s2)
    }
}
