import SwiftUI

/// App entry screen: loads the game, runs it while the app is active, saves when it is not.
public struct RootView: View {
    @State private var store: GameStore?
    @State private var loadError: String?
    @Environment(\.scenePhase) private var scenePhase

    public init() {}

    public var body: some View {
        Group {
            if let store {
                DashboardView(store: store)
            } else if let loadError {
                VStack(spacing: Theme.Spacing.md) {
                    Text(L10n.string("error.content"))
                        .font(Theme.Typography.headline)
                        .foregroundStyle(Theme.Colors.danger)
                    Text(verbatim: loadError)
                        .font(Theme.Typography.caption)
                        .foregroundStyle(Theme.Colors.textSecondary)
                }
                .padding(Theme.Spacing.xl)
            } else {
                ProgressView()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.Colors.background.ignoresSafeArea())
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
