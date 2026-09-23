#if os(iOS)
import SwiftUI
import CaseEngine

// MARK: - Logo

/// "TRACE" in Geist 600, wide tracking, framed by 4 capture marks; the bottom-right one is amber.
struct Logo: View {
    var body: some View {
        Text("TRACE")
            .font(Theme.Fonts.logo)
            .tracking(Theme.Tracking.logo)
            .foregroundStyle(Theme.Colors.textPrimary)
            .padding(.horizontal, Theme.Spacing.s4)
            .padding(.vertical, Theme.Spacing.s3)
            .overlay { CaptureMarks() }
            .accessibilityAddTraits(.isHeader)
    }
}

/// The four corner brackets of a screen capture.
struct CaptureMarks: View {
    var body: some View {
        GeometryReader { geo in
            let m = Theme.Size.captureMark
            let w = geo.size.width, h = geo.size.height
            ZStack {
                corner(x: 0, y: 0, dx: 1, dy: 1, m: m).stroke(Theme.Colors.textPrimary, lineWidth: 1.5)
                corner(x: w, y: 0, dx: -1, dy: 1, m: m).stroke(Theme.Colors.textPrimary, lineWidth: 1.5)
                corner(x: 0, y: h, dx: 1, dy: -1, m: m).stroke(Theme.Colors.textPrimary, lineWidth: 1.5)
                corner(x: w, y: h, dx: -1, dy: -1, m: m).stroke(Theme.Colors.signal, lineWidth: 1.5)
            }
        }
        .accessibilityHidden(true)
    }

    private func corner(x: CGFloat, y: CGFloat, dx: CGFloat, dy: CGFloat, m: CGFloat) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: x, y: y + dy * m))
        path.addLine(to: CGPoint(x: x, y: y))
        path.addLine(to: CGPoint(x: x + dx * m, y: y))
        return path
    }
}

// MARK: - Shared pieces

/// "‹ Accueil" back row + large title, for the menu screens.
struct MetaHeader: View {
    let title: String
    let onBack: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.s3) {
            Button(action: onBack) {
                Text("‹ " + L10n.t("home.title")).font(Theme.Fonts.callout).foregroundStyle(Theme.Colors.textSecondary)
                    .frame(minHeight: Theme.Size.hit)
            }
            .buttonStyle(.plain)
            Text(title)
                .font(Theme.Fonts.titleLarge)
                .tracking(-1)
                .foregroundStyle(Theme.Colors.textPrimary)
                .accessibilityAddTraits(.isHeader)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, Theme.Spacing.marginList)
    }
}

/// "001" style case number.
func caseNumber(_ n: Int) -> String {
    n < 10 ? "00\(n)" : n < 100 ? "0\(n)" : "\(n)"
}

// MARK: - 02 · Home

struct HomeView: View {
    let next: CaseFile?
    let resumable: (saved: SavedInvestigation, file: CaseFile)?
    let progress: [String: CaseProgress]
    let attemptsCount: Int
    let onStart: (CaseFile) -> Void
    let onResume: () -> Void
    let onNavigate: (RootView.Stage) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.s6) {
            HStack {
                Logo()
                Spacer()
                Button { onNavigate(.profile) } label: {
                    Circle()
                        .fill(Theme.Colors.bgRaised)
                        .overlay(Circle().strokeBorder(Theme.Colors.line2))
                        .overlay(Image(systemName: "person.fill").font(Theme.Fonts.caption).foregroundStyle(Theme.Colors.textSecondary))
                        .frame(width: Theme.Size.hit, height: Theme.Size.hit)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text(L10n.t("menu.profile")))
            }
            .padding(.top, Theme.Spacing.s5)

            Text(L10n.t("home.tagline"))
                .font(Theme.Fonts.narrative)
                .foregroundStyle(Theme.Colors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, Theme.Spacing.s5)

            Spacer()

            VStack(spacing: 0) {
                menuRow(L10n.t("menu.cases"), value: "\(progress.values.filter(\.solved).count)") { onNavigate(.cases) }
                    .accessibilityIdentifier("menu.cases")
                menuRow(L10n.t("menu.archive"), value: "\(attemptsCount)") { onNavigate(.archive) }
                menuRow(L10n.t("menu.profile"), value: nil) { onNavigate(.profile) }
                menuRow(L10n.t("menu.settings"), value: nil) { onNavigate(.settings) }
            }

            if let resumable {
                resumeCard(resumable.saved, resumable.file)
            } else if let next {
                nextCard(next)
            }
        }
        .padding(.horizontal, Theme.Spacing.marginGame)
        .padding(.bottom, Theme.Spacing.s5)
    }

    private func menuRow(_ title: String, value: String?, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Text(title).font(Theme.Fonts.bodyLarge).foregroundStyle(Theme.Colors.textPrimary)
                Spacer()
                if let value { Text(value).font(Theme.Fonts.data).foregroundStyle(Theme.Colors.textSecondary) }
                Text("›").font(Theme.Fonts.body).foregroundStyle(Theme.Colors.textTertiary)
            }
            .frame(height: 56)
            .contentShape(Rectangle())
            .overlay(alignment: .bottom) { Rectangle().fill(Theme.Colors.line1).frame(height: 1) }
        }
        .buttonStyle(.plain)
    }

    /// "Reprendre": case, time left, pinned items, a 3 pt progress bar (time used), CTA 52.
    private func resumeCard(_ saved: SavedInvestigation, _ file: CaseFile) -> some View {
        let remaining = saved.remainingSeconds
        let used = 1 - remaining / max(1, Double(saved.snapshot.durationSeconds))
        return VStack(alignment: .leading, spacing: Theme.Spacing.s3) {
            CaseCover(file: file, countdown: remaining, highlight: true)
            Text(L10n.f("home.resumeOverline", caseNumber(file.number))).overline(Theme.Colors.signal)
            Text(file.title).font(Theme.Fonts.title).foregroundStyle(Theme.Colors.textPrimary)
            Text(L10n.f("home.resumeMeta", PhoneFormat.countdown(remaining), saved.snapshot.notebook.count))
                .font(Theme.Fonts.data).foregroundStyle(Theme.Colors.textSecondary)
                .accessibilityIdentifier("home.resumeMeta")
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Theme.Colors.line2)
                    Capsule().fill(Theme.Colors.signal).frame(width: geo.size.width * used)
                }
            }
            .frame(height: 3)
            .accessibilityHidden(true)
            Button(L10n.t("home.resume"), action: onResume)
                .buttonStyle(PrimaryButtonStyle(height: Theme.Size.buttonM))
                .accessibilityIdentifier("home.resume")
                .padding(.top, Theme.Spacing.s2)
        }
        .padding(Theme.Spacing.s5)
        .background(RoundedRectangle(cornerRadius: Theme.Radius.lg).fill(Theme.Colors.bgSurface))
        .elevation0(Theme.Radius.lg)
    }

    /// Without a game in progress, the "Reprendre" card becomes "Affaire suivante / Commencer".
    private func nextCard(_ file: CaseFile) -> some View {
        let entry = progress[file.id]
        return VStack(alignment: .leading, spacing: Theme.Spacing.s3) {
            CaseCover(file: file, countdown: Double(file.durationSeconds), highlight: false)
            Text((entry?.plays ?? 0) > 0 ? L10n.f("home.caseOverline", caseNumber(file.number)) : L10n.t("home.nextCase"))
                .overline(Theme.Colors.signal)
            Text(file.title).font(Theme.Fonts.title).foregroundStyle(Theme.Colors.textPrimary)
            Text(file.tagline).font(Theme.Fonts.callout).foregroundStyle(Theme.Colors.textSecondary).lineLimit(2)
            Button(L10n.t("home.start")) { onStart(file) }
                .buttonStyle(PrimaryButtonStyle(height: Theme.Size.buttonM))
                .accessibilityIdentifier("home.start")
                .padding(.top, Theme.Spacing.s2)
        }
        .padding(Theme.Spacing.s5)
        .background(RoundedRectangle(cornerRadius: Theme.Radius.lg).fill(Theme.Colors.bgSurface))
        .elevation0(Theme.Radius.lg)
    }
}

/// Cover of a case: the seized phone's lock screen (wallpaper, the time it was handed over, whose
/// phone), and the time you get to search it.
struct CaseCover: View {
    let file: CaseFile
    let countdown: Double
    /// Resume card: the time left in amber.
    let highlight: Bool
    var height: CGFloat = 150

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous)
        ZStack {
            Wallpaper()
            VStack(spacing: 2) {
                Text(PhoneFormat.longDayCapitalized(file.phoneStartTime))
                    .font(Theme.Fonts.caption)
                    .foregroundStyle(Theme.Colors.textSecondary)
                Text(PhoneFormat.time(file.phoneStartTime))
                    .font(.custom(Theme.FontName.light, fixedSize: 44))
                    .foregroundStyle(Theme.Colors.textPrimary)
                if let label = file.devices.first?.label {
                    Label(label, systemImage: "lock.fill")
                        .font(Theme.Fonts.caption)
                        .foregroundStyle(Theme.Colors.textSecondary)
                }
            }
        }
        .frame(height: height)
        .clipShape(shape)
        .overlay(shape.strokeBorder(Theme.Colors.line2))
        .overlay(alignment: .bottomTrailing) {
            Label(PhoneFormat.countdown(countdown), systemImage: "timer")
                .font(Theme.Fonts.dataStrong)
                .foregroundStyle(highlight ? Theme.Colors.signal : Theme.Colors.textPrimary)
                .padding(.horizontal, Theme.Spacing.s3)
                .frame(height: 28)
                .background(Capsule().fill(Theme.Colors.ink0.opacity(0.7)))
                .padding(Theme.Spacing.s3)
        }
        .accessibilityHidden(true)
    }
}

// MARK: - 03 · Cases

struct CasesView: View {
    let cases: [CaseFile]
    let progress: [String: CaseProgress]
    let onOpen: (CaseFile) -> Void
    let onBack: () -> Void

    enum Filter: Hashable { case all, toPlay, done }
    @State private var filter: Filter = .all

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.s5) {
            MetaHeader(title: L10n.t("menu.cases"), onBack: onBack)
            Segmented(options: [(Filter.all, L10n.t("cases.all")), (.toPlay, L10n.t("cases.toPlay")), (.done, L10n.t("cases.done"))],
                      selection: $filter)
                .padding(.horizontal, Theme.Spacing.marginList)
            ScrollView {
                LazyVStack(spacing: Theme.Spacing.s4) {
                    ForEach(visible) { file in
                        Button { onOpen(file) } label: { CaseCard(file: file, progress: progress[file.id]) }
                            .buttonStyle(.plain)
                            .accessibilityIdentifier("case.\(file.id)")
                    }
                    if visible.isEmpty {
                        EmptyStateView(title: L10n.t("cases.emptyTitle"), message: L10n.t("cases.emptyMessage"))
                    }
                }
                .padding(.horizontal, Theme.Spacing.marginList)
                .padding(.bottom, Theme.Spacing.s8)
            }
        }
        .padding(.top, Theme.Spacing.s3)
    }

    private var visible: [CaseFile] {
        cases.filter { file in
            let solved = progress[file.id]?.solved == true
            switch filter {
            case .all: return true
            case .toPlay: return !solved
            case .done: return solved
            }
        }
    }
}

/// CaseCard: available · played · solved (✓ n %) · perfect (◆ PARFAITE). r 20, pad 18.
struct CaseCard: View {
    let file: CaseFile
    let progress: CaseProgress?

    var body: some View {
        let solved = progress?.solved == true
        let perfect = (progress?.bestScore ?? 0) >= 100
        VStack(alignment: .leading, spacing: Theme.Spacing.s3) {
            CaseCover(file: file, countdown: Double(file.durationSeconds), highlight: false, height: 120)
            HStack {
                Text(L10n.f("home.caseOverline", caseNumber(file.number))).overline(Theme.Colors.signal)
                Spacer()
                if perfect {
                    Text(L10n.t("cases.perfect"))
                        .font(Theme.Fonts.dataSmall).foregroundStyle(Theme.Colors.textOnLight)
                        .padding(.horizontal, Theme.Spacing.s3).frame(height: 22)
                        .background(Capsule().fill(Theme.Colors.signal))
                } else if solved, let progress {
                    Text("✓ \(progress.bestScore) %")
                        .font(Theme.Fonts.dataSmall).foregroundStyle(Theme.Colors.clear)
                        .padding(.horizontal, Theme.Spacing.s3).frame(height: 22)
                        .overlay(Capsule().strokeBorder(Theme.Colors.clear.opacity(0.5)))
                }
            }
            Text(file.title).font(Theme.Fonts.title).foregroundStyle(Theme.Colors.textPrimary)
            Text(file.tagline).font(Theme.Fonts.callout).foregroundStyle(Theme.Colors.textSecondary)
            HStack(spacing: Theme.Spacing.s4) {
                Text(PhoneFormat.countdown(Double(file.durationSeconds)))
                Text(L10n.f("cases.suspects", file.suspects.count))
                Text(String(repeating: "●", count: file.difficulty) + String(repeating: "○", count: max(0, 3 - file.difficulty)))
                    .accessibilityLabel(Text(L10n.f("cases.difficulty", file.difficulty)))
                if let plays = progress?.plays, plays > 0 { Text(L10n.f("cases.plays", plays)) }
            }
            .font(Theme.Fonts.data)
            .foregroundStyle(Theme.Colors.textTertiary)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: Theme.Radius.lg + 3, style: .continuous).fill(Theme.Colors.bgSurface))
        .elevation0(Theme.Radius.lg + 3)
        .accessibilityElement(children: .combine)
    }
}

// MARK: - 04 · Intro

/// ink.0 background; overline, display title, serif sentences fading in one by one (a tap shows all),
/// suspects, whose phone and when, the duration in mono; the CTA is active right away.
struct CaseIntroView: View {
    let caseFile: CaseFile
    let onStart: () -> Void
    let onClose: () -> Void
    @State private var shownLines = 0

    var body: some View {
        let lines = caseFile.synopsis
        VStack(alignment: .leading, spacing: Theme.Spacing.s5) {
            Button(action: onClose) {
                Image(systemName: "xmark").font(Theme.Fonts.headline).foregroundStyle(Theme.Colors.textSecondary)
                    .frame(width: Theme.Size.hit, height: Theme.Size.hit)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text(L10n.t("a11y.close")))

            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.s5) {
                    Text(L10n.f("home.caseOverline", caseNumber(caseFile.number))).overline(Theme.Colors.signal)
                    Text(caseFile.title).font(Theme.Fonts.display).tracking(-1.4).foregroundStyle(Theme.Colors.textPrimary)
                    ForEach(Array(lines.enumerated()), id: \.offset) { index, line in
                        Text(line)
                            .font(Theme.Fonts.narrative)
                            .foregroundStyle(Theme.Colors.textPrimary)
                            .opacity(index < shownLines ? 1 : 0)
                    }
                    Text(caseFile.objective)
                        .font(Theme.Fonts.callout)
                        .foregroundStyle(Theme.Colors.signal)
                        .opacity(shownLines >= lines.count ? 1 : 0)
                }
            }

            VStack(alignment: .leading, spacing: Theme.Spacing.s2) {
                suspects
                if let device = caseFile.devices.first {
                    Text(L10n.f("intro.handedOver", device.label, PhoneFormat.dayAndTime(caseFile.phoneStartTime)))
                        .font(Theme.Fonts.caption).foregroundStyle(Theme.Colors.textSecondary)
                }
                Text(PhoneFormat.countdown(Double(caseFile.durationSeconds)))
                    .font(Theme.Fonts.timerIntro)
                    .foregroundStyle(Theme.Colors.textPrimary)
                    .accessibilityLabel(Text(L10n.f("a11y.duration", caseFile.durationSeconds / 60)))
            }
            Button(L10n.t("intro.start"), action: onStart)
                .accessibilityIdentifier("intro.start")
                .buttonStyle(PrimaryButtonStyle())
        }
        .padding(.horizontal, Theme.Spacing.marginGame)
        .padding(.bottom, Theme.Spacing.s5)
        .contentShape(Rectangle())
        .onTapGesture { shownLines = lines.count }
        .task {
            for index in 1...max(1, lines.count) {
                try? await Task.sleep(for: .seconds(Theme.Motion.introGap))
                withAnimation(Theme.Motion.emphasized(Theme.Motion.introLine)) { shownLines = max(shownLines, index) }
            }
        }
    }

    private var suspects: some View {
        let contacts = caseFile.devices.first?.contacts ?? []
        return HStack(spacing: -10) {
            ForEach(caseFile.suspects) { suspect in
                Avatar(contact: contacts.first { $0.id == suspect.contact }, size: Theme.Size.avatarS)
                    .overlay(Circle().strokeBorder(Theme.Colors.ink0, lineWidth: 2))
            }
            Text(L10n.f("cases.suspects", caseFile.suspects.count))
                .font(Theme.Fonts.data)
                .foregroundStyle(Theme.Colors.textSecondary)
                .padding(.leading, Theme.Spacing.s5)
        }
        .padding(.bottom, Theme.Spacing.s2)
        .accessibilityElement(children: .combine)
    }
}

// MARK: - 05 · Archive

struct ArchiveView: View {
    let cases: [CaseFile]
    let attempts: [Attempt]
    let progress: [String: CaseProgress]
    let onOpen: (CaseFile, Attempt) -> Void
    let onBack: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.s5) {
            MetaHeader(title: L10n.t("menu.archive"), onBack: onBack)
            if attempts.isEmpty {
                EmptyStateView(title: L10n.t("archive.emptyTitle"), message: L10n.t("archive.emptyMessage"))
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        ForEach(attempts.reversed()) { attempt in
                            row(attempt)
                        }
                    }
                    .padding(.horizontal, Theme.Spacing.marginList)
                }
            }
        }
        .padding(.top, Theme.Spacing.s3)
    }

    private func row(_ attempt: Attempt) -> some View {
        let file = cases.first { $0.id == attempt.caseID }
        let canOpen = file != nil && progress[attempt.caseID]?.archiveOpen == true
        return Button {
            if let file, canOpen { onOpen(file, attempt) }
        } label: {
            HStack(spacing: Theme.Spacing.s4) {
                Text(attempt.solved ? "✓" : "✕")
                    .font(Theme.Fonts.dataStrong)
                    .foregroundStyle(attempt.solved ? Theme.Colors.clear : Theme.Colors.alertText)
                    .frame(width: 20)
                VStack(alignment: .leading, spacing: 2) {
                    Text(file?.title ?? attempt.caseID).font(Theme.Fonts.headline).foregroundStyle(Theme.Colors.textPrimary)
                    Text(attempt.date.formatted(date: .abbreviated, time: .shortened))
                        .font(Theme.Fonts.dataSmall).foregroundStyle(Theme.Colors.textTertiary)
                }
                Spacer()
                Text(attempt.ranked ? "\(attempt.score) %" : L10n.t("archive.unranked"))
                    .font(Theme.Fonts.dataStrong)
                    .foregroundStyle(attempt.ranked ? Theme.Colors.textPrimary : Theme.Colors.textTertiary)
                if canOpen { Text("›").foregroundStyle(Theme.Colors.textTertiary) }
            }
            .frame(minHeight: 62)
            .contentShape(Rectangle())
            .overlay(alignment: .bottom) { Rectangle().fill(Theme.Colors.line1).frame(height: 1) }
        }
        .buttonStyle(.plain)
        .disabled(!canOpen)
        .accessibilityElement(children: .combine)
    }
}

/// The reconstruction of a solved (or revealed) case, read-only.
struct ArchivedCaseView: View {
    let caseFile: CaseFile
    let attempt: Attempt
    let onClose: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button(action: onClose) {
                Text("‹ " + L10n.t("menu.archive")).font(Theme.Fonts.callout).foregroundStyle(Theme.Colors.textSecondary)
                    .frame(minHeight: Theme.Size.hit)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, Theme.Spacing.marginGame)
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.s5) {
                    Text(L10n.f("home.caseOverline", caseNumber(caseFile.number))).overline(Theme.Colors.signal)
                    Text(caseFile.solution.headline).font(Theme.Fonts.title2).tracking(-0.8).foregroundStyle(Theme.Colors.textPrimary)
                    Text(caseFile.solution.summary).font(Theme.Fonts.narrativeSmall).foregroundStyle(Theme.Colors.textSecondary)
                    RevealTimeline(steps: caseFile.solution.reveal, found: Set(caseFile.solution.reveal.compactMap(\.evidence)), shown: caseFile.solution.reveal.count)
                    ForEach(Array(caseFile.solution.story.enumerated()), id: \.offset) { _, paragraph in
                        Text(paragraph).font(Theme.Fonts.body).foregroundStyle(Theme.Colors.textPrimary)
                    }
                }
                .padding(.horizontal, Theme.Spacing.marginGame)
                .padding(.bottom, Theme.Spacing.s8)
            }
        }
    }
}

// MARK: - 06 · Profile

struct ProfileView: View {
    let attempts: [Attempt]
    let caseCount: Int
    let onBack: () -> Void

    var body: some View {
        let summary = ProgressStore.summary(of: attempts)
        let solved = summary.values.filter(\.solved).count
        let ranked = attempts.filter(\.ranked)
        let best = ranked.map(\.score).max() ?? 0
        let found = attempts.reduce(0) { $0 + $1.found }
        let total = attempts.reduce(0) { $0 + $1.total }
        let rank = min(solved, 4)
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.s6) {
                MetaHeader(title: L10n.t("menu.profile"), onBack: onBack)
                VStack(alignment: .leading, spacing: Theme.Spacing.s3) {
                    Text(L10n.t("profile.rank")).overline(Theme.Colors.signal)
                    Text(L10n.t("profile.rank\(rank)")).font(Theme.Fonts.title2).foregroundStyle(Theme.Colors.textPrimary)
                    HStack(spacing: Theme.Spacing.s2) {
                        ForEach(0..<4, id: \.self) { step in
                            Capsule().fill(step < rank ? Theme.Colors.signal : Theme.Colors.line2).frame(height: 4)
                        }
                    }
                    Text(rank < 4 ? L10n.t("profile.rankNext") : L10n.t("profile.rankMax"))
                        .font(Theme.Fonts.caption).foregroundStyle(Theme.Colors.textSecondary)
                }
                .padding(Theme.Spacing.s5)
                .background(RoundedRectangle(cornerRadius: Theme.Radius.lg).fill(Theme.Colors.bgSurface))
                .elevation0(Theme.Radius.lg)
                .padding(.horizontal, Theme.Spacing.marginList)
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible())], spacing: 10) {
                    StatCard(label: L10n.t("profile.solved"), value: "\(solved)/\(caseCount)")
                    StatCard(label: L10n.t("profile.attempts"), value: "\(attempts.count)")
                    StatCard(label: L10n.t("profile.best"), value: ranked.isEmpty ? "—" : "\(best) %")
                    StatCard(label: L10n.t("profile.found"), value: total == 0 ? "—" : "\(found * 100 / total) %")
                }
                .padding(.horizontal, Theme.Spacing.marginList)
                VStack(alignment: .leading, spacing: Theme.Spacing.s3) {
                    Text(L10n.t("profile.badges")).overline()
                    badge("checkmark.seal.fill", L10n.t("profile.badgeFirst"), earned: solved > 0)
                    badge("bolt.fill", L10n.t("profile.badgeNoHelp"), earned: attempts.contains { $0.solved && $0.ranked && $0.hintsUsed == 0 })
                    badge("rosette", L10n.t("profile.badgePerfect"), earned: attempts.contains { $0.ranked && $0.score >= 100 })
                    badge("magnifyingglass", L10n.t("profile.badgeThorough"), earned: attempts.contains { $0.total > 0 && $0.found == $0.total })
                }
                .padding(.horizontal, Theme.Spacing.marginList)
            }
            .padding(.bottom, Theme.Spacing.s8)
        }
        .padding(.top, Theme.Spacing.s3)
    }
}

extension ProfileView {
    /// A distinction: lit when earned, dimmed (with its condition) otherwise.
    func badge(_ symbol: String, _ title: String, earned: Bool) -> some View {
        HStack(spacing: Theme.Spacing.s4) {
            Image(systemName: symbol)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(earned ? Theme.Colors.textOnLight : Theme.Colors.textTertiary)
                .frame(width: 36, height: 36)
                .background(Circle().fill(earned ? Theme.Colors.signal : Theme.Colors.bgRaised))
            Text(title).font(Theme.Fonts.body).foregroundStyle(earned ? Theme.Colors.textPrimary : Theme.Colors.textTertiary)
            Spacer()
            if earned { Image(systemName: "checkmark").foregroundStyle(Theme.Colors.clear) }
        }
        .padding(Theme.Spacing.s3)
        .background(RoundedRectangle(cornerRadius: Theme.Radius.md).fill(Theme.Colors.bgSurface))
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(earned ? .isSelected : [])
    }
}

struct StatCard: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.s3) {
            Text(label).overline()
            Text(value).font(Theme.Fonts.timerIntro).foregroundStyle(Theme.Colors.textPrimary)
        }
        .padding(Theme.Spacing.s5)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: Theme.Radius.lg).fill(Theme.Colors.bgSurface))
        .elevation0(Theme.Radius.lg)
        .accessibilityElement(children: .combine)
    }
}

// MARK: - 07 · Settings

struct GameSettingsView: View {
    let onBack: () -> Void
    let onReplayOnboarding: () -> Void
    @AppStorage(Preferences.vibrationsKey) private var vibrations = true
    @AppStorage(Preferences.reduceMotionKey) private var reduceMotion = false

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.s6) {
            MetaHeader(title: L10n.t("menu.settings"), onBack: onBack)
            group(L10n.t("settings.soundGroup")) {
                Toggle(L10n.t("settings.vibrations"), isOn: $vibrations)
            }
            group(L10n.t("settings.accessibilityGroup")) {
                Toggle(L10n.t("settings.reduceMotion"), isOn: $reduceMotion)
            }
            group(L10n.t("settings.helpGroup")) {
                Button(action: onReplayOnboarding) {
                    HStack {
                        Text(L10n.t("settings.replayOnboarding"))
                        Spacer()
                        Text("›").foregroundStyle(Theme.Colors.textTertiary)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("settings.replayOnboarding")
            }
            Spacer()
        }
        .padding(.top, Theme.Spacing.s3)
    }

    private func group<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.s3) {
            Text(title).overline()
            content()
                .font(Theme.Fonts.body)
                .foregroundStyle(Theme.Colors.textPrimary)
                .tint(Theme.Colors.clear)
                .padding(.horizontal, Theme.Spacing.s5)
                .frame(minHeight: 56)
                .background(RoundedRectangle(cornerRadius: Theme.Radius.md).fill(Theme.Colors.bgSurface))
        }
        .padding(.horizontal, Theme.Spacing.marginList)
    }
}
#endif
