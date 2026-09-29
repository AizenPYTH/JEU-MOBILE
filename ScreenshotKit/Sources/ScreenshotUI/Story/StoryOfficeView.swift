#if os(iOS)
import SwiftUI
import StoryEngine

/// h09 · « Mon bureau », seen from above: the desk under the lamp, a leather pad, and on it the
/// objects of the current level (and the rewards of the career) laid as paper cards — the BEN
/// card, the folders, the telephone, the computer… — each with a pin (red while it has never been
/// opened). A tap opens its sheet (name, provenance). The summary « Mon bureau · Niveau n / 4 »
/// below. No 3D (owner's decision).
struct StoryOfficeView: View {
    let story: StoryCoordinator
    /// An object to open at once (from h18 « Voir dans mon bureau »), by the unlock it needs.
    var focusUnlock: String?
    let onBack: () -> Void

    @State private var opened: OfficeObject?
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    @AppStorage(Preferences.reduceMotionKey) private var appReduceMotion = false

    private var reduceMotion: Bool { systemReduceMotion || appReduceMotion }
    private var location: StoryLocation? { story.content?.location("ENV_BEN_OFFICE_PLAYER") }
    private var unlocks: Set<String> { story.save?.unlocks ?? [] }

    /// The objects of this level: the props with a hotspot, and the rewards the career put there.
    private var objects: [OfficeObject] {
        let rewards = Dictionary((story.content?.campaign.chapters.flatMap(\.steps).compactMap(\.reward).flatMap { $0.items ?? [] } ?? [])
            .map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        let props = location?.props(unlocked: unlocks, level: story.officeLevel) ?? []
        return props.compactMap { prop -> OfficeObject? in
            guard prop.hidden != true else { return nil }
            if let spot = prop.hotspot {
                return OfficeObject(id: prop.id, kind: prop.kind, label: story.resolve(spot.label), name: story.resolve(spot.name),
                                    provenance: spot.provenance.map { story.resolve($0) }, requires: prop.requires)
            }
            if let unlock = prop.requires, let item = rewards[unlock] {
                let name = story.resolve(item.name)
                return OfficeObject(id: prop.id, kind: prop.kind, label: name.uppercased(), name: name,
                                    provenance: item.provenance.map { story.resolve($0) }, requires: unlock)
            }
            return nil
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            topBar
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 6) {
                        StoryLabel(text: L10n.t("story.hub.kicker"), color: Trace.Colors.ivory2)
                        Text(L10n.t("story.office.title"))
                            .font(Trace.Fonts.title)
                            .foregroundStyle(Trace.Colors.ivory)
                            .accessibilityAddTraits(.isHeader)
                    }
                    pad
                    summary
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 24)
            }
            .scrollBounceBehavior(.basedOnSize)
        }
        .background(ModeBackdrop())
        .sheet(item: $opened) { object in
            HotspotSheet(object: object)
                .presentationDetents([.height(260), .medium])
                .presentationCornerRadius(Trace.Radius.sheet)
                .presentationBackground(Trace.Colors.paper)
                .presentationDragIndicator(.visible)
        }
        // A container's identifier must not replace its buttons' identifiers.
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("story.office.view")
        .task {
            guard let focusUnlock, let object = objects.first(where: { $0.requires == focusUnlock }) else { return }
            try? await Task.sleep(for: .milliseconds(reduceMotion ? 100 : 450))
            open(object)
        }
    }

    // MARK: Top bar

    private var topBar: some View {
        HStack {
            BackChevron(label: L10n.t("story.nav.hub")) { onBack() }
                .accessibilityIdentifier("story.office.back")
            Spacer(minLength: 8)
            Text(L10n.f("story.office.levelLabel", story.officeLevel))
                .font(Trace.Fonts.data)
                .tracking(1)
                .textCase(.uppercase)
                .foregroundStyle(Trace.Colors.ink)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Trace.Colors.label)
                .shadow(color: .black.opacity(0.3), radius: 2, y: 1)
                .accessibilityLabel(Text(L10n.f("story.office.level", story.officeLevel)))
        }
        .padding(.horizontal, 12)
        .padding(.trailing, 4)
    }

    // MARK: The desk pad

    private var pad: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 18), GridItem(.flexible(), spacing: 18)], spacing: 22) {
            ForEach(objects) { object in
                let isNew = !(story.save?.seenHotspots.contains(object.id) ?? true)
                Button { open(object) } label: {
                    OfficeObjectCard(object: object, isNew: isNew, player: story.player)
                }
                .buttonStyle(PressableStyle())
                .accessibilityLabel(Text(isNew ? L10n.f("story.office.newObject", object.label.capitalizedSentence)
                                               : object.label.capitalizedSentence))
                .accessibilityHint(Text(object.name))
                .accessibilityIdentifier("story.office.hotspot.\(object.id)")
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 26)
        .padding(.bottom, 22)
        .background(
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(Trace.Colors.kraftBoard)
                .overlay(RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .strokeBorder(Trace.Colors.ivory.opacity(0.08), lineWidth: 1)
                    .padding(5))
                .shadow(color: Trace.Shadow.slip.color, radius: Trace.Shadow.slip.radius, y: Trace.Shadow.slip.y)
                .accessibilityHidden(true)
        )
    }

    // MARK: Summary « Mon bureau · Niveau n / 4 »

    private var summary: some View {
        let level = story.officeLevel
        let rewards = (story.content?.campaign.chapters.flatMap(\.steps).compactMap(\.reward).flatMap { $0.items ?? [] } ?? [])
            .filter { unlocks.contains($0.id) }.count
        return VStack(alignment: .leading, spacing: 10) {
            StoryLabel(text: L10n.f("story.office.sheet", level))
                .accessibilityAddTraits(.isHeader)
            Text(nextAddition ?? L10n.t("story.office.complete"))
                .font(Trace.StoryFonts.body)
                .foregroundStyle(Trace.Colors.ink)
                .fixedSize(horizontal: false, vertical: true)
            Rectangle().fill(Trace.Story.rule).frame(height: 1).accessibilityHidden(true)
            Text(L10n.f("story.office.objects", objects.count) + "  ·  " + L10n.f("story.office.rewards", rewards))
                .font(Trace.Fonts.caption)
                .foregroundStyle(Trace.Colors.ink2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .paper(Trace.Colors.paper)
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

    // MARK: Actions

    private func open(_ object: OfficeObject) {
        story.markHotspotSeen(object.id)
        Haptics.light()
        AudioDirector.shared.play(.paper, volume: 0.3)
        opened = object
    }
}

/// One object of the office (a prop of the player's office with its sheet).
private struct OfficeObject: Identifiable, Hashable {
    let id: String
    let kind: String
    /// « TÉLÉPHONE », « CARTE BEN »…
    let label: String
    let name: String
    let provenance: String?
    let requires: String?
}

private extension String {
    /// « CARTE BEN » → « Carte BEN » for VoiceOver.
    var capitalizedSentence: String { StoryTitles.sentence(self) }
}

/// An object laid on the pad: a paper card (tilted by 1.5° at most) with a pin — red while never
/// opened — its picture drawn in ink by kind (the BEN card as a small ID card, the folders as a
/// kraft folder, the rest as a glyph), its label in Plex Mono caps and its name.
private struct OfficeObjectCard: View {
    let object: OfficeObject
    let isNew: Bool
    let player: StoryPlayer?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            picture
                .frame(maxWidth: .infinity, minHeight: 64)
            VStack(alignment: .leading, spacing: 3) {
                Text(object.label)
                    .fieldLabel(Trace.Colors.ink)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
                Text(object.name)
                    .font(Trace.Fonts.caption)
                    .foregroundStyle(Trace.Colors.ink2)
                    .multilineTextAlignment(.leading)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(12)
        .padding(.top, 4)
        .frame(maxWidth: .infinity, minHeight: 168, alignment: .topLeading)
        .paper(Trace.Colors.paperCard)
        .overlay(alignment: .top) {
            Pin(color: isNew ? Trace.Colors.red : Trace.Colors.staple, size: isNew ? 14 : 12)
                .offset(y: -6)
        }
        .tilt("office." + object.id)
        .contentShape(Rectangle())
    }

    @ViewBuilder
    private var picture: some View {
        switch object.kind {
        case "card":
            BenCardMini(player: player)
        case "files", "file":
            FolderMini()
        default:
            Image(systemName: Self.symbol(object.kind))
                .font(.system(size: 26, weight: .light))
                .foregroundStyle(Trace.Colors.ink)
                .frame(width: 60, height: 60)
                .overlay(Circle().strokeBorder(Trace.Colors.ink.opacity(0.35), lineWidth: 1))
                .accessibilityHidden(true)
        }
    }

    private static func symbol(_ kind: String) -> String {
        switch kind {
        case "computer": "desktopcomputer"
        case "desk_phone", "phone": "phone"
        case "cabinet": "archivebox"
        case "shelf", "trophy": "rosette"
        case "corkboard", "board": "pin"
        case "safe": "lock"
        case "frame": "photo.artframe"
        case "lamp": "lamp.desk"
        case "mug", "coffee": "cup.and.saucer"
        default: "shippingbox"
        }
    }
}

/// The BEN card, small: a print with initials, « BEN », the service number.
private struct BenCardMini: View {
    let player: StoryPlayer?

    var body: some View {
        HStack(spacing: 8) {
            PortraitOrInitials(image: nil,
                               initials: player.map { StoryCoordinator.initials($0.firstName, $0.lastName) } ?? "",
                               width: 30, height: 38)
            VStack(alignment: .leading, spacing: 2) {
                Text(L10n.t("story.paper.ben"))
                    .font(.custom(Trace.FontName.monoBold, fixedSize: 11))
                    .foregroundStyle(Trace.Colors.red)
                Text(verbatim: player?.serviceNumber ?? "")
                    .font(.custom(Trace.FontName.monoSemibold, fixedSize: 9))
                    .foregroundStyle(Trace.Colors.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
        }
        .padding(6)
        .frame(width: 112, height: 56, alignment: .leading)
        .background(Trace.Colors.photoBorder)
        .overlay(RoundedRectangle(cornerRadius: 4).strokeBorder(Trace.Colors.ink.opacity(0.25), lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 4))
        .shadow(color: Trace.Shadow.print.color, radius: 2, y: 1)
        .accessibilityHidden(true)
    }
}

/// A small kraft folder with a sheet peeking out.
private struct FolderMini: View {
    var body: some View {
        ZStack(alignment: .topLeading) {
            Rectangle().fill(Trace.Colors.paper)
                .frame(width: 70, height: 40)
                .offset(x: 12, y: 4)
            VStack(alignment: .leading, spacing: 0) {
                UnevenRoundedRectangle(topLeadingRadius: 3, bottomLeadingRadius: 0, bottomTrailingRadius: 0, topTrailingRadius: 3)
                    .fill(Trace.Colors.kraft)
                    .frame(width: 30, height: 7)
                Rectangle().fill(Trace.Colors.kraft)
                    .frame(width: 92, height: 46)
                    .overlay(Rectangle().strokeBorder(Trace.Colors.kraftDark.opacity(0.5), lineWidth: 1))
            }
            .offset(y: 10)
        }
        .frame(width: 96, height: 64, alignment: .topLeading)
        .shadow(color: Trace.Shadow.print.color, radius: 2, y: 1)
        .accessibilityHidden(true)
    }
}

/// The object's sheet (paper): its label, its name, where it comes from.
private struct HotspotSheet: View {
    let object: OfficeObject

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            StoryLabel(text: object.label)
            Text(object.name)
                .font(Trace.StoryFonts.h2)
                .foregroundStyle(Trace.Colors.ink)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)
            if let provenance = object.provenance, !provenance.isEmpty {
                Rectangle().fill(Trace.Story.rule).frame(height: 1).accessibilityHidden(true)
                Text(provenance)
                    .font(Trace.Fonts.callout)
                    .foregroundStyle(Trace.Colors.ink2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(24)
        .padding(.top, 8)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Trace.Colors.paper.overlay(PaperGrain()).ignoresSafeArea())
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("story.office.sheet")
    }
}
#endif
