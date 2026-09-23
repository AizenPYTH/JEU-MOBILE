import SwiftUI
import GameCore
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// Displays a game asset by name (always built with `AssetName`).
///
/// If the asset is missing from the catalogs, shows a visible placeholder with the asset
/// name instead of crashing or showing nothing — so missing art is obvious during testing.
public struct GameImage: View {
    private let name: String

    public init(_ name: String) {
        self.name = name
    }

    public var body: some View {
        if let image = Self.load(name) {
            image.resizable().scaledToFit()
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

/// Placeholder for a missing asset: tinted shape + asset name. Color is stable per name.
public struct AssetPlaceholder: View {
    let name: String

    public init(name: String) {
        self.name = name
    }

    public var body: some View {
        RoundedRectangle(cornerRadius: Theme.Radius.sm)
            .fill(Self.tint(for: name).opacity(0.35))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.sm)
                    .strokeBorder(Theme.Colors.placeholderStroke, style: StrokeStyle(lineWidth: 1, dash: [4, 3]))
            )
            .overlay(
                Text(verbatim: name)
                    .font(Theme.Typography.tiny)
                    .foregroundStyle(Theme.Colors.textPrimary)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.5)
                    .padding(Theme.Spacing.xs)
            )
            .accessibilityLabel(Text(verbatim: name))
    }

    /// Deterministic (unlike `hashValue`) so a given asset always gets the same color.
    static func tint(for name: String) -> Color {
        let palette = [Theme.Colors.primary, Theme.Colors.secondary, Theme.Colors.accent,
                       Theme.Colors.gems, Theme.Colors.affinity, Theme.Colors.success]
        let sum = name.unicodeScalars.reduce(0) { $0 &+ Int($1.value) }
        return palette[sum % palette.count]
    }
}

#Preview("Missing assets") {
    HStack(spacing: Theme.Spacing.md) {
        GameImage(AssetName.ingredient("tomato")).frame(width: 72, height: 72)
        GameImage(AssetName.dish("bruschetta")).frame(width: 72, height: 72)
        GameImage(AssetName.character("margot", .portrait)).frame(width: 72, height: 72)
    }
    .padding()
    .background(Theme.Colors.background)
}
