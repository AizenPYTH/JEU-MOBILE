import Foundation
import Testing
import CaseEngine
import CaseLibrary

/// The art catalogue (`ScreenshotUI/Resources/Art.xcassets`) is matched to the cases by file name only:
/// `portrait_<NNN>_<contactId>` / `avatar_<NNN>_<contactId>`. These tests check that chain —
/// asset present → name → case and contact that exist → right person → right size — so a renamed
/// contact in a case script never leaves an orphan picture. Missing pictures are fine (initials).
@Suite("Art assets")
struct ArtAssetsTests {
    static let catalog = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
        .appendingPathComponent("Sources/ScreenshotUI/Resources/Art.xcassets")

    static let metaNames: Set<String> = ["player_elise_a", "player_elise_b", "player_vincent_a", "player_vincent_b", "npc_lacaze"]
    /// Full-screen artwork of the loading screen, and its size (the native bar is placed on it in pixels).
    static let loadingScreens: [String: (Int, Int)] = ["loading_main": (941, 1672)]

    struct ImageSet {
        let name: String
        let group: String
        let file: URL
    }

    static func imageSets() throws -> [ImageSet] {
        let fm = FileManager.default
        var sets: [ImageSet] = []
        for group in try fm.contentsOfDirectory(atPath: catalog.path).sorted() {
            let groupURL = catalog.appendingPathComponent(group)
            var isDir: ObjCBool = false
            guard fm.fileExists(atPath: groupURL.path, isDirectory: &isDir), isDir.boolValue else { continue }
            for entry in try fm.contentsOfDirectory(atPath: groupURL.path).sorted() where entry.hasSuffix(".imageset") {
                let dir = groupURL.appendingPathComponent(entry)
                let contents = try JSONSerialization.jsonObject(with: Data(contentsOf: dir.appendingPathComponent("Contents.json"))) as? [String: Any]
                let images = contents?["images"] as? [[String: Any]] ?? []
                let filename = try #require(images.first?["filename"] as? String, "\(entry) has no image")
                sets.append(ImageSet(name: String(entry.dropLast(".imageset".count)), group: group, file: dir.appendingPathComponent(filename)))
            }
        }
        return sets
    }

    /// Width × height of a baseline or progressive JPEG (reads the SOF marker).
    static func jpegSize(_ url: URL) throws -> (width: Int, height: Int)? {
        let bytes = [UInt8](try Data(contentsOf: url))
        guard bytes.count > 4, bytes[0] == 0xFF, bytes[1] == 0xD8 else { return nil }
        var i = 2
        while i + 9 < bytes.count {
            guard bytes[i] == 0xFF else { i += 1; continue }
            let marker = bytes[i + 1]
            let length = Int(bytes[i + 2]) << 8 | Int(bytes[i + 3])
            if (0xC0...0xCF).contains(marker), marker != 0xC4, marker != 0xC8, marker != 0xCC {
                return (Int(bytes[i + 7]) << 8 | Int(bytes[i + 8]), Int(bytes[i + 5]) << 8 | Int(bytes[i + 6]))
            }
            i += 2 + length
        }
        return nil
    }

    @Test func everyPictureBelongsToAnExistingPerson() throws {
        let cases = try CaseLibrary.loadCases()
        let sets = try Self.imageSets()
        #expect(!sets.isEmpty)
        for set in sets {
            #expect(set.file.lastPathComponent == set.name + ".jpg", "\(set.name): file \(set.file.lastPathComponent)")
            #expect(FileManager.default.fileExists(atPath: set.file.path), "\(set.name): missing file")
            if Self.loadingScreens[set.name] != nil {
                #expect(set.group == "Loading", "\(set.name) in \(set.group)")
                continue
            }
            if Self.metaNames.contains(set.name) {
                #expect(set.group == (set.name.hasPrefix("npc_") ? "NPC" : "Players"), "\(set.name) in \(set.group)")
                continue
            }
            let parts = set.name.split(separator: "_", maxSplits: 2).map(String.init)
            try #require(parts.count == 3 && ["portrait", "avatar"].contains(parts[0]), "Unexpected asset name \(set.name)")
            #expect(set.group == (parts[0] == "portrait" ? "Portraits" : "Avatars"), "\(set.name) in \(set.group)")
            let file = cases.first { String(format: "%03d", $0.number) == parts[1] }
            let caseFile = try #require(file, "\(set.name): no case #\(parts[1])")
            let contacts = caseFile.devices.flatMap(\.contacts)
            #expect(contacts.contains { $0.id == parts[2] }, "\(set.name): no contact « \(parts[2]) » in case #\(parts[1])")
        }
    }

    @Test func picturesHaveTheirSpecifiedSize() throws {
        for set in try Self.imageSets() {
            let size = try #require(try Self.jpegSize(set.file), "\(set.name) is not a JPEG")
            let expected = Self.loadingScreens[set.name] ?? (set.name.hasPrefix("avatar_") ? (512, 512) : (1024, 1280))
            #expect(size.width == expected.0 && size.height == expected.1, "\(set.name): \(size.width)×\(size.height)")
        }
    }

    /// The test pictures of #001 land on the right people.
    @Test func firstCasePortraitsMatchTheirSuspects() throws {
        let file = try #require(try CaseLibrary.loadCases().first { $0.number == 1 })
        let contacts = file.devices.flatMap(\.contacts)
        let names = Set(try Self.imageSets().map(\.name))
        #expect(contacts.first { $0.id == "sarah" }?.name == "Sarah Vasseur")
        #expect(contacts.first { $0.id == "karim" }?.name == "Karim Haddad")
        #expect(names.contains("portrait_001_sarah") && names.contains("portrait_001_karim"))
        #expect(file.suspects.contains { $0.contact == "sarah" } && file.suspects.contains { $0.contact == "karim" })
    }
}
