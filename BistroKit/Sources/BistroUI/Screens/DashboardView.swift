import SwiftUI
import GameCore

/// Provisional M1 screen: a live, readable view of the whole game state.
/// Replaced by the SpriteKit restaurant scene + HUD in M2, but kept as a debug screen.
struct DashboardView: View {
    let store: GameStore

    private var state: GameState { store.state }

    var body: some View {
        VStack(spacing: 0) {
            hud
            ScrollView {
                VStack(spacing: Theme.Spacing.lg) {
                    if let problem = store.saveProblem {
                        Text(problem)
                            .font(Theme.Typography.caption)
                            .foregroundStyle(Theme.Colors.textOnPrimary)
                            .padding(Theme.Spacing.md)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Theme.Colors.danger, in: RoundedRectangle(cornerRadius: Theme.Radius.sm))
                    }
                    tables
                    kitchen
                    menu
                    stats
                    debug
                }
                .padding(Theme.Spacing.lg)
            }
        }
        .background(Theme.Colors.background.ignoresSafeArea())
    }

    // MARK: HUD

    private var hud: some View {
        HStack {
            CurrencyCounter(.coins, amount: state.coins)
            Spacer()
            Text(L10n.format("hud.served", state.stats.customersServed))
                .font(Theme.Typography.caption)
                .foregroundStyle(Theme.Colors.textSecondary)
        }
        .padding(.horizontal, Theme.Spacing.lg)
        .padding(.vertical, Theme.Spacing.sm)
        .background(Theme.Colors.surfaceMuted)
    }

    // MARK: Tables

    private var tables: some View {
        Card(L10n.string("section.tables")) {
            ForEach(state.tables) { table in
                HStack(spacing: Theme.Spacing.md) {
                    tableIcon(table)
                    VStack(alignment: .leading, spacing: Theme.Spacing.xxs) {
                        Text(L10n.format("table.name", table.id + 1))
                            .font(Theme.Typography.body)
                            .foregroundStyle(Theme.Colors.textPrimary)
                        Text(status(of: table))
                            .font(Theme.Typography.caption)
                            .foregroundStyle(Theme.Colors.textSecondary)
                    }
                    Spacer()
                    if table.pendingCoins > 0 {
                        Button {
                            store.collect(table: table.id)
                        } label: {
                            Text(verbatim: "+\(table.pendingCoins)")
                                .font(Theme.Typography.headline)
                                .foregroundStyle(Theme.Colors.textOnPrimary)
                                .padding(.horizontal, Theme.Spacing.md)
                                .frame(minHeight: Theme.Size.minTapTarget)
                                .background(Theme.Colors.coins, in: Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            if state.tables.contains(where: { $0.pendingCoins > 0 }) {
                Button(L10n.string("button.collectAll")) { store.collectAll() }
                    .font(Theme.Typography.caption)
                    .tint(Theme.Colors.primary)
            }
        }
    }

    @ViewBuilder
    private func tableIcon(_ table: TableState) -> some View {
        Group {
            if let customer = table.customer, let recipe = customer.recipe, customer.phase == .eating {
                GameImage(AssetName.dish(recipe))
            } else if table.customer != nil {
                GameImage(AssetName.uiIcon("customer"))
            } else {
                GameImage(AssetName.uiIcon("table"))
            }
        }
        .frame(width: Theme.Size.iconLg, height: Theme.Size.iconLg)
    }

    private func status(of table: TableState) -> String {
        guard let customer = table.customer else { return L10n.string("table.empty") }
        let dish = customer.recipe.map(L10n.dishName) ?? ""
        switch customer.phase {
        case .choosing: return L10n.string("customer.choosing")
        case .waitingForFood: return L10n.format("customer.waiting", dish)
        case .eating: return L10n.format("customer.eating", dish)
        }
    }

    // MARK: Kitchen

    private var kitchen: some View {
        Card(L10n.string("section.kitchen")) {
            ForEach(state.stations) { station in
                Button {
                    store.boost(station.id)
                } label: {
                    HStack(spacing: Theme.Spacing.md) {
                        GameImage(AssetName.station(station.id, level: station.level))
                            .frame(width: Theme.Size.iconLg, height: Theme.Size.iconLg)
                        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                            HStack {
                                Text(L10n.stationName(station.id))
                                    .font(Theme.Typography.body)
                                    .foregroundStyle(Theme.Colors.textPrimary)
                                Spacer()
                                if !station.queue.isEmpty {
                                    Text(L10n.format("station.queue", station.queue.count))
                                        .font(Theme.Typography.caption)
                                        .foregroundStyle(Theme.Colors.textSecondary)
                                }
                            }
                            ProgressView(value: station.progress)
                                .tint(Theme.Colors.secondary)
                            Text(station.current.map { L10n.format("station.cooking", L10n.dishName($0.recipe)) }
                                 ?? L10n.string("station.idle"))
                                .font(Theme.Typography.caption)
                                .foregroundStyle(Theme.Colors.textSecondary)
                        }
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
            Text(L10n.string("station.tapHint"))
                .font(Theme.Typography.tiny)
                .foregroundStyle(Theme.Colors.textSecondary)
            Divider()
            Text(state.waiter.delivering.map { L10n.format("waiter.delivering", L10n.dishName($0.recipe)) }
                 ?? L10n.string("waiter.idle"))
                .font(Theme.Typography.caption)
                .foregroundStyle(Theme.Colors.textSecondary)
        }
    }

    // MARK: Menu

    private var menu: some View {
        Card(L10n.string("section.menu")) {
            Text(L10n.format("menu.slots", state.menu.count, state.menuSlots))
                .font(Theme.Typography.caption)
                .foregroundStyle(Theme.Colors.textSecondary)
            ForEach(state.discoveredRecipes, id: \.self) { id in
                let onMenu = state.menu.contains(id)
                Button {
                    store.toggleMenu(id)
                } label: {
                    HStack(spacing: Theme.Spacing.md) {
                        GameImage(AssetName.dish(id))
                            .frame(width: Theme.Size.iconMd, height: Theme.Size.iconMd)
                        Text(L10n.dishName(id))
                            .font(Theme.Typography.body)
                            .foregroundStyle(Theme.Colors.textPrimary)
                        Spacer()
                        if let recipe = store.index.recipes[id] {
                            Text(verbatim: "\(recipe.basePrice)")
                                .font(Theme.Typography.caption)
                                .foregroundStyle(Theme.Colors.coins)
                        }
                        Image(systemName: onMenu ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(onMenu ? Theme.Colors.success : Theme.Colors.textSecondary)
                    }
                    .frame(minHeight: Theme.Size.minTapTarget)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: Stats & debug

    private var stats: some View {
        Card(L10n.string("section.stats")) {
            Text(L10n.format("stats.coinsEarned", state.stats.coinsEarned))
            Text(L10n.format("stats.tips", state.stats.tipsEarned))
            Text(L10n.format("stats.playTime",
                             Duration.seconds(state.stats.playSeconds).formatted(.time(pattern: .hourMinuteSecond))))
        }
        .font(Theme.Typography.caption)
        .foregroundStyle(Theme.Colors.textSecondary)
    }

    private var debug: some View {
        Card(L10n.string("section.debug")) {
            Button(L10n.string("debug.reset"), role: .destructive) { store.resetGame() }
                .font(Theme.Typography.caption)
        }
    }
}

#Preview {
    DashboardView(store: .preview())
}
