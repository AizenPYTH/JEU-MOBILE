#if os(iOS)
import SwiftUI
import StoryEngine

/// h09 · « Mon bureau »: the player's office in 3D, a fixed WIDE 3/4 shot from above
/// (cam_po_wide); 3 to 6 points by level. A point frames its object (450 ms), then its sheet.
/// New objects wear a ben ring until they are opened. Overlay controls in the UX V3 look (flat,
/// legible on the scene); the 3D office itself is unchanged.
struct StoryOfficeView: View {
    let story: StoryCoordinator
    /// A prop to frame at once (from h18 « Voir dans mon bureau »), by the unlock it needs.
    var focusUnlock: String?
    let onBack: () -> Void

    @State private var points: [String: CGPoint] = [:]
    @State private var focused: String?
    @State private var sheetOpen = false
    @State private var fading = false
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    @AppStorage(Preferences.reduceMotionKey) private var appReduceMotion = false

    private var reduceMotion: Bool { systemReduceMotion || appReduceMotion }
    private var location: StoryLocation? { story.content?.location("ENV_BEN_OFFICE_PLAYER") }
    private var unlocks: Set<String> { story.save?.unlocks ?? [] }

    /// The points of this level (visible props with a hotspot).
    private var hotspots: [StageProp] {
        (location?.props(unlocked: unlocks, level: story.officeLevel) ?? []).filter { $0.hotspot != nil && $0.hidden != true }
    }

    private var stage: StageState {
        var s = StageState()
        s.location = "ENV_BEN_OFFICE_PLAYER"
        if let id = focused, let prop = location?.prop(id), let camera = prop.hotspot?.camera {
            s.shot = CameraShot(kind: .focusObject, camera: camera, prop: prop.id)
        } else {
            s.shot = CameraShot(kind: .wide, camera: "cam_po_wide")
        }
        return s
    }

    var body: some View {
        ZStack {
            Trace.Story.sceneVoid.ignoresSafeArea()
            if let content = story.content, let player = story.player {
                StoryStageView(snapshot: StageSnapshot(stage: stage, location: location, content: content, player: player,
                                                       rank: story.save?.rank ?? .enqueteur, unlocks: unlocks,
                                                       officeLevel: story.officeLevel, text: { story.resolve($0) },
                                                       reduceMotion: true,
                                                       project: focused == nil ? hotspots.map(\.id) : []),
                               onProject: { found in points = found })
                    .ignoresSafeArea()
                    .accessibilityHidden(true)
            }
            // T-UI-4: a short fade between the wide shot and the object.
            Color.black.opacity(fading ? 1 : 0).ignoresSafeArea().allowsHitTesting(false)
            if focused == nil {
                ForEach(hotspots) { prop in
                    if let point = points[prop.id], let spot = prop.hotspot {
                        HotspotDot(label: story.resolve(spot.label), isNew: !(story.save?.seenHotspots.contains(prop.id) ?? true)) {
                            open(prop.id)
                        }
                        .position(point)
                        .accessibilityIdentifier("story.office.hotspot.\(prop.id)")
                    }
                }
            }
            VStack {
                HStack {
                    BackChevron(label: focused == nil ? L10n.t("story.nav.hub") : L10n.t("story.office.title")) {
                        if focused != nil { close() } else { onBack() }
                    }
                    .padding(.horizontal, 10)
                    .background(Capsule().fill(Trace.Story.hud))
                    .accessibilityIdentifier("story.office.back")
                    Spacer()
                    Text(L10n.f("story.office.levelTag", story.officeLevel))
                        .font(Trace.Fonts.data)
                        .foregroundStyle(Trace.Colors.text2)
                        .padding(.horizontal, 10)
                        .frame(minHeight: Trace.Height.badge)
                        .background(Capsule().fill(Trace.Story.hud))
                        .accessibilityLabel(Text(L10n.f("story.office.level", story.officeLevel)))
                }
                .padding(.horizontal, 12)
                .padding(.top, 4)
                Spacer()
                if focused == nil { summary }
            }
        }
        .sheet(isPresented: $sheetOpen, onDismiss: close) {
            if let id = focused, let prop = location?.prop(id), let spot = prop.hotspot {
                HotspotSheet(name: story.resolve(spot.name), provenance: spot.provenance.map { story.resolve($0) },
                             label: story.resolve(spot.label))
                    .presentationDetents([.height(230)])
                    .presentationCornerRadius(Trace.Radius.sheet)
                    .presentationBackground(Trace.Colors.surface)
                    .presentationDragIndicator(.visible)
            }
        }
        // A container's identifier must not replace its buttons' identifiers.
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("story.office.view")
        .onAppear {
            guard let focusUnlock, let prop = hotspots.first(where: { $0.requires == focusUnlock }) else { return }
            open(prop.id)
        }
    }

    // MARK: Sheet « Mon bureau · NIVEAU n / 4 »

    private var summary: some View {
        let level = story.officeLevel
        let rewards = (story.content?.campaign.chapters.flatMap(\.steps).compactMap(\.reward).flatMap { $0.items ?? [] } ?? [])
            .filter { unlocks.contains($0.id) }.count
        return VStack(alignment: .leading, spacing: 10) {
            StoryLabel(text: L10n.f("story.office.sheet", level), color: Trace.Colors.text2)
            if let next = nextAddition {
                Text(next)
                    .font(Trace.StoryFonts.body)
                    .foregroundStyle(Trace.Colors.text2)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                Text(L10n.t("story.office.complete"))
                    .font(Trace.StoryFonts.body)
                    .foregroundStyle(Trace.Colors.text2)
            }
            HStack(spacing: 8) {
                chip(L10n.f("story.office.objects", hotspots.count))
                chip(L10n.f("story.office.rewards", rewards))
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .benCard()
        .padding(.horizontal, 16)
        .padding(.bottom, 12)
        .accessibilityElement(children: .combine)
    }

    /// The next level's condition (the rank that brings it).
    private var nextAddition: String? {
        guard let content = story.content, let save = story.save, let tier = content.campaign.tier(after: save.rank) else { return nil }
        let rank = story.rankTitle(tier.rank)
        if let chapter = tier.chapter {
            return L10n.f("story.office.next", story.officeLevel + 1, rank, tier.cases, dossierNumber(chapter))
        }
        return L10n.f("story.office.nextCases", story.officeLevel + 1, rank, tier.cases)
    }

    private func chip(_ text: String) -> some View {
        Text(text)
            .font(Trace.Fonts.caption)
            .foregroundStyle(Trace.Colors.text2)
            .padding(.horizontal, 10)
            .frame(minHeight: Trace.Height.badge)
            .background(Capsule().fill(Trace.Colors.surface2))
    }

    // MARK: Actions

    private func open(_ id: String) {
        story.markHotspotSeen(id)
        Haptics.light()
        if reduceMotion {
            focused = id
            sheetOpen = true
            return
        }
        withAnimation(.easeIn(duration: 0.2)) { fading = true }
        Task {
            try? await Task.sleep(for: .milliseconds(220))
            focused = id
            withAnimation(.easeOut(duration: 0.25)) { fading = false }
            try? await Task.sleep(for: .milliseconds(300))
            sheetOpen = true
        }
    }

    private func close() {
        sheetOpen = false
        guard focused != nil else { return }
        if reduceMotion { focused = nil; return }
        withAnimation(.easeIn(duration: 0.2)) { fading = true }
        Task {
            try? await Task.sleep(for: .milliseconds(220))
            focused = nil
            withAnimation(.easeOut(duration: 0.25)) { fading = false }
        }
    }
}

/// HotspotDot: 12 pt light point, 5 pt halo at 18 %, a Plex Sans 12/600 label on a dark tag;
/// 44 pt target; a 2 pt ben ring until first opened.
private struct HotspotDot: View {
    let label: String
    let isNew: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                ZStack {
                    Circle().fill(Trace.Story.dialogue.opacity(0.18)).frame(width: 22, height: 22)
                    Circle().fill(Trace.Story.dialogue).frame(width: 12, height: 12)
                    if isNew {
                        Circle().strokeBorder(Trace.Colors.ben, lineWidth: 2).frame(width: 22, height: 22)
                    }
                }
                Text(label)
                    .font(Trace.StoryFonts.label)
                    .foregroundStyle(Trace.Story.dialogue)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(RoundedRectangle(cornerRadius: 6, style: .continuous).fill(Trace.Story.hotspotLabel))
            }
            .frame(minWidth: 44, minHeight: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(isNew ? L10n.f("story.office.newObject", label) : label))
    }
}

/// The object's sheet: name, provenance.
private struct HotspotSheet: View {
    let name: String
    let provenance: String?
    let label: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            StoryLabel(text: label, color: Trace.Colors.text2)
            Text(name)
                .font(Trace.StoryFonts.h2)
                .foregroundStyle(Trace.Colors.text)
                .fixedSize(horizontal: false, vertical: true)
            if let provenance {
                Text(provenance)
                    .font(Trace.StoryFonts.caption)
                    .foregroundStyle(Trace.Colors.text2)
            }
            Spacer(minLength: 0)
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("story.office.sheet")
    }
}
#endif
