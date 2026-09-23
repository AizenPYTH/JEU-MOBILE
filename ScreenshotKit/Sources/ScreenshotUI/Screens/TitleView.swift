#if os(iOS)
import SwiftUI
import CaseEngine

/// Title screen + the list of cases.
struct TitleView: View {
    let cases: [CaseFile]
    let progress: [String: CaseProgress]
    let onOpen: (CaseFile) -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.xl) {
                VStack(alignment: .leading, spacing: Theme.Spacing.s) {
                    HStack(spacing: Theme.Spacing.s) {
                        Circle().fill(Theme.Colors.alert).frame(width: 8, height: 8)
                        Text(L10n.t("title.recording")).font(Theme.Fonts.overline).foregroundStyle(Theme.Colors.alert)
                    }
                    Text("SCREENSHOT")
                        .font(Theme.Fonts.wordmark)
                        .tracking(4)
                        .foregroundStyle(Theme.Colors.textPrimary)
                    Text(L10n.t("title.tagline"))
                        .font(Theme.Fonts.callout)
                        .foregroundStyle(Theme.Colors.textSecondary)
                }
                .padding(.top, Theme.Spacing.xxl)

                Text(L10n.t("title.cases")).font(Theme.Fonts.overline).foregroundStyle(Theme.Colors.textSecondary)
                ForEach(cases) { file in
                    Button { onOpen(file) } label: { CaseCard(file: file, progress: progress[file.id]) }
                        .buttonStyle(.plain)
                }
                ForEach((cases.count + 1)...(cases.count + 2), id: \.self) { number in
                    LockedCaseCard(number: number)
                }
            }
            .padding(Theme.Spacing.xl)
        }
        .background(
            ZStack {
                Theme.Colors.background
                RadialGradient(colors: [Color(hex: 0x14202E).opacity(0.8), .clear], center: .top, startRadius: 0, endRadius: 500)
            }
            .ignoresSafeArea()
        )
    }
}

struct CaseCard: View {
    let file: CaseFile
    let progress: CaseProgress?

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.m) {
            HStack {
                Text(L10n.f("bar.case", file.number)).font(Theme.Fonts.overline).foregroundStyle(Theme.Colors.textSecondary)
                Spacer()
                HStack(spacing: 3) {
                    ForEach(1...3, id: \.self) { level in
                        Circle()
                            .fill(level <= file.difficulty ? Theme.Colors.textPrimary : Theme.Colors.surfaceHigh)
                            .frame(width: 6, height: 6)
                    }
                }
                .accessibilityLabel(Text(L10n.f("a11y.difficulty", file.difficulty)))
            }
            Text(file.title).font(Theme.Fonts.title)
            Text(file.tagline).font(Theme.Fonts.callout).foregroundStyle(Theme.Colors.textSecondary)
            HStack(spacing: Theme.Spacing.l) {
                Label(PhoneFormat.countdown(Double(file.durationSeconds)), systemImage: "timer")
                Label("\(file.suspects.count)", systemImage: "person.2")
                Spacer()
                if let progress, progress.plays > 0 {
                    Text(progress.solved ? L10n.f("title.best", progress.bestScore) : L10n.t("title.unsolved"))
                        .foregroundStyle(progress.solved ? Theme.Colors.success : Theme.Colors.textSecondary)
                }
            }
            .font(Theme.Fonts.footnote.monospacedDigit())
            .foregroundStyle(Theme.Colors.textSecondary)
        }
        .padding(Theme.Spacing.l)
        .background(RoundedRectangle(cornerRadius: Theme.Radius.l).fill(Theme.Colors.surface))
        .overlay(RoundedRectangle(cornerRadius: Theme.Radius.l).strokeBorder(Theme.Colors.separator))
    }
}

struct LockedCaseCard: View {
    let number: Int

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                Text(L10n.f("bar.case", number)).font(Theme.Fonts.overline)
                Text(L10n.t("title.soon")).font(Theme.Fonts.headline)
            }
            Spacer()
            Image(systemName: "lock.fill")
        }
        .foregroundStyle(Theme.Colors.textTertiary)
        .padding(Theme.Spacing.l)
        .background(RoundedRectangle(cornerRadius: Theme.Radius.l).strokeBorder(Theme.Colors.separator, style: StrokeStyle(lineWidth: 1, dash: [5, 4])))
    }
}
#endif
