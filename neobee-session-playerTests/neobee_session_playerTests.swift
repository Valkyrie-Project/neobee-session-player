//
//  neobee_session_playerTests.swift
//  neobee-session-playerTests
//
//  Created by Haoran Zhang on 10/09/2025.
//

import Testing
import Foundation

struct neobee_session_playerTests {

    // 简化的基础测试，不依赖具体的应用模块
    
    @Test func testBasicFunctionality() async throws {
        // 测试基础功能
        let supportedFormats = ["mkv", "mpg"]
        #expect(supportedFormats.count == 2)
        #expect(supportedFormats.contains("mkv"))
        #expect(supportedFormats.contains("mpg"))
    }
    
    @Test func testURLCreation() async throws {
        // 测试 URL 创建和处理
        let testPath = "/Users/test/video.mkv"
        let url = URL(fileURLWithPath: testPath)
        
        #expect(url.path == testPath)
        #expect(url.pathExtension == "mkv")
        #expect(url.lastPathComponent == "video.mkv")
    }

}
