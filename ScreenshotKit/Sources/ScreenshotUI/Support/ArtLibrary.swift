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

    /// Player appearances and the commander: in the catalogue for the player-selection and
    /// recruitment screens, which do not exist yet.
    enum Player: String, CaseIterable { case eliseA = "player_elise_a", eliseB = "player_elise_b", vincentA = "player_vincent_a", vincentB = "player_vincent_b" }
    static func player(_ player: Player) -> UIImage? { image(player.rawValue) }
    static var commander: UIImage? { image("npc_lacaze") }

    /// Launch: finds the delivered portraits of every case and decodes them ahead of display, so the
    /// first file opened does not stutter. Missing ones are remembered as missing (initials).
    static func warmUp(portraitsOf cases: [CaseFile]) async {
        for file in cases {
            for contact in file.devices.flatMap(\.contacts) {
                let name = portraitName(case: file.number, contact: contact.id)
                guard let image = image(name) else { continue }
                if let ready = image.preparingForDisplay() { cache[name] = ready }
                await Task.yield()
            }
        }
    }

    private static var cache: [String: UIImage] = [:]
    private static var missing: Set<String> = []

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
