#if os(iOS)
import SwiftUI
import CaseEngine
import CaseLibrary

/// Home → Affaires → Intro → investigation (phone) → time up / accusation → result → score.
public struct RootView: View {
    enum Stage {
        case home
        case cases
        case archive
        case profile
        case settings
        case intro(CaseFile)
        case playing(GameSession)
        case result(Play)
        case score(Play)
        case archived(CaseFile, Attempt)
    }

    /// A finished investigation on its way through the result screens.
    struct Play {
        let session: GameSession
        let verdict: Verdict
        let attemptID: UUID
        var revealed = false
    }

    @State private var stage: Stage = .home
    @State private var attempts = ProgressStore.attempts()
    @AppStorage(Preferences.reduceMotionKey) private var reduceMotion = false
    private let cases: [CaseFile]
    private let rules: GameRules?
    private let loadError: String?

    public init() {
        AppFonts.register()
        do {
            cases = try CaseLibrary.loadCases().sorted { $0.number < $1.number }
            rules = try CaseLibrary.loadRules()
            loadError = nil
        } catch {
            cases = []
            rules = nil
            loadError = String(describing: error)
        }
    }

    public var body: some View {
        ZStack {
            Theme.Colors.ink0.ignoresSafeArea()
            content
        }
        .preferredColorScheme(.dark)
        .animation(reduceMotion ? nil : Theme.Motion.emphasized(), value: stageKey)
        .transaction { if reduceMotion { $0.animation = nil } }
    }

    @ViewBuilder
    private var content: some View {
        if let loadError {
            VStack(alignment: .leading, spacing: Theme.Spacing.s3) {
                Text(L10n.t("error.damaged")).overline(Theme.Colors.alertText)
                Text(loadError).font(Theme.Fonts.data).foregroundStyle(Theme.Colors.textSecondary)
            }
            .padding(Theme.Spacing.marginGame)
        } else {
            switch stage {
            case .home:
                HomeView(next: nextCase, progress: progress, attemptsCount: attempts.count,
                         onStart: { stage = .intro($0) },
                         onNavigate: { stage = $0 })
                    .transition(.opacity)
            case .cases:
                CasesView(cases: cases, progress: progress, onOpen: { stage = .intro($0) }, onBack: goHome)
                    .transition(.move(edge: .trailing))
            case .archive:
                ArchiveView(cases: cases, attempts: attempts, progress: progress,
                            onOpen: { file, attempt in stage = .archived(file, attempt) }, onBack: goHome)
                    .transition(.move(edge: .trailing))
            case .profile:
                ProfileView(attempts: attempts, caseCount: cases.count, onBack: goHome)
                    .transition(.move(edge: .trailing))
            case .settings:
                GameSettingsView(onBack: goHome)
                    .transition(.move(edge: .trailing))
            case .intro(let file):
                CaseIntroView(caseFile: file, onStart: { start(file) }, onClose: goHome)
                    .transition(.opacity)
            case .playing(let session):
                PlayingView(session: session)
                    .transition(.opacity)
            case .result(let play):
                ResultView(verdict: play.verdict, caseFile: play.session.caseFile, names: names(play.session),
                           onScore: { stage = .score(play) },
                           onReplay: { start(play.session.caseFile) },
                           onRevealRequested: { reveal(play) },
                           revealed: play.revealed)
                    .id(play.revealed)
                    .transition(.opacity)
            case .score(let play):
                ScoreView(verdict: play.verdict, duration: play.session.caseFile.durationSeconds,
                          onReplay: { start(play.session.caseFile) },
                          onNext: { stage = nextCase(after: play.session.caseFile).map { .intro($0) } ?? .cases })
                    .transition(.opacity)
            case .archived(let file, let attempt):
                ArchivedCaseView(caseFile: file, attempt: attempt, onClose: { stage = .archive })
                    .transition(.move(edge: .trailing))
            }
        }
    }

    private var progress: [String: CaseProgress] { ProgressStore.summary(of: attempts) }

    /// The first case not solved yet (or the last one).
    private var nextCase: CaseFile? {
        cases.first { progress[$0.id]?.solved != true } ?? cases.last
    }

    private func nextCase(after file: CaseFile) -> CaseFile? {
        cases.first { $0.number > file.number }
    }

    private var stageKey: String {
        switch stage {
        case .home: "home"
        case .cases: "cases"
        case .archive: "archive"
        case .profile: "profile"
        case .settings: "settings"
        case .intro(let f): "intro-\(f.id)"
        case .playing: "playing"
        case .result(let p): "result-\(p.revealed)"
        case .score: "score"
        case .archived(_, let a): "archived-\(a.id)"
        }
    }

    private func goHome() {
        attempts = ProgressStore.attempts()
        stage = .home
    }

    private func names(_ session: GameSession) -> [SuspectID: String] {
        Dictionary(uniqueKeysWithValues: session.caseFile.suspects.map { ($0.id, session.game.name(of: $0.contact)) })
    }

    private func start(_ file: CaseFile) {
        guard let rules else { return }
        let session = GameSession(caseFile: file, rules: rules) { verdict in
            guard case .playing(let session) = stage else { return }
            let attempt = Attempt(caseID: file.id, date: .now, score: verdict.score, solved: verdict.isCorrect,
                                  ranked: true, found: verdict.foundCount, total: verdict.totalCount,
                                  hintsUsed: verdict.hintsUsed)
            ProgressStore.record(attempt)
            attempts = ProgressStore.attempts()
            stage = .result(Play(session: session, verdict: verdict, attemptID: attempt.id))
        }
        session.begin()
        stage = .playing(session)
    }

    /// "Révéler la solution" after a wrong answer: the attempt becomes unranked.
    private func reveal(_ play: Play) {
        ProgressStore.markRevealed(play.attemptID)
        attempts = ProgressStore.attempts()
        var revealed = play
        revealed.revealed = true
        stage = .result(revealed)
    }
}

/// Phone while investigating; "temps écoulé" when the timer hits zero; then the accusation.
struct PlayingView: View {
    let session: GameSession
    @State private var timeUpShown = false

    var body: some View {
        if session.phase == .investigating {
            InvestigationView(session: session)
                .transition(.opacity)
        } else if session.remainingSeconds <= 0 && !timeUpShown {
            TimeUpView { timeUpShown = true }
                .transition(.opacity)
        } else {
            AccusationView(session: session)
                .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }
}
#endif
