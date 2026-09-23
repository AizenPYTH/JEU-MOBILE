#if os(iOS)
import SwiftUI

/// A photographic-looking picture generated from a scene key: light, colour, grain and a
/// recognisable subject. Lets cases ship 80 photos without a single drawn asset.
/// What matters for the investigation is in the caption / details text, not in pixels.
struct GeneratedPhoto: View {
    let scene: String
    let seed: String
    var showsSubject = true

    var body: some View {
        let look = PhotoLook.make(scene)
        ZStack {
            LinearGradient(colors: look.colors, startPoint: .top, endPoint: .bottom)
            // Light sources (street lamps, windows, stage lights…).
            Canvas { context, size in
                var rng = SeededRandom(seed: seed)
                for _ in 0..<look.lights {
                    let x = rng.next() * size.width
                    let y = rng.next() * size.height * 0.7
                    let r = (0.08 + rng.next() * 0.18) * min(size.width, size.height)
                    context.fill(Path(ellipseIn: CGRect(x: x - r, y: y - r, width: r * 2, height: r * 2)),
                                 with: .color(look.light.opacity(0.35 + rng.next() * 0.3)))
                }
            }
            .blur(radius: 14)
            if showsSubject {
                Image(systemName: look.symbol)
                    .resizable()
                    .scaledToFit()
                    .padding(28)
                    .foregroundStyle(.white.opacity(look.subjectOpacity))
                    .blur(radius: 0.6)
            }
            // Film grain.
            Canvas { context, size in
                var rng = SeededRandom(seed: seed + "grain")
                for _ in 0..<Int(size.width * size.height / 60) {
                    let x = rng.next() * size.width, y = rng.next() * size.height
                    context.fill(Path(CGRect(x: x, y: y, width: 1, height: 1)),
                                 with: .color(.white.opacity(rng.next() * 0.08)))
                }
            }
            LinearGradient(colors: [.clear, .black.opacity(0.25)], startPoint: .center, endPoint: .bottom)
        }
        .drawingGroup()
        .clipped()
        .accessibilityHidden(true)
    }
}

private struct PhotoLook {
    var colors: [Color]
    var light: Color
    var lights: Int
    var symbol: String
    var subjectOpacity: Double = 0.55

    static func make(_ scene: String) -> PhotoLook {
        switch scene {
        case "sunset": PhotoLook(colors: [Color(hex: 0xF08A4B), Color(hex: 0x5B2A4E), Color(hex: 0x1A1026)], light: Color(hex: 0xFFD08A), lights: 2, symbol: "sun.horizon.fill")
        case "sky": PhotoLook(colors: [Color(hex: 0x3D8BD9), Color(hex: 0x9CC8F0)], light: .white, lights: 1, symbol: "cloud.fill", subjectOpacity: 0.35)
        case "rain": PhotoLook(colors: [Color(hex: 0x3B4652), Color(hex: 0x1E252D)], light: Color(hex: 0xB9C7D6), lights: 5, symbol: "cloud.rain.fill", subjectOpacity: 0.3)
        case "street_day": PhotoLook(colors: [Color(hex: 0x9BB7CF), Color(hex: 0x6E6A63), Color(hex: 0x3E3A36)], light: .white, lights: 2, symbol: "building.2.fill")
        case "street_night": PhotoLook(colors: [Color(hex: 0x10151F), Color(hex: 0x1C2330), Color(hex: 0x0B0D12)], light: Color(hex: 0xFFB35C), lights: 6, symbol: "lamp.floor.fill", subjectOpacity: 0.35)
        case "parking_night": PhotoLook(colors: [Color(hex: 0x0D1117), Color(hex: 0x1D2733), Color(hex: 0x080A0D)], light: Color(hex: 0xFF3B30), lights: 3, symbol: "car.rear.fill", subjectOpacity: 0.4)
        case "concert": PhotoLook(colors: [Color(hex: 0x2A0F45), Color(hex: 0x120720)], light: Color(hex: 0xB45CFF), lights: 7, symbol: "music.mic", subjectOpacity: 0.4)
        case "bar": PhotoLook(colors: [Color(hex: 0x3A2414), Color(hex: 0x1C120B)], light: Color(hex: 0xFFB35C), lights: 6, symbol: "wineglass.fill", subjectOpacity: 0.4)
        case "party": PhotoLook(colors: [Color(hex: 0x3B1D3A), Color(hex: 0x1B0F22)], light: Color(hex: 0xFFE08A), lights: 9, symbol: "balloon.2.fill")
        case "group", "selfie": PhotoLook(colors: [Color(hex: 0x4A3A2E), Color(hex: 0x23201D)], light: Color(hex: 0xFFC98A), lights: 4, symbol: "person.3.fill")
        case "gallery": PhotoLook(colors: [Color(hex: 0xD9D4CC), Color(hex: 0x8C857B)], light: .white, lights: 3, symbol: "photo.artframe")
        case "climbing": PhotoLook(colors: [Color(hex: 0x5C6B7A), Color(hex: 0x2B323A)], light: .white, lights: 3, symbol: "figure.climbing")
        case "cat": PhotoLook(colors: [Color(hex: 0x8A6F55), Color(hex: 0x3D3128)], light: Color(hex: 0xFFE0B0), lights: 1, symbol: "cat.fill")
        case "books": PhotoLook(colors: [Color(hex: 0x5A4636), Color(hex: 0x2A211A)], light: Color(hex: 0xFFE0B0), lights: 2, symbol: "books.vertical.fill")
        case "interior_warm": PhotoLook(colors: [Color(hex: 0x7A5C44), Color(hex: 0x3A2B20)], light: Color(hex: 0xFFCF8A), lights: 3, symbol: "sofa.fill")
        case "bed": PhotoLook(colors: [Color(hex: 0x6F7C8C), Color(hex: 0x3C3A44), Color(hex: 0x24222A)], light: Color(hex: 0xDDE8FF), lights: 2, symbol: "bed.double.fill")
        case "station": PhotoLook(colors: [Color(hex: 0x6D7680), Color(hex: 0x2F353B)], light: .white, lights: 4, symbol: "tram.fill")
        case "laptop": PhotoLook(colors: [Color(hex: 0x2C3440), Color(hex: 0x14181E)], light: Color(hex: 0x6FB7FF), lights: 2, symbol: "laptopcomputer")
        case "desk_night": PhotoLook(colors: [Color(hex: 0x2A2621), Color(hex: 0x12100E)], light: Color(hex: 0xFFD27A), lights: 3, symbol: "bell.fill", subjectOpacity: 0.4)
        case "car": PhotoLook(colors: [Color(hex: 0x8E9AA6), Color(hex: 0x4B525A)], light: .white, lights: 2, symbol: "car.side.fill")
        case "park": PhotoLook(colors: [Color(hex: 0x7FA36B), Color(hex: 0x3C5230)], light: Color(hex: 0xFFF3C4), lights: 3, symbol: "tree.fill")
        case "plant": PhotoLook(colors: [Color(hex: 0x5D7A52), Color(hex: 0x2A3826)], light: Color(hex: 0xFFF3C4), lights: 2, symbol: "leaf.fill")
        case "document": PhotoLook(colors: [Color(hex: 0xE8E4DC), Color(hex: 0xB8B2A8)], light: .white, lights: 1, symbol: "doc.text.fill", subjectOpacity: 0.5)
        case "screenshot": PhotoLook(colors: [Color(hex: 0x1C1C1E), Color(hex: 0x2C2C2E)], light: Color(hex: 0x0A84FF), lights: 1, symbol: "text.alignleft", subjectOpacity: 0.5)
        default: PhotoLook(colors: [Color(hex: 0x444444), Color(hex: 0x222222)], light: .white, lights: 2, symbol: "photo")
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
