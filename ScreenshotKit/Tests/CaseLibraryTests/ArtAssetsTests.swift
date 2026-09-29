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
    /// Design assets of the final handoff (logo derivatives §H, stamps and seals, paper textures):
    /// group, file extension and size in pixels.
    static let designAssets: [String: (group: String, ext: String, size: (Int, Int))] = [
        "logo_tile": ("Brand", "png", (564, 564)),
        "logo_wordmark": ("Brand", "png", (990, 444)),
        "stamp_resolu_rouge_marque": ("Stamps", "png", (558, 184)),
        "stamp_confidentiel_rouge_marque": ("Stamps", "png", (996, 184)),
        "stamp_element_cle_rouge_marque": ("Stamps", "png", (923, 184)),
        "stamp_non_resolu_noir_marque": ("Stamps", "png", (850, 184)),
        "stamp_enqueteur_rouge": ("Stamps", "png", (777, 184)),
        "stamp_inspecteur_rouge": ("Stamps", "png", (850, 184)),
        "stamp_senior_rouge": ("Stamps", "png", (558, 184)),
        "stamp_experimente_rouge": ("Stamps", "png", (923, 184)),
        "seal_ben_bleu": ("Stamps", "png", (720, 720)),
        "signature_lacaze_bleu": ("Stamps", "png", (900, 300)),
        "tex_paper_grain": ("Textures", "jpg", (512, 512)),
        "tex_kraft_fibers": ("Textures", "jpg", (512, 512)),
    ]

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

    /// Width × height of a PNG (reads the IHDR chunk).
    static func pngSize(_ url: URL) throws -> (width: Int, height: Int)? {
        let bytes = [UInt8](try Data(contentsOf: url).prefix(24))
        guard bytes.count == 24, bytes[0] == 0x89, bytes[1] == 0x50 else { return nil }
        func int(_ i: Int) -> Int { bytes[i..<i + 4].reduce(0) { $0 << 8 | Int($1) } }
        return (int(16), int(20))
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
            #expect(FileManager.default.fileExists(atPath: set.file.path), "\(set.name): missing file")
            if let design = Self.designAssets[set.name] {
                #expect(set.group == design.group, "\(set.name) in \(set.group)")
                #expect(set.file.lastPathComponent == set.name + "." + design.ext, "\(set.name): file \(set.file.lastPathComponent)")
                continue
            }
            #expect(set.file.lastPathComponent == set.name + ".jpg", "\(set.name): file \(set.file.lastPathComponent)")
            if set.group == "Photos" {
                // Prepared by the photo pipeline: case<NNN>_photo_<photoId>, a photo of that case.
                let m = set.name.split(separator: "_", maxSplits: 2).map(String.init)
                try #require(m.count == 3 && m[0].hasPrefix("case") && m[1] == "photo", "Unexpected photo name \(set.name)")
                let file = cases.first { "case" + String(format: "%03d", $0.number) == m[0] }
                let caseFile = try #require(file, "\(set.name): no case \(m[0])")
                #expect(caseFile.devices.flatMap(\.photos).contains { $0.id == m[2] }, "\(set.name): no photo « \(m[2]) »")
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
            if let design = Self.designAssets[set.name] {
                let size = try #require(try design.ext == "png" ? Self.pngSize(set.file) : Self.jpegSize(set.file), "\(set.name): unreadable")
                #expect(size.width == design.size.0 && size.height == design.size.1, "\(set.name): \(size.width)×\(size.height)")
                continue
            }
            let size = try #require(try Self.jpegSize(set.file), "\(set.name) is not a JPEG")
            let expected = set.group == "Photos" ? (1024, 768) : set.name.hasPrefix("avatar_") ? (512, 512) : (1024, 1280)
            #expect(size.width == expected.0 && size.height == expected.1, "\(set.name): \(size.width)×\(size.height)")
        }
    }

    /// Every design asset of the final handoff is in the catalogue.
    @Test func designAssetsAreDelivered() throws {
        let names = Set(try Self.imageSets().map(\.name))
        let missing = Self.designAssets.keys.filter { !names.contains($0) }.sorted()
        #expect(missing.isEmpty, "Missing design assets: \(missing)")
    }

    /// No person is pictured: the generated portraits of the art pack are gone (the game shows
    /// initials), only design assets and the real photos of the phones remain.
    @Test func noPortraitOfAPerson() throws {
        for set in try Self.imageSets() {
            #expect(!["Portraits", "Avatars", "Players", "NPC"].contains(set.group), "\(set.name) pictures a person")
        }
    }
}
