import Foundation
import SwiftUI
import AppKit
import VLCKit

extension Notification.Name {
    static let showPlayer = Notification.Name("ShowPlayerWindow")
}

final class VLCPlayerController: NSObject, ObservableObject, VLCMediaPlayerDelegate {
    static let shared = VLCPlayerController()
    @Published var isPlaying: Bool = false
    @Published var currentURL: URL?
    @Published var audioTrackIds: [Int32] = []
    @Published var currentAudioTrackId: Int32? = nil
    @Published var audioTrackNames: [String] = []
    @Published var videoSize: CGSize = .zero
    enum PreferredTrack { case original, accompaniment }
    @Published var preferredTrack: PreferredTrack = .original

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
            // Auto-advance when current ended
            if self.mediaPlayer.state == .ended {
                QueueManager.shared.playNextIfAvailable()
            }
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
        NotificationCenter.default.post(name: .showPlayer, object: nil)
        // Refresh tracks shortly after playback starts
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.refreshAudioTracks()
            // also try to read video size shortly after start
            if let size = self?.mediaPlayer.videoSize, size.width > 0 && size.height > 0 {
                self?.videoSize = size
            }
            self?.applyPreferredTrackIfPossible()
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

        // Do not force default here; defer to preferred track application

        logAudioTracks(context: "refresh")
    }

    var originalTrackId: Int32? { audioTrackIds.indices.contains(0) ? audioTrackIds[0] : nil }
    var accompanimentTrackId: Int32? { audioTrackIds.indices.contains(1) ? audioTrackIds[1] : nil }

    func selectOriginalTrack() {
        if let id = originalTrackId {
            mediaPlayer.currentAudioTrackIndex = id
            mediaPlayer.audio?.isMuted = false
            currentAudioTrackId = id
            preferredTrack = .original
            logAudioTracks(context: "select-original")
        }
    }

    func selectAccompanimentTrack() {
        if let id = accompanimentTrackId {
            mediaPlayer.currentAudioTrackIndex = id
            mediaPlayer.audio?.isMuted = false
            currentAudioTrackId = id
            preferredTrack = .accompaniment
            logAudioTracks(context: "select-accompaniment")
        }
    }

    private func applyPreferredTrackIfPossible() {
        switch preferredTrack {
        case .original:
            if let id = originalTrackId { mediaPlayer.currentAudioTrackIndex = id; currentAudioTrackId = id; logAudioTracks(context: "apply-pref-original") }
        case .accompaniment:
            if let id = accompanimentTrackId { mediaPlayer.currentAudioTrackIndex = id; currentAudioTrackId = id; logAudioTracks(context: "apply-pref-accompaniment") }
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
