import SwiftUI

/// gauge.progress: h 12 · pill · gold fill with a dot screen (riso "trame").
public struct ProgressGauge: View {
    private let progress: Double

    public init(_ progress: Double) {
        self.progress = min(1, max(0, progress))
    }

    public var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Theme.Colors.surfaceSunk)
                Capsule()
                    .fill(Theme.Colors.accentGold)
                    .overlay(DotScreen(color: Theme.Colors.inkPrimary.opacity(0.25)).clipShape(Capsule()))
                    .frame(width: max(0, geo.size.width * progress))
            }
        }
        .frame(height: Theme.Size.progressHeight)
        .overlay(Capsule().strokeBorder(Theme.Colors.inkPrimary, lineWidth: Theme.Border.hair))
        .accessibilityElement()
        .accessibilityValue(Text("\(Int(progress * 100)) %"))
    }
}

/// Regular grid of small dots, the riso screen texture used on gold fills.
struct DotScreen: View {
    let color: Color
    var spacing: CGFloat = 5
    var radius: CGFloat = 1.2

    var body: some View {
        Canvas { context, size in
            var y = spacing / 2
            while y < size.height {
                var x = spacing / 2
                while x < size.width {
                    context.fill(Path(ellipseIn: CGRect(x: x - radius, y: y - radius, width: radius * 2, height: radius * 2)),
                                 with: .color(color))
                    x += spacing
                }
                y += spacing
            }
        }
        .allowsHitTesting(false)
    }
}

#Preview {
    VStack(spacing: Theme.Spacing.s4) {
        ProgressGauge(0)
        ProgressGauge(0.42)
        ProgressGauge(1)
    }
    .padding()
    .background(Theme.Colors.bgPaper)
}
