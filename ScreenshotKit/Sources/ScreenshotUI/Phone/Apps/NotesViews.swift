#if os(iOS)
import SwiftUI
import CaseEngine

/// Lock screen of a protected app: a code keypad, with the owner's hint. Each try costs time.
///
/// The whole screen stays above the dossier bar on every iPhone (SE included): the keys shrink
/// (72 → 64 → 60 → 52 pt, never less) and the icon goes before anything has to scroll; only an
/// oversized text setting falls back to a scrolling keypad.
struct AppLockView: View {
    let app: AppID
    let session: GameSession
    @State private var code = ""
    @State private var failed = false

    private var lock: AppLock? { session.game.device.lockedApps.first { $0.app == app } }
    private var length: Int { lock?.code.count ?? 4 }

    private static let keys = ["1", "2", "3", "4", "5", "6", "7", "8", "9", "", "0", "⌫"]

    /// One size of the lock screen: keys, gaps, and the app icon (nil: hidden, the header shows it).
    struct Metrics {
        let key: CGFloat
        let rowGap: CGFloat
        let columnGap: CGFloat
        let block: CGFloat
        let glyph: CGFloat?

        static let roomy = Metrics(key: Theme.Size.keypadKey, rowGap: Theme.Spacing.s4, columnGap: Theme.Spacing.s5,
                                   block: Theme.Spacing.s6, glyph: Theme.Size.lockGlyph)
        static let regular = Metrics(key: Theme.Size.keypadKeyMedium, rowGap: Theme.Spacing.s3, columnGap: Theme.Spacing.s5,
                                     block: Theme.Spacing.s5, glyph: Theme.Size.avatarM)
        static let compact = Metrics(key: Theme.Size.keypadKeyCompact, rowGap: Theme.Spacing.s3, columnGap: Theme.Spacing.s5,
                                     block: Theme.Spacing.s3, glyph: nil)
        static let tight = Metrics(key: Theme.Size.keypadKeyMin, rowGap: Theme.Spacing.s2, columnGap: Theme.Spacing.s5,
                                   block: Theme.Spacing.s3, glyph: nil)
    }

    var body: some View {
        // The first size that fits the room left above the dossier bar.
        ViewThatFits(in: .vertical) {
            panel(.roomy)
            panel(.regular)
            panel(.compact)
            panel(.tight)
            ScrollView {
                panel(.tight)
                    .padding(.vertical, Theme.Spacing.s4)
            }
            .scrollBounceBehavior(.basedOnSize)
            .contentMargins(.bottom, 0, for: .scrollContent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.bottom, PhoneLayout.barClearance)
        .appRoot(app, subtitle: L10n.t("lock.subtitle"), session: session)
    }

    private func panel(_ m: Metrics) -> some View {
        VStack(spacing: m.block) {
            if let glyph = m.glyph {
                AppTileGlyph(app: app, size: glyph)
                    .overlay(alignment: .bottomTrailing) {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(Theme.Colors.textPrimary)
                            .frame(width: 28, height: 28)
                            .background(Circle().fill(Theme.Colors.bgSelected))
                            .overlay(Circle().strokeBorder(Theme.Colors.bgBase, lineWidth: 2))
                            .offset(x: 8, y: 8)
                    }
            }
            VStack(spacing: Theme.Spacing.s2) {
                Text(L10n.f("lock.title", app.title)).font(Theme.Fonts.title).foregroundStyle(Theme.Colors.textPrimary)
                if let hint = lock?.hint {
                    Text(L10n.f("lock.hint", hint))
                        .font(Theme.Fonts.callout)
                        .foregroundStyle(Theme.Colors.textSecondary)
                }
            }
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, Theme.Spacing.marginList)
            VStack(spacing: Theme.Spacing.s3) {
                HStack(spacing: Theme.Spacing.s5) {
                    ForEach(0..<length, id: \.self) { i in
                        Circle()
                            .strokeBorder(Theme.Colors.textPrimary, lineWidth: 1.5)
                            .background(Circle().fill(i < code.count ? Theme.Colors.textPrimary : .clear))
                            .frame(width: 14, height: 14)
                    }
                }
                .modifier(Shake(animatableData: failed ? 1 : 0))
                Text(L10n.f("lock.cost", session.rules.timeCosts.unlockAttempt))
                    .font(Theme.Fonts.caption)
                    .foregroundStyle(Theme.Colors.textTertiary)
            }
            keypad(m)
        }
        .frame(maxWidth: .infinity)
    }

    private func keypad(_ m: Metrics) -> some View {
        VStack(spacing: m.rowGap) {
            ForEach(0..<4, id: \.self) { row in
                HStack(spacing: m.columnGap) {
                    ForEach(Self.keys[(row * 3)..<(row * 3 + 3)], id: \.self) { key in
                        keyButton(key, size: m.key)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func keyButton(_ key: String, size: CGFloat) -> some View {
        if key.isEmpty {
            Color.clear.frame(width: size, height: size)
        } else {
            Button {
                press(key)
            } label: {
                Text(key)
                    .font(.system(size: size * Theme.Size.keypadGlyphRatio, weight: .regular))
                    .foregroundStyle(Theme.Colors.textPrimary)
                    .frame(width: size, height: size)
                    .background(Circle().fill(key == "⌫" ? .clear : Theme.Colors.bgRaised))
                    .contentShape(Circle())
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("lock.key.\(key)")
        }
    }

    private func press(_ key: String) {
        if key == "⌫" { if !code.isEmpty { code.removeLast() }; return }
        guard code.count < length else { return }
        AudioDirector.shared.play(.key, volume: 0.5)
        code.append(key)
        failed = false
        if code.count == length {
            let attempt = code
            if !session.unlock(app, code: attempt) {
                withAnimation(.default) { failed = true }
                code = ""
            }
        }
    }
}

struct Shake: GeometryEffect {
    var animatableData: CGFloat

    func effectValue(size: CGSize) -> ProjectionTransform {
        ProjectionTransform(CGAffineTransform(translationX: 8 * sin(animatableData * .pi * 4), y: 0))
    }
}

struct NotesListView: View {
    let session: GameSession

    var body: some View {
        let notes = session.game.device.notes.sorted { $0.modifiedAt > $1.modifiedAt }
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                AppSectionHeader(title: L10n.t("notes.folder"), count: notes.count, color: Theme.appAccent(.notes))
                if notes.isEmpty {
                    EmptyStateView(title: L10n.t("empty.notesTitle"), message: L10n.t("empty.notesMessage"))
                }
                CardGroup {
                    ForEach(Array(notes.enumerated()), id: \.element.id) { offset, note in
                        Button {
                            session.open(.note(note.id))
                        } label: {
                            VStack(alignment: .leading, spacing: Theme.Spacing.s1) {
                                Text(note.title).font(Theme.Fonts.headline).foregroundStyle(Theme.Colors.textPrimary).lineLimit(1)
                                HStack(spacing: Theme.Spacing.s3) {
                                    Text(PhoneFormat.relative(note.modifiedAt, now: session.game.phoneNow))
                                        .foregroundStyle(Theme.Colors.textPrimary)
                                    Text(note.body.replacingOccurrences(of: "\n", with: " ")).lineLimit(1)
                                        .foregroundStyle(Theme.Colors.textSecondary)
                                }
                                .font(Theme.Fonts.callout)
                            }
                            .padding(Theme.Spacing.s4)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        if offset < notes.count - 1 { RowDivider() }
                    }
                }
            }
            .padding(.bottom, Theme.Spacing.bottomInset)
        }
        .appRoot(.notes, subtitle: L10n.f("n.notes", notes.count), session: session)
    }
}

struct NoteView: View {
    let noteID: String
    let session: GameSession

    var body: some View {
        if let note = session.game.index.note(noteID) {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.s4) {
                    Text(L10n.f("notes.modified", PhoneFormat.dayAndTime(note.modifiedAt)))
                        .font(Theme.Fonts.caption)
                        .foregroundStyle(Theme.Colors.textSecondary)
                        .frame(maxWidth: .infinity)
                    Text(note.title).font(Theme.Fonts.title2).foregroundStyle(Theme.Colors.textPrimary)
                    Rectangle().fill(Theme.appAccent(.notes)).frame(width: 40, height: 3)
                    Text(note.body).font(Theme.Fonts.bodyLarge).foregroundStyle(Theme.Colors.textPrimary).lineSpacing(4)
                    Text(L10n.f("notes.created", PhoneFormat.dayAndTime(note.createdAt)))
                        .font(Theme.Fonts.caption)
                        .foregroundStyle(Theme.Colors.textTertiary)
                }
                .padding(Theme.Spacing.s5)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .navigationBarTitleDisplayMode(.inline)
            .pinnable(ItemRef(.note, note.id), session: session, selectOnTap: false)
        }
    }
}
#endif
