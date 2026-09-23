#if os(iOS)
import SwiftUI
import CaseEngine
import CaseLibrary

/// Title → briefing → investigation (phone) → accusation → result.
public struct RootView: View {
    private enum Stage {
        case title
        case briefing(CaseFile)
        case playing(GameSession)
        case result(Verdict, GameSession)
    }

    @State private var stage: Stage = .title
    @State private var progress = ProgressStore.all()
    private let cases: [CaseFile]
    private let rules: GameRules?
    private let loadError: String?

    public init() {
        do {
            cases = try CaseLibrary.loadCases()
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
            Theme.Colors.background.ignoresSafeArea()
            content
        }
        .preferredColorScheme(.dark)
        .animation(Theme.Motion.spring, value: stageKey)
    }

    @ViewBuilder
    private var content: some View {
        if let loadError {
            Text(loadError)
                .font(Theme.Fonts.footnote)
                .foregroundStyle(Theme.Colors.alert)
                .padding()
        } else {
            switch stage {
            case .title:
                TitleView(cases: cases, progress: progress) { stage = .briefing($0) }
                    .transition(.opacity)
            case .briefing(let file):
                BriefingView(file: file, rules: rules!, onStart: { start(file) }, onBack: { stage = .title })
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            case .playing(let session):
                PlayingView(session: session)
                    .transition(.opacity)
            case .result(let verdict, let session):
                ResultView(verdict: verdict, session: session,
                           onReplay: { stage = .briefing(session.caseFile) },
                           onExit: { progress = ProgressStore.all(); stage = .title })
                    .transition(.opacity)
            }
        }
    }

    private var stageKey: String {
        switch stage {
        case .title: "title"
        case .briefing(let f): "briefing-\(f.id)"
        case .playing: "playing"
        case .result: "result"
        }
    }

    private func start(_ file: CaseFile) {
        guard let rules else { return }
        let session = GameSession(caseFile: file, rules: rules) { verdict in
            ProgressStore.record(caseID: file.id, solved: verdict.isCorrect, score: verdict.score)
            if case .playing(let current) = stage { stage = .result(verdict, current) }
        }
        session.begin()
        stage = .playing(session)
    }
}

/// Switches between the phone and the accusation screen as the phase changes.
struct PlayingView: View {
    let session: GameSession

    var body: some View {
        if session.phase == .investigating {
            InvestigationView(session: session)
                .transition(.opacity)
        } else {
            AccusationView(session: session)
                .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }
}
#endif
