import SwiftUI
import GameCore

/// Destinations reachable from the action bar (and settings from the HUD).
enum Destination: String, Identifiable, CaseIterable {
    case regulars, upgrades, lab, menu, shop, settings
    var id: String { rawValue }
}

/// Screen 1 · Main (docs/design « Bistro Ecran Principal »):
/// the restaurant fills the screen, the HUD floats on top (reading only + settings),
/// the action bar sits in the thumb zone with the raised Lab button in the middle.
/// Until the SpriteKit scene (M2), the restaurant is shown as readable panels.
struct MainView: View {
    let store: GameStore
    @State private var destination: Destination?

    var body: some View {
        ZStack(alignment: .bottom) {
            Theme.Colors.bgScene.ignoresSafeArea()
            RestaurantPreviewView(store: store)
                .safeAreaPadding(.bottom, Theme.Size.actionBarHeight)
            ActionBar { destination = $0 }
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            HUDView(state: store.state) { destination = .settings }
        }
        .sheet(item: $destination) { destination in
            screen(for: destination)
                .presentationDetents([.fraction(0.92)])
                .presentationCornerRadius(Theme.Radius.sheet)
                .presentationBackground(Theme.Colors.bgPaper)
                .presentationDragIndicator(.visible)
        }
    }

    @ViewBuilder
    private func screen(for destination: Destination) -> some View {
        let close = { self.destination = nil }
        switch destination {
        case .menu: MenuScreen(store: store, onClose: close)
        case .settings: SettingsScreen(store: store, onClose: close)
        case .regulars:
            ComingSoonScreen(title: L10n.string("coming.regulars.title"), message: L10n.string("coming.regulars.body"),
                             asset: AssetName.character("margot", .portrait), onClose: close)
        case .upgrades:
            ComingSoonScreen(title: L10n.string("coming.upgrades.title"), message: L10n.string("coming.upgrades.body"),
                             asset: AssetName.station("stove", level: 2), onClose: close)
        case .lab:
            ComingSoonScreen(title: L10n.string("coming.lab.title"), message: L10n.string("coming.lab.body"),
                             asset: AssetName.ui("lab_pot"), onClose: close)
        case .shop:
            ComingSoonScreen(title: L10n.string("coming.shop.title"), message: L10n.string("coming.shop.body"),
                             asset: AssetName.currency(.gems), onClose: close)
        }
    }
}

#Preview {
    MainView(store: .preview())
        .onAppear { BistroFonts.register() }
}
