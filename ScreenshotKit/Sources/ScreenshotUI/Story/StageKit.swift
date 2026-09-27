#if os(iOS)
import SceneKit
import Metal
import UIKit
import StoryEngine

// The story's 3D stage (SceneKit): rooms, furniture and people built from simple shapes, in a
// sober, stylised look — matte materials, warm practical lights, soft shadows, no textures to
// download. Everything comes from the story's data (StoryLocation, CharacterAppearance): the same
// data always gives the same picture. Real 3D models can replace any piece later (see
// docs/story/SCENE_SYSTEM.md, « Assets à produire ») without touching the story.

/// Colours of the stage that are not in the data (skin shading, metal, glass…).
enum StagePalette {
    static let metal = UIColor(white: 0.55, alpha: 1)
    static let darkMetal = UIColor(white: 0.18, alpha: 1)
    static let screen = UIColor(red: 0.30, green: 0.42, blue: 0.55, alpha: 1)
    static let screenOff = UIColor(white: 0.06, alpha: 1)
    static let glass = UIColor(red: 0.62, green: 0.72, blue: 0.80, alpha: 0.35)
    static let paper = UIColor(red: 0.93, green: 0.91, blue: 0.86, alpha: 1)
    static let kraft = UIColor(red: 0.69, green: 0.54, blue: 0.35, alpha: 1)
    static let leaf = UIColor(red: 0.25, green: 0.38, blue: 0.24, alpha: 1)
    static let pot = UIColor(red: 0.45, green: 0.30, blue: 0.22, alpha: 1)
    static let warmLight = UIColor(red: 1.0, green: 0.86, blue: 0.68, alpha: 1)
    static let coolLight = UIColor(red: 0.80, green: 0.87, blue: 1.0, alpha: 1)
    static let brass = UIColor(red: 0.78, green: 0.64, blue: 0.24, alpha: 1)
    static let shoe = UIColor(white: 0.08, alpha: 1)
    static let trousers = UIColor(white: 0.14, alpha: 1)
    static let lens = UIColor(white: 0.9, alpha: 0.25)
    static let lip = UIColor(red: 0.55, green: 0.30, blue: 0.28, alpha: 1)
    static let background = UIColor(red: 0.04, green: 0.04, blue: 0.05, alpha: 1)
    /// Light temperatures (STORY_ART_DIRECTION §3).
    static let neon4000 = UIColor(red: 1.0, green: 0.93, blue: 0.86, alpha: 1)
    static let neon3500 = UIColor(red: 1.0, green: 0.90, blue: 0.80, alpha: 1)
    static let neon5000 = UIColor(red: 0.97, green: 0.97, blue: 1.0, alpha: 1)
    static let lamp2700 = UIColor(red: 1.0, green: 0.78, blue: 0.52, alpha: 1)
    static let sodium = UIColor(red: 1.0, green: 0.62, blue: 0.28, alpha: 1)
    /// Red only on objects that mean something: the recording light, a seal.
    static let signalRed = UIColor(red: 0.72, green: 0.13, blue: 0.10, alpha: 1)
    static let benBlue = UIColor(red: 0.435, green: 0.478, blue: 0.525, alpha: 1)
    static let cardWhite = UIColor(red: 0.95, green: 0.95, blue: 0.93, alpha: 1)
}

/// The 3D quality profile (3D_DIRECTION §9, h19 « Qualité »).
@MainActor
enum StageQuality {
    static var profile: StoryPreferences.Quality { StoryPreferences.quality }
    static var shadows: Bool { profile != .economy }
    static var shadowMapSize: CGFloat { profile == .high ? 2048 : 1024 }
    static var shadowSamples: Int { profile == .high ? 16 : 8 }
    static var framesPerSecond: Int { profile == .high ? 60 : 30 }
    static var antialiasing: SCNAntialiasingMode { profile == .economy ? .none : .multisampling4X }
    /// Only in « Haute » (the first captures were blurred everywhere in « Auto »).
    static var depthOfField: Bool { profile == .high && StoryPreferences.depthOfField }
}

/// Global level of the sets' lights and of the stage camera's exposure.
enum StageLighting {
    static let scale: CGFloat = 0.4
    /// Exposure offset of the stage and studio cameras (EV).
    static let exposure: CGFloat = -0.8
}

extension UIColor {
    /// « #RRGGBB » (the story's data); grey when unreadable.
    convenience init(storyHex hex: String?) {
        guard let hex, hex.count == 7, hex.hasPrefix("#"), let value = UInt32(hex.dropFirst(), radix: 16) else {
            self.init(white: 0.5, alpha: 1)
            return
        }
        self.init(red: CGFloat((value >> 16) & 0xFF) / 255, green: CGFloat((value >> 8) & 0xFF) / 255,
                  blue: CGFloat(value & 0xFF) / 255, alpha: 1)
    }
}

// MARK: - Materials

enum StageMaterial {
    static func matte(_ color: UIColor, roughness: CGFloat = 0.85) -> SCNMaterial {
        let m = SCNMaterial()
        m.lightingModel = .physicallyBased
        m.diffuse.contents = color
        m.roughness.contents = roughness
        m.metalness.contents = 0.0
        return m
    }

    static func metal(_ color: UIColor) -> SCNMaterial {
        let m = matte(color, roughness: 0.35)
        m.metalness.contents = 0.8
        return m
    }

    static func emissive(_ color: UIColor, intensity: CGFloat = 1) -> SCNMaterial {
        let m = SCNMaterial()
        m.lightingModel = .constant
        m.diffuse.contents = color
        m.emission.contents = color
        m.emission.intensity = intensity
        return m
    }

    static func glass() -> SCNMaterial {
        let m = SCNMaterial()
        m.lightingModel = .physicallyBased
        m.diffuse.contents = StagePalette.glass
        m.transparency = 0.4
        m.roughness.contents = 0.05
        m.isDoubleSided = true
        return m
    }
}

extension SCNNode {
    /// A box sitting on y = 0 (its base on the floor), centred in x and z.
    static func block(_ w: CGFloat, _ h: CGFloat, _ d: CGFloat, _ material: SCNMaterial, chamfer: CGFloat = 0.01) -> SCNNode {
        let box = SCNBox(width: w, height: h, length: d, chamferRadius: chamfer)
        box.materials = [material]
        let node = SCNNode(geometry: box)
        node.pivot = SCNMatrix4MakeTranslation(0, -Float(h) / 2, 0)
        return node
    }

    func at(_ x: Double, _ y: Double, _ z: Double) -> SCNNode {
        position = SCNVector3(Float(x), Float(y), Float(z))
        return self
    }

    func turned(_ degrees: Double) -> SCNNode {
        eulerAngles.y = Float(degrees * .pi / 180)
        return self
    }
}

// MARK: - Rooms

/// Builds a room of the story: floor, walls (the camera side stays open), ceiling, lights and props.
@MainActor
enum StageBuilder {
    /// `level`: the player's office level (1–4). Hidden props are built but hidden until a scene
    /// shows them (`StageDirectorView` toggles them by name « prop_<id> »).
    static func room(_ location: StoryLocation, unlocked: Set<String>, level: Int = 4, text: (String) -> String) -> SCNNode {
        let root = SCNNode()
        root.name = "room_" + location.id
        let w = CGFloat(location.size[0]), d = CGFloat(location.size[1]), h = CGFloat(location.size[2])
        let wall = StageMaterial.matte(UIColor(storyHex: location.wallColor), roughness: 0.95)
        let floor = StageMaterial.matte(UIColor(storyHex: location.floorColor), roughness: 0.7)
        let accent = UIColor(storyHex: location.accentColor ?? location.wallColor)

        let floorNode = SCNNode.block(w, 0.02, d, floor, chamfer: 0).at(0, -0.02, 0)
        floorNode.name = "floor"
        root.addChildNode(floorNode)
        // Ceiling tiles (60 × 60 cm) read as a slightly lighter grid.
        root.addChildNode(SCNNode.block(w, 0.02, d, StageMaterial.matte(UIColor(white: 0.62, alpha: 1), roughness: 0.95), chamfer: 0).at(0, Double(h), 0))
        // Four walls: every camera is inside the room (the validator checks it).
        root.addChildNode(SCNNode.block(w, h, 0.08, wall, chamfer: 0).at(0, 0, -Double(d) / 2 - 0.04))
        root.addChildNode(SCNNode.block(w, h, 0.08, wall, chamfer: 0).at(0, 0, Double(d) / 2 + 0.04))
        root.addChildNode(SCNNode.block(0.08, h, d, wall, chamfer: 0).at(-Double(w) / 2 - 0.04, 0, 0))
        root.addChildNode(SCNNode.block(0.08, h, d, wall, chamfer: 0).at(Double(w) / 2 + 0.04, 0, 0))
        // Skirting in the accent colour, on the four sides.
        let skirting = StageMaterial.matte(accent, roughness: 0.6)
        root.addChildNode(SCNNode.block(w, 0.1, 0.02, skirting, chamfer: 0).at(0, 0, -Double(d) / 2 + 0.01))
        root.addChildNode(SCNNode.block(w, 0.1, 0.02, skirting, chamfer: 0).at(0, 0, Double(d) / 2 - 0.01))
        root.addChildNode(SCNNode.block(0.02, 0.1, d, skirting, chamfer: 0).at(-Double(w) / 2 + 0.01, 0, 0))
        root.addChildNode(SCNNode.block(0.02, 0.1, d, skirting, chamfer: 0).at(Double(w) / 2 - 0.01, 0, 0))

        for prop in location.props(unlocked: unlocked, level: level) {
            let node = self.prop(prop, text: text)
            node.name = "prop_" + prop.id
            node.isHidden = prop.hidden == true
            root.addChildNode(node.at(prop.x, prop.y ?? 0, prop.z).turned(prop.rotation ?? 0))
        }
        for light in lights(for: location) { root.addChildNode(light) }
        return root
    }

    // MARK: Lights

    static func lights(for location: StoryLocation) -> [SCNNode] {
        let w = location.size[0], d = location.size[1], h = location.size[2]
        func light(_ type: SCNLight.LightType, _ color: UIColor, _ intensity: CGFloat, at p: SCNVector3, shadows: Bool = false) -> SCNNode {
            let l = SCNLight()
            l.type = type
            l.color = color
            l.intensity = intensity
            if shadows {
                l.castsShadow = true
                l.shadowMode = .deferred
                l.shadowRadius = 8
                l.shadowSampleCount = StageQuality.shadowSamples
                l.shadowMapSize = CGSize(width: StageQuality.shadowMapSize, height: StageQuality.shadowMapSize)
                l.shadowColor = UIColor(white: 0, alpha: 0.45)
            }
            if type == .spot {
                l.spotInnerAngle = 30
                l.spotOuterAngle = 80
            }
            let n = SCNNode()
            n.light = l
            n.position = p
            return n
        }
        var result: [SCNNode] = []
        let ambient: (UIColor, CGFloat)
        let key: (UIColor, CGFloat)
        switch location.lighting {
        // Office 312 at night: the green lamp (2 700 K) leads, the street's sodium behind the blinds.
        case "office_night": ambient = (StagePalette.coolLight, 70); key = (StagePalette.lamp2700, 520)
        case "office_evening": ambient = (StagePalette.warmLight, 180); key = (StagePalette.warmLight, 900)
        case "archive": ambient = (StagePalette.neon3500, 90); key = (StagePalette.neon3500, 650)
        case "interrogation": ambient = (StagePalette.neon5000, 110); key = (StagePalette.neon5000, 1150)
        case "corridor": ambient = (StagePalette.neon4000, 150); key = (StagePalette.neon4000, 620)
        case "openspace": ambient = (StagePalette.neon4000, 200); key = (StagePalette.neon4000, 700)
        case "briefing": ambient = (StagePalette.neon4000, 160); key = (StagePalette.neon4000, 600)
        default: ambient = (StagePalette.coolLight, 220); key = (UIColor.white, 800)
        }
        result.append(light(.ambient, ambient.0, ambient.1, at: SCNVector3(0, Float(h), 0)))
        // One dynamic key light with soft shadows for the people (3D_DIRECTION §5).
        let keyNode = light(.spot, key.0, key.1, at: SCNVector3(Float(w) * 0.2, Float(h) - 0.1, Float(d) * 0.15), shadows: StageQuality.shadows)
        keyNode.look(at: SCNVector3(0, 0, -Float(d) * 0.15))
        result.append(keyNode)
        // A low fill from the room's front, never red, never coloured.
        let fill = light(.omni, StagePalette.coolLight, key.1 * 0.18, at: SCNVector3(0, 1.6, Float(d) / 2 - 0.3))
        fill.light?.attenuationEndDistance = CGFloat(max(w, d)) * 1.2
        result.append(fill)
        switch location.lighting {
        case "office_night":
            // Sodium street light through the window (2 100 K), a back light.
            let sodium = light(.spot, StagePalette.sodium, 380, at: SCNVector3(0.8, 2.2, -Float(d) / 2 - 0.6))
            sodium.look(at: SCNVector3(0, 0.8, 0))
            result.append(sodium)
        case "interrogation":
            let top = light(.spot, StagePalette.neon5000, 700, at: SCNVector3(0, Float(h) - 0.05, 0), shadows: StageQuality.shadows)
            top.look(at: SCNVector3(0, 0, 0))
            result.append(top)
        case "corridor":
            // Neons every few metres down the corridor.
            var z = Float(d) / 2 - 2
            while z > -Float(d) / 2 {
                let n = light(.omni, StagePalette.neon4000, 160, at: SCNVector3(0, Float(h) - 0.2, z))
                n.light?.attenuationEndDistance = 4
                result.append(n)
                z -= 4
            }
        default:
            break
        }
        // Physically based materials: the presets are written for a daylight studio; the BEN at
        // night is darker (CI captures of the first build were blown out by about 6×).
        for node in result { node.light?.intensity *= StageLighting.scale }
        return result
    }

    // MARK: Props

    static func prop(_ prop: StageProp, text: (String) -> String) -> SCNNode {
        let color = prop.color.map { UIColor(storyHex: $0) }
        let size = prop.size
        func dim(_ i: Int, _ fallback: Double) -> CGFloat { CGFloat(size.flatMap { $0.count > i ? $0[i] : nil } ?? fallback) }
        let node = SCNNode()
        switch prop.kind {
        case "desk", "table":
            let w = dim(0, prop.kind == "desk" ? 1.6 : 2.0), d = dim(1, 0.8), h = dim(2, 0.76)
            let top = StageMaterial.matte(color ?? UIColor(red: 0.30, green: 0.22, blue: 0.16, alpha: 1), roughness: 0.55)
            node.addChildNode(SCNNode.block(w, 0.05, d, top).at(0, Double(h) - 0.05, 0))
            let leg = StageMaterial.metal(StagePalette.darkMetal)
            for (sx, sz) in [(-1.0, -1.0), (1.0, -1.0), (-1.0, 1.0), (1.0, 1.0)] {
                node.addChildNode(SCNNode.block(0.05, h - 0.05, 0.05, leg).at(sx * Double(w / 2 - 0.06), 0, sz * Double(d / 2 - 0.06)))
            }
            if prop.kind == "desk" {
                node.addChildNode(SCNNode.block(w * 0.35, h * 0.6, d * 0.9, top).at(Double(w) * 0.3, Double(h) * 0.35, 0))
            }
        case "chair":
            let seat = StageMaterial.matte(color ?? UIColor(white: 0.16, alpha: 1), roughness: 0.6)
            node.addChildNode(SCNNode.block(0.48, 0.07, 0.46, seat).at(0, 0.44, 0))
            node.addChildNode(SCNNode.block(0.48, 0.5, 0.06, seat).at(0, 0.5, -0.21))
            node.addChildNode(SCNNode.block(0.06, 0.44, 0.06, StageMaterial.metal(StagePalette.darkMetal)).at(0, 0, 0))
            node.addChildNode(SCNNode.block(0.5, 0.03, 0.5, StageMaterial.metal(StagePalette.darkMetal)).at(0, 0, 0))
        case "shelf", "cabinet":
            let w = dim(0, 1.2), d = dim(1, 0.35), h = dim(2, 2.0)
            let wood = StageMaterial.matte(color ?? UIColor(red: 0.26, green: 0.22, blue: 0.19, alpha: 1))
            node.addChildNode(SCNNode.block(w, h, 0.03, wood).at(0, 0, -Double(d) / 2))
            for i in 0...4 {
                let y = Double(i) * Double(h) / 4
                node.addChildNode(SCNNode.block(w, 0.03, d, wood).at(0, min(y, Double(h) - 0.03), 0))
                if i < 4 {
                    // Binders and boxes, deterministic widths.
                    var x = -Double(w) / 2 + 0.05
                    var k = i
                    while x < Double(w) / 2 - 0.12 {
                        let bw = 0.06 + Double((k * 7) % 5) * 0.02
                        let tone: UIColor = k % 3 == 0 ? StagePalette.kraft : (k % 3 == 1 ? StagePalette.paper : UIColor(red: 0.2, green: 0.26, blue: 0.34, alpha: 1))
                        node.addChildNode(SCNNode.block(CGFloat(bw), CGFloat(Double(h) / 4 * 0.75), d * 0.8, StageMaterial.matte(tone)).at(x + bw / 2, y + 0.03, 0))
                        x += bw + 0.01
                        k += 1
                    }
                }
            }
        case "door":
            let frame = StageMaterial.matte(UIColor(white: 0.2, alpha: 1))
            node.addChildNode(SCNNode.block(1.0, 2.15, 0.06, StageMaterial.matte(color ?? UIColor(red: 0.33, green: 0.30, blue: 0.27, alpha: 1))).at(0, 0, 0))
            node.addChildNode(SCNNode.block(1.1, 0.06, 0.08, frame).at(0, 2.15, 0))
            node.addChildNode(SCNNode.block(0.08, 0.03, 0.05, StageMaterial.metal(StagePalette.metal)).at(0.38, 1.05, 0.05))
            if let label = prop.label { node.addChildNode(textPlate(text(label), width: 0.5, color: StagePalette.paper).at(0, 1.55, 0.04)) }
        case "window":
            let w = dim(0, 1.4), h = dim(2, 1.2)
            let glass = SCNNode(geometry: SCNPlane(width: w, height: h))
            glass.geometry?.materials = [StageMaterial.emissive(UIColor(red: 0.55, green: 0.63, blue: 0.72, alpha: 1), intensity: 0.6)]
            node.addChildNode(glass.at(0, Double(h) / 2, 0.01))
            let frame = StageMaterial.matte(UIColor(white: 0.85, alpha: 1))
            node.addChildNode(SCNNode.block(w + 0.08, 0.05, 0.08, frame).at(0, -0.02, 0))
            node.addChildNode(SCNNode.block(w + 0.08, 0.05, 0.08, frame).at(0, Double(h), 0))
            node.addChildNode(SCNNode.block(0.04, h, 0.06, frame).at(0, 0, 0))
        case "lamp":
            node.addChildNode(SCNNode.block(0.14, 0.02, 0.14, StageMaterial.metal(StagePalette.darkMetal)).at(0, 0, 0))
            node.addChildNode(SCNNode.block(0.02, 0.38, 0.02, StageMaterial.metal(StagePalette.darkMetal)).at(0, 0.02, 0))
            let shade = SCNNode(geometry: SCNCone(topRadius: 0.05, bottomRadius: 0.12, height: 0.14))
            shade.geometry?.materials = [StageMaterial.matte(color ?? UIColor(red: 0.15, green: 0.27, blue: 0.2, alpha: 1))]
            node.addChildNode(shade.at(0, 0.44, 0))
            let bulb = SCNLight()
            bulb.type = .omni
            bulb.color = StagePalette.warmLight
            bulb.intensity = 40
            bulb.attenuationStartDistance = 0.2
            bulb.attenuationEndDistance = 1.8
            let bulbNode = SCNNode()
            bulbNode.light = bulb
            node.addChildNode(bulbNode.at(0, 0.36, 0))
        case "computer":
            node.addChildNode(SCNNode.block(0.56, 0.34, 0.03, StageMaterial.matte(StagePalette.darkMetal)).at(0, 0.12, 0))
            let screen = SCNNode(geometry: SCNPlane(width: 0.52, height: 0.3))
            screen.geometry?.materials = [StageMaterial.emissive(StagePalette.screen, intensity: 0.8)]
            node.addChildNode(screen.at(0, 0.29, 0.017))
            node.addChildNode(SCNNode.block(0.06, 0.12, 0.06, StageMaterial.metal(StagePalette.metal)).at(0, 0, -0.02))
            node.addChildNode(SCNNode.block(0.42, 0.015, 0.14, StageMaterial.matte(UIColor(white: 0.2, alpha: 1))).at(0, 0, 0.22))
        case "phone":
            node.addChildNode(SCNNode.block(0.08, 0.01, 0.16, StageMaterial.matte(StagePalette.screenOff, roughness: 0.2)).at(0, 0, 0))
        case "file", "files":
            let count = prop.kind == "files" ? 4 : 1
            for i in 0..<count {
                let folder = SCNNode.block(0.32, 0.02, 0.24, StageMaterial.matte(color ?? StagePalette.kraft, roughness: 0.9))
                node.addChildNode(folder.at(Double(i % 2) * 0.04, Double(i) * 0.022, Double(i) * 0.01).turned(Double(i * 7)))
            }
            node.addChildNode(SCNNode.block(0.3, 0.005, 0.22, StageMaterial.matte(StagePalette.paper)).at(0.01, Double(count) * 0.022, 0))
        case "board":
            let w = dim(0, 1.8), h = dim(2, 1.1)
            node.addChildNode(SCNNode.block(w, h, 0.04, StageMaterial.matte(color ?? UIColor(red: 0.42, green: 0.35, blue: 0.27, alpha: 1))).at(0, 0, 0))
            // Pinned papers and photos (deterministic layout).
            for i in 0..<7 {
                let px = -Double(w) / 2 + 0.2 + Double(i) * Double(w - 0.4) / 6
                let py = 0.2 + Double((i * 5) % 3) * Double(h - 0.45) / 2
                let sheet = SCNNode(geometry: SCNPlane(width: 0.16, height: 0.2))
                sheet.geometry?.materials = [StageMaterial.matte(i % 2 == 0 ? StagePalette.paper : UIColor(white: 0.3, alpha: 1))]
                node.addChildNode(sheet.at(px, py + 0.1, 0.025))
            }
        case "plant":
            let pot = SCNNode(geometry: SCNCylinder(radius: 0.14, height: 0.3))
            pot.geometry?.materials = [StageMaterial.matte(StagePalette.pot)]
            node.addChildNode(pot.at(0, 0.15, 0))
            for i in 0..<5 {
                let leaf = SCNNode(geometry: SCNSphere(radius: 0.16))
                leaf.geometry?.materials = [StageMaterial.matte(StagePalette.leaf)]
                leaf.scale = SCNVector3(0.9, 1.3, 0.9)
                let a = Double(i) * 1.26
                node.addChildNode(leaf.at(cos(a) * 0.1, 0.55 + Double(i % 2) * 0.12, sin(a) * 0.1))
            }
        case "plaque":
            if let label = prop.label {
                node.addChildNode(textPlate(text(label), width: 0.9, color: color ?? StagePalette.brass, dark: true))
            }
        case "frame":
            node.addChildNode(SCNNode.block(0.5, 0.36, 0.03, StageMaterial.matte(UIColor(white: 0.1, alpha: 1))))
            let picture = SCNNode(geometry: SCNPlane(width: 0.42, height: 0.28))
            picture.geometry?.materials = [StageMaterial.matte(color ?? UIColor(red: 0.35, green: 0.40, blue: 0.45, alpha: 1))]
            node.addChildNode(picture.at(0, 0.18, 0.017))
        case "trophy":
            node.addChildNode(SCNNode.block(0.3, 0.22, 0.03, StageMaterial.matte(UIColor(red: 0.18, green: 0.22, blue: 0.3, alpha: 1))))
            node.addChildNode(SCNNode.block(0.12, 0.12, 0.01, StageMaterial.metal(StagePalette.brass)).at(0, 0.05, 0.02))
        case "coffee":
            let cup = SCNNode(geometry: SCNCylinder(radius: 0.04, height: 0.09))
            cup.geometry?.materials = [StageMaterial.matte(StagePalette.paper)]
            node.addChildNode(cup.at(0, 0.045, 0))
        case "bench", "sofa":
            let fabric = StageMaterial.matte(color ?? UIColor(white: 0.22, alpha: 1))
            node.addChildNode(SCNNode.block(1.4, 0.45, 0.45, fabric))
            if prop.kind == "sofa" { node.addChildNode(SCNNode.block(1.4, 0.45, 0.12, fabric).at(0, 0.45, -0.17)) }
        case "mirror":
            let w = dim(0, 2.0), h = dim(2, 1.1)
            let glass = SCNNode(geometry: SCNPlane(width: w, height: h))
            glass.geometry?.materials = [StageMaterial.metal(UIColor(white: 0.25, alpha: 1))]
            node.addChildNode(glass.at(0, Double(h) / 2, 0.01))
        case "partition":
            // Glass partition with a thin metal frame.
            let w = dim(0, 3.0), h = dim(2, 2.6)
            let glass = SCNNode(geometry: SCNBox(width: w, height: h - 0.9, length: 0.02, chamferRadius: 0))
            glass.geometry?.materials = [StageMaterial.glass()]
            node.addChildNode(glass.at(0, Double(h) / 2 + 0.45, 0))
            node.addChildNode(SCNNode.block(w, 0.9, 0.06, StageMaterial.matte(UIColor(white: 0.5, alpha: 1))).at(0, 0, 0))
            node.addChildNode(SCNNode.block(0.04, h, 0.06, StageMaterial.metal(StagePalette.metal)).at(Double(w) / 2, 0, 0))
        case "neon":
            let panel = SCNNode(geometry: SCNBox(width: 1.2, height: 0.03, length: 0.3, chamferRadius: 0))
            panel.geometry?.materials = [StageMaterial.emissive(StagePalette.neon4000, intensity: 0.85)]
            node.addChildNode(panel)
            if prop.flicker == true {
                // A neon that crackles now and then (never a strobe).
                let off = SCNAction.fadeOpacity(to: 0.35, duration: 0.05)
                let on = SCNAction.fadeOpacity(to: 1, duration: 0.05)
                panel.runAction(.repeatForever(.sequence([.wait(duration: 5.5, withRange: 3), off, on, .wait(duration: 0.12), off, on])))
            }
        case "light_panel":
            let panel = SCNNode(geometry: SCNBox(width: 1.2, height: 0.03, length: 0.3, chamferRadius: 0))
            panel.geometry?.materials = [StageMaterial.emissive(UIColor(white: 0.95, alpha: 1), intensity: 0.9)]
            node.addChildNode(panel)
        case "fountain":
            node.addChildNode(SCNNode.block(0.32, 0.95, 0.32, StageMaterial.matte(UIColor(white: 0.85, alpha: 1))))
            let bottle = SCNNode(geometry: SCNCylinder(radius: 0.13, height: 0.42))
            bottle.geometry?.materials = [StageMaterial.glass()]
            node.addChildNode(bottle.at(0, 1.16, 0))
        case "cart":
            let metal = StageMaterial.metal(StagePalette.metal)
            for y in [0.15, 0.55, 0.9] { node.addChildNode(SCNNode.block(0.8, 0.02, 0.45, metal).at(0, y, 0)) }
            for (sx, sz) in [(-1.0, -1.0), (1.0, -1.0), (-1.0, 1.0), (1.0, 1.0)] {
                node.addChildNode(SCNNode.block(0.02, 0.92, 0.02, metal).at(sx * 0.39, 0.02, sz * 0.21))
            }
            for i in 0..<5 {
                node.addChildNode(SCNNode.block(0.06, 0.3, 0.32, StageMaterial.matte(i % 2 == 0 ? StagePalette.kraft : StagePalette.benBlue)).at(-0.3 + Double(i) * 0.14, 0.57, 0))
            }
        case "sign", "poster":
            if let label = prop.label {
                let plate = textPlate(text(label), width: prop.kind == "sign" ? 1.6 : 0.6, color: prop.kind == "sign" ? StagePalette.benBlue : StagePalette.paper)
                node.addChildNode(plate)
            }
        case "radiator":
            let iron = StageMaterial.matte(UIColor(white: 0.72, alpha: 1), roughness: 0.5)
            for i in 0..<9 { node.addChildNode(SCNNode.block(0.06, 0.6, 0.12, iron).at(-0.32 + Double(i) * 0.08, 0.12, 0)) }
        case "blinds":
            let w = dim(0, 1.4), h = dim(2, 1.3)
            let slat = StageMaterial.matte(UIColor(white: 0.78, alpha: 1), roughness: 0.6)
            var y = 0.02
            while y < Double(h) {
                let s = SCNNode.block(w, 0.012, 0.035, slat).at(0, y, 0)
                s.eulerAngles.x = 0.5
                node.addChildNode(s)
                y += 0.05
            }
        case "desk_phone":
            let body = StageMaterial.matte(UIColor(white: 0.15, alpha: 1), roughness: 0.4)
            node.addChildNode(SCNNode.block(0.2, 0.06, 0.18, body))
            node.addChildNode(SCNNode.block(0.2, 0.04, 0.06, body).at(0, 0.065, -0.04))
            node.addChildNode(SCNNode.block(0.08, 0.004, 0.06, StageMaterial.emissive(StagePalette.screen, intensity: 0.5)).at(0.03, 0.061, 0.04))
        case "frame_down":
            // A photo frame laid face down: only its back shows.
            node.addChildNode(SCNNode.block(0.22, 0.015, 0.17, StageMaterial.matte(UIColor(white: 0.1, alpha: 1))))
        case "mug":
            let cup = SCNNode(geometry: SCNCylinder(radius: 0.042, height: 0.1))
            cup.geometry?.materials = [StageMaterial.matte(color ?? UIColor(white: 0.9, alpha: 1), roughness: 0.4)]
            node.addChildNode(cup.at(0, 0.05, 0))
        case "folder":
            // A file (kraft, or BEN blue-grey for an agent's file) with its label.
            let folder = SCNNode.block(0.33, 0.012, 0.25, StageMaterial.matte(color ?? StagePalette.kraft, roughness: 0.9))
            node.addChildNode(folder)
            node.addChildNode(SCNNode.block(0.33, 0.002, 0.004, StageMaterial.matte(UIColor(white: 0.1, alpha: 1))).at(0, 0.013, 0.08))
            if let label = prop.label {
                let plate = textPlate(text(label), width: 0.16, color: StagePalette.paper)
                plate.eulerAngles.x = -.pi / 2
                node.addChildNode(plate.at(0.05, 0.016, -0.02))
            }
        case "evidence_bag":
            let bag = SCNNode.block(0.2, 0.012, 0.3, StageMaterial.glass())
            node.addChildNode(bag)
            node.addChildNode(SCNNode.block(0.075, 0.009, 0.15, StageMaterial.matte(StagePalette.screenOff, roughness: 0.2)).at(0, 0.002, 0.01))
            node.addChildNode(SCNNode.block(0.2, 0.004, 0.025, StageMaterial.matte(StagePalette.signalRed)).at(0, 0.013, -0.13))
        case "card":
            node.addChildNode(SCNNode.block(0.086, 0.004, 0.054, StageMaterial.matte(StagePalette.cardWhite, roughness: 0.3)))
            node.addChildNode(SCNNode.block(0.086, 0.001, 0.014, StageMaterial.matte(StagePalette.benBlue)).at(0, 0.004, -0.02))
            if let label = prop.label {
                let plate = textPlate(text(label), width: 0.08, color: StagePalette.cardWhite)
                plate.scale = SCNVector3(0.5, 0.5, 0.5)
                plate.eulerAngles.x = -.pi / 2
                node.addChildNode(plate.at(0, 0.006, 0.012))
            }
        case "coat_rack":
            let wood = StageMaterial.matte(UIColor(red: 0.30, green: 0.22, blue: 0.16, alpha: 1))
            node.addChildNode(SCNNode.block(0.05, 1.75, 0.05, wood))
            node.addChildNode(SCNNode.block(0.4, 0.03, 0.4, wood))
            let coat = SCNNode(geometry: SCNCapsule(capRadius: 0.13, height: 0.8))
            coat.geometry?.materials = [StageMaterial.matte(UIColor(red: 0.23, green: 0.26, blue: 0.31, alpha: 1))]
            node.addChildNode(coat.at(0.1, 1.25, 0))
        case "column":
            node.addChildNode(SCNNode.block(0.5, 2.6, 0.5, StageMaterial.matte(UIColor(white: 0.55, alpha: 1), roughness: 0.95)))
        case "archive_box":
            node.addChildNode(SCNNode.block(0.4, 0.26, 0.3, StageMaterial.matte(StagePalette.kraft, roughness: 0.95)))
            if let label = prop.label { node.addChildNode(textPlate(text(label), width: 0.3, color: StagePalette.paper).at(0, 0.14, 0.152)) }
        case "ladder":
            let metal = StageMaterial.metal(StagePalette.metal)
            for side in [-1.0, 1.0] { node.addChildNode(SCNNode.block(0.03, 1.6, 0.03, metal).at(side * 0.2, 0, 0)) }
            for i in 1...5 { node.addChildNode(SCNNode.block(0.4, 0.02, 0.05, metal).at(0, Double(i) * 0.3, 0)) }
        case "mic":
            node.addChildNode(SCNNode.block(0.08, 0.01, 0.08, StageMaterial.matte(UIColor(white: 0.1, alpha: 1))))
            node.addChildNode(SCNNode.block(0.01, 0.18, 0.01, StageMaterial.metal(StagePalette.darkMetal)))
            let head = SCNNode(geometry: SCNSphere(radius: 0.02))
            head.geometry?.materials = [StageMaterial.matte(UIColor(white: 0.12, alpha: 1))]
            node.addChildNode(head.at(0, 0.2, 0))
        case "red_light":
            // The recording light: the only red light of the BEN.
            let lamp = SCNNode(geometry: SCNSphere(radius: 0.03))
            lamp.geometry?.materials = [StageMaterial.emissive(StagePalette.signalRed, intensity: 1)]
            node.addChildNode(lamp)
        case "wall_screen":
            let w = dim(0, 2.4), h = dim(2, 1.35)
            node.addChildNode(SCNNode.block(w + 0.04, h + 0.04, 0.04, StageMaterial.matte(UIColor(white: 0.05, alpha: 1))))
            let screen = SCNNode(geometry: SCNPlane(width: w, height: h))
            screen.geometry?.materials = [StageMaterial.emissive(StagePalette.screen, intensity: 0.35)]
            node.addChildNode(screen.at(0, Double(h) / 2 + 0.02, 0.022))
        case "whiteboard":
            let w = dim(0, 1.8), h = dim(2, 1.1)
            node.addChildNode(SCNNode.block(w, h, 0.03, StageMaterial.matte(UIColor(white: 0.93, alpha: 1), roughness: 0.3)))
        case "corkboard":
            let w = dim(0, 1.4), h = dim(2, 0.9)
            node.addChildNode(SCNNode.block(w, h, 0.03, StageMaterial.matte(UIColor(red: 0.62, green: 0.47, blue: 0.32, alpha: 1))))
            for i in 0..<6 {
                let px = -Double(w) / 2 + 0.18 + Double(i) * Double(w - 0.36) / 5
                let py = 0.18 + Double((i * 5) % 3) * Double(h - 0.36) / 2
                let sheet = SCNNode(geometry: SCNPlane(width: 0.14, height: 0.18))
                sheet.geometry?.materials = [StageMaterial.matte(i % 2 == 0 ? StagePalette.paper : UIColor(white: 0.35, alpha: 1))]
                node.addChildNode(sheet.at(px, py + 0.09, 0.02))
            }
            // The thread between the pieces (red only because it means something).
            let thread = SCNNode.block(CGFloat(w) - 0.4, 0.004, 0.004, StageMaterial.matte(StagePalette.signalRed)).at(0, Double(h) / 2, 0.022)
            thread.eulerAngles.z = 0.12
            node.addChildNode(thread)
        case "safe":
            node.addChildNode(SCNNode.block(0.55, 0.7, 0.5, StageMaterial.metal(UIColor(white: 0.25, alpha: 1))))
            let dial = SCNNode(geometry: SCNCylinder(radius: 0.05, height: 0.02))
            dial.geometry?.materials = [StageMaterial.metal(StagePalette.metal)]
            dial.eulerAngles.x = .pi / 2
            node.addChildNode(dial.at(0, 0.4, 0.26))
        case "armchair":
            let leather = StageMaterial.matte(UIColor(red: 0.25, green: 0.18, blue: 0.13, alpha: 1), roughness: 0.55)
            node.addChildNode(SCNNode.block(0.75, 0.45, 0.75, leather))
            node.addChildNode(SCNNode.block(0.75, 0.5, 0.15, leather).at(0, 0.45, -0.3))
        default:
            node.addChildNode(SCNNode.block(dim(0, 0.5), dim(2, 0.5), dim(1, 0.5), StageMaterial.matte(color ?? UIColor(white: 0.35, alpha: 1))))
        }
        return node
    }

    /// A small plate with engraved text (a door, the player's name plaque).
    static func textPlate(_ string: String, width: CGFloat, color: UIColor, dark: Bool = false) -> SCNNode {
        let node = SCNNode()
        let plate = SCNNode.block(width, 0.16, 0.015, StageMaterial.metal(color))
        node.addChildNode(plate.at(0, -0.08, 0))
        let text = SCNText(string: string, extrusionDepth: 0.002)
        text.font = UIFont.systemFont(ofSize: 1, weight: .semibold)
        text.flatness = 0.05
        text.materials = [StageMaterial.matte(dark ? UIColor(white: 0.08, alpha: 1) : UIColor(white: 0.1, alpha: 1))]
        let textNode = SCNNode(geometry: text)
        let (minB, maxB) = textNode.boundingBox
        let tw = CGFloat(maxB.x - minB.x), th = CGFloat(maxB.y - minB.y)
        let scale = Float(min((width - 0.06) / max(tw, 0.01), 0.1 / max(th, 0.01)))
        textNode.scale = SCNVector3(scale, scale, scale)
        textNode.position = SCNVector3(-Float(tw) * scale / 2 - minB.x * scale, -Float(th) * scale / 2 - minB.y * scale, 0.01)
        node.addChildNode(textNode)
        return node
    }
}

// MARK: - People

/// What a person wears beyond the outfit: NPC extras (« halfmoon_glasses », « tie »…) and the
/// player's rank details (CHARACTER_CUSTOMIZATION §6: plastic → metal BEN card, a scarf, a leather
/// document case, a lapel pin).
struct RigDetails {
    var extras: [String] = []
    var height: Double = 1.75
    var build: Double = 1
    var rank: StoryRank?

    static func npc(_ npc: StoryNPC) -> RigDetails {
        RigDetails(extras: npc.extras ?? [], height: npc.height ?? 1.75, build: npc.build ?? 1, rank: nil)
    }

    static func player(_ player: StoryPlayer, rank: StoryRank) -> RigDetails {
        RigDetails(extras: [], height: player.appearance.presentation == "presentation_m" ? 1.80 : 1.68, build: 1, rank: rank)
    }
}

/// A stylised person: legs, torso in the outfit, arms that can move, head, hair, eyes — from a
/// `CharacterAppearance`, at its height (1.55–1.95 m). Named parts so animations can find them:
/// « body », « torso », « head », « arm_l », « arm_r », « legs ». Real rigged models (USDZ) can
/// replace it later without touching the story (docs/story/SCENE_SYSTEM.md).
@MainActor
enum CharacterRig {
    static func make(_ appearance: CharacterAppearance, catalog: CharacterCatalog, name: String, details: RigDetails = RigDetails()) -> SCNNode {
        func variant(_ id: String) -> CharacterVariant? { catalog.variant(id) }
        func color(_ id: String, accent: Bool = false) -> UIColor {
            let v = variant(id)
            return UIColor(storyHex: accent ? (v?.accent ?? v?.color) : v?.color)
        }
        let root = SCNNode()
        root.name = name
        let body = SCNNode()
        body.name = "body"
        root.addChildNode(body)
        // Built at 1.75 m, then scaled to the person's height; the build widens the silhouette.
        let scale = Float(details.height / 1.75)
        root.scale = SCNVector3(scale * Float(details.build), scale, scale * Float(min(1.1, details.build)))

        let skin = StageMaterial.matte(color(appearance.skinTone), roughness: 0.5)
        let outfitShape = variant(appearance.outfit)?.shape ?? "parka"
        let outfit = StageMaterial.matte(color(appearance.outfit), roughness: outfitShape == "leather" ? 0.55 : 0.9)
        let inner = StageMaterial.matte(color(appearance.outfit, accent: true), roughness: 0.9)
        let hair = StageMaterial.matte(color(appearance.hairColor), roughness: 0.8)
        let feminine = appearance.presentation == "presentation_f"
        let shoulders: CGFloat = feminine ? 0.40 : 0.47

        // Legs and dark city shoes.
        let legs = SCNNode()
        legs.name = "legs"
        let trousers = StageMaterial.matte(outfitShape == "coat" && feminine ? UIColor(white: 0.12, alpha: 1) : StagePalette.trousers)
        for side in [-1.0, 1.0] {
            let leg = SCNNode(geometry: SCNCapsule(capRadius: feminine ? 0.068 : 0.075, height: 0.86))
            leg.geometry?.materials = [trousers]
            legs.addChildNode(leg.at(side * 0.1, 0.45, 0))
            legs.addChildNode(SCNNode.block(0.11, 0.07, 0.26, StageMaterial.matte(StagePalette.shoe, roughness: 0.4)).at(side * 0.1, 0, 0.04))
        }
        legs.pivot = SCNMatrix4MakeTranslation(0, 0.88, 0)
        legs.position = SCNVector3(0, 0.88, 0)
        body.addChildNode(legs)

        // Torso: the outfit's silhouette over the shirt / roll-neck / sweater.
        let torso = SCNNode()
        torso.name = "torso"
        let chestLength: CGFloat = outfitShape == "coat" ? 0.95 : (outfitShape == "parka" ? 0.72 : 0.64)
        let chest = SCNNode(geometry: SCNBox(width: shoulders, height: chestLength, length: 0.27, chamferRadius: 0.1))
        chest.geometry?.materials = [outfit]
        torso.addChildNode(chest.at(0, 0.62 - Double(chestLength) / 2, 0))
        switch outfitShape {
        case "coat", "suit", "parka", "leather", "cardigan":
            // Open front: the layer underneath shows.
            let front = SCNNode(geometry: SCNBox(width: outfitShape == "cardigan" ? 0.1 : 0.13, height: 0.44, length: 0.02, chamferRadius: 0.01))
            front.geometry?.materials = [inner]
            torso.addChildNode(front.at(0, 0.38, 0.135))
            if outfitShape == "coat" {
                let collar = SCNNode(geometry: SCNCylinder(radius: 0.075, height: 0.09))
                collar.geometry?.materials = [inner]
                torso.addChildNode(collar.at(0, 0.66, 0))
            }
            if outfitShape == "parka" {
                let hood = SCNNode(geometry: SCNTorus(ringRadius: 0.11, pipeRadius: 0.035))
                hood.geometry?.materials = [outfit]
                torso.addChildNode(hood.at(0, 0.64, -0.03))
            }
        case "shirt":
            // Rolled sleeves are drawn on the arms; a loosened tie if the extras say so.
            break
        default:
            break
        }
        torso.position = SCNVector3(0, 0.88, 0)
        body.addChildNode(torso)

        // Arms, hinged at the shoulder so they can lift a file or point.
        let rolled = outfitShape == "shirt"
        for (side, armName) in [(-1.0, "arm_l"), (1.0, "arm_r")] {
            let arm = SCNNode()
            arm.name = armName
            let sleeve = SCNNode(geometry: SCNCapsule(capRadius: 0.058, height: rolled ? 0.4 : 0.62))
            sleeve.geometry?.materials = [outfit]
            arm.addChildNode(sleeve.at(0, rolled ? -0.18 : -0.29, 0))
            if rolled {
                let forearm = SCNNode(geometry: SCNCapsule(capRadius: 0.045, height: 0.3))
                forearm.geometry?.materials = [skin]
                arm.addChildNode(forearm.at(0, -0.47, 0))
            }
            let hand = SCNNode(geometry: SCNSphere(radius: 0.052))
            hand.geometry?.materials = [skin]
            arm.addChildNode(hand.at(0, -0.63, 0))
            arm.position = SCNVector3(Float(side) * Float(shoulders / 2 + 0.05), 1.46, 0)
            body.addChildNode(arm)
        }

        // Neck and head (the face preset shapes the skull and the jaw).
        let neck = SCNNode(geometry: SCNCylinder(radius: 0.052, height: 0.1))
        neck.geometry?.materials = [skin]
        body.addChildNode(neck.at(0, 1.55, 0))
        let head = SCNNode()
        head.name = "head"
        head.position = SCNVector3(0, 1.66, 0)
        let skull = SCNNode(geometry: SCNSphere(radius: 0.112))
        skull.geometry?.materials = [skin]
        let face = faceScale(variant(appearance.face)?.shape)
        skull.scale = SCNVector3(face.x * (feminine ? 0.9 : 0.94), face.y * 1.08, 0.98)
        head.addChildNode(skull)
        let jaw = SCNNode(geometry: SCNBox(width: CGFloat(0.15 * face.jaw), height: 0.07, length: 0.12, chamferRadius: CGFloat(0.035 * face.round)))
        jaw.geometry?.materials = [skin]
        head.addChildNode(jaw.at(0, -0.075, 0.03))
        let nose = SCNNode(geometry: SCNBox(width: 0.022, height: 0.045, length: 0.03, chamferRadius: 0.01))
        nose.geometry?.materials = [skin]
        head.addChildNode(nose.at(0, -0.01, 0.108))
        let eye = StageMaterial.matte(color(appearance.eyeColor), roughness: 0.25)
        let white = StageMaterial.matte(UIColor(white: 0.92, alpha: 1), roughness: 0.3)
        let eyes = SCNNode()
        eyes.name = "eyes"
        for side in [-1.0, 1.0] {
            let ball = SCNNode(geometry: SCNSphere(radius: 0.016))
            ball.geometry?.materials = [white]
            eyes.addChildNode(ball.at(side * 0.04, 0.018, 0.094))
            let iris = SCNNode(geometry: SCNSphere(radius: 0.009))
            iris.geometry?.materials = [eye]
            eyes.addChildNode(iris.at(side * 0.04, 0.018, 0.108))
            let brow = SCNNode.block(0.035, 0.007, 0.01, hair).at(side * 0.04, 0.045, 0.104)
            head.addChildNode(brow)
        }
        head.addChildNode(eyes)
        // Lids in the skin tone: a blink every 3 to 6 s shows them for a tenth of a second.
        let lids = SCNNode()
        lids.name = "lids"
        for side in [-1.0, 1.0] {
            let lid = SCNNode(geometry: SCNSphere(radius: 0.0175))
            lid.geometry?.materials = [skin]
            lids.addChildNode(lid.at(side * 0.04, 0.018, 0.095))
        }
        lids.isHidden = true
        head.addChildNode(lids)
        lids.runAction(.repeatForever(.sequence([.wait(duration: 4.5, withRange: 3), .unhide(), .wait(duration: 0.1), .hide()])), forKey: "blink")
        let mouth = SCNNode(geometry: SCNBox(width: 0.038, height: 0.006, length: 0.004, chamferRadius: 0.002))
        mouth.geometry?.materials = [StageMaterial.matte(StagePalette.lip)]
        head.addChildNode(mouth.at(0, -0.055, 0.1))
        addHair(variant(appearance.hairStyle)?.shape ?? "short", material: hair, to: head)
        addBeard(variant(appearance.beard)?.shape, material: hair, to: head)
        body.addChildNode(head)
        addDetails(details, outfitShape: outfitShape, inner: inner, head: head, torso: torso, body: body)
        return root
    }

    /// Width, height, jaw and roundness per face preset.
    private static func faceScale(_ shape: String?) -> (x: Float, y: Float, jaw: Double, round: Double) {
        switch shape {
        case "long": (0.92, 1.08, 0.9, 0.8)
        case "square": (1.02, 0.98, 1.12, 0.4)
        case "round": (1.05, 0.97, 1.0, 1.0)
        case "angular": (0.96, 1.03, 1.05, 0.3)
        case "heart": (1.0, 1.0, 0.82, 0.9)
        default: (1.0, 1.0, 0.95, 0.8) // oval
        }
    }

    private static func addHair(_ shape: String, material: SCNMaterial, to head: SCNNode) {
        func cap(_ scaleY: Float, _ offsetY: Double, _ offsetZ: Double = -0.012, radius: CGFloat = 0.12) -> SCNNode {
            let s = SCNNode(geometry: SCNSphere(radius: radius))
            s.geometry?.materials = [material]
            s.scale = SCNVector3(0.97, scaleY, 1.0)
            return s.at(0, offsetY, offsetZ)
        }
        func piece(_ w: CGFloat, _ h: CGFloat, _ d: CGFloat, _ x: Double, _ y: Double, _ z: Double, chamfer: CGFloat = 0.04) -> SCNNode {
            let b = SCNNode(geometry: SCNBox(width: w, height: h, length: d, chamferRadius: chamfer))
            b.geometry?.materials = [material]
            return b.at(x, y, z)
        }
        switch shape {
        case "bald":
            break
        case "shaved":
            let m = material.copy() as! SCNMaterial
            m.transparency = 0.55
            let c = cap(0.6, 0.04, radius: 0.116)
            c.geometry?.materials = [m]
            head.addChildNode(c)
        case "crop":
            head.addChildNode(cap(0.6, 0.052))
        case "side":
            head.addChildNode(cap(0.64, 0.05))
            head.addChildNode(piece(0.11, 0.03, 0.2, 0.04, 0.1, 0.0, chamfer: 0.015))
        case "swept":
            head.addChildNode(cap(0.68, 0.05, -0.02))
            head.addChildNode(piece(0.2, 0.12, 0.08, 0, -0.03, -0.1))
        case "receding":
            let c = cap(0.55, 0.035, -0.04)
            head.addChildNode(c)
        case "bob":
            head.addChildNode(cap(0.74, 0.04))
            head.addChildNode(piece(0.26, 0.19, 0.13, 0, -0.06, -0.045, chamfer: 0.06))
        case "ponytail":
            head.addChildNode(cap(0.7, 0.045))
            let tail = SCNNode(geometry: SCNCapsule(capRadius: 0.032, height: 0.22))
            tail.geometry?.materials = [material]
            tail.eulerAngles.x = 0.25
            head.addChildNode(tail.at(0, -0.1, -0.13))
        case "braid":
            head.addChildNode(cap(0.7, 0.045))
            for i in 0..<5 {
                let knot = SCNNode(geometry: SCNSphere(radius: 0.03 - Double(i) * 0.002))
                knot.geometry?.materials = [material]
                head.addChildNode(knot.at(0, -0.08 - Double(i) * 0.045, -0.13 + Double(i) * 0.004))
            }
        case "bun":
            head.addChildNode(cap(0.7, 0.045))
            let bun = SCNNode(geometry: SCNSphere(radius: 0.05))
            bun.geometry?.materials = [material]
            head.addChildNode(bun.at(0, -0.04, -0.13))
        case "curly":
            for i in 0..<10 {
                let a = Double(i) * .pi / 5
                let curl = SCNNode(geometry: SCNSphere(radius: 0.05))
                curl.geometry?.materials = [material]
                head.addChildNode(curl.at(cos(a) * 0.08, 0.075 + sin(Double(i)) * 0.012, sin(a) * 0.075 - 0.025))
            }
        case "long":
            head.addChildNode(cap(0.75, 0.04))
            head.addChildNode(piece(0.26, 0.32, 0.1, 0, -0.14, -0.07, chamfer: 0.05))
        default: // short
            head.addChildNode(cap(0.66, 0.05))
        }
    }

    private static func addBeard(_ shape: String?, material: SCNMaterial, to head: SCNNode) {
        switch shape {
        case "full":
            let beard = SCNNode(geometry: SCNBox(width: 0.16, height: 0.085, length: 0.08, chamferRadius: 0.035))
            beard.geometry?.materials = [material]
            head.addChildNode(beard.at(0, -0.08, 0.07))
        case "stubble":
            let m = material.copy() as! SCNMaterial
            m.transparency = 0.4
            let stubble = SCNNode(geometry: SCNBox(width: 0.165, height: 0.07, length: 0.06, chamferRadius: 0.03))
            stubble.geometry?.materials = [m]
            head.addChildNode(stubble.at(0, -0.075, 0.074))
        case "moustache":
            let m = SCNNode(geometry: SCNBox(width: 0.065, height: 0.012, length: 0.012, chamferRadius: 0.005))
            m.geometry?.materials = [material]
            head.addChildNode(m.at(0, -0.035, 0.106))
        default:
            break
        }
    }

    /// NPC extras and the player's rank details.
    private static func addDetails(_ details: RigDetails, outfitShape: String, inner: SCNMaterial, head: SCNNode, torso: SCNNode, body: SCNNode) {
        let frame = StageMaterial.matte(UIColor(white: 0.12, alpha: 1), roughness: 0.35)
        for extra in details.extras {
            switch extra {
            case "halfmoon_glasses", "glasses_chain", "glasses":
                for side in [-1.0, 1.0] {
                    let lens = SCNNode(geometry: SCNBox(width: 0.04, height: extra == "halfmoon_glasses" ? 0.014 : 0.026, length: 0.003, chamferRadius: 0.004))
                    lens.geometry?.materials = [StageMaterial.glass()]
                    head.addChildNode(lens.at(side * 0.04, extra == "halfmoon_glasses" ? 0.0 : 0.012, 0.118))
                    head.addChildNode(SCNNode.block(0.042, 0.003, 0.003, frame).at(side * 0.04, extra == "halfmoon_glasses" ? 0.007 : 0.026, 0.119))
                }
                if extra == "glasses_chain" {
                    let chain = SCNNode(geometry: SCNTorus(ringRadius: 0.1, pipeRadius: 0.002))
                    chain.geometry?.materials = [StageMaterial.metal(StagePalette.brass)]
                    chain.eulerAngles.x = 0.6
                    head.addChildNode(chain.at(0, -0.1, 0.02))
                }
            case "tie":
                let tie = SCNNode.block(0.045, 0.34, 0.01, StageMaterial.matte(UIColor(red: 0.23, green: 0.26, blue: 0.31, alpha: 1)))
                tie.eulerAngles.z = 0.06
                torso.addChildNode(tie.at(0.01, 0.26, 0.14))
            case "lanyard":
                let cord = SCNNode(geometry: SCNTorus(ringRadius: 0.1, pipeRadius: 0.004))
                cord.geometry?.materials = [StageMaterial.matte(UIColor(red: 0.42, green: 0.17, blue: 0.19, alpha: 1))]
                cord.eulerAngles.x = 1.1
                torso.addChildNode(cord.at(0, 0.52, 0.06))
                torso.addChildNode(SCNNode.block(0.055, 0.085, 0.004, StageMaterial.matte(StagePalette.cardWhite)).at(0, 0.3, 0.14))
            case "headset":
                let band = SCNNode(geometry: SCNTorus(ringRadius: 0.1, pipeRadius: 0.012))
                band.geometry?.materials = [frame]
                band.eulerAngles.x = .pi / 2 - 0.4
                torso.addChildNode(band.at(0, 0.66, 0.02))
            default:
                break
            }
        }
        guard let rank = details.rank else { return }
        // The BEN card: plastic at the belt for an ENQUÊTEUR, metal from INSPECTEUR.
        let metalCard = rank >= .inspecteur
        let card = SCNNode.block(0.05, 0.075, 0.006, metalCard ? StageMaterial.metal(StagePalette.metal) : StageMaterial.matte(StagePalette.cardWhite, roughness: 0.3))
        torso.addChildNode(card.at(0.12, 0.02, 0.14))
        if rank >= .inspecteur {
            // The outfit gains a detail: a scarf (coats) or gloves (the others).
            if outfitShape == "coat" || outfitShape == "parka" {
                let scarf = SCNNode(geometry: SCNTorus(ringRadius: 0.085, pipeRadius: 0.035))
                scarf.geometry?.materials = [StageMaterial.matte(UIColor(red: 0.35, green: 0.31, blue: 0.26, alpha: 1))]
                torso.addChildNode(scarf.at(0, 0.64, 0.01))
            } else {
                for name in ["arm_l", "arm_r"] {
                    if let arm = body.childNode(withName: name, recursively: false) {
                        let glove = SCNNode(geometry: SCNSphere(radius: 0.056))
                        glove.geometry?.materials = [StageMaterial.matte(UIColor(white: 0.1, alpha: 1), roughness: 0.5)]
                        arm.addChildNode(glove.at(0, -0.63, 0))
                    }
                }
            }
        }
        if rank >= .senior, let arm = body.childNode(withName: "arm_l", recursively: false) {
            // A leather document case.
            arm.addChildNode(SCNNode.block(0.3, 0.22, 0.04, StageMaterial.matte(UIColor(red: 0.30, green: 0.20, blue: 0.13, alpha: 1), roughness: 0.55)).at(0, -0.8, 0.02))
        }
        if rank >= .experimente {
            let pin = SCNNode(geometry: SCNCylinder(radius: 0.012, height: 0.004))
            pin.geometry?.materials = [StageMaterial.metal(StagePalette.brass)]
            pin.eulerAngles.x = .pi / 2
            torso.addChildNode(pin.at(-0.12, 0.5, 0.14))
        }
    }
}

// MARK: - Camera

/// The shot: one of the set's named cameras (position, target, focal). Scenes never compute a
/// camera on the fly (ENVIRONMENTS §4): an unknown camera falls back to the room's first one.
@MainActor
enum StageCamera {
    struct Framing: Equatable {
        var position: SCNVector3
        var target: SCNVector3
        var fov: CGFloat
        var focus: SCNVector3?

        static func == (a: Framing, b: Framing) -> Bool {
            SCNVector3EqualToVector3(a.position, b.position) && SCNVector3EqualToVector3(a.target, b.target) && a.fov == b.fov
        }
    }

    static func framing(for shot: CameraShot?, stage: StageState, location: StoryLocation) -> Framing {
        let cam = shot?.camera.flatMap(location.camera) ?? location.cameras.first
        guard let cam else { return Framing(position: SCNVector3(0, 1.6, 2), target: SCNVector3(0, 1.2, 0), fov: 50) }
        // Focus on the eyes of the person the shot is on, or on the object.
        var focus: SCNVector3?
        if let subject = shot?.subject, let a = stage.actors[subject] {
            focus = SCNVector3(a.x, a.seated ? 1.2 : 1.6, a.z)
        } else if let id = shot?.prop, let p = location.prop(id) {
            focus = SCNVector3(p.x, (p.y ?? 0) + 0.02, p.z)
        }
        return Framing(position: SCNVector3(cam.x, cam.y, cam.z), target: SCNVector3(cam.lookX, cam.lookY, cam.lookZ),
                       fov: CGFloat(cam.verticalFOV), focus: focus)
    }
}

extension SCNVector3 {
    init(_ x: Double, _ y: Double, _ z: Double) { self.init(Float(x), Float(y), Float(z)) }
}

// MARK: - Portrait (S4)

/// The file photo of the player: the bust in the S4 camera (85 mm at 1.55 m, #6F7A86 background, a
/// soft key 30° left and a fill at −2 EV), 1024 × 1280 — the same look as the portraits of the Carnet.
@MainActor
enum PortraitRenderer {
    static func render(_ appearance: CharacterAppearance, catalog: CharacterCatalog, rank: StoryRank,
                       size: CGSize = CGSize(width: 512, height: 640)) -> UIImage? {
        guard let device = MTLCreateSystemDefaultDevice() else { return nil }
        let scene = SCNScene()
        scene.background.contents = StagePalette.benBlue
        let feminine = appearance.presentation == "presentation_f"
        let player = CharacterRig.make(appearance, catalog: catalog, name: "portrait",
                                       details: RigDetails(height: feminine ? 1.68 : 1.80, rank: rank))
        player.childNode(withName: "lids", recursively: true)?.removeAction(forKey: "blink")
        scene.rootNode.addChildNode(player)
        let eye: Float = 1.66 * (feminine ? 1.68 : 1.80) / 1.75
        let key = SCNNode()
        key.light = SCNLight()
        key.light?.type = .spot
        key.light?.color = StagePalette.neon4000
        key.light?.intensity = 320
        key.light?.spotOuterAngle = 60
        key.position = SCNVector3(-1.2, eye + 0.6, 1.6)
        key.look(at: SCNVector3(0, eye - 0.1, 0))
        scene.rootNode.addChildNode(key)
        let fill = SCNNode()
        fill.light = SCNLight()
        fill.light?.type = .ambient
        fill.light?.color = UIColor(red: 0.11, green: 0.13, blue: 0.19, alpha: 1)
        fill.light?.intensity = 90
        scene.rootNode.addChildNode(fill)
        let camera = SCNNode()
        camera.camera = SCNCamera()
        camera.camera?.fieldOfView = CGFloat(2 * atan(18.0 / 85.0) * 180 / .pi)
        camera.position = SCNVector3(0, eye - 0.08, 1.35)
        camera.look(at: SCNVector3(0, eye - 0.14, 0))
        scene.rootNode.addChildNode(camera)
        let renderer = SCNRenderer(device: device, options: nil)
        renderer.scene = scene
        renderer.pointOfView = camera
        let image = renderer.snapshot(atTime: 0, with: size, antialiasingMode: .multisampling4X)
        return image
    }
}
#endif
