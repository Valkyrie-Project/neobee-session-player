import Foundation
import SwiftUI
import AppKit
import VLCKit

final class VLCPlayerController: NSObject, ObservableObject, VLCMediaPlayerDelegate {
    @Published var isPlaying: Bool = false
    @Published var currentURL: URL?
    @Published var audioTrackIds: [Int32] = []
    @Published var currentAudioTrackId: Int32? = nil
    @Published var audioTrackNames: [String] = []
    @Published var videoSize: CGSize = .zero

    private let mediaPlayer: VLCMediaPlayer
    // Single-player approach: no secondary player, no sync timer
    private var lastAudioLogSignature: String?
    private var lastAudioLogAt: Date = .distantPast
    let videoView: VLCVideoView

    override init() {
        self.videoView = VLCVideoView()
        self.mediaPlayer = VLCMediaPlayer(options: [
            "--quiet",
            "--verbose=0",
            "--no-stats",
            "--no-osd"
        ])
        super.init()
        mediaPlayer.drawable = videoView
        mediaPlayer.delegate = self
    }

    deinit {
        mediaPlayer.stop()
    }

    // VLCMediaPlayerDelegate
    func mediaPlayerStateChanged(_ aNotification: Notification) {
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.isPlaying = self.mediaPlayer.isPlaying
            // capture current video size if available
            let size = self.mediaPlayer.videoSize
            if size.width > 0 && size.height > 0 {
                self.videoSize = size
            }
            self.refreshAudioTracks()
        }
    }

    func mediaPlayerTimeChanged(_ aNotification: Notification) {
        // lazily update video size once it becomes known
        let size = mediaPlayer.videoSize
        if size.width > 0 && size.height > 0 && size != videoSize {
            DispatchQueue.main.async { [weak self] in
                self?.videoSize = size
            }
        }
    }

    func attach(to view: VLCVideoView) {
        mediaPlayer.drawable = view
    }

    func openAndPlayFromPanel() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.directoryURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        panel.begin { [weak self] response in
            guard let self, response == .OK, let url = panel.url else { return }
            self.play(url: url)
        }
    }

    func play(url: URL) {
        currentURL = url
        let media = VLCMedia(url: url)
        mediaPlayer.media = media
        mediaPlayer.play()
        // Refresh tracks shortly after playback starts
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.refreshAudioTracks()
            // also try to read video size shortly after start
            if let size = self?.mediaPlayer.videoSize, size.width > 0 && size.height > 0 {
                self?.videoSize = size
            }
        }
    }

    func play() {
        mediaPlayer.play()
    }

    func pause() {
        mediaPlayer.pause()
    }

    func stop() {
        mediaPlayer.stop()
        isPlaying = false
    }

    func refreshAudioTracks() {
        // Read raw arrays
        let rawIds: [Int32] = (mediaPlayer.audioTrackIndexes as? [NSNumber])?.map { Int32(truncating: $0) } ?? []
        let rawNames: [String] = (mediaPlayer.audioTrackNames as? [String]) ?? []

        // If we get a transient empty response while playing, keep previous values and retry shortly
        if mediaPlayer.isPlaying && rawIds.isEmpty && rawNames.isEmpty {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                self?.refreshAudioTracks()
            }
            logAudioTracks(context: "refresh-skip-empty")
            return
        }

        // Align names to ids length, then filter out invalid ids and the built-in "Disable" entry
        let alignedNames = Array(rawNames.prefix(rawIds.count))
        var filteredIds: [Int32] = []
        var filteredNames: [String] = []
        for (idx, id) in rawIds.enumerated() {
            guard id >= 0 else { continue }
            let name = idx < alignedNames.count ? alignedNames[idx] : ""
            if name.trimmingCharacters(in: .whitespacesAndNewlines).localizedCaseInsensitiveContains("disable") {
                continue
            }
            filteredIds.append(id)
            filteredNames.append(name)
        }

        audioTrackIds = filteredIds
        audioTrackNames = filteredNames

        // Update current selection from main player state
        let current: Int32 = mediaPlayer.currentAudioTrackIndex
        currentAudioTrackId = current >= 0 ? current : nil

        // Ensure main player uses a valid track if available
        if let a = originalTrackId, currentAudioTrackId == nil {
            mediaPlayer.currentAudioTrackIndex = a
        }

        logAudioTracks(context: "refresh")
    }

    var originalTrackId: Int32? { audioTrackIds.indices.contains(0) ? audioTrackIds[0] : nil }
    var accompanimentTrackId: Int32? { audioTrackIds.indices.contains(1) ? audioTrackIds[1] : nil }

    func selectOriginalTrack() {
        if let id = originalTrackId {
            mediaPlayer.currentAudioTrackIndex = id
            mediaPlayer.audio?.isMuted = false
            currentAudioTrackId = id
            logAudioTracks(context: "select-original")
        }
    }

    func selectAccompanimentTrack() {
        if let id = accompanimentTrackId {
            mediaPlayer.currentAudioTrackIndex = id
            mediaPlayer.audio?.isMuted = false
            currentAudioTrackId = id
            logAudioTracks(context: "select-accompaniment")
        }
    }

    private func logAudioTracks(context: String) {
        let ids = audioTrackIds.map { String($0) }.joined(separator: ", ")
        let names = audioTrackNames.joined(separator: ", ")
        let current = currentAudioTrackId.map { String($0) } ?? "nil"
        let muted = mediaPlayer.audio?.isMuted ?? false
        let signature = "ids=[\(ids)] names=[\(names)] current=\(current) muted=\(muted)"
        let now = Date()
        // Only print when state actually changes, and avoid printing more than once per second
        if signature == lastAudioLogSignature && now.timeIntervalSince(lastAudioLogAt) < 1.0 {
            return
        }
        lastAudioLogSignature = signature
        lastAudioLogAt = now
        print("[Audio][\(context)] \(signature)")
    }

    // Single-player approach: no sync timer needed
}

struct VLCVideoContainerView: NSViewRepresentable {
    let controller: VLCPlayerController

    func makeNSView(context: Context) -> VLCVideoView {
        controller.attach(to: controller.videoView)
        return controller.videoView
    }

    func updateNSView(_ nsView: VLCVideoView, context: Context) {
        controller.attach(to: nsView)
    }
}

struct PlayerView: View {
    @StateObject private var controller = VLCPlayerController()

    var body: some View {
        VStack(spacing: 12) {
            GeometryReader { geo in
                ZStack {
                    Color.black
                    // Maintain left/right fit, letterbox top/bottom
                    let containerW = max(geo.size.width, 1)
                    let containerH = max(geo.size.height, 1)
                    let videoW = max(controller.videoSize.width, 16)
                    let videoH = max(controller.videoSize.height, 9)
                    let aspect = videoW / videoH
                    // Fit-to-width: fill left/right fully, compute height by aspect
                    let finalW = containerW
                    let finalH = finalW / aspect
                    VLCVideoContainerView(controller: controller)
                        .frame(width: finalW, height: finalH)
                        .position(x: geo.size.width / 2, y: geo.size.height / 2)
                        .clipped()
                }
            }
            .frame(minWidth: 800, minHeight: 450)

            HStack(spacing: 12) {
                Button("Open…") {
                    controller.openAndPlayFromPanel()
                }

                Button(controller.isPlaying ? "Pause" : "Play") {
                    controller.isPlaying ? controller.pause() : controller.play()
                }
                .disabled(controller.currentURL == nil)

                Button("Stop") {
                    controller.stop()
                }
                .disabled(controller.currentURL == nil)

                Spacer()

                // Audio track quick toggle: 原唱(0) / 伴奏(1)
                HStack(spacing: 8) {
                    Button("原唱") { controller.selectOriginalTrack() }
                        .disabled(controller.originalTrackId == nil)
                        .buttonStyle(.bordered)
                        .tint(controller.currentAudioTrackId == controller.originalTrackId ? .accentColor : .gray)

                    Button("伴奏") { controller.selectAccompanimentTrack() }
                        .disabled(controller.accompanimentTrackId == nil)
                        .buttonStyle(.bordered)
                        .tint(controller.currentAudioTrackId == controller.accompanimentTrackId ? .accentColor : .gray)
                }

                if let url = controller.currentURL {
                    Text(url.lastPathComponent)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(.ultraThinMaterial)
            .zIndex(1)
        }
        .padding(.bottom)
    }
}

#Preview {
    PlayerView()
}


