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
            VStack(spacing: 12) {
                // Progress bar with current time and duration, seekable
                ProgressSeekBar()
                
                HStack(spacing: 20) {
                // Play/Pause button
                PlayPauseButton()
                
                Spacer()
                
                // Audio track selector
                AudioTrackSelector()
                
                Spacer()
                
                // Secondary controls
                SecondaryControls()
                    
                    // Volume slider
                    VolumeControl()
                }
            }
            .padding()
            .background(ControlBackground())
            .padding(.horizontal)
            .padding(.bottom, isFullScreen ? 40 : 32)
        }
    }
}

// MARK: - Progress Seek Bar

struct ProgressSeekBar: View {
    @ObservedObject private var controller = VLCPlayerController.shared
    @State private var isScrubbing: Bool = false
    @State private var localProgress: Double = 0.0 // 0..1 while scrubbing
    
    private func formatTime(_ ms: Int64) -> String {
        let totalSeconds = Int(ms / 1000)
        let s = totalSeconds % 60
        let m = (totalSeconds / 60) % 60
        let h = totalSeconds / 3600
        if h > 0 {
            return String(format: "%d:%02d:%02d", h, m, s)
        } else {
            return String(format: "%02d:%02d", m, s)
        }
    }
    
    var body: some View {
        let progress: Double = {
            if isScrubbing { return localProgress }
            return Double(controller.currentPosition)
        }()
        HStack(spacing: 10) {
            Text(formatTime(controller.currentTimeMs))
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 48, alignment: .leading)
            Slider(value: Binding<Double>(
                get: { progress },
                set: { newValue in
                    isScrubbing = true
                    localProgress = newValue
                }
            ), in: 0...1)
            .onChange(of: localProgress) { _, newValue in
                // Throttle seek calls during dragging
                controller.seek(toProgress: Float(newValue))
            }
            .onChange(of: isScrubbing) { _, scrubbing in
                if !scrubbing {
                    // Final seek when scrubbing finishes
                    controller.seek(toProgress: Float(localProgress))
                }
            }
            Text(formatTime(controller.durationMs))
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 48, alignment: .trailing)
        }
        .disabled(controller.currentURL == nil)
        .onChange(of: controller.currentURL) { _, _ in
            // Reset progress when switching songs
            localProgress = 0.0
            isScrubbing = false
        }
    }
}

// MARK: - Volume Control

struct VolumeControl: View {
    @ObservedObject private var controller = VLCPlayerController.shared
    
    // Simple linear volume control - no logarithmic scaling for now
    private func linearToLog(_ linear: Float) -> Float {
        return linear
    }
    
    private func logToLinear(_ log: Float) -> Float {
        return log
    }
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: controller.volume <= 0.001 ? "speaker.slash.fill" : (controller.volume < 0.5 ? "speaker.fill" : "speaker.wave.2.fill"))
                .font(.system(size: 14))
                .foregroundStyle(.primary)
            Slider(value: Binding<Double>(
                get: { Double(linearToLog(controller.volume)) },
                set: { newVal in 
                    let logVal = Float(newVal)
                    controller.volume = logToLinear(logVal)
                }
            ), in: 0...1)
            .frame(width: 160)
        }
        .frame(maxHeight: 24)
    }
}
