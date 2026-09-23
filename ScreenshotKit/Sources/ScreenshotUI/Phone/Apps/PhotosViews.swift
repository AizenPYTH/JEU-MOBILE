#if os(iOS)
import SwiftUI
import CaseEngine

/// Photos: the library, sorted by the date *stored in each photo* — like a real phone.
struct PhotosGridView: View {
    let session: GameSession

    var body: some View {
        let game = session.game
        let byDay = Dictionary(grouping: game.photos, by: { $0.takenAt.dayNumber })
        let days = byDay.keys.sorted(by: >)
        ScrollView {
            LazyVStack(alignment: .leading, spacing: Theme.Spacing.s4, pinnedViews: [.sectionHeaders]) {
                if days.isEmpty {
                    EmptyStateView(title: L10n.t("empty.photosTitle"), message: L10n.t("empty.photosMessage"))
                }
                ForEach(days, id: \.self) { day in
                    let photos = byDay[day] ?? []
                    Section {
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 2), count: 3), spacing: 2) {
                            ForEach(photos) { photo in
                                Button {
                                    session.open(.photo(photo.id))
                                } label: {
                                    GeneratedPhoto(scene: photo.scene, seed: photo.id)
                                        .aspectRatio(1, contentMode: .fill)
                                        .frame(minHeight: Theme.Size.photoThumb)
                                        .clipped()
                                }
                                .buttonStyle(.plain)
                                .accessibilityIdentifier("photo.\(photo.id)")
                                .pinnable(ItemRef(.photo, photo.id), session: session, radius: 0)
                            }
                        }
                    } header: {
                        HStack(alignment: .firstTextBaseline) {
                            Text(photos.first.map { PhoneFormat.longDayCapitalized($0.takenAt) } ?? "")
                                .font(Theme.Fonts.headline)
                                .foregroundStyle(Theme.Colors.textPrimary)
                            Spacer()
                            Text(L10n.f("n.photos", photos.count))
                                .font(Theme.Fonts.caption)
                                .foregroundStyle(Theme.Colors.textSecondary)
                        }
                        .padding(.horizontal, Theme.Spacing.s4)
                        .padding(.vertical, Theme.Spacing.s3)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Theme.Colors.bgBase.opacity(0.92))
                    }
                }
            }
            .padding(.bottom, Theme.Spacing.bottomInset)
        }
        .appRoot(.photos, subtitle: L10n.f("n.photos", game.photos.count) + " · " + L10n.f("n.days", days.count), session: session)
    }
}

/// One photo: zoom, caption, and a paid close analysis (metadata + details).
struct PhotoDetailView: View {
    let photoID: String
    let session: GameSession
    @State private var scale: CGFloat = 1
    @GestureState private var pinch: CGFloat = 1

    var body: some View {
        let game = session.game
        if let photo = game.index.photo(photoID) {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.s5) {
                    GeneratedPhoto(scene: photo.scene, seed: photo.id)
                        .aspectRatio(4 / 3, contentMode: .fit)
                        .scaleEffect(min(4, max(1, scale * pinch)))
                        .gesture(MagnifyGesture()
                            .updating($pinch) { value, state, _ in state = value.magnification }
                            .onEnded { value in scale = min(4, max(1, scale * value.magnification)) })
                        .onTapGesture(count: 2) { withAnimation(Theme.Motion.springApp) { scale = scale > 1 ? 1 : 2.5 } }
                        .clipped()

                    VStack(alignment: .leading, spacing: Theme.Spacing.s3) {
                        HStack(alignment: .firstTextBaseline) {
                            Text(PhoneFormat.longDayCapitalized(photo.takenAt))
                                .font(Theme.Fonts.headline)
                            Spacer()
                            Text(PhoneFormat.time(photo.takenAt))
                                .font(Theme.Fonts.dataStrong)
                                .foregroundStyle(Theme.Colors.textSecondary)
                        }
                        Text(photo.caption)
                            .font(Theme.Fonts.body)
                            .foregroundStyle(Theme.Colors.textSecondary)
                    }
                    .padding(.horizontal, Theme.Spacing.s5)

                    if game.isAnalyzed(photo.id) {
                        PhotoInfoPanel(photo: photo, game: game)
                            .padding(.horizontal, Theme.Spacing.s5)
                            .pinnable(ItemRef(.photoInfo, photo.id), session: session)
                    } else {
                        Button {
                            session.perform { $0.analyzePhoto(photo.id) }
                        } label: {
                            HStack(spacing: Theme.Spacing.s3) {
                                Image(systemName: "info.circle.fill").font(.system(size: 20))
                                VStack(alignment: .leading, spacing: 1) {
                                    Text(L10n.t("photos.analyzeTitle")).font(Theme.Fonts.headline)
                                    Text(L10n.t("photos.analyzeHelp")).font(Theme.Fonts.caption).foregroundStyle(Theme.Colors.textSecondary)
                                }
                                Spacer()
                                CostTag(seconds: session.rules.timeCosts.analyzePhoto)
                            }
                            .padding(Theme.Spacing.s4)
                            .frame(maxWidth: .infinity, minHeight: Theme.Size.hit)
                            .background(RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous).fill(Theme.Colors.infoTint))
                            .overlay(RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous).strokeBorder(Theme.Colors.info.opacity(0.4)))
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(Theme.Colors.info)
                        .accessibilityLabel(Text(L10n.f("photos.analyze", session.rules.timeCosts.analyzePhoto)))
                        .padding(.horizontal, Theme.Spacing.s5)
                        .accessibilityIdentifier("photo.analyze")
                    }
                }
                .padding(.bottom, Theme.Spacing.s7)
            }
            .navigationBarTitleDisplayMode(.inline)
            .pinnable(ItemRef(.photo, photo.id), session: session)
        }
    }
}

struct PhotoInfoPanel: View {
    let photo: Photo
    let game: Investigation

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.s4) {
            Label(L10n.t("photos.metadata"), systemImage: "info.circle.fill")
                .font(Theme.Fonts.overline)
                .foregroundStyle(Theme.Colors.info)
            InfoRow(icon: "camera", label: L10n.t("photos.taken"), value: PhoneFormat.dayAndTime(photo.takenAt))
            if let place = photo.place { InfoRow(icon: "mappin.and.ellipse", label: L10n.t("photos.place"), value: place) }
            if let device = photo.device { InfoRow(icon: "iphone", label: L10n.t("photos.device"), value: device) }
            if photo.source == .received, let from = photo.from, let received = photo.receivedAt {
                InfoRow(icon: "arrow.down.circle", label: L10n.t("photos.received"),
                        value: "\(game.name(of: from)) · \(PhoneFormat.dayAndTime(received))")
            }
            Divider().overlay(Theme.Colors.line2)
            Text(L10n.t("photos.details"))
                .font(Theme.Fonts.overline)
                .foregroundStyle(Theme.Colors.textSecondary)
            Text(photo.details)
                .font(Theme.Fonts.body)
        }
        .padding(Theme.Spacing.s5)
        .background(RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous).fill(Theme.Colors.bgSurface))
        .overlay(RoundedRectangle(cornerRadius: Theme.Radius.md, style: .continuous).strokeBorder(Theme.Colors.line2))
    }
}

struct InfoRow: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: Theme.Spacing.s4) {
            Image(systemName: icon).frame(width: 20).foregroundStyle(Theme.Colors.textSecondary)
            Text(label).foregroundStyle(Theme.Colors.textSecondary)
            Spacer(minLength: Theme.Spacing.s3)
            Text(value).multilineTextAlignment(.trailing)
        }
        .font(Theme.Fonts.callout)
    }
}
#endif
