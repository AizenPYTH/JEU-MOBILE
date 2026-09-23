import SwiftUI
import GameCore

/// Screen 5 · Menu management (docs/design « Bistro Ecrans » 5a), M1 version:
/// tap to add / remove. Drag & drop, estimated revenue and locked slots come with M3.
struct MenuScreen: View {
    let store: GameStore
    let onClose: () -> Void

    private var state: GameState { store.state }
    private var available: [RecipeID] { state.discoveredRecipes.filter { !state.menu.contains($0) } }
    private var isFull: Bool { state.menu.count >= state.menuSlots }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.s5) {
                SheetHeader(L10n.string("menu.title"), onClose: onClose)

                sectionTitle(L10n.string("menu.onMenu"), trailing: "\(state.menu.count) / \(state.menuSlots)")
                VStack(spacing: Theme.Spacing.s3) {
                    ForEach(state.menu, id: \.self) { id in
                        row(id, onMenu: true)
                    }
                    ForEach(0..<max(0, state.menuSlots - state.menu.count), id: \.self) { _ in
                        emptySlot
                    }
                }

                sectionTitle(L10n.string("menu.available"), trailing: "\(available.count)")
                if available.isEmpty {
                    Text(L10n.string("menu.noneAvailable"))
                        .typography(Theme.Typography.bodyM)
                        .foregroundStyle(Theme.Colors.inkSecondary)
                } else {
                    if isFull {
                        Text(L10n.string("menu.full"))
                            .typography(Theme.Typography.caption)
                            .foregroundStyle(Theme.Colors.inkSecondary)
                    }
                    VStack(spacing: Theme.Spacing.s3) {
                        ForEach(available, id: \.self) { id in
                            row(id, onMenu: false)
                        }
                    }
                }
            }
            .padding(Theme.Layout.defaultMargin)
        }
    }

    private func sectionTitle(_ title: String, trailing: String) -> some View {
        HStack {
            Text(title)
                .typography(Theme.Typography.titleS)
                .foregroundStyle(Theme.Colors.inkPrimary)
            Spacer()
            Text(verbatim: trailing)
                .typography(Theme.Typography.numberHud)
                .foregroundStyle(Theme.Colors.inkSecondary)
        }
    }

    private func row(_ id: RecipeID, onMenu: Bool) -> some View {
        let shape = RoundedRectangle(cornerRadius: Theme.Radius.m)
        let recipe = store.index.recipes[id]
        let canAdd = onMenu || !isFull
        return HStack(spacing: Theme.Spacing.s3) {
            GameImage(AssetName.dish(id))
                .frame(width: Theme.Size.menuRowHeight - Theme.Spacing.s4, height: Theme.Size.menuRowHeight - Theme.Spacing.s4)
            VStack(alignment: .leading, spacing: Theme.Spacing.s1) {
                Text(L10n.dishName(id))
                    .typography(Theme.Typography.titleS)
                    .foregroundStyle(Theme.Colors.inkPrimary)
                    .lineLimit(2)
                if let recipe {
                    HStack(spacing: Theme.Spacing.s1) {
                        GameImage(AssetName.currency(.coins))
                            .frame(width: Theme.Size.iconS * 0.8, height: Theme.Size.iconS * 0.8)
                        Text(verbatim: "\(recipe.basePrice)")
                            .typography(Theme.Typography.numberHud)
                        GameImage(AssetName.uiIcon("clock"))
                            .frame(width: Theme.Size.iconS * 0.7, height: Theme.Size.iconS * 0.7)
                            .padding(.leading, Theme.Spacing.s2)
                        Text(Duration.seconds(recipe.prepSeconds).formatted(.time(pattern: .minuteSecond)))
                            .typography(Theme.Typography.numberHud)
                    }
                    .foregroundStyle(Theme.Colors.inkSecondary)
                }
            }
            Spacer(minLength: Theme.Spacing.s2)
            Button {
                store.toggleMenu(id)
            } label: {
                Image(systemName: onMenu ? "minus" : (canAdd ? "plus" : "lock.fill"))
                    .fontWeight(.heavy)
                    .foregroundStyle(canAdd ? Theme.Colors.inkPrimary : Theme.Colors.inkDisabled)
                    .frame(width: Theme.Layout.hit, height: Theme.Layout.hit)
                    .background(Circle().fill(onMenu ? Theme.Colors.surfaceSunk : Theme.Colors.accentGold))
                    .overlay(Circle().strokeBorder(Theme.Colors.inkPrimary, lineWidth: Theme.Border.ui))
            }
            .buttonStyle(.plain)
            .disabled(!canAdd || (onMenu && state.menu.count <= 1))
            .accessibilityLabel(Text(L10n.format(onMenu ? "menu.remove" : "menu.add", L10n.dishName(id))))
        }
        .padding(.horizontal, Theme.Spacing.s3)
        .frame(minHeight: Theme.Size.menuRowHeight)
        .background(shape.fill(Theme.Colors.surfaceCard))
        .overlay(shape.strokeBorder(Theme.Colors.inkPrimary, lineWidth: Theme.Border.ui))
        .inkShadow(Theme.Shadow.s, in: shape)
    }

    private var emptySlot: some View {
        let shape = RoundedRectangle(cornerRadius: Theme.Radius.m)
        return Text(L10n.string("menu.freeSlot"))
            .typography(Theme.Typography.bodyM)
            .foregroundStyle(Theme.Colors.inkSecondary)
            .frame(maxWidth: .infinity, minHeight: Theme.Size.menuRowHeight)
            .background(shape.fill(Theme.Colors.surfaceSunk))
            .overlay(shape.strokeBorder(Theme.Colors.inkSecondary, style: StrokeStyle(lineWidth: Theme.Border.hair, dash: [6, 4])))
    }
}

#Preview {
    MenuScreen(store: .preview(), onClose: {})
        .background(Theme.Colors.bgPaper)
        .onAppear { BistroFonts.register() }
}
