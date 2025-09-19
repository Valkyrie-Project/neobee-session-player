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
    // Playback progress (milliseconds)
    @Published var currentTimeMs: Int64 = 0
    @Published var durationMs: Int64 = 0
    // Global volume (0.0 - 1.0), persisted
    @Published var volume: Float = 1.0 {
        didSet {
            applyVolumeToPlayer()
            persistVolume()
        }
    }

    private let mediaPlayer: VLCMediaPlayer
    // Single-player approach: no secondary player, no sync timer
    private var lastAudioLogSignature: String?
    private var lastAudioLogAt: Date = .distantPast
    let videoView: VLCVideoView
    // Track whether stop was triggered by user
    private var userInitiatedStop: Bool = false
    // Ensure we only auto-advance once per track
    private var didAdvanceForCurrent: Bool = false

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
        // Load persisted global volume
        loadPersistedVolume()
        // Apply initial volume to the player
        applyVolumeToPlayer()
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
            // Auto-advance when current finished
            switch self.mediaPlayer.state {
            case .ended:
                if !self.didAdvanceForCurrent {
                    self.didAdvanceForCurrent = true
                    QueueManager.shared.playNextIfAvailable()
                }
            case .stopped:
                if self.userInitiatedStop {
                    self.userInitiatedStop = false
                } else {
                    if !self.didAdvanceForCurrent {
                        self.didAdvanceForCurrent = true
                        QueueManager.shared.playNextIfAvailable()
                    }
                }
            default:
                break
            }
        }
    }

    func mediaPlayerTimeChanged(_ aNotification: Notification) {
        // Update progress and lazily update video size once it becomes known
        let time = mediaPlayer.time
        let length = mediaPlayer.media?.length
        let newCurrentMs = Int64(time.intValue)
        let newDurationMs = Int64(length?.intValue ?? 0)
        if newCurrentMs != currentTimeMs || newDurationMs != durationMs {
            DispatchQueue.main.async { [weak self] in
                self?.currentTimeMs = newCurrentMs
                self?.durationMs = newDurationMs
            }
        }
        // Fallback: if we reach the end threshold, try to advance once
        if newDurationMs > 0 && newCurrentMs >= newDurationMs - 500 && !didAdvanceForCurrent {
            didAdvanceForCurrent = true
            QueueManager.shared.playNextIfAvailable()
        }
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
        userInitiatedStop = false
        // 验证文件是否存在
        guard FileManager.default.fileExists(atPath: url.path) else {
            Task { @MainActor in
                ErrorHandler.shared.handle(
                    AppError.fileNotFound(url.path),
                    context: "播放媒体文件"
                )
            }
            return
        }
        
        // 验证文件格式（仅支持 mkv 与 mpg）
        let supportedFormats = ["mkv", "mpg"]
        guard supportedFormats.contains(url.pathExtension.lowercased()) else {
            Task { @MainActor in
                ErrorHandler.shared.handle(
                    AppError.unsupportedFileFormat(url.pathExtension),
                    context: "播放媒体文件"
                )
            }
            return
        }
        
        currentURL = url
        didAdvanceForCurrent = false
        // Reset progress when starting new media
        currentTimeMs = 0
        durationMs = 0
        let media = VLCMedia(url: url)
        mediaPlayer.media = media
        mediaPlayer.play()
        NotificationCenter.default.post(name: .showPlayer, object: nil)
        // Refresh tracks shortly after playback starts
        DispatchQueue.main.asyncAfter(deadline: .now() + DesignSystem.Animation.trackRefreshDelay) { [weak self] in
            self?.refreshAudioTracks()
            // also try to read video size shortly after start
            if let size = self?.mediaPlayer.videoSize, size.width > 0 && size.height > 0 {
                self?.videoSize = size
            }
            self?.applyPreferredTrackIfPossible()
            // Ensure global volume is applied after media is ready
            self?.applyVolumeToPlayer()
        }
    }

    func play() {
        userInitiatedStop = false
        didAdvanceForCurrent = false
        mediaPlayer.play()
    }

    func pause() {
        mediaPlayer.pause()
    }
    
    func togglePlayPause() {
        if isPlaying {
            pause()
        } else {
            play()
        }
    }

    func stop() {
        userInitiatedStop = true
        mediaPlayer.stop()
        isPlaying = false
        currentTimeMs = 0
        durationMs = 0
    }

    // MARK: - Seeking
    func seek(toMilliseconds targetMs: Int64) {
        let clamped = max(0, min(targetMs, durationMs > 0 ? durationMs : targetMs))
        mediaPlayer.time = VLCTime(int: Int32(clamped))
    }
    
    func seek(toProgress progress: Float) {
        // progress 0.0 - 1.0
        let p = max(0, min(progress, 1))
        
        // Use time-based seeking for more reliable results
        if durationMs > 0 {
            let targetTime = Int64(Float(durationMs) * p)
            mediaPlayer.time = VLCTime(int: Int32(targetTime))
        } else {
            // Fallback to position-based seeking
            mediaPlayer.position = p
        }
    }
    
    // Get current position for UI updates
    var currentPosition: Float {
        return mediaPlayer.position
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

    // MARK: - Volume Persistence and Application
    private let volumeDefaultsKey = "GlobalVolume_0_1"
    
    private func loadPersistedVolume() {
        if UserDefaults.standard.object(forKey: volumeDefaultsKey) != nil {
            let v = UserDefaults.standard.float(forKey: volumeDefaultsKey)
            if v >= 0.0 && v <= 1.0 {
                volume = v
            }
        }
    }
    
    private func persistVolume() {
        UserDefaults.standard.set(volume, forKey: volumeDefaultsKey)
    }
    
    private func applyVolumeToPlayer() {
        // VLCKit volume typical range is 0-100 for unity gain; >100 boosts and may clip.
        // Map 0.0-1.0 to 0-100 to avoid distortion.
        let scaled = Int32((max(0.0, min(volume, 1.0)) * 100.0).rounded())
        mediaPlayer.audio?.volume = scaled
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
