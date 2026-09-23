#if os(iOS)
import SwiftUI
import CaseEngine

/// "QUI EST VOTRE SUSPECT ?" — forced when the timer hits zero, or chosen early.
struct AccusationView: View {
    let session: GameSession
    @State private var selected: SuspectID?

    var body: some View {
        let game = session.game
        let timeLeft = session.remainingSeconds > 0
        VStack(spacing: Theme.Spacing.xl) {
            VStack(spacing: Theme.Spacing.s) {
                Text(timeLeft ? L10n.f("accuse.timeLeft", PhoneFormat.countdown(session.remainingSeconds)) : L10n.t("accuse.timeUp"))
                    .font(Theme.Fonts.overline)
                    .foregroundStyle(timeLeft ? Theme.Colors.textSecondary : Theme.Colors.alert)
                Text(L10n.t("accuse.title"))
                    .font(Theme.Fonts.display)
                    .multilineTextAlignment(.center)
                Text(session.caseFile.objective)
                    .font(Theme.Fonts.callout)
                    .foregroundStyle(Theme.Colors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, Theme.Spacing.xxl)

            LazyVGrid(columns: [GridItem(.flexible(), spacing: Theme.Spacing.m), GridItem(.flexible())], spacing: Theme.Spacing.m) {
                ForEach(session.caseFile.suspects) { suspect in
                    let isSelected = selected == suspect.id
                    Button {
                        selected = suspect.id
                        Haptics.selection()
                    } label: {
                        VStack(spacing: Theme.Spacing.s) {
                            Avatar(contact: game.contact(suspect.contact), size: Theme.Size.avatarL * 0.8)
                            Text(game.name(of: suspect.contact).uppercased())
                                .font(Theme.Fonts.headline)
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                            Text(suspect.role)
                                .font(Theme.Fonts.caption)
                                .foregroundStyle(Theme.Colors.textSecondary)
                                .multilineTextAlignment(.center)
                                .lineLimit(2)
                            let marks = game.marks[suspect.id]?.count ?? 0
                            let pins = game.pins[suspect.id]?.count ?? 0
                            if marks + pins > 0 {
                                Text(L10n.f("accuse.notes", pins, marks))
                                    .font(Theme.Fonts.caption2)
                                    .foregroundStyle(Theme.Colors.accent)
                            }
                        }
                        .padding(Theme.Spacing.m)
                        .frame(maxWidth: .infinity, minHeight: 170)
                        .background(RoundedRectangle(cornerRadius: Theme.Radius.l).fill(Theme.Colors.surface))
                        .overlay(
                            RoundedRectangle(cornerRadius: Theme.Radius.l)
                                .strokeBorder(isSelected ? Theme.Colors.textPrimary : Theme.Colors.separator, lineWidth: isSelected ? 2 : 1)
                        )
                        .scaleEffect(isSelected ? 1.03 : 1)
                        .animation(Theme.Motion.spring, value: isSelected)
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(isSelected ? .isSelected : [])
                }
            }
            .padding(.horizontal, Theme.Spacing.l)

            Spacer()

            VStack(spacing: Theme.Spacing.m) {
                Button {
                    if let selected { session.accuse(selected) }
                } label: {
                    Text(L10n.t("accuse.confirm"))
                        .font(Theme.Fonts.headline.weight(.heavy))
                        .tracking(2)
                        .foregroundStyle(selected == nil ? Theme.Colors.textTertiary : .black)
                        .frame(maxWidth: .infinity, minHeight: 54)
                        .background(RoundedRectangle(cornerRadius: Theme.Radius.m)
                            .fill(selected == nil ? Theme.Colors.surfaceElevated : Theme.Colors.textPrimary))
                }
                .buttonStyle(.plain)
                .disabled(selected == nil)
                if timeLeft {
                    Button(L10n.t("accuse.back")) { session.resumeInvestigation() }
                        .font(Theme.Fonts.subheadline)
                        .foregroundStyle(Theme.Colors.textSecondary)
                }
            }
            .padding(.horizontal, Theme.Spacing.l)
            .padding(.bottom, Theme.Spacing.l)
        }
        .background(Theme.Colors.background.ignoresSafeArea())
    }
}
#endif
