import Foundation

// The places of the story: a few reusable rooms (the BEN's office, corridor, archives,
// interrogation room, briefing room, the player's office…), each described as data — size,
// colours, light, sound, props and named points — and built in 3D by the game's stage.
// Units: metres. x to the right, z towards the camera of the room's « wide » shot, y up.

/// A point where a character stands (or sits): position and the direction they face (degrees,
/// 0 = towards +z, 90 = towards +x).
public struct StageAnchor: Codable, Sendable, Hashable, Identifiable {
    public var id: String
    public var x: Double
    public var z: Double
    public var facing: Double
    /// Seated at this point (a chair is expected there).
    public var seated: Bool?
}

/// A named camera placed in the set (« cam_lac_ms »): scenes only reference these, a camera is
/// never computed on the fly. A shot the set does not provide means adding a camera here.
public struct CameraAnchor: Codable, Sendable, Hashable, Identifiable {
    public var id: String
    public var x: Double
    public var y: Double
    public var z: Double
    public var lookX: Double
    public var lookY: Double
    public var lookZ: Double
    /// Focal length, millimetres (full-frame equivalent: 28, 35, 50, 85 or 100).
    public var focal: Double?
    /// Vertical field of view, degrees (used when `focal` is absent).
    public var fov: Double?

    /// The allowed focals (STORY_ART_DIRECTION §4).
    public static let focals: Set<Double> = [28, 35, 50, 85, 100]

    /// Vertical field of view of the portrait frame: the 36 mm side of the sensor is vertical.
    public var verticalFOV: Double {
        if let focal, focal > 0 { return 2 * atan(18 / focal) * 180 / .pi }
        return fov ?? 50
    }
}

/// What the player can touch in their office (h09): a label, and the sheet that opens.
public struct PropHotspot: Codable, Sendable, Hashable {
    /// « TÉLÉPHONE », « ARCHIVES »…
    public var label: String
    public var name: String
    /// Where it comes from (« Remis par le Cdt. Lacaze »).
    public var provenance: String?
    /// The close-up camera of the object (« cam_po_obj_phone »).
    public var camera: String?
}

/// A piece of furniture or an object of the room, built by the stage from its `kind`.
public struct StageProp: Codable, Sendable, Hashable, Identifiable {
    public var id: String
    /// desk, chair, table, shelf, cabinet, door, window, lamp, board, plant, computer, phone, file,
    /// files, plaque, frame, trophy, coffee, sofa, mirror, bench, light_panel… (unknown kinds are
    /// drawn as a neutral block: content never breaks the stage).
    public var kind: String
    public var x: Double
    public var z: Double
    /// Height above the floor (objects on a desk: 0.76).
    public var y: Double?
    /// Rotation around the vertical axis, degrees.
    public var rotation: Double?
    /// Width × depth × height override, metres.
    public var size: [Double]?
    /// « #RRGGBB » override.
    public var color: String?
    /// Only in the room once this office item is unlocked (the player's office grows with the
    /// career); nil = always there.
    public var requires: String?
    /// Text written on it (a door plate, the player's name plaque: may use {player.lastName}).
    public var label: String?
    /// The player's office only: present from this office level (1–4, from the rank)…
    public var level: Int?
    /// …and up to this one (the metal desk gives way to the wooden one).
    public var maxLevel: Int?
    /// Not on the set until a scene shows it (`SceneBeat.show`): the file taken out of a drawer.
    public var hidden: Bool?
    /// A neon that flickers now and then.
    public var flicker: Bool?
    /// The player's office only: a point the player can tap.
    public var hotspot: PropHotspot?
}

/// A reusable room.
public struct StoryLocation: Codable, Sendable, Hashable, Identifiable {
    public var id: String
    public var name: String
    /// Width (x) × depth (z) × height (y), metres.
    public var size: [Double]
    public var wallColor: String
    public var floorColor: String
    public var accentColor: String?
    /// office_day, office_evening, archive, interrogation, briefing, corridor (the stage's presets).
    public var lighting: String
    /// Looping ambience (a sound of the game: « room », « hall »…).
    public var ambience: String?
    public var anchors: [StageAnchor]
    public var cameras: [CameraAnchor]
    public var props: [StageProp]

    public func anchor(_ id: String) -> StageAnchor? { anchors.first { $0.id == id } }
    public func camera(_ id: String) -> CameraAnchor? { cameras.first { $0.id == id } }
    public func prop(_ id: String) -> StageProp? { props.first { $0.id == id } }

    /// The props visible with these items unlocked, at this office level. An object not yet
    /// unlocked is not there at all (no silhouette).
    public func props(unlocked: Set<String>, level: Int = 4) -> [StageProp] {
        props.filter { ($0.requires == nil || unlocked.contains($0.requires!)) && ($0.level ?? 1) <= level && level <= ($0.maxLevel ?? 4) }
    }
}
