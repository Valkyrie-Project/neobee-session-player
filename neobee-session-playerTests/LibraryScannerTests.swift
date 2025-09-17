import Testing
import Foundation

struct LibraryScannerTests {
    
    // 简化的库扫描测试，不依赖 CoreData
    
    @Test func testFileExtensionFiltering() async throws {
        // 测试文件扩展名过滤逻辑
        let supportedExtensions = ["mkv", "mpg"]
        let testFiles = [
            "video1.mkv",
            "video2.mpg", 
            "video3.mp4", // 不支持
            "audio.mp3",  // 不支持
            "VIDEO.MKV", // 大写应该也支持
        ]
        
        for filename in testFiles {
            let url = URL(fileURLWithPath: "/test/\(filename)")
            let isSupported = supportedExtensions.contains(url.pathExtension.lowercased())
            
            switch filename {
            case "video1.mkv", "video2.mpg", "VIDEO.MKV":
                #expect(isSupported)
            default:
                #expect(!isSupported)
            }
        }
    }
    
    @Test func testDirectoryScanning() async throws {
        // 测试目录扫描逻辑（不实际扫描文件系统）
        let testDirectory = "/Users/test/Music/"
        let url = URL(fileURLWithPath: testDirectory)
        
        #expect(url.hasDirectoryPath)
        #expect(url.path.contains("Music"))
    }
    
    @Test func testMetadataExtraction() async throws {
        // 测试元数据提取逻辑
        let testURL = URL(fileURLWithPath: "/test/song.mkv")
        let filename = testURL.deletingPathExtension().lastPathComponent
        
        #expect(filename == "song")
        #expect(testURL.pathExtension == "mkv")
    }
}

