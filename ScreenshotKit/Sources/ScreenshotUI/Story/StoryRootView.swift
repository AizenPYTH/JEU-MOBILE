#if os(iOS)
import SwiftUI
import StoryEngine

/// The story mode (HISTOIRE): routes between the hub, the creator, the scenes, the new file, the
/// chapter's result, the office and the consultation screens (docs/design_story/STORY_UX_FLOW.md),
/// all laid on the V4 desk (docs/design_v4) — no 3D.
/// The phone itself is played by `GameRoot` (the story's cases have their own save slot).
struct StoryRootView: View {
    let story: StoryCoordinator
    /// Title, file label (« N° 001 », « N° C02-A ») and chapter number of a story case.
    let caseInfo: (String) -> (title: String, label: String, chapter: Int)?
    let onExit: () -> Void
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    @AppStorage(Preferences.reduceMotionKey) private var appReduceMotion = false

    private var push: AnyTransition {
        systemReduceMotion || appReduceMotion ? .opacity : .opacity.combined(with: .offset(x: 24))
    }

    var body: some View {
        ZStack {
            ModeBackdrop()
            content
        }
        .animation(systemReduceMotion || appReduceMotion ? .easeInOut(duration: 0.2) : Trace.StoryMotion.paper, value: screenKey)
        .onAppear { story.load() }
    }

    @ViewBuilder
    private var content: some View {
        switch story.screen {
        case .hub:
            if story.hasInvestigator || story.loadError != nil {
                StoryHubView(story: story,
                             onBack: onExit,
                             onContinue: { story.continueStory() },
                             onProfile: { story.screen = .profile },
                             onCareer: { story.screen = .career },
                             onOffice: { story.screen = .office(focus: nil) },
                             onSettings: { story.screen = .settings },
                             onChapter: { story.screen = .chapter($0) })
                    .transition(.opacity)
            } else {
                // P1: the first time, the creator.
                CharacterCreatorView(story: story, onClose: onExit)
                    .transition(.opacity)
            }
        case .creator:
            CharacterCreatorView(story: story, onClose: { story.screen = .hub })
                .transition(push)
        case .scene:
            StoryScenePlayer(story: story)
                .transition(.opacity)
        case .caseFolder(let id):
            let info = caseInfo(id)
            StoryCaseFolderView(story: story, caseID: id, caseTitle: info?.title ?? "", label: info?.label ?? "",
                                chapterNumber: info?.chapter ?? story.currentChapter?.number ?? 1,
                                onOpen: { story.openCaseFolder(id) })
                .transition(.opacity)
        case .phone:
            Trace.Story.sceneVoid.ignoresSafeArea().accessibilityHidden(true)
        case .result:
            if case .result(let result) = story.mode {
                StoryResultFlow(story: story, result: result,
                                onDone: { story.finishResult() },
                                onOffice: { story.finishResult(officeFocus: $0) })
                    .transition(.opacity)
            } else {
                Trace.Story.sceneVoid.ignoresSafeArea().accessibilityHidden(true).onAppear { story.screen = .hub }
            }
        case .office(let focus):
            StoryOfficeView(story: story, focusUnlock: focus, onBack: { story.closeOffice() })
                .transition(.opacity)
        case .profile:
            StoryProfileView(story: story, onBack: { story.screen = .hub })
                .transition(push)
        case .career:
            StoryCareerView(story: story, onBack: { story.screen = .hub })
                .transition(push)
        case .chapter(let id):
            StoryChapterView(story: story, chapterID: id, onBack: { story.screen = .hub },
                             onContinue: { story.continueStory() })
                .transition(push)
        case .settings:
            StorySettingsView(story: story, onBack: { story.screen = .hub },
                              onReplay: { story.replay($0) })
                .transition(push)
        }
    }

    private var screenKey: String {
        switch story.screen {
        case .hub: "hub"
        case .creator: "creator"
        case .scene: "scene"
        case .caseFolder(let id): "folder-\(id)"
        case .phone: "phone"
        case .result: "result"
        case .office: "office"
        case .profile: "profile"
        case .career: "career"
        case .chapter(let id): "chapter-\(id)"
        case .settings: "settings"
        }
    }
}
#endif
