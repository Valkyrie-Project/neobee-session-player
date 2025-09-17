import Testing
import Foundation
@testable import neobee_session_player

struct VLCPlayerControllerTests {
    
    @Test func testInitialState() async throws {
        let controller = VLCPlayerController.shared
        
        #expect(!controller.isPlaying)
        #expect(controller.currentURL == nil)
        #expect(controller.audioTrackIds.isEmpty)
        #expect(controller.currentAudioTrackId == nil)
        #expect(controller.audioTrackNames.isEmpty)
        #expect(controller.videoSize == .zero)
        #expect(controller.preferredTrack == .original)
    }
    
    @Test func testPreferredTrackEnum() async throws {
        let controller = VLCPlayerController.shared
        
        // Test enum values
        #expect(VLCPlayerController.PreferredTrack.original != VLCPlayerController.PreferredTrack.accompaniment)
        
        // Test initial state
        #expect(controller.preferredTrack == .original)
        
        // Test that we can change preferred track
        controller.preferredTrack = .accompaniment
        #expect(controller.preferredTrack == .accompaniment)
        
        controller.preferredTrack = .original
        #expect(controller.preferredTrack == .original)
    }
    
    @Test func testAudioTrackProperties() async throws {
        let controller = VLCPlayerController.shared
        
        // Test with empty audio tracks
        #expect(controller.originalTrackId == nil)
        #expect(controller.accompanimentTrackId == nil)
        
        // Simulate having audio tracks
        controller.audioTrackIds = [1, 2, 3]
        
        #expect(controller.originalTrackId == 1)
        #expect(controller.accompanimentTrackId == 2)
    }
    
    @Test func testAudioTrackPropertiesWithSingleTrack() async throws {
        let controller = VLCPlayerController.shared
        
        // Test with only one audio track
        controller.audioTrackIds = [5]
        
        #expect(controller.originalTrackId == 5)
        #expect(controller.accompanimentTrackId == nil)
    }
    
    @Test func testVideoSizeProperty() async throws {
        let controller = VLCPlayerController.shared
        
        // Test initial state
        #expect(controller.videoSize == .zero)
        
        // Test that video size can be updated
        let testSize = CGSize(width: 1920, height: 1080)
        controller.videoSize = testSize
        
        #expect(controller.videoSize.width == 1920)
        #expect(controller.videoSize.height == 1080)
        #expect(controller.videoSize == testSize)
    }
    
    @Test func testCurrentURLProperty() async throws {
        let controller = VLCPlayerController.shared
        
        // Test initial state
        #expect(controller.currentURL == nil)
        
        // Test that current URL can be set
        let testURL = URL(fileURLWithPath: "/test/video.mkv")
        controller.currentURL = testURL
        
        #expect(controller.currentURL == testURL)
        #expect(controller.currentURL?.path == "/test/video.mkv")
        
        // Test clearing URL
        controller.currentURL = nil
        #expect(controller.currentURL == nil)
    }
    
    @Test func testIsPlayingProperty() async throws {
        let controller = VLCPlayerController.shared
        
        // Test initial state
        #expect(!controller.isPlaying)
        
        // Test that playing state can be changed
        controller.isPlaying = true
        #expect(controller.isPlaying)
        
        controller.isPlaying = false
        #expect(!controller.isPlaying)
    }
    
    @Test func testAudioTrackArrays() async throws {
        let controller = VLCPlayerController.shared
        
        // Test initial empty state
        #expect(controller.audioTrackIds.isEmpty)
        #expect(controller.audioTrackNames.isEmpty)
        
        // Test setting audio track data
        let testIds: [Int32] = [1, 2, 3]
        let testNames = ["Track 1", "Track 2", "Track 3"]
        
        controller.audioTrackIds = testIds
        controller.audioTrackNames = testNames
        
        #expect(controller.audioTrackIds.count == 3)
        #expect(controller.audioTrackNames.count == 3)
        #expect(controller.audioTrackIds[0] == 1)
        #expect(controller.audioTrackNames[0] == "Track 1")
    }
    
    @Test func testCurrentAudioTrackId() async throws {
        let controller = VLCPlayerController.shared
        
        // Test initial state
        #expect(controller.currentAudioTrackId == nil)
        
        // Test setting current audio track
        controller.currentAudioTrackId = 42
        #expect(controller.currentAudioTrackId == 42)
        
        // Test clearing current audio track
        controller.currentAudioTrackId = nil
        #expect(controller.currentAudioTrackId == nil)
    }
    
    @Test func testSingletonPattern() async throws {
        let controller1 = VLCPlayerController.shared
        let controller2 = VLCPlayerController.shared
        
        // Test that shared returns the same instance
        #expect(controller1 === controller2)
        
        // Test that changes to one affect the other (since they're the same object)
        controller1.isPlaying = true
        #expect(controller2.isPlaying)
        
        controller1.isPlaying = false
        #expect(!controller2.isPlaying)
    }
}
