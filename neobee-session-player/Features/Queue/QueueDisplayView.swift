import SwiftUI
import Foundation

struct QueueDisplayView: View {
    @ObservedObject private var queue = QueueManager.shared
    @ObservedObject private var controller = VLCPlayerController.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.large) {
            Text("已点歌曲")
                .font(DesignSystem.Typography.queueTitle)
                .foregroundStyle(.primary)
            
            if queue.hasSongs {
                ScrollView {
                    VStack(spacing: DesignSystem.Spacing.medium) {
                        // Current playing song
                        if let currentURL = queue.currentPlayingURL {
                            CurrentPlayingRow(url: currentURL)
                        }
                        
                        // Upcoming songs
                        if !queue.upcomingSongs.isEmpty {
                            Divider()
                            
                            ForEach(Array(queue.upcomingSongs.enumerated()), id: \.offset) { index, url in
                                UpcomingSongRow(
                                    url: url,
                                    index: index,
                                    canMoveToNext: index > 0, // Only allow if it's not the next song (index > 0)
                                    onRemove: { queue.removeFromQueue(at: index + (queue.currentIndex ?? 0) + 1) },
                                    onMoveToNext: { queue.moveToNext(at: index + (queue.currentIndex ?? 0) + 1) }
                                )
                            }
                        }
                    }
                    .padding(DesignSystem.Spacing.controlPadding)
                }
                .frame(maxHeight: DesignSystem.Sizes.queueMaxHeight) // Fixed maximum height
                .background(DesignSystem.Colors.controlOverlay, in: RoundedRectangle(cornerRadius: DesignSystem.Sizes.smallCornerRadius))
            } else {
                Text("暂无已点歌曲")
                    .foregroundStyle(.secondary)
                    .italic()
                    .frame(maxHeight: DesignSystem.Sizes.queueMaxHeight) // Same height as when populated
                    .frame(maxWidth: .infinity)
                    .background(DesignSystem.Colors.controlOverlay, in: RoundedRectangle(cornerRadius: DesignSystem.Sizes.smallCornerRadius))
            }
        }
    }
}

struct CurrentPlayingRow: View {
    let url: URL
    @ObservedObject private var controller = VLCPlayerController.shared
    
    var body: some View {
        HStack {
            Image(systemName: "play.circle.fill")
                .foregroundStyle(.green)
                .font(.system(size: DesignSystem.Sizes.statusIconSize))
            
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.small) {
                Text(url.deletingPathExtension().lastPathComponent)
                    .font(DesignSystem.Typography.queueItemTitle)
                    .fontWeight(.medium)
                    .lineLimit(1)
                
                Text("正在播放")
                    .font(DesignSystem.Typography.queueItemSubtitle)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            if controller.isPlaying {
                Text("播放中")
                    .font(DesignSystem.Typography.statusBadge)
                    .foregroundStyle(.green)
                    .padding(.horizontal, DesignSystem.Spacing.medium)
                    .padding(.vertical, DesignSystem.Spacing.small)
                    .background(.green.opacity(DesignSystem.Opacity.statusBadge), in: RoundedRectangle(cornerRadius: DesignSystem.Sizes.statusBadgeCornerRadius))
            } else {
                Text("已暂停")
                    .font(DesignSystem.Typography.statusBadge)
                    .foregroundStyle(.orange)
                    .padding(.horizontal, DesignSystem.Spacing.medium)
                    .padding(.vertical, DesignSystem.Spacing.small)
                    .background(.orange.opacity(DesignSystem.Opacity.statusBadge), in: RoundedRectangle(cornerRadius: DesignSystem.Sizes.statusBadgeCornerRadius))
            }
        }
    }
}

struct UpcomingSongRow: View {
    let url: URL
    let index: Int
    let canMoveToNext: Bool
    let onRemove: () -> Void
    let onMoveToNext: () -> Void
    
    var body: some View {
        HStack {
            Text("\(index + 1)")
                .font(DesignSystem.Typography.queueItemSubtitle)
                .foregroundStyle(.secondary)
                .frame(width: DesignSystem.Sizes.queueIndexWidth, alignment: .leading)
            
            Image(systemName: "music.note")
                .foregroundStyle(.secondary)
                .font(.system(size: DesignSystem.Sizes.volumeIconSize))
            
            Text(url.deletingPathExtension().lastPathComponent)
                .font(DesignSystem.Typography.queueItemTitle)
                .lineLimit(1)
            
            Spacer()
            
            HStack(spacing: DesignSystem.Spacing.medium) {
                if canMoveToNext {
                    Button("顶到下一首") {
                        onMoveToNext()
                    }
                    .buttonStyle(.borderless)
                    .font(DesignSystem.Typography.queueItemSubtitle)
                    .foregroundStyle(.blue)
                }
                
                Button("删除") {
                    onRemove()
                }
                .buttonStyle(.borderless)
                .font(DesignSystem.Typography.queueItemSubtitle)
                .foregroundStyle(.red)
            }
        }
    }
}

#Preview {
    QueueDisplayView()
        .padding()
}
