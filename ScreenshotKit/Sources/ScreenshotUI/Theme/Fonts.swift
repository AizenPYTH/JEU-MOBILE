#if os(iOS)
import CoreText
import Foundation

/// Registers the bundled OFL fonts (Geist, JetBrains Mono, Instrument Serif) at launch.
/// Swift packages cannot declare fonts in Info.plist; if registration fails, SwiftUI falls back
/// to the system font.
enum AppFonts {
    nonisolated(unsafe) private static var registered = false
    private static let lock = NSLock()

    static func register() {
        lock.lock(); defer { lock.unlock() }
        guard !registered else { return }
        registered = true
        let urls = (Bundle.module.urls(forResourcesWithExtension: "ttf", subdirectory: nil) ?? [])
            + (Bundle.module.urls(forResourcesWithExtension: "ttf", subdirectory: "Fonts") ?? [])
        for url in urls { CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil) }
    }
}
#endif
