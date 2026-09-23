#if os(iOS)
import SwiftUI
import CaseEngine

/// Phone: recent calls (incoming, outgoing, missed) with exact time and duration.
struct CallsView: View {
    let session: GameSession
    @State private var missedOnly = false

    var body: some View {
        let game = session.game
        let calls = game.calls.filter { !missedOnly || $0.direction == .missed }
        List {
            ForEach(calls) { call in
                Button {
                    session.open(.contact(call.contact))
                } label: {
                    CallRow(call: call, game: game)
                }
                .buttonStyle(.plain)
                .onAppear { session.markSeen(ItemRef(.call, call.id)) }
                .pinnable(ItemRef(.call, call.id), session: session)
            }
        }
        .listStyle(.plain)
        .navigationTitle(L10n.t("calls.title"))
        .toolbar {
            ToolbarItem(placement: .principal) {
                Segmented(options: [(false, L10n.t("calls.all")), (true, L10n.t("calls.missed"))], selection: $missedOnly)
                    .frame(width: 220)
            }
        }
    }
}

struct CallRow: View {
    let call: Call
    let game: Investigation

    var body: some View {
        let missed = call.direction == .missed
        HStack(spacing: Theme.Spacing.s4) {
            Text(CallsFormat.arrow(call))
                .font(Theme.Fonts.headline)
                .foregroundStyle(missed ? Theme.Colors.alertText : Theme.Colors.textSecondary)
                .frame(width: 20)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: Theme.Spacing.s1) {
                Text(game.name(of: call.contact))
                    .font(Theme.Fonts.headline)
                    .foregroundStyle(missed ? Theme.Colors.alertText : Theme.Colors.textPrimary)
                Text(CallsFormat.label(call))
                    .font(Theme.Fonts.data)
                    .foregroundStyle(Theme.Colors.textSecondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: Theme.Spacing.s1) {
                Text(PhoneFormat.relative(call.at, now: game.phoneNow)).font(Theme.Fonts.caption)
                Text(PhoneFormat.time(call.at)).font(Theme.Fonts.data)
            }
            .foregroundStyle(Theme.Colors.textTertiary)
        }
        .frame(minHeight: Theme.Size.callRow)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }
}
#endif
