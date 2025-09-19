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
                .font(.system(size: DesignSystem.Sizes.playPauseButtonSize))
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
                HStack(spacing: DesignSystem.Spacing.small) {
                    Image(systemName: "person.wave.2")
                        .font(DesignSystem.Typography.audioTrackButton)
                    Text("原唱")
                        .font(DesignSystem.Typography.audioTrackButton)
                }
                .padding(.horizontal, DesignSystem.Spacing.medium)
                .padding(.vertical, DesignSystem.Spacing.small)
                .background(
                    RoundedRectangle(cornerRadius: DesignSystem.Sizes.audioTrackButtonCornerRadius)
                        .fill(selectedTrack == 0 ? Color.accentColor : Color.clear)
                )
                .foregroundStyle(
                    selectedTrack == 0 ? 
                    .white : 
                    .primary
                )
                .overlay(
                    RoundedRectangle(cornerRadius: DesignSystem.Sizes.audioTrackButtonCornerRadius)
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
                HStack(spacing: DesignSystem.Spacing.small) {
                    Image(systemName: "music.note")
                        .font(DesignSystem.Typography.audioTrackButton)
                    Text("伴奏")
                        .font(DesignSystem.Typography.audioTrackButton)
                }
                .padding(.horizontal, DesignSystem.Spacing.medium)
                .padding(.vertical, DesignSystem.Spacing.small)
                .background(
                    RoundedRectangle(cornerRadius: DesignSystem.Sizes.audioTrackButtonCornerRadius)
                        .fill(selectedTrack == 1 ? Color.accentColor : Color.clear)
                )
                .foregroundStyle(
                    selectedTrack == 1 ? 
                    .white : 
                    .primary
                )
                .overlay(
                    RoundedRectangle(cornerRadius: DesignSystem.Sizes.audioTrackButtonCornerRadius)
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
        HStack(spacing: DesignSystem.Spacing.extraLarge) {
            // Next song button
            Button(action: { queue.playNextIfAvailable() }) {
                Image(systemName: "forward.end.circle")
                    .font(.system(size: DesignSystem.Sizes.secondaryControlSize))
            }
            .buttonStyle(.borderless)
            .disabled(!queue.canPlayNext)
            
            // Stop button
            Button(action: { controller.stop() }) {
                Image(systemName: "stop.circle")
                    .font(.system(size: DesignSystem.Sizes.secondaryControlSize))
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
                    .font(.system(size: DesignSystem.Sizes.fullScreenButtonSize))
            }
            .buttonStyle(.borderless)
        }
    }
}

// MARK: - Control Background

struct ControlBackground: View {
    var body: some View {
        RoundedRectangle(cornerRadius: DesignSystem.Sizes.cornerRadius)
            .fill(DesignSystem.Colors.controlBackground)
            .shadow(color: DesignSystem.Colors.shadowColor, radius: 8, x: 0, y: 2)
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
            HStack(spacing: DesignSystem.Spacing.extraLarge) {
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
            .padding(DesignSystem.Spacing.controlPadding)
            .background(ControlBackground())
            .padding(.horizontal)
            .padding(.bottom, isFullScreen ? DesignSystem.Spacing.bottomPadding : DesignSystem.Spacing.bottomPaddingEmbedded)
        }
    }
}

// MARK: - Progress Seek Bar

struct ProgressSeekBar: View {
    @ObservedObject private var controller = VLCPlayerController.shared
    @State private var isScrubbing: Bool = false
    @State private var localProgress: Double = 0.0 // 0..1 while scrubbing
    
    private func formatTime(_ ms: Int64) -> String {
        return DesignSystem.formatTime(ms)
    }
    
    var body: some View {
        let progress: Double = {
            if isScrubbing { return localProgress }
            return Double(controller.currentPosition)
        }()
        HStack(spacing: DesignSystem.Spacing.medium) {
            Text(formatTime(controller.currentTimeMs))
                .font(DesignSystem.Typography.timeLabel)
                .foregroundStyle(.secondary)
                .frame(width: DesignSystem.Sizes.timeLabelWidth, alignment: .leading)
            Slider(value: Binding<Double>(
                get: { progress },
                set: { newValue in
                    isScrubbing = true
                    localProgress = newValue
                }
            ), in: 0...1, onEditingChanged: { editing in
                // Toggle scrubbing state and perform a final seek when user releases the knob
                isScrubbing = editing
                if !editing {
                    controller.seek(toProgress: Float(localProgress))
                }
            })
            .frame(minWidth: DesignSystem.Sizes.progressBarMinWidth, maxWidth: DesignSystem.Sizes.progressBarMaxWidth)
            .onChange(of: localProgress) { _, newValue in
                // Throttle seek calls during dragging
                controller.seek(toProgress: Float(newValue))
            }
            Text(formatTime(controller.durationMs))
                .font(DesignSystem.Typography.timeLabel)
                .foregroundStyle(.secondary)
                .frame(width: DesignSystem.Sizes.timeLabelWidth, alignment: .trailing)
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
        HStack(spacing: DesignSystem.Spacing.medium) {
            Image(systemName: DesignSystem.volumeIconName(for: controller.volume))
                .font(.system(size: DesignSystem.Sizes.volumeIconSize))
                .foregroundStyle(.primary)
            Slider(value: Binding<Double>(
                get: { Double(linearToLog(controller.volume)) },
                set: { newVal in 
                    let logVal = Float(newVal)
                    controller.volume = logToLinear(logVal)
                }
            ), in: 0...1)
            .frame(width: DesignSystem.Sizes.volumeSliderWidth)
        }
        .frame(maxHeight: DesignSystem.Sizes.volumeControlMaxHeight)
    }
}
