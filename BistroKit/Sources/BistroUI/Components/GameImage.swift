import SwiftUI
import GameCore
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// Displays a game asset by name (always built with `AssetName`).
///
/// Lookup order:
/// 1. the app's asset catalog (`Bistro/Assets.xcassets`) — final illustrations go there (M9);
/// 2. the design sketches bundled in BistroUI (`Resources/Sketches.xcassets`, from the handoff);
/// 3. for currencies: the design's shapes (gold coin = circle, verdigris gem = diamond);
///    for `ui_icon_*`: an SF Symbol stand-in;
/// 4. otherwise a visible placeholder (shape + asset name), never a crash.
public struct GameImage: View {
    private let name: String

    public init(_ name: String) {
        self.name = name
    }

    public var body: some View {
        if let image = Self.load(name) {
            image.resizable().scaledToFit()
        } else if name == AssetName.currency(.coins) || name == AssetName.currency(.gems) {
            CurrencyGlyph(isGem: name == AssetName.currency(.gems))
        } else if let symbol = UIIconFallback.symbol(for: name) {
            Image(systemName: symbol)
                .resizable()
                .scaledToFit()
                .fontWeight(.bold)
                .foregroundStyle(Theme.Colors.inkPrimary)
        } else {
            AssetPlaceholder(name: name)
        }
    }

    static func load(_ name: String) -> Image? {
        #if canImport(UIKit)
        if let ui = UIImage(named: name, in: .main, with: nil) ?? UIImage(named: name, in: .module, with: nil) {
            return Image(uiImage: ui)
        }
        #elseif canImport(AppKit)
        if let ns = Bundle.main.image(forResource: name) ?? Bundle.module.image(forResource: name) {
            return Image(nsImage: ns)
        }
        #endif
        return nil
    }
}

/// Coin / gem drawn from the design rules until `currency_coins` / `currency_gems` are delivered.
struct CurrencyGlyph: View {
    let isGem: Bool

    var body: some View {
        GeometryReader { geo in
            let side = min(geo.size.width, geo.size.height)
            Group {
                if isGem {
                    Rectangle()
                        .fill(Theme.Colors.currencyGem)
                        .overlay(Rectangle().strokeBorder(Theme.Colors.inkPrimary, lineWidth: Theme.Border.hair))
                        .rotationEffect(.degrees(45))
                        .frame(width: side * 0.68, height: side * 0.68)
                } else {
                    Circle()
                        .fill(Theme.Colors.currencyCoin)
                        .overlay(Circle().inset(by: side * 0.2).stroke(Theme.Colors.inkPrimary.opacity(0.35), lineWidth: Theme.Border.hair))
                        .overlay(Circle().strokeBorder(Theme.Colors.inkPrimary, lineWidth: Theme.Border.hair))
                        .frame(width: side * 0.9, height: side * 0.9)
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
    }
}

/// SF Symbols used until the `ui_icon_*` set is drawn (see HANDOFF_INTEGRATION.md).
enum UIIconFallback {
    static func symbol(for assetName: String) -> String? {
        let prefix = "ui_icon_"
        guard assetName.hasPrefix(prefix) else { return nil }
        return symbols[String(assetName.dropFirst(prefix.count))]
    }

    static let symbols: [String: String] = [
        "lab": "flask.fill", "book": "book.closed.fill", "upgrade": "arrow.up.circle.fill",
        "menu": "list.bullet.rectangle.fill", "shop": "bag.fill", "settings": "gearshape.fill",
        "close": "xmark", "back": "chevron.left", "lock": "lock.fill", "video": "play.rectangle.fill",
        "check": "checkmark", "heart": "heart.fill", "star": "star.fill", "clock": "clock.fill",
        "map": "map.fill", "gift": "gift.fill", "calendar": "calendar", "sound": "speaker.wave.2.fill",
        "music": "music.note", "vibration": "iphone.radiowaves.left.and.right", "globe": "globe",
        "restore": "arrow.clockwise", "shield": "checkmark.shield.fill", "info": "info.circle.fill",
        "hint": "lightbulb.fill", "grip": "line.3.horizontal", "plus": "plus", "people": "person.2.fill",
        "table": "table.furniture.fill", "flame": "flame.fill", "sparkle": "sparkles", "x2": "multiply.circle.fill",
        "customer": "person.fill",
    ]
}

/// Placeholder for a missing asset: dashed paper tile + asset name. Color is stable per name.
public struct AssetPlaceholder: View {
    let name: String

    public init(name: String) {
        self.name = name
    }

    public var body: some View {
        RoundedRectangle(cornerRadius: Theme.Radius.s)
            .fill(Self.tint(for: name).opacity(0.3))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.s)
                    .strokeBorder(Theme.Colors.inkSecondary, style: StrokeStyle(lineWidth: Theme.Border.hair, dash: [4, 3]))
            )
            .overlay(
                Text(verbatim: name)
                    .font(Theme.Typography.caption.font)
                    .foregroundStyle(Theme.Colors.inkPrimary)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.4)
                    .padding(Theme.Spacing.s1)
            )
            .accessibilityLabel(Text(verbatim: name))
    }

    /// Deterministic (unlike `hashValue`) so a given asset always gets the same ink.
    static func tint(for name: String) -> Color {
        let inks = [Theme.Colors.accentSanguine, Theme.Colors.accentVerdigris, Theme.Colors.accentGold, Theme.Colors.inkSecondary]
        let sum = name.unicodeScalars.reduce(0) { $0 &+ Int($1.value) }
        return inks[sum % inks.count]
    }
}

#Preview("Sketches, icons, placeholders") {
    HStack(spacing: Theme.Spacing.s3) {
        GameImage(AssetName.ingredient("tomato")).frame(width: 72, height: 72)
        GameImage(AssetName.character("margot", .portrait)).frame(width: 72, height: 72)
        GameImage(AssetName.uiIcon("lab")).frame(width: 30, height: 30)
        GameImage(AssetName.dish("lemon_tart")).frame(width: 72, height: 72)
    }
    .padding()
    .background(Theme.Colors.bgPaper)
}
