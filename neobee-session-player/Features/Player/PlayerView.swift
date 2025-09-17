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

struct PlayerView: View {
    @ObservedObject private var controller = VLCPlayerController.shared
    @ObservedObject private var queue = QueueManager.shared
    let isEmbedded: Bool
    
    @State private var showControls = true
    @State private var controlsOpacity: Double = 1.0
    @State private var isHovering = false

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Main video container with rounded corners and shadow
                videoContainerView(geometry: geometry)
                
                // iOS 26 Liquid Glass control overlay
                if showControls {
                    controlOverlay
                        .opacity(controlsOpacity)
                        .animation(.easeInOut(duration: 0.3), value: controlsOpacity)
                }
                
                // Floating song info card
                if let url = controller.currentURL {
                    songInfoCard(url: url)
                }
            }
        }
        .background(
            // iOS 26 Dynamic background with subtle gradient
            LinearGradient(
                colors: [
                    Color.black.opacity(0.95),
                    Color.black.opacity(0.8),
                    Color.black.opacity(0.95)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(isEmbedded ? 12 : 0)
        .onHover { hovering in
            withAnimation(.liquidMotion(duration: 0.4)) {
                isHovering = hovering
                controlsOpacity = hovering ? 1.0 : 0.7
            }
        }
    }
    
    // MARK: - Video Container
    private func videoContainerView(geometry: GeometryProxy) -> some View {
        let containerW = max(geometry.size.width, 1)
        let containerH = max(geometry.size.height - 120, 1) // Reserve space for controls
        let videoW = max(controller.videoSize.width, 16)
        let videoH = max(controller.videoSize.height, 9)
        let aspect = videoW / videoH
        
        let isFullScreen = NSApp.keyWindow?.styleMask.contains(.fullScreen) ?? false
        let widthFitH = containerW / aspect
        let (finalW, finalH): (CGFloat, CGFloat) = {
            if isFullScreen || widthFitH <= containerH {
                return (containerW, widthFitH)
            } else {
                let h = containerH
                let w = h * aspect
                return (w, h)
            }
        }()
        
        return ZStack {
            // Background with subtle pattern
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.black)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.1),
                                    Color.clear,
                                    Color.white.opacity(0.05)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
            
            VLCVideoContainerView(controller: controller)
                .frame(width: finalW, height: finalH)
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.top, 20)
    }
    
    // MARK: - iOS 26 Liquid Glass Control Overlay
    private var controlOverlay: some View {
        VStack {
            Spacer()
            
            // Main control panel with Liquid Glass effect
            HStack(spacing: 20) {
                // Play/Pause with modern design
                playPauseButton
                
                Spacer()
                
                // Audio track selector with segmented style
                audioTrackSelector
                
                Spacer()
                
                // Secondary controls
                secondaryControls
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .background(liquidGlassBackground)
            .cornerRadius(20)
            .shadow(color: .black.opacity(0.2), radius: 12, x: 0, y: 6)
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
    }
    
    // MARK: - Liquid Glass Background
    private var liquidGlassBackground: some View {
        ZStack {
            // Base glass effect
            Rectangle()
                .fill(.ultraThinMaterial)
                .environment(\.colorScheme, .dark)
            
            // iOS 26 Liquid Glass overlay
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.15),
                            Color.white.opacity(0.05),
                            Color.white.opacity(0.1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .blendMode(.overlay)
            
            // Subtle border glow
            Rectangle()
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.2),
                            Color.clear,
                            Color.white.opacity(0.1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 0.5
                )
        }
    }
    
    // MARK: - Modern Play/Pause Button
    private var playPauseButton: some View {
        Button(action: {
            withAnimation(.liquidMotion(duration: 0.3)) {
                controller.isPlaying ? controller.pause() : controller.play()
            }
        }) {
            Image(systemName: controller.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                .font(.system(size: 44, weight: .medium))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.white, .white.opacity(0.8)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .scaleEffect(isHovering ? 1.1 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(controller.currentURL == nil)
        .opacity(controller.currentURL == nil ? 0.3 : 1.0)
    }
    
    // MARK: - Audio Track Selector
    private var audioTrackSelector: some View {
        HStack(spacing: 12) {
            audioTrackButton(
                title: "原唱",
                isSelected: controller.currentAudioTrackId == controller.originalTrackId,
                isEnabled: controller.originalTrackId != nil,
                action: { controller.selectOriginalTrack() }
            )
            
            audioTrackButton(
                title: "伴奏",
                isSelected: controller.currentAudioTrackId == controller.accompanimentTrackId,
                isEnabled: controller.accompanimentTrackId != nil,
                action: { controller.selectAccompanimentTrack() }
            )
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.black.opacity(0.2))
        )
    }
    
    private func audioTrackButton(title: String, isSelected: Bool, isEnabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: {
            withAnimation(.liquidMotion(duration: 0.2)) {
                action()
            }
        }) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(isSelected ? .black : .white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isSelected ? .white : Color.clear)
                        .animation(.liquidMotion(duration: 0.2), value: isSelected)
                )
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1.0 : 0.4)
    }
    
    // MARK: - Secondary Controls
    private var secondaryControls: some View {
        HStack(spacing: 16) {
            // Next song button
            Button(action: {
                withAnimation(.liquidMotion(duration: 0.2)) {
                    queue.playNextIfAvailable()
                }
            }) {
                Image(systemName: "forward.end.circle")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
            }
            .buttonStyle(PlainButtonStyle())
            .disabled(!queue.canPlayNext)
            .opacity(queue.canPlayNext ? 1.0 : 0.3)
            
            // Stop button
            Button(action: {
                withAnimation(.liquidMotion(duration: 0.2)) {
                    controller.stop()
                }
            }) {
                Image(systemName: "stop.circle")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
            }
            .buttonStyle(PlainButtonStyle())
            .disabled(controller.currentURL == nil)
            .opacity(controller.currentURL == nil ? 0.3 : 1.0)
            
            // Full screen button
            Button(action: {
                if let window = NSApp.keyWindow {
                    window.toggleFullScreen(nil)
                }
            }) {
                Image(systemName: "arrow.up.left.and.arrow.down.right")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
    
    // MARK: - Floating Song Info Card
    private func songInfoCard(url: URL) -> some View {
        VStack {
            HStack {
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(url.deletingPathExtension().lastPathComponent)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white)
                        .lineLimit(2)
                        .multilineTextAlignment(.trailing)
                    
                    if controller.isPlaying {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(Color.green)
                                .frame(width: 6, height: 6)
                                .scaleEffect(isHovering ? 1.2 : 1.0)
                                .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: isHovering)
                            
                            Text("正在播放")
                                .font(.system(size: 11, weight: .regular))
                                .foregroundColor(.green)
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(.ultraThinMaterial)
                        .environment(\.colorScheme, .dark)
                )
                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
            }
            .padding(.top, 20)
            .padding(.trailing, 20)
            
            Spacer()
        }
    }
}

// MARK: - iOS 26 Animation Extensions
extension Animation {
    static func liquidMotion(duration: Double = 0.4) -> Animation {
        .timingCurve(0.2, 0.8, 0.2, 1.0, duration: duration)
    }
}

#Preview {
    PlayerView(isEmbedded: false)
}


