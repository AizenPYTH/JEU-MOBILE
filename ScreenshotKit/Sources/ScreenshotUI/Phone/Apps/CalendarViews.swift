#if os(iOS)
import SwiftUI
import CaseEngine

/// Calendar: agenda grouped by day, upcoming first then the past.
struct CalendarListView: View {
    let session: GameSession

    var body: some View {
        let game = session.game
        let events = game.device.calendar.sorted { $0.start > $1.start }
        let days = Dictionary(grouping: events, by: { $0.start.dayNumber })
        List {
            ForEach(days.keys.sorted(by: >), id: \.self) { day in
                let dayEvents = (days[day] ?? []).sorted { $0.start < $1.start }
                Section(dayEvents.first.map { PhoneFormat.longDayCapitalized($0.start) } ?? "") {
                    ForEach(dayEvents) { event in
                        Button {
                            session.open(.calendarEvent(event.id))
                        } label: {
                            HStack(spacing: Theme.Spacing.m) {
                                RoundedRectangle(cornerRadius: 2).fill(Theme.Colors.alert).frame(width: 4)
                                VStack(alignment: .leading, spacing: Theme.Spacing.xxs) {
                                    Text(event.title).font(Theme.Fonts.headline)
                                    if let location = event.location {
                                        Text(location).font(Theme.Fonts.subheadline).foregroundStyle(Theme.Colors.textSecondary)
                                    }
                                }
                                Spacer()
                                Text(event.allDay == true ? L10n.t("calendar.allDay") : PhoneFormat.time(event.start))
                                    .font(Theme.Fonts.subheadline)
                                    .monospacedDigit()
                                    .foregroundStyle(Theme.Colors.textSecondary)
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .navigationTitle(AppID.calendar.title)
    }
}

struct CalendarEventView: View {
    let eventID: String
    let session: GameSession

    var body: some View {
        let game = session.game
        if let event = game.index.calendarEvent(eventID) {
            List {
                Section {
                    VStack(alignment: .leading, spacing: Theme.Spacing.s) {
                        Text(event.title).font(Theme.Fonts.title)
                        if let location = event.location {
                            Text(location).foregroundStyle(Theme.Colors.textSecondary)
                        }
                    }
                    .padding(.vertical, Theme.Spacing.s)
                }
                Section {
                    InfoRow(icon: "calendar", label: L10n.t("calendar.date"), value: PhoneFormat.longDayCapitalized(event.start))
                    if event.allDay != true {
                        InfoRow(icon: "clock", label: L10n.t("calendar.time"),
                                value: event.end.map { "\(PhoneFormat.time(event.start)) – \(PhoneFormat.time($0))" } ?? PhoneFormat.time(event.start))
                    }
                }
                if let notes = event.notes {
                    Section(L10n.t("calendar.notes")) { Text(notes) }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .pinnable(ItemRef(.calendar, event.id), session: session)
        }
    }
}
#endif
