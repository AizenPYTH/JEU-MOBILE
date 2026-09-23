import SwiftUI
import GameCore

/// Provisional restaurant (until the SpriteKit scene of M2): the dining room and the kitchen
/// as readable panels, with the design sketches as art. Tap coins to collect, tap a station
/// to speed it up.
struct RestaurantPreviewView: View {
    let store: GameStore

    private var state: GameState { store.state }

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.s5) {
                if let problem = store.saveProblem {
                    Text(problem)
                        .typography(Theme.Typography.caption)
                        .foregroundStyle(Theme.Colors.inkInverse)
                        .padding(Theme.Spacing.s3)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(RoundedRectangle(cornerRadius: Theme.Radius.m).fill(Theme.Colors.surfaceInverse))
                }
                diningRoom
                kitchen
            }
            .padding(.horizontal, Theme.Layout.defaultMargin)
            .padding(.vertical, Theme.Spacing.s4)
        }
    }

    // MARK: Dining room

    private var diningRoom: some View {
        Panel(L10n.string("section.tables")) {
            ForEach(state.tables) { table in
                HStack(spacing: Theme.Spacing.s3) {
                    tableArt(table)
                    VStack(alignment: .leading, spacing: Theme.Spacing.s1) {
                        Text(L10n.format("table.name", table.id + 1))
                            .typography(Theme.Typography.titleS)
                            .foregroundStyle(Theme.Colors.inkPrimary)
                        Text(status(of: table))
                            .typography(Theme.Typography.caption)
                            .foregroundStyle(Theme.Colors.inkSecondary)
                    }
                    Spacer(minLength: Theme.Spacing.s2)
                    if table.pendingCoins > 0 {
                        coinButton(table)
                    }
                }
                if table.id < state.tables.count - 1 {
                    Rectangle().fill(Theme.Colors.lineSoft).frame(height: Theme.Border.hair)
                }
            }
            if state.tables.filter({ $0.pendingCoins > 0 }).count > 1 {
                BistroButton(L10n.string("button.collectAll"), kind: .secondary) { store.collectAll() }
            }
        }
    }

    private func tableArt(_ table: TableState) -> some View {
        Group {
            if let customer = table.customer, let recipe = customer.recipe, customer.phase != .choosing {
                GameImage(AssetName.dish(recipe))
            } else if table.customer != nil {
                GameImage(AssetName.uiIcon("customer"))
                    .padding(Theme.Spacing.s3)
            } else {
                GameImage(AssetName.uiIcon("table"))
                    .padding(Theme.Spacing.s3)
                    .opacity(0.5)
            }
        }
        .frame(width: Theme.Size.stationThumb * 0.8, height: Theme.Size.stationThumb * 0.8)
    }

    /// Tip bubble (ui_bubble_tip): coin + amount, tap to collect.
    private func coinButton(_ table: TableState) -> some View {
        Button {
            store.collect(table: table.id)
        } label: {
            HStack(spacing: Theme.Spacing.s1) {
                GameImage(AssetName.currency(.coins))
                    .frame(width: Theme.Size.iconS, height: Theme.Size.iconS)
                Text(verbatim: "+" + CompactNumber.format(table.pendingCoins, style: L10n.numberStyle))
                    .typography(Theme.Typography.numberHud)
                    .foregroundStyle(Theme.Colors.inkPrimary)
            }
            .padding(.horizontal, Theme.Spacing.s3)
            .frame(minHeight: Theme.Layout.hit)
            .background(Capsule().fill(Theme.Colors.surfaceCard))
            .overlay(Capsule().strokeBorder(Theme.Colors.inkPrimary, lineWidth: Theme.Border.ui))
            .inkShadow(Theme.Shadow.reward, in: Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(L10n.format("a11y.tip", table.pendingCoins)))
    }

    private func status(of table: TableState) -> String {
        guard let customer = table.customer else {
            return table.pendingCoins > 0 ? L10n.string("table.coinsWaiting") : L10n.string("table.empty")
        }
        let dish = customer.recipe.map(L10n.dishName) ?? ""
        switch customer.phase {
        case .choosing: return L10n.string("customer.choosing")
        case .waitingForFood: return L10n.format("customer.waiting", dish)
        case .eating: return L10n.format("customer.eating", dish)
        }
    }

    // MARK: Kitchen

    private var kitchen: some View {
        Panel(L10n.string("section.kitchen")) {
            ForEach(state.stations) { station in
                Button {
                    store.boost(station.id)
                } label: {
                    HStack(spacing: Theme.Spacing.s3) {
                        GameImage(AssetName.station(station.id, level: station.level))
                            .frame(width: Theme.Size.stationThumb, height: Theme.Size.stationThumb)
                        VStack(alignment: .leading, spacing: Theme.Spacing.s2) {
                            HStack {
                                Text(L10n.stationName(station.id))
                                    .typography(Theme.Typography.titleS)
                                    .foregroundStyle(Theme.Colors.inkPrimary)
                                Spacer()
                                if !station.queue.isEmpty {
                                    Badge(.count(station.queue.count))
                                        .accessibilityLabel(Text(L10n.format("station.queue", station.queue.count)))
                                }
                            }
                            ProgressGauge(station.progress)
                            Text(station.current.map { L10n.format("station.cooking", L10n.dishName($0.recipe)) }
                                 ?? L10n.string("station.idle"))
                                .typography(Theme.Typography.caption)
                                .foregroundStyle(Theme.Colors.inkSecondary)
                        }
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
            Text(L10n.string("station.tapHint"))
                .typography(Theme.Typography.caption)
                .foregroundStyle(Theme.Colors.inkSecondary)
            Rectangle().fill(Theme.Colors.lineSoft).frame(height: Theme.Border.hair)
            HStack(spacing: Theme.Spacing.s3) {
                GameImage(AssetName.staff(.waiter, state.waiter.delivering == nil ? .idle : .walking))
                    .frame(width: Theme.Size.stationThumb * 0.6, height: Theme.Size.stationThumb * 0.8)
                Text(state.waiter.delivering.map { L10n.format("waiter.delivering", L10n.dishName($0.recipe)) }
                     ?? L10n.string("waiter.idle"))
                    .typography(Theme.Typography.bodyM)
                    .foregroundStyle(Theme.Colors.inkPrimary)
            }
        }
    }
}
