import SwiftUI
import Foundation
import AppKit

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
    
    private var isOriginalSelected: Bool { controller.preferredTrack == .original }
    private var isAccompanimentSelected: Bool { controller.preferredTrack == .accompaniment }
    
    var body: some View {
        HStack(spacing: 2) {
            // 原唱按钮
            Button(action: {
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
                        .fill(isOriginalSelected ? Color.accentColor : Color.clear)
                )
                .foregroundStyle(isOriginalSelected ? .white : .primary)
                .overlay(
                    RoundedRectangle(cornerRadius: DesignSystem.Sizes.audioTrackButtonCornerRadius)
                        .stroke(isOriginalSelected ? Color.clear : Color.secondary.opacity(0.3), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
            .disabled(controller.originalTrackId == nil)
            
            // 伴奏按钮
            Button(action: {
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
                        .fill(isAccompanimentSelected ? Color.accentColor : Color.clear)
                )
                .foregroundStyle(isAccompanimentSelected ? .white : .primary)
                .overlay(
                    RoundedRectangle(cornerRadius: DesignSystem.Sizes.audioTrackButtonCornerRadius)
                        .stroke(isAccompanimentSelected ? Color.clear : Color.secondary.opacity(0.3), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
            .disabled(controller.accompanimentTrackId == nil)
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
                    // Defer to next runloop to avoid colliding with same-frame updates
                    DispatchQueue.main.async {
                        window.toggleFullScreen(nil)
                    }
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
        // Install keyboard shortcuts for arrow keys
        .modifier(ArrowKeyShortcutHandler())
        // Optional: reduce expensive effects during transition
        //.animation(nil, value: isFullScreen)
    }
}

// MARK: - Progress Seek Bar

struct ProgressSeekBar: View {
    @ObservedObject private var controller = VLCPlayerController.shared
    @State private var isScrubbing: Bool = false
    @State private var localProgress: Double = 0.0 // 0..1 while scrubbing
    
    // Debounce state
    @State private var lastSeekAt: CFTimeInterval = 0
    private let seekInterval: CFTimeInterval = 0.20 // 放宽节流：~5 Hz
    
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
                    // During drag, update local state only
                    isScrubbing = true
                    localProgress = newValue
                    // Debounced seek while scrubbing (milliseconds)
                    let now = CACurrentMediaTime()
                    if now - lastSeekAt >= seekInterval {
                        lastSeekAt = now
                        let targetMs = Int64(Double(controller.durationMs) * newValue)
                        controller.seek(toMilliseconds: max(0, min(targetMs, controller.durationMs)))
                    }
                }
            ), in: 0...1, onEditingChanged: { editing in
                // Toggle scrubbing state and perform a final seek when user releases the knob
                isScrubbing = editing
                if !editing {
                    let finalMs = Int64(Double(controller.durationMs) * localProgress)
                    controller.seek(toMilliseconds: max(0, min(finalMs, controller.durationMs)))
                }
            })
            .frame(minWidth: DesignSystem.Sizes.progressBarMinWidth, maxWidth: DesignSystem.Sizes.progressBarMaxWidth)
            .transaction { t in
                // Disable implicit animations to reduce layout work during frequent updates
                t.animation = nil
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
    @State private var lastNonZeroVolume: Float = 1.0
    
    private var isMuted: Bool { controller.volume <= 0.0001 }
    
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.medium) {
            // Mute/Unmute toggle
            Button(action: {
                if isMuted {
                    controller.volume = max(lastNonZeroVolume, 0.1) // restore to previous or a small audible level
                } else {
                    lastNonZeroVolume = controller.volume
                    controller.volume = 0.0
                }
            }) {
                Image(systemName: DesignSystem.volumeIconName(for: controller.volume))
                    .font(.system(size: DesignSystem.Sizes.volumeIconSize))
            }
            .buttonStyle(.borderless)
            .help(isMuted ? "取消静音" : "静音")
            
            // Volume slider
            Slider(value: Binding<Double>(
                get: { Double(controller.volume) },
                set: { newVal in
                    let v = Float(newVal)
                    controller.volume = v
                    if v > 0 { lastNonZeroVolume = v }
                }
            ), in: 0...1)
            .frame(width: 120)
        }
        .frame(maxHeight: DesignSystem.Sizes.volumeControlMaxHeight)
    }
}

// MARK: - Arrow Key Shortcut Handler

private struct ArrowKeyShortcutHandler: ViewModifier {
    @ObservedObject private var controller = VLCPlayerController.shared
    @State private var monitor: Any?
    
    private let seekStepSeconds: Double = 5.0
    private let volumeStep: Float = 0.05
    
    func body(content: Content) -> some View {
        content
            .onAppear {
                // Install local monitor for keyDown events
                monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
                    handle(event: event)
                }
            }
            .onDisappear {
                // Remove monitor to avoid leaks/duplicates
                if let monitor {
                    NSEvent.removeMonitor(monitor)
                }
                monitor = nil
            }
    }
    
    private func handle(event: NSEvent) -> NSEvent? {
        guard controller.currentURL != nil else { return event } // only when media is loaded
        
        switch Int(event.keyCode) {
        case kVK_LeftArrow:
            performSeek(deltaSeconds: -seekStepSeconds)
            return nil
        case kVK_RightArrow:
            performSeek(deltaSeconds: seekStepSeconds)
            return nil
        case kVK_UpArrow:
            adjustVolume(by: volumeStep)
            return nil
        case kVK_DownArrow:
            adjustVolume(by: -volumeStep)
            return nil
        default:
            break
        }
        return event
    }
    
    private func performSeek(deltaSeconds: Double) {
        let durationMs = max(0, controller.durationMs)
        guard durationMs > 0 else { return }
        let currentMs = max(0, controller.currentTimeMs)
        let targetMs = min(Int64(Double(durationMs)), max(Int64(0), currentMs + Int64(deltaSeconds * 1000.0)))
        controller.seek(toMilliseconds: targetMs)
    }
    
    private func adjustVolume(by delta: Float) {
        let newValue = min(1.0, max(0.0, controller.volume + delta))
        controller.volume = newValue
    }
}

// Import Carbon for virtual key codes
import Carbon.HIToolbox
