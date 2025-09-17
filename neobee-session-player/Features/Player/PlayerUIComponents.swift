import SwiftUI
import Foundation


// MARK: - Video Container

struct VideoContainerView: View {
    @ObservedObject private var controller = VLCPlayerController.shared
    let geometry: GeometryProxy
    let isFullScreen: Bool
    
    var body: some View {
        let containerW = max(geometry.size.width, 1)
        let containerH = max(geometry.size.height, 1) // Use full container height
        let videoW = max(controller.videoSize.width, 16)
        let videoH = max(controller.videoSize.height, 9)
        let aspect = videoW / videoH
        
        let (finalW, finalH): (CGFloat, CGFloat) = {
            if isFullScreen {
                // In fullscreen: always fill width, allow top/bottom black bars
                let heightForWidth = containerW / aspect
                return (containerW, heightForWidth)
            } else {
                // In windowed mode: fill width, reserve space for controls at bottom
                let availableH = containerH - 120 // Reduced from 150
                let heightForWidth = containerW / aspect
                if heightForWidth <= availableH {
                    // Video fits in available height, use full width
                    return (containerW, heightForWidth)
                } else {
                    // Video too tall, scale down but keep full width
                    let h = availableH
                    let w = containerW // Always use full width
                    return (w, h)
                }
            }
        }()
        
        return ZStack {
            // Background with subtle pattern
            RoundedRectangle(cornerRadius: isFullScreen ? 0 : 16)
                .fill(Color.black)
                .overlay(
                    RoundedRectangle(cornerRadius: isFullScreen ? 0 : 16)
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
                .cornerRadius(isFullScreen ? 0 : 12)
                .shadow(color: .black.opacity(isFullScreen ? 0 : 0.3), radius: 8, x: 0, y: 4)
                .position(
                    x: containerW / 2,
                    y: isFullScreen ? containerH / 2 : (containerH - 120) / 2
                )
        }
        .frame(width: containerW, height: containerH)
        .clipped() // Ensure content doesn't overflow
    }
}

// MARK: - Full Screen Mouse Detection

struct FullScreenMouseDetection: View {
    let geometry: GeometryProxy
    let showControls: Bool
    let showControlsWithAutoHide: () -> Void
    let startHideTimer: () -> Void
    let hideControlsTimer: Timer?
    
    @State private var localShowControls: Bool
    
    init(geometry: GeometryProxy, 
         showControls: Bool, 
         showControlsWithAutoHide: @escaping () -> Void, 
         startHideTimer: @escaping () -> Void, 
         hideControlsTimer: Timer?) {
        self.geometry = geometry
        self.showControls = showControls
        self.showControlsWithAutoHide = showControlsWithAutoHide
        self.startHideTimer = startHideTimer
        self.hideControlsTimer = hideControlsTimer
        self._localShowControls = State(initialValue: showControls)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Top area - click to show controls as backup
            Rectangle()
                .fill(Color.clear)
                .contentShape(Rectangle()) // Ensure hover detection works
                .onHover { hovering in
                    // Mouse in top area, start hide timer if leaving
                    if !hovering && localShowControls {
                        startHideTimer()
                    }
                }
                .onTapGesture {
                    // Backup: click anywhere to toggle controls
                    if localShowControls {
                        localShowControls = false
                        hideControlsTimer?.invalidate()
                    } else {
                        showControlsWithAutoHide()
                        localShowControls = true
                    }
                }
            
            // Bottom control area - 150px high
            Rectangle()
                .fill(Color.clear)
                .frame(height: 150)
                .contentShape(Rectangle()) // Ensure hover detection works
                .allowsHitTesting(false) // Don't interfere with control clicks
                .onHover { hovering in
                    if hovering {
                        // Mouse entered control area
                        showControlsWithAutoHide()
                        localShowControls = true
                    } else {
                        // Mouse left control area
                        startHideTimer()
                    }
                }
        }
        .onChange(of: showControls) { _, newValue in
            localShowControls = newValue
        }
    }
}

// MARK: - Background Gradient

struct PlayerBackgroundGradient: View {
    var body: some View {
        LinearGradient(
            colors: [
                Color.black.opacity(0.95),
                Color.black.opacity(0.8),
                Color.black.opacity(0.95)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}
