//
//  DesignSystem.swift
//  neobee-session-player
//
//  Created by Haoran Zhang on 10/09/2025.
//

import SwiftUI

// MARK: - 设计系统常量

struct DesignSystem {
    
    // MARK: - 尺寸常量
    struct Sizes {
        // 播放器控制
        static let playPauseButtonSize: CGFloat = 44
        static let secondaryControlSize: CGFloat = 24
        static let fullScreenButtonSize: CGFloat = 20
        static let audioTrackButtonFontSize: CGFloat = 11
        
        // 进度条
        static let progressBarMinWidth: CGFloat = 120
        static let progressBarMaxWidth: CGFloat = 200
        static let timeLabelWidth: CGFloat = 40
        
        // 音量控制
        static let volumeSliderWidth: CGFloat = 160
        static let volumeControlMaxHeight: CGFloat = 24
        static let volumeIconSize: CGFloat = 14
        
        // 队列显示
        static let queueMaxHeight: CGFloat = 200
        static let queueItemHeight: CGFloat = 44
        
        // 播放器视图
        // 保证控制区不被遮挡的最小宽度（根据控件总宽度与间距预留）
        // 控制区包含：播放按钮(44) + 时间标签(40*2) + 进度条(200) + 音轨按钮(2*60) + 其他控件(24*4) + 音量(160) + 间距(16*8) = 约800
        static let playerMinWidth: CGFloat = 900
        static let libraryMinWidth: CGFloat = 360
        static let minWindowHeight: CGFloat = 400
        static let searchFieldMaxWidth: CGFloat = 320
        static let statusIconSize: CGFloat = 16
        static let queueIndexWidth: CGFloat = 20
        
        // 圆角
        static let cornerRadius: CGFloat = 12
        static let smallCornerRadius: CGFloat = 8
        static let audioTrackButtonCornerRadius: CGFloat = 5
        static let statusBadgeCornerRadius: CGFloat = 4
    }
    
    // MARK: - 间距常量
    struct Spacing {
        static let small: CGFloat = 4
        static let medium: CGFloat = 8
        static let large: CGFloat = 12
        static let extraLarge: CGFloat = 16
        static let huge: CGFloat = 24
        static let windowGutter: CGFloat = 24
        static let controlPadding: CGFloat = 8
        static let controlPanelPadding: CGFloat = 16
        static let horizontalPadding: CGFloat = 32
        static let bottomPadding: CGFloat = 40
        static let bottomPaddingEmbedded: CGFloat = 32
    }
    
    // MARK: - 动画常量
    struct Animation {
        static let controlFadeDuration: Double = 0.3
        static let autoHideDelay: Double = 3.0
        static let bookmarkRestoreDelay: Double = 0.5
        static let trackRefreshDelay: Double = 0.3
    }
    
    // MARK: - 透明度常量
    struct Opacity {
        static let controlHover: Double = 0.7
        static let controlNormal: Double = 1.0
        static let shadow: Double = 0.1
        static let statusBadge: Double = 0.2
    }
    
    // MARK: - 颜色常量
    struct Colors {
        static let controlBackground = Material.thickMaterial
        static let controlOverlay = Material.regularMaterial
        static let shadowColor = Color.black.opacity(Opacity.shadow)
    }
    
    // MARK: - 字体常量
    struct Typography {
        static let timeLabel = Font.caption
        static let audioTrackButton = Font.system(size: Sizes.audioTrackButtonFontSize, weight: .medium)
        static let queueTitle = Font.headline
        static let queueItemTitle = Font.subheadline
        static let queueItemSubtitle = Font.caption
        static let statusBadge = Font.caption
    }
}

// MARK: - 扩展方法

extension DesignSystem {
    /// 格式化时间显示
    static func formatTime(_ milliseconds: Int64) -> String {
        let totalSeconds = Int(milliseconds / 1000)
        let seconds = totalSeconds % 60
        let minutes = (totalSeconds / 60) % 60
        let hours = totalSeconds / 3600
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
    
    /// 计算音量图标名称
    static func volumeIconName(for volume: Float) -> String {
        if volume <= 0.001 {
            return "speaker.slash.fill"
        } else if volume < 0.5 {
            return "speaker.fill"
        } else {
            return "speaker.wave.2.fill"
        }
    }
}
