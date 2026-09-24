#if os(iOS)
import AVFoundation
import Foundation

/// The game's few sounds, each with a narrative job: the street and the sirens of the opening, the
/// seized phone vibrating, its notifications, the unlock, the keypad. Plus the reporter's voice
/// (system speech). Sounds follow the "Sons" setting and the silent switch (ambient session), and
/// never interrupt the player's own music.
@MainActor
final class AudioDirector {
    static let shared = AudioDirector()

    enum Sound: String, CaseIterable {
        case street, sirens, crowd, vibrate, notification, unlock, key, tick, sting
    }

    private var players: [String: AVAudioPlayer] = [:]
    private let speech = AVSpeechSynthesizer()
    private var sessionReady = false

    private init() {}

    private var enabled: Bool { Preferences.sounds }

    private func prepareSession() {
        guard !sessionReady else { return }
        sessionReady = true
        try? AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default, options: [.mixWithOthers])
        try? AVAudioSession.sharedInstance().setActive(true)
    }

    private func player(for name: String) -> AVAudioPlayer? {
        if let existing = players[name] { return existing }
        guard let url = Bundle.module.url(forResource: name, withExtension: "wav"),
              let player = try? AVAudioPlayer(contentsOf: url) else { return nil }
        player.prepareToPlay()
        players[name] = player
        return player
    }

    /// A one-off sound (unknown names are ignored: a case may name sounds a later version adds).
    func play(_ name: String, volume: Float = 1) {
        guard enabled, let player = player(for: name) else { return }
        prepareSession()
        player.numberOfLoops = 0
        player.volume = volume
        player.currentTime = 0
        player.play()
    }

    func play(_ sound: Sound, volume: Float = 1) { play(sound.rawValue, volume: volume) }

    /// A looping ambience, faded in.
    func loop(_ name: String, volume: Float = 0.6, fadeIn: TimeInterval = 1.2) {
        guard enabled, let player = player(for: name) else { return }
        prepareSession()
        player.numberOfLoops = -1
        if !player.isPlaying {
            player.volume = 0
            player.currentTime = 0
            player.play()
        }
        player.setVolume(volume, fadeDuration: fadeIn)
    }

    /// Fades out and stops every looping ambience (the ones not in `keeping`).
    func stopAmbience(keeping: Set<String> = [], fadeOut: TimeInterval = 0.8) {
        for (name, player) in players where player.numberOfLoops == -1 && !keeping.contains(name) && player.isPlaying {
            player.setVolume(0, fadeDuration: fadeOut)
            Task { @MainActor in
                try? await Task.sleep(for: .seconds(fadeOut))
                if player.volume == 0 { player.stop() }
            }
        }
    }

    /// Reads a line with the system's French voice.
    func speak(_ text: String) {
        guard enabled else { return }
        prepareSession()
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: Locale.current.language.languageCode?.identifier == "en" ? "en-GB" : "fr-FR")
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate * 1.02
        utterance.pitchMultiplier = 1.05
        utterance.volume = 0.95
        speech.speak(utterance)
    }

    func stopAll() {
        speech.stopSpeaking(at: .immediate)
        for player in players.values { player.stop() }
    }
}
#endif
