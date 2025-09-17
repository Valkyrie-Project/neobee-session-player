import SwiftUI
import Foundation

struct QueueDisplayView: View {
    @ObservedObject private var queue = QueueManager.shared
    @ObservedObject private var controller = VLCPlayerController.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("已点歌曲")
                .font(.headline)
                .foregroundStyle(.primary)
            
            if queue.hasSongs {
                ScrollView {
                    VStack(spacing: 8) {
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
                    .padding()
                }
                .frame(maxHeight: 200) // Fixed maximum height
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
            } else {
                Text("暂无已点歌曲")
                    .foregroundStyle(.secondary)
                    .italic()
                    .frame(maxHeight: 200) // Same height as when populated
                    .frame(maxWidth: .infinity)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
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
                .font(.system(size: 16))
            
            VStack(alignment: .leading, spacing: 2) {
                Text(url.deletingPathExtension().lastPathComponent)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)
                
                Text("正在播放")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            if controller.isPlaying {
                Text("播放中")
                    .font(.caption)
                    .foregroundStyle(.green)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.green.opacity(0.2), in: RoundedRectangle(cornerRadius: 4))
            } else {
                Text("已暂停")
                    .font(.caption)
                    .foregroundStyle(.orange)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.orange.opacity(0.2), in: RoundedRectangle(cornerRadius: 4))
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
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 20, alignment: .leading)
            
            Image(systemName: "music.note")
                .foregroundStyle(.secondary)
                .font(.system(size: 14))
            
            Text(url.deletingPathExtension().lastPathComponent)
                .font(.subheadline)
                .lineLimit(1)
            
            Spacer()
            
            HStack(spacing: 8) {
                if canMoveToNext {
                    Button("顶到下一首") {
                        onMoveToNext()
                    }
                    .buttonStyle(.borderless)
                    .font(.caption)
                    .foregroundStyle(.blue)
                }
                
                Button("删除") {
                    onRemove()
                }
                .buttonStyle(.borderless)
                .font(.caption)
                .foregroundStyle(.red)
            }
        }
    }
}

#Preview {
    QueueDisplayView()
        .padding()
}
