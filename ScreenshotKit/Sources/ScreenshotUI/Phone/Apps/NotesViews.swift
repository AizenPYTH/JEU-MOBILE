#if os(iOS)
import SwiftUI
import CaseEngine

/// Lock screen of a protected app: a code keypad, with the owner's hint. Each try costs time.
struct AppLockView: View {
    let app: AppID
    let session: GameSession
    @State private var code = ""
    @State private var failed = false

    private var lock: AppLock? { session.game.device.lockedApps.first { $0.app == app } }
    private var length: Int { lock?.code.count ?? 4 }

    var body: some View {
        VStack(spacing: Theme.Spacing.s7) {
            Spacer()
            Image(systemName: "lock.fill").font(.system(size: 36)).foregroundStyle(Theme.Colors.textSecondary)
            Text(L10n.f("lock.title", app.title)).font(Theme.Fonts.headline)
            if let hint = lock?.hint {
                Text(L10n.f("lock.hint", hint))
                    .font(Theme.Fonts.callout)
                    .foregroundStyle(Theme.Colors.textSecondary)
            }
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
            LazyVGrid(columns: Array(repeating: GridItem(.fixed(Theme.Size.keypadKey), spacing: Theme.Spacing.s5), count: 3),
                      spacing: Theme.Spacing.s4) {
                ForEach(["1", "2", "3", "4", "5", "6", "7", "8", "9", "", "0", "⌫"], id: \.self) { key in
                    if key.isEmpty {
                        Color.clear.frame(width: Theme.Size.keypadKey, height: Theme.Size.keypadKey)
                    } else {
                        Button {
                            press(key)
                        } label: {
                            Text(key)
                                .font(.system(size: 28, weight: .regular))
                                .frame(width: Theme.Size.keypadKey, height: Theme.Size.keypadKey)
                                .background(Circle().fill(key == "⌫" ? .clear : Theme.Colors.bgRaised))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func press(_ key: String) {
        if key == "⌫" { if !code.isEmpty { code.removeLast() }; return }
        guard code.count < length else { return }
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
        List(notes) { note in
            Button {
                session.open(.note(note.id))
            } label: {
                VStack(alignment: .leading, spacing: Theme.Spacing.s1) {
                    Text(note.title).font(Theme.Fonts.headline).lineLimit(1)
                    HStack {
                        Text(PhoneFormat.relative(note.modifiedAt, now: session.game.phoneNow))
                        Text(note.body.replacingOccurrences(of: "\n", with: " ")).lineLimit(1)
                    }
                    .font(Theme.Fonts.callout)
                    .foregroundStyle(Theme.Colors.textSecondary)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .navigationTitle(AppID.notes.title)
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
                    Text(note.title).font(Theme.Fonts.title)
                    Text(note.body).font(Theme.Fonts.body)
                    Text(L10n.f("notes.created", PhoneFormat.dayAndTime(note.createdAt)))
                        .font(Theme.Fonts.caption)
                        .foregroundStyle(Theme.Colors.textTertiary)
                }
                .padding(Theme.Spacing.s5)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .navigationBarTitleDisplayMode(.inline)
            .pinnable(ItemRef(.note, note.id), session: session)
        }
    }
}
#endif
