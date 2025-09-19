import Foundation
import SwiftUI
import AppKit

struct PlayerView: View {
    @ObservedObject private var controller = VLCPlayerController.shared
    @ObservedObject private var queue = QueueManager.shared
    let isEmbedded: Bool
    
    @State private var showControls = true
    @State private var controlsOpacity: Double = 1.0
    @State private var isHovering = false
    @State private var isFullScreen = false
    @State private var hideControlsTimer: Timer?
    // 非阻塞帮助面板开关
    @State private var isShowingHelp = false

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Main video container with rounded corners and shadow
                VideoContainerView(geometry: geometry, isFullScreen: isFullScreen)
                
                // Mouse detection overlay (behind controls)
                if isFullScreen {
                    FullScreenMouseDetection(
                        geometry: geometry,
                        showControls: showControls,
                        showControlsWithAutoHide: showControlsWithAutoHide,
                        startHideTimer: startHideTimer,
                        hideControlsTimer: hideControlsTimer
                    )
                    .zIndex(1)
                }
                
                // iOS 26 Liquid Glass control overlay
                if showControls {
                    ControlOverlay(isHovering: isHovering, isFullScreen: isFullScreen)
                        .opacity(controlsOpacity)
                        .zIndex(10) // Above mouse detection layer
                }
                
            }
        }
        .background(PlayerBackgroundGradient())
        .cornerRadius(isEmbedded ? DesignSystem.Sizes.cornerRadius : 0)
        .onHover { hovering in
            isHovering = hovering
            if !isFullScreen {
                // Simple opacity change without animation for better performance
                controlsOpacity = hovering ? DesignSystem.Opacity.controlNormal : DesignSystem.Opacity.controlHover
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSWindow.didEnterFullScreenNotification)) { _ in
            isFullScreen = true
            // Show controls initially, then auto-hide after 3 seconds
            showControlsWithAutoHide()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSWindow.didExitFullScreenNotification)) { _ in
            isFullScreen = false
            hideControlsTimer?.invalidate()
            showControls = true
            controlsOpacity = 1.0
        }
        .onAppear {
            isFullScreen = NSApp.keyWindow?.styleMask.contains(.fullScreen) ?? false
            if isFullScreen {
                showControlsWithAutoHide()
            }
        }
        .onDisappear {
            // 清理定时器，避免潜在泄漏或越界回调
            hideControlsTimer?.invalidate()
            hideControlsTimer = nil
        }
        // 非阻塞的帮助面板（Sheet）
        .sheet(isPresented: $isShowingHelp) {
            HelpView()
        }
        // 监听菜单栏发出的帮助请求
        .onReceive(NotificationCenter.default.publisher(for: .init("ShowHelpRequested"))) { _ in
            isShowingHelp = true
        }
    }
    
    private func showControlsWithAutoHide() {
        // 如果控件已经显示，不需要重复操作
        if showControls {
            return
        }
        
        showControls = true
        controlsOpacity = 1.0
        
        // Always restart the timer when showing controls
        startHideTimer()
    }
    
    private func startHideTimer() {
        hideControlsTimer?.invalidate()
        hideControlsTimer = Timer.scheduledTimer(withTimeInterval: DesignSystem.Animation.autoHideDelay, repeats: false) { _ in
            if isFullScreen {
                // Simple hide without animation for better performance
                showControls = false
            }
        }
    }
}

#Preview {
    PlayerView(isEmbedded: false)
}
