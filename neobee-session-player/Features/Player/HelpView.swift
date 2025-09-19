// HelpView.swift
import SwiftUI

struct HelpView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("NeoBee KTV播放器 - 帮助")
                .font(.title2)
                .bold()
            
            Group {
                Text("基本操作：").bold()
                Text("• 空格键：播放/暂停")
                Text("• F键：全屏切换")
                Text("• ESC键：退出全屏")
                Text("• Cmd+O：添加歌单")
                Text("• Cmd+F：搜索歌曲")
                Text("• Cmd+,：偏好设置")
                Text("• Cmd+Q：退出应用")
            }
            Group {
                Text("方向键快捷键：").bold()
                Text("• 左方向键：快退 5 秒")
                Text("• 右方向键：快进 5 秒")
                Text("• 上方向键：音量 +5%")
                Text("• 下方向键：音量 -5%")
            }
            Group {
                Text("音轨选择：").bold()
                Text("• 点击“原唱”按钮播放带人声版本")
                Text("• 点击“伴奏”按钮播放纯伴奏版本")
            }
            Group {
                Text("歌单管理：").bold()
                Text("• 点击“添加歌单”选择音乐文件夹")
                Text("• 在搜索框输入歌曲名称或艺人")
                Text("• 点击“清理歌单”清空当前歌单")
            }
            Text("支持格式：MKV, MPG")
                .italic()
            
            Spacer()
        }
        .padding(20)
        .frame(minWidth: 420, idealWidth: 520, minHeight: 420)
    }
}
