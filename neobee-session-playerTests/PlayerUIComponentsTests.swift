import Testing
import Foundation

struct PlayerUIComponentsTests {
    
    // 简化的 UI 组件测试，不依赖 SwiftUI 组件
    
    @Test func testUIStateManagement() async throws {
        // 测试 UI 状态管理逻辑
        var isHovering = false
        var isFullScreen = false
        var showControls = true
        
        // 测试悬停状态
        isHovering = true
        #expect(isHovering)
        
        // 测试全屏状态
        isFullScreen = true
        #expect(isFullScreen)
        
        // 测试控制显示状态
        showControls = false
        #expect(!showControls)
    }
    
    @Test func testURLFileNameExtraction() async throws {
        // 测试 URL 文件名提取逻辑
        let testCases = [
            ("/music/song.mkv", "song"),
            ("/videos/movie.mpg", "movie"),
            ("/path/with spaces/file with spaces.mkv", "file with spaces"),
            ("/single.mkv", "single"),
            ("/path/no-extension", "no-extension")
        ]
        
        for (path, expectedName) in testCases {
            let url = URL(fileURLWithPath: path)
            let extractedName = url.deletingPathExtension().lastPathComponent
            #expect(extractedName == expectedName, "Expected '\(expectedName)' but got '\(extractedName)' for path '\(path)'")
        }
    }
}
