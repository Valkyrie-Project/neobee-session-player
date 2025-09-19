import SwiftUI

struct HelpView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header
            HStack {
                Text("NeoBee KTV播放器 - 帮助")
                    .font(.title2)
                    .bold()
                Spacer()
                Button("关闭") { dismiss() }
                    .keyboardShortcut(.cancelAction)
            }

            // Basics
            Group {
                Text("基本操作：")
                    .font(.headline)
                VStack(alignment: .leading, spacing: 6) {
                    Text("• 空格键：播放/暂停")
                    Text("• F 键：全屏切换")
                    Text("• ESC 键：退出全屏")
                    Text("• ⌘O：添加歌单")
                    Text("• ⌘F：搜索歌曲")
                    Text("• ⌘Q：退出应用")
                }
            }

            // Arrow key shortcuts
            Group {
                Text("方向键快捷键：")
                    .font(.headline)
                VStack(alignment: .leading, spacing: 6) {
                    Text("• 左方向键：快退 5 秒")
                    Text("• 右方向键：快进 5 秒")
                    Text("• 上方向键：音量 +5%")
                    Text("• 下方向键：音量 -5%")
                }
            }

            // Tracks
            Group {
                Text("音轨选择：")
                    .font(.headline)
                VStack(alignment: .leading, spacing: 6) {
                    Text("• 点击“原唱”按钮播放带人声版本")
                    Text("• 点击“伴奏”按钮播放纯伴奏版本")
                }
            }

            // Library
            Group {
                Text("歌单管理：")
                    .font(.headline)
                VStack(alignment: .leading, spacing: 6) {
                    Text("• 点击“添加歌单”选择音乐文件夹")
                    Text("• 在搜索框输入歌曲名称或艺人")
                    Text("• 点击“清理歌单”清空当前歌单")
                }
            }

            Divider()

            Text("支持格式：MKV, MPG")
                .italic()
                .foregroundStyle(.secondary)

            Spacer(minLength: 0)
        }
        .padding(20)
        .frame(minWidth: 420, idealWidth: 520, minHeight: 420)
    }
}

#Preview {
    HelpView()
        .frame(width: 520, height: 440)
}
