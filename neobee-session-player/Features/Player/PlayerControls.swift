import SwiftUI
import Foundation

// MARK: - Player Control Components

struct PlayPauseButton: View {
    @ObservedObject private var controller = VLCPlayerController.shared
    
    var body: some View {
        Button(action: {
            controller.isPlaying ? controller.pause() : controller.play()
        }) {
            Image(systemName: controller.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                .font(.system(size: 44))
                .foregroundStyle(.primary)
        }
        .buttonStyle(.borderless)
        .disabled(controller.currentURL == nil)
    }
}

struct AudioTrackSelector: View {
    @ObservedObject private var controller = VLCPlayerController.shared
    @State private var selectedTrack: Int = 0
    
    var body: some View {
        Picker("音轨选择", selection: $selectedTrack) {
            Text("原唱").tag(0)
            Text("伴奏").tag(1)
        }
        .pickerStyle(.segmented)
        .disabled(controller.originalTrackId == nil && controller.accompanimentTrackId == nil)
        .onChange(of: selectedTrack) { _, newValue in
            if newValue == 0 {
                controller.selectOriginalTrack()
            } else {
                controller.selectAccompanimentTrack()
            }
        }
        .onAppear {
            // 根据当前播放的音轨设置选择器状态
            if controller.currentAudioTrackId == controller.originalTrackId {
                selectedTrack = 0
            } else if controller.currentAudioTrackId == controller.accompanimentTrackId {
                selectedTrack = 1
            }
        }
    }
}

struct SecondaryControls: View {
    @ObservedObject private var controller = VLCPlayerController.shared
    @ObservedObject private var queue = QueueManager.shared
    
    var body: some View {
        HStack(spacing: 16) {
            // Next song button
            Button(action: { queue.playNextIfAvailable() }) {
                Image(systemName: "forward.end.circle")
                    .font(.system(size: 24))
            }
            .buttonStyle(.borderless)
            .disabled(!queue.canPlayNext)
            
            // Stop button
            Button(action: { controller.stop() }) {
                Image(systemName: "stop.circle")
                    .font(.system(size: 24))
            }
            .buttonStyle(.borderless)
            .disabled(controller.currentURL == nil)
            
            // Full screen button
            Button(action: {
                if let window = NSApp.keyWindow {
                    window.toggleFullScreen(nil)
                }
            }) {
                Image(systemName: "arrow.up.left.and.arrow.down.right")
                    .font(.system(size: 20))
            }
            .buttonStyle(.borderless)
        }
    }
}

// MARK: - Control Background

struct ControlBackground: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(.thickMaterial)
            .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 2)
    }
}

// MARK: - Control Overlay Container

struct ControlOverlay: View {
    let isHovering: Bool
    let isFullScreen: Bool
    
    var body: some View {
        VStack {
            Spacer()
            
            // Main control panel
            HStack(spacing: 20) {
                // Play/Pause button
                PlayPauseButton()
                
                Spacer()
                
                // Audio track selector
                AudioTrackSelector()
                
                Spacer()
                
                // Secondary controls
                SecondaryControls()
            }
            .padding()
            .background(ControlBackground())
            .padding(.horizontal)
            .padding(.bottom, isFullScreen ? 40 : 32)
        }
    }
}
