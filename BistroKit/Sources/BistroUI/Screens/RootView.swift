import SwiftUI
import GameCore
import GameData

/// App entry screen. M0: proves the wiring (content loading, theme, localization,
/// asset fallback). Replaced by the restaurant scene in M2.
public struct RootView: View {
    private let content: GameContent?

    public init() {
        content = try? GameData.loadContent()
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                Text(L10n.string("app.title"))
                    .font(Theme.Typography.display)
                    .foregroundStyle(Theme.Colors.textPrimary)
                Text(L10n.string("app.tagline"))
                    .font(Theme.Typography.body)
                    .foregroundStyle(Theme.Colors.textSecondary)

                if let content {
                    section(title: L10n.string("debug.ingredients")) {
                        grid(content.ingredients.map { Tile(asset: AssetName.ingredient($0.id), label: L10n.ingredientName($0.id)) })
                    }
                    section(title: L10n.string("debug.regulars")) {
                        grid(content.regulars.map { Tile(asset: AssetName.character($0.id, .portrait), label: L10n.regularName($0.id)) })
                    }
                } else {
                    Text(L10n.string("error.content"))
                        .foregroundStyle(Theme.Colors.danger)
                }
            }
            .padding(Theme.Spacing.lg)
        }
        .background(Theme.Colors.background.ignoresSafeArea())
    }

    private func section<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text(title)
                .font(Theme.Typography.headline)
                .foregroundStyle(Theme.Colors.textPrimary)
            content()
        }
    }

    private struct Tile {
        let asset: String
        let label: String
    }

    private func grid(_ items: [Tile]) -> some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: Theme.Size.ingredientTile), spacing: Theme.Spacing.sm)],
                  spacing: Theme.Spacing.sm) {
            ForEach(items, id: \.asset) { item in
                VStack(spacing: Theme.Spacing.xs) {
                    GameImage(item.asset)
                        .frame(width: Theme.Size.ingredientTile, height: Theme.Size.ingredientTile)
                    Text(item.label)
                        .font(Theme.Typography.caption)
                        .foregroundStyle(Theme.Colors.textSecondary)
                }
            }
        }
    }
}

#Preview {
    RootView()
}
