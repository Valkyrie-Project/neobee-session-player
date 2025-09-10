import Foundation
import SwiftUI
import AppKit
import VLCKit

final class VLCPlayerController: NSObject, ObservableObject, VLCMediaPlayerDelegate {
    @Published var isPlaying: Bool = false
    @Published var currentURL: URL?

    private let mediaPlayer: VLCMediaPlayer
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
            ZStack {
                VLCVideoContainerView(controller: controller)
                    .background(Color.black)
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

                if let url = controller.currentURL {
                    Text(url.lastPathComponent)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal)
        }
        .padding(.bottom)
    }
}

#Preview {
    PlayerView()
}


