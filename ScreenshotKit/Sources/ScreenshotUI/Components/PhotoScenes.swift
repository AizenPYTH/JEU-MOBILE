#if os(iOS)
import SwiftUI

/// More places for the generated photos (cases #002–#005 and their opening sequences): a metro
/// platform, a club, a mountain road at night, a gala, a display case, mountains, a newsroom, a
/// terrace on the bay, garden stairs, a forest, a living room the morning after a party.
/// Same rules as the other scenes: layered shapes and light, people only as blurred silhouettes.
extension PhotoPainter {
    // MARK: City at night

    static func metro(_ ctx: inout C, _ w: CGFloat, _ h: CGFloat, _ rng: inout SeededRandom) {
        // Curved tiled vault, cold fluorescent light.
        fill(&ctx, CGRect(x: 0, y: 0, width: w, height: h), [hex(0x9FA89A), hex(0x6F7A72), hex(0x2B312E)])
        var y: CGFloat = 0
        while y < h * 0.62 {
            var x: CGFloat = (Int(y / 10) % 2 == 0) ? 0 : -9
            while x < w {
                ctx.stroke(Path(roundedRect: CGRect(x: x, y: y, width: 18, height: 10), cornerRadius: 1.5),
                           with: .color(hex(0x3F4843).opacity(0.25)), lineWidth: 0.8)
                x += 18
            }
            y += 10
        }
        // The tunnel mouth on the left, black.
        ctx.fill(Path(roundedRect: CGRect(x: -w * 0.15, y: h * 0.22, width: w * 0.42, height: h * 0.5), cornerRadius: w * 0.2),
                 with: .color(hex(0x07090A)))
        // Fluorescent tubes.
        for i in 0..<4 {
            let x = w * (0.34 + CGFloat(i) * 0.17)
            ctx.fill(Path(roundedRect: CGRect(x: x, y: h * 0.06, width: w * 0.12, height: 3), cornerRadius: 1.5), with: .color(hex(0xE9FFF4)))
            glow(&ctx, CGPoint(x: x + w * 0.06, y: h * 0.07), w * 0.16, hex(0xD8FFF0), 0.35)
        }
        // Information screen.
        ctx.fill(Path(roundedRect: CGRect(x: w * 0.55, y: h * 0.2, width: w * 0.3, height: h * 0.08), cornerRadius: 2), with: .color(hex(0x0A0E14)))
        ctx.fill(Path(CGRect(x: w * 0.57, y: h * 0.225, width: w * 0.12, height: 4)), with: .color(hex(0xFFB547).opacity(0.9)))
        ctx.fill(Path(CGRect(x: w * 0.74, y: h * 0.225, width: w * 0.08, height: 4)), with: .color(hex(0xFFB547).opacity(0.9)))
        // Track bed, platform, yellow safety line.
        fill(&ctx, CGRect(x: 0, y: h * 0.62, width: w, height: h * 0.08), [hex(0x141716), hex(0x0A0B0B)])
        fill(&ctx, CGRect(x: 0, y: h * 0.7, width: w, height: h * 0.3), [hex(0x7D7F7A), hex(0x3E403D)])
        ctx.fill(Path(CGRect(x: 0, y: h * 0.705, width: w, height: 4)), with: .color(hex(0xE3C04A).opacity(0.85)))
        // An empty bench.
        ctx.fill(Path(roundedRect: CGRect(x: w * 0.56, y: h * 0.8, width: w * 0.34, height: h * 0.03), cornerRadius: 2), with: .color(hex(0x2B3A48)))
        for x in [w * 0.59, w * 0.85] { ctx.fill(Path(CGRect(x: x, y: h * 0.83, width: 3, height: h * 0.06)), with: .color(hex(0x1E252B))) }
        bokeh(&ctx, w, h, &rng, count: 4, colors: [hex(0xD8FFF0)], radius: 8...18, yMax: 0.3, blur: 10, opacity: 0.1...0.2)
    }

    static func club(_ ctx: inout C, _ w: CGFloat, _ h: CGFloat, _ rng: inout SeededRandom) {
        fill(&ctx, CGRect(x: 0, y: 0, width: w, height: h), [hex(0x07060C), hex(0x150B22), hex(0x050407)])
        // Haze lit from above.
        glow(&ctx, CGPoint(x: w * 0.5, y: h * 0.18), w * 0.7, hex(0x6A2BD9), 0.35)
        glow(&ctx, CGPoint(x: w * 0.2, y: h * 0.3), w * 0.4, hex(0x16C6D8), 0.2)
        // Lasers fanning out from the booth.
        let origin = CGPoint(x: w * 0.5, y: h * 0.42)
        for i in 0..<9 {
            let a = CGFloat(i) / 8
            ctx.stroke(Path { p in p.move(to: origin); p.addLine(to: CGPoint(x: -w * 0.2 + a * w * 1.4, y: -h * 0.05)) },
                       with: .color((i % 2 == 0 ? hex(0x33F0FF) : hex(0xFF3FD2)).opacity(0.35)), lineWidth: 1.2)
        }
        // DJ booth.
        ctx.fill(Path(roundedRect: CGRect(x: w * 0.3, y: h * 0.42, width: w * 0.4, height: h * 0.12), cornerRadius: 3), with: .color(hex(0x0D0D12)))
        glow(&ctx, CGPoint(x: w * 0.5, y: h * 0.44), w * 0.12, hex(0xFFFFFF), 0.25)
        silhouettes(&ctx, w, h, &rng, count: 1, baseline: 0.44, scale: 0.14, color: hex(0x1A1426).opacity(0.95), blur: 2)
        // The crowd, raised hands.
        silhouettes(&ctx, w, h, &rng, count: 7, baseline: 1.02, scale: 0.26, color: hex(0x09070D), blur: 3)
        bokeh(&ctx, w, h, &rng, count: 10, colors: [hex(0xFF3FD2), hex(0x33F0FF), hex(0xFFFFFF)], radius: 3...9, yMax: 0.6, blur: 3)
    }

    static func roadNight(_ ctx: inout C, _ w: CGFloat, _ h: CGFloat, _ rng: inout SeededRandom) {
        // Fog, a mountain road between pines, a car stopped on the shoulder with its hazard lights.
        fill(&ctx, CGRect(x: 0, y: 0, width: w, height: h), [hex(0x0B0F12), hex(0x1C2428), hex(0x080A0B)])
        glow(&ctx, CGPoint(x: w * 0.5, y: h * 0.45), w * 0.7, hex(0x9FB2B8), 0.18)
        pines(&ctx, w, h, &rng, base: 0.58, count: 9, color: hex(0x06090A), height: 0.4)
        var road = Path()
        road.move(to: CGPoint(x: w * 0.44, y: h * 0.5)); road.addLine(to: CGPoint(x: w * 0.56, y: h * 0.5))
        road.addLine(to: CGPoint(x: w * 1.1, y: h)); road.addLine(to: CGPoint(x: -w * 0.1, y: h)); road.closeSubpath()
        ctx.fill(road, with: .linearGradient(Gradient(colors: [hex(0x1A1E20), hex(0x2B3033)]), startPoint: CGPoint(x: 0, y: h * 0.5), endPoint: CGPoint(x: 0, y: h)))
        for i in 0..<6 { // centre dashes
            let t = CGFloat(i) / 6
            let y = h * (0.52 + t * t * 0.46)
            ctx.fill(Path(CGRect(x: w * 0.5 - 1 - t * 2, y: y, width: 2 + t * 4, height: 4 + t * 16)), with: .color(.white.opacity(0.35)))
        }
        // The car, rear view, slightly off the road.
        let car = CGRect(x: w * 0.56, y: h * 0.6, width: w * 0.3, height: h * 0.14)
        ctx.fill(Path(roundedRect: car, cornerRadius: 10), with: .color(hex(0x0F1113)))
        ctx.fill(Path(roundedRect: CGRect(x: car.minX + car.width * 0.12, y: car.minY - h * 0.05, width: car.width * 0.76, height: h * 0.06), cornerRadius: 8),
                 with: .color(hex(0x151A1D)))
        for x in [car.minX + 10, car.maxX - 10] {
            glow(&ctx, CGPoint(x: x, y: car.midY), w * 0.1, hex(0xFF9A1F), 0.8)
            ctx.fill(Path(ellipseIn: CGRect(x: x - 5, y: car.midY - 3, width: 10, height: 6)), with: .color(hex(0xFFC060)))
        }
        // The driver's door left open (a pale strip of interior light).
        ctx.fill(Path(CGRect(x: car.minX - 6, y: car.minY + 4, width: 5, height: car.height * 0.7)), with: .color(hex(0xE8D9A8).opacity(0.6)))
        // Rain.
        for _ in 0..<90 {
            let x = rng.next() * w, y = rng.next() * h
            ctx.stroke(Path { p in p.move(to: CGPoint(x: x, y: y)); p.addLine(to: CGPoint(x: x - 3, y: y + 12)) },
                       with: .color(.white.opacity(0.12)), lineWidth: 1)
        }
    }

    static func forest(_ ctx: inout C, _ w: CGFloat, _ h: CGFloat, _ rng: inout SeededRandom) {
        fill(&ctx, CGRect(x: 0, y: 0, width: w, height: h), [hex(0x2A3432), hex(0x1A2220), hex(0x0C100F)])
        glow(&ctx, CGPoint(x: w * 0.55, y: h * 0.35), w * 0.6, hex(0xB9C8C0), 0.18)
        // Trunks, far (pale, foggy) to near (dark).
        for layer in 0..<3 {
            let count = 7 - layer * 2
            let shade: [UInt32] = [0x46524E, 0x27302D, 0x0E1211]
            for _ in 0..<count {
                let x = rng.next() * w
                let tw = CGFloat(4 + layer * 6) + rng.next() * 6
                ctx.fill(Path(CGRect(x: x, y: 0, width: tw, height: h)), with: .color(hex(shade[layer]).opacity(0.9)))
            }
        }
        fill(&ctx, CGRect(x: 0, y: h * 0.82, width: w, height: h * 0.18), [hex(0x1B1F1C), hex(0x0A0C0B)])
    }

    static func pines(_ ctx: inout C, _ w: CGFloat, _ h: CGFloat, _ rng: inout SeededRandom, base: CGFloat, count: Int,
                      color: Color, height: CGFloat) {
        for i in 0..<count {
            let x = w * (CGFloat(i) / CGFloat(max(count - 1, 1))) + (rng.next() - 0.5) * w * 0.08
            let th = h * height * (0.6 + rng.next() * 0.5)
            let tw = th * 0.38
            var tree = Path()
            tree.move(to: CGPoint(x: x, y: base * h - th))
            tree.addLine(to: CGPoint(x: x + tw / 2, y: base * h)); tree.addLine(to: CGPoint(x: x - tw / 2, y: base * h)); tree.closeSubpath()
            ctx.fill(tree, with: .color(color))
        }
    }

    // MARK: Gala

    static func gala(_ ctx: inout C, _ w: CGFloat, _ h: CGFloat, _ rng: inout SeededRandom) {
        fill(&ctx, CGRect(x: 0, y: 0, width: w, height: h), [hex(0x1A130C), hex(0x2E2115), hex(0x0D0906)])
        // Glass roof structure and chandeliers.
        for i in 0..<7 {
            let x = w * CGFloat(i) / 6
            ctx.stroke(Path { p in p.move(to: CGPoint(x: x, y: 0)); p.addLine(to: CGPoint(x: w * 0.5, y: h * 0.28)) },
                       with: .color(hex(0x4A3A28).opacity(0.5)), lineWidth: 1)
        }
        for i in 0..<3 {
            let c = CGPoint(x: w * (0.2 + CGFloat(i) * 0.3), y: h * 0.16)
            glow(&ctx, c, w * 0.22, hex(0xFFD48A), 0.45)
            ctx.fill(Path(ellipseIn: CGRect(x: c.x - 8, y: c.y - 5, width: 16, height: 10)), with: .color(hex(0xFFEBC2)))
        }
        // Columns.
        for x in [w * 0.06, w * 0.94] {
            fill(&ctx, CGRect(x: x - w * 0.04, y: h * 0.1, width: w * 0.08, height: h * 0.8), [hex(0x3A2C1E), hex(0x1E160E)], vertical: false)
        }
        // Stage and spotlight on the left, the lit display case on the right.
        glow(&ctx, CGPoint(x: w * 0.22, y: h * 0.55), w * 0.25, hex(0xFFF3DA), 0.5)
        ctx.fill(Path(CGRect(x: 0, y: h * 0.66, width: w * 0.42, height: h * 0.04)), with: .color(hex(0x2A1F14)))
        let case4 = CGRect(x: w * 0.68, y: h * 0.48, width: w * 0.14, height: h * 0.2)
        glow(&ctx, CGPoint(x: case4.midX, y: case4.minY), w * 0.2, hex(0xFFFFFF), 0.4)
        ctx.stroke(Path(case4), with: .color(.white.opacity(0.5)), lineWidth: 1)
        ctx.fill(Path(CGRect(x: case4.minX, y: case4.maxY, width: case4.width, height: h * 0.1)), with: .color(hex(0x171008)))
        // Guests.
        silhouettes(&ctx, w, h, &rng, count: 8, baseline: 1.0, scale: 0.24, color: hex(0x0B0805).opacity(0.95), blur: 2.5)
        bokeh(&ctx, w, h, &rng, count: 14, colors: [hex(0xFFD48A), hex(0xFFFFFF)], radius: 3...8, yMax: 0.5, blur: 3)
    }

    static func vitrine(_ ctx: inout C, _ w: CGFloat, _ h: CGFloat, _ rng: inout SeededRandom, empty: Bool) {
        fill(&ctx, CGRect(x: 0, y: 0, width: w, height: h), [hex(0x0A0908), hex(0x16120E), hex(0x050404)])
        // Light cone from above.
        var cone = Path()
        cone.move(to: CGPoint(x: w * 0.44, y: 0)); cone.addLine(to: CGPoint(x: w * 0.56, y: 0))
        cone.addLine(to: CGPoint(x: w * 0.78, y: h * 0.72)); cone.addLine(to: CGPoint(x: w * 0.22, y: h * 0.72)); cone.closeSubpath()
        ctx.fill(cone, with: .linearGradient(Gradient(colors: [hex(0xFFF6E0).opacity(0.28), .clear]), startPoint: .zero, endPoint: CGPoint(x: 0, y: h * 0.72)))
        // Glass case and velvet bust.
        let glass = CGRect(x: w * 0.2, y: h * 0.2, width: w * 0.6, height: h * 0.55)
        ctx.stroke(Path(glass), with: .color(.white.opacity(0.35)), lineWidth: 1.2)
        ctx.fill(Path(CGRect(x: glass.minX + 4, y: glass.minY + 4, width: 3, height: glass.height - 8)), with: .color(.white.opacity(0.12)))
        var bust = Path()
        bust.move(to: CGPoint(x: w * 0.36, y: h * 0.72))
        bust.addQuadCurve(to: CGPoint(x: w * 0.42, y: h * 0.4), control: CGPoint(x: w * 0.34, y: h * 0.5))
        bust.addQuadCurve(to: CGPoint(x: w * 0.58, y: h * 0.4), control: CGPoint(x: w * 0.5, y: h * 0.33))
        bust.addQuadCurve(to: CGPoint(x: w * 0.64, y: h * 0.72), control: CGPoint(x: w * 0.66, y: h * 0.5))
        bust.closeSubpath()
        ctx.fill(bust, with: .linearGradient(Gradient(colors: [hex(0x2C1A2A), hex(0x120A11)]), startPoint: CGPoint(x: 0, y: h * 0.35), endPoint: CGPoint(x: 0, y: h * 0.72)))
        if !empty {
            // The necklace: a drooping arc of pearls, a clasp glint.
            let n = 41
            for i in 0..<n {
                let t = CGFloat(i) / CGFloat(n - 1)
                let x = w * (0.4 + t * 0.2)
                let y = h * (0.44 + sin(t * .pi) * 0.12)
                let r: CGFloat = 3.2 - abs(t - 0.5) * 1.2
                ctx.fill(Path(ellipseIn: CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2)), with: .color(hex(0xF4EEE2)))
                ctx.fill(Path(ellipseIn: CGRect(x: x - r * 0.4, y: y - r * 0.6, width: r * 0.6, height: r * 0.6)), with: .color(.white))
            }
            glow(&ctx, CGPoint(x: w * 0.5, y: h * 0.56), 14, .white, 0.7)
        } else {
            // The case door ajar: a skewed reflection.
            ctx.stroke(Path { p in p.move(to: CGPoint(x: glass.maxX, y: glass.minY)); p.addLine(to: CGPoint(x: glass.maxX + w * 0.06, y: glass.minY + h * 0.02))
                p.addLine(to: CGPoint(x: glass.maxX + w * 0.06, y: glass.maxY + h * 0.02)); p.addLine(to: CGPoint(x: glass.maxX, y: glass.maxY)) },
                       with: .color(.white.opacity(0.4)), lineWidth: 1)
        }
        fill(&ctx, CGRect(x: 0, y: h * 0.75, width: w, height: h * 0.25), [hex(0x1B140D), hex(0x080604)])
        ctx.fill(Path(CGRect(x: w * 0.4, y: h * 0.8, width: w * 0.2, height: h * 0.04)), with: .color(hex(0xD9C08A).opacity(0.5)))
    }

    // MARK: Mountains, work

    static func mountain(_ ctx: inout C, _ w: CGFloat, _ h: CGFloat, _ rng: inout SeededRandom) {
        fill(&ctx, CGRect(x: 0, y: 0, width: w, height: h * 0.6), [hex(0x8FA3B5), hex(0xC9D3DB)])
        // Two ridges, the far one snowy.
        var far = Path(); far.move(to: CGPoint(x: 0, y: h * 0.5))
        var x: CGFloat = 0
        while x <= w { far.addLine(to: CGPoint(x: x, y: h * (0.28 + rng.next() * 0.16))); x += w / 7 }
        far.addLine(to: CGPoint(x: w, y: h * 0.6)); far.addLine(to: CGPoint(x: 0, y: h * 0.6)); far.closeSubpath()
        ctx.fill(far, with: .linearGradient(Gradient(colors: [hex(0xF2F4F6), hex(0x7F8C96)]), startPoint: CGPoint(x: 0, y: h * 0.28), endPoint: CGPoint(x: 0, y: h * 0.6)))
        // Limestone cliffs of the plateau.
        fill(&ctx, CGRect(x: 0, y: h * 0.52, width: w, height: h * 0.1), [hex(0xB4AFA4), hex(0x7C786F)])
        // A pale scar in the hillside (a quarry, far away).
        ctx.fill(Path(roundedRect: CGRect(x: w * (0.55 + rng.next() * 0.2), y: h * 0.6, width: w * 0.16, height: h * 0.06), cornerRadius: 4),
                 with: .color(hex(0xD8D2C4).opacity(0.8)))
        fill(&ctx, CGRect(x: 0, y: h * 0.6, width: w, height: h * 0.4), [hex(0x2E3B33), hex(0x141A16)])
        pines(&ctx, w, h, &rng, base: 1.0, count: 11, color: hex(0x0F1512), height: 0.3)
    }

    static func office(_ ctx: inout C, _ w: CGFloat, _ h: CGFloat, _ rng: inout SeededRandom) {
        fill(&ctx, CGRect(x: 0, y: 0, width: w, height: h), [hex(0xC7CDD2), hex(0x8E969C)])
        // Windows with daylight.
        for i in 0..<3 {
            let r = CGRect(x: w * (0.05 + CGFloat(i) * 0.32), y: h * 0.08, width: w * 0.26, height: h * 0.34)
            ctx.fill(Path(r), with: .linearGradient(Gradient(colors: [hex(0xE9F1F7), hex(0xB7C8D6)]), startPoint: CGPoint(x: r.minX, y: r.minY), endPoint: CGPoint(x: r.minX, y: r.maxY)))
            ctx.stroke(Path(r), with: .color(hex(0x5C646A)), lineWidth: 2)
        }
        // Desks, screens, a paper pile.
        fill(&ctx, CGRect(x: 0, y: h * 0.62, width: w, height: h * 0.38), [hex(0x6C6457), hex(0x3E382F)])
        for i in 0..<3 {
            let x = w * (0.08 + CGFloat(i) * 0.31)
            ctx.fill(Path(roundedRect: CGRect(x: x, y: h * 0.46, width: w * 0.22, height: h * 0.14), cornerRadius: 3), with: .color(hex(0x1E2328)))
            ctx.fill(Path(CGRect(x: x + 4, y: h * 0.47, width: w * 0.22 - 8, height: h * 0.12)), with: .color(hex(0xDDE6EE).opacity(0.8 - Double(i) * 0.15)))
            ctx.fill(Path(CGRect(x: x + w * 0.1, y: h * 0.6, width: 4, height: h * 0.03)), with: .color(hex(0x1E2328)))
        }
        ctx.fill(Path(CGRect(x: w * 0.7, y: h * 0.66, width: w * 0.2, height: h * 0.05)), with: .color(hex(0xF0EDE6)))
        silhouettes(&ctx, w, h, &rng, count: 2, baseline: 0.9, scale: 0.2, color: hex(0x2A2724).opacity(0.7), blur: 3)
    }

    // MARK: The bay, the morning after

    static func terrace(_ ctx: inout C, _ w: CGFloat, _ h: CGFloat, _ rng: inout SeededRandom) {
        fill(&ctx, CGRect(x: 0, y: 0, width: w, height: h * 0.45), [hex(0xAFC8DB), hex(0xF1E3C8)])
        fill(&ctx, CGRect(x: 0, y: h * 0.45, width: w, height: h * 0.15), [hex(0x7FA6B5), hex(0x9CB7BD)])
        glow(&ctx, CGPoint(x: w * 0.8, y: h * 0.2), w * 0.4, hex(0xFFF1CF), 0.6)
        pines(&ctx, w, h, &rng, base: 0.47, count: 5, color: hex(0x2F3B2E).opacity(0.8), height: 0.2)
        // Wooden deck and railing.
        fill(&ctx, CGRect(x: 0, y: h * 0.6, width: w, height: h * 0.4), [hex(0xA88867), hex(0x6E5840)])
        for i in 0..<10 {
            let y = h * 0.6 + CGFloat(i) * h * 0.04
            ctx.fill(Path(CGRect(x: 0, y: y, width: w, height: 1)), with: .color(hex(0x4F3F2D).opacity(0.5)))
        }
        ctx.fill(Path(CGRect(x: 0, y: h * 0.56, width: w, height: 3)), with: .color(hex(0xE9E2D6)))
        // Table with glasses left over.
        ctx.fill(Path(ellipseIn: CGRect(x: w * 0.2, y: h * 0.72, width: w * 0.5, height: h * 0.1)), with: .color(hex(0xE6DDCC)))
        for i in 0..<4 {
            let x = w * (0.28 + CGFloat(i) * 0.1)
            ctx.fill(Path(roundedRect: CGRect(x: x, y: h * 0.7, width: 8, height: 16), cornerRadius: 2), with: .color(.white.opacity(0.45)))
        }
    }

    static func gardenStairs(_ ctx: inout C, _ w: CGFloat, _ h: CGFloat, _ rng: inout SeededRandom) {
        fill(&ctx, CGRect(x: 0, y: 0, width: w, height: h * 0.4), [hex(0x7E97A8), hex(0xD7D0BE)])
        fill(&ctx, CGRect(x: 0, y: h * 0.4, width: w, height: h * 0.12), [hex(0x5E8594), hex(0x87A3A6)])
        pines(&ctx, w, h, &rng, base: 0.55, count: 6, color: hex(0x25301F), height: 0.35)
        fill(&ctx, CGRect(x: 0, y: h * 0.52, width: w, height: h * 0.48), [hex(0x5E6B45), hex(0x39432A)])
        // Stone steps going down towards the water.
        for i in 0..<9 {
            let t = CGFloat(i) / 9
            let sw = w * (0.18 + t * 0.34)
            let y = h * (0.55 + t * 0.42)
            ctx.fill(Path(CGRect(x: w * 0.5 - sw / 2, y: y, width: sw, height: h * 0.035)), with: .color(hex(0xB9AE98)))
            ctx.fill(Path(CGRect(x: w * 0.5 - sw / 2, y: y + h * 0.03, width: sw, height: h * 0.012)), with: .color(hex(0x6C6352)))
        }
        glow(&ctx, CGPoint(x: w * 0.15, y: h * 0.5), w * 0.2, hex(0xFFD58A), 0.3)
    }

    static func villaMorning(_ ctx: inout C, _ w: CGFloat, _ h: CGFloat, _ rng: inout SeededRandom) {
        fill(&ctx, CGRect(x: 0, y: 0, width: w, height: h), [hex(0xE6D8C2), hex(0xB9A58A), hex(0x6F5E4B)])
        // Bay window, sheer curtains, sun rays.
        ctx.fill(Path(CGRect(x: w * 0.05, y: h * 0.06, width: w * 0.9, height: h * 0.46)), with: .color(hex(0xFFF6E3)))
        for i in 0..<5 {
            let x = w * (0.08 + CGFloat(i) * 0.18)
            ctx.fill(Path(CGRect(x: x, y: h * 0.06, width: w * 0.08, height: h * 0.46)), with: .color(hex(0xEADFCB).opacity(0.7)))
        }
        for i in 0..<4 {
            var ray = Path()
            let x = w * (0.2 + CGFloat(i) * 0.2)
            ray.move(to: CGPoint(x: x, y: h * 0.1)); ray.addLine(to: CGPoint(x: x + w * 0.08, y: h * 0.1))
            ray.addLine(to: CGPoint(x: x + w * 0.3, y: h)); ray.addLine(to: CGPoint(x: x + w * 0.12, y: h)); ray.closeSubpath()
            ctx.fill(ray, with: .color(hex(0xFFF3D6).opacity(0.18)))
        }
        // Sofa, low table, glasses and bottles, deflating balloons.
        ctx.fill(Path(roundedRect: CGRect(x: w * 0.02, y: h * 0.56, width: w * 0.4, height: h * 0.16), cornerRadius: 12), with: .color(hex(0x8C8A83)))
        ctx.fill(Path(roundedRect: CGRect(x: w * 0.3, y: h * 0.76, width: w * 0.62, height: h * 0.07), cornerRadius: 4), with: .color(hex(0x5A4632)))
        for i in 0..<7 {
            let x = w * (0.34 + CGFloat(i) * 0.08)
            let tall = rng.next() > 0.6
            ctx.fill(Path(roundedRect: CGRect(x: x, y: h * (tall ? 0.66 : 0.71), width: tall ? 9 : 8, height: h * (tall ? 0.1 : 0.05)), cornerRadius: 2),
                     with: .color(tall ? hex(0x2E4A33).opacity(0.85) : .white.opacity(0.5)))
        }
        for i in 0..<3 {
            let c = CGPoint(x: w * (0.7 + CGFloat(i) * 0.09), y: h * (0.58 + rng.next() * 0.08))
            ctx.fill(Path(ellipseIn: CGRect(x: c.x - 14, y: c.y - 17, width: 28, height: 34)), with: .color([hex(0xD9B25A), hex(0xE9E4DA), hex(0xC98B6B)][i].opacity(0.85)))
        }
    }
}
#endif
