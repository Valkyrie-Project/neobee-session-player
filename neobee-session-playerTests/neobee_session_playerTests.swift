//
//  neobee_session_playerTests.swift
//  neobee-session-playerTests
//
//  Created by Haoran Zhang on 10/09/2025.
//

import Testing
@testable import neobee_session_player

struct neobee_session_playerTests {

    @Test func testAppLaunch() async throws {
        // Test that basic app components can be initialized
        // This is a smoke test to ensure nothing crashes on startup
        
        // Test that core managers can be accessed
        let queueManager = QueueManager.shared
        let playerController = VLCPlayerController.shared
        
        // Test that shared instances exist (they're non-optional, so just access them)
        _ = queueManager
        _ = playerController
        
        // Test initial states are reasonable
        #expect(queueManager.queue.isEmpty)
        #expect(!playerController.isPlaying)
        #expect(playerController.currentURL == nil)
    }
    
    @Test func testSharedInstancesAreSingleton() async throws {
        // Test that shared instances maintain singleton pattern
        let queueManager1 = QueueManager.shared
        let queueManager2 = QueueManager.shared
        let playerController1 = VLCPlayerController.shared
        let playerController2 = VLCPlayerController.shared
        
        #expect(queueManager1 === queueManager2)
        #expect(playerController1 === playerController2)
    }

}
