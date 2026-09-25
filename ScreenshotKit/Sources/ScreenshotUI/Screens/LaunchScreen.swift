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

/// The real start-up work, step by step: fonts, the player's saves, the rules, each case file
/// (decoded off the main thread), the interface sounds, the delivered portraits. `progress` is the
/// share of that work actually done; the loading bar follows it.
@MainActor
@Observable
final class LaunchLoader {
    private(set) var progress: Double = 0
    private(set) var boot: BootData?

    private var done = 0.0
    private var total = 1.0
    private var started = false

    func run() async {
        guard !started else { return }
        started = true
        let caseURLs = (try? FileManager.default.contentsOfDirectory(at: CaseLibrary.casesDirectory, includingPropertiesForKeys: nil))?
            .filter { $0.pathExtension == "json" }
            .sorted { $0.lastPathComponent < $1.lastPathComponent } ?? []
        // Weights: a case file is the heaviest step.
        total = 1 + 1 + 1 + Double(caseURLs.count) * 3 + 1 + 1
        var data = BootData()

        AppFonts.register()
        await step(1)

        UITestHooks.applyAtLaunch()
        data.attempts = ProgressStore.attempts()
        data.savedGame = SavedInvestigationStore.load()
        await step(1)

        do {
            data.rules = try await Task.detached(priority: .userInitiated) { try CaseLibrary.loadRules() }.value
        } catch {
            data.loadError = String(describing: error)
        }
        await step(1)

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
            await step(3)
        }
        if caseURLs.isEmpty { data.loadError = data.loadError ?? "Cases" }
        data.cases = data.loadError == nil ? cases.sorted { $0.number < $1.number } : []
        if data.loadError != nil { data.rules = nil }

        AudioDirector.shared.warmUp()
        await step(1)

        await ArtLibrary.warmUp(portraitsOf: data.cases)
        await step(1)

        boot = data
    }

    /// Records a finished step and gives the screen a frame to show it.
    private func step(_ weight: Double) async {
        done += weight
        progress = min(1, done / total)
        await Task.yield()
    }
}

// MARK: - Loading screen

/// The loading screen: the key art full screen, and over the bar drawn in the art, a real bar
/// driven by `LaunchLoader`. It never finishes before the work is done, never flashes by on a fast
/// device (minimum time), then fades into the game.
struct LoadingScreen: View {
    let loader: LaunchLoader
    let onFinished: (BootData) -> Void

    @State private var shown: Double = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// The artwork and its drawn bar, in the artwork's pixels (941 × 1672).
    private enum Art {
        static let size = CGSize(width: 941, height: 1672)
        static let bar = CGRect(x: 188, y: 1446, width: 566, height: 28)
    }

    /// Shortest time on screen, so the art is seen and the bar is read, even on a fast iPhone.
    private static let minimumDuration: Double = 1.8

    var body: some View {
        GeometryReader { geo in
            let scale = max(geo.size.width / Art.size.width, geo.size.height / Art.size.height)
            let origin = CGPoint(x: (geo.size.width - Art.size.width * scale) / 2,
                                 y: (geo.size.height - Art.size.height * scale) / 2)
            let bar = CGRect(x: origin.x + Art.bar.minX * scale, y: origin.y + Art.bar.minY * scale,
                             width: Art.bar.width * scale, height: Art.bar.height * scale)
            ZStack(alignment: .topLeading) {
                background(size: geo.size)
                LoadingBar(progress: shown, shine: !reduceMotion)
                    .frame(width: bar.width, height: bar.height)
                    .offset(x: bar.minX, y: bar.minY)
            }
        }
        .ignoresSafeArea()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(L10n.t("launch.loading")))
        .accessibilityValue(Text("\(Int((shown * 100).rounded())) %"))
        .accessibilityIdentifier("launch.loading")
        .task { await loader.run() }
        .task { await drive() }
    }

    @ViewBuilder
    private func background(size: CGSize) -> some View {
        if let image = ArtLibrary.image("loading_main") {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: size.width, height: size.height)
                .clipped()
        } else {
            TraceDesk()
        }
    }

    /// Moves the bar toward the real progress, never faster than the minimum time allows.
    private func drive() async {
        let start = Date()
        while !Task.isCancelled {
            let elapsed = Date().timeIntervalSince(start)
            let target = min(loader.progress, elapsed / Self.minimumDuration)
            let gap = target - shown
            shown = gap < 0.002 ? max(shown, target) : shown + gap * 0.16
            if loader.boot != nil, shown >= 0.998 { break }
            try? await Task.sleep(for: .milliseconds(16))
        }
        shown = 1
        try? await Task.sleep(for: .milliseconds(380))
        if let boot = loader.boot { onFinished(boot) }
    }
}

/// The bar, drawn to replace the one in the artwork: a black channel with a thin worn rim, filled
/// with a deep red that brightens toward its leading edge, a faint glow, and (while loading) a slow
/// light running along the red.
struct LoadingBar: View {
    let progress: Double
    var shine = true

    var body: some View {
        GeometryReader { geo in
            let inset = geo.size.height * 0.16
            let width = max(geo.size.height - inset * 2, (geo.size.width - inset * 2) * progress)
            ZStack(alignment: .leading) {
                // Hides the bar and the red glow painted in the artwork.
                Capsule().fill(Trace.Colors.loadingTrack)
                    .padding(-geo.size.height * 0.35)
                    .blur(radius: geo.size.height * 0.3)
                Capsule().fill(Trace.Colors.loadingTrack)
                Capsule()
                    .fill(LinearGradient(colors: [Trace.Colors.loadingRedDeep, Trace.Colors.loadingRed, Trace.Colors.loadingRedHot],
                                         startPoint: .leading, endPoint: .trailing))
                    .frame(width: width)
                    .padding(inset)
                    .shadow(color: Trace.Colors.loadingRedHot.opacity(0.55), radius: geo.size.height * 0.35)
                    .overlay(alignment: .leading) {
                        if shine && progress < 1 {
                            Shine().frame(width: width).clipShape(Capsule()).padding(inset)
                        }
                    }
                    .opacity(progress > 0.001 ? 1 : 0)
                Capsule().strokeBorder(Trace.Colors.loadingRim, lineWidth: max(1, geo.size.height * 0.07))
            }
        }
    }

    /// A soft highlight crossing the filled part every 1.6 s.
    private struct Shine: View {
        var body: some View {
            TimelineView(.animation) { timeline in
                GeometryReader { geo in
                    let phase = timeline.date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 1.6) / 1.6
                    LinearGradient(colors: [.clear, Trace.Colors.label.opacity(0.28), .clear], startPoint: .leading, endPoint: .trailing)
                        .frame(width: max(24, geo.size.width * 0.25))
                        .offset(x: -geo.size.width * 0.25 + (geo.size.width * 1.25) * phase)
                }
            }
            .allowsHitTesting(false)
        }
    }
}
#endif
