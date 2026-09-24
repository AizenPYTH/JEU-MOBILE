#if os(iOS)
import SwiftUI
import CaseEngine

/// A photograph of the seized phone, painted from its scene key: real depth (out-of-focus
/// backgrounds, light sources, reflections), then what the camera did to it — a night shot's noise,
/// a selfie's flash, a quick shot's tilt, a blurry shot, an old print's faded colours, a document on
/// a desk, a screenshot of an app. No two photos share a layout (everything is seeded by the photo id).
/// People are never drawn: at most out-of-focus shapes against the light.
/// What matters for the investigation is in the caption / details text, not in pixels.
struct GeneratedPhoto: View, Equatable {
    let scene: String
    let seed: String
    var style: Photo.Style = .standard
    /// Legible text (documents, screenshots).
    var lines: [String] = []
    /// The date on an old print.
    var year: Int? = nil

    init(scene: String, seed: String, style: Photo.Style = .standard, lines: [String] = []) {
        self.scene = scene
        self.seed = seed
        self.style = style
        self.lines = lines
    }

    init(photo: Photo) {
        scene = photo.scene
        seed = photo.id
        style = photo.style ?? PhotoPainter.defaultStyle(for: photo.scene)
        lines = photo.lines ?? []
        year = photo.takenAt.year
    }

    var body: some View {
        let style = self.style
        ZStack {
            Canvas(rendersAsynchronously: true) { context, size in
                var rng = SeededRandom(seed: seed)
                PhotoPainter.paint(scene: scene, style: style, lines: lines, in: &context, size: size, rng: &rng)
            }
            .blur(radius: style == .blurry ? 5 : style == .quick ? 1.2 : 0)
            .scaleEffect(style == .quick ? 1.12 : 1)
            .rotationEffect(.degrees(style == .quick ? PhotoPainter.tilt(seed) : 0))
            // Film / sensor grain, heavier at night.
            Canvas(rendersAsynchronously: true) { context, size in
                var rng = SeededRandom(seed: seed + "grain")
                let density: CGFloat = style == .night || style == .blurry ? 26 : style == .old ? 34 : 60
                for _ in 0..<Int(size.width * size.height / density) {
                    let x = rng.next() * size.width, y = rng.next() * size.height
                    context.fill(Path(CGRect(x: x, y: y, width: 1, height: 1)),
                                 with: .color(.white.opacity(rng.next() * (style == .night ? 0.13 : 0.08))))
                }
            }
            .allowsHitTesting(false)
            // Lens vignette.
            RadialGradient(colors: [.clear, .black.opacity(style == .selfie ? 0.45 : 0.32)], center: .center, startRadius: 40, endRadius: 260)
                .blendMode(.multiply)
            if style == .selfie {
                // On-camera flash hot spot.
                RadialGradient(colors: [.white.opacity(0.16), .clear], center: UnitPoint(x: 0.5, y: 0.42), startRadius: 0, endRadius: 150)
                    .blendMode(.screen)
            }
            if style == .old {
                Color(hex: 0xC8A46A).opacity(0.28).blendMode(.overlay)
                Color(hex: 0xF3E6C8).opacity(0.10)
            }
        }
        .saturation(style == .old ? 0.45 : style == .screenshot || style == .document ? 0.95 : 0.78)
        .contrast(style == .old ? 0.82 : 1)
        .brightness(style == .night ? -0.04 : 0)
        .overlay {
            if style == .old {
                // The white border of a scanned print.
                Rectangle().strokeBorder(Color(hex: 0xEDE6D8).opacity(0.85), lineWidth: 5)
            }
        }
        .drawingGroup()
        .clipped()
        .accessibilityHidden(true)
    }

    nonisolated static func == (a: GeneratedPhoto, b: GeneratedPhoto) -> Bool {
        a.scene == b.scene && a.seed == b.seed && a.style == b.style && a.lines == b.lines
    }
}

// MARK: - Painter

/// Paints each kind of scene in layers: far (blurred) → near (sharp) → light.
enum PhotoPainter {
    typealias C = GraphicsContext

    static func defaultStyle(for scene: String) -> Photo.Style {
        switch scene {
        case "screenshot": .screenshot
        case "document": .document
        case "street_night", "parking_night", "concert", "desk_night", "party": .night
        default: .standard
        }
    }

    /// A quick shot is never straight: −6…6° from its seed.
    static func tilt(_ seed: String) -> Double {
        var rng = SeededRandom(seed: seed + "tilt")
        return Double(rng.next() * 12 - 6)
    }

    static func paint(scene: String, style: Photo.Style, lines: [String], in ctx: inout C, size: CGSize, rng: inout SeededRandom) {
        let w = size.width, h = size.height
        switch scene {
        case "sunset": sunset(&ctx, w, h, &rng)
        case "sky": sky(&ctx, w, h, &rng)
        case "rain": rain(&ctx, w, h, &rng)
        case "street_day": streetDay(&ctx, w, h, &rng)
        case "street_night": streetNight(&ctx, w, h, &rng)
        case "parking_night": parkingNight(&ctx, w, h, &rng)
        case "concert": concert(&ctx, w, h, &rng)
        case "bar": bar(&ctx, w, h, &rng)
        case "party": party(&ctx, w, h, &rng)
        case "group", "selfie": people(&ctx, w, h, &rng, close: style == .selfie || scene == "selfie")
        case "gallery": gallery(&ctx, w, h, &rng)
        case "climbing": climbing(&ctx, w, h, &rng)
        case "cat": cat(&ctx, w, h, &rng)
        case "books": books(&ctx, w, h, &rng)
        case "interior_warm": interior(&ctx, w, h, &rng)
        case "bed": bed(&ctx, w, h, &rng)
        case "station": station(&ctx, w, h, &rng)
        case "laptop": laptop(&ctx, w, h, &rng)
        case "desk_night": deskNight(&ctx, w, h, &rng)
        case "car": car(&ctx, w, h, &rng)
        case "park": park(&ctx, w, h, &rng)
        case "plant": plant(&ctx, w, h, &rng)
        case "document": document(&ctx, w, h, &rng, lines: lines)
        case "screenshot": screenshot(&ctx, w, h, &rng, lines: lines)
        case "beach": beach(&ctx, w, h, &rng)
        case "snow": snow(&ctx, w, h, &rng)
        case "ceiling": ceiling(&ctx, w, h, &rng)
        case "pocket": pocket(&ctx, w, h, &rng)
        case "receipt": receipt(&ctx, w, h, &rng, lines: lines)
        case "mirror": mirror(&ctx, w, h, &rng)
        case "view": viewFromWindow(&ctx, w, h, &rng)
        default: sky(&ctx, w, h, &rng)
        }
    }

    // MARK: Primitives

    static func hex(_ v: UInt32) -> Color { Color(hex: v) }

    static func fill(_ ctx: inout C, _ rect: CGRect, _ colors: [Color], vertical: Bool = true) {
        ctx.fill(Path(rect), with: .linearGradient(Gradient(colors: colors),
                                                   startPoint: CGPoint(x: rect.minX, y: rect.minY),
                                                   endPoint: vertical ? CGPoint(x: rect.minX, y: rect.maxY) : CGPoint(x: rect.maxX, y: rect.minY)))
    }

    static func glow(_ ctx: inout C, _ center: CGPoint, _ radius: CGFloat, _ color: Color, _ opacity: Double = 1) {
        ctx.fill(Path(ellipseIn: CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2)),
                 with: .radialGradient(Gradient(colors: [color.opacity(opacity), color.opacity(0)]), center: center, startRadius: 0, endRadius: radius))
    }

    /// Out-of-focus light discs.
    static func bokeh(_ ctx: inout C, _ w: CGFloat, _ h: CGFloat, _ rng: inout SeededRandom, count: Int, colors: [Color],
                      radius: ClosedRange<CGFloat>, yMax: CGFloat = 1, blur: CGFloat = 4, opacity: ClosedRange<Double> = 0.25...0.6) {
        var local = rng
        ctx.drawLayer { layer in
            layer.addFilter(.blur(radius: blur))
            for _ in 0..<count {
                let r = radius.lowerBound + local.next() * (radius.upperBound - radius.lowerBound)
                let x = local.next() * w, y = local.next() * h * yMax
                let c = colors[Int(local.next() * CGFloat(colors.count)) % colors.count]
                let o = opacity.lowerBound + Double(local.next()) * (opacity.upperBound - opacity.lowerBound)
                layer.fill(Path(ellipseIn: CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2)), with: .color(c.opacity(o)))
            }
        }
        rng = local
    }

    /// Heads and shoulders against the light, never in focus.
    static func silhouettes(_ ctx: inout C, _ w: CGFloat, _ h: CGFloat, _ rng: inout SeededRandom, count: Int,
                            baseline: CGFloat, scale: CGFloat, color: Color, blur: CGFloat) {
        var local = rng
        ctx.drawLayer { layer in
            layer.addFilter(.blur(radius: blur))
            for i in 0..<count {
                let spread = w / CGFloat(max(count, 1))
                let cx = spread * (CGFloat(i) + 0.5) + (local.next() - 0.5) * spread * 0.6
                let s = scale * (0.85 + local.next() * 0.3) * h
                let headY = baseline * h - s * 0.95 + (local.next() - 0.5) * s * 0.2
                layer.fill(Path(ellipseIn: CGRect(x: cx - s * 0.2, y: headY, width: s * 0.4, height: s * 0.48)), with: .color(color))
                layer.fill(Path(roundedRect: CGRect(x: cx - s * 0.55, y: headY + s * 0.46, width: s * 1.1, height: s * 0.9), cornerRadius: s * 0.35),
                           with: .color(color))
            }
        }
        rng = local
    }

    static func skyline(_ ctx: inout C, _ w: CGFloat, _ h: CGFloat, _ rng: inout SeededRandom, base: CGFloat, color: Color,
                        lit: Double, windowColor: Color) {
        var x: CGFloat = -10
        while x < w {
            let bw = w * (0.08 + rng.next() * 0.14)
            let bh = h * (0.12 + rng.next() * 0.35)
            let rect = CGRect(x: x, y: base * h - bh, width: bw, height: bh + 2)
            ctx.fill(Path(rect), with: .color(color))
            var wy = rect.minY + 5
            while wy < rect.maxY - 6 {
                var wx = rect.minX + 4
                while wx < rect.maxX - 5 {
                    if Double(rng.next()) < lit {
                        ctx.fill(Path(CGRect(x: wx, y: wy, width: 3, height: 4)), with: .color(windowColor.opacity(0.5 + Double(rng.next()) * 0.5)))
                    }
                    wx += 7
                }
                wy += 9
            }
            x += bw + rng.next() * 3
        }
    }

    // MARK: Outdoor

    static func sunset(_ ctx: inout C, _ w: CGFloat, _ h: CGFloat, _ rng: inout SeededRandom) {
        fill(&ctx, CGRect(x: 0, y: 0, width: w, height: h * 0.62), [hex(0x2B1C44), hex(0xB5486A), hex(0xF59A4F)])
        let horizon = h * 0.62
        glow(&ctx, CGPoint(x: w * (0.3 + rng.next() * 0.4), y: horizon - h * 0.04), w * 0.5, hex(0xFFC27A), 0.7)
        ctx.fill(Path(ellipseIn: CGRect(x: w * 0.46, y: horizon - h * 0.09, width: h * 0.1, height: h * 0.1)), with: .color(hex(0xFFE2A8)))
        fill(&ctx, CGRect(x: 0, y: horizon, width: w, height: h - horizon), [hex(0x6C3350), hex(0x1B1224)])
        for i in 0..<14 { // reflection
            let y = horizon + CGFloat(i) * (h - horizon) / 14
            ctx.fill(Path(CGRect(x: w * 0.5 - w * 0.12 * rng.next(), y: y, width: w * 0.24 * rng.next(), height: 1.5)),
                     with: .color(hex(0xFFC27A).opacity(0.5)))
        }
        // Cranes and a ferry against the light.
        for i in 0..<3 {
            let x = w * (0.08 + CGFloat(i) * 0.12)
            var crane = Path()
            crane.move(to: CGPoint(x: x, y: horizon)); crane.addLine(to: CGPoint(x: x, y: horizon - h * 0.28))
            crane.addLine(to: CGPoint(x: x + w * 0.16, y: horizon - h * 0.26))
            ctx.stroke(crane, with: .color(hex(0x1A0F1E)), lineWidth: 2.5)
        }
        ctx.fill(Path(roundedRect: CGRect(x: w * 0.62, y: horizon - h * 0.07, width: w * 0.3, height: h * 0.07), cornerRadius: 3),
                 with: .color(hex(0x1A0F1E)))
    }

    static func sky(_ ctx: inout C, _ w: CGFloat, _ h: CGFloat, _ rng: inout SeededRandom) {
        let morning = rng.next() > 0.5
        fill(&ctx, CGRect(x: 0, y: 0, width: w, height: h),
             morning ? [hex(0x6E7FB8), hex(0xE8A38C), hex(0xF6D3A8)] : [hex(0x2F74C8), hex(0x6FA8E0), hex(0xB9D7F1)])
        bokeh(&ctx, w, h, &rng, count: 6, colors: [.white], radius: w * 0.1...w * 0.25, yMax: 0.8, blur: 18, opacity: 0.15...0.35)
        var trail = Path()
        let y0 = h * (0.2 + rng.next() * 0.3)
        trail.move(to: CGPoint(x: -10, y: y0)); trail.addLine(to: CGPoint(x: w + 10, y: y0 - h * 0.25))
        ctx.stroke(trail, with: .color(.white.opacity(0.55)), lineWidth: 1.5)
        // Rooftops at the bottom.
        skyline(&ctx, w, h, &rng, base: 1.02, color: hex(0x1D2330), lit: 0, windowColor: .clear)
    }

    static func rain(_ ctx: inout C, _ w: CGFloat, _ h: CGFloat, _ rng: inout SeededRandom) {
        fill(&ctx, CGRect(x: 0, y: 0, width: w, height: h), [hex(0x5B6673), hex(0x2B323A)])
        bokeh(&ctx, w, h, &rng, count: 14, colors: [hex(0xFFD08A), hex(0xE0E6EE), hex(0xFF7A6A)], radius: 6...20, blur: 9)
        // Drops on the glass: highlight + shadow.
        for _ in 0..<70 {
            let r = 1 + rng.next() * 3.5
            let x = rng.next() * w, y = rng.next() * h
            ctx.fill(Path(ellipseIn: CGRect(x: x, y: y, width: r * 2, height: r * 2.3)), with: .color(.black.opacity(0.18)))
            ctx.fill(Path(ellipseIn: CGRect(x: x + r * 0.4, y: y + r * 0.3, width: r * 0.8, height: r * 0.8)), with: .color(.white.opacity(0.4)))
        }
        for _ in 0..<10 {
            let x = rng.next() * w
            var streak = Path(); streak.move(to: CGPoint(x: x, y: rng.next() * h * 0.5))
            streak.addLine(to: CGPoint(x: x + 2, y: h * (0.6 + rng.next() * 0.4)))
            ctx.stroke(streak, with: .color(.white.opacity(0.12)), lineWidth: 1.5)
        }
    }

    static func streetDay(_ ctx: inout C, _ w: CGFloat, _ h: CGFloat, _ rng: inout SeededRandom) {
        fill(&ctx, CGRect(x: 0, y: 0, width: w, height: h * 0.45), [hex(0x8DB5DE), hex(0xCFE0EE)])
        // Two facades in perspective.
        var left = Path(); left.move(to: .zero); left.addLine(to: CGPoint(x: w * 0.38, y: h * 0.35))
        left.addLine(to: CGPoint(x: w * 0.38, y: h * 0.7)); left.addLine(to: CGPoint(x: 0, y: h)); left.closeSubpath()
        ctx.fill(left, with: .linearGradient(Gradient(colors: [hex(0xC9B79C), hex(0x8E7E6A)]), startPoint: .zero, endPoint: CGPoint(x: w * 0.4, y: 0)))
        var right = Path(); right.move(to: CGPoint(x: w, y: 0)); right.addLine(to: CGPoint(x: w * 0.62, y: h * 0.35))
        right.addLine(to: CGPoint(x: w * 0.62, y: h * 0.7)); right.addLine(to: CGPoint(x: w, y: h)); right.closeSubpath()
        ctx.fill(right, with: .linearGradient(Gradient(colors: [hex(0x6F6558), hex(0xA99A84)]), startPoint: CGPoint(x: w * 0.6, y: 0), endPoint: CGPoint(x: w, y: 0)))
        var road = Path(); road.move(to: CGPoint(x: w * 0.38, y: h * 0.7)); road.addLine(to: CGPoint(x: w * 0.62, y: h * 0.7))
        road.addLine(to: CGPoint(x: w, y: h)); road.addLine(to: CGPoint(x: 0, y: h)); road.closeSubpath()
        ctx.fill(road, with: .color(hex(0x5F5B57)))
        // Windows and a shop front.
        for i in 0..<5 {
            let t = CGFloat(i) / 5
            ctx.fill(Path(CGRect(x: w * (0.05 + t * 0.28), y: h * (0.12 + t * 0.2), width: w * 0.04, height: h * 0.08)), with: .color(hex(0x3A3F48).opacity(0.8)))
        }
        ctx.fill(Path(CGRect(x: w * 0.66, y: h * 0.5, width: w * 0.2, height: h * 0.18)), with: .color(hex(0xE9D8B0).opacity(0.7)))
        silhouettes(&ctx, w, h, &rng, count: 3, baseline: 0.82, scale: 0.18, color: hex(0x2A2724).opacity(0.8), blur: 2.5)
    }

    static func streetNight(_ ctx: inout C, _ w: CGFloat, _ h: CGFloat, _ rng: inout SeededRandom) {
        fill(&ctx, CGRect(x: 0, y: 0, width: w, height: h), [hex(0x0C1220), hex(0x1A2234), hex(0x0B0D12)])
        skyline(&ctx, w, h, &rng, base: 0.62, color: hex(0x0E1119), lit: 0.18, windowColor: hex(0xFFC77A))
        fill(&ctx, CGRect(x: 0, y: h * 0.62, width: w, height: h * 0.38), [hex(0x1C1E24), hex(0x0D0E11)])
        // Street lamps and their pools of light on the wet road.
        for i in 0..<3 {
            let x = w * (0.18 + CGFloat(i) * 0.32 + (rng.next() - 0.5) * 0.08)
            ctx.stroke(Path { p in p.move(to: CGPoint(x: x, y: h * 0.66)); p.addLine(to: CGPoint(x: x, y: h * 0.3)) },
                       with: .color(hex(0x15171C)), lineWidth: 2)
            glow(&ctx, CGPoint(x: x, y: h * 0.3), w * 0.18, hex(0xFFB35C), 0.55)
            ctx.fill(Path(ellipseIn: CGRect(x: x - 4, y: h * 0.3 - 3, width: 8, height: 6)), with: .color(hex(0xFFE0A8)))
            glow(&ctx, CGPoint(x: x, y: h * 0.86), w * 0.22, hex(0xFFB35C), 0.18)
        }
        // A parked car (tail lights) or a bus shelter screen.
        if rng.next() > 0.5 {
            ctx.fill(Path(roundedRect: CGRect(x: w * 0.55, y: h * 0.7, width: w * 0.32, height: h * 0.12), cornerRadius: 8), with: .color(hex(0x101217)))
            glow(&ctx, CGPoint(x: w * 0.58, y: h * 0.76), 8, hex(0xFF3B30), 0.9)
            glow(&ctx, CGPoint(x: w * 0.84, y: h * 0.76), 8, hex(0xFF3B30), 0.9)
        } else {
            ctx.fill(Path(roundedRect: CGRect(x: w * 0.6, y: h * 0.45, width: w * 0.22, height: h * 0.14), cornerRadius: 3), with: .color(hex(0x0F1B2A)))
            ctx.fill(Path(CGRect(x: w * 0.62, y: h * 0.47, width: w * 0.18, height: h * 0.04)), with: .color(hex(0xFFB547).opacity(0.85)))
            ctx.fill(Path(CGRect(x: w * 0.62, y: h * 0.53, width: w * 0.12, height: h * 0.03)), with: .color(hex(0xFFB547).opacity(0.6)))
        }
    }

    static func parkingNight(_ ctx: inout C, _ w: CGFloat, _ h: CGFloat, _ rng: inout SeededRandom) {
        fill(&ctx, CGRect(x: 0, y: 0, width: w, height: h), [hex(0x080B10), hex(0x1B2330), hex(0x070809)])
        // Sodium lights in the fog.
        for i in 0..<4 {
            let x = w * (0.1 + CGFloat(i) * 0.27)
            glow(&ctx, CGPoint(x: x, y: h * 0.22), w * 0.2, hex(0xFF9F43), 0.35)
            ctx.fill(Path(ellipseIn: CGRect(x: x - 3, y: h * 0.22 - 2, width: 6, height: 4)), with: .color(hex(0xFFD18A)))
        }
        // Parking bays in perspective.
        for i in 0..<9 {
            let t = CGFloat(i) / 8
            ctx.stroke(Path { p in
                p.move(to: CGPoint(x: w * (0.35 + t * 0.3), y: h * 0.58))
                p.addLine(to: CGPoint(x: w * (-0.3 + t * 1.6), y: h))
            }, with: .color(.white.opacity(0.22)), lineWidth: 1.5)
        }
        ctx.fill(Path(CGRect(x: 0, y: h * 0.56, width: w, height: 2)), with: .color(.white.opacity(0.1)))
        // Barrier, a pale figure near it, and a small car leaving (tail lights).
        ctx.stroke(Path { p in p.move(to: CGPoint(x: w * 0.12, y: h * 0.58)); p.addLine(to: CGPoint(x: w * 0.4, y: h * 0.55)) },
                   with: .color(hex(0xD9D2C0).opacity(0.7)), lineWidth: 3)
        silhouettes(&ctx, w, h, &rng, count: 1, baseline: 0.62, scale: 0.16, color: hex(0xB9B4A6).opacity(0.55), blur: 3)
        ctx.fill(Path(roundedRect: CGRect(x: w * 0.62, y: h * 0.5, width: w * 0.16, height: h * 0.07), cornerRadius: 5), with: .color(hex(0x3B3E44)))
        glow(&ctx, CGPoint(x: w * 0.635, y: h * 0.535), 7, hex(0xFF2D20), 1)
        glow(&ctx, CGPoint(x: w * 0.765, y: h * 0.535), 7, hex(0xFF2D20), 1)
        bokeh(&ctx, w, h, &rng, count: 5, colors: [hex(0xFF9F43)], radius: 10...24, yMax: 0.4, blur: 14, opacity: 0.1...0.25)
    }

    static func concert(_ ctx: inout C, _ w: CGFloat, _ h: CGFloat, _ rng: inout SeededRandom) {
        fill(&ctx, CGRect(x: 0, y: 0, width: w, height: h), [hex(0x14061F), hex(0x2A0F45), hex(0x0A0410)])
        for i in 0..<5 { // light beams
            let x = w * (0.15 + CGFloat(i) * 0.18)
            var beam = Path()
            beam.move(to: CGPoint(x: x, y: h * 0.1))
            beam.addLine(to: CGPoint(x: x - w * 0.18 + rng.next() * w * 0.1, y: h * 0.9))
            beam.addLine(to: CGPoint(x: x + w * 0.1 + rng.next() * w * 0.1, y: h * 0.9))
            beam.closeSubpath()
            ctx.fill(beam, with: .linearGradient(Gradient(colors: [hex(i % 2 == 0 ? 0xB45CFF : 0x4C9BFF).opacity(0.5), .clear]),
                                                 startPoint: CGPoint(x: x, y: h * 0.1), endPoint: CGPoint(x: x, y: h * 0.9)))
        }
        bokeh(&ctx, w, h, &rng, count: 14, colors: [hex(0xB45CFF), hex(0xFF5CA8), hex(0x4C9BFF)], radius: 4...14, yMax: 0.5, blur: 5)
        silhouettes(&ctx, w, h, &rng, count: 7, baseline: 1.05, scale: 0.2, color: hex(0x07030B), blur: 2)
    }

    static func bar(_ ctx: inout C, _ w: CGFloat, _ h: CGFloat, _ rng: inout SeededRandom) {
        fill(&ctx, CGRect(x: 0, y: 0, width: w, height: h), [hex(0x2A170C), hex(0x3E2413), hex(0x140B06)])
        bokeh(&ctx, w, h, &rng, count: 18, colors: [hex(0xFFB35C), hex(0xFFD08A), hex(0xFF8A4C)], radius: 5...18, yMax: 0.6, blur: 7)
        silhouettes(&ctx, w, h, &rng, count: 3, baseline: 0.78, scale: 0.34, color: hex(0x120A05).opacity(0.85), blur: 7)
        // Table top and glasses.
        fill(&ctx, CGRect(x: 0, y: h * 0.74, width: w, height: h * 0.26), [hex(0x5A3A22), hex(0x2A1A0E)])
        for i in 0..<Int(2 + rng.next() * 3) {
            let x = w * (0.15 + CGFloat(i) * 0.2 + rng.next() * 0.05)
            let base = h * (0.86 + rng.next() * 0.06)
            var glass = Path()
            glass.addEllipse(in: CGRect(x: x - 11, y: base - 46, width: 22, height: 26))
            glass.addRect(CGRect(x: x - 1, y: base - 22, width: 2, height: 20))
            glass.addEllipse(in: CGRect(x: x - 8, y: base - 3, width: 16, height: 4))
            ctx.fill(glass, with: .color(.white.opacity(0.18)))
            ctx.fill(Path(ellipseIn: CGRect(x: x - 9, y: base - 34, width: 18, height: 12)), with: .color(hex(0x7A1B2E).opacity(0.7)))
            ctx.stroke(Path(ellipseIn: CGRect(x: x - 11, y: base - 46, width: 22, height: 26)), with: .color(hex(0xFFD08A).opacity(0.35)), lineWidth: 1)
        }
    }

    static func party(_ ctx: inout C, _ w: CGFloat, _ h: CGFloat, _ rng: inout SeededRandom) {
        fill(&ctx, CGRect(x: 0, y: 0, width: w, height: h), [hex(0x2B1530), hex(0x1B0F22)])
        // String lights in two catenaries.
        for row in 0..<2 {
            let y0 = h * (0.12 + CGFloat(row) * 0.14)
            for i in 0..<18 {
                let t = CGFloat(i) / 17
                let y = y0 + sin(t * .pi) * h * 0.08
                glow(&ctx, CGPoint(x: t * w, y: y), 9, hex(0xFFE08A), 0.8)
                ctx.fill(Path(ellipseIn: CGRect(x: t * w - 2, y: y - 2, width: 4, height: 4)), with: .color(hex(0xFFF3C4)))
            }
        }
        // Balloons.
        let colors: [UInt32] = [0xE35D8C, 0x5DB3E3, 0xE3C25D, 0x9B5DE3]
        for i in 0..<Int(4 + rng.next() * 4) {
            let x = rng.next() * w, y = h * (0.3 + rng.next() * 0.3)
            let r = w * (0.05 + rng.next() * 0.04)
            let c = hex(colors[i % colors.count])
            ctx.fill(Path(ellipseIn: CGRect(x: x - r, y: y - r * 1.15, width: r * 2, height: r * 2.3)),
                     with: .radialGradient(Gradient(colors: [c.opacity(0.95), c.opacity(0.6)]), center: CGPoint(x: x - r * 0.3, y: y - r * 0.5), startRadius: 0, endRadius: r * 1.6))
            ctx.fill(Path(ellipseIn: CGRect(x: x - r * 0.55, y: y - r * 0.8, width: r * 0.35, height: r * 0.5)), with: .color(.white.opacity(0.35)))
            ctx.stroke(Path { p in p.move(to: CGPoint(x: x, y: y + r * 1.15)); p.addLine(to: CGPoint(x: x + 4, y: y + r * 3)) },
                       with: .color(.white.opacity(0.3)), lineWidth: 0.7)
        }
        silhouettes(&ctx, w, h, &rng, count: 4, baseline: 1.08, scale: 0.3, color: hex(0x0E0712), blur: 5)
    }

    static func people(_ ctx: inout C, _ w: CGFloat, _ h: CGFloat, _ rng: inout SeededRandom, close: Bool) {
        let warm = rng.next() > 0.4
        fill(&ctx, CGRect(x: 0, y: 0, width: w, height: h), warm ? [hex(0x4A3526), hex(0x241A13)] : [hex(0x3A4252), hex(0x1C2029)])
        bokeh(&ctx, w, h, &rng, count: 16, colors: warm ? [hex(0xFFC98A), hex(0xFFE0B0)] : [hex(0xDDE8FF), hex(0x9CC8F0)],
              radius: 6...22, yMax: 0.55, blur: 10)
        let count = close ? Int(2 + rng.next() * 2) : Int(3 + rng.next() * 3)
        silhouettes(&ctx, w, h, &rng, count: count, baseline: close ? 1.2 : 1.05, scale: close ? 0.62 : 0.4,
                    color: (warm ? hex(0x2A1C12) : hex(0x161A22)).opacity(0.92), blur: close ? 9 : 6)
        // Light on the edges of the faces (rim light), out of focus.
        var local = rng
        ctx.drawLayer { layer in
            layer.addFilter(.blur(radius: 12))
            for _ in 0..<count {
                let x = local.next() * w, y = h * (0.45 + local.next() * 0.25)
                layer.fill(Path(ellipseIn: CGRect(x: x - 22, y: y - 26, width: 44, height: 52)),
                           with: .color((warm ? hex(0xE8B08A) : hex(0xC9D2E0)).opacity(0.28)))
            }
        }
        rng = local
    }

    // MARK: Indoor

    static func gallery(_ ctx: inout C, _ w: CGFloat, _ h: CGFloat, _ rng: inout SeededRandom) {
        fill(&ctx, CGRect(x: 0, y: 0, width: w, height: h * 0.75), [hex(0xE7E2D8), hex(0xC9C2B4)])
        fill(&ctx, CGRect(x: 0, y: h * 0.75, width: w, height: h * 0.25), [hex(0xB08A5E), hex(0x7A5C3C)])
        for i in 0..<4 {
            let x = w * (0.06 + CGFloat(i) * 0.24)
            glow(&ctx, CGPoint(x: x + w * 0.09, y: h * 0.12), w * 0.2, hex(0xFFF3D6), 0.6)
            let frame = CGRect(x: x, y: h * (0.25 + rng.next() * 0.04), width: w * 0.18, height: h * 0.3)
            ctx.fill(Path(frame), with: .color(hex(0xD8C6A6)))
            ctx.fill(Path(frame.insetBy(dx: 5, dy: 5)), with: .color(hex(0x2A2724)))
            ctx.fill(Path(frame.insetBy(dx: 9, dy: 9)),
                     with: .linearGradient(Gradient(colors: [hex(0x55504A), hex(0x1F1D1B)]), startPoint: CGPoint(x: frame.minX, y: frame.minY), endPoint: CGPoint(x: frame.maxX, y: frame.maxY)))
        }
        let visitors = Int(rng.next() * 3)
        silhouettes(&ctx, w, h, &rng, count: visitors, baseline: 1.05, scale: 0.36, color: hex(0x3B342C).opacity(0.8), blur: 5)
    }

    static func climbing(_ ctx: inout C, _ w: CGFloat, _ h: CGFloat, _ rng: inout SeededRandom) {
        fill(&ctx, CGRect(x: 0, y: 0, width: w, height: h), [hex(0x8C96A0), hex(0x4B525B)])
        // Wall panels.
        for i in 0..<5 { ctx.fill(Path(CGRect(x: 0, y: h * CGFloat(i) * 0.22, width: w, height: 1)), with: .color(.black.opacity(0.18))) }
        let holdColors: [UInt32] = [0xF2C14E, 0x3E7CD6, 0xE24A4A, 0x3FAE6A, 0xF08A3C]
        for _ in 0..<26 {
            let x = rng.next() * w, y = rng.next() * h
            let r = 4 + rng.next() * 9
            var hold = Path()
            hold.addEllipse(in: CGRect(x: x - r, y: y - r * 0.7, width: r * 2, height: r * 1.4))
            ctx.fill(hold, with: .color(hex(holdColors[Int(rng.next() * 5) % 5])))
            ctx.fill(Path(ellipseIn: CGRect(x: x - r * 0.4, y: y - r * 0.5, width: r * 0.8, height: r * 0.5)), with: .color(.white.opacity(0.35)))
        }
        silhouettes(&ctx, w, h, &rng, count: 1, baseline: 0.5, scale: 0.3, color: hex(0x7A2A26).opacity(0.7), blur: 4)
        glow(&ctx, CGPoint(x: w * 0.5, y: -h * 0.1), w * 0.8, .white, 0.25)
    }

    static func cat(_ ctx: inout C, _ w: CGFloat, _ h: CGFloat, _ rng: inout SeededRandom) {
        fill(&ctx, CGRect(x: 0, y: 0, width: w, height: h * 0.4), [hex(0x6B5846), hex(0x4E3F32)])
        fill(&ctx, CGRect(x: 0, y: h * 0.4, width: w, height: h * 0.6), [hex(0x7D6A55), hex(0x5A4A3B)])
        // Doormat with a woven texture.
        let mat = CGRect(x: w * 0.12, y: h * 0.5, width: w * 0.76, height: h * 0.38)
        ctx.fill(Path(roundedRect: mat, cornerRadius: 6), with: .color(hex(0x9C7A4E)))
        for i in stride(from: mat.minY, to: mat.maxY, by: 4) {
            ctx.fill(Path(CGRect(x: mat.minX, y: i, width: mat.width, height: 1)), with: .color(.black.opacity(0.12)))
        }
        // A curled up ginger cat: body, head, ears, tail.
        let cx = w * (0.45 + rng.next() * 0.1), cy = h * 0.66
        ctx.fill(Path(ellipseIn: CGRect(x: cx - w * 0.2, y: cy - h * 0.1, width: w * 0.4, height: h * 0.2)),
                 with: .radialGradient(Gradient(colors: [hex(0xE09A52), hex(0xA8622A)]), center: CGPoint(x: cx - w * 0.05, y: cy - h * 0.06), startRadius: 2, endRadius: w * 0.25))
        let hx = cx + w * 0.15, hy = cy - h * 0.06
        ctx.fill(Path(ellipseIn: CGRect(x: hx - w * 0.08, y: hy - h * 0.06, width: w * 0.16, height: h * 0.12)), with: .color(hex(0xC9803E)))
        for side: CGFloat in [-1, 1] {
            var ear = Path()
            ear.move(to: CGPoint(x: hx + side * w * 0.03, y: hy - h * 0.04)); ear.addLine(to: CGPoint(x: hx + side * w * 0.07, y: hy - h * 0.11))
            ear.addLine(to: CGPoint(x: hx + side * w * 0.075, y: hy - h * 0.02)); ear.closeSubpath()
            ctx.fill(ear, with: .color(hex(0xB06E34)))
        }
        ctx.stroke(Path { p in p.move(to: CGPoint(x: cx - w * 0.18, y: cy + h * 0.04)); p.addQuadCurve(to: CGPoint(x: cx + w * 0.05, y: cy + h * 0.11), control: CGPoint(x: cx - w * 0.12, y: cy + h * 0.16)) },
                   with: .color(hex(0xB06E34)), lineWidth: 7)
    }

    static func books(_ ctx: inout C, _ w: CGFloat, _ h: CGFloat, _ rng: inout SeededRandom) {
        fill(&ctx, CGRect(x: 0, y: 0, width: w, height: h), [hex(0x3A2A1D), hex(0x241A12)])
        let spines: [UInt32] = [0xE8E1D3, 0x1E1E1E, 0xB33A2E, 0x2E4A6B, 0xD9B45C, 0x5B6B4A, 0xF2F0EA, 0x7A2A4A]
        for shelf in 0..<3 {
            let base = h * (0.32 + CGFloat(shelf) * 0.33)
            ctx.fill(Path(CGRect(x: 0, y: base, width: w, height: h * 0.03)), with: .color(hex(0x6B4B2E)))
            var x: CGFloat = 4
            while x < w - 6 {
                let bw = 6 + rng.next() * 12
                let bh = h * (0.18 + rng.next() * 0.1)
                ctx.fill(Path(CGRect(x: x, y: base - bh, width: bw, height: bh)), with: .color(hex(spines[Int(rng.next() * 8) % 8])))
                ctx.fill(Path(CGRect(x: x + 1, y: base - bh * 0.7, width: bw - 2, height: 1.5)), with: .color(.black.opacity(0.25)))
                x += bw + 1
            }
        }
        glow(&ctx, CGPoint(x: w * 0.8, y: h * 0.1), w * 0.6, hex(0xFFE0B0), 0.25)
    }

    static func interior(_ ctx: inout C, _ w: CGFloat, _ h: CGFloat, _ rng: inout SeededRandom) {
        fill(&ctx, CGRect(x: 0, y: 0, width: w, height: h * 0.7), [hex(0xB9A58C), hex(0x8C7A64)])
        fill(&ctx, CGRect(x: 0, y: h * 0.7, width: w, height: h * 0.3), [hex(0x7A6048), hex(0x4F3D2D)])
        // Window with daylight.
        let win = CGRect(x: w * 0.62, y: h * 0.1, width: w * 0.3, height: h * 0.4)
        ctx.fill(Path(win), with: .linearGradient(Gradient(colors: [hex(0xE8F1F8), hex(0xB5CCDD)]), startPoint: CGPoint(x: win.minX, y: win.minY), endPoint: CGPoint(x: win.minX, y: win.maxY)))
        ctx.stroke(Path(win), with: .color(hex(0xEFE8DC)), lineWidth: 3)
        glow(&ctx, CGPoint(x: win.midX, y: win.maxY + h * 0.1), w * 0.4, .white, 0.25)
        // Sofa, boxes.
        ctx.fill(Path(roundedRect: CGRect(x: w * 0.05, y: h * 0.48, width: w * 0.5, height: h * 0.22), cornerRadius: 10), with: .color(hex(0x46505E)))
        ctx.fill(Path(roundedRect: CGRect(x: w * 0.03, y: h * 0.58, width: w * 0.54, height: h * 0.15), cornerRadius: 8), with: .color(hex(0x3A4350)))
        for i in 0..<3 {
            let bx = w * (0.58 + CGFloat(i) * 0.12), bh = h * (0.12 + rng.next() * 0.1)
            ctx.fill(Path(CGRect(x: bx, y: h * 0.85 - bh, width: w * 0.11, height: bh)), with: .color(hex(0xB58A57)))
            ctx.fill(Path(CGRect(x: bx, y: h * 0.85 - bh + 6, width: w * 0.11, height: 2)), with: .color(hex(0xD9C29A)))
        }
        silhouettes(&ctx, w, h, &rng, count: 1, baseline: 0.62, scale: 0.2, color: hex(0x3A2E26).opacity(0.7), blur: 5)
    }

    /// A bedroom in the early evening: the window still shows a light sky (what the careful eye
    /// notices), a duvet, a mug, the glow of a television.
    static func bed(_ ctx: inout C, _ w: CGFloat, _ h: CGFloat, _ rng: inout SeededRandom) {
        fill(&ctx, CGRect(x: 0, y: 0, width: w, height: h), [hex(0x4E5664), hex(0x2C2F38)])
        let win = CGRect(x: w * 0.12, y: h * 0.08, width: w * 0.36, height: h * 0.34)
        ctx.fill(Path(win), with: .linearGradient(Gradient(colors: [hex(0x9DB7D6), hex(0xE6C9A8)]), startPoint: CGPoint(x: win.minX, y: win.minY), endPoint: CGPoint(x: win.minX, y: win.maxY)))
        ctx.stroke(Path(win), with: .color(hex(0xD8D3CA)), lineWidth: 3)
        ctx.fill(Path(CGRect(x: win.midX - 1, y: win.minY, width: 2, height: win.height)), with: .color(hex(0xD8D3CA)))
        glow(&ctx, CGPoint(x: win.midX, y: win.maxY), w * 0.35, hex(0xF2E3CC), 0.3)
        // Duvet and pillows.
        var duvet = Path()
        duvet.move(to: CGPoint(x: 0, y: h * 0.62))
        duvet.addCurve(to: CGPoint(x: w, y: h * 0.58), control1: CGPoint(x: w * 0.3, y: h * 0.48), control2: CGPoint(x: w * 0.7, y: h * 0.7))
        duvet.addLine(to: CGPoint(x: w, y: h)); duvet.addLine(to: CGPoint(x: 0, y: h)); duvet.closeSubpath()
        ctx.fill(duvet, with: .linearGradient(Gradient(colors: [hex(0xE9E6E0), hex(0x9C9A98)]), startPoint: CGPoint(x: 0, y: h * 0.5), endPoint: CGPoint(x: 0, y: h)))
        for i in 0..<4 {
            ctx.stroke(Path { p in
                p.move(to: CGPoint(x: w * (0.1 + CGFloat(i) * 0.22), y: h * 0.7))
                p.addQuadCurve(to: CGPoint(x: w * (0.2 + CGFloat(i) * 0.22), y: h * 0.95), control: CGPoint(x: w * (0.22 + CGFloat(i) * 0.22), y: h * 0.8))
            }, with: .color(.black.opacity(0.12)), lineWidth: 3)
        }
        // A mug with steam.
        let mug = CGRect(x: w * 0.08, y: h * 0.66, width: w * 0.09, height: h * 0.1)
        ctx.fill(Path(roundedRect: mug, cornerRadius: 3), with: .color(hex(0x2F5D7A)))
        var local = rng
        ctx.drawLayer { layer in
            layer.addFilter(.blur(radius: 3))
            for i in 0..<3 {
                layer.stroke(Path { p in
                    let x = mug.midX + CGFloat(i - 1) * 5
                    p.move(to: CGPoint(x: x, y: mug.minY))
                    p.addCurve(to: CGPoint(x: x + 3, y: mug.minY - h * 0.12), control1: CGPoint(x: x + 8, y: mug.minY - h * 0.04), control2: CGPoint(x: x - 8, y: mug.minY - h * 0.08))
                }, with: .color(.white.opacity(0.3 + Double(local.next()) * 0.2)), lineWidth: 2)
            }
        }
        rng = local
        // Television glow, its small clock unreadable.
        let tv = CGRect(x: w * 0.66, y: h * 0.3, width: w * 0.3, height: h * 0.2)
        ctx.fill(Path(roundedRect: tv, cornerRadius: 3), with: .color(hex(0x0E1016)))
        ctx.fill(Path(tv.insetBy(dx: 3, dy: 3)), with: .linearGradient(Gradient(colors: [hex(0x6FA0D8), hex(0x2C4F7A)]), startPoint: CGPoint(x: tv.minX, y: tv.minY), endPoint: CGPoint(x: tv.maxX, y: tv.maxY)))
        glow(&ctx, CGPoint(x: tv.midX, y: tv.midY), w * 0.3, hex(0x6FA0D8), 0.25)
        ctx.fill(Path(CGRect(x: tv.maxX - 16, y: tv.maxY + 3, width: 12, height: 4)), with: .color(hex(0x6FF0A0).opacity(0.5)))
    }

    static func station(_ ctx: inout C, _ w: CGFloat, _ h: CGFloat, _ rng: inout SeededRandom) {
        fill(&ctx, CGRect(x: 0, y: 0, width: w, height: h), [hex(0x7A848E), hex(0x3A4046)])
        // Roof arches.
        for i in 0..<4 {
            ctx.stroke(Path { p in
                p.move(to: CGPoint(x: -w * 0.2 + CGFloat(i) * w * 0.4, y: h * 0.45))
                p.addQuadCurve(to: CGPoint(x: w * 0.2 + CGFloat(i) * w * 0.4, y: h * 0.45), control: CGPoint(x: CGFloat(i) * w * 0.4, y: -h * 0.1))
            }, with: .color(hex(0x2A3036)), lineWidth: 4)
        }
        glow(&ctx, CGPoint(x: w * 0.5, y: 0), w * 0.8, .white, 0.3)
        // Departure board.
        let board = CGRect(x: w * 0.18, y: h * 0.28, width: w * 0.64, height: h * 0.22)
        ctx.fill(Path(roundedRect: board, cornerRadius: 3), with: .color(hex(0x0B0E14)))
        for row in 0..<4 {
            let y = board.minY + 6 + CGFloat(row) * board.height / 4.3
            ctx.fill(Path(CGRect(x: board.minX + 6, y: y, width: board.width * 0.15, height: 4)), with: .color(hex(0xFFB547).opacity(0.9)))
            ctx.fill(Path(CGRect(x: board.minX + board.width * 0.24, y: y, width: board.width * (0.4 + rng.next() * 0.2), height: 4)), with: .color(hex(0xFFB547).opacity(0.7)))
            if row == 1 { ctx.fill(Path(CGRect(x: board.maxX - 30, y: y, width: 24, height: 4)), with: .color(hex(0xFF5A4A))) }
        }
        fill(&ctx, CGRect(x: 0, y: h * 0.7, width: w, height: h * 0.3), [hex(0x55595E), hex(0x2B2E31)])
        silhouettes(&ctx, w, h, &rng, count: 6, baseline: 0.92, scale: 0.16, color: hex(0x1B1D20).opacity(0.85), blur: 2.5)
    }

    static func laptop(_ ctx: inout C, _ w: CGFloat, _ h: CGFloat, _ rng: inout SeededRandom) {
        fill(&ctx, CGRect(x: 0, y: 0, width: w, height: h), [hex(0x1C222C), hex(0x0F1216)])
        let screen = CGRect(x: w * 0.16, y: h * 0.12, width: w * 0.68, height: h * 0.48)
        ctx.fill(Path(roundedRect: screen.insetBy(dx: -6, dy: -6), cornerRadius: 8), with: .color(hex(0x2A2D32)))
        ctx.fill(Path(screen), with: .color(hex(0xF1EFEA)))
        // A poster being designed: blue and orange blocks.
        ctx.fill(Path(CGRect(x: screen.minX + screen.width * 0.3, y: screen.minY + 8, width: screen.width * 0.4, height: screen.height - 16)), with: .color(hex(0x2E5CB8)))
        ctx.fill(Path(ellipseIn: CGRect(x: screen.midX - 16, y: screen.midY - 16, width: 32, height: 32)), with: .color(hex(0xF08A3C)))
        ctx.fill(Path(CGRect(x: screen.minX + 6, y: screen.minY + 6, width: screen.width * 0.22, height: screen.height - 12)), with: .color(hex(0xDCD9D2)))
        glow(&ctx, CGPoint(x: screen.midX, y: screen.midY), w * 0.6, hex(0xBFD4FF), 0.2)
        // Keyboard in perspective.
        var base = Path()
        base.move(to: CGPoint(x: w * 0.1, y: h * 0.64)); base.addLine(to: CGPoint(x: w * 0.9, y: h * 0.64))
        base.addLine(to: CGPoint(x: w, y: h * 0.95)); base.addLine(to: CGPoint(x: 0, y: h * 0.95)); base.closeSubpath()
        ctx.fill(base, with: .color(hex(0x9DA1A7)))
        for row in 0..<4 {
            let y = h * (0.67 + CGFloat(row) * 0.06)
            ctx.fill(Path(CGRect(x: w * (0.15 - CGFloat(row) * 0.02), y: y, width: w * (0.7 + CGFloat(row) * 0.04), height: h * 0.035)), with: .color(hex(0x2C2E32)))
        }
    }

    static func deskNight(_ ctx: inout C, _ w: CGFloat, _ h: CGFloat, _ rng: inout SeededRandom) {
        fill(&ctx, CGRect(x: 0, y: 0, width: w, height: h), [hex(0x2A2621), hex(0x12100E)])
        glow(&ctx, CGPoint(x: w * 0.5, y: h * 0.1), w * 0.6, hex(0xFFD27A), 0.35)
        // Wall logo (a swan's neck line) and an unreadable wall clock.
        ctx.stroke(Path { p in
            p.move(to: CGPoint(x: w * 0.42, y: h * 0.3))
            p.addCurve(to: CGPoint(x: w * 0.56, y: h * 0.18), control1: CGPoint(x: w * 0.5, y: h * 0.34), control2: CGPoint(x: w * 0.48, y: h * 0.12))
        }, with: .color(hex(0xD9B45C).opacity(0.8)), lineWidth: 3)
        var local = rng
        ctx.drawLayer { layer in
            layer.addFilter(.blur(radius: 1.5))
            let c = CGPoint(x: w * 0.8, y: h * 0.2)
            layer.fill(Path(ellipseIn: CGRect(x: c.x - 16, y: c.y - 16, width: 32, height: 32)), with: .color(hex(0xEDE6D8)))
            layer.stroke(Path { p in p.move(to: c); p.addLine(to: CGPoint(x: c.x + 3, y: c.y - 10 - local.next())) }, with: .color(.black), lineWidth: 2)
            layer.stroke(Path { p in p.move(to: c); p.addLine(to: CGPoint(x: c.x + 11, y: c.y + 4)) }, with: .color(.black), lineWidth: 1.5)
        }
        rng = local
        // Counter, booking screen, bell.
        fill(&ctx, CGRect(x: 0, y: h * 0.58, width: w, height: h * 0.42), [hex(0x5A3A22), hex(0x2A1A0E)])
        let screen = CGRect(x: w * 0.15, y: h * 0.36, width: w * 0.34, height: h * 0.22)
        ctx.fill(Path(roundedRect: screen, cornerRadius: 3), with: .color(hex(0x0B0E14)))
        ctx.fill(Path(screen.insetBy(dx: 3, dy: 3)), with: .color(hex(0x2F6FD0).opacity(0.85)))
        for row in 0..<4 {
            ctx.fill(Path(CGRect(x: screen.minX + 8, y: screen.minY + 8 + CGFloat(row) * 9, width: screen.width * 0.7, height: 3)), with: .color(.white.opacity(0.6)))
        }
        glow(&ctx, CGPoint(x: screen.midX, y: screen.midY), w * 0.25, hex(0x6FB7FF), 0.25)
        ctx.fill(Path(ellipseIn: CGRect(x: w * 0.66, y: h * 0.52, width: w * 0.12, height: h * 0.08)), with: .color(hex(0xD9C07A)))
        ctx.fill(Path(CGRect(x: w * 0.64, y: h * 0.58, width: w * 0.16, height: 4)), with: .color(hex(0x8C7440)))
    }

    static func car(_ ctx: inout C, _ w: CGFloat, _ h: CGFloat, _ rng: inout SeededRandom) {
        fill(&ctx, CGRect(x: 0, y: 0, width: w, height: h * 0.6), [hex(0x8E9AA6), hex(0x646D76)])
        fill(&ctx, CGRect(x: 0, y: h * 0.6, width: w, height: h * 0.4), [hex(0x55595D), hex(0x3A3D40)])
        // A small grey hatchback, side view.
        var body = Path()
        body.move(to: CGPoint(x: w * 0.12, y: h * 0.72))
        body.addLine(to: CGPoint(x: w * 0.16, y: h * 0.56)); body.addLine(to: CGPoint(x: w * 0.34, y: h * 0.52))
        body.addLine(to: CGPoint(x: w * 0.44, y: h * 0.38)); body.addLine(to: CGPoint(x: w * 0.72, y: h * 0.37))
        body.addLine(to: CGPoint(x: w * 0.86, y: h * 0.52)); body.addLine(to: CGPoint(x: w * 0.9, y: h * 0.72)); body.closeSubpath()
        ctx.fill(body, with: .linearGradient(Gradient(colors: [hex(0xB9BEC4), hex(0x7C8288)]), startPoint: CGPoint(x: 0, y: h * 0.38), endPoint: CGPoint(x: 0, y: h * 0.72)))
        var glass = Path()
        glass.move(to: CGPoint(x: w * 0.46, y: h * 0.41)); glass.addLine(to: CGPoint(x: w * 0.7, y: h * 0.4))
        glass.addLine(to: CGPoint(x: w * 0.8, y: h * 0.51)); glass.addLine(to: CGPoint(x: w * 0.38, y: h * 0.52)); glass.closeSubpath()
        ctx.fill(glass, with: .color(hex(0x2B3440)))
        for x in [w * 0.28, w * 0.74] {
            ctx.fill(Path(ellipseIn: CGRect(x: x - h * 0.08, y: h * 0.64, width: h * 0.16, height: h * 0.16)), with: .color(hex(0x151618)))
            ctx.fill(Path(ellipseIn: CGRect(x: x - h * 0.04, y: h * 0.68, width: h * 0.08, height: h * 0.08)), with: .color(hex(0x9DA1A7)))
        }
        // A bike leaning in front, hiding the plate.
        ctx.stroke(Path(ellipseIn: CGRect(x: w * 0.03, y: h * 0.68, width: h * 0.2, height: h * 0.2)), with: .color(hex(0x1B1D20)), lineWidth: 2)
        ctx.stroke(Path { p in p.move(to: CGPoint(x: w * 0.1, y: h * 0.78)); p.addLine(to: CGPoint(x: w * 0.2, y: h * 0.62)); p.addLine(to: CGPoint(x: w * 0.26, y: h * 0.78)) },
                   with: .color(hex(0xC23B32)), lineWidth: 2.5)
        glow(&ctx, CGPoint(x: w * 0.6, y: h * 0.4), w * 0.3, .white, 0.15)
    }

    static func park(_ ctx: inout C, _ w: CGFloat, _ h: CGFloat, _ rng: inout SeededRandom) {
        fill(&ctx, CGRect(x: 0, y: 0, width: w, height: h * 0.5), [hex(0xAFCBE0), hex(0xE3EDE2)])
        fill(&ctx, CGRect(x: 0, y: h * 0.5, width: w, height: h * 0.5), [hex(0x6F8F4E), hex(0x3F5530)])
        bokeh(&ctx, w, h, &rng, count: 12, colors: [hex(0x5E8A3E), hex(0xC9A43E), hex(0xD98B3A)], radius: w * 0.08...w * 0.18, yMax: 0.55, blur: 6, opacity: 0.7...0.95)
        // Path.
        var path = Path()
        path.move(to: CGPoint(x: w * 0.45, y: h * 0.55)); path.addLine(to: CGPoint(x: w * 0.55, y: h * 0.55))
        path.addLine(to: CGPoint(x: w * 0.9, y: h)); path.addLine(to: CGPoint(x: w * 0.1, y: h)); path.closeSubpath()
        ctx.fill(path, with: .color(hex(0xC9B48E)))
        for _ in 0..<30 {
            let x = rng.next() * w, y = h * (0.55 + rng.next() * 0.45)
            ctx.fill(Path(ellipseIn: CGRect(x: x, y: y, width: 4, height: 2.5)), with: .color(hex(0xD9A23A).opacity(0.8)))
        }
    }

    static func plant(_ ctx: inout C, _ w: CGFloat, _ h: CGFloat, _ rng: inout SeededRandom) {
        fill(&ctx, CGRect(x: 0, y: 0, width: w, height: h), [hex(0xD8D2C4), hex(0x9C9585)])
        glow(&ctx, CGPoint(x: w * 0.1, y: h * 0.2), w * 0.8, .white, 0.45)
        let pot = CGRect(x: w * 0.36, y: h * 0.66, width: w * 0.28, height: h * 0.24)
        for _ in 0..<26 {
            let a = rng.next() * .pi * 2
            let r = w * (0.08 + rng.next() * 0.28)
            let x = w * 0.5 + cos(a) * r, y = h * 0.45 + sin(a) * r * 0.8
            var leaf = Path()
            leaf.addEllipse(in: CGRect(x: x - 12, y: y - 8, width: 24, height: 16))
            ctx.fill(leaf, with: .color(hex(rng.next() > 0.5 ? 0x3F7A3A : 0x5E9A45)))
        }
        ctx.fill(Path(roundedRect: pot, cornerRadius: 6), with: .color(hex(0xB5643C)))
    }

    static func beach(_ ctx: inout C, _ w: CGFloat, _ h: CGFloat, _ rng: inout SeededRandom) {
        fill(&ctx, CGRect(x: 0, y: 0, width: w, height: h * 0.45), [hex(0x5EA8E6), hex(0xB8DDF4)])
        fill(&ctx, CGRect(x: 0, y: h * 0.45, width: w, height: h * 0.25), [hex(0x2F8FB8), hex(0x5CC0D0)])
        fill(&ctx, CGRect(x: 0, y: h * 0.68, width: w, height: h * 0.32), [hex(0xE8D3A8), hex(0xD1B684)])
        for i in 0..<5 {
            ctx.stroke(Path { p in
                let y = h * (0.62 + CGFloat(i) * 0.015)
                p.move(to: CGPoint(x: 0, y: y)); p.addQuadCurve(to: CGPoint(x: w, y: y), control: CGPoint(x: w * 0.5, y: y + 6))
            }, with: .color(.white.opacity(0.35)), lineWidth: 1.5)
        }
        // A parasol.
        let px = w * (0.2 + rng.next() * 0.5)
        ctx.stroke(Path { p in p.move(to: CGPoint(x: px, y: h * 0.62)); p.addLine(to: CGPoint(x: px, y: h * 0.88)) }, with: .color(.white), lineWidth: 2)
        var top = Path(); top.move(to: CGPoint(x: px - w * 0.14, y: h * 0.66))
        top.addQuadCurve(to: CGPoint(x: px + w * 0.14, y: h * 0.66), control: CGPoint(x: px, y: h * 0.52)); top.closeSubpath()
        ctx.fill(top, with: .color(hex(0xE85D4A)))
        glow(&ctx, CGPoint(x: w * 0.85, y: h * 0.1), w * 0.3, .white, 0.5)
    }

    static func snow(_ ctx: inout C, _ w: CGFloat, _ h: CGFloat, _ rng: inout SeededRandom) {
        fill(&ctx, CGRect(x: 0, y: 0, width: w, height: h * 0.5), [hex(0x8FA9C8), hex(0xDCE6F0)])
        for i in 0..<3 {
            var m = Path()
            let x0 = w * (CGFloat(i) * 0.4 - 0.2)
            m.move(to: CGPoint(x: x0, y: h * 0.55)); m.addLine(to: CGPoint(x: x0 + w * 0.3, y: h * (0.18 + rng.next() * 0.1)))
            m.addLine(to: CGPoint(x: x0 + w * 0.65, y: h * 0.55)); m.closeSubpath()
            ctx.fill(m, with: .linearGradient(Gradient(colors: [hex(0xF4F7FA), hex(0x9DAEC2)]), startPoint: CGPoint(x: x0, y: h * 0.2), endPoint: CGPoint(x: x0, y: h * 0.55)))
        }
        fill(&ctx, CGRect(x: 0, y: h * 0.55, width: w, height: h * 0.45), [hex(0xEEF2F6), hex(0xC9D3DE)])
        for _ in 0..<8 {
            let x = rng.next() * w, y = h * (0.5 + rng.next() * 0.3)
            var tree = Path(); tree.move(to: CGPoint(x: x, y: y - 26)); tree.addLine(to: CGPoint(x: x + 10, y: y)); tree.addLine(to: CGPoint(x: x - 10, y: y)); tree.closeSubpath()
            ctx.fill(tree, with: .color(hex(0x2E4A3A)))
        }
    }

    /// An accidental shot of a ceiling (pressed the button by mistake).
    static func ceiling(_ ctx: inout C, _ w: CGFloat, _ h: CGFloat, _ rng: inout SeededRandom) {
        fill(&ctx, CGRect(x: 0, y: 0, width: w, height: h), [hex(0xDCD6CC), hex(0xB4AC9E)])
        glow(&ctx, CGPoint(x: w * (0.3 + rng.next() * 0.4), y: h * (0.3 + rng.next() * 0.3)), w * 0.35, .white, 0.9)
        ctx.fill(Path(CGRect(x: 0, y: h * 0.85, width: w, height: 3)), with: .color(.black.opacity(0.1)))
    }

    /// Taken from inside a pocket: almost black, a strip of fabric light.
    static func pocket(_ ctx: inout C, _ w: CGFloat, _ h: CGFloat, _ rng: inout SeededRandom) {
        fill(&ctx, CGRect(x: 0, y: 0, width: w, height: h), [hex(0x0A0A0C), hex(0x16151A)])
        glow(&ctx, CGPoint(x: w * (0.7 + rng.next() * 0.2), y: h * 0.1), w * 0.4, hex(0x4A3B5A), 0.6)
    }

    static func mirror(_ ctx: inout C, _ w: CGFloat, _ h: CGFloat, _ rng: inout SeededRandom) {
        fill(&ctx, CGRect(x: 0, y: 0, width: w, height: h), [hex(0x7B8594), hex(0x3E4450)])
        let frame = CGRect(x: w * 0.12, y: h * 0.04, width: w * 0.76, height: h * 0.92)
        ctx.stroke(Path(roundedRect: frame, cornerRadius: 10), with: .color(hex(0x1C1E22)), lineWidth: 5)
        silhouettes(&ctx, w, h, &rng, count: 1, baseline: 1.15, scale: 0.7, color: hex(0x22262E), blur: 6)
        // The phone held up, its flash.
        glow(&ctx, CGPoint(x: w * 0.6, y: h * 0.45), w * 0.18, .white, 0.7)
    }

    static func viewFromWindow(_ ctx: inout C, _ w: CGFloat, _ h: CGFloat, _ rng: inout SeededRandom) {
        fill(&ctx, CGRect(x: 0, y: 0, width: w, height: h), [hex(0xE3A07A), hex(0xF5D0A8)])
        skyline(&ctx, w, h, &rng, base: 0.95, color: hex(0x3A3440), lit: 0.1, windowColor: hex(0xFFE0A8))
        ctx.stroke(Path(CGRect(x: 4, y: 4, width: w - 8, height: h - 8)), with: .color(hex(0xEDE6D8)), lineWidth: 8)
        ctx.fill(Path(CGRect(x: w * 0.5 - 3, y: 0, width: 6, height: h)), with: .color(hex(0xEDE6D8)))
    }

    // MARK: Documents & screens

    static func document(_ ctx: inout C, _ w: CGFloat, _ h: CGFloat, _ rng: inout SeededRandom, lines: [String]) {
        fill(&ctx, CGRect(x: 0, y: 0, width: w, height: h), [hex(0x6B4B30), hex(0x3E2A1A)])
        for i in 0..<8 { ctx.fill(Path(CGRect(x: 0, y: CGFloat(i) * h / 8, width: w, height: 1)), with: .color(.black.opacity(0.1))) }
        var paper = ctx
        let angle = Angle.degrees(Double(rng.next() * 8 - 4))
        paper.translateBy(x: w / 2, y: h / 2)
        paper.rotate(by: angle)
        let sheet = CGRect(x: -w * 0.34, y: -h * 0.42, width: w * 0.68, height: h * 0.84)
        paper.fill(Path(sheet.offsetBy(dx: 4, dy: 6)), with: .color(.black.opacity(0.35)))
        paper.fill(Path(sheet), with: .linearGradient(Gradient(colors: [hex(0xF6F3EC), hex(0xDCD6CA)]),
                                                     startPoint: CGPoint(x: sheet.minX, y: sheet.minY), endPoint: CGPoint(x: sheet.maxX, y: sheet.maxY)))
        let fontSize = max(6, w * 0.032)
        var y = sheet.minY + fontSize * 1.6
        if lines.isEmpty {
            for i in 0..<12 {
                paper.fill(Path(CGRect(x: sheet.minX + 10, y: y, width: sheet.width * (i == 0 ? 0.4 : 0.55 + rng.next() * 0.3), height: 2.5)),
                           with: .color(.black.opacity(i == 0 ? 0.7 : 0.35)))
                y += fontSize * 1.2
            }
        } else {
            for (i, line) in lines.enumerated() {
                let text = Text(line)
                    .font(.custom(i == 0 ? Theme.FontName.semibold : Theme.FontName.regular, fixedSize: i == 0 ? fontSize * 1.3 : fontSize))
                    .foregroundColor(hex(0x1C1D20))
                paper.draw(text, at: CGPoint(x: sheet.minX + 10, y: y), anchor: .leading)
                y += fontSize * (i == 0 ? 2.2 : 1.6)
                if i == 0 {
                    paper.fill(Path(CGRect(x: sheet.minX + 10, y: y - fontSize * 0.7, width: sheet.width - 20, height: 1)), with: .color(.black.opacity(0.3)))
                }
            }
            // The rest of the page: small print nobody reads at a glance.
            while y < sheet.maxY - fontSize * 2 {
                paper.fill(Path(CGRect(x: sheet.minX + 10, y: y, width: sheet.width * (0.4 + rng.next() * 0.45), height: 1.5)), with: .color(.black.opacity(0.22)))
                y += fontSize * 0.9
            }
        }
        glow(&ctx, CGPoint(x: w * 0.8, y: h * 0.1), w * 0.5, hex(0xFFE9C4), 0.25)
    }

    static func receipt(_ ctx: inout C, _ w: CGFloat, _ h: CGFloat, _ rng: inout SeededRandom, lines: [String]) {
        fill(&ctx, CGRect(x: 0, y: 0, width: w, height: h), [hex(0x2C2F36), hex(0x16181C)])
        let strip = CGRect(x: w * 0.3, y: h * 0.04, width: w * 0.4, height: h * 0.92)
        ctx.fill(Path(strip), with: .color(hex(0xF4F1EA)))
        let fontSize = max(6, w * 0.028)
        var y = strip.minY + fontSize * 1.5
        for line in (lines.isEmpty ? ["TICKET", "—", "TOTAL"] : lines) {
            ctx.draw(Text(line).font(.custom(Theme.FontName.mono, fixedSize: fontSize)).foregroundColor(hex(0x2A2A2A)),
                     at: CGPoint(x: strip.midX, y: y), anchor: .center)
            y += fontSize * 1.6
        }
        while y < strip.maxY - 10 {
            ctx.fill(Path(CGRect(x: strip.minX + 8, y: y, width: strip.width * (0.3 + rng.next() * 0.5), height: 1.2)), with: .color(.black.opacity(0.2)))
            y += fontSize
        }
    }

    /// A screenshot: the status bar of this phone, an app's header, its content as text rows.
    static func screenshot(_ ctx: inout C, _ w: CGFloat, _ h: CGFloat, _ rng: inout SeededRandom, lines: [String]) {
        fill(&ctx, CGRect(x: 0, y: 0, width: w, height: h), [hex(0x111318), hex(0x0B0C0F)])
        let fontSize = max(6, w * 0.036)
        ctx.draw(Text("9:41").font(.custom(Theme.FontName.semibold, fixedSize: fontSize)).foregroundColor(.white), at: CGPoint(x: w * 0.1, y: fontSize), anchor: .leading)
        ctx.fill(Path(roundedRect: CGRect(x: w * 0.8, y: fontSize * 0.6, width: w * 0.1, height: fontSize * 0.8), cornerRadius: 2), with: .color(.white.opacity(0.8)))
        let accent: UInt32 = [0x4C9BFF, 0x4FD17F, 0xFFB547, 0xB28CFF][Int(rng.next() * 4) % 4]
        var y = fontSize * 3
        for (i, line) in (lines.isEmpty ? ["—"] : lines).enumerated() {
            if i == 0 {
                ctx.draw(Text(line).font(.custom(Theme.FontName.semibold, fixedSize: fontSize * 1.6)).foregroundColor(.white),
                         at: CGPoint(x: w * 0.06, y: y), anchor: .leading)
                y += fontSize * 2.4
            } else {
                let row = CGRect(x: w * 0.05, y: y - fontSize * 0.95, width: w * 0.9, height: fontSize * 1.9)
                ctx.fill(Path(roundedRect: row, cornerRadius: 5), with: .color(.white.opacity(0.07)))
                ctx.fill(Path(ellipseIn: CGRect(x: row.minX + 5, y: row.midY - 3, width: 6, height: 6)), with: .color(hex(accent)))
                ctx.draw(Text(line).font(.custom(Theme.FontName.regular, fixedSize: fontSize)).foregroundColor(.white.opacity(0.9)),
                         at: CGPoint(x: row.minX + 16, y: row.midY), anchor: .leading)
                y += fontSize * 2.3
            }
        }
    }
}

/// Small deterministic generator so a photo always looks the same.
struct SeededRandom {
    private var state: UInt64

    init(seed: String) {
        state = seed.unicodeScalars.reduce(UInt64(1469598103934665603)) { ($0 ^ UInt64($1.value)) &* 1099511628211 }
    }

    mutating func next() -> CGFloat {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        z ^= z >> 31
        return CGFloat(z % 10_000) / 10_000
    }
}
#endif
