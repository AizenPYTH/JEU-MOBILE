#if os(iOS)
import SwiftUI
import SceneKit
import StoryEngine

/// What the stage shows: the director's stage state plus everything needed to build it.
struct StageSnapshot {
    var stage: StageState
    var location: StoryLocation?
    var content: StoryContent
    var player: StoryPlayer
    var rank: StoryRank
    var unlocks: Set<String>
    /// The player's office level (1–4).
    var officeLevel: Int = 1
    /// Resolves the placeholders written on the set ({player.LASTNAME} on a door).
    var text: (String) -> String
    /// Camera moves become cuts, people do not walk (« Réduire les animations »).
    var reduceMotion: Bool
    /// The hub (h04): a slow lateral travelling back and forth (6 cm/s, 20 s).
    var drift = false
    /// Props whose screen position the caller wants (h09 hotspots).
    var project: [String] = []
}

/// The story's 3D stage: one SceneKit view, the room of the scene, its people and the camera.
///
/// Declarative: it follows `StageState` (where each person is, which way they face, the pose, the
/// shot, the props shown). A new location unloads the previous room and builds the next one, so
/// only one room is ever in memory.
struct StoryStageView: UIViewRepresentable {
    let snapshot: StageSnapshot
    /// Screen points of `snapshot.project` (in the view's coordinates), after each change.
    var onProject: (@MainActor ([String: CGPoint]) -> Void)? = nil

    func makeCoordinator() -> StageDirectorView { StageDirectorView() }

    func makeUIView(context: Context) -> SCNView {
        let view = SCNView(frame: .zero)
        view.backgroundColor = StagePalette.background
        view.antialiasingMode = StageQuality.antialiasing
        view.preferredFramesPerSecond = StageQuality.framesPerSecond
        view.rendersContinuously = true
        view.isPlaying = true
        view.allowsCameraControl = false
        view.isUserInteractionEnabled = false
        view.accessibilityElementsHidden = true
        view.scene = context.coordinator.scene
        view.pointOfView = context.coordinator.cameraNode
        context.coordinator.view = view
        context.coordinator.apply(snapshot)
        report(context.coordinator)
        return view
    }

    func updateUIView(_ view: SCNView, context: Context) {
        context.coordinator.apply(snapshot)
        report(context.coordinator)
    }

    private func report(_ coordinator: StageDirectorView) {
        guard let onProject, !snapshot.project.isEmpty else { return }
        // Only when what is projected or the shot changed (the report itself re-renders the caller).
        let key = snapshot.project.joined(separator: ",") + "|" + (snapshot.stage.shot?.camera ?? "") + "|\(snapshot.officeLevel)|\(snapshot.unlocks.count)"
        guard key != coordinator.lastProjection else { return }
        coordinator.lastProjection = key
        // After the camera settled (its moves last up to 0.8 s).
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(900))
            onProject(coordinator.projected(snapshot.project))
        }
    }

    static func dismantleUIView(_ view: SCNView, coordinator: StageDirectorView) {
        coordinator.unload()
        view.scene = nil
    }
}

/// Keeps the SceneKit graph in step with the stage state.
@MainActor
final class StageDirectorView {
    let scene = SCNScene()
    let cameraNode = SCNNode()
    weak var view: SCNView?
    private var roomNode: SCNNode?
    private var roomKey: String?
    private var locationID: String?
    private var actors: [String: SCNNode] = [:]
    private var actorStates: [String: ActorState] = [:]
    private var framing: StageCamera.Framing?
    private var drifting = false
    /// What was last reported to `onProject`.
    var lastProjection = ""

    init() {
        scene.background.contents = StagePalette.background
        let camera = SCNCamera()
        camera.zNear = 0.03
        camera.zFar = 60
        camera.fieldOfView = 50
        camera.wantsHDR = true
        // ACES-like tonemapping, a light vignette (18 %), no bloom but on emissive screens.
        camera.wantsExposureAdaptation = false
        camera.exposureOffset = -0.2
        camera.whitePoint = 1.2
        camera.minimumExposure = -1
        camera.bloomIntensity = 0.05
        camera.bloomThreshold = 0.95
        camera.vignettingIntensity = 0.18
        camera.vignettingPower = 0.8
        camera.saturation = 0.85
        camera.contrast = 0.05
        camera.wantsDepthOfField = false
        cameraNode.camera = camera
        cameraNode.name = "story.camera"
        scene.rootNode.addChildNode(cameraNode)
    }

    func apply(_ snapshot: StageSnapshot) {
        guard let location = snapshot.location else {
            unload()
            return
        }
        // The office changes with what the player has unlocked and their level: the key includes it.
        let key = location.id + "|" + snapshot.unlocks.sorted().joined(separator: ",") + "|\(snapshot.officeLevel)"
        if key != roomKey {
            roomNode?.removeFromParentNode()
            let room = StageBuilder.room(location, unlocked: snapshot.unlocks, level: snapshot.officeLevel, text: snapshot.text)
            scene.rootNode.addChildNode(room)
            roomNode = room
            roomKey = key
            if locationID != location.id {
                // A new room: nobody from the previous one is kept.
                for node in actors.values { node.removeFromParentNode() }
                actors = [:]
                actorStates = [:]
                framing = nil
                locationID = location.id
            }
        }
        syncProps(snapshot)
        syncActors(snapshot)
        syncCamera(snapshot, location: location)
    }

    func unload() {
        roomNode?.removeFromParentNode()
        roomNode = nil
        roomKey = nil
        locationID = nil
        for node in actors.values { node.removeFromParentNode() }
        actors = [:]
        actorStates = [:]
        framing = nil
    }

    /// Screen positions of props (for the office's hotspots).
    func projected(_ ids: [String]) -> [String: CGPoint] {
        guard let view, let room = roomNode else { return [:] }
        var result: [String: CGPoint] = [:]
        for id in ids {
            guard let node = room.childNode(withName: "prop_" + id, recursively: false), !node.isHidden else { continue }
            let (minB, maxB) = node.boundingBox
            let local = SCNVector3((minB.x + maxB.x) / 2, maxB.y, (minB.z + maxB.z) / 2)
            let world = node.convertPosition(local, to: nil)
            let p = view.projectPoint(world)
            guard p.z > 0, p.z < 1 else { continue }
            result[id] = CGPoint(x: CGFloat(p.x), y: CGFloat(p.y))
        }
        return result
    }

    // MARK: Props

    private func syncProps(_ snapshot: StageSnapshot) {
        guard let room = roomNode, let location = snapshot.location else { return }
        for prop in location.props where prop.hidden == true || snapshot.stage.removedProps.contains(prop.id) {
            guard let node = room.childNode(withName: "prop_" + prop.id, recursively: false) else { continue }
            let visible = (prop.hidden != true || snapshot.stage.shownProps.contains(prop.id)) && !snapshot.stage.removedProps.contains(prop.id)
            if node.isHidden == visible {
                node.isHidden = !visible
                if visible, !snapshot.reduceMotion {
                    node.opacity = 0
                    node.runAction(.fadeIn(duration: 0.3))
                }
            }
        }
    }

    // MARK: People

    private func appearance(of id: String, in snapshot: StageSnapshot) -> (CharacterAppearance, RigDetails)? {
        if id == "player" { return (snapshot.player.appearance, .player(snapshot.player, rank: snapshot.rank)) }
        guard let npc = snapshot.content.npc(id) else { return nil }
        return (npc.appearance, .npc(npc))
    }

    private func syncActors(_ snapshot: StageSnapshot) {
        let animate = !snapshot.reduceMotion
        for (id, state) in snapshot.stage.actors {
            let node: SCNNode
            let isNew: Bool
            if let existing = actors[id] {
                node = existing
                isNew = false
            } else {
                guard let look = appearance(of: id, in: snapshot) else { continue }
                node = CharacterRig.make(look.0, catalog: snapshot.content.catalog, name: "actor.\(id)", details: look.1)
                node.opacity = 0
                scene.rootNode.addChildNode(node)
                actors[id] = node
                isNew = true
                if animate { Self.breathe(node) }
            }
            let previous = actorStates[id]
            guard previous != state else { continue }
            actorStates[id] = state
            let target = SCNVector3(state.x, 0, state.z)
            let angle = Float(state.facing * .pi / 180)
            if isNew || previous?.visible == false || !animate {
                node.removeAction(forKey: "walk")
                node.position = target
                node.eulerAngles.y = angle
            } else if let previous, previous.x != state.x || previous.z != state.z {
                let distance = ((previous.x - state.x) * (previous.x - state.x) + (previous.z - state.z) * (previous.z - state.z)).squareRoot()
                let duration = max(0.6, distance / 1.1)
                // Turn towards the destination, walk, then take the final facing.
                let heading = Float(atan2(state.x - previous.x, state.z - previous.z))
                let walk = SCNAction.sequence([
                    .rotateTo(x: 0, y: CGFloat(Self.closest(heading, to: node.eulerAngles.y)), z: 0, duration: 0.25, usesShortestUnitArc: true),
                    .move(to: target, duration: duration),
                    .rotateTo(x: 0, y: CGFloat(angle), z: 0, duration: 0.3, usesShortestUnitArc: true),
                ])
                walk.timingMode = .easeInEaseOut
                node.runAction(walk, forKey: "walk")
                Self.stride(duration: duration, on: node)
            } else {
                node.runAction(.rotateTo(x: 0, y: CGFloat(angle), z: 0, duration: 0.35, usesShortestUnitArc: true), forKey: "turn")
            }
            // Appear / leave.
            let opacity: CGFloat = state.visible ? 1 : 0
            if node.opacity != opacity {
                if animate { node.runAction(.fadeOpacity(to: opacity, duration: 0.45), forKey: "fade") } else { node.opacity = opacity }
            }
            let settleDelay = (previous.map { $0.x != state.x || $0.z != state.z } ?? false) && animate
            Self.pose(node, seated: state.seated, pose: state.pose, changed: previous?.pose != state.pose || isNew,
                      animate: animate, after: settleDelay ? 1.0 : 0)
        }
        // People no longer on the stage.
        for (id, node) in actors where snapshot.stage.actors[id] == nil {
            node.removeFromParentNode()
            actors[id] = nil
            actorStates[id] = nil
        }
    }

    private static func closest(_ angle: Float, to current: Float) -> Float {
        var a = angle
        while a - current > .pi { a -= 2 * .pi }
        while a - current < -.pi { a += 2 * .pi }
        return a
    }

    /// A slow breath and a weight shift every 6–9 s: people on the stage are never frozen.
    private static func breathe(_ node: SCNNode) {
        guard let torso = node.childNode(withName: "torso", recursively: true) else { return }
        let phase = Double((node.name ?? "").utf8.reduce(0) { $0 + Int($1) } % 100) / 100
        let up = SCNAction.scale(to: 1.012, duration: 1.9)
        up.timingMode = .easeInEaseOut
        let down = SCNAction.scale(to: 1.0, duration: 1.9)
        down.timingMode = .easeInEaseOut
        torso.runAction(.sequence([.wait(duration: phase * 1.5), .repeatForever(.sequence([up, down]))]), forKey: "breath")
        if let body = node.childNode(withName: "body", recursively: false) {
            let left = SCNAction.rotateTo(x: 0, y: 0, z: 0.012, duration: 1.2)
            let right = SCNAction.rotateTo(x: 0, y: 0, z: -0.012, duration: 1.2)
            left.timingMode = .easeInEaseOut
            right.timingMode = .easeInEaseOut
            body.runAction(.repeatForever(.sequence([.wait(duration: 7.5, withRange: 3), left, .wait(duration: 6, withRange: 3), right])), forKey: "weight")
        }
    }

    /// A light bob of the body while walking.
    private static func stride(duration: Double, on node: SCNNode) {
        guard let body = node.childNode(withName: "body", recursively: false) else { return }
        let bob = SCNAction.sequence([.moveBy(x: 0, y: 0.022, z: 0, duration: 0.25), .moveBy(x: 0, y: -0.022, z: 0, duration: 0.25)])
        body.runAction(.sequence([.wait(duration: 0.25), .repeat(bob, count: max(1, Int(duration / 0.5)))]), forKey: "bob")
    }

    /// Seated / standing, and the short gestures of the shared library (3D_DIRECTION §6): nod,
    /// gesture, handover, typing, phone, shrug, read, take, put_down, cross_arms, lean_forward.
    /// Unknown poses are ignored.
    private static func pose(_ node: SCNNode, seated: Bool, pose: String?, changed: Bool, animate: Bool, after delay: Double) {
        guard let body = node.childNode(withName: "body", recursively: false) else { return }
        let legs = body.childNode(withName: "legs", recursively: false)
        let head = body.childNode(withName: "head", recursively: false)
        let armL = body.childNode(withName: "arm_l", recursively: false)
        let armR = body.childNode(withName: "arm_r", recursively: false)
        let duration = animate ? 0.45 : 0
        // Seated: the body drops by the seat height and the legs fold forward.
        let seatY: Float = seated ? -0.42 : 0
        let wasSeated = body.position.y < -0.2
        if wasSeated != seated {
            let sit = SCNAction.group([.move(to: SCNVector3(0, seatY, 0), duration: duration)])
            body.runAction(.sequence([.wait(duration: delay), sit]), forKey: "sit")
            legs?.runAction(.sequence([.wait(duration: delay), .rotateTo(x: seated ? -.pi / 2.1 : 0, y: 0, z: 0, duration: duration)]), forKey: "legs")
        }
        guard changed, let pose, animate else { return }
        func swing(_ arm: SCNNode?, x: CGFloat, z: CGFloat = 0, hold: Double) {
            arm?.runAction(.sequence([.wait(duration: delay), .rotateTo(x: x, y: 0, z: z, duration: 0.35), .wait(duration: hold),
                                      .rotateTo(x: 0, y: 0, z: 0, duration: 0.45)]), forKey: "gesture")
        }
        switch pose {
        case "nod":
            head?.runAction(.sequence([.rotateBy(x: 0.2, y: 0, z: 0, duration: 0.18), .rotateBy(x: -0.2, y: 0, z: 0, duration: 0.2),
                                       .rotateBy(x: 0.12, y: 0, z: 0, duration: 0.16), .rotateBy(x: -0.12, y: 0, z: 0, duration: 0.2)]), forKey: "nod")
        case "gesture":
            swing(armR, x: -0.9, z: 0.25, hold: 0.6)
        case "handover":
            swing(armR, x: -1.3, hold: 1.4)
        case "take", "put_down":
            swing(armR, x: -1.0, z: 0.1, hold: 0.5)
            head?.runAction(.sequence([.rotateTo(x: 0.3, y: 0, z: 0, duration: 0.3), .wait(duration: 0.8), .rotateTo(x: 0, y: 0, z: 0, duration: 0.4)]), forKey: "nod")
        case "read":
            // Head down over the file, a page turned now and then.
            head?.runAction(.rotateTo(x: 0.35, y: 0, z: 0, duration: 0.5), forKey: "nod")
            swing(armL, x: -0.8, z: -0.15, hold: 2.5)
        case "typing":
            let tap = SCNAction.sequence([.rotateTo(x: -1.0, y: 0, z: 0, duration: 0.3), .repeat(.sequence([.rotateBy(x: 0.08, y: 0, z: 0, duration: 0.12), .rotateBy(x: -0.08, y: 0, z: 0, duration: 0.12)]), count: 6), .rotateTo(x: 0, y: 0, z: 0, duration: 0.4)])
            armL?.runAction(tap, forKey: "gesture")
            armR?.runAction(tap, forKey: "gesture")
        case "phone":
            armR?.runAction(.sequence([.rotateTo(x: -1.2, y: 0, z: 0.35, duration: 0.35), .wait(duration: 2.0), .rotateTo(x: 0, y: 0, z: 0, duration: 0.45)]), forKey: "gesture")
            head?.runAction(.sequence([.rotateTo(x: 0.3, y: 0, z: 0, duration: 0.35), .wait(duration: 2.0), .rotateTo(x: 0, y: 0, z: 0, duration: 0.45)]), forKey: "nod")
        case "shrug":
            for arm in [armL, armR] {
                arm?.runAction(.sequence([.moveBy(x: 0, y: 0.05, z: 0, duration: 0.2), .wait(duration: 0.3), .moveBy(x: 0, y: -0.05, z: 0, duration: 0.3)]), forKey: "shrug")
            }
        case "cross_arms":
            armL?.runAction(.rotateTo(x: -0.9, y: 0, z: -0.9, duration: 0.4), forKey: "gesture")
            armR?.runAction(.rotateTo(x: -0.9, y: 0, z: 0.9, duration: 0.4), forKey: "gesture")
        case "lean_forward":
            body.childNode(withName: "torso", recursively: false)?.runAction(.rotateTo(x: 0.18, y: 0, z: 0, duration: 0.5), forKey: "lean")
        case "stand", "idle", "sit":
            head?.runAction(.rotateTo(x: 0, y: 0, z: 0, duration: 0.4), forKey: "nod")
            armL?.runAction(.rotateTo(x: 0, y: 0, z: 0, duration: 0.4), forKey: "gesture")
            armR?.runAction(.rotateTo(x: 0, y: 0, z: 0, duration: 0.4), forKey: "gesture")
            body.childNode(withName: "torso", recursively: false)?.runAction(.rotateTo(x: 0, y: 0, z: 0, duration: 0.4), forKey: "lean")
        default:
            break
        }
    }

    // MARK: Camera

    private func syncCamera(_ snapshot: StageSnapshot, location: StoryLocation) {
        guard let camera = cameraNode.camera else { return }
        let next = StageCamera.framing(for: snapshot.stage.shot, stage: snapshot.stage, location: location)
        if let focus = next.focus, StageQuality.depthOfField {
            camera.wantsDepthOfField = true
            let d = CGFloat(simd_distance(SIMD3<Float>(focus), SIMD3<Float>(next.position)))
            camera.focusDistance = d
            camera.fStop = snapshot.stage.shot?.kind == .focusObject ? 2.0 : 2.8
            camera.apertureBladeCount = 6
            camera.focalBlurSampleCount = 8
        } else {
            camera.wantsDepthOfField = false
        }
        let move = snapshot.stage.shot?.move
        guard next != framing || (snapshot.drift && !drifting) else { return }
        framing = next
        cameraNode.removeAllActions()
        drifting = false
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 0
        cameraNode.position = next.position
        camera.fieldOfView = next.fov
        cameraNode.look(at: next.target, up: SCNVector3(0, 1, 0), localFront: SCNVector3(0, 0, -1))
        SCNTransaction.commit()
        guard !snapshot.reduceMotion else { return }
        // Slow moves only (≤ 8 cm/s, push-in ≤ 15 cm per shot): never a handheld shake.
        let forward = simd_normalize(SIMD3<Float>(next.target) - SIMD3<Float>(next.position))
        if move == .pushIn {
            let push = SCNAction.move(by: SCNVector3(forward * 0.12), duration: 3.0)
            push.timingMode = .easeInEaseOut
            cameraNode.runAction(push, forKey: "move")
        } else if move == .track || snapshot.drift {
            let side = simd_normalize(simd_cross(forward, SIMD3<Float>(0, 1, 0)))
            let span: Float = snapshot.drift ? 0.6 : 0.24
            let seconds = snapshot.drift ? 10.0 : 4.0
            let there = SCNAction.move(by: SCNVector3(side * span), duration: seconds)
            there.timingMode = .easeInEaseOut
            if snapshot.drift {
                cameraNode.runAction(.repeatForever(.sequence([there, there.reversed()])), forKey: "move")
                drifting = true
            } else {
                cameraNode.runAction(there, forKey: "move")
            }
        }
    }
}

/// A person alone in the studio (3D_DIRECTION §4): the corridor far behind, soft key 4 500 K at 45°,
/// a warm back light, a cold fill; the finger turns the person (±180°, damped).
struct CharacterPreview: UIViewRepresentable {
    let appearance: CharacterAppearance
    let catalog: CharacterCatalog
    var rank: StoryRank = .enqueteur
    /// Degrees of yaw given by the finger.
    var yaw: Double = 0
    /// Close-up on the face (step 2) or full length (step 3).
    var closeUp = false

    func makeCoordinator() -> Holder { Holder() }

    @MainActor
    final class Holder {
        var key: CharacterAppearance?
        var rank: StoryRank?
        var closeUp: Bool?
        let scene = SCNScene()
        let pivot = SCNNode()
        let camera = SCNNode()
    }

    func makeUIView(context: Context) -> SCNView {
        let view = SCNView(frame: .zero)
        view.backgroundColor = .clear
        view.antialiasingMode = StageQuality.antialiasing
        view.preferredFramesPerSecond = 30
        view.isUserInteractionEnabled = false
        view.accessibilityElementsHidden = true
        let scene = context.coordinator.scene
        scene.background.contents = UIColor.clear
        let floor = SCNNode(geometry: SCNCylinder(radius: 0.6, height: 0.01))
        floor.geometry?.materials = [StageMaterial.matte(UIColor(white: 0.1, alpha: 1))]
        scene.rootNode.addChildNode(floor.at(0, -0.005, 0))
        scene.rootNode.addChildNode(context.coordinator.pivot)
        let key = SCNNode()
        key.light = SCNLight()
        key.light?.type = .spot
        key.light?.color = UIColor(red: 1.0, green: 0.95, blue: 0.9, alpha: 1)
        key.light?.intensity = 1100
        key.light?.spotOuterAngle = 70
        key.light?.castsShadow = true
        key.light?.shadowRadius = 6
        key.position = SCNVector3(1.6, 3.0, 1.8)
        key.look(at: SCNVector3(0, 1.1, 0))
        scene.rootNode.addChildNode(key)
        let back = SCNNode()
        back.light = SCNLight()
        back.light?.type = .spot
        back.light?.color = StagePalette.lamp2700
        back.light?.intensity = 900
        back.light?.spotOuterAngle = 60
        back.position = SCNVector3(-1.4, 2.4, -2.0)
        back.look(at: SCNVector3(0, 1.3, 0))
        scene.rootNode.addChildNode(back)
        let fill = SCNNode()
        fill.light = SCNLight()
        fill.light?.type = .ambient
        fill.light?.color = UIColor(red: 0.11, green: 0.13, blue: 0.19, alpha: 1)
        fill.light?.intensity = 380
        scene.rootNode.addChildNode(fill)
        let camera = context.coordinator.camera
        camera.camera = SCNCamera()
        scene.rootNode.addChildNode(camera)
        view.scene = scene
        view.pointOfView = camera
        view.isPlaying = true
        update(context.coordinator)
        return view
    }

    func updateUIView(_ view: SCNView, context: Context) { update(context.coordinator) }

    private func update(_ holder: Holder) {
        if holder.key != appearance || holder.rank != rank {
            holder.key = appearance
            holder.rank = rank
            holder.pivot.childNodes.forEach { $0.removeFromParentNode() }
            let feminine = appearance.presentation == "presentation_f"
            let person = CharacterRig.make(appearance, catalog: catalog, name: "preview",
                                           details: RigDetails(height: feminine ? 1.68 : 1.80, rank: rank))
            person.opacity = 0
            holder.pivot.addChildNode(person)
            person.runAction(.fadeIn(duration: 0.15))
        }
        holder.pivot.eulerAngles.y = Float(yaw * .pi / 180)
        if holder.closeUp != closeUp {
            holder.closeUp = closeUp
            let eye: Float = appearance.presentation == "presentation_f" ? 1.55 : 1.66
            SCNTransaction.begin()
            SCNTransaction.animationDuration = holder.closeUp == nil ? 0 : 0.45
            if closeUp {
                holder.camera.camera?.fieldOfView = CGFloat(2 * atan(18.0 / 85.0) * 180 / .pi)
                holder.camera.position = SCNVector3(0, eye, 1.45)
                holder.camera.look(at: SCNVector3(0, eye - 0.05, 0))
            } else {
                holder.camera.camera?.fieldOfView = CGFloat(2 * atan(18.0 / 50.0) * 180 / .pi)
                holder.camera.position = SCNVector3(0, 1.1, 3.6)
                holder.camera.look(at: SCNVector3(0, 0.92, 0))
            }
            SCNTransaction.commit()
        }
    }
}
#endif
