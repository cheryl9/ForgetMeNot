import AVFoundation
import SwiftUI

// ─────────────────────────────────────────────
// MARK: - Ambient Music Player
// Singleton-style ObservableObject injected at app root.
// Loops "ambient_music.mp3" (or .m4a) from the project bundle.
// Just drag your MP3 into the Xcode project navigator and
// make sure "Add to target" is ticked — no asset catalog needed.
// ─────────────────────────────────────────────
class AmbientMusicPlayer: ObservableObject {
    @Published var isPlaying = false
    private var player: AVAudioPlayer?

    func toggle() {
        isPlaying ? pause() : play()
    }

    func play() {
        if player == nil { prepare() }
        player?.play()
        isPlaying = true
    }

    func pause() {
        player?.pause()
        isPlaying = false
    }

    func stop() {
        player?.stop()
        player?.currentTime = 0
        isPlaying = false
    }

    private func prepare() {
        let name = "ambient_music"
        let url = Bundle.main.url(forResource: name, withExtension: "mp3")
            ?? Bundle.main.url(forResource: name, withExtension: "m4a")
        guard let url else {
            print("AmbientMusicPlayer: '\(name).mp3/.m4a' not found in bundle.")
            return
        }
        do {
            // .mixWithOthers keeps other system audio (calls, etc.) alive
            try AVAudioSession.sharedInstance().setCategory(
                .playback, mode: .default, options: .mixWithOthers
            )
            try AVAudioSession.sharedInstance().setActive(true)
            player = try AVAudioPlayer(contentsOf: url)
            player?.numberOfLoops = -1   // loop forever
            player?.volume = 0.4
            player?.prepareToPlay()
        } catch {
            print("AmbientMusicPlayer error: \(error)")
        }
    }
}

// ─────────────────────────────────────────────
// MARK: - Music Toggle Button
// Drop this anywhere you want the music button to appear.
// ─────────────────────────────────────────────
struct MusicToggleButton: View {
    @ObservedObject var musicPlayer: AmbientMusicPlayer
    @State private var pulsing = false

    var body: some View {
        Button { musicPlayer.toggle() } label: {
            ZStack {
                // Pulsing glow ring when playing
                Circle()
                    .fill(Color(hex: "F4A8B8").opacity(musicPlayer.isPlaying ? 0.4 : 0))
                    .frame(width: 62, height: 62)
                    .scaleEffect(pulsing ? 1.18 : 1.0)
                    .animation(
                        musicPlayer.isPlaying
                            ? .easeInOut(duration: 1.1).repeatForever(autoreverses: true)
                            : .default,
                        value: pulsing
                    )

                // Button circle
                Circle()
                    .fill(
                        LinearGradient(
                            colors: musicPlayer.isPlaying
                                ? [Color(hex: "F4A8B8"), Color(hex: "e8829a")]
                                : [Color.white.opacity(0.88), Color.white.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 50, height: 50)
                    .shadow(color: Color(hex: "F4A8B8").opacity(0.5), radius: 8, x: 0, y: 4)

                Image(systemName: musicPlayer.isPlaying ? "music.note" : "music.note.list")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(musicPlayer.isPlaying ? .white : Color(hex: "e8829a"))
            }
        }
        .onChange(of: musicPlayer.isPlaying) { _, playing in
            pulsing = playing
        }
    }
}