import SwiftUI
import GameCore

/// App entry screen: loads the game, runs it while the app is active, saves when it is not.
public struct RootView: View {
    @State private var store: GameStore?
    @State private var loadError: String?
    @Environment(\.scenePhase) private var scenePhase

    public init() {
        BistroFonts.register()
    }

    public var body: some View {
        Group {
            if let store {
                MainView(store: store)
            } else if let loadError {
                VStack(spacing: Theme.Spacing.s3) {
                    Text(L10n.string("error.content"))
                        .typography(Theme.Typography.titleS)
                        .foregroundStyle(Theme.Colors.stateAlert)
                    Text(verbatim: loadError)
                        .typography(Theme.Typography.caption)
                        .foregroundStyle(Theme.Colors.inkSecondary)
                }
                .padding(Theme.Spacing.s6)
            } else {
                GameImage(AssetName.ui("lab_pot"))
                    .frame(width: Theme.Size.labPot.width, height: Theme.Size.labPot.height)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.Colors.bgPaper.ignoresSafeArea())
        .task { load() }
        .onChange(of: scenePhase) { _, phase in
            switch phase {
            case .active: store?.start()
            case .inactive, .background: store?.stop()
            @unknown default: break
            }
        }
    }

    private func load() {
        guard store == nil, loadError == nil else { return }
        do {
            let store = try GameStore.live()
            store.start()
            self.store = store
        } catch {
            loadError = String(describing: error)
        }
    }
}

#Preview {
    RootView()
}
