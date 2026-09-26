#if os(iOS)
import SwiftUI
import UIKit
import CaseEngine

/// Real images delivered by the art team (`Resources/Art.xcassets`), found by name only — no case data
/// refers to them. Every lookup can fail: the views then keep their current rendering (initials).
///
/// Names (handoff « Pack personnages » §7):
///   portrait_<NNN>_<contactId>   case file ID photo, 1024 × 1280 — paper only
///   avatar_<NNN>_<contactId>     informal photo, 512 × 512 — inside the phone only
///   player_<elise|vincent>_<a|b>, npc_lacaze
/// `<NNN>` = case number on 3 digits, `<contactId>` = the contact's id in the case (`me` = the owner).
@MainActor
enum ArtLibrary {
    static func portraitName(case number: Int, contact id: ContactID) -> String {
        "portrait_\(dossierNumber(number))_\(id)"
    }

    static func avatarName(case number: Int, contact id: ContactID) -> String {
        "avatar_\(dossierNumber(number))_\(id)"
    }

    /// The case file photo of a contact, if delivered.
    static func portrait(case number: Int?, contact: Contact?) -> UIImage? {
        guard let number, let contact else { return nil }
        return image(portraitName(case: number, contact: contact.id))
    }

    /// The phone avatar of a contact, if delivered.
    static func avatar(case number: Int?, contact: Contact?) -> UIImage? {
        guard let number, let contact else { return nil }
        return image(avatarName(case: number, contact: contact.id))
    }

    /// Player appearances (« Qui enquête ? », profile) and the commander (assignment).
    enum Player: String, CaseIterable { case eliseA = "player_elise_a", eliseB = "player_elise_b", vincentA = "player_vincent_a", vincentB = "player_vincent_b" }
    static func player(_ player: Player) -> UIImage? { image(player.rawValue) }
    static var commander: UIImage? { image("npc_lacaze") }

    /// Launch (final handoff §F-01): the pictures seen first, in order — the title banner, the paper
    /// and kraft textures, the suspects of `file` (case #001, or the case in progress), then the
    /// four investigator photos.
    static func launchNames(first file: CaseFile?) -> [String] {
        var names = ["logo_wordmark", "tex_paper_grain", "tex_kraft_fibers"]
        if let file {
            names += file.suspects.map { portraitName(case: file.number, contact: $0.contact) }
        }
        names += Player.allCases.map(\.rawValue)
        return names
    }

    /// Decodes the named pictures ahead of display, in order, one per main-actor turn, so the screen
    /// that shows them first does not stutter. Missing ones are remembered as missing (initials);
    /// a name already warmed is skipped.
    static func warmUp(names: [String]) async {
        for name in names where !prepared.contains(name) {
            prepared.insert(name)
            guard let image = image(name) else { continue }
            if let ready = image.preparingForDisplay() { cache[name] = ready }
            await Task.yield()
        }
    }

    /// The delivered portraits of every case (after the launch screen, in the background).
    static func warmUp(portraitsOf cases: [CaseFile]) async {
        let names: [String] = cases.flatMap { file in
            file.devices.flatMap(\.contacts).map { portraitName(case: file.number, contact: $0.id) }
        }
        await warmUp(names: names)
    }

    private static var cache: [String: UIImage] = [:]
    private static var missing: Set<String> = []
    /// Names already decoded ahead of display (or found missing).
    private static var prepared: Set<String> = []

    static func image(_ name: String) -> UIImage? {
        if let hit = cache[name] { return hit }
        if missing.contains(name) { return nil }
        guard let image = UIImage(named: name, in: .module, with: nil) else {
            missing.insert(name)
            return nil
        }
        cache[name] = image
        return image
    }
}

private struct CaseNumberKey: EnvironmentKey {
    static let defaultValue: Int? = nil
}

extension EnvironmentValues {
    /// The case on screen, so a portrait can find `portrait_<NNN>_<contactId>`.
    var caseNumber: Int? {
        get { self[CaseNumberKey.self] }
        set { self[CaseNumberKey.self] = newValue }
    }
}
#endif
