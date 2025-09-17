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
        HStack(spacing: 2) {
            // 原唱按钮
            Button(action: {
                selectedTrack = 0
                controller.selectOriginalTrack()
            }) {
                HStack(spacing: 3) {
                    Image(systemName: "person.wave.2")
                        .font(.system(size: 11, weight: .medium))
                    Text("原唱")
                        .font(.system(size: 11, weight: .medium))
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(
                    RoundedRectangle(cornerRadius: 5)
                        .fill(selectedTrack == 0 ? Color.accentColor : Color.clear)
                )
                .foregroundStyle(
                    selectedTrack == 0 ? 
                    .white : 
                    .primary
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 5)
                        .stroke(
                            selectedTrack == 0 ? 
                            Color.clear : 
                            Color.secondary.opacity(0.3), 
                            lineWidth: 1
                        )
                )
            }
            .buttonStyle(.plain)
            .disabled(controller.originalTrackId == nil)
            
            // 伴奏按钮
            Button(action: {
                selectedTrack = 1
                controller.selectAccompanimentTrack()
            }) {
                HStack(spacing: 3) {
                    Image(systemName: "music.note")
                        .font(.system(size: 11, weight: .medium))
                    Text("伴奏")
                        .font(.system(size: 11, weight: .medium))
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(
                    RoundedRectangle(cornerRadius: 5)
                        .fill(selectedTrack == 1 ? Color.accentColor : Color.clear)
                )
                .foregroundStyle(
                    selectedTrack == 1 ? 
                    .white : 
                    .primary
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 5)
                        .stroke(
                            selectedTrack == 1 ? 
                            Color.clear : 
                            Color.secondary.opacity(0.3), 
                            lineWidth: 1
                        )
                )
            }
            .buttonStyle(.plain)
            .disabled(controller.accompanimentTrackId == nil)
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
            
            // Main control panel - single row layout
            HStack(spacing: 16) {
                // Play/Pause button
                PlayPauseButton()
                
                // Progress bar with current time and duration, seekable
                ProgressSeekBar()
                
                // Audio track selector
                AudioTrackSelector()
                
                // Secondary controls
                SecondaryControls()
                
                // Volume slider
                VolumeControl()
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
        HStack(spacing: 8) {
            Text(formatTime(controller.currentTimeMs))
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 40, alignment: .leading)
            Slider(value: Binding<Double>(
                get: { progress },
                set: { newValue in
                    isScrubbing = true
                    localProgress = newValue
                }
            ), in: 0...1)
            .frame(minWidth: 120, maxWidth: 200)
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
                .frame(width: 40, alignment: .trailing)
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
