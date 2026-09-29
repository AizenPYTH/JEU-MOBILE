#if os(iOS)
import SwiftUI
import UIKit
import CaseEngine
import CaseLibrary

// MARK: - What the game needs before its first screen

/// Everything the desk needs, loaded once at launch.
struct BootData {
    var cases: [CaseFile] = []
    var rules: GameRules?
    var loadError: String?
    var attempts: [Attempt] = []
    var savedGame: SavedInvestigation?
}

/// The real start-up work: fonts, the player's saves, the rules, each case file (decoded off the
/// main thread), the interface sounds, the portraits. `boot` is published as soon as the game can
/// start (saves, rules, cases); `portraitsReady` once the pictures seen first (§F-01: case #001's
/// suspects, the investigators) are decoded. The other cases' portraits follow in the background.
@MainActor
@Observable
final class LaunchLoader {
    private(set) var boot: BootData?
    private(set) var portraitsReady = false

    private var started = false

    init() {
        // Before the first frame, so the launch screen's label is already set in Plex Mono.
        AppFonts.register()
    }

    func run() async {
        guard !started else { return }
        started = true
        let caseURLs = (try? FileManager.default.contentsOfDirectory(at: CaseLibrary.casesDirectory, includingPropertiesForKeys: nil))?
            .filter { $0.pathExtension == "json" }
            .sorted { $0.lastPathComponent < $1.lastPathComponent } ?? []
        var data = BootData()

        UITestHooks.applyAtLaunch()
        data.attempts = ProgressStore.attempts()
        data.savedGame = SavedInvestigationStore.load()
        // Players of earlier versions keep their desk: already assigned to the BEN.
        PlayerStore.migrate(attempts: data.attempts)

        do {
            data.rules = try await Task.detached(priority: .userInitiated) { try CaseLibrary.loadRules() }.value
        } catch {
            data.loadError = String(describing: error)
        }

        var cases: [CaseFile] = []
        for url in caseURLs {
            do {
                let file = try await Task.detached(priority: .userInitiated) { () throws -> CaseFile in
                    guard let bytes = try? Data(contentsOf: url) else { throw CaseLoadError.missingFile(url.lastPathComponent) }
                    return try CaseLoader.loadCase(bytes, name: url.lastPathComponent)
                }.value
                cases.append(file)
            } catch {
                data.loadError = data.loadError ?? String(describing: error)
            }
        }
        if caseURLs.isEmpty { data.loadError = data.loadError ?? "Cases" }
        data.cases = data.loadError == nil ? cases.sorted { $0.number < $1.number } : []
        if data.loadError != nil { data.rules = nil }

        AudioDirector.shared.warmUp()
        await Task.yield()

        // The game can start: the launch screen leaves once its minimum time is over.
        boot = data

        // First the pictures seen first: the case in progress (or #001), then the investigators.
        let loaded = data.cases
        let inProgress = data.savedGame.flatMap { game in loaded.first { $0.id == game.snapshot.caseID } }
        let first = inProgress ?? loaded.first { $0.number == 1 } ?? loaded.first
        await ArtLibrary.warmUp(names: ArtLibrary.launchNames(first: first))
        portraitsReady = true

        // Then every other case's portraits, once the next screen has faded in, one per turn.
        Task {
            try? await Task.sleep(for: .seconds(1.5))
            await ArtLibrary.warmUp(portraitsOf: loaded)
        }
    }
}

// MARK: - 01 · Lancement

/// Screen 01 (final handoff §F-01, UX V3 colours): the logo tile on the flat BEN background #0B0E13
/// (the system launch screen's « LaunchBackground »), exactly where the system launch screen drew it
/// (188 pt, centred in the whole screen), no paper, and « NOREL GAMES » 58 pt from the bottom
/// edge. No bar, no spinner. It stays at least 1.6 s; it leaves when the game can start and the
/// first portraits are decoded, and never waits past 4 s for the portraits (they fall back to
/// initials). Then the logo fades to black (250 ms) and RootView fades the next screen in (350 ms).
struct LoadingScreen: View {
    let loader: LaunchLoader
    let onFinished: (BootData) -> Void

    @State private var leaving = false

    /// Shortest time on screen, so the brand is seen even on a fast iPhone.
    private static let minimumDuration: Duration = .milliseconds(1600)
    /// Longest wait for the portraits (the case files themselves are always waited for).
    private static let maximumDuration: Duration = .seconds(4)
    /// Fade to black before handing over.
    private static let fadeOut: Duration = .milliseconds(250)
    private static let tileSize: CGFloat = 188
    private static let studioBottom: CGFloat = 58
    /// The studio's name: not translated.
    private static let studio = "NOREL GAMES"
    /// Plex Mono 10, tracking +32 %.
    private static let studioFont = Font.custom(Trace.FontName.mono, fixedSize: 10)
    private static let studioTracking: CGFloat = 3.2

    var body: some View {
        ZStack {
            Trace.Colors.bg
            LogoTile(size: Self.tileSize)
                .opacity(leaving ? 0 : 1)
            Text(verbatim: Self.studio)
                .font(Self.studioFont)
                .tracking(Self.studioTracking)
                .foregroundStyle(Trace.Colors.text3)
                .opacity(leaving ? 0 : 1)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                .padding(.bottom, Self.studioBottom)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(L10n.t("launch.loading")))
        .accessibilityIdentifier("launch.loading")
        .task { await loader.run() }
        .task { await drive() }
    }

    /// Waits for the case files (however long), the minimum time, and the first portraits (at most
    /// until the maximum time), then fades to black and hands the boot data over.
    private func drive() async {
        let clock = ContinuousClock()
        let start = clock.now
        while !Task.isCancelled {
            let elapsed = start.duration(to: clock.now)
            if loader.boot != nil, elapsed >= Self.minimumDuration,
               loader.portraitsReady || elapsed >= Self.maximumDuration {
                break
            }
            try? await Task.sleep(for: .milliseconds(40))
        }
        guard !Task.isCancelled, let boot = loader.boot else { return }
        withAnimation(.easeIn(duration: 0.25)) { leaving = true }
        try? await Task.sleep(for: Self.fadeOut)
        onFinished(boot)
    }
}
#endif
