import Foundation
import Testing

/// SCREENSHOT replaced an earlier prototype with a completely different theme.
/// This test scans every text file of the repository and fails if a word from that
/// old theme comes back (in code, data, comments or docs).
@Suite("No trace of the previous concept")
struct LegacyWordsTests {
    static let repositoryRoot = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()

    /// Written with a separator so this file does not match itself.
    static let words = [
        "resta|urant", "cuis|ine", "cuisi|nier", "coo|king", "fo|od", "reci|pe", "rece|tte", "ingredi|ent", "ingrédi|ent",
        "ch|ef", "bist|ro", "bistr|ot", "habit|ué", "habit|ue", "marg|ot", "di|sh", "kitc|hen", "cl|ient", "boulang|ère",
        "ri|so", "tyc|oon", "co|zy", "plat du jo|ur", "marm|ite",
    ].map { $0.replacingOccurrences(of: "|", with: "") }

    static let textExtensions: Set<String> = ["swift", "json", "md", "yml", "yaml", "sh", "xcconfig", "pbxproj", "xcscheme",
                                               "xcstrings", "txt", "py", "js", "html", "plist", "gitignore"]

    @Test func noLegacyWordAnywhere() throws {
        let pattern = "(?i)(?<![\\p{L}])(" + Self.words.map(NSRegularExpression.escapedPattern(for:)).joined(separator: "|") + ")(?:s|es|x)?(?![\\p{L}])"
        let regex = try NSRegularExpression(pattern: pattern)
        let enumerator = FileManager.default.enumerator(at: Self.repositoryRoot, includingPropertiesForKeys: nil)
        var findings: [String] = []
        var scanned = 0
        while let url = enumerator?.nextObject() as? URL {
            let path = url.path
            if path.contains("/.git/") || path.contains("/.build/") || path.contains("/.swiftpm/") { continue }
            let ext = url.pathExtension.isEmpty ? url.lastPathComponent.trimmingCharacters(in: ["."]) : url.pathExtension
            guard Self.textExtensions.contains(ext), let text = try? String(contentsOf: url, encoding: .utf8) else { continue }
            scanned += 1
            let range = NSRange(text.startIndex..., in: text)
            for match in regex.matches(in: text, range: range).prefix(3) {
                if let r = Range(match.range, in: text) {
                    findings.append("\(path.replacingOccurrences(of: Self.repositoryRoot.path, with: "")): \(text[r])")
                }
            }
        }
        #expect(scanned > 20, "the scan found too few files — wrong root?")
        #expect(findings.isEmpty, "Legacy words found:\n\(findings.joined(separator: "\n"))")
    }
}
