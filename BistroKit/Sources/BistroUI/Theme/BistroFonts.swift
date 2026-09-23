import CoreText
import Foundation

/// Registers the bundled OFL fonts (Bricolage Grotesque, IBM Plex Mono) at runtime.
/// Swift packages cannot declare fonts in an Info.plist, so this is done once at launch.
/// If registration fails, SwiftUI silently falls back to the system font.
public enum BistroFonts {
    nonisolated(unsafe) private static var registered = false
    private static let lock = NSLock()

    public static func register() {
        lock.lock(); defer { lock.unlock() }
        guard !registered else { return }
        registered = true
        let urls = (Bundle.module.urls(forResourcesWithExtension: "ttf", subdirectory: nil) ?? [])
            + (Bundle.module.urls(forResourcesWithExtension: "ttf", subdirectory: "Fonts") ?? [])
        for url in urls {
            CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
        }
    }
}
