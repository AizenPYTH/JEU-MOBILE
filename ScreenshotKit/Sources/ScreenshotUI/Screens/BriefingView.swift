#if os(iOS)
import SwiftUI
import CaseEngine

/// Before the timer starts: what happened, who is involved, what they told the police.
struct BriefingView: View {
    let file: CaseFile
    let rules: GameRules
    let onStart: () -> Void
    let onBack: () -> Void

    private var contacts: [Contact] { file.devices.flatMap(\.contacts) }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.xl) {
                    Button(action: onBack) {
                        Label(L10n.t("common.back"), systemImage: "chevron.left").font(Theme.Fonts.subheadline)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(Theme.Colors.textSecondary)

                    VStack(alignment: .leading, spacing: Theme.Spacing.s) {
                        Text(L10n.f("bar.case", file.number)).font(Theme.Fonts.overline).foregroundStyle(Theme.Colors.alert)
                        Text(file.title).font(Theme.Fonts.display)
                    }
                    VStack(alignment: .leading, spacing: Theme.Spacing.m) {
                        ForEach(Array(file.synopsis.enumerated()), id: \.offset) { _, paragraph in
                            Text(paragraph).font(Theme.Fonts.body)
                        }
                    }
                    VStack(alignment: .leading, spacing: Theme.Spacing.s) {
                        Text(L10n.t("briefing.objective")).font(Theme.Fonts.overline).foregroundStyle(Theme.Colors.textSecondary)
                        Text(file.objective).font(Theme.Fonts.headline)
                    }
                    VStack(alignment: .leading, spacing: Theme.Spacing.m) {
                        Text(L10n.t("briefing.statements")).font(Theme.Fonts.overline).foregroundStyle(Theme.Colors.textSecondary)
                        ForEach(file.suspects) { suspect in
                            let contact = contacts.first { $0.id == suspect.contact }
                            HStack(alignment: .top, spacing: Theme.Spacing.m) {
                                Avatar(contact: contact)
                                VStack(alignment: .leading, spacing: Theme.Spacing.xxs) {
                                    Text(contact?.name ?? suspect.contact).font(Theme.Fonts.headline)
                                    Text(suspect.role).font(Theme.Fonts.caption).foregroundStyle(Theme.Colors.textSecondary)
                                    Text(suspect.statement).font(Theme.Fonts.callout.italic())
                                }
                            }
                        }
                    }
                    VStack(alignment: .leading, spacing: Theme.Spacing.s) {
                        Text(L10n.t("briefing.rules")).font(Theme.Fonts.overline).foregroundStyle(Theme.Colors.textSecondary)
                        Label(L10n.f("briefing.rule.time", PhoneFormat.countdown(Double(file.durationSeconds))), systemImage: "timer")
                        Label(L10n.t("briefing.rule.cost"), systemImage: "hourglass")
                        Label(L10n.t("briefing.rule.pin"), systemImage: "hand.tap")
                        Label(L10n.t("briefing.rule.end"), systemImage: "person.fill.questionmark")
                    }
                    .font(Theme.Fonts.callout)
                }
                .padding(Theme.Spacing.xl)
            }
            Button(action: onStart) {
                Text(L10n.t("briefing.start"))
                    .font(Theme.Fonts.headline.weight(.heavy))
                    .tracking(1)
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity, minHeight: 54)
                    .background(RoundedRectangle(cornerRadius: Theme.Radius.m).fill(Theme.Colors.textPrimary))
            }
            .buttonStyle(.plain)
            .padding(Theme.Spacing.l)
        }
        .background(Theme.Colors.background.ignoresSafeArea())
    }
}
#endif
