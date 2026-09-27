import Foundation
import Testing
import CaseEngine
import CaseLibrary

/// The photo asset pipeline (scripts/photos, docs/photo_pipeline): its catalogue covers every photo
/// of every case, a piece of evidence only comes from a photo library when its query sheet says so,
/// every external image shipped in the game is a real photograph with its provenance, licence and
/// credit, and no AI-generated image is left in the game. The game never calls a photo API.
@Suite("Photo pipeline")
struct PhotoPipelineTests {
    static let repo = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
    static let photosGroup = repo.appendingPathComponent("ScreenshotKit/Sources/ScreenshotUI/Resources/Art.xcassets/Photos")

    static func json(_ path: String) throws -> [String: Any]? {
        let url = repo.appendingPathComponent(path)
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }
        return try JSONSerialization.jsonObject(with: Data(contentsOf: url)) as? [String: Any]
    }

    static let decisions: Set<String> = ["KEEP_REAL", "REPLACE_REAL", "CUSTOM_REAL", "PROCEDURAL", "REMOVE"]

    @Test func catalogueCoversEveryPhotoOnce() throws {
        let catalog = try #require(try Self.json("config/photo_catalog.json"), "config/photo_catalog.json missing: run ./scripts/photos.sh audit")
        let photos = try #require(catalog["photos"] as? [[String: Any]])
        var expected: Set<String> = []
        for file in try CaseLibrary.loadCases() {
            for photo in file.devices.flatMap(\.photos) {
                expected.insert("case\(String(format: "%03d", file.number))_photo_\(photo.id)")
            }
        }
        let ids = photos.compactMap { $0["assetId"] as? String }
        #expect(ids.count == Set(ids).count, "duplicate catalogue entries")
        #expect(Set(ids) == expected, "catalogue out of date: run ./scripts/photos.sh audit")
        for p in photos {
            let decision = p["decision"] as? String ?? ""
            #expect(Self.decisions.contains(decision), "\(p["assetId"] ?? "?"): \(decision)")
            if p["isEvidence"] as? Bool == true, decision == "REPLACE_REAL" {
                #expect(p["planned"] as? Bool == true, "\(p["assetId"] ?? "?"): evidence needs its query sheet (config/photo_queries)")
            }
        }
        let sources = try #require(catalog["sources"] as? [[String: Any]])
        for s in sources {
            #expect(!((s["query"] as? String) ?? "").trimmingCharacters(in: .whitespaces).isEmpty, "\(s["id"] ?? "?"): no query")
        }
    }

    @Test func everyShippedPhotoIsCredited() throws {
        let manifest = try Self.json("config/photo_sources.json") ?? [:]
        let sources = (manifest["sources"] as? [[String: Any]] ?? []).filter { $0["status"] as? String == "fetched" }
        let byID = Dictionary(uniqueKeysWithValues: sources.map { ($0["sourceId"] as? String ?? "", $0) })
        let assets = manifest["assets"] as? [[String: Any]] ?? []
        for s in sources {
            for field in ["provider", "providerPhotoId", "sourceUrl", "license", "licenseUrl", "queryUsed", "dateFetched", "attributionText"] {
                #expect(!((s[field] as? String) ?? "").isEmpty, "\(s["sourceId"] ?? "?"): no \(field)")
            }
            if ["openverse", "wikimedia"].contains(s["provider"] as? String ?? "") {
                #expect(["cc0", "pdm", "by", "by-sa"].contains(s["license"] as? String ?? ""), "\(s["sourceId"] ?? "?"): licence")
            }
        }
        var listed: Set<String> = []
        for a in assets {
            let id = a["assetId"] as? String ?? ""
            listed.insert(id)
            #expect(byID[a["sourceId"] as? String ?? ""] != nil, "\(id): no provenance")
            let path = Self.repo.appendingPathComponent(a["finalAssetPath"] as? String ?? "")
            #expect(FileManager.default.fileExists(atPath: path.path), "\(id): missing file")
        }
        // No orphan image in the Photos group.
        let fm = FileManager.default
        if fm.fileExists(atPath: Self.photosGroup.path) {
            for entry in try fm.contentsOfDirectory(atPath: Self.photosGroup.path) where entry.hasSuffix(".imageset") {
                #expect(listed.contains(String(entry.dropLast(".imageset".count))), "\(entry): not in the manifest")
            }
        }
        // The in-game credits list exactly the sources in use.
        let credits = try Self.json("ScreenshotKit/Sources/ScreenshotUI/Resources/PhotoCredits.json")
        let used = Set(assets.compactMap { $0["sourceId"] as? String })
        let items = credits?["items"] as? [[String: Any]] ?? []
        #expect(items.count == used.count, "PhotoCredits.json out of date: run ./scripts/photos.sh report")
        if sources.contains(where: { $0["provider"] as? String == "pexels" && used.contains($0["sourceId"] as? String ?? "") }) {
            #expect(credits?["pexels"] as? Bool == true, "« Photos provided by Pexels » must be shown")
        }
    }

    /// No AI-generated picture anywhere in the game's images: the portraits the art pack delivered
    /// were generated and are gone (the game shows initials); the phones only show real photographs.
    @Test func noAIImageIsShipped() throws {
        let art = Self.repo.appendingPathComponent("ScreenshotKit/Sources/ScreenshotUI/Resources/Art.xcassets")
        let config = try #require(try Self.json("config/photo_pipeline.json"))
        let removed = (config["removedImages"] as? [[String: Any]] ?? []).compactMap { $0["name"] as? String }
        #expect(removed.count >= 5)
        let enumerator = FileManager.default.enumerator(at: art, includingPropertiesForKeys: nil)
        var sets: [String] = []
        while let url = enumerator?.nextObject() as? URL {
            guard url.pathExtension == "imageset" else { continue }
            sets.append(url.deletingPathExtension().lastPathComponent)
        }
        for name in removed { #expect(!sets.contains(name), "\(name) is an AI image") }
        // People are never pictured: no portrait, avatar or player photo is shipped.
        for name in sets {
            #expect(!name.hasPrefix("portrait_") && !name.hasPrefix("avatar_") && !name.hasPrefix("player_") && !name.hasPrefix("npc_"), "\(name)")
        }
    }

    @Test func noApiKeyInTheRepository() throws {
        let pattern = try NSRegularExpression(pattern: #"(PEXELS_API_KEY)\s*[:=]\s*['"]?[A-Za-z0-9]{20,}"#)
        let exts: Set<String> = ["json", "py", "sh", "yml", "yaml", "md", "swift", "xcconfig", "plist"]
        var found: [String] = []
        let enumerator = FileManager.default.enumerator(at: Self.repo, includingPropertiesForKeys: nil)
        while let url = enumerator?.nextObject() as? URL {
            let p = url.path
            if p.contains("/.git/") || p.contains("/.build/") || p.contains("/cache/") { continue }
            guard exts.contains(url.pathExtension), let text = try? String(contentsOf: url, encoding: .utf8) else { continue }
            if pattern.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)) != nil { found.append(p) }
        }
        #expect(found.isEmpty, "API key in clear: \(found)")
    }

    /// Offline at runtime: the game ships its photos, it never asks a photo service.
    @Test func theGameNeverCallsAPhotoApi() throws {
        let sources = Self.repo.appendingPathComponent("ScreenshotKit/Sources")
        let enumerator = FileManager.default.enumerator(at: sources, includingPropertiesForKeys: nil)
        while let url = enumerator?.nextObject() as? URL {
            guard url.pathExtension == "swift", let text = try? String(contentsOf: url, encoding: .utf8) else { continue }
            for word in ["api.pexels.com", "api.openverse.org", "URLSession"] {
                #expect(!text.contains(word), "\(url.lastPathComponent) uses \(word)")
            }
        }
    }
}
