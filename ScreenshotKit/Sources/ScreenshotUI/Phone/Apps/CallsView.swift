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
        let missed = game.calls.filter { $0.direction == .missed }.count
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Segmented(options: [(false, L10n.t("calls.all")), (true, L10n.t("calls.missed"))], selection: $missedOnly)
                    .padding(.horizontal, Theme.Spacing.marginList)
                    .padding(.vertical, Theme.Spacing.s4)
                AppSectionHeader(title: L10n.t("calls.title"), count: calls.count, color: Theme.appAccent(.phone))
                CardGroup {
                    ForEach(Array(calls.enumerated()), id: \.element.id) { offset, call in
                        Button {
                            session.open(.contact(call.contact))
                        } label: {
                            CallRow(call: call, game: game)
                        }
                        .buttonStyle(.plain)
                        .onAppear { session.markSeen(ItemRef(.call, call.id)) }
                        .pinnable(ItemRef(.call, call.id), session: session, radius: Theme.Radius.sm)
                        if offset < calls.count - 1 { RowDivider(leading: 64) }
                    }
                }
                if calls.isEmpty {
                    EmptyStateView(title: L10n.t("calls.emptyTitle"), message: L10n.t("calls.emptyMessage"))
                }
            }
            .padding(.bottom, Theme.Spacing.bottomInset)
        }
        .appRoot(.phone, subtitle: L10n.f("calls.subtitle", game.calls.count, missed), session: session)
    }
}

/// Avatar with the call direction badge, name (red when missed), type + duration, day and time.
struct CallRow: View {
    let call: Call
    let game: Investigation

    var body: some View {
        let missed = call.direction == .missed
        HStack(spacing: Theme.Spacing.s4) {
            Avatar(contact: game.contact(call.contact), size: Theme.Size.avatarS)
                .overlay(alignment: .bottomTrailing) {
                    Image(systemName: CallsFormat.symbol(call))
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(Theme.Colors.textPrimary)
                        .frame(width: 18, height: 18)
                        .background(Circle().fill(missed ? Theme.Colors.alert : Theme.Colors.bgSelected))
                        .overlay(Circle().strokeBorder(Theme.Colors.bgSurface, lineWidth: 2))
                        .offset(x: 4, y: 4)
                }
            VStack(alignment: .leading, spacing: Theme.Spacing.s1) {
                Text(game.name(of: call.contact))
                    .font(Theme.Fonts.headline)
                    .foregroundStyle(missed ? Theme.Colors.alertText : Theme.Colors.textPrimary)
                    .lineLimit(1)
                Text(CallsFormat.arrow(call) + " " + CallsFormat.label(call))
                    .font(Theme.Fonts.callout)
                    .foregroundStyle(Theme.Colors.textSecondary)
            }
            Spacer(minLength: Theme.Spacing.s3)
            VStack(alignment: .trailing, spacing: Theme.Spacing.s1) {
                Text(PhoneFormat.time(call.at)).font(Theme.Fonts.dataStrong).foregroundStyle(Theme.Colors.textPrimary)
                Text(PhoneFormat.relative(call.at, now: game.phoneNow)).font(Theme.Fonts.caption).foregroundStyle(Theme.Colors.textTertiary)
            }
        }
        .padding(.horizontal, Theme.Spacing.s4)
        .frame(minHeight: Theme.Size.callRow)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }
}
#endif
