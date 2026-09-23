import Testing
@testable import CaseEngine

@Suite("Moment")
struct MomentTests {
    @Test func parsesAndPrints() throws {
        let moment = try #require(Moment("2026-09-12 22:17"))
        #expect(moment.year == 2026 && moment.month == 9 && moment.day == 12)
        #expect(moment.hour == 22 && moment.minute == 17)
        #expect(moment.description == "2026-09-12 22:17")
        #expect(moment.clockText == "22:17")
        #expect(Moment("2026-09-12 22:17:05")?.second == 5)
    }

    @Test func weekdays() {
        #expect(Moment("2026-09-12 12:00")?.weekday == 6) // Saturday
        #expect(Moment("2026-09-13 12:00")?.weekday == 7) // Sunday
        #expect(Moment("1970-01-01 00:00")?.weekday == 4) // Thursday
    }

    @Test(arguments: ["", "2026-09-12", "2026-13-01 10:00", "2026-09-12 25:00", "hier 22h"])
    func rejectsMalformed(_ text: String) {
        #expect(Moment(text) == nil)
    }

    @Test func ordersAndAdds() throws {
        let a = try #require(Moment("2026-09-12 23:59"))
        let b = a.adding(seconds: 120)
        #expect(b.description == "2026-09-13 00:01")
        #expect(a < b && !a.isSameDay(as: b))
    }
}
