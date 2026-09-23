import Testing
@testable import GameCore

@Suite("Compact numbers (design rules)")
struct CompactNumberTests {
    private let nnbsp = "\u{202F}"

    @Test func smallNumbersAreWritten() {
        #expect(CompactNumber.format(0, style: .french) == "0")
        #expect(CompactNumber.format(850, style: .french) == "850")
        #expect(CompactNumber.format(9_850, style: .french) == "9\(nnbsp)850")
        #expect(CompactNumber.format(9_999, style: .english) == "9,999")
    }

    @Test func designExamplesInFrench() {
        #expect(CompactNumber.format(12_400, style: .french) == "12,4\(nnbsp)k")
        #expect(CompactNumber.format(1_200_000, style: .french) == "1,2\(nnbsp)M")
        #expect(CompactNumber.format(45_700_000_000, style: .french) == "45,7\(nnbsp)Md")
        #expect(CompactNumber.format(128_000, style: .french) == "128\(nnbsp)k")
    }

    @Test func designExamplesInEnglish() {
        #expect(CompactNumber.format(12_400, style: .english) == "12.4K")
        #expect(CompactNumber.format(1_200_000, style: .english) == "1.2M")
        #expect(CompactNumber.format(45_700_000_000, style: .english) == "45.7B")
        #expect(CompactNumber.format(3_000_000_000_000_000, style: .english) == "3Qa")
    }

    @Test func roundsDownNeverUp() {
        #expect(CompactNumber.format(12_499, style: .english) == "12.4K")
        #expect(CompactNumber.format(999_999, style: .english) == "999K")
        #expect(CompactNumber.format(1_999_999, style: .english) == "1.99M")
    }

    @Test func hudStaysShort() {
        for value in [10_000, 99_999, 123_456_789, 9_876_543_210_987, Int.max] {
            let text = CompactNumber.format(value, style: .english)
            #expect(text.count <= 7, "\(value) → \(text)")
        }
    }
}
