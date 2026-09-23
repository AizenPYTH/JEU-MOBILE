import SwiftUI
import GameCore

/// Screen 13 · Settings, M1 version: version/build (useful for TestFlight reports), stats
/// and the debug reset. Sound / music / vibration switches, language, purchases and legal
/// rows arrive with M8.
struct SettingsScreen: View {
    let store: GameStore
    let onClose: () -> Void

    private var stats: GameStats { store.state.stats }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.s5) {
                SheetHeader(L10n.string("settings.title"), onClose: onClose)

                Panel(L10n.string("settings.stats")) {
                    line(L10n.format("hud.served", stats.customersServed))
                    line(L10n.format("stats.coinsEarned", stats.coinsEarned))
                    line(L10n.format("stats.tips", stats.tipsEarned))
                    line(L10n.format("stats.playTime",
                                     Duration.seconds(stats.playSeconds).formatted(.time(pattern: .hourMinuteSecond))))
                }

                Panel(L10n.string("settings.debug")) {
                    BistroButton(L10n.string("debug.reset"), kind: .secondary) { store.resetGame() }
                }

                Text(L10n.format("settings.version", Self.appVersion, Self.buildNumber))
                    .typography(Theme.Typography.caption)
                    .foregroundStyle(Theme.Colors.inkSecondary)
                    .frame(maxWidth: .infinity)
            }
            .padding(Theme.Layout.defaultMargin)
        }
    }

    private func line(_ text: String) -> some View {
        Text(text)
            .typography(Theme.Typography.bodyM)
            .foregroundStyle(Theme.Colors.inkPrimary)
    }

    static var appVersion: String { Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "?" }
    static var buildNumber: String { Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "?" }
}
