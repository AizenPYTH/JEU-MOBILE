import Foundation
import Testing
import CaseEngine
import CaseLibrary

/// The game plays no video, ever (decision of the project owner): no cinematic, no opening
/// sequence, no video file, no player. Each case is presented by its dossier instead.
@Suite("No cinematic")
struct NoCinematicTests {
    static let root = LegacyWordsTests.repositoryRoot

    private static func files(under path: String, extensions: Set<String>) -> [URL] {
        let base = root.appendingPathComponent(path)
        guard let walker = FileManager.default.enumerator(at: base, includingPropertiesForKeys: nil) else { return [] }
        return walker.compactMap { $0 as? URL }.filter { extensions.contains($0.pathExtension.lowercased()) }
    }

    @Test func noVideoFileIsShipped() {
        let videos = Self.files(under: "Screenshot", extensions: ["mp4", "mov", "m4v", "webm"])
            + Self.files(under: "ScreenshotKit/Sources", extensions: ["mp4", "mov", "m4v", "webm"])
        #expect(videos.isEmpty, "video files: \(videos.map(\.lastPathComponent))")
    }

    @Test func noCodePlaysAVideo() throws {
        // Written split so this file does not match itself.
        let banned = ["AV" + "Kit", "AV" + "Player", "Video" + "Player", "AVQueue" + "Player", ".mp" + "4"]
        let sources = Self.files(under: "ScreenshotKit/Sources", extensions: ["swift"]) + Self.files(under: "Screenshot", extensions: ["swift"])
        #expect(sources.count > 50)
        for url in sources {
            let text = try String(contentsOf: url, encoding: .utf8)
            for word in banned where text.contains(word) {
                Issue.record("\(url.lastPathComponent) uses \(word)")
            }
        }
    }

    @Test func noDataAsksForAnOpeningOrAVideo() throws {
        let data = Self.files(under: "ScreenshotKit/Sources/CaseLibrary/Resources", extensions: ["json"])
            + Self.files(under: "ScreenshotKit/Sources/StoryLibrary/Resources", extensions: ["json"])
        #expect(data.count > 10)
        for url in data {
            let text = try String(contentsOf: url, encoding: .utf8)
            for key in ["\"introScene\"", "\"video\"", "\"cinematic\""] where text.contains(key) {
                Issue.record("\(url.lastPathComponent) still declares \(key)")
            }
        }
    }

    /// Every case presented by a dossier (ENQUÊTES and HISTOIRE) has its « PREMIÈRE PISTE ».
    @Test func everyDossierHasAFirstLead() throws {
        for file in try CaseLibrary.loadCases() where !file.isAlibi {
            let lead = try #require(file.firstLead, "\(file.id) has no first lead")
            #expect((20...160).contains(lead.count), "\(file.id): \(lead.count) characters")
            #expect(file.synopsis.count <= 4, "\(file.id): the context stays short")
        }
    }
}
