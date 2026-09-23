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
                Picker("", selection: $missedOnly) {
                    Text(L10n.t("calls.all")).tag(false)
                    Text(L10n.t("calls.missed")).tag(true)
                }
                .pickerStyle(.segmented)
                .frame(width: 200)
            }
        }
    }
}

struct CallRow: View {
    let call: Call
    let game: Investigation

    var body: some View {
        HStack(spacing: Theme.Spacing.m) {
            Image(systemName: icon)
                .foregroundStyle(call.direction == .missed ? Theme.Colors.missed : Theme.Colors.textSecondary)
                .frame(width: 22)
            VStack(alignment: .leading, spacing: Theme.Spacing.xxs) {
                Text(game.name(of: call.contact))
                    .font(Theme.Fonts.headline)
                    .foregroundStyle(call.direction == .missed ? Theme.Colors.missed : Theme.Colors.textPrimary)
                Text(label)
                    .font(Theme.Fonts.subheadline)
                    .foregroundStyle(Theme.Colors.textSecondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: Theme.Spacing.xxs) {
                Text(PhoneFormat.relative(call.at, now: game.phoneNow))
                Text(PhoneFormat.time(call.at)).monospacedDigit()
            }
            .font(Theme.Fonts.subheadline)
            .foregroundStyle(Theme.Colors.textSecondary)
        }
        .padding(.vertical, Theme.Spacing.xxs)
        .contentShape(Rectangle())
    }

    private var icon: String {
        switch call.direction {
        case .incoming: "phone.arrow.down.left"
        case .outgoing: "phone.arrow.up.right"
        case .missed: "phone.down.fill"
        }
    }

    private var label: String {
        switch call.direction {
        case .incoming: L10n.f("calls.incoming", PhoneFormat.duration(call.durationSeconds))
        case .outgoing: call.durationSeconds > 0 ? L10n.f("calls.outgoing", PhoneFormat.duration(call.durationSeconds)) : L10n.t("calls.noAnswer")
        case .missed: L10n.t("calls.missedLabel")
        }
    }
}
#endif
