#if os(iOS)
import SwiftUI
import CaseEngine

/// Calendar: the month grid (today circled, dots on days with events) above the agenda,
/// grouped by day in chronological order. Tapping a day jumps to it.
struct CalendarListView: View {
    let session: GameSession

    var body: some View {
        let game = session.game
        let now = game.phoneNow
        let events = game.device.calendar.sorted { $0.start < $1.start }
        let days = Dictionary(grouping: events, by: { $0.start.dayNumber })
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    MonthGrid(month: now, today: now, eventDays: Set(days.keys)) { day in
                        withAnimation(Theme.Motion.standard()) { proxy.scrollTo(day, anchor: .top) }
                    }
                    .padding(.horizontal, Theme.Spacing.marginCompact)
                    .padding(.top, Theme.Spacing.s4)
                    if events.isEmpty {
                        EmptyStateView(title: L10n.t("empty.calendarTitle"), message: L10n.t("empty.calendarMessage"))
                    }

                    ForEach(days.keys.sorted(), id: \.self) { day in
                        let dayEvents = days[day] ?? []
                        if let first = dayEvents.first {
                            AppSectionHeader(title: PhoneFormat.longDayCapitalized(first.start),
                                             color: day == now.dayNumber ? Theme.appAccent(.calendar) : Theme.Colors.textSecondary)
                                .id(day)
                        }
                        CardGroup {
                            ForEach(Array(dayEvents.enumerated()), id: \.element.id) { offset, event in
                                Button {
                                    session.open(.calendarEvent(event.id))
                                } label: {
                                    EventRow(event: event)
                                }
                                .buttonStyle(.plain)
                                if offset < dayEvents.count - 1 { RowDivider(leading: 76) }
                            }
                        }
                    }
                }
                .padding(.bottom, Theme.Spacing.bottomInset)
            }
        }
        .appRoot(.calendar, subtitle: PhoneFormat.monthYear(now), session: session)
    }
}

/// One agenda line: start (and end) time, a coloured bar, title and place.
struct EventRow: View {
    let event: CalendarEvent

    var body: some View {
        HStack(alignment: .top, spacing: Theme.Spacing.s4) {
            VStack(alignment: .trailing, spacing: 2) {
                Text(event.allDay == true ? L10n.t("calendar.allDay") : PhoneFormat.time(event.start))
                    .font(Theme.Fonts.dataStrong)
                    .foregroundStyle(Theme.Colors.textPrimary)
                if event.allDay != true, let end = event.end {
                    Text(PhoneFormat.time(end)).font(Theme.Fonts.dataSmall).foregroundStyle(Theme.Colors.textTertiary)
                }
            }
            .frame(width: 48, alignment: .trailing)
            RoundedRectangle(cornerRadius: 2).fill(Theme.appAccent(.calendar)).frame(width: 4)
            VStack(alignment: .leading, spacing: Theme.Spacing.s1) {
                Text(event.title).font(Theme.Fonts.headline).foregroundStyle(Theme.Colors.textPrimary)
                if let location = event.location {
                    Label(location, systemImage: "mappin")
                        .font(Theme.Fonts.callout)
                        .foregroundStyle(Theme.Colors.textSecondary)
                        .labelStyle(.titleAndIcon)
                }
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.right").font(.system(size: 13, weight: .semibold)).foregroundStyle(Theme.Colors.textTertiary)
                .padding(.top, 3)
        }
        .padding(Theme.Spacing.s4)
        .contentShape(Rectangle())
    }
}

/// Month grid, Monday first: today in a red disc, a dot under days that have events.
struct MonthGrid: View {
    let month: Moment
    let today: Moment
    let eventDays: Set<Int64>
    let onSelect: (Int64) -> Void

    var body: some View {
        let first = month.dayNumber - Int64(month.day - 1)
        let leading = Moment(seconds: first * 86_400).weekday - 1
        let count = Self.daysInMonth(firstDay: first)
        let cells: [Int64?] = Array(repeating: nil, count: leading) + (0..<count).map { Optional(first + Int64($0)) }
        VStack(spacing: Theme.Spacing.s3) {
            HStack(spacing: 0) {
                ForEach(Array(PhoneFormat.weekdayInitials.enumerated()), id: \.offset) { _, letter in
                    Text(letter).font(Theme.Fonts.dataSmall).foregroundStyle(Theme.Colors.textTertiary).frame(maxWidth: .infinity)
                }
            }
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 7), spacing: Theme.Spacing.s2) {
                ForEach(Array(cells.enumerated()), id: \.offset) { _, day in
                    if let day {
                        dayCell(day)
                    } else {
                        Color.clear.frame(height: 40)
                    }
                }
            }
        }
        .padding(Theme.Spacing.s4)
        .background(RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous).fill(Theme.Colors.bgSurface))
        .overlay(RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous).strokeBorder(Theme.Colors.line1))
    }

    private func dayCell(_ day: Int64) -> some View {
        let isToday = day == today.dayNumber
        let hasEvents = eventDays.contains(day)
        return Button {
            if hasEvents { onSelect(day) }
        } label: {
            VStack(spacing: 3) {
                Text("\(Moment(seconds: day * 86_400).day)")
                    .font(isToday ? Theme.Fonts.calloutStrong : Theme.Fonts.callout)
                    .foregroundStyle(isToday ? Theme.Colors.textPrimary : (hasEvents ? Theme.Colors.textPrimary : Theme.Colors.textSecondary))
                    .frame(width: 30, height: 30)
                    .background(Circle().fill(isToday ? Theme.Colors.alert : .clear))
                Circle()
                    .fill(hasEvents ? Theme.appAccent(.calendar) : .clear)
                    .frame(width: 5, height: 5)
            }
            .frame(maxWidth: .infinity, minHeight: 40)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isToday ? .isSelected : [])
    }

    private static func daysInMonth(firstDay: Int64) -> Int {
        let month = Moment(seconds: firstDay * 86_400).month
        var count = 28
        while count < 31 && Moment(seconds: (firstDay + Int64(count)) * 86_400).month == month { count += 1 }
        return count
    }
}

struct CalendarEventView: View {
    let eventID: String
    let session: GameSession

    var body: some View {
        let game = session.game
        if let event = game.index.calendarEvent(eventID) {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.s5) {
                    HStack(alignment: .top, spacing: Theme.Spacing.s4) {
                        RoundedRectangle(cornerRadius: 2).fill(Theme.appAccent(.calendar)).frame(width: 4, height: 56)
                        VStack(alignment: .leading, spacing: Theme.Spacing.s2) {
                            Text(event.title).font(Theme.Fonts.title).foregroundStyle(Theme.Colors.textPrimary)
                            if let location = event.location {
                                Label(location, systemImage: "mappin")
                                    .font(Theme.Fonts.callout)
                                    .foregroundStyle(Theme.Colors.textSecondary)
                            }
                        }
                    }
                    .padding(.horizontal, Theme.Spacing.marginList)
                    CardGroup {
                        InfoRow(icon: "calendar", label: L10n.t("calendar.date"), value: PhoneFormat.longDayCapitalized(event.start))
                            .padding(Theme.Spacing.s4)
                        if event.allDay != true {
                            RowDivider()
                            InfoRow(icon: "clock", label: L10n.t("calendar.time"),
                                    value: event.end.map { "\(PhoneFormat.time(event.start)) – \(PhoneFormat.time($0))" } ?? PhoneFormat.time(event.start))
                                .padding(Theme.Spacing.s4)
                        }
                    }
                    if let notes = event.notes {
                        AppSectionHeader(title: L10n.t("calendar.notes"))
                        Text(notes)
                            .font(Theme.Fonts.body)
                            .foregroundStyle(Theme.Colors.textPrimary)
                            .padding(Theme.Spacing.s4)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous).fill(Theme.Colors.bgSurface))
                            .padding(.horizontal, Theme.Spacing.marginCompact)
                    }
                }
                .padding(.vertical, Theme.Spacing.s5)
                .padding(.bottom, Theme.Spacing.bottomInset)
            }
            .navigationBarTitleDisplayMode(.inline)
            .pinnable(ItemRef(.calendar, event.id), session: session)
        }
    }
}
#endif
